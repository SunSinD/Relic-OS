// RelicBoot.HC
// Relic OS Desktop Environment Startup
// Usage: #include "E:/RelicBoot.HC";

// Step 1: Apply dark color palette
#include "E:/RelicTheme.HC"
RelicThemeApply;

// Step 2: Load wallpaper bitmap
#include "E:/RelicWallpaper.HC"
RelicWallpaperLoad;

// Step 3: Launch desktop
#include "E:/RelicDesktop.HC"
RelicDesktop;
