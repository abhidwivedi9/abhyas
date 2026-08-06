# Interview Mapping — Audit finding: are heartbeat's logs actually being rotated?

## Troubleshooting questions

Q: "How do you verify that a configuration file is actually doing what it
claims, not just that it's syntactically valid?"

Strong answer sketch: Syntactic validity and functional correctness are
different questions, and a config can pass the first while completely
failing the second — exactly this scenario. The reliable approach is to
use whatever dry-run or debug mode the tool itself provides (here,
`logrotate -d`) rather than reading the config and reasoning about intent
by eye. Where no dry-run mode exists, construct the smallest possible
real test that exercises the actual behavior the config controls.

## System design angle

Q: "Why is a tool that fails silently on misconfiguration more dangerous
than one that errors out loudly?"

Strong answer sketch: A loud failure gets noticed immediately — someone
runs the tool, sees an error, investigates. A silent no-op looks
identical to "everything is fine and there was simply nothing to do,"
which is indistinguishable from the broken state without deliberately
verifying the positive case (that real work actually happened). This is
why proactive audits and periodic dry-run checks matter specifically for
tools designed to be permissive/forgiving — permissiveness is a
usability feature that trades away a safety signal.

## Behavioral / STAR

Q: "Tell me about an issue you found before it caused an incident."

- S: A routine platform audit specifically designed to verify (not just
  inspect) configurations found a logrotate policy that looked correct
  but silently matched zero real files.
- T: Confirm the actual gap, fix it, and identify why nothing else would
  have caught it before an outage occurred.
- A: Used the tool's own dry-run mode to verify actual behavior rather
  than trusting a visual review of the config, found the one-character
  path typo, and proposed making that same verification step mandatory
  on every future config change rather than relying on periodic audits alone.
- R: Fixed proactively, with zero customer impact — and produced a
  process change that closes the detection gap for the entire class of
  "syntactically valid but functionally silent" misconfiguration, not just
  this one instance.
