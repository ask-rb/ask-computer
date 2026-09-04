# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class Screenshot < Ask::Tool
        description "Capture a screenshot of the current desktop via Cua Driver. " \
                    "Returns an image that vision models can analyze."

        def execute
          sandbox = Ask::Computer.sandbox
          image = sandbox.screenshot
          Ask::Result.ok(data: image)
        rescue Ask::Computer::Error => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        end
      end
    end
  end
end
