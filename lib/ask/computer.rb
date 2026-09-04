# frozen_string_literal: true

require_relative "computer/version"
require_relative "computer/errors"
require_relative "computer/config"
require_relative "computer/context"

module Ask
  module Computer
    class << self
      def config
        @config ||= Config.new
      end

      def configure
        yield config if block_given?
        config
      end

      def reset!
        @config = Config.new
        @driver = nil
        @history = nil
        @sandbox = nil
      end

      def driver
        @driver ||= Driver.new(config)
      end

      def driver=(instance)
        @driver = instance
      end

      def history(driver = nil)
        History.new(driver || self.driver)
      end

      def sandbox(driver = nil)
        Sandbox.new(driver || self.driver)
      end

      # Launch (or find) a desktop app and resolve its live window.
      #
      #   app = Ask::Computer.launch("com.apple.calculator")
      #   app.press("7")
      #
      def launch(bundle_id_or_name, driver: nil)
        App.launch(bundle_id_or_name, driver: driver || self.driver)
      end

      def installer
        Installer
      end

      def installed? = Installer.installed?
      def install(...) = Installer.install(...)
      def setup(...) = Installer.setup(...)
      def status = Installer.status
    end

    autoload :Driver, "ask/computer/driver"
    autoload :App, "ask/computer/app"
    autoload :EmptyAccessibilityTree, "ask/computer/app"
    autoload :History, "ask/computer/history"
    autoload :Sandbox, "ask/computer/sandbox"
    autoload :Installer, "ask/computer/installer"
    autoload :CLI, "ask/computer/cli"
  end
end
