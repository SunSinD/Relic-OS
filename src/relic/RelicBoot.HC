// RelicBoot.HC
// Relic OS Desktop Environment Startup
// Usage: #include "::/Home/RelicOS/RelicBoot.HC";

winmgr.show_menu = FALSE;
AutoComplete(OFF);
WinBorder(OFF);

RelicBootLog("RelicBoot: theme");
// Step 1: Apply dark color palette
#include "::/Home/RelicOS/RelicTheme.HC"
RelicThemeApply;

// Step 2: Install Relic status strip and chrome suppression helpers
#include "::/Home/RelicOS/RelicChrome.HC"
RelicChromeInstall;

// UserStartUp hands us a task with no DolDoc yet; give it a dark terminal
// so nothing below ever prints in raw mode, then strip the kernel menu and
// border doc from it.
if (!DocPut)
  DocTermNew;
RelicMenuOff;

RelicBootLog("RelicBoot: wallpaper");
// Step 3: Load wallpaper bitmap
#include "::/Home/RelicOS/RelicWallpaper.HC"
RelicWallpaperLoad;

RelicBootLog("RelicBoot: install check");
// Step 4: Live CD install offer (no-op on an installed system)
#include "::/Home/RelicOS/RelicInstall.HC"
if (RelicInstallPromptNeeded)
  RelicInstallPrompt;

// Step 4b: the host asked for an ISO build (tools\relic.ps1 iso).  Runs
// here, before the desktop exists, so no keystrokes have to be typed in.
U8 relic_build_path[32];
if (relic_dev_action == 2) {
  relic_dev_action = 1;
  StrPrint(relic_build_path, "%c:/Build.HC", relic_dev_drv);
  "$FG,CYAN$ISO build requested by the host: %s$FG$\n", relic_build_path;
  try {
    ExeFile(relic_build_path);
  } catch {
    Fs->catch_except = TRUE;
    "$FG,LTRED$ISO build failed.$FG$\n";
    PutExcept;
  }
}

RelicBootLog("RelicBoot: desktop");
// Step 5: Launch desktop
#include "::/Home/RelicOS/RelicDesktop.HC"
// Restart the desktop after an exception, but give up after 3 failures in
// a row within 10 s each, so a broken build falls back to the terminal in
// UserStartUp instead of spinning forever.
I64 relic_desktop_fails = 0;
F64 relic_desktop_t0;
while (relic_desktop_fails < 3) {
  relic_desktop_t0 = tS;
  try {
    winmgr.show_menu = FALSE;
    RelicDesktop;
  } catch {
    Fs->catch_except = TRUE;
    RelicBootLog("RelicBoot: desktop exception");
    if (tS - relic_desktop_t0 < 10.0)
      relic_desktop_fails++;
    else
      relic_desktop_fails = 1;
    PutExcept;
  }
  RelicDesktopRestore;
}
throw('RelicDsk');
