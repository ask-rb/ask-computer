# frozen_string_literal: true

require "ask/tools"

module Ask
  module Tools
    module Computer
      class Click < Ask::Tool
        description "Click at screen coordinates via Cua Driver. Background click — does not steal cursor."

        param :x, type: :integer, desc: "X coordinate in screen pixels", required: true
        param :y, type: :integer, desc: "Y coordinate in screen pixels", required: true
        param :button, type: :string, desc: "Mouse button: left, right, middle", required: false

        def execute(x:, y:, button: "left")
          driver = Ask::Computer.driver
          result = driver.call_tool("computer_click", { x: Integer(x), y: Integer(y), button: button.to_s })
          Ask::Result.ok(data: result)
        rescue Ask::Computer::Error => e
          Ask::Result.error(message: e.message, metadata: { error_class: e.class.name })
        rescue ArgumentError => e
          Ask::Result.error(message: e.message)
        end
      end
    end
  end
end
