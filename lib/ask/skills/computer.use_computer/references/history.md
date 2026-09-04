# Computer History Reference

Detailed schema for `Ask::Computer::History` responses. The live contract is the Cua RFC; this file is a local summary so the skill stays compact.

## Status Response

```
{
  supported: bool, admitted: bool, enabled: bool, paused: bool,
  encrypted: bool, profile: String, retention_days: int (default 7),
  quota_bytes: int (default 104857600), bytes_used: int,
  dropped_events: int, health: String
}
```

Health values:

| health | meaning |
|---|---|
| ready | Healthy |
| disabled | Capture off |
| paused | Capture paused, history still queryable |
| not_admitted | Daemon not started with preview flag |
| key_unavailable / key_locked / key_corrupt / key_destroy_failed | Credential store issue |
| storage_unavailable / storage_corrupt | Encrypted store unreadable |
| quota_reached | Store at quota, new events may be incomplete |
| events_dropped | Nonblocking writer dropped events |
| writer_stopped | Writer unavailable |

## Event (CloudEvents 1.0, dataschema urn:cua-driver:schema:history-event:v0)

Each `history_query` event:

```
{
  specversion, id, source, type, subject, time, datacontenttype, dataschema,
  data: {
    session_id, action_id, sequence, platform, process_model, capability,
    caller_category,
    application?: { bundle_id?, display_name? },
    payload: { kind, effect?, route?, delivery?, delivered_count?, evidence_kinds?[] }
  }
}
```

### Event Types

| type | payload kind |
|---|---|
| cua-driver.history.control.v0 | control |
| cua-driver.history.action_started.v0 | action_started |
| cua-driver.history.action_completed.v0 | action_completed |
| cua-driver.history.session_started.v0 | session |
| cua-driver.history.session_ended.v0 | session |
| cua-driver.history.access.v0 | access |
| cua-driver.history.health.v0 | health |

Ordering: `data.sequence` ascending. `limit` keeps newest N then returns them ascending. No pagination token — page with `since_sequence` / `until_sequence` (inclusive).

## Error Codes

Tool failures map to typed errors via `Ask::Computer::Error.from_code`:

- `invalid_history_query` / `invalid_history_query_range` → `InvalidHistoryQuery*`
- `history_preview_not_admitted` → `HistoryNotAdmitted`
- `history_key_*` → `HistoryKey*`
- `history_storage_*` → `HistoryStorage*`
- `history_quota_reached` → `HistoryQuotaReached`
- `history_writer_stopped` → `HistoryWriterStopped`
- `history_events_dropped` → `HistoryEventsDropped`

Permission denials surface as `Ask::Computer::PermissionDenied` (do not retry with a broader tool).

## Storage Profile

CBOR Sequence of COSE_Encrypt0, CloudEvents JSON inside, ChaCha20-Poly1305, HKDF per chunk, root key in platform credential store (Keychain / Credential Manager / Secret Service). No plaintext fallback.

For full spec see:
- https://github.com/trycua/cua/blob/main/libs/cua-driver/docs/computer-history-preview.md
- https://github.com/trycua/cua/blob/main/libs/cua-driver/docs/computer-history-agent-integration-rfc.md
