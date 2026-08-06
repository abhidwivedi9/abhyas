# Interview Mapping — Heartbeat won't start after routine server maintenance

## Troubleshooting questions

**Q:** "A service fails to start and there's no application-level error in
the logs at all. Where do you look?"

**Strong answer sketch:** Absence of an application log line is itself a
signal — it usually means the process never got far enough to log anything,
which points at the layer *below* the application: the process manager's
own error (systemd's journal entry, not the app's), file permissions,
missing binaries, or a bad working directory. The instinct to check
`ls -l` on the executable and confirm the running user actually has
execute rights is a basic but frequently-skipped step under pressure.

## System design angle

**Q:** "How would you prevent a maintenance script from silently breaking
a production service's permissions?"

**Strong answer sketch:** Scope any bulk permission/ownership change as
narrowly as possible (never a broad glob across shared parent directories);
run it in dry-run/report mode first; and pair any maintenance automation
with an immediate post-run smoke test of the services it could plausibly
affect, rather than relying on the next organic restart to surface a
problem hours or days later.

## Behavioral / STAR

**Q:** "Tell me about a time a routine operational task caused an
unexpected incident."

- **S:** A routine overnight maintenance script caused a service to fail on
  its next restart, with no code change and no obvious link in the change log.
- **T:** Restore service and identify why an unrelated maintenance task
  caused this.
- **A:** Distinguished "no application log at all" from a crash with a
  traceback, went straight to systemd's own journal entry, and checked file
  permissions against what the unit actually needed.
- **R:** Restored service in minutes; RCA traced it to an overly broad
  maintenance script and produced a concrete scoping fix, not just "be more
  careful next time."
