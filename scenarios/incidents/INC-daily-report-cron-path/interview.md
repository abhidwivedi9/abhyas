# Interview Mapping — Daily report hasn't updated, but the script runs fine when I test it

## Troubleshooting questions

Q: "A scheduled job fails, but running the exact same script manually
works perfectly. How do you approach this?"

Strong answer sketch: Treat "works manually, fails when scheduled" as a
strong signal that the two invocation environments differ, not that the
script's logic is inconsistent. The fastest path isn't staring at the
script, it's reproducing the scheduler's actual environment directly
(cron's real default PATH, its working directory, its user context) and
running the exact same command inside it. This turns a vague, hard-to-
reproduce failure into a locally reproducible one in seconds, instead of
waiting on the job's real schedule to fail again.

## System design angle

Q: "Why do cron, systemd, and CI runners typically give a job a
different environment than an interactive shell?"

Strong answer sketch: Interactive shells load a stack of convenience
configuration (profile scripts, PATH extensions for locally installed
tools) meant for a human at a keyboard. Schedulers and automated triggers
deliberately don't inherit any of that, they invoke the target program
directly with a minimal, predictable environment, so behavior doesn't
silently depend on whichever human last logged in and what they happened
to have configured. That predictability is a feature, but it means
anything a script needs must be stated explicitly (full paths, explicit
PATH=, explicit env vars) rather than assumed.

## Behavioral / STAR

Q: "Describe a bug that was hard to reproduce because your test didn't
match the real failure conditions."

- S: A scheduled job silently failed on every real run, but manual
  testing of the identical script consistently succeeded.
- T: Find the actual discrepancy, not just re-confirm "it works for me."
- A: Recognized the pattern as an environment mismatch rather than a
  logic bug, and reproduced the scheduler's exact environment directly
  instead of continuing to test interactively, which immediately
  surfaced the missing PATH entry.
- R: Fixed the real cause (hardcoded the dependency's full path) and
  changed the team's testing practice going forward to always validate
  against the real invocation environment, not just a convenient one.
