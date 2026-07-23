# Changelog

## 0.1.2-experimental — 2026-07-22

Guide tightenings from the first scripted launcher dry run (a low-cost agent
walked a simulated beginner from the public prompt to Gate A):

- The kickoff card must be shown before Gate A approval is requested, with a
  matching preflight check; approve-first-see-later is now explicitly banned.
- No invented elapsed-time or effort estimates; external clocks are named as
  dependencies instead.
- DNS inventory runs the moment the domain is named, and extra pre-gate
  clarification rounds beyond the single grouped question set are disallowed.
- Registrar-default parking/forwarding records no longer force `migration`
  classification once the human confirms nothing depends on them.
- The gut check is asked with the grouped questions.

## 0.1.1-experimental — 2026-07-22

- Made the guide fully standalone: the support boundary is now an absolute URL,
  and the starter archive is downloaded and checksum-verified during read-only
  preflight instead of first being referenced mid-build.
- Replaced the anonymous success receipt with a human-initiated celebration
  email and newsletter invitation.
- Added live sshd configuration validation to the deploy path, with matching
  doas authority and regression checks.
- Documented the operator-key authority boundary in the guide and starter
  contract.
- Release archives are now built with `git archive` so untracked working files
  can never ship.

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
