# Changelog

## 0.1.0-experimental — 2026-07-19

- Extracted a sanitized OpenBSD mail starter from the working private system.
- Added a hard owned-domain preflight gate.
- Included Roundcube HTTPS webmail with behavior-based smoke checks.
- Rendered relay and direct-to-MX outbound candidates; relay starts active and
  direct activation requires a complete human-approved gate receipt.
- Added atomic relay-secret installation, alias preservation, resumable phase
  receipts, guarded scratch handling, and offline privacy/failure tests.
- Published the agent execution contract under an explicit experimental,
  human-supervised boundary.
- Added MIT licensing, best-effort support guidance, and the first human essay
  draft.
