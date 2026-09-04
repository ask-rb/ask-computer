# Changelog

## [0.1.0] - 2026-08-20

### Added

- Initial release of `ask-computer` — computer use for the ask-rb ecosystem.
- `Ask::Computer` — driver/history/sandbox facades with `configure` / `reset!`.
- `Ask::Computer::Driver` — MCP stdio/HTTP client for Cua Driver (`call_tool`, `tools`, `history_available?`, `start`/`stop`).
- `Ask::Computer::History` — encrypted history client (`status`, `query`, `recent`, `each_page`) with RFC validation (1..200 limit, inclusive sequence bounds, session_id 1..128).
- `Ask::Computer::Sandbox` — VM sandbox facade (`screenshot`, `ephemeral` with `Handle`).
- `Ask::Computer::Error` hierarchy mapped from RFC codes (`HistoryKeyLocked`, `StorageCorrupt`, `QuotaReached`, etc.) via `Error.from_code`.
- `Ask::Tools::Computer::*` — `HistoryStatus`, `HistoryQuery`, `Screenshot`, `Click`, `Type`, `Key` as `Ask::Tool` subclasses.
- Bundled skill `computer.use_computer` (`SKILL.md` + `references/history.md`) discovered by `ask-skills` `Source::Gems` — no `ask-skills` runtime dep needed.
- Dependencies: `ask-core >= 0.11.3`, `ask-tools >= 0.6.2`.
