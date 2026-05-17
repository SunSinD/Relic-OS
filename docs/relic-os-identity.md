# Relic OS — Project Identity

## What Relic OS Is

Relic OS is an independent operating system built from the TempleOS source
code. It is not TempleOS. It is a fork that aims to become a practical,
daily-driver operating system.

## What Makes It Different From TempleOS

| Area              | TempleOS                          | Relic OS (goal)                       |
|-------------------|-----------------------------------|---------------------------------------|
| Purpose           | Personal religious OS             | General-purpose daily-driver OS       |
| Networking        | None                              | Planned (long-term)                   |
| Multi-user        | Single user                       | Single user (may revisit later)       |
| UI                | 16-color VGA, HolyC DolDoc        | Start same, modernize over time       |
| Shell             | HolyC REPL                        | HolyC REPL + improvements             |
| Startup message   | TempleOS branding                 | Relic OS branding                     |
| Identity          | TempleOS                          | Relic OS                              |

## What Stays The Same (For Now)

- HolyC as the primary language.
- The kernel, compiler, and filesystem are unchanged until tooling exists to
  safely modify and rebuild them.
- The boot process is the same as TempleOS V5.03.

## The Separation Line

The first visible difference from TempleOS will be the startup message.
Every subsequent change will be recorded in `CHANGELOG.md`.

## Guiding Principles

1. Never break boot.
2. One small change at a time.
3. Every change is tested in VMware before it is committed.
4. Every change is documented in `CHANGELOG.md`.

## Origin

Relic OS began as a fork of TempleOS V5.03, created by Terry A. Davis.
TempleOS is in the public domain. Relic OS original code is MIT licensed.
See `LICENSE` and `NOTICE.md`.
