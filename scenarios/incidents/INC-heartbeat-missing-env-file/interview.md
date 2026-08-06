# Interview Mapping — Heartbeat completely refuses to start after a partial config rollout

## Troubleshooting questions

Q: "A service fails to start with no application-level error anywhere in
its logs. What's your first hypothesis?"

Strong answer sketch: No application log line at all — not even a
crash — usually means the process was never launched in the first place,
which points at the layer below the application: the process manager's
own refusal to start the job. For systemd specifically, that means
checking the unit definition itself (missing files it references,
invalid directives, permission issues on the unit file) rather than
assuming the application has a bug. This pattern recurs across several
related failure classes (missing files, bad user references, bad
dependencies) — the shared signature is always "systemd never even
attempts to run your code."

## System design angle

Q: "Why would a configuration rollout deploy in a way that could leave a
system half-configured?"

Strong answer sketch: Whenever a change spans more than one artifact
(here: a unit file plus a config file it depends on) and those artifacts
are deployed as separate steps rather than one atomic operation, there's
a window where the system can observe a partially-applied state. The fix
is either true atomicity (both land together or neither does) or making
each individual step safely tolerate the other's absence (e.g. an
optional `EnvironmentFile=-...` with a leading dash, or defaults baked
into the application itself) — the incident is really evidence that
neither safeguard existed for this particular rollout.

## Behavioral / STAR

Q: "Tell me about an incident caused by an incomplete deployment."

- S: A configuration rollout partially applied — a unit file change
  landed, but the config file it depended on never shipped — causing the
  service to refuse to start entirely.
- T: Restore service and identify the actual gap in how the rollout was
  deployed, not just patch this one occurrence.
- A: Recognized the complete absence of application-level logs as a
  signal that systemd itself was refusing the job, found the missing
  file reference in the unit definition, and chose the appropriate fix
  based on the rollout's actual intent.
- R: Fast recovery; RCA identified the lack of atomic deployment as the
  real root cause and proposed a concrete validation step to prevent this
  exact class of partial-rollout incident going forward.
