# ADR 0001: Documentation-First Foundation

## Status

Accepted

## Context

Relic OS is starting as a TempleOS fork, but the project needs a stable base
before source code changes become useful. TempleOS has unusual architecture,
tooling, language design, and user interaction patterns. Importing or rewriting
code without a clear map would make future work harder to review.

## Decision

Relic OS will begin with documentation, repository structure, provenance
tracking, and architecture notes before large source imports or rewrites.

## Consequences

- Contributors have a clear starting point.
- Compatibility goals can be discussed before implementation.
- Imported source must include provenance and license notes.
- Early progress may look slower, but later code changes should be easier to
  review and maintain.
