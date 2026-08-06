# Interview Mapping — Cart service process count climbing steadily, no obvious cause

## Troubleshooting questions

Q: "A container's process count keeps growing but the app seems fine.
What do you check?"

Strong answer sketch: Look at the actual process table, specifically the
process state column - a `Z` (zombie) state means a process has already
exited but hasn't been reaped by its parent. Check who the parent (PPID)
is: zombies owned by PID 1 specifically point at a missing-init problem,
a very common container-specific pattern that doesn't show up on a
normal VM where a real init system (systemd, SysV init) always reaps
orphans automatically.

## System design angle

Q: "Why do containers need special handling for zombie processes that a
regular Linux host doesn't?"

Strong answer sketch: On a normal host, PID 1 is a real init system
(systemd, etc.) specifically designed to reap any orphaned process. In a
container, PID 1 is whatever the image's entrypoint launches - usually
the application itself, which has no idea it's supposed to take on
init's responsibilities and was never written to reap unrelated
processes. This is exactly why Docker added the `--init` flag (which
injects a minimal init like `tini`) and why `tini`/similar tools exist as
a standard container-hardening practice, not an edge case.

## Behavioral / STAR

Q: "Tell me about a subtle issue you caught before it became a real
outage."

- S: A container's process count was climbing steadily with no visible
  application impact - the kind of signal that's easy to deprioritize
  since nothing looks broken.
- T: Determine whether this was a real risk worth acting on, and find the
  actual cause.
- A: Identified the growing entries as zombie processes via the process
  state column, traced the pattern to a missing init in the container,
  and recognized process-table exhaustion as the real (if not yet
  visible) risk rather than dismissing it as cosmetic.
- R: Resolved before any customer impact occurred; RCA proposed adding
  proper init handling as a standing hardening measure, converting a
  one-off cleanup into a permanent fix for the whole class of issue.
