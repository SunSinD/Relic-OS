# TempleOS Compatibility

Compatibility needs to be precise. Relic OS should avoid vague claims such as
"TempleOS compatible" without saying which behavior is compatible.

## Compatibility Areas

- Boot media.
- Disk images and filesystems.
- HolyC source behavior.
- System calls or kernel APIs.
- Graphics behavior.
- Keyboard and mouse behavior.
- Shell commands.
- Built-in applications and demos.

## Compatibility Labels

Use these labels in docs and issues:

- `required`: Must work for the first compatibility milestone.
- `targeted`: Planned, but not required for the current milestone.
- `unsupported`: Intentionally not supported.
- `unknown`: Needs research.

## Compatibility Test Format

Each compatibility claim should eventually have:

- Name.
- Upstream behavior.
- Relic OS expected behavior.
- Test image or source input.
- Pass/fail criteria.
