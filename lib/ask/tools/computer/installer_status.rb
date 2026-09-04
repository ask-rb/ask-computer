# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class InstallerStatus < Ask::Tool
        description "Check whether Cua Driver is installed and report its version and " \
                    "Computer History health. Read-only, safe to call without the daemon."

        def execute
          s = Ask::Computer::Installer.status
          Ask::Result.ok(data: {
            installed: s[:installed],
            version: s[:version],
            bin: s[:bin],
            history: s[:history]
          })
        rescue StandardError => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        end
      end
    end
  end
end
