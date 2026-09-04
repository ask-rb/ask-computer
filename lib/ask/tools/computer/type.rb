# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class Type < Ask::Tool
        description "Type text via Cua Driver. Sends keystrokes in the background."

        param :text, type: :string, desc: "Text to type", required: true

        def execute(text:)
          driver = Ask::Computer.driver
          result = driver.call_tool("computer_type", { text: text.to_s })
          Ask::Result.ok(data: result)
        rescue Ask::Computer::Error => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        end
      end
    end
  end
end
