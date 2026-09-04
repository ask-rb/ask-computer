# frozen_string_literal: true

module Ask
  module Computer
    DESCRIPTION = "Computer use via Cua Driver — drive desktop apps in the background, " \
                  "take screenshots, click, type, and query encrypted Computer History"
    DOCS_URL = "https://cua.ai/docs"
    DRIVER_INSTALL_URL = "https://cua.ai/driver/install.sh"
    HISTORY_DOCS_URL = "https://github.com/trycua/cua/blob/main/libs/cua-driver/docs/computer-history-preview.md"
    AUTH_NAME = :cua_driver
    AUTH_HOW = "Install Cua Driver: /bin/bash -c \"$(curl -fsSL https://cua.ai/driver/install.sh)\" — " \
               "see https://cua.ai/docs/tutorials/drive-your-first-app"
    GEM_NAME = "cua-driver"
    GEM_DOCS = "https://cua.ai/docs"
    QUICK_START = <<~RUBY
      require "ask-computer"

      # Connect to the local Cua Driver daemon
      driver = Ask::Computer.driver
      driver.start

      # Drive the desktop
      driver.call_tool("computer_screenshot", {})
      driver.call_tool("computer_click", { x: 100, y: 200 })

      # Query encrypted Computer History
      history = Ask::Computer.history
      history.status
      history.recent(limit: 20)
    RUBY
  end
end
