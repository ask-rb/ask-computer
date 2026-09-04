# frozen_string_literal: true

require_relative "../../../test_helper"

class ToolsTest < Minitest::Test
  def test_history_status_is_a_tool
    assert Ask::Tools::Computer::HistoryStatus < Ask::Tool
    assert_equal "history_status", Ask::Tools::Computer::HistoryStatus.new.name
  end

  def test_history_query_is_a_tool
    assert Ask::Tools::Computer::HistoryQuery < Ask::Tool
    assert Ask::Tools::Computer::HistoryQuery.new.parameters.key?(:limit)
  end

  def test_screenshot_is_a_tool
    assert Ask::Tools::Computer::Screenshot < Ask::Tool
  end

  def test_click_validates_params
    assert Ask::Tools::Computer::Click.new.parameters.key?(:x)
    assert Ask::Tools::Computer::Click.new.parameters.key?(:y)
  end

  def test_history_status_execute_maps_to_result
    history = mock("history")
    status = Ask::Computer::Status.new(
      supported: true, admitted: true, enabled: true, paused: false, encrypted: true,
      profile: "p", retention_days: 7, quota_bytes: 100, bytes_used: 10, dropped_events: 0,
      health: "ready", raw: {}
    )
    history.stubs(:status).returns(status)
    Ask::Computer.stubs(:history).returns(history)

    result = Ask::Tools::Computer::HistoryStatus.new.execute
    assert result.success?
    assert_equal true, result.content[:enabled]
  end

  def test_history_query_invalid_limit_returns_error_result
    result = Ask::Tools::Computer::HistoryQuery.new.execute(limit: 999)
    assert result.error?
  end
end
