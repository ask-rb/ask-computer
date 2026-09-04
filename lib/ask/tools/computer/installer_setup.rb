# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class InstallerSetup < Ask::Tool
        description "Install Cua Driver (if missing) and optionally enable Computer History. " \
                    "Use dry_run: true to preview the shell command without executing it. " \
                    "Channel is stable or nightly."

        param :channel, type: :string, desc: "stable or nightly", required: false
        param :enable_history, type: :boolean, desc: "Enable Computer History after install", required: false
        param :dry_run, type: :boolean, desc: "Preview only, do not run installer", required: false

        def execute(channel: "stable", enable_history: false, dry_run: false)
          steps = Ask::Computer::Installer.setup(
            channel: channel,
            enable_history: enable_history,
            dry_run: dry_run
          )
          Ask::Result.ok(data: {
            steps: steps.map { |name, r| { name: name.to_s, ok: r.ok?, message: r.message, command: r.command } }
          })
        rescue StandardError => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        end
      end
    end
  end
end
