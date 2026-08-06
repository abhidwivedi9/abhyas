# Interview Mapping — Cart service repeatedly restarting, customers losing cart contents

## Troubleshooting questions

Q: "A container keeps restarting. How do you determine if it's an
application bug or a resource/infrastructure problem?"

Strong answer sketch: Check the container runtime's own signals before
looking at application logs - docker inspect (or kubectl describe pod in
Kubernetes) exposes exactly how and why the container last terminated,
including whether the kernel OOM-killed it. A climbing restart count
combined with OOMKilled: true and no corresponding code deploy in the
change log points squarely at resource configuration, not application
logic - checking this first can save significant time versus starting
with application-level log diving.

## System design angle

Q: "How do you size memory limits for a containerized service safely?"

Strong answer sketch: Never guess or use a flat template value across
dissimilar services - measure actual usage under realistic load first
(via docker stats, or a monitoring system's historical data in
production), then add real headroom (commonly 2-3x observed peak, more
for services with unpredictable load patterns) rather than trimming
close to idle usage. Roll changes out gradually with a health check gate
rather than fleet-wide, so a bad value is caught on one instance instead
of taking down every replica simultaneously.

## Behavioral / STAR

Q: "Tell me about an incident caused by a well-intentioned
infrastructure change."

- S: A cost-optimization pass reduced container memory limits without
  first measuring actual usage, causing an immediate, sustained crash
  loop across the affected service.
- T: Restore service and identify why a routine optimization caused an
  outage instead of the intended savings.
- A: Used the container runtime's own crash signals (OOMKilled,
  RestartCount) to immediately rule out an application bug, corrected
  the limit with real headroom, and made the fix durable (updated the
  deployment config, not just the live running container).
- R: Fast recovery; RCA produced concrete process changes (measure before
  rightsizing, roll out gradually, gate on a health check) that prevent
  the same optimization-caused-outage pattern from recurring.
