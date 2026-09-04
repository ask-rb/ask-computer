# frozen_string_literal: true

module Ask
  module Computer
    class Config
      attr_accessor :driver_command, :driver_args, :driver_url, :transport
      attr_accessor :history_default_limit

      def initialize
        @driver_command = ENV.fetch("ASK_COMPUTER_DRIVER_COMMAND", "cua-driver")
        @driver_args = ENV["ASK_COMPUTER_DRIVER_ARGS"] ? ENV["ASK_COMPUTER_DRIVER_ARGS"].split : ["mcp"]
        @driver_url = ENV["ASK_COMPUTER_DRIVER_URL"]
        @transport = :stdio
        @history_default_limit = 50
      end

      def driver_url?
        driver_url && !driver_url.empty?
      end
    end
  end
end
