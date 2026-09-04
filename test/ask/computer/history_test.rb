# frozen_string_literal: true

require_relative "../../test_helper"

class HistoryTest < Minitest::Test
  def make_driver(returning:)
    driver = mock("driver")
    driver.stubs(:call_tool).returns(returning)
    driver
  end

  def test_status_builds_status_struct
    payload = {
      "supported" => true, "admitted" => true, "enabled" => true,
      "paused" => false, "encrypted" => true, "profile" => "cua-history-profile-v1/cbor-sequence+cose-encrypt0+cloudevents-json",
      "retention_days" => 7, "quota_bytes" => 104_857_600, "bytes_used" => 48291,
      "dropped_events" => 0, "health" => "ready"
    }
    history = Ask::Computer::History.new(make_driver(returning: payload))
    status = history.status
    assert status.enabled?
    assert status.healthy?
    assert status.available?
    assert_equal "ready", status.health
    assert_equal 48291, status.bytes_used
  end

  def test_query_validates_limit
    history = Ask::Computer::History.new(make_driver(returning: {}))
    assert_raises(Ask::Computer::InvalidHistoryQuery) { history.query(limit: 0) }
    assert_raises(Ask::Computer::InvalidHistoryQuery) { history.query(limit: 201) }
  end

  def test_query_validates_sequence_range
    history = Ask::Computer::History.new(make_driver(returning: {}))
    assert_raises(Ask::Computer::InvalidHistoryQueryRange) do
      history.query(since_sequence: 10, until_sequence: 5)
    end
  end

  def test_query_validates_session_id_length
    history = Ask::Computer::History.new(make_driver(returning: {}))
    assert_raises(Ask::Computer::InvalidHistoryQuery) { history.query(session_id: "") }
    assert_raises(Ask::Computer::InvalidHistoryQuery) { history.query(session_id: "x" * 129) }
  end

  def test_query_returns_query_result
    payload = {
      "events" => [
        {
          "specversion" => "1.0", "id" => "111", "source" => "urn:cua-driver:history:222",
          "type" => "cua-driver.history.action_completed.v0", "subject" => "action/444",
          "time" => "2026-08-14T12:00:00Z", "datacontenttype" => "application/json",
          "dataschema" => "urn:cua-driver:schema:history-event:v0",
          "data" => { "sequence" => 42, "capability" => "computer.pointer.click" }
        }
      ],
      "metadata_only" => true, "model_context_disclosure" => true
    }
    history = Ask::Computer::History.new(make_driver(returning: payload))
    result = history.query(limit: 1)
    assert_equal 1, result.events.size
    assert result.metadata_only?
    assert_equal 42, result.events.first.data["sequence"] || result.events.first.data[:sequence]
  end

  def test_each_page_yields_pages_until_empty
    driver = mock("driver2")
    driver.stubs(:call_tool).returns(
      "events" => Array.new(3) { |i| {"id" => i.to_s, "source" => "s", "type" => "t", "data" => {"sequence" => i + 1}}},
      "metadata_only" => true
    )
    history = Ask::Computer::History.new(driver)
    pages = []
    history.each_page(limit: 50) { |p| pages << p }
    assert_equal 1, pages.size
    assert_equal 3, pages.first.events.size
  end

  def test_each_page_returns_enumerator_without_block
    driver = mock("driver_enum")
    driver.stubs(:call_tool).returns("events" => [], "metadata_only" => true)
    history = Ask::Computer::History.new(driver)
    enum = history.each_page(limit: 10)
    assert_kind_of Enumerator, enum
  end
end
