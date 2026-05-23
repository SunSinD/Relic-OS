// RelicBoot.HC
// Relic OS Desktop Environment Startup
// Usage: #include "::/Home/RelicOS/RelicBoot.HC";

winmgr.show_menu = FALSE;
AutoComplete(OFF);
WinBorder(OFF);

// Step 1: Apply dark color palette
#include "::/Home/RelicOS/RelicTheme.HC"
RelicThemeApply;

// Step 2: Install Relic status strip
#include "::/Home/RelicOS/RelicChrome.HC"
RelicChromeInstall;

// Step 2: Load wallpaper bitmap
#include "::/Home/RelicOS/RelicWallpaper.HC"
RelicWallpaperLoad;

// Step 3: Launch desktop
#include "::/Home/RelicOS/RelicDesktop.HC"
while (TRUE) {
  try {
    winmgr.show_menu = FALSE;
    RelicDesktop;
  } catch {
    RelicDesktopRestore;
  }
  RelicDesktopRestore;
}
