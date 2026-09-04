# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class HistoryQuery < Ask::Tool
        description "Query encrypted Computer History for a bounded slice of metadata-only events. " \
                    "Returns at most 200 events ordered by sequence. Requires history.query capability. " \
                    "Check history_status first. Results are metadata-only — no screenshots or typed text."

        param :limit, type: :integer, desc: "Max events to return (1..200, default 50)", required: false
        param :session_id, type: :string, desc: "Opaque session ID filter (1..128 chars)", required: false
        param :since_sequence, type: :integer, desc: "Inclusive lower sequence bound (>=1)", required: false
        param :until_sequence, type: :integer, desc: "Inclusive upper sequence bound (>=1)", required: false

        def execute(limit: 50, session_id: nil, since_sequence: nil, until_sequence: nil)
          history = Ask::Computer.history
          result = history.query(
            limit: limit,
            session_id: session_id,
            since_sequence: since_sequence,
            until_sequence: until_sequence
          )

          Ask::Result.ok(data: {
            events: result.events.map { |e| serialize_event(e) },
            metadata_only: result.metadata_only,
            model_context_disclosure: result.model_context_disclosure
          })
        rescue Ask::Computer::InvalidHistoryQuery, Ask::Computer::InvalidHistoryQueryRange => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name, code: e.class.name })
        rescue Ask::Computer::Error => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        end

        private

        def serialize_event(event)
          {
            specversion: event.specversion,
            id: event.id,
            source: event.source,
            type: event.type,
            subject: event.subject,
            time: event.time,
            datacontenttype: event.datacontenttype,
            dataschema: event.dataschema,
            data: event.data
          }
        end
      end
    end
  end
end
