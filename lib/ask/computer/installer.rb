# frozen_string_literal: true

require "open3"

module Ask
  module Computer
    class Installer
      INSTALL_URL = "https://cua.ai/driver/install.sh"
      UNINSTALL_URL = "https://cua.ai/driver/uninstall.sh"

      Result = Data.define(:ok, :command, :stdout, :stderr, :exit_code, :message) do
        def ok? = !!ok
        def success? = ok?
      end

      class << self
        def installed?
          !which(cua_bin).nil?
        end

        def version
          out, _err, status = Open3.capture3(cua_bin, "--version")
          return nil unless status.success?
          out.strip
        rescue StandardError
          nil
        end

        def history_status
          out, err, status = Open3.capture3(cua_bin, "history", "status", "--json")
          raw = out.empty? ? err : out
          return Result.new(ok: false, command: "#{cua_bin} history status", stdout: out, stderr: err, exit_code: status.exitstatus, message: raw.strip) unless status.success?
          Result.new(ok: true, command: "#{cua_bin} history status", stdout: out, stderr: err, exit_code: 0, message: out.strip)
        rescue StandardError => e
          Result.new(ok: false, command: "#{cua_bin} history status", stdout: "", stderr: e.message, exit_code: 1, message: e.message)
        end

        def install(channel: "stable", bin_dir: nil, no_modify_path: false, dry_run: false)
          args = []
          args += ["--channel", channel.to_s] if channel
          args += ["--bin-dir", bin_dir] if bin_dir && !bin_dir.empty?
          args << "--no-modify-path" if no_modify_path

          cmd = build_install_command(args)
          return Result.new(ok: true, command: cmd, stdout: "", stderr: "", exit_code: 0, message: "dry run: #{cmd}") if dry_run

          run_shell(cmd)
        end

        def enable_history
          run_cua("history", "enable")
        end

        def disable_history
          run_cua("history", "disable")
        end

        def history_enable_result
          enable_history
        end

        def uninstall(purge: false)
          args = purge ? ["--purge"] : []
          cmd = "/bin/bash -c \"$(curl -fsSL #{UNINSTALL_URL})\"#{args.empty? ? "" : " -- #{args.join(" ")}"}"
          run_shell(cmd)
        end

        def status
          {
            installed: installed?,
            version: installed? ? version : nil,
            bin: which(cua_bin),
            history: history_status_payload
          }
        end

        def setup(channel: "stable", enable_history: false, bin_dir: nil, no_modify_path: false, dry_run: false)
          steps = []
          unless installed?
            r = install(channel: channel, bin_dir: bin_dir, no_modify_path: no_modify_path, dry_run: dry_run)
            steps << [:install, r]
            return steps unless r.ok?
          else
            steps << [:install, Result.new(ok: true, command: "already installed", stdout: "", stderr: "", exit_code: 0, message: "cua-driver already installed (#{version})")]
          end

          if enable_history
            if dry_run
              r = Result.new(ok: true, command: "#{cua_bin} history enable", stdout: "", stderr: "", exit_code: 0, message: "dry run: #{cua_bin} history enable")
            else
              r = enable_history
            end
            steps << [:enable_history, r]
          end

          steps
        end

        private

        def cua_bin
          Ask::Computer.config.driver_command
        end

        def which(bin)
          out, _err, status = Open3.capture3("which", bin)
          return nil unless status.success?
          path = out.strip
          path.empty? ? nil : path
        rescue StandardError
          nil
        end

        def build_install_command(extra_args)
          arg_str = extra_args.empty? ? "" : " -- #{extra_args.join(" ")}"
          "/bin/bash -c \"$(curl -fsSL #{INSTALL_URL})\"#{arg_str}"
        end

        def run_shell(cmd)
          out, err, status = Open3.capture3("/bin/bash", "-c", cmd)
          ok = status.success?
          msg = ok ? out.strip : (err.strip.empty? ? out.strip : err.strip)
          Result.new(ok: ok, command: cmd, stdout: out, stderr: err, exit_code: status.exitstatus, message: msg)
        rescue StandardError => e
          Result.new(ok: false, command: cmd, stdout: "", stderr: e.message, exit_code: 1, message: e.message)
        end

        def run_cua(*args)
          out, err, status = Open3.capture3(cua_bin, *args)
          ok = status.success?
          msg = ok ? out.strip : (err.strip.empty? ? out.strip : err.strip)
          Result.new(ok: ok, command: "#{cua_bin} #{args.join(" ")}", stdout: out, stderr: err, exit_code: status.exitstatus, message: msg)
        rescue StandardError => e
          Result.new(ok: false, command: "#{cua_bin} #{args.join(" ")}", stdout: "", stderr: e.message, exit_code: 1, message: e.message)
        end

        def history_status_payload
          r = history_status
          return { ok: false, message: r.message } unless r.ok?
          begin
            require "json"
            JSON.parse(r.stdout)
          rescue StandardError
            { ok: true, raw: r.stdout }
          end
        end
      end
    end
  end
end
