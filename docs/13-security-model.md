# Security Model

Relic OS does not currently claim a production security model. This document
exists so the project can be honest about risk and intentional about future
boundaries.

## Threat Model Draft

Document whether the system is expected to defend against:

- Malicious local programs.
- Malicious disk images.
- Malicious input files.
- Broken drivers.
- Network input if networking is ever added.
- Supply-chain attacks during build.

## Early Security Work

- Track provenance for all imported code.
- Keep build scripts reviewable.
- Prefer deterministic build steps.
- Add parser and filesystem tests before accepting untrusted images.
- Document privilege assumptions instead of implying safety.
