// RunTOOM.HC - Launches TOOM (DOOM) in an isolated child task.
//
// Robust against:
//   - Missing WAD file (clear message, blocking pause).
//   - TOOM source not installed (clear message).
//   - TOOM crashing on startup (post-mortem visible).
// On clean exit, restores the Relic palette + dark chrome.

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
  Fs->border_src = 0;
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
}

U0 RelicTOOMRestoreDark()
{
  RelicTermDark;
}

U8 *RelicTOOMFindIWAD()
{
  if (FileFind("::/Home/TOOM/doom1.wad"))
    return "doom1.wad";
  if (FileFind("::/Home/TOOM/DOOM1.WAD"))
    return "DOOM1.WAD";
  if (FileFind("::/Home/TOOM/freedoom1.wad"))
    return "freedoom1.wad";
  if (FileFind("::/Home/TOOM/FREEDOOM1.WAD"))
    return "FREEDOOM1.WAD";
  if (FileFind("::/Home/RelicOS/TOOM/doom1.wad"))
    return "doom1.wad";
  if (FileFind("::/Home/RelicOS/TOOM/freedoom1.wad"))
    return "freedoom1.wad";
  if (FileFind("::/Home/RelicOS/TOOM/FREEDOOM1.WAD"))
    return "FREEDOOM1.WAD";
  if (FileFind("::/Home/TOOM/doom2.wad"))
    return "doom2.wad";
  if (FileFind("::/Home/TOOM/DOOM2.WAD"))
    return "DOOM2.WAD";
  return NULL;
}

U0 RelicTOOMUseIWAD(U8 *iwad)
{
  FramePtrDel("USE_IWAD");
  FramePtrDel("USE_PWAD");
  FramePtrDel("USE_WAD");
  if (iwad)
    FramePtrAdd("USE_IWAD", StrNew(iwad));
}

U0 RelicTOOMReloadThemeChrome()
{
  if (FileFind("::/Home/RelicOS/RelicChrome.HC"))
    ExeFile("::/Home/RelicOS/RelicChrome.HC", CCF_JUST_LOAD);
  if (FileFind("::/Home/RelicOS/RelicTheme.HC"))
    ExeFile("::/Home/RelicOS/RelicTheme.HC", CCF_JUST_LOAD);
  ExePrint("RelicThemeApply;");
  ExePrint("RelicChromeInstall;");
}

// Pick the TOOM source directory that actually contains SinglePlayer.HC.
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

// Show a full-screen error inside DOOM's task and wait for a keypress.
U0 RelicTOOMError(U8 *title, U8 *body)
{
  RelicTermDark;
  DocClear;
  DCFill;
  "\n\n$FG,LTRED$%s$FG$\n\n", title;
  "$FG,LTGRAY$%s$FG$\n\n", body;
  "$FG,YELLOW$Press any key to return to the games menu...$FG$\n";
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  FlushMsgs;
  GetChar(NULL, FALSE);
}

// Runs inside the spawned "TOOM Task" child only.
U0 RelicTOOMChildMain()
{
  Bool old_silent = Silent;
  U8 *dir, *iwad;
  Bool quit_clean = FALSE;

  RelicTOOMDarkWin;
  winmgr.show_menu = FALSE;
  DocClear;
  DCFill;

  dir = RelicTOOMFindDir();
  if (!dir) {
    RelicTOOMError("TOOM source not installed.",
          "Reinstall DOOM by copying src/relic/TOOM/ into the VM and re-running Build.HC.");
    return;
  }

  iwad = RelicTOOMFindIWAD();
  if (!iwad) {
    RelicTOOMError("No DOOM WAD found.",
          "Put doom1.wad or freedoom1.wad in ::/Home/TOOM/ then re-run Build.HC.");
    return;
  }

  Cd(dir);
  RelicTOOMUseIWAD(iwad);

  try {
    FlushMsgs;
    RelicTOOMDarkWin;
    if (FileFind("SinglePlayer.HC"))
      ExeFile("SinglePlayer.HC", CCF_JUST_LOAD);
    else
      ExeFile("SinglePlayer.HC.Z", CCF_JUST_LOAD);
    FramePtrAdd("RELIC_TOOM_FRESH", StrNew("1"));
    ExePrint("TOOMStart;");
    Silent(old_silent);
    try { ExePrint("TOOMStopTasks;"); } catch { Fs->catch_except = TRUE; }
    quit_clean = TRUE;
  } catch {
    Silent(old_silent);
    try { ExePrint("TOOMStopTasks;"); } catch { Fs->catch_except = TRUE; }
    RelicTOOMError("DOOM crashed while starting.",
          "TOOM raised an exception. Verify that doom1.wad is a valid WAD file.");
    return;
  }

  if (quit_clean)
    FramePtrDel("RELIC_TOOM_QUIT");
}

U0 RunTOOM()
{
  CTask *task;
  Bool old_silent;
  CBGR48 relic_pal[COLORS_NUM];
  U8 *iwad, *dir;

  if (FileFind("::/Home/RelicOS/RelicTheme.HC"))
    ExeFile("::/Home/RelicOS/RelicTheme.HC", CCF_JUST_LOAD);

  // Parent-side fast preflight so we can show an inline error without
  // spawning a child task that might itself fail invisibly.
  dir = RelicTOOMFindDir();
  iwad = RelicTOOMFindIWAD();
  if (!dir || !iwad) {
    DocClear;
    DCFill;
    "\n\n$FG,LTRED$DOOM cannot launch.$FG$\n\n";
    if (!dir)
      "$FG,LTGRAY$Missing TOOM source at $FG,CYAN$::/Home/TOOM/$FG$\n";
    if (!iwad)
      "$FG,LTGRAY$Missing WAD: put $FG,CYAN$doom1.wad$FG,LTGRAY$ or $FG,CYAN$freedoom1.wad$FG,LTGRAY$ in $FG,CYAN$::/Home/TOOM/$FG$\n";
    "\n$FG,DKGRAY$Build.HC should copy TOOM + WAD automatically.$FG$\n\n";
    "$FG,YELLOW$Press any key to return to the games menu...$FG$\n";
    LBts(&Fs->display_flags, DISPLAYf_SHOW);
    WinZBufUpdate;
    FlushMsgs;
    GetChar(NULL, FALSE);
    return;
  }

  GrPaletteGet(relic_pal);
  old_silent = Silent;

  task = Spawn(&RelicTOOMChildMain, NULL, "TOOM Task", 0, Fs);
  task->border_src = 0;
  task->border_attr = BLACK << 4 | DKGRAY;
  task->text_attr = BLACK << 4 | LTGRAY;
  DeathWait(&task);

  Silent(old_silent);
  GrPaletteSet(relic_pal);
  RelicTOOMReloadThemeChrome;
  RelicTermDark;
  DocClear;
  FlushMsgs;
}
