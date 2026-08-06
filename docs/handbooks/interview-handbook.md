# Interview Handbook

Grows one chapter per milestone. Each chapter compiles the interview
mapping from that milestone's scenarios — solve the scenario first
(`abhyasctl scenario start <id>`), then use this as a review/quiz sheet
afterward. Reading the answers without having run the scenario first will
teach you far less than actually debugging it.

---

## Chapter 1 — Milestone 1: Foundations (Linux, Git, Bash)

Twelve scenarios, all on the `legacy-vm` lab. Quick index:

| Scenario | Category | What it trains |
|---|---|---|
| [INC-heartbeat-crashloop](../../scenarios/incidents/INC-heartbeat-crashloop/interview.md) | systemd | Reading a traceback in `journalctl`; restart-loop signatures |
| [INC-heartbeat-permission-denied](../../scenarios/incidents/INC-heartbeat-permission-denied/interview.md) | permissions | OS-level vs. application-level failure |
| [INC-heartbeat-masked](../../scenarios/incidents/INC-heartbeat-masked/interview.md) | systemd | `mask` vs `disable`; config as source of truth |
| [INC-heartbeat-wrong-user](../../scenarios/incidents/INC-heartbeat-wrong-user/interview.md) | systemd | Reading systemd exit-status codes |
| [INC-heartbeat-disk-full](../../scenarios/incidents/INC-heartbeat-disk-full/interview.md) | disk pressure | Liveness checks that lie |
| [INC-heartbeat-log-permission-denied](../../scenarios/incidents/INC-heartbeat-log-permission-denied/interview.md) | permissions | Recurring incidents & prioritizing prevention |
| [INC-daily-report-cron-path](../../scenarios/incidents/INC-daily-report-cron-path/interview.md) | cron | Scheduler environment vs. interactive shell |
| [INC-daily-report-not-executable](../../scenarios/incidents/INC-daily-report-not-executable/interview.md) | cron | Exit code 126 vs. 127 |
| [INC-logrotate-misconfigured](../../scenarios/incidents/INC-logrotate-misconfigured/interview.md) | config drift | Silent misconfiguration; verifying vs. inspecting |
| [INC-heartbeat-port-conflict](../../scenarios/incidents/INC-heartbeat-port-conflict/interview.md) | networking | Shared-host resource contention |
| [INC-heartbeat-missing-env-file](../../scenarios/incidents/INC-heartbeat-missing-env-file/interview.md) | systemd | Partial/non-atomic rollouts |
| [INC-heartbeat-bad-dependency](../../scenarios/incidents/INC-heartbeat-bad-dependency/interview.md) | systemd | `Requires=` vs `Wants=`; dependency audits |

### 1. INC-heartbeat-crashloop — Reading a crash-looping service

**Q (troubleshooting):** A service keeps restarting and then goes down
entirely and stays down. Walk me through your debugging.
**A:** Check the process manager's own state first — restarting-then-
stopping is the signature of a deterministic failure being caught by
restart limiting, not a mystery. Go straight to the full log history
(not just the last line) and read the actual error.

**Q (system design):** Why do process managers limit restarts instead of
retrying forever?
**A:** Unlimited retries burn resources, flood logs, and mask an outage
behind a flapping state. Rate-limited restarts trade a few seconds of
detection latency for a stable, loud failure a human can act on — the
same tradeoff behind circuit breakers.

**Q (behavioral):** Tell me about debugging a production incident under
pressure. **A:** Checked the process manager's state before guessing;
pulled full logs instead of the last line; traced to a one-character
typo; fixed the root cause and cleared the process manager's lockout
state; wrote an RCA identifying the missing pre-deploy check.

### 2. INC-heartbeat-permission-denied — OS-level vs. app-level failure

**Q:** A service fails to start with no application-level error anywhere.
Where do you look? **A:** Absence of an app log line is itself a signal —
the process likely never got far enough to log anything. Check the layer
below the app: file permissions, missing binaries, the running user's
actual rights on the target file.

**Q (system design):** How do you prevent a maintenance script from
silently breaking a service's permissions? **A:** Scope bulk permission
changes as narrowly as possible, dry-run first, and pair any such
automation with an immediate post-run smoke test rather than waiting for
the next organic restart to surface a problem.

### 3. INC-heartbeat-masked — mask vs. disable

**Q:** Why does `systemctl mask` delete the unit file instead of just
disabling it? **A:** `mask` exists to hard-block a unit even against
dependency-triggered starts, implemented as a symlink to `/dev/null` —
which is exactly why unmasking alone doesn't restore a deleted original.
This is a direct argument for configuration living in source control, not
only on the box.

**Q (troubleshooting):** A restart command does nothing — no error, no
change. **A:** Check `LoadState` via `systemctl status`, specifically for
`masked` vs. `loaded` — a blocked start looks different from a failed one.

### 4. INC-heartbeat-wrong-user — reading systemd exit codes

**Q:** A service fails with exit status `217/USER`. What does that tell
you? **A:** systemd's numbered exit statuses encode *which step* failed —
`217`/`USER` means it failed resolving the configured user account,
before the executable ever ran. Narrows the search immediately to
`User=`/`Group=` and the system's user database.

### 5. INC-heartbeat-disk-full — health checks that lie

**Q:** Monitoring says healthy, but a user reports it's not doing its
job. **A:** Trust the direct evidence over the shallow check — a health
check is a proxy, and proxies can be wrong. Go straight to the service's
actual output.

**Q (system design):** Difference between a liveness check and a real
health check? **A:** Liveness proves the process is running and
responsive; it does not prove the process is doing its actual job.
Kubernetes' separate liveness/readiness probes exist for exactly this
distinction.

### 6. INC-heartbeat-log-permission-denied — recurring incidents

**Q:** How do you prioritize a prevention item that would have stopped a
*previous* incident, against new work? **A:** A repeat incident from an
un-implemented action item is measured evidence, not a hypothetical —
that should move it ahead of speculative new work.

### 7. INC-daily-report-cron-path — scheduler environment ≠ shell environment

**Q:** A scheduled job fails but the identical script works when run
manually. **A:** Treat this as an environment mismatch, not inconsistent
logic. Reproduce the scheduler's actual environment directly (its real
PATH, working directory, user context) rather than re-testing manually.

**Q (system design):** Why do cron/systemd/CI give jobs a different
environment than an interactive shell? **A:** Interactive shells load
human-convenience configuration; schedulers deliberately don't inherit
any of it, so behavior doesn't silently depend on whoever last logged in.

### 8. INC-daily-report-not-executable — exit code 126 vs. 127

**Q:** A scheduled script fails with exit code 126. What does that tell
you? **A:** 126 = found the file but couldn't execute it (permissions);
127 = couldn't find it at all (PATH). The distinction narrows the
investigation before you even open the file.

### 9. INC-logrotate-misconfigured — silent misconfiguration

**Q:** How do you verify a config is doing what it claims, not just that
it's syntactically valid? **A:** Use the tool's own dry-run/debug mode
(`logrotate -d`) rather than reading the config and reasoning about
intent by eye.

**Q (system design):** Why is silent-failure-on-misconfiguration more
dangerous than a loud error? **A:** A silent no-op is indistinguishable
from "nothing to do" — it requires deliberately verifying the positive
case, not just the absence of errors.

### 10. INC-heartbeat-port-conflict — shared-host contention

**Q:** A service fails with "address already in use." Resolve it safely.
**A:** Identify exactly what's holding the port and confirm what it is
*before* removing it — blindly killing an unknown PID on a shared host
risks turning one incident into two.

**Q (system design):** Why do containers/Pods avoid this whole class of
incident? **A:** Each workload gets its own network namespace, so port
collisions become structurally impossible rather than something policed
by convention.

### 11. INC-heartbeat-missing-env-file — partial rollouts

**Q:** No application-level error anywhere in the logs. First hypothesis?
**A:** The process was likely never launched — check the unit definition
itself (missing referenced files, bad directives) rather than assuming
an application bug.

**Q (system design):** Why would a rollout leave a system half-configured?
**A:** When a change spans multiple artifacts deployed as separate steps
rather than atomically, there's a window where the system observes a
partial state — the fix is true atomicity or tolerating the other's
absence.

### 12. INC-heartbeat-bad-dependency — Requires= vs Wants=

**Q:** A failure names a completely unrelated-sounding unit. Approach?
**A:** Take the error at face value — check the failing unit's own
`Requires=`/`After=` for a reference to what was named, rather than
searching elsewhere.

**Q (system design):** When should a unit use `Requires=` vs `Wants=`?
**A:** Reserve `Requires=` for genuine hard dependencies — its absence
should be an immediate, correct outage. Over-using it turns any future
decommission of the dependency into an unplanned outage rather than a
graceful degradation.

---

*Full Q&A with complete answer sketches lives in each scenario's own
`interview.md` (linked in the table above) — this chapter is the
quick-review version.*
