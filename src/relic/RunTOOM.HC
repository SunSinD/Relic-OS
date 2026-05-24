// RunTOOM.HC - TOOM launch helpers.  Compiled into the desktop heap via
// #include from GamesLauncher.HC.  Launched inline with RelicDoomBegin/End.

U0 RelicTOOMDarkWin()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS -
        WIF_SELF_BORDER - WIF_FOCUS_TASK_MENU;
  WinFocus;
  MsSet(GR_WIDTH / 2, GR_HEIGHT / 2);
  Fs->border_src  = 0;
  Fs->text_attr   = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
}

U0 RelicTOOMRestoreChrome()
{
  if (FileFind("::/Home/RelicOS/RelicChrome.HC"))
    ExeFile("::/Home/RelicOS/RelicChrome.HC", CCF_JUST_LOAD);
  if (FileFind("::/Home/RelicOS/RelicTheme.HC"))
    ExeFile("::/Home/RelicOS/RelicTheme.HC", CCF_JUST_LOAD);
  ExePrint("RelicThemeApply;");
  ExePrint("RelicChromeInstall;");
}

U0 RelicTOOMPaletteVanilla()
{
  CBGR48 pal[COLORS_NUM];

  pal[BLACK].r=0x0000; pal[BLACK].g=0x0000; pal[BLACK].b=0x0000;
  pal[BLUE].r=0x0000;  pal[BLUE].g=0x0000;  pal[BLUE].b=0xA800;
  pal[GREEN].r=0x0000; pal[GREEN].g=0xA800; pal[GREEN].b=0x0000;
  pal[CYAN].r=0x0000;  pal[CYAN].g=0xA800;  pal[CYAN].b=0xA800;
  pal[RED].r=0xA800;   pal[RED].g=0x0000;   pal[RED].b=0x0000;
  pal[PURPLE].r=0xA800;pal[PURPLE].g=0x0000;pal[PURPLE].b=0xA800;
  pal[BROWN].r=0xA800; pal[BROWN].g=0x5400; pal[BROWN].b=0x0000;
  pal[LTGRAY].r=0xA800;pal[LTGRAY].g=0xA800;pal[LTGRAY].b=0xA800;
  pal[DKGRAY].r=0x5400;pal[DKGRAY].g=0x5400;pal[DKGRAY].b=0x5400;
  pal[LTBLUE].r=0x5400;pal[LTBLUE].g=0x5400;pal[LTBLUE].b=0xFCFC;
  pal[LTGREEN].r=0x5400;pal[LTGREEN].g=0xFCFC;pal[LTGREEN].b=0x5400;
  pal[LTCYAN].r=0x5400;pal[LTCYAN].g=0xFCFC;pal[LTCYAN].b=0xFCFC;
  pal[LTRED].r=0xFCFC; pal[LTRED].g=0x5400; pal[LTRED].b=0x5400;
  pal[LTPURPLE].r=0xFCFC; pal[LTPURPLE].g=0x5400; pal[LTPURPLE].b=0xFCFC;
  pal[YELLOW].r=0xFCFC; pal[YELLOW].g=0xFCFC; pal[YELLOW].b=0x5400;
  pal[WHITE].r=0xFCFC; pal[WHITE].g=0xFCFC; pal[WHITE].b=0xFCFC;

  GrPaletteSet(pal);
}

U8 *RelicTOOMFindDir()
{
  if (FileFind("::/Home/TOOM/SinglePlayer.HC") ||
        FileFind("::/Home/TOOM/SinglePlayer.HC.Z"))
    return "::/Home/TOOM";
  if (FileFind("::/Home/RelicOS/TOOM/SinglePlayer.HC") ||
        FileFind("::/Home/RelicOS/TOOM/SinglePlayer.HC.Z"))
    return "::/Home/RelicOS/TOOM";
  return NULL;
}

U8 *RelicTOOMFindIWAD()
{
  if (FileFind("::/Home/TOOM/doom1.wad"))     return "doom1.wad";
  if (FileFind("::/Home/TOOM/DOOM1.WAD"))     return "DOOM1.WAD";
  if (FileFind("::/Home/TOOM/freedoom1.wad")) return "freedoom1.wad";
  if (FileFind("::/Home/TOOM/FREEDOOM1.WAD")) return "FREEDOOM1.WAD";
  if (FileFind("::/Home/TOOM/doom2.wad"))     return "doom2.wad";
  if (FileFind("::/Home/TOOM/DOOM2.WAD"))     return "DOOM2.WAD";
  if (FileFind("::/Home/RelicOS/TOOM/doom1.wad"))     return "doom1.wad";
  if (FileFind("::/Home/RelicOS/TOOM/freedoom1.wad")) return "freedoom1.wad";
  return NULL;
}

U0 RelicTOOMUseIWAD(U8 *iwad)
{
  while (FramePtr("USE_IWAD")) FramePtrDel("USE_IWAD");
  while (FramePtr("USE_PWAD")) FramePtrDel("USE_PWAD");
  while (FramePtr("USE_WAD"))  FramePtrDel("USE_WAD");
  while (FramePtr("RELIC_TOOM_QUIT"))  FramePtrDel("RELIC_TOOM_QUIT");
  while (FramePtr("RELIC_TOOM_FRESH")) FramePtrDel("RELIC_TOOM_FRESH");
  while (FramePtr("RELIC_DOOM_SCRN"))  FramePtrDel("RELIC_DOOM_SCRN");
  if (iwad)
    FramePtrAdd("USE_IWAD", StrNew(iwad));
}

U0 RelicTOOMShowError(U8 *msg)
{
  I64 ec, ea, eb;
  Fs->draw_it = NULL;
  WinBorder(OFF);
  WinMax;
  WinFocus;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
  DocClear;
  DCFill;
  "\n\n$FG,LTRED$DOOM failed to start.$FG$\n\n";
  "$FG,LTGRAY$%s$FG$\n\n", msg;
  "$FG,YELLOW$Press any key to return to the games menu...$FG$\n";
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  Sleep(500);
  FlushMsgs;
  do {
    ec = ScanMsg(&ea, &eb, 1 << MSG_KEY_DOWN);
    if (!ec) Sleep(15);
  } while (!ec);
}

U0 RelicTOOMHideTextPlane()
{
  Fs->draw_it = NULL;
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocClear;
  DCFill;
}

U0 RunTOOM()
{
  Bool old_silent;
  CBGR48 saved_pal[COLORS_NUM];
  U8 *dir, *iwad;

  dir  = RelicTOOMFindDir();
  iwad = RelicTOOMFindIWAD();

  if (!dir || !iwad) {
    Fs->draw_it = NULL;
    DocClear;
    DCFill;
    "\n\n$FG,LTRED$DOOM cannot launch.$FG$\n\n";
    if (!dir)
      "$FG,LTGRAY$TOOM source missing. Re-run Build.HC.$FG$\n";
    if (!iwad)
      "$FG,LTGRAY$No WAD found. Copy doom1.wad to src/relic/TOOM/ on the host\n"
      "then rebuild the VHD with MakeVHD.ps1 and re-run Build.HC.$FG$\n";
    "$FG,YELLOW$\nPress any key to return...$FG$\n";
    LBts(&Fs->display_flags, DISPLAYf_SHOW);
    WinZBufUpdate;
    Sleep(500);
    FlushMsgs;
    {
      I64 ec2, ea2, eb2;
      do {
        ec2 = ScanMsg(&ea2, &eb2, 1 << MSG_KEY_DOWN);
        if (!ec2) Sleep(15);
      } while (!ec2);
    }
    return;
  }

  GrPaletteGet(saved_pal);
  RelicTOOMPaletteVanilla;
  old_silent = Silent;

  Cd(dir);
  RelicTOOMDarkWin;
  RelicTOOMHideTextPlane;
  RelicTOOMUseIWAD(iwad);
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocClear;
  DCFill;
  gr.fp_wall_paper = NULL;

  try {
    FlushMsgs;
    Silent(TRUE);
    if (FileFind("SinglePlayer.HC"))
      ExeFile("SinglePlayer.HC");
    else
      ExeFile("SinglePlayer.HC.Z");
    Silent(old_silent);
  } catch {
    Silent(old_silent);
    GrPaletteSet(saved_pal);
    if (FramePtr("RELIC_TOOM_QUIT")) {
      FlushMsgs;
    } else {
      RelicTOOMShowError(
        "An exception occurred during DOOM startup or gameplay.\n"
        "Make sure doom1.wad (or freedoom1.wad) is a valid WAD file.");
    }
  }

  GrPaletteSet(saved_pal);
  RelicTOOMRestoreChrome;
  DocClear;
  DCFill;
  FlushMsgs;
}

