# Interview Mapping — Heartbeat failing to start after a config change

## Troubleshooting questions

**Q:** "A service fails to start with exit status `217/USER`. What does
that tell you, specifically?"

**Strong answer sketch:** systemd's numbered exit statuses encode *which
step* of process startup failed, not just that it failed — `217` paired
with `USER` means the failure happened while systemd was resolving the
configured `User=` account, before the actual executable ever ran. That
narrows the search space immediately to the unit file's user/group
configuration and the system's user database, rather than the
application at all.

## System design angle

**Q:** "What's the risk of hand-editing configuration directly on
production hosts, even for something as small as a unit file?"

**Strong answer sketch:** Every hand-edit is unreviewed, undiffed, and
untracked — there's no record of what changed, why, or by whom beyond
whatever's in the host's own logs, and no automated check (like a CI lint
or `systemd-analyze verify`) runs before it takes effect. At fleet scale,
the same mistake often gets repeated across many hosts precisely because
there was no single reviewed change to catch it once. This is the core
argument for treating infrastructure config the same as application code —
version-controlled, reviewed, and applied through automation.

## Behavioral / STAR

**Q:** "Describe a time a small typo caused a service outage."

- **S:** A fleet-wide service-account hardening change, applied via direct
  host edits, introduced a typo in one service's configured user account.
- **T:** Restore the service and identify the actual mechanism, not just
  "a change broke it."
- **A:** Recognized the specific systemd exit code as pointing at user
  resolution rather than the application; compared the configured user
  against the real account; fixed the unit file and, critically,
  remembered to reload systemd's cached definition before restarting.
- **R:** Fast recovery; RCA identified hand-edited configuration as a
  recurring root cause pattern and proposed routing all such changes
  through reviewed automation instead.
