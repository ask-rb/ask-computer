# frozen_string_literal: true

require_relative "../../test_helper"

class AppTest < Minitest::Test
  def live_state(pid, wid, elements: 5)
    [{ text: "window_id=#{wid} pid=#{pid} size=400x300 elements=#{elements}\n\n- [0] AXWindow", type: "text" }]
  end

  def dead_state
    [{ text: "window_id 9 is not a live window (closed, or the id is stale)", type: "text" }]
  end

  def test_launch_resolves_pid_from_launch_output
    driver = mock("driver")
    driver.stubs(:call_tool)
      .with("launch_app", { bundle_id: "com.apple.calculator" })
      .returns([{ text: "Launched Calculator (pid 1234) in background.", type: "text" }])

    app = Ask::Computer::App.launch("com.apple.calculator", driver: driver)
    assert_equal 1234, app.pid
  end

  def test_launch_by_name_uses_name_arg
    driver = mock("driver")
    driver.stubs(:call_tool)
      .with("launch_app", { name: "Calculator" })
      .returns([{ text: "Launched Calculator (pid 42) in background.", type: "text" }])

    app = Ask::Computer::App.launch("Calculator", driver: driver)
    assert_equal 42, app.pid
  end

  def test_launch_falls_back_to_list_apps
    driver = mock("driver")
    driver.stubs(:call_tool)
      .with("launch_app", { bundle_id: "com.example.thing" })
      .returns([{ text: "no pid here", type: "text" }])
    driver.stubs(:call_tool)
      .with("list_apps", {})
      .returns([{ text: "- Thing (pid 777) [com.example.thing]", type: "text" }])

    app = Ask::Computer::App.launch("com.example.thing", driver: driver)
    assert_equal 777, app.pid
  end

  def test_launch_raises_when_app_not_found
    driver = mock("driver")
    driver.stubs(:call_tool).returns([{ text: "nothing", type: "text" }])

    error = assert_raises(Ask::Computer::DriverNotAvailable) do
      Ask::Computer::App.launch("com.example.missing", driver: driver)
    end
    assert_match(/Could not launch or find/, error.message)
  end

  def test_resolve_window_probes_ids_until_live
    driver = mock("driver")
    driver.stubs(:call_tool)
      .with("get_window_state", { pid: 1, window_id: 1, include_screenshot: false })
      .returns(dead_state)
    driver.stubs(:call_tool)
      .with("get_window_state", { pid: 1, window_id: 2, include_screenshot: false })
      .returns(live_state(1, 2))

    app = Ask::Computer::App.new(pid: 1, driver: driver)
    assert_equal 2, app.resolve_window!(ids: [1, 2])
  end

  def test_resolve_window_trusts_constructor_window_id
    driver = mock("driver")
    driver.expects(:call_tool).never

    app = Ask::Computer::App.new(pid: 1, driver: driver, window_id: 3)
    assert_equal 3, app.resolve_window!
    assert_equal 3, app.resolve_window!
  end

  def test_resolve_window_memoizes_probed_id
    driver = mock("driver")
    driver.expects(:call_tool).once.returns(live_state(1, 7))

    app = Ask::Computer::App.new(pid: 1, driver: driver)
    assert_equal 7, app.resolve_window!(ids: [7])
    assert_equal 7, app.resolve_window!(ids: [7])
  end

  def test_resolve_window_raises_with_guidance
    driver = mock("driver")
    driver.stubs(:call_tool).returns(dead_state)

    app = Ask::Computer::App.new(pid: 9, driver: driver)
    error = assert_raises(Ask::Computer::DriverNotAvailable) do
      app.resolve_window!(ids: [1])
    end
    assert_match(/bring_to_front/, error.message)
  end

  def test_press_prefers_window_scoped_key
    driver = mock("driver")
    driver.stubs(:call_tool)
      .with("get_window_state", { pid: 1, window_id: 5, include_screenshot: false })
      .returns(live_state(1, 5))
    driver.expects(:call_tool)
      .with("press_key", { pid: 1, window_id: 5, key: "return" })
      .returns([{ text: "pressed", type: "text" }])

    app = Ask::Computer::App.new(pid: 1, driver: driver, window_id: 5)
    assert_equal "pressed", app.press("return")
  end

  def test_press_falls_back_to_frontmost_on_off_space
    driver = mock("driver")
    driver.stubs(:call_tool)
      .with("get_window_state", { pid: 1, window_id: 5, include_screenshot: false })
      .returns(live_state(1, 5))
    driver.stubs(:call_tool)
      .with("press_key", { pid: 1, window_id: 5, key: "7" })
      .raises(Ask::Computer::Error.new("off_space_or_ax_unresolved"))
    driver.stubs(:call_tool)
      .with("bring_to_front", { pid: 1, window_id: 5 })
      .returns([{ text: "front", type: "text" }])
    driver.expects(:call_tool)
      .with("press_key", { key: "7" })
      .returns([{ text: "pressed frontmost", type: "text" }])

    app = Ask::Computer::App.new(pid: 1, driver: driver, window_id: 5)
    assert_equal "pressed frontmost", app.press("7")
  end

  def test_state_returns_ax_text
    driver = mock("driver")
    driver.stubs(:call_tool).returns(live_state(1, 5))

    app = Ask::Computer::App.new(pid: 1, driver: driver, window_id: 5)
    assert_match(/elements=5/, app.state)
  end

  def test_state_raises_typed_error_on_empty_tree
    driver = mock("driver")
    driver.stubs(:call_tool).returns(live_state(1, 5, elements: 0))

    app = Ask::Computer::App.new(pid: 1, driver: driver, window_id: 5)
    error = assert_raises(Ask::Computer::EmptyAccessibilityTree) { app.state }
    assert_match(/#display/, error.message)
  end

  def test_display_copies_and_reads_clipboard
    driver = mock("driver")
    driver.stubs(:call_tool)
      .with("get_window_state", { pid: 1, window_id: 5, include_screenshot: false })
      .returns(live_state(1, 5))
    driver.stubs(:call_tool)
      .with("hotkey", { pid: 1, window_id: 5, keys: %w[cmd c] })
      .returns([{ text: "copied", type: "text" }])
    driver.stubs(:call_tool)
      .with("clipboard_read", {})
      .returns([{ text: "56", type: "text" }])

    app = Ask::Computer::App.new(pid: 1, driver: driver, window_id: 5)
    assert_equal "56", app.display
  end

  def test_type_bring_to_front_first
    driver = mock("driver")
    driver.expects(:call_tool)
      .with("bring_to_front", { pid: 2 })
      .returns([{ text: "front", type: "text" }])
    driver.expects(:call_tool)
      .with("type_text", { text: "hi", pid: 2 })
      .returns([{ text: "typed", type: "text" }])

    app = Ask::Computer::App.new(pid: 2, driver: driver)
    assert_equal "typed", app.type("hi")
  end

  def test_ask_computer_launch_delegate
    driver = mock("driver")
    driver.stubs(:call_tool).returns([{ text: "Launched X (pid 5) in background.", type: "text" }])
    Ask::Computer.stubs(:driver).returns(driver)

    app = Ask::Computer.launch("com.example.x")
    assert_equal 5, app.pid
  ensure
    Ask::Computer.unstub(:driver) rescue nil
    Ask::Computer.reset!
  end
end
