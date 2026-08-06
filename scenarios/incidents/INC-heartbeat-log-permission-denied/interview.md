# Interview Mapping — Heartbeat health check green, but is it actually logging?

## Troubleshooting questions

**Q:** "You've seen a health check give false confidence before. How do
you prevent the exact same class of incident from recurring?"

**Strong answer sketch:** Recognize that the *symptom* differs (disk full
vs. broken permissions) but the *underlying gap* is identical: the health
check only proves the process is alive, not that its actual work is
happening. Fixing the specific trigger each time (free disk space, restore
ownership) treats the trigger, not the gap — the real fix is a health
check that verifies actual function, done once, which prevents this entire
class of incident regardless of what specifically breaks the background
thread next.

## System design angle

**Q:** "How do you prioritize a prevention action item that would have
stopped a *previous* incident, against new work?"

**Strong answer sketch:** A repeat incident from an un-implemented action
item is a strong, concrete signal — it's no longer a hypothetical
"this might help," it's proven to have prevented a specific, real second
occurrence. That evidence should move it to the top of the queue over
speculative new work; the cost of the gap is no longer estimated, it's
measured (two incidents, two response cycles).

## Behavioral / STAR

**Q:** "Tell me about a recurring incident and what changed the second
time around."

- **S:** The same underlying gap (health check blind to background thread
  failures) caused a second, superficially different incident — this time
  from a permissions change instead of disk space.
- **T:** Fix it fast, and make the case that the earlier action item needs
  to actually get implemented now, not just recorded.
- **A:** Recognized the failure signature from the previous incident
  immediately, diagnosed faster as a result, and used the second
  occurrence as concrete evidence to escalate the priority of the
  still-unimplemented prevention item.
- **R:** Fast recovery; the repeat-incident evidence got the real fix
  prioritized in a way the first RCA alone hadn't achieved.
