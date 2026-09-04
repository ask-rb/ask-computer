# frozen_string_literal: true

require_relative "../../test_helper"

class ErrorsTest < Minitest::Test
  def test_from_code_maps_known_codes
    assert_kind_of Ask::Computer::HistoryNotAdmitted, Ask::Computer::Error.from_code("history_preview_not_admitted")
    assert_kind_of Ask::Computer::HistoryKeyLocked, Ask::Computer::Error.from_code("history_key_locked")
    assert_kind_of Ask::Computer::HistoryStorageCorrupt, Ask::Computer::Error.from_code("history_storage_corrupt")
    assert_kind_of Ask::Computer::HistoryQuotaReached, Ask::Computer::Error.from_code("history_quota_reached")
    assert_kind_of Ask::Computer::InvalidHistoryQuery, Ask::Computer::Error.from_code("invalid_history_query")
    assert_kind_of Ask::Computer::InvalidHistoryQueryRange, Ask::Computer::Error.from_code("invalid_history_query_range")
  end

  def test_from_code_unknown_defaults_to_base
    err = Ask::Computer::Error.from_code("something_else", "oops")
    assert_kind_of Ask::Computer::Error, err
    assert_equal "oops", err.message
  end

  def test_code_map_covers_rfc_codes
    %w[history_key_unavailable history_key_corrupt history_storage_unavailable
       history_writer_stopped history_events_dropped].each do |code|
      assert Ask::Computer::CODE_MAP.key?(code), "missing #{code}"
    end
  end
end
