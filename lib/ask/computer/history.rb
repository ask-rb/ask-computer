# frozen_string_literal: true

module Ask
  module Computer
    Status = Data.define(
      :supported, :admitted, :enabled, :paused, :encrypted,
      :profile, :retention_days, :quota_bytes, :bytes_used,
      :dropped_events, :health, :raw
    ) do
      def enabled? = !!enabled
      def paused? = !!paused
      def healthy? = health.to_s == "ready"
      def available? = supported && admitted && enabled && !paused? && healthy?
    end

    Event = Data.define(
      :specversion, :id, :source, :type, :subject, :time,
      :datacontenttype, :dataschema, :data, :raw
    )

    QueryResult = Data.define(:events, :metadata_only, :model_context_disclosure, :raw) do
      def metadata_only? = !!metadata_only
    end

    class History
      DEFAULT_LIMIT = 50
      MAX_LIMIT = 200

      def initialize(driver = nil)
        @driver = driver || Ask::Computer.driver
      end

      def status
        payload = call("history_status", {})
        build_status(payload)
      end

      def query(limit: DEFAULT_LIMIT, session_id: nil, since_sequence: nil, until_sequence: nil)
        args = {}
        args[:limit] = Integer(limit) if limit
        args[:session_id] = session_id if session_id
        args[:since_sequence] = Integer(since_sequence) if since_sequence
        args[:until_sequence] = Integer(until_sequence) if until_sequence

        validate_query_args!(args)
        payload = call("history_query", args)
        build_result(payload)
      end

      def recent(limit: DEFAULT_LIMIT, session_id: nil)
        query(limit: limit, session_id: session_id)
      end

      def each_page(limit: DEFAULT_LIMIT, session_id: nil)
        return enum_for(:each_page, limit: limit, session_id: session_id) unless block_given?

        cursor = nil
        loop do
          args = { limit: limit }
          args[:session_id] = session_id if session_id
          args[:until_sequence] = cursor if cursor
          result = query(**args)
          break if result.events.empty?

          yield result
          break if result.events.size < limit

          earliest = result.events.map { |e| e.data[:sequence] || e.data["sequence"] }.compact.min
          break unless earliest && earliest > 1

          cursor = earliest - 1
        end
      end

      private

      def call(name, args)
        raw = @driver.call_tool(name, args)
        payload = unwrap_content(raw)
        if payload.is_a?(Array) && payload.first.is_a?(Hash)
          text = payload.first[:text] || payload.first["text"]
          raise HistoryNotAvailable, text if text.is_a?(String) && text.match?(/Unknown tool/i)
        elsif payload.is_a?(Hash)
          text = payload[:text] || payload["text"]
          raise HistoryNotAvailable, text if text.is_a?(String) && text.match?(/Unknown tool/i)
        end
        payload
      rescue Ask::Computer::Error
        raise
      rescue StandardError => e
        code = extract_code(e.message)
        raise Ask::Computer::Error.from_code(code, e.message) if code

        raise Ask::Computer::Error, e.message
      end

      def unwrap_content(raw)
        if raw.is_a?(Array)
          if raw.first.is_a?(Hash)
            text = raw.first[:text] || raw.first["text"]
            if text.is_a?(String)
              begin
                parsed = JSON.parse(text, symbolize_names: true)
                return parsed if parsed.is_a?(Hash)
              rescue JSON::ParserError
              end
            end
          end
          return raw
        end

        return raw if raw.is_a?(Hash) && !raw.key?(:content) && !raw.key?("content")

        content = raw[:content] || raw["content"] if raw.is_a?(Hash)
        return raw unless content.is_a?(Array) && content.first

        first = content.first
        text = first[:text] || first["text"]
        return raw unless text

        JSON.parse(text, symbolize_names: true)
      rescue JSON::ParserError
        raw
      end

      def build_status(payload)
        h = stringify(payload)
        Status.new(
          supported: !!h["supported"],
          admitted: !!h["admitted"],
          enabled: !!h["enabled"],
          paused: !!h["paused"],
          encrypted: !!h["encrypted"],
          profile: h["profile"],
          retention_days: h["retention_days"]&.to_i || 7,
          quota_bytes: h["quota_bytes"]&.to_i || 104_857_600,
          bytes_used: h["bytes_used"]&.to_i || 0,
          dropped_events: h["dropped_events"]&.to_i || 0,
          health: h["health"]&.to_s || "unknown",
          raw: payload
        )
      end

      def build_result(payload)
        h = stringify(payload)
        events = Array(h["events"]).map { |e| build_event(e) }
        QueryResult.new(
          events: events,
          metadata_only: h["metadata_only"],
          model_context_disclosure: h["model_context_disclosure"],
          raw: payload
        )
      end

      def build_event(hash)
        h = stringify(hash)
        Event.new(
          specversion: h["specversion"],
          id: h["id"],
          source: h["source"],
          type: h["type"],
          subject: h["subject"],
          time: h["time"],
          datacontenttype: h["datacontenttype"],
          dataschema: h["dataschema"],
          data: h["data"] || {},
          raw: hash
        )
      end

      def stringify(obj)
        return obj unless obj.is_a?(Hash)

        obj.transform_keys(&:to_s)
      end

      def validate_query_args!(args)
        if args[:limit] && (args[:limit] < 1 || args[:limit] > MAX_LIMIT)
          raise InvalidHistoryQuery, "limit must be 1..#{MAX_LIMIT} (got #{args[:limit]})"
        end
        if args[:session_id] && (args[:session_id].to_s.empty? || args[:session_id].to_s.length > 128)
          raise InvalidHistoryQuery, "session_id must be 1..128 characters"
        end
        if args[:since_sequence] && args[:since_sequence] < 1
          raise InvalidHistoryQuery, "since_sequence must be >= 1"
        end
        if args[:until_sequence] && args[:until_sequence] < 1
          raise InvalidHistoryQuery, "until_sequence must be >= 1"
        end
        if args[:since_sequence] && args[:until_sequence] && args[:since_sequence] > args[:until_sequence]
          raise InvalidHistoryQueryRange, "since_sequence (#{args[:since_sequence]}) must not exceed until_sequence (#{args[:until_sequence]})"
        end
      end

      def extract_code(message)
        if (m = message.match(/"code"\s*:\s*"(?<code>[^"]+)"/))
          m[:code]
        elsif (m = message.match(/\b(history_\w+|invalid_history\w*)\b/))
          m[1]
        end
      end
    end
  end
end
