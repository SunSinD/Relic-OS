// RelicTheme.HC
// Refined palette for Relic OS
// Conservative changes - keeps readability, just softens harsh colors

U0 RelicThemeApply()
{
  CBGR48 pal[COLORS_NUM];

  MemSet(pal, 0, sizeof(CBGR48) * COLORS_NUM);

  // 0  BLACK - keep pure black (used for dark backgrounds)
  pal[0].r=0x0000; pal[0].g=0x0000; pal[0].b=0x0000;
  // 1  BLUE - set to black to hide kernel status bar background
  pal[1].r=0x0000; pal[1].g=0x0000; pal[1].b=0x0000;
  // 2  GREEN - dark olive; avoids neon DOOM flats
  pal[2].r=0x2000; pal[2].g=0x5200; pal[2].b=0x2400;
  // 3  CYAN - Relic accent, muted enough for TOOM
  pal[3].r=0x0000; pal[3].g=0x9000; pal[3].b=0xB800;
  // 4  RED - stronger DOOM red
  pal[4].r=0xB800; pal[4].g=0x0800; pal[4].b=0x0800;
  // 5  PURPLE - soft purple
  pal[5].r=0x6000; pal[5].g=0x1500; pal[5].b=0x7000;
  // 6  BROWN - warmer DOOM wall/floor tone
  pal[6].r=0xA000; pal[6].g=0x5200; pal[6].b=0x1000;
  // 7  LTGRAY - subdued readable gray
  pal[7].r=0x7800; pal[7].g=0x7800; pal[7].b=0x7400;
  // 8  DKGRAY - terminal/border gray
  pal[8].r=0x3800; pal[8].g=0x3800; pal[8].b=0x3A00;
  // 9  LTBLUE - subdued blue-gray
  pal[9].r=0x3000; pal[9].g=0x4800; pal[9].b=0x9000;
  // 10 LTGREEN - muted readable green
  pal[10].r=0x3800; pal[10].g=0x9000; pal[10].b=0x4800;
  // 11 LTCYAN - muted dark teal (used in system output highlights)
  pal[11].r=0x1000; pal[11].g=0x3000; pal[11].b=0x3500;
  // 12 LTRED - brighter blood/fire accent
  pal[12].r=0xFFFF; pal[12].g=0x3838; pal[12].b=0x2828;
  // 13 LTPURPLE - lavender
  pal[13].r=0xBBBB; pal[13].g=0x5000; pal[13].b=0xCCCC;
  // 14 YELLOW - warm amber
  pal[14].r=0xFFFF; pal[14].g=0xC800; pal[14].b=0x2800;
  // 15 WHITE - dark gray, never real white
  pal[15].r=0x2800; pal[15].g=0x2800; pal[15].b=0x2600;

  GrPaletteSet(pal);
}
