# Drivers

Drivers should be documented as contracts between hardware, the kernel, and
user-visible behavior.

## First Driver Areas

- Display output.
- Keyboard input.
- Timer.
- Disk or block device.
- Serial output for debugging.

## Driver Record Template

For each driver, document:

- Hardware or emulator device.
- Initialization sequence.
- Interrupts used.
- Memory or port ranges used.
- Public API.
- Failure behavior.
- Test method.

## Rule

Do not add a driver without a documented way to test it in an emulator or on
clearly named hardware.
