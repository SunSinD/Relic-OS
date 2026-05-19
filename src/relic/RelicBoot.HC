// RelicBoot.HC
// Relic OS Desktop Environment Startup
// Usage: #include "::/Home/RelicOS/RelicBoot.HC";

// Step 1: Apply dark color palette
#include "::/Home/RelicOS/RelicTheme.HC"
RelicThemeApply;

// Step 2: Load wallpaper bitmap
#include "::/Home/RelicOS/RelicWallpaper.HC"
RelicWallpaperLoad;

// Step 3: Launch desktop
#include "::/Home/RelicOS/RelicDesktop.HC"
RelicDesktop;
