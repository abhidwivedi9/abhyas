# Interview Mapping — Heartbeat down, restart attempts having no effect

## Troubleshooting questions

**Q:** "You run `systemctl restart` on a down service and nothing happens —
no error, no change. What do you check?"

**Strong answer sketch:** "Nothing happens" is itself informative — a
service that at least *tries* and fails leaves a trace (a crash, an error).
A service that a start command refuses to even attempt points at systemd
itself blocking it, not the application: check `LoadState` via `systemctl
status`, specifically watching for `masked` versus the more common
`loaded`. This is a different failure class entirely from anything
application-level, and worth ruling in or out in the first 30 seconds.

## System design angle

**Q:** "Why does `systemctl mask` delete the unit file instead of just
disabling it?"

**Strong answer sketch:** `disable` (removes it from boot targets) and
`mask` (makes it impossible to start at all, even manually or as a
dependency) solve different problems — mask exists specifically to
hard-block a unit that something else keeps trying to (re)start. Because
it's meant to be a strong, deliberate override, systemd implements it as a
symlink to `/dev/null` rather than a flag, which is exactly why the
original file has to go: a symlink and a real file can't occupy the same
path. This scenario's twist — that unmasking alone doesn't restore a
deleted original — is a direct consequence of that design, and is exactly
why configuration should live in source control, not only on the box.

## Behavioral / STAR

**Q:** "Tell me about an incident caused by someone else's change that
you had to diagnose without much context."

- **S:** A service went down shortly after a teammate's unrelated cleanup
  work, with no obvious connection in the initial report.
- **T:** Diagnose and restore service, and figure out the actual causal
  link to the "unrelated" change.
- **A:** Noticed the unusual `LoadState: masked` (rather than assuming a
  normal crash), traced it to the unit file having been replaced by a
  `/dev/null` symlink, and recognized that simply unmasking wouldn't be
  enough since the original config was gone — restored it properly from
  configuration management instead of hand-authoring a replacement.
- **R:** Full recovery with the exact original configuration, no drift
  introduced; RCA identified the real gap (unreviewed manual changes) and
  produced a process fix, not just a technical one.
