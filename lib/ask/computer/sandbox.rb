# frozen_string_literal: true

module Ask
  module Computer
    class Sandbox
      attr_reader :driver

      def initialize(driver = nil)
        @driver = driver || Ask::Computer.driver
      end

      def screenshot
        result = @driver.call_tool("computer_screenshot", {})
        extract_image(result)
      end

      def ephemeral(image = "linux", &block)
        started = ensure_sandbox_tool?
        raise DriverNotAvailable, "Sandbox not available on this driver" unless started

        result = @driver.call_tool("sandbox_create", { image: image.to_s })
        id = result["sandbox_id"] || result[:sandbox_id] || result.dig("content", 0, "text")
        handle = Handle.new(id.to_s, @driver)
        return handle unless block

        begin
          yield handle
        ensure
          handle.destroy
        end
      end

      class Handle
        attr_reader :id, :driver

        def initialize(id, driver)
          @id = id
          @driver = driver
        end

        def screenshot
          @driver.call_tool("sandbox_screenshot", { sandbox_id: id })
        end

        def click(x, y)
          @driver.call_tool("sandbox_click", { sandbox_id: id, x: Integer(x), y: Integer(y) })
        end

        def type(text)
          @driver.call_tool("sandbox_type", { sandbox_id: id, text: text.to_s })
        end

        def shell(command)
          @driver.call_tool("sandbox_shell", { sandbox_id: id, command: command.to_s })
        end

        def destroy
          @driver.call_tool("sandbox_destroy", { sandbox_id: id })
        rescue StandardError
          nil
        end
      end

      private

      def ensure_sandbox_tool?
        tools = @driver.tools
        tools.key?("sandbox_create") || tools.key?(:sandbox_create)
      rescue StandardError
        false
      end

      def extract_image(result)
        return result if result.is_a?(Hash) && (result["type"] == "image" || result[:type] == "image")

        content = result[:content] || result["content"]
        return result unless content.is_a?(Array)

        image = content.find { |c| (c[:type] || c["type"]) == "image" }
        image || result
      end
    end
  end
end
