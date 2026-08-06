# Interview Mapping — Heartbeat service down, health checks failing

What this scenario trains you to answer, and what a strong answer sounds like.

## Troubleshooting questions

**Q:** "A service keeps restarting and then goes down entirely and stays
down. Walk me through your debugging."

**Strong answer sketch:** Start with what the process manager (systemd,
Kubernetes, whatever) itself reports — its state is ground truth about
*how* it's failing, before you even look at application logs. A restart
counter that keeps climbing every couple of seconds is the signature of a
deterministic failure (same error every time), not an intermittent one —
that already tells you *where* to look next: whatever changed most recently,
not "add more retries." From there, go straight to the full log/journal for
the failing process — not just the last line, the whole recent history — and
read the actual error, don't guess. The insight this scenario teaches: a
process manager restarting something over and over isn't noise to filter
out, it's diagnostic information about the shape of the failure.

## System design angle

**Q:** "Why do process managers like systemd or Kubernetes cap or back off
automatic restarts instead of retrying forever?"

**Strong answer sketch:** Unlimited automatic restarts of a deterministically
failing process burns CPU/IO in a tight loop, floods logs (making the real
signal harder to find), and can mask an outage behind a flapping "kind of up"
state that's worse for downstream health checks than a clean "down." Rate-
limited or backed-off restarts (systemd's `StartLimitBurst`/
`StartLimitIntervalSec`, Kubernetes' exponential CrashLoopBackOff) trade a
little extra detection latency for a stable, loud failure signal a human or
alert can act on — and this scenario's own box shows why that configuration
matters: without a restart-limit *action* wired up, the crash loop just runs
forever rather than escalating. This is the same tradeoff behind circuit
breakers in distributed systems — fail fast and loud beats retry forever and
quiet.

## Behavioral / STAR

**Q:** "Tell me about a time you debugged a production incident under pressure."

Having actually run this scenario, your STAR answer writes itself:
- **S:** A health check started failing; the pager fired for a service that
  was reported down, with a recent deploy as the only lead.
- **T:** As on-call, restore the service and confirm it's genuinely stable —
  not just report it "fixed" after one restart.
- **A:** Checked the process manager's own state first (`systemctl status`)
  rather than blindly restarting; pulled the full log history
  (`journalctl -u heartbeat`) to get the actual error instead of guessing;
  traced it to a one-character typo in an import statement from the recent
  deploy; fixed the root cause, not the symptom — and knew to clear the
  process manager's failure-lockout state before it would even try again.
- **R:** Service restored and verified stable (not just restarted once);
  wrote the RCA identifying the missing pre-deploy validation as the real
  gap, and logged a concrete prevention action item rather than just
  closing the ticket.
