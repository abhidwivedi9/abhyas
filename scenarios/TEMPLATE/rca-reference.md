# RCA Reference — <scenario title>

> Model blameless postmortem. Compare your own RCA against this **after**
> resolving the incident. Graded per the rubric in
> `docs/handbooks/postmortem-rubric.md`.

## Incident summary

- **Incident:** INC-XXXX-NNNN
- **Severity / duration / user impact:** <e.g. Sev-2, 47 min, 3.1% of checkouts failed>
- **SLO impact:** <error budget consumed>

## Timeline (all times UTC)

| Time | Event |
|---|---|
| T+0 | <fault injected / first symptom> |
| T+2m | <first alert fired> |
| ... | ... |

## Root cause

<One paragraph. The actual mechanism, not the trigger. "The deploy" is a
trigger; "connection pool sized below peak concurrency, exhausted when retries
amplified load" is a root cause.>

## Contributing factors

- <gap in alerting/testing/review/process that let this happen or slowed response>

## What went well / what went poorly

- ✅ ...
- ❌ ...

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | <prevention> | prevent | <role> | P1 |
| 2 | <faster detection> | detect | <role> | P2 |
| 3 | <faster mitigation> | mitigate | <role> | P2 |
