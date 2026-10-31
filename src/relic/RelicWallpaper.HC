// RelicWallpaper.HC
// Loads wallpaper.raw from boot drive and displays it via GrBlot

CDC *relic_wp_dc = NULL;

U0 RelicWallpaperLoad()
{
  I64 size, i;
  U8 *data;

  // Load raw pixel data from file
  data = FileRead("::/Home/RelicOS/wallpaper.raw", &size);
  if (!data || size != 640 * 480) {
    if (data) Free(data);
    "Wallpaper missing or invalid; using solid black.\n";
    return;
  }

  // Create a 640x480 device context
  if (relic_wp_dc) DCDel(relic_wp_dc);
  relic_wp_dc = DCNew(640, 480);

  // Copy pixel data into the DC body.  The artwork is drawn in CYAN, which
  // the matte palette turns grey, so it moves to the LTGREEN slot that
  // RelicMatteApply keeps as the Reaper blue.
  MemCpy(relic_wp_dc->body, data, size);
  for (i = 0; i < size; i++)
    if (relic_wp_dc->body[i] == CYAN)
      relic_wp_dc->body[i] = LTGREEN;

  Free(data);
}

U0 RelicWallpaperDraw(CDC *dc)
{
  if (relic_wp_dc)
    GrBlot(dc, 0, 0, relic_wp_dc);
}
