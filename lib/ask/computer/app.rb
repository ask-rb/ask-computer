# frozen_string_literal: true

module Ask
  module Computer
    # High-level facade for driving one desktop app.
    #
    # Wraps the four workarounds found live on macOS (Cua Driver 0.21.0):
    #
    # 1. `list_windows` only returns a count — probe `get_window_state`
    #    with small IDs to find the live window.
    # 2. `press_key`/`type_text` without a pid targets the frontmost app,
    #    so `bring_to_front` first (falls back to pid-scoped keys when the
    #    app has multiple windows).
    # 3. Apps with custom rendering (Calculator) expose `elements=0` — read
    #    state back through the clipboard (`Cmd+C`) instead of the AX tree.
    # 4. Every unexpected payload surfaces a typed error that says what to
    #    try next, instead of a raw `Symbol into Integer` crash.
    #
    #   app = Ask::Computer::App.launch("com.apple.calculator")
    #   app.type("7*8")          # frontmost keystrokes
    #   app.press("return")
    #   app.display              # clipboard readback for Calculator-like apps
    #   app.state                # AX text when the app exposes it
    #
    class App
      attr_reader :driver, :pid, :window_id, :bundle_id, :name

      PROBE_IDS = (1..24).to_a.freeze
      DISPLAY_CLEAR_KEYS = %w[escape].freeze

      class << self
        # Launch (or find) an app and resolve its live window.
        #
        # @param bundle_id_or_name [String] `com.apple.calculator` or `Calculator`
        # @param driver [Driver] defaults to `Ask::Computer.driver` (must be started)
        # @return [App]
        # @raise [DriverNotAvailable] when no window can be resolved
        def launch(bundle_id_or_name, driver: nil)
          drv = driver || Ask::Computer.driver
          new(pid: resolve_pid(drv, bundle_id_or_name), driver: drv)
        end

        private

        def resolve_pid(driver, bundle_id_or_name)
          id = bundle_id_or_name.to_s
          result = driver.call_tool("launch_app", id.start_with?("com.") || id.include?(".") ? { bundle_id: id } : { name: id })
          text = content_text(result)
          pid = text.match(/pid (\d+)/)&.then { _1[1].to_i }
          return pid if pid

          apps = content_text(driver.call_tool("list_apps", {}))
          short = id.split(".").last.downcase
          line = apps.lines.find { |l| l.downcase.include?(short) && l.match(/pid (\d+)/) }
          found = line&.match(/pid (\d+)/)&.then { _1[1].to_i }
          return found if found

          raise DriverNotAvailable, "Could not launch or find app #{id.inspect}. Tried bundle_id/name and list_apps."
        end

        def content_text(result)
          return result.to_s unless result.is_a?(Array)

          result.map { |c| c[:text] || c["text"] || "" }.join("\n")
        end
      end

      def initialize(pid:, driver: nil, window_id: nil, bundle_id: nil, name: nil)
        @driver = driver || Ask::Computer.driver
        @pid = Integer(pid)
        @window_id = window_id && Integer(window_id)
        @resolved_window = !@window_id.nil?
        @bundle_id = bundle_id
        @name = name
        @mutex = Mutex.new
      end

      # Resolve (and memoize) the live window for this pid by probing
      # `get_window_state` — works when `list_windows` only returns a count.
      #
      # @return [Integer] the live window id
      # @raise [DriverNotAvailable] when no live window is found
      def resolve_window!(ids: PROBE_IDS)
        @mutex.synchronize do
          return @window_id if @window_id && @resolved_window

          Array(ids).each do |wid|
            if live_window?(wid)
              @window_id = wid
              @resolved_window = true
              return @window_id
            end
          end

          raise DriverNotAvailable,
            "No live window for pid #{pid}. The app may not have opened a window yet, " \
            "or its windows are on another Space. Try `bring_to_front` first."
        end
      end

      # Bring the app to the foreground so pid-less keystrokes land.
      # Falls back gracefully when the app owns several windows.
      #
      # @return [String] the driver message
      def bring_to_front!
        args = { pid: pid }
        args[:window_id] = window_id if window_id
        text = text_of(driver.call_tool("bring_to_front", args))
        if text.match?(/more than one eligible/i)
          resolve_window!
          text = text_of(driver.call_tool("bring_to_front", { pid: pid, window_id: @window_id }))
        end
        text
      end

      # Type text into the app. Prefers the live window's text area when one
      # is exposed, otherwise sends frontmost keystrokes after `bring_to_front`.
      def type(text, element_index: nil)
        bring_to_front!
        args = { text: text.to_s }
        args[:pid] = pid
        args[:window_id] = window_id if window_id
        args[:element_index] = element_index if element_index
        text_of(driver.call_tool("type_text", args))
      rescue Ask::Computer::Error => e
        if e.message.match?(/more than one eligible/i)
          resolve_window!
          retry
        end
        raise friendly_error("type_text", e)
      end

      # Press a single key (`return`, `escape`, `7`, `*`, ...).
      # Sends pid-scoped first, falls back to frontmost (no pid) when the
      # driver refuses (e.g. off-Space window).
      def press(key)
        wid = window_id || resolve_window!
        begin
          return text_of(driver.call_tool("press_key", { pid: pid, window_id: wid, key: key.to_s }))
        rescue Ask::Computer::Error => e
          raise friendly_error("press_key", e) unless fallbackable?(e)
        end
        bring_to_front!
        text_of(driver.call_tool("press_key", { key: key.to_s }))
      rescue Ask::Computer::Error => e
        raise friendly_error("press_key", e)
      end

      # Raw AX markdown for the live window. Raises {EmptyAccessibilityTree}
      # with guidance when the app renders custom content (Calculator).
      def state(include_screenshot: false)
        wid = window_id || resolve_window!
        payload = driver.call_tool(
          "get_window_state",
          { pid: pid, window_id: wid, include_screenshot: include_screenshot }
        )
        text = text_of(payload)
        raise EmptyAccessibilityTree.new(self) if text.match?(/elements=0/)

        text
      end

      # Read the app's visible value via the clipboard (`Cmd+C`).
      # The Calculator workaround: its display is `AXStaticText` with
      # `elements=0`, so the AX tree can't be read — copy and read back.
      #
      # @return [String] clipboard text after copy
      def display
        d = @driver
        begin
          attempt_display(d)
        rescue Ask::Computer::Error => e
          raise friendly_error("display", e) unless fallbackable?(e)

          @mutex.synchronize { @window_id = nil }
          resolve_window!
          attempt_display(d)
        end
      end

      # Clear the app's entry field (`escape` by default).
      def clear(key: "escape")
        press(key)
      end

      private

      def attempt_display(driver)
        wid = window_id || resolve_window!
        driver.call_tool("hotkey", { pid: pid, window_id: wid, keys: %w[cmd c] })
        sleep 0.2
        read = driver.call_tool("clipboard_read", {})
        clipboard_text(read) || raise(
          Ask::Computer::Error,
          "clipboard_read returned no text for pid #{pid}. " \
          "The app may not support Cmd+C; use #state instead."
        )
      end

      def live_window?(wid)
        return false unless wid

        payload = driver.call_tool(
          "get_window_state",
          { pid: pid, window_id: wid, include_screenshot: false }
        )
        text_of(payload).match?(/elements=\d+/) &&
          !text_of(payload).match?(/not a live window|stale/i)
      rescue Ask::Computer::Error
        false
      end

      def fallbackable?(error)
        error.message.match?(/off_space|not among|more than one eligible|Unknown tool/i)
      end

      def friendly_error(tool, error)
        message = error.message.to_s
        hint =
          if message.match?(/bare element_index/)
            " Pass element_index together with the window's snapshot, or use pixel x/y on the window PNG."
          elsif message.match?(/off_space|not among the process/)
            " The window may be on another Space. Called bring_to_front first — verify the app is visible."
          elsif message.match?(/elements=0|empty/i)
            " The app renders custom content with no AX tree. Use #display (clipboard readback) instead of #state."
          elsif message.match?(/Unknown tool/i)
            " The driver build does not advertise this tool (stable vs nightly). Check history_available? / installer status."
          end
        Ask::Computer::Error.new("#{tool} failed for pid #{pid}: #{message}#{hint}")
      end

      def text_of(result)
        return result.to_s unless result.is_a?(Array)

        result.map { |c| c[:text] || c["text"] || "" }.join("\n")
      end

      def clipboard_text(result)
        parts = result.is_a?(Array) ? result : [result]
        parts.each do |part|
          next unless part.is_a?(Hash)

          text = part[:text] || part["text"]
          return text unless text.nil? || text.match?(/omitted|privacy-sensitive/i)
          sc = part[:structuredContent] || part["structuredContent"]
          if sc.is_a?(Hash)
            t = sc[:text] || sc["text"]
            return t if t && !t.empty?
          end
        end
        nil
      end
    end

    # Raised by {App#state} when the app exposes `elements=0`
    # (custom rendering, e.g. Calculator) — use {App#display} instead.
    class EmptyAccessibilityTree < Error
      def initialize(app)
        super(
          "pid #{app.pid} exposes elements=0 (custom rendering, e.g. Calculator). " \
          "Use #display (Cmd+C clipboard readback) or vision on the window PNG instead of #state."
        )
      end
    end
  end
end
