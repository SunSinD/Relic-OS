# Roadmap

Ideas and bug reports: open an [issue](https://github.com/SunSinD/Relic-OS/issues).

## Done (v0.5.0)

- Matte-black desktop with the Reaper wallpaper, taskbar and Start menu with search
- Browser, Files, Paint, Calculator, Calendar, Notes and Settings
- Settings that stay after a reboot
- 28 games, including DOOM, Tetris, Scorch, Sudoku and Chess
- Networking with plain HTTP pages
- Loading screen and automatic boot to the desktop
- Mouse works in VMware without capturing it
- Shell command history and a `help` command

## Next

- [ ] HTTPS in the Browser
- [ ] Graphical Tasks, Memory and System apps
- [ ] Image viewer and Paint with more tools
- [ ] Game thumbnails in the Games library

## Later

- [ ] 1080p desktop (the experimental build in `src/platform/`)
- [ ] Sound (DOOM music)
- [ ] TempleCraft in Games
- [ ] Automatic boot test for every release

## Known issues

- The screen is 640x480, so VMs that stretch the window make it look soft
- A few TempleOS games open their own plain windows (ToTheFront, Tree Checkers)
- Tasks, Memory and System show plain text reports
- QEMU without hardware acceleration is slow on the first boot after installing

Every change is in [CHANGELOG.md](../CHANGELOG.md).
