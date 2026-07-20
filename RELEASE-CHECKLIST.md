# Release Checklist

The experimental release and stable v1 have intentionally different bars.
Publishing early is allowed; overstating what is automated is not.

## Experimental publication bar

### Package

- [x] Sanitized public config and secret-reference contract
- [x] Domain-ownership hard gate and separate acquisition preflight
- [x] Generic OpenBSD rendering with strict input validation
- [x] Relay-first SMTP, IMAP, ACME, HTTPS, firewall, SSH, aliases, and doas templates
- [x] Roundcube installer/config and behavior-based webmail smoke test
- [x] Direct-to-MX candidate with human-approved gate and relay rollback
- [x] Atomic relay-secret rotation and repeat-safe alias merge
- [x] Resumable phase ledger and guarded scratch handling
- [x] Offline privacy, safety, and failure-injection suite
- [x] Experimental limitations stated in the agent guide
- [x] MIT license and best-effort support boundary

### Publication surface

- [x] Create public `HenryThriver/agent-native-email` repository
- [x] Run public-tree and Git-history secret scans before first push
- [ ] Tag immutable `v0.1.0-experimental` and publish its archive checksum
- [x] Replace local starter source and pending checksum in the guide
- [ ] Host the versioned raw guide without JavaScript or authentication
- [ ] Fetch the public guide URL outside the signed-in website session and
      confirm it returns the intended plain Markdown
- [x] Draft the human handoff essay with the copy-paste launcher
- [ ] Henry voice-pass the essay
- [ ] Publish the essay and add its callout to the quest page

These unchecked publication-surface items are the only remaining blockers to
sharing the experimental release cleanly.

## Stable v1 hardening

These improve repeatability and confidence. Henry has explicitly decided they
do not block experimental publication.

### Deterministic adapters and acceptance

- [ ] Read-only Cloudflare/Vultr capability probes
- [ ] Vultr plan/image discovery and dry-run/apply adapter
- [ ] DNS inventory, non-destructive planner, rollback, and gated apply
- [ ] Server bootstrap and package-discovery adapter
- [ ] DKIM generation/public-record extraction with private-key boundary test
- [ ] TLS issuance and renewal verification
- [ ] macOS mbsync/notmuch/msmtp renderers and scheduler-context test
- [ ] Provider-independent SMTP/IMAP/auth/open-relay acceptance runner
- [ ] Live dual-path acceptance: direct deliverability plus relay fallback
- [ ] Live Roundcube login, protected-path, receive, and send acceptance
- [ ] Snapshot and isolated restore-drill adapter
- [ ] Minimal tool-disabled classifier and synthetic golden set

### Rehearsals and review

- [ ] Disposable fresh-domain replay from a clean macOS user context
- [ ] Interrupt/resume tests at every phase boundary
- [ ] Failure injections for provider timeout, dirty IP, bad token scope, stale
      resolver, invalid config, failed secret transport, and failed acceptance
- [ ] Migration-shaped rehearsal with populated DNS and exact rollback
- [ ] Independent OpenBSD/OpenSMTPD/Dovecot correctness review
- [ ] Independent secrets, DNS, deliverability, and least-privilege review
- [ ] Prompt-injection and agent-authority review
- [ ] Beginner follows only the public guide and starter
- [ ] Test the public launcher from a clean agent conversation

Set `release_status: stable` only after these stable-v1 gates pass or are
explicitly replaced by equally strong evidence.
