---
name: computer.use_computer
description: Drive desktop apps in the background via Cua Driver and query encrypted Computer History — screenshots, clicks, typing, sandboxed VMs, and prior-run context
---

Use this skill when you need to automate desktop applications, inspect screen state, or resume prior work using Computer History.

## Prerequisites

Cua Driver must be installed. If `Ask::Computer.driver.start` fails, tell the user how to install it:

```bash
/bin/bash -c "$(curl -fsSL https://cua.ai/driver/install.sh)"
# then follow post-install instructions at https://cua.ai/docs/tutorials/drive-your-first-app
```

For Computer History (prior-run context), the daemon must be a nightly build with the preview admitted and history enabled:

```bash
cua-driver history enable
cua-driver history status
```

All history access is permission-gated and metadata-only. Never assume history is available.

## Step 1: Discover and Check History

Before broader desktop inspection, check whether history is available — but only when the user asks to continue, resume, recall recent activity, or explain what a prior Cua run did. Do not query history for unrelated tasks.

```ruby
require "ask-computer"

driver = Ask::Computer.driver
driver.start

history = Ask::Computer.history
status = history.status

# status fields: supported, admitted, enabled, paused, encrypted, profile,
#                retention_days, quota_bytes, bytes_used, dropped_events, health
# health values: ready, disabled, paused, not_admitted, key_locked, key_unavailable,
#                storage_corrupt, quota_reached, events_dropped, writer_stopped

if status.enabled? && status.healthy?
  result = history.recent(limit: 20)
  # result.events => Array<Ask::Computer::Event>  (CloudEvents 1.0, see references/history.md)
  # result.metadata_only? => true  (always — no screenshots or typed text)
else
  # Continue without history. Preserve the reason (disabled/paused/unhealthy) in reasoning.
end
```

If `history_status` or `history_query` is not advertised, or permission is denied, continue without history. Do not retry with a broader tool, read files directly, or ask the model to reconstruct history.

## Step 2: Drive the Desktop

Use the computer tools to observe and act. Always verify state changes with a screenshot after acting.

```ruby
# Observe
sandbox = Ask::Computer.sandbox
image = sandbox.screenshot  # or driver.call_tool("computer_screenshot", {})

# Act (background — does not steal cursor or focus)
driver.call_tool("computer_click", { x: 120, y: 80 })
driver.call_tool("computer_type", { text: "Hello" })
driver.call_tool("computer_key", { key: "Enter" })

# Or via Ask::Tool subclasses (for agent sessions)
# Ask::Tools::Computer::Screenshot, Click, Type, Key, HistoryStatus, HistoryQuery
```

Prefer accessibility-aware targeting when available over raw coordinates. After each state-changing action, re-screenshot to confirm the change.

## Step 3: Query History with Bounded Reads

Events are ordered by `data.sequence` ascending. Treat missing sequence numbers as gap evidence. Paginate toward older records with `until_sequence`; toward newer with `since_sequence`. Bounds are inclusive — subtract/add 1 for non-overlapping pages.

```ruby
# Filtered query
history.query(limit: 20, session_id: "abc", since_sequence: 40, until_sequence: 100)

# Paginate through all recent history (newest-first, bounded pages)
history.each_page(limit: 50) do |page|
  page.events.each { |e| puts "#{e.type} seq=#{e.data[:sequence]}" }
end

# Ergonomic: maps RFC error codes to typed errors
#   HistoryNotAdmitted, HistoryKeyLocked, HistoryStorageCorrupt, InvalidHistoryQuery, etc.
```

Handle health warnings explicitly:

- `dropped_events > 0` or `health == "events_dropped"` → treat interval as incomplete.
- `health == "quota_reached"` → history after that point is incomplete.
- `health == "storage_corrupt"` → stop querying; direct user to `cua-driver history delete --yes` if they accept data loss.
- `health == "key_locked"` → user must unlock Keychain/Credential Manager; do not prompt via another tool.

## Step 4: Use History as a Lead, Not a Transcript

Returned events contain only: time, sequence, session/action IDs, capability, optional `application` (`bundle_id`, `display_name`), outcome/route/delivery/evidence categories. They never contain screenshots, typed text, clipboard, tool args/results, window titles, or URLs.

Treat events as hints. Use an identified `application` or `capability` to locate the app, then verify live state (screenshot, accessibility tree) before acting. Never treat history as a complete transcript.

## Sandbox VMs (Optional)

For isolated or parallel runs, use sandboxed VMs:

```ruby
sandbox = Ask::Computer.sandbox

sandbox.ephemeral(:linux) do |vm|
  vm.shell("echo hello")
  vm.screenshot
  vm.click(100, 200)
  vm.type("Hello from sandbox")
end
# vm.destroy is called automatically on block exit
```

Requires a driver that advertises `sandbox_create` / `sandbox_*` tools. Degrade gracefully when unavailable.
