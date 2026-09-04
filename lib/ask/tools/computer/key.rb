# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class Key < Ask::Tool
        description "Press a key or key combination via Cua Driver (e.g. Enter, Tab, Control+C)."

        param :key, type: :string, desc: "Key or combination to press", required: true

        def execute(key:)
          driver = Ask::Computer.driver
          result = driver.call_tool("computer_key", { key: key.to_s })
          Ask::Result.ok(data: result)
        rescue Ask::Computer::Error => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        end
      end
    end
  end
end
