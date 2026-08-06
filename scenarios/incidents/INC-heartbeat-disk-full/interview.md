# Interview Mapping — Heartbeat health check green, but on-call suspects it's actually stuck

## Troubleshooting questions

**Q:** "Your monitoring says a service is healthy, but a user reports it's
not actually doing its job. How do you approach this?"

**Strong answer sketch:** Trust the user's report over the shallow check —
a health check is a proxy for "the service is doing useful work," and
proxies can be wrong. Go straight to the actual output the service is
supposed to produce (here, the log) and verify it directly, rather than
re-checking the same health endpoint that already claimed everything's
fine. If the direct evidence contradicts the health check, the health
check itself is the next thing to investigate — what exactly does it
prove, and what does it *not* prove?

## System design angle

**Q:** "What's the difference between a liveness check and a real health
check, and why does it matter?"

**Strong answer sketch:** A liveness check answers "is the process still
running and responsive" — it catches crashes and hangs. It does *not*
answer "is the process successfully doing its actual job," which requires
checking domain-specific signals (here: is the log advancing; in a real
system: are messages being consumed, are writes succeeding, is the queue
draining). Kubernetes' separate liveness vs. readiness (and increasingly,
startup) probes exist for exactly this reason — this scenario is a
single-process illustration of the same underlying distinction, and a
strong answer should connect the two.

## Behavioral / STAR

**Q:** "Tell me about a time your monitoring told you everything was fine,
but it wasn't."

- **S:** A service's health check and process status both reported healthy
  throughout an incident where the service had actually stopped doing its
  real work, discovered only because someone happened to notice stale
  output.
- **T:** Confirm and fix the actual problem, and figure out why monitoring
  didn't catch it.
- **A:** Went past the health check to the service's real output, found a
  background thread had silently died from a disk-full error while the
  main thread stayed healthy, fixed the immediate cause (freed disk), and
  identified the health check itself as the deeper gap.
- **R:** Restored real functionality, not just a green check; RCA produced
  action items that improved detection for this entire class of "partially
  alive" failure, not just this one incident.
