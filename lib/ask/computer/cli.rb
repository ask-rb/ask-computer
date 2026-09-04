# frozen_string_literal: true

require "optparse"

module Ask
  module Computer
    module CLI
      module_function

      def run(argv = ARGV)
        argv = argv.dup
        command = argv.shift

        case command
        when "install" then cmd_install(argv)
        when "setup" then cmd_setup(argv)
        when "status" then cmd_status
        when "history" then cmd_history(argv)
        when "uninstall" then cmd_uninstall(argv)
        when "help", "--help", "-h", nil then cmd_help
        else
          warn "Unknown command: #{command}"
          cmd_help
          1
        end
      end

      def cmd_install(argv)
        opts = { channel: "stable", bin_dir: nil, no_modify_path: false, dry_run: false }
        parser = OptionParser.new do |o|
          o.banner = "Usage: ask-computer install [options]"
          o.on("--channel NAME", "stable or nightly [stable]") { |v| opts[:channel] = v }
          o.on("--bin-dir PATH", "Install dir (default ~/.local/bin)") { |v| opts[:bin_dir] = v }
          o.on("--no-modify-path", "Do not append PATH export to shell rc") { opts[:no_modify_path] = true }
          o.on("--dry-run", "Print the install command without running it") { opts[:dry_run] = true }
          o.on("-h", "--help", "Show help") { puts o; return 0 }
        end
        parser.parse!(argv)
        result = Installer.install(**opts)
        puts result.message
        warn result.stderr unless result.stderr.empty?
        result.ok? ? 0 : 1
      end

      def cmd_setup(argv)
        opts = { channel: "stable", enable_history: false, bin_dir: nil, no_modify_path: false, dry_run: false }
        parser = OptionParser.new do |o|
          o.banner = "Usage: ask-computer setup [options]"
          o.on("--channel NAME", "stable or nightly [stable]") { |v| opts[:channel] = v }
          o.on("--with-history", "Enable Computer History after install") { opts[:enable_history] = true }
          o.on("--bin-dir PATH", "Install dir") { |v| opts[:bin_dir] = v }
          o.on("--no-modify-path", "Do not modify shell rc") { opts[:no_modify_path] = true }
          o.on("--dry-run", "Print commands without running") { opts[:dry_run] = true }
          o.on("-h", "--help", "Show help") { puts o; return 0 }
        end
        parser.parse!(argv)
        steps = Installer.setup(**opts)
        steps.each do |name, result|
          label = name == :install ? "Install" : "History enable"
          puts "#{label}: #{result.ok? ? "ok" : "failed"} — #{result.message}"
          warn result.stderr unless result.stderr.empty?
        end
        steps.all? { |_, r| r.ok? } ? 0 : 1
      end

      def cmd_status
        s = Installer.status
        puts "Installed: #{s[:installed] ? "yes (#{s[:bin]})" : "no"}"
        puts "Version: #{s[:version] || "(unknown)"}" if s[:installed]
        h = s[:history]
        if h.is_a?(Hash) && h[:ok] == false
          puts "History: #{h[:message] || "unavailable"}"
        elsif h.is_a?(Hash)
          puts "History: #{h["health"] || h[:health] || h.inspect[0,120]}"
        else
          puts "History: #{h.inspect[0,120]}"
        end
        0
      end

      def cmd_history(argv)
        sub = argv.shift
        case sub
        when "enable"
          r = Installer.enable_history
          puts r.message
          r.ok? ? 0 : 1
        when "disable"
          r = Installer.disable_history
          puts r.message
          r.ok? ? 0 : 1
        when "status"
          r = Installer.history_status
          puts r.stdout.empty? ? r.message : r.stdout
          warn r.stderr unless r.stderr.empty?
          r.ok? ? 0 : 1
        else
          puts "Usage: ask-computer history <enable|disable|status>"
          1
        end
      end

      def cmd_uninstall(argv)
        purge = argv.include?("--purge")
        r = Installer.uninstall(purge: purge)
        puts r.message
        r.ok? ? 0 : 1
      end

      def cmd_help
        puts <<~HELP
          ask-computer — Cua Driver helper for the ask-computer gem

          Usage:
            ask-computer install [--channel stable|nightly] [--dry-run]
            ask-computer setup [--channel nightly] [--with-history] [--dry-run]
            ask-computer status
            ask-computer history <enable|disable|status>
            ask-computer uninstall [--purge]

          Examples:
            ask-computer install                          # stable channel
            ask-computer install --channel nightly        # nightly (for Computer History preview)
            ask-computer setup --channel nightly --with-history
            ask-computer status
            ask-computer history status --json

          Ruby API:
            Ask::Computer.install(channel: "nightly", dry_run: true)
            Ask::Computer.setup(channel: "nightly", enable_history: true)
            Ask::Computer.status
            Ask::Computer::Installer.version
        HELP
        0
      end
    end
  end
end
