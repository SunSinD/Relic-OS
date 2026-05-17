# Contributing To Relic OS

Relic OS is documentation-first until the upstream source inventory, build
strategy, and compatibility goals are clear. Contributions should make the
project easier to understand, build, test, or maintain.

## Good First Contributions

- Improve subsystem documentation with links to exact source files or notes.
- Add research notes that explain how original TempleOS behavior works.
- Turn uncertain design questions into Architecture Decision Records.
- Add small tooling scripts that make local work repeatable.
- Improve test plans, emulator notes, or compatibility checklists.

## Contribution Rules

1. Keep changes scoped. A pull request should do one thing well.
2. Explain why the change exists, not only what changed.
3. Use an ADR for changes that affect architecture, compatibility, language, build tools, or repository layout.
4. Do not import third-party code without documenting its license and source.
5. Do not import upstream TempleOS code until the provenance checklist is complete.
6. Prefer clear markdown notes over private assumptions.

## Pull Request Checklist

- [ ] The change has a clear purpose.
- [ ] Documentation was added or updated where behavior changed.
- [ ] Any new source, asset, or dependency has provenance and license notes.
- [ ] Large design choices are captured in `docs/adr`.
- [ ] Tests or verification steps are listed, even if they are manual for now.

## Commit Style

Use short imperative commit subjects:

```text
Document boot handoff assumptions
Add source inventory template
Define first emulator test target
```

Avoid mixing formatting, planning, source imports, and design changes in one
commit.
