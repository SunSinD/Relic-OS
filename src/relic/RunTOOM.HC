// Run the TOOM copy installed into the release ISO by Build.HC.
U0 RelicTOOMDarkWin()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS -
        WIF_SELF_BORDER - WIF_FOCUS_TASK_MENU;
  MsSet(GR_WIDTH / 2, GR_HEIGHT / 2);
  Fs->text_attr = BLACK << 4 | LTGRAY;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
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
    FramePtrDel("USE_IWAD");
    FramePtrDel("USE_PWAD");
    FramePtrDel("USE_WAD");
    if (FileFind("doom1.wad"))
      FramePtrAdd("USE_IWAD", StrNew("doom1.wad"));
    else
      FramePtrAdd("USE_IWAD", StrNew("freedoom1.wad"));
    try {
      FlushMsgs;
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
    FramePtrDel("USE_IWAD");
    FramePtrDel("USE_PWAD");
    FramePtrDel("USE_WAD");
    if (FileFind("doom1.wad"))
      FramePtrAdd("USE_IWAD", StrNew("doom1.wad"));
    else
      FramePtrAdd("USE_IWAD", StrNew("freedoom1.wad"));
    try {
      FlushMsgs;
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
    ExeFile("Load.HC");
  } else if (FileFind("::/Home/TOOM/Home/TOOM/Load.HC") ||
        FileFind("::/Home/TOOM/Home/TOOM/Load.HC.Z")) {
    found = TRUE;
    Cd("::/Home/TOOM/Home/TOOM");
    RelicTOOMDarkWin;
    DocClear;
    ExeFile("Load.HC");
  }

  if (!found) {
    "\n$FG,LTRED$TOOM is not installed in ::/Home/TOOM.$FG$\n";
    "$FG,LTGRAY$Rebuild the release with #include \"E:/Build.HC\";.$FG$\n\n";
    "$FG,DKGRAY$Returning to the launcher...$FG$\n";
    Sleep(1500);
  }
}
