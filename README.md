# Agent-Native Email Public Handoff

> Experimental release candidate. It is designed for transparent, supported
> early use, not unattended business-critical migration.

This folder packages the proven Agent-Native Comms mail build into a public,
beginner-safe handoff:

- `agent-native-email.md` — the single file a human gives to an agent.
- `starter-kit/` — sanitized, testable infrastructure primitives used by that
  file.
- `STARTER-KIT-CONTRACT.md` — the boundary between the guide and starter.
- `RELEASE-CHECKLIST.md` — the small experimental publish bar and the separate
  stable-v1 hardening backlog.
- `SUPPORT.md` — best-effort help and safe support-request format.
- `LICENSE` — MIT license for reuse and adaptation.
- `CHANGELOG.md` — release-level changes.

## Start here

Give your coding agent the immutable
[`v0.1.0-experimental` guide](https://raw.githubusercontent.com/HenryThriver/agent-native-email/v0.1.0-experimental/agent-native-email.md)
and tell it to begin in `PREFLIGHT` mode. Read the experimental boundary before
approving any paid resource, DNS change, deployment, or migration.

The matching starter archive and checksum are pinned in the guide. Questions
and safe bug reports follow [SUPPORT.md](SUPPORT.md).

The reference build requires an owned domain with registrar and DNS control. It
includes Roundcube webmail and working outbound from launch: SMTP2GO is the
initial/fallback route, while direct-to-MX becomes preferred only after its
explicit deliverability and rollback gates pass.

The private `th-mail-server` repository is evidence, not a publishable template.
It contains personal DNS records, provider IDs, domain keys, and assumptions
from a live system. Public artifacts must be generated independently and prove
that none of those identifiers survived extraction.

## Release state

Current version: `0.1.0-experimental`.

Henry has accepted an early-publication posture: sharing is not blocked on two
additional rehearsals because the underlying live system has already exercised
the architecture. The public package must be explicit about what remains
unpinned, preserve every human gate, and offer best-effort support. Stable v1
keeps the higher automation and independent-review bar.

Required before stable `v1`:

1. Complete provider adapters and offline tests.
2. Run a disposable fresh-domain rehearsal.
3. Run a migration-shaped rehearsal with rollback.
4. Obtain an independent security and beginner-UX review.
5. Publish the starter as a versioned release and replace draft source paths in
   the agent guide with immutable public URLs and checksums.
