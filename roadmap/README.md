# Roadmap

Ideas and feedback are welcome: open an [issue](https://github.com/SunSinD/Relic-OS/issues)
or reply in the TempleOS Discord thread.

## Done (v0.4.0)

- Dark desktop with wallpaper, dock and a status bar (version, date, time, FPS)
- Dock apps: Files, Editor, Shell, Games, Tasks, Memory, SysInfo, Help
- Help page with a tribute to Terry A. Davis and a key list
- Games menu: DOOM (TOOM port) and the TempleOS games
- DOOM in colour at 30 fps in a VM, with mouse look
- Fast display driver for VMs (VMware SVGA II, Bochs VBE), plain VGA elsewhere
- Live CD with an install prompt
- Broken start-up code opens a terminal instead of the debugger
- Fixed a Titanium crash that is also in stock TempleOS

## Next (v0.5)

- [ ] Files: browse folders and open files in the Editor
- [ ] Editor: pick which file to open
- [ ] Shell: command history with Up/Down
- [ ] Dark colours for popups and the Editor
- [ ] Demo games full screen
- [ ] Dock: show which app was clicked

## Later

- [ ] Settings app (colours, wallpaper)
- [ ] Settings that stay after a reboot
- [ ] Boot splash screen
- [ ] DOOM music (needs a sound card driver)
- [ ] TempleCraft in the Games menu
- [ ] Automatic boot test (boot the ISO, take a screenshot, compare)

## Known issues

- Long Memory and Tasks reports scroll over the status bar
- Blank lines between Games menu sections don't show
- Shell: after a line of exactly 80 characters, the text stays shifted one column
- DOOM tan walls look greyish (16-colour limit)
- First boot after installing can be slow for about a minute in QEMU without acceleration

For developers: the dev loop and HolyC gotchas are in
[docs/vmware-workflow.md](../docs/vmware-workflow.md), every change is in
[CHANGELOG.md](../CHANGELOG.md).
