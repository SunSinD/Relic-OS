# Testing And Quality

Testing an operating system requires layers. Start small and automate what can
be automated.

## Test Layers

- Documentation structure checks.
- Formatting checks.
- Unit tests for host-side tools.
- Emulator boot smoke tests.
- Filesystem image tests.
- Compatibility tests against known programs or images.
- Regression tests for fixed bugs.

## First CI Goal

The first useful CI target should verify that the repo structure is intact and
that documentation required by the foundation phase exists. Later CI should
build and boot a minimal image in an emulator.

## Manual Verification Template

```text
Host:
Commit:
Command:
Expected:
Observed:
Logs:
```
