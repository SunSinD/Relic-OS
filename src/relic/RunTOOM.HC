// Run the TOOM copy installed into the release ISO by Build.HC.
U0 RelicTOOMDarkWin()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS -
        WIF_SELF_BORDER;
  WinFocus;
  MsSet(GR_WIDTH / 2, GR_HEIGHT / 2);
  Fs->text_attr = BLACK << 4 | LTGRAY;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

U0 RelicTOOMGamePalette()
{
  CBGR48 pal[COLORS_NUM];

  MemSet(pal, 0, sizeof(CBGR48) * COLORS_NUM);
  pal[0].b=0x0000; pal[0].g=0x0000; pal[0].r=0x0000;
  pal[1].b=0x0000; pal[1].g=0x0000; pal[1].r=0x0000;
  pal[2].b=0x0000; pal[2].g=0xAAAA; pal[2].r=0x0000;
  pal[3].b=0xAAAA; pal[3].g=0xAAAA; pal[3].r=0x0000;
  pal[4].b=0x0000; pal[4].g=0x0000; pal[4].r=0xAAAA;
  pal[5].b=0xAAAA; pal[5].g=0x0000; pal[5].r=0xAAAA;
  pal[6].b=0x0000; pal[6].g=0x5555; pal[6].r=0xAAAA;
  pal[7].b=0xAAAA; pal[7].g=0xAAAA; pal[7].r=0xAAAA;
  pal[8].b=0x5555; pal[8].g=0x5555; pal[8].r=0x5555;
  pal[9].b=0xFFFF; pal[9].g=0x5555; pal[9].r=0x5555;
  pal[10].b=0x5555; pal[10].g=0xFFFF; pal[10].r=0x5555;
  pal[11].b=0xFFFF; pal[11].g=0xFFFF; pal[11].r=0x5555;
  pal[12].b=0x5555; pal[12].g=0x5555; pal[12].r=0xFFFF;
  pal[13].b=0xFFFF; pal[13].g=0x5555; pal[13].r=0xFFFF;
  pal[14].b=0x5555; pal[14].g=0xFFFF; pal[14].r=0xFFFF;
  pal[15].b=0xFFFF; pal[15].g=0xFFFF; pal[15].r=0xFFFF;

  GrPaletteSet(pal);
}

U0 RelicTOOMUseIWAD()
{
  FramePtrDel("USE_IWAD");
  FramePtrDel("USE_PWAD");
  FramePtrDel("USE_WAD");
  if (FileFind("doom1.wad"))
    FramePtrAdd("USE_IWAD", StrNew("doom1.wad"));
  else
    FramePtrAdd("USE_IWAD", StrNew("freedoom1.wad"));
}

U0 RunTOOM()
{
  Bool found = FALSE;
  Bool old_silent;
  CBGR48 relic_pal[COLORS_NUM];
  GrPaletteGet(relic_pal);
  old_silent = Silent;

  RelicTOOMDarkWin;
  winmgr.show_menu = FALSE;
  DocClear;

  if (FileFind("::/Home/TOOM/SinglePlayer.HC") ||
      FileFind("::/Home/TOOM/SinglePlayer.HC.Z")) {
    found = TRUE;
    Cd("::/Home/TOOM");
    RelicTOOMDarkWin;
    DocClear;
    RelicTOOMUseIWAD;
    try {
      FlushMsgs;
      RelicTOOMGamePalette;
      RelicTOOMDarkWin;
      Silent(TRUE);
      ExeFile("SinglePlayer.HC");
      Silent(old_silent);
    } catch {
      Silent(old_silent);
      DocClear;
      "$FG,LTRED$DOOM failed to start cleanly.$FG$\n";
      "$FG,DKGRAY$Returning to the desktop...$FG$\n";
      Sleep(1500);
    }
    GrPaletteSet(relic_pal);
    RelicTOOMDarkWin;
    DocClear;
  } else if (FileFind("::/Home/TOOM/Home/TOOM/SinglePlayer.HC") ||
        FileFind("::/Home/TOOM/Home/TOOM/SinglePlayer.HC.Z")) {
    found = TRUE;
    Cd("::/Home/TOOM/Home/TOOM");
    RelicTOOMDarkWin;
    DocClear;
    RelicTOOMUseIWAD;
    try {
      FlushMsgs;
      RelicTOOMGamePalette;
      RelicTOOMDarkWin;
      Silent(TRUE);
      ExeFile("SinglePlayer.HC");
      Silent(old_silent);
    } catch {
      Silent(old_silent);
      DocClear;
      "$FG,LTRED$DOOM failed to start cleanly.$FG$\n";
      "$FG,DKGRAY$Returning to the desktop...$FG$\n";
      Sleep(1500);
    }
    GrPaletteSet(relic_pal);
    RelicTOOMDarkWin;
    DocClear;
  } else if (FileFind("::/Home/TOOM/Load.HC") ||
        FileFind("::/Home/TOOM/Load.HC.Z")) {
    found = TRUE;
    Cd("::/Home/TOOM");
    RelicTOOMDarkWin;
    DocClear;
    RelicTOOMGamePalette;
    RelicTOOMDarkWin;
    try {
      FlushMsgs;
      Silent(TRUE);
      ExeFile("Load.HC");
      Silent(old_silent);
    } catch {
      Silent(old_silent);
      DocClear;
      "$FG,LTRED$DOOM failed to start cleanly.$FG$\n";
      "$FG,DKGRAY$Returning to the launcher...$FG$\n";
      Sleep(1500);
    }
    GrPaletteSet(relic_pal);
    RelicTOOMDarkWin;
  } else if (FileFind("::/Home/TOOM/Home/TOOM/Load.HC") ||
        FileFind("::/Home/TOOM/Home/TOOM/Load.HC.Z")) {
    found = TRUE;
    Cd("::/Home/TOOM/Home/TOOM");
    RelicTOOMDarkWin;
    DocClear;
    RelicTOOMGamePalette;
    RelicTOOMDarkWin;
    try {
      FlushMsgs;
      Silent(TRUE);
      ExeFile("Load.HC");
      Silent(old_silent);
    } catch {
      Silent(old_silent);
      DocClear;
      "$FG,LTRED$DOOM failed to start cleanly.$FG$\n";
      "$FG,DKGRAY$Returning to the launcher...$FG$\n";
      Sleep(1500);
    }
    GrPaletteSet(relic_pal);
    RelicTOOMDarkWin;
  }

  if (!found) {
    "\n$FG,LTRED$TOOM is not installed in ::/Home/TOOM.$FG$\n";
    "$FG,LTGRAY$Rebuild the release with #include \"E:/Build.HC\";.$FG$\n\n";
    "$FG,DKGRAY$Returning to the launcher...$FG$\n";
    Sleep(1500);
  }
}
