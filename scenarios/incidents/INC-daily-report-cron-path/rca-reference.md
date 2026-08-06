# RCA Reference — Daily report hasn't updated, but the script runs fine when I test it

## Incident summary

- Incident: INC-daily-report-cron-path
- Severity / duration / user impact: Sev-3, ~20 min, internal report
  freshness only, no customer-facing impact
- SLO impact: none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A helper tool is installed under /usr/local/bin and the report script is updated to call it |
| T+0 | The next scheduled cron run fails immediately (command not found), silently, no MTA configured to surface the failure by mail |
| T+~15m | report.log's staleness crosses the alert threshold |

## Root cause

daily_report.sh was changed to call a helper tool by name only, relying
on the caller's PATH to locate it. The helper lives under /usr/local/bin,
which is on a normal interactive shell's PATH by default on this distro,
but cron does not use an interactive shell's environment. Cron's own
default PATH (/usr/bin:/bin on Debian/Ubuntu) does not include
/usr/local/bin, so every cron-triggered run failed with "command not
found," while anyone testing the script by simply running it by hand saw
it work perfectly, the classic gap between how you test something and how
its real trigger actually invokes it.

## Contributing factors

- The change was tested only by running the script manually, never under
  cron's actual environment.
- The crontab entry has no explicit PATH=, so it silently inherits
  whatever minimal default cron itself uses.
- No mail transport is configured on this box, so cron's own failure
  notification (which would normally email the job's stderr) goes nowhere,
  the failure was genuinely invisible until staleness alerting caught it.

## What went well / what went poorly

- Good: staleness alerting on report.log caught the problem within the
  time-box, even without cron's own failure notification working.
- Bad: the change was validated only interactively, never against cron's
  actual invocation environment, this is a repeatable, fixable process gap.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Require any cron job change to be tested via an emulated cron PATH, not just run manually | prevent | Platform Engineer | P1 |
| 2 | Use full paths (or an explicit PATH= in the crontab) for any command a cron job depends on | prevent | Platform Engineer | P1 |
| 3 | Configure a local mail sink so cron job failures are at least visible in journalctl/syslog | detect | Platform Engineer | P2 |
