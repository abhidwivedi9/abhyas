# INC-daily-report-not-executable: Daily report cron job has stopped producing output

> Severity: Sev-3 - Tier: L1 - Role: SRE on-call - Time-box: 15 min

## What the pager says

```
[FIRING] DailyReportStale - report.log on legacy-vm has not been updated
by its scheduled job in over 15 minutes.
```

## What the customer / stakeholder says

> "Someone was doing a permissions cleanup on /opt earlier today. The
> daily facility summary job might have gotten caught up in it."

## What you know

- Environment: legacy-vm (local lab)
- Job: daily_report.sh, scheduled every 5 minutes via cron
- Recent changes: a permissions cleanup ran across /opt earlier today

## Acceptance criteria

- [ ] The scheduled job succeeds and report.log is updating again
- [ ] grade.sh passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-daily-report-not-executable
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 10+ minutes? walkthrough.md is spoiler-gated.
