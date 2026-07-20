# Evidence

Store privacy-safe build receipts here. Never store message content, email
addresses beyond the configured public mailbox, API responses containing
tokens, recovery codes, passwords, private keys, or raw provider exports.

Private evidence belongs under `evidence/private/`, which is ignored by Git and
must be owner-only. The build ledger records only receipt paths and SHA-256
digests, not secret or personal content.

`direct-send-gate.example.json` is intentionally fail-closed. Copy it into the
private evidence area and set a field to `true` only from the corresponding
behavioral check. `human_approved` records the named approval; it is never
inferred by the agent. Direct delivery cannot be selected until every field is
true, including the tested relay rollback.
