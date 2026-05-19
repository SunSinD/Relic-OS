// RelicWallpaper.HC
// Loads wallpaper.raw from boot drive and displays it via GrBlot

CDC *relic_wp_dc = NULL;

U0 RelicWallpaperLoad()
{
  I64 size;
  U8 *data;

  // Load raw pixel data from file
  data = FileRead("::/Home/RelicOS/wallpaper.raw", &size);
  if (!data) {
    "Failed to load wallpaper.raw\n";
    return;
  }

  // Create a 640x480 device context
  relic_wp_dc = DCNew(640, 480);

  // Copy pixel data into the DC body
  MemCpy(relic_wp_dc->body, data, size);

  Free(data);
}

U0 RelicWallpaperDraw(CDC *dc)
{
  if (relic_wp_dc)
    GrBlot(dc, 0, 0, relic_wp_dc);
}
