# frozen_string_literal: true

module Ask
  module Computer
    class Driver
      attr_reader :config

      def initialize(config = Ask::Computer.config)
        @config = config
        @client = nil
        @mutex = Mutex.new
      end

      def client
        @mutex.synchronize { @client ||= build_client }
      end

      def start
        client.start
        self
      rescue Errno::ENOENT, IOError => e
        raise DriverNotAvailable,
          "Cua Driver not found (#{config.driver_command}): #{e.message}. " \
          "Install it: /bin/bash -c \"$(curl -fsSL https://cua.ai/driver/install.sh)\" — https://cua.ai/docs"
      rescue StandardError => e
        raise DriverNotAvailable, "Failed to start Cua Driver (#{config.driver_command}): #{e.message}"
      end

      def stop
        @mutex.synchronize do
          @client&.stop
          @client = nil
        end
      end

      def started?
        !!(@client&.initialized?)
      end

      def tools
        ensure_started
        client.tools
      end

      def call_tool(name, arguments = {})
        ensure_started
        client.call_tool(name.to_s, arguments)
      rescue DriverNotStarted
        raise
      rescue StandardError => e
        if defined?(Ask::MCP::Error) && e.is_a?(Ask::MCP::Error)
          raise map_mcp_error(e)
        end
        raise Ask::Computer::Error, e.message
      end

      def history_available?
        ensure_started
        names = client.tools.keys.map(&:to_s)
        names.include?("history_status") || names.include?("history_query")
      rescue Ask::Computer::Error
        false
      end

      private

      def ensure_started
        raise DriverNotStarted, "Driver not started — call #start first" unless started?
      end

      def build_client
        require "ask/mcp"
        if config.driver_url?
          Ask::MCP.from_http(config.driver_url)
        else
          Ask::MCP.from_stdio(config.driver_command, Array(config.driver_args))
        end
      end

      def map_mcp_error(error)
        message = error.message.to_s
        code = extract_code(message)
        return Ask::Computer::Error.from_code(code, message) if code

        if message.match?(/permission|denied|unauthorized|forbidden/i)
          PermissionDenied.new(message)
        else
          Ask::Computer::Error.new(message)
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
