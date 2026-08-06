# Interview Mapping — Heartbeat won't come back up after a maintenance window

## Troubleshooting questions

Q: "A service fails to start with an error naming a completely different,
unrelated-sounding unit. How do you approach this?"

Strong answer sketch: Take the error at face value first — systemd is
telling you exactly what it's looking for and can't find. Rather than
assuming the message is a red herring, check the failing unit's own
dependency declarations (Requires=/After=) for a reference to whatever
was named in the error. This scenario's whole lesson is that the fix is
almost always simpler than it first appears once you trust the specific
error text instead of searching elsewhere.

## System design angle

Q: "When should a unit declare Requires= versus Wants= for another unit
it depends on?"

Strong answer sketch: Requires= should be reserved for genuine hard
dependencies — cases where running without the other unit is actively
wrong or unsafe, not just suboptimal. Wants= expresses "start this too if
possible" without making its absence fatal. Over-using Requires= (as this
incident shows) means any future decommissioning of the depended-on unit
becomes an immediate outage for everything that hard-depends on it,
rather than a graceful degradation — the dependency type itself is a
design decision with real operational consequences, not just documentation.

## Behavioral / STAR

Q: "Tell me about an incident caused by someone decommissioning something
that turned out to still be in use."

- S: An internal service was decommissioned during a maintenance window
  without checking what else declared a hard dependency on it, breaking a
  different service entirely.
- T: Restore the affected service and identify the actual process gap
  that allowed this.
- A: Trusted systemd's specific error message rather than searching
  broadly, quickly traced it to a Requires= declaration on the
  now-removed unit, and fixed the dependent unit's definition.
- R: Fast recovery; RCA proposed a concrete pre-decommissioning
  dependency-check step, converting a reactive fix into a preventive
  process change for the whole class of incident.
