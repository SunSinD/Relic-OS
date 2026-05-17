# Project Charter

## Mission

Relic OS exists to study TempleOS, preserve its unusual strengths, and turn the
work into a documented, buildable, and more usable experimental operating
system.

## Goals

- Make the codebase understandable to someone who did not write TempleOS.
- Preserve the ideas worth studying: immediacy, integrated tooling, graphics,
  shell interaction, and the feeling of a small personal system.
- Build a repeatable development environment with emulator-first testing.
- Modernize carefully where it improves usability, maintainability, or safety.
- Record design decisions before large rewrites happen.

## Non-Goals

- Do not claim production readiness early.
- Do not hide inherited limitations behind vague marketing language.
- Do not import source, assets, or dependencies without provenance.
- Do not chase every modern OS feature before the base system is understood.
- Do not rewrite subsystems without documenting the behavior being replaced.

## Engineering Principles

- Prefer small, reviewable changes.
- Prefer explicit subsystem boundaries.
- Prefer tests and emulator scripts over manual-only verification.
- Prefer clear documents over tribal knowledge.
- Prefer compatibility matrices over guesses.
