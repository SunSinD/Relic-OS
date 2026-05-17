# Security Policy

Relic OS is not ready for production use. It is an experimental operating
system fork in the documentation and planning phase.

## Supported Versions

No released version is currently supported for security use.

| Version | Supported |
| --- | --- |
| Unreleased foundation work | No |

## Reporting Security Issues

For now, open a private report through GitHub security advisories if available,
or contact the repository owner directly. Do not publish exploit details before
the issue is triaged.

## Security Direction

Security work should start with documentation before implementation:

- Define the threat model.
- Document privilege boundaries.
- Track boot chain assumptions.
- Record how code and dependencies enter the repository.
- Add tests for parser, filesystem, loader, and driver boundaries as they exist.
