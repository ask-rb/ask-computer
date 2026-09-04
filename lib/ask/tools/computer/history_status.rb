# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class HistoryStatus < Ask::Tool
        description "Check Cua Computer History status — whether capture is enabled, " \
                    "paused, healthy, and how much encrypted storage is used. " \
                    "Call this before history_query."

        def execute
          history = Ask::Computer.history
          status = history.status

          Ask::Result.ok(data: {
            supported: status.supported,
            admitted: status.admitted,
            enabled: status.enabled,
            paused: status.paused,
            encrypted: status.encrypted,
            profile: status.profile,
            retention_days: status.retention_days,
            quota_bytes: status.quota_bytes,
            bytes_used: status.bytes_used,
            dropped_events: status.dropped_events,
            health: status.health
          })
        rescue Ask::Computer::Error => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        end
      end
    end
  end
end
