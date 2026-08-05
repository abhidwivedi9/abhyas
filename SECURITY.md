# Security Policy

Abhyas ships *intentional* vulnerabilities inside scenario injections
(`scenarios/**/inject.sh`). Those are the product, not bugs — but they must
only ever affect the learner's own sandboxed environment.

## Reporting a vulnerability

If you find a security issue in the platform itself (not an intentional
scenario fault) — e.g. a real secret committed to the repo, an injection that
escapes the sandbox, or a supply-chain issue in our CI — please **do not open
a public issue**. Use GitHub's private vulnerability reporting on this
repository instead.

We aim to acknowledge reports within 72 hours.

## Scope

- In scope: `tools/`, `ci/`, `platform/`, `aiops/`, anything that runs on a
  contributor's or learner's machine outside a scenario sandbox.
- Out of scope: intentional faults inside scenario definitions, provided they
  are confined to the scenario environment and documented.
