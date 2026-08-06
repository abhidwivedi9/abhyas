# Interview Mapping — Daily report cron job has stopped producing output

## Troubleshooting questions

Q: "A scheduled script fails with exit code 126. What does that tell you?"

Strong answer sketch: Shell exit codes above 125 have specific,
standardized meanings — 126 means the shell found the target but could not
execute it (almost always a permissions problem), 127 means the shell
could not find it at all (almost always a PATH problem). Recognizing this
distinction narrows the investigation immediately, before even looking at
the file, and separates this scenario cleanly from the PATH-mismatch
scenario that looks superficially similar (both are "the job just doesn't
run") but has a completely different root cause and fix.

## Behavioral / STAR

Q: "Tell me about two similar-looking incidents that turned out to have
different root causes."

- S: Two scheduled-job failures looked identical from the pager alert
  alone ("report hasn't updated"), but had different underlying causes —
  one a PATH mismatch, one a stripped execute bit.
- T: Diagnose each correctly rather than assuming the same fix applies.
- A: Used the exit code as an immediate differentiator (127 vs 126)
  before investigating further, and reproduced cron's exact invocation
  environment for both rather than guessing.
- R: Correctly fixed both incidents with their actual respective causes,
  and used the pattern of "two permission-related incidents in a row" to
  push a process fix (narrower-scoped cleanup scripts) up in priority.
