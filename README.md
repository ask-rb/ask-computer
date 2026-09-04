# ask-computer

[![Gem Version](https://badge.fury.io/rb/ask-computer.svg)](https://badge.fury.io/rb/ask-computer)

Computer use for the ask-rb ecosystem. Drive desktop apps in the background via Cua Driver — screenshots, clicks, typing, sandboxed VMs, and encrypted Computer History. Wraps Cua's MCP tools as `Ask::Tool` subclasses and ships a bundled `computer.use_computer` skill discovered by `ask-skills`.

## Installation

```ruby
gem "ask-computer"
```

```bash
bundle install
```

### Cua Driver — Easy Setup

`ask-computer` talks to a running Cua Driver daemon via MCP (stdio `cua-driver mcp`).

**One command (recommended):**

```bash
bundle exec ask-computer setup --with-history          # stable + history
bundle exec ask-computer setup --channel nightly --with-history  # nightly preview for Computer History
bundle exec ask-computer setup --dry-run               # preview without running
```

Or step by step:

```bash
bundle exec ask-computer install --channel nightly     # or stable (default)
bundle exec ask-computer history enable
bundle exec ask-computer status                        # driver version + history health
bundle exec ask-computer history status                # raw history JSON
```

Ruby API for the same flow:

```ruby
require "ask-computer"

Ask::Computer.setup(channel: "nightly", enable_history: true)
Ask::Computer.status        # => { installed: true, version: "cua-driver 0.21.0", history: { "health" => "ready" } }
Ask::Computer.install(channel: "stable", dry_run: true)  # preview the shell command
Ask::Computer::Installer.version   # => "cua-driver 0.21.0"
```

Manual install still works: `/bin/bash -c "$(curl -fsSL https://cua.ai/driver/install.sh)"`
See https://cua.ai/docs and https://github.com/trycua/cua.

## Quick Start

```ruby
require "ask-computer"

# Connect to the local daemon
driver = Ask::Computer.driver
driver.start

# Drive the desktop (background — does not steal cursor)
driver.call_tool("computer_screenshot", {})
driver.call_tool("computer_click", { x: 120, y: 80 })
driver.call_tool("computer_type", { text: "Hello" })
driver.call_tool("computer_key", { key: "Enter" })

# Encrypted Computer History (permission-gated, metadata-only)
history = Ask::Computer.history
status = history.status
# => #<data Status supported=true admitted=true enabled=true ... health="ready">

if status.enabled? && status.healthy?
  page = history.recent(limit: 20)
  page.events.each { |e| puts "#{e.type} seq=#{e.data[:sequence]}" }
end

# Bounded, paginated reads
history.each_page(limit: 50) do |page|
  page.events.each { |e| puts e.type }
end

# Sandbox VMs (requires driver with sandbox tools)
sandbox = Ask::Computer.sandbox
sandbox.ephemeral(:linux) do |vm|
  vm.shell("echo hello")
  vm.screenshot
  vm.click(100, 200)
end
```

### As Ask::Tool subclasses (for agent sessions)

```ruby
require "ask-computer"

# HistoryStatus / HistoryQuery map to history.status / history.query
# Screenshot / Click / Type / Key map to the corresponding Cua tools
Ask::Tools::Computer::HistoryStatus.new.execute
Ask::Tools::Computer::HistoryQuery.new.execute(limit: 20, session_id: "abc")
Ask::Tools::Computer::Screenshot.new.execute
Ask::Tools::Computer::Click.new.execute(x: 100, y: 200)
```

## Configuration

```ruby
Ask::Computer.configure do |c|
  c.driver_command = "cua-driver"   # binary for stdio transport
  c.driver_args = ["mcp"]           # extra args (default: ["mcp"])
  c.driver_url = nil                # if set, uses HTTP transport instead of stdio
  c.transport = :stdio              # :stdio or :http
  c.history_default_limit = 50
end

# Env vars
# ASK_COMPUTER_DRIVER_COMMAND  — override driver binary (default: cua-driver)
# ASK_COMPUTER_DRIVER_ARGS     — override driver args (default: mcp)
# ASK_COMPUTER_DRIVER_URL      — if set, use HTTP transport
```

## Bundled Skill

The gem ships `lib/ask/skills/computer.use_computer/SKILL.md` (with `references/history.md`). It is auto-discovered by `ask-skills` via `Source::Gems` — no extra dependency needed. Load it in an agent:

```ruby
Ask::Skills.discover        # finds computer.use_computer
registry["computer.use_computer"]
```

## History Contract

- `History#status` → `Ask::Computer::Status` (supported/admitted/enabled/paused/health/retention/quota/bytes_used/dropped_events)
- `History#query(limit:, session_id:, since_sequence:, until_sequence:)` → `QueryResult` (events/metadata_only/model_context_disclosure)
- `History#recent` — alias for `query`
- `History#each_page` — paginates with `until_sequence` (inclusive bounds, handles gaps)
- Typed errors: `HistoryNotAdmitted`, `HistoryKeyLocked`, `HistoryStorageCorrupt`, `InvalidHistoryQuery`, `PermissionDenied`, etc.
- Events are CloudEvents 1.0, `dataschema: urn:cua-driver:schema:history-event:v0`, ordered by `data.sequence` ascending. Metadata-only — no screenshots or typed text.

## Full Documentation

The full ask-rb documentation lives at https://ask-rb.github.io/ask-docs.
