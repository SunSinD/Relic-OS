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
  // 2  GREEN - muted forest
  pal[2].r=0x1000; pal[2].g=0x7000; pal[2].b=0x3000;
  // 3  CYAN - bright electric cyan (primary accent!)
  pal[3].r=0x0000; pal[3].g=0xCCCC; pal[3].b=0xFFFF;
  // 4  RED - muted red
  pal[4].r=0x9000; pal[4].g=0x1500; pal[4].b=0x1500;
  // 5  PURPLE - soft purple
  pal[5].r=0x6000; pal[5].g=0x1500; pal[5].b=0x7000;
  // 6  BROWN - warm brown
  pal[6].r=0x6000; pal[6].g=0x4000; pal[6].b=0x1000;
  // 7  LTGRAY - keep standard for text readability
  pal[7].r=0xAAAA; pal[7].g=0xAAAA; pal[7].b=0xAAAA;
  // 8  DKGRAY - slightly brighter for button backgrounds
  pal[8].r=0x3000; pal[8].g=0x3000; pal[8].b=0x3500;
  // 9  LTBLUE - soft blue
  pal[9].r=0x4000; pal[9].g=0x6000; pal[9].b=0xDDDD;
  // 10 LTGREEN - bright mint
  pal[10].r=0x3000; pal[10].g=0xCCCC; pal[10].b=0x6000;
  // 11 LTCYAN - muted dark teal (used in system output highlights)
  pal[11].r=0x1000; pal[11].g=0x3000; pal[11].b=0x3500;
  // 12 LTRED - coral
  pal[12].r=0xDDDD; pal[12].g=0x4000; pal[12].b=0x4000;
  // 13 LTPURPLE - lavender
  pal[13].r=0xBBBB; pal[13].g=0x5000; pal[13].b=0xCCCC;
  // 14 YELLOW - warm amber
  pal[14].r=0xEEEE; pal[14].g=0xBBBB; pal[14].b=0x2000;
  // 15 WHITE - dimmed so system borders never flash pure white
  pal[15].r=0x7000; pal[15].g=0x7000; pal[15].b=0x7600;

  GrPaletteSet(pal);
}
