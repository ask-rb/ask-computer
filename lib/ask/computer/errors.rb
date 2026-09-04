# frozen_string_literal: true

module Ask
  module Computer
    class Error < StandardError
      CODE_MAP = {
        "history_preview_not_admitted" => "HistoryNotAdmitted",
        "history_key_locked" => "HistoryKeyLocked",
        "history_key_unavailable" => "HistoryKeyUnavailable",
        "history_key_corrupt" => "HistoryKeyCorrupt",
        "history_key_destroy_failed" => "HistoryKeyCorrupt",
        "history_storage_unavailable" => "HistoryStorageUnavailable",
        "history_storage_corrupt" => "HistoryStorageCorrupt",
        "history_quota_reached" => "HistoryQuotaReached",
        "history_writer_stopped" => "HistoryWriterStopped",
        "history_events_dropped" => "HistoryEventsDropped",
        "invalid_history_query" => "InvalidHistoryQuery",
        "invalid_history_query_range" => "InvalidHistoryQueryRange"
      }.freeze

      def self.from_code(code, message = nil)
        klass_name = CODE_MAP[code.to_s]
        klass = klass_name ? Ask::Computer.const_get(klass_name) : self
        klass.new(message || code.to_s)
      end
    end
    class DriverNotAvailable < Error; end
    class DriverNotStarted < Error; end
    class HistoryNotAvailable < Error; end
    class HistoryNotAdmitted < Error; end
    class HistoryKeyLocked < Error; end
    class HistoryKeyUnavailable < Error; end
    class HistoryKeyCorrupt < Error; end
    class HistoryStorageUnavailable < Error; end
    class HistoryStorageCorrupt < Error; end
    class HistoryQuotaReached < Error; end
    class HistoryWriterStopped < Error; end
    class HistoryEventsDropped < Error; end
    class InvalidHistoryQuery < Error; end
    class InvalidHistoryQueryRange < Error; end
    class PermissionDenied < Error; end

    CODE_MAP = Error::CODE_MAP
  end
end
