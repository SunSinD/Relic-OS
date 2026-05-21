// Run the TOOM copy installed into the release ISO by Build.HC.
// No extern declarations — load theme/chrome files dynamically to avoid
// compile-time symbol resolution failures.

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
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
}

U0 RelicTOOMRestoreDark()
{
  Fs->text_attr = BLACK << 4 | LTGRAY;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

Bool RelicTOOMHandleCatch(Bool old_silent)
{
  Silent(old_silent);
  
  // Safely stop background tasks in case we exited via throw('Quit')
  try {
    ExePrint("TOOMStopTasks;");
  } catch {
    Fs->animate_task = NULL;
  }

  if (FramePtr("RELIC_TOOM_QUIT")) {
    FramePtrDel("RELIC_TOOM_QUIT");
    Snd;
    FlushMsgs;
    return TRUE;
  }

  RelicTOOMRestoreDark;
  DocClear;
  "$FG,LTRED$DOOM failed to start cleanly.$FG$\n";
  "$FG,DKGRAY$Returning to the desktop...$FG$\n";
  Sleep(1500);
  return FALSE;
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

U0 RelicTOOMReloadThemeChrome()
{
  // Reload theme and chrome into this task's symbol table,
  // then call the setup functions via ExePrint so we don't
  // need extern declarations that can fail at compile time.
  if (FileFind("::/Home/RelicOS/RelicChrome.HC"))
    ExeFile("::/Home/RelicOS/RelicChrome.HC", CCF_JUST_LOAD);
  if (FileFind("::/Home/RelicOS/RelicTheme.HC"))
    ExeFile("::/Home/RelicOS/RelicTheme.HC", CCF_JUST_LOAD);
  ExePrint("RelicThemeApply;");
  ExePrint("RelicChromeInstall;");
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
  DCFill;

  if (FileFind("::/Home/TOOM/SinglePlayer.HC") ||
      FileFind("::/Home/TOOM/SinglePlayer.HC.Z")) {
    found = TRUE;
    Cd("::/Home/TOOM");
    RelicTOOMDarkWin;
    DocClear;
    RelicTOOMUseIWAD;
    try {
      FlushMsgs;
      RelicTOOMDarkWin;
      Silent(TRUE);
      ExeFile("SinglePlayer.HC");
      Silent(old_silent);
      try { ExePrint("TOOMStopTasks;"); } catch {}
    } catch {
      RelicTOOMHandleCatch(old_silent);
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
      RelicTOOMDarkWin;
      Silent(TRUE);
      ExeFile("SinglePlayer.HC");
      Silent(old_silent);
      try { ExePrint("TOOMStopTasks;"); } catch {}
    } catch {
      RelicTOOMHandleCatch(old_silent);
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
    RelicTOOMDarkWin;
    try {
      FlushMsgs;
      Silent(TRUE);
      ExeFile("Load.HC");
      Silent(old_silent);
      try { ExePrint("TOOMStopTasks;"); } catch {}
    } catch {
      RelicTOOMHandleCatch(old_silent);
    }
    GrPaletteSet(relic_pal);
    RelicTOOMDarkWin;
  } else if (FileFind("::/Home/TOOM/Home/TOOM/Load.HC") ||
        FileFind("::/Home/TOOM/Home/TOOM/Load.HC.Z")) {
    found = TRUE;
    Cd("::/Home/TOOM/Home/TOOM");
    RelicTOOMDarkWin;
    DocClear;
    RelicTOOMDarkWin;
    try {
      FlushMsgs;
      Silent(TRUE);
      ExeFile("Load.HC");
      Silent(old_silent);
      try { ExePrint("TOOMStopTasks;"); } catch {}
    } catch {
      RelicTOOMHandleCatch(old_silent);
    }
    GrPaletteSet(relic_pal);
    RelicTOOMDarkWin;
  }

  if (!found) {
    RelicTOOMRestoreDark;
    "\n$FG,LTRED$TOOM is not installed in ::/Home/TOOM.$FG$\n";
    "$FG,LTGRAY$Rebuild the release with #include \"E:/Build.HC\";.$FG$\n\n";
    "$FG,DKGRAY$Returning to the launcher...$FG$\n";
    Sleep(1500);
  }

  // Restore Relic palette and reload theme/chrome via ExePrint
  // so we don't rely on extern symbols at compile time.
  GrPaletteSet(relic_pal);
  RelicTOOMReloadThemeChrome;
  RelicTOOMDarkWin;
  DocClear;
  DCFill;
}
