// RunTOOM.HC — launch TOOM (DOOM) from the Relic desktop.
//
// KEY: ExeFile("SinglePlayer.HC") WITHOUT CCF_JUST_LOAD so that
//      all global initializers run at compile time:
//        - doom_scrn  = DCNew(GR_WIDTH, GR_HEIGHT)
//        - WAD loading in ModMan.HC (reads USE_IWAD frame pointer)
//      CCF_JUST_LOAD suppresses execution, leaving doom_scrn=NULL and
//      the WAD unloaded, which causes an immediate hardware fault.
//      ExeFile without the flag compiles + executes + auto-calls
//      TOOMStart (the last function in the file) in one step.

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

// Return the TOOM source directory, or NULL if not installed.
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

// Return IWAD filename (relative, in TOOM dir), or NULL if missing.
U8 *RelicTOOMFindIWAD()
{
  if (FileFind("::/Home/TOOM/doom1.wad"))    return "doom1.wad";
  if (FileFind("::/Home/TOOM/DOOM1.WAD"))    return "DOOM1.WAD";
  if (FileFind("::/Home/TOOM/freedoom1.wad")) return "freedoom1.wad";
  if (FileFind("::/Home/TOOM/FREEDOOM1.WAD")) return "FREEDOOM1.WAD";
  if (FileFind("::/Home/TOOM/doom2.wad"))    return "doom2.wad";
  if (FileFind("::/Home/TOOM/DOOM2.WAD"))    return "DOOM2.WAD";
  if (FileFind("::/Home/RelicOS/TOOM/doom1.wad"))    return "doom1.wad";
  if (FileFind("::/Home/RelicOS/TOOM/freedoom1.wad")) return "freedoom1.wad";
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

// Show an error for at least 500 ms, then wait for a key.
// Uses ScanMsg loop so a stale Enter from the menu can't dismiss it.
U0 RelicTOOMShowError(U8 *msg)
{
  I64 ec, ea, eb;
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
  Sleep(500);     // Minimum visible time
  FlushMsgs;      // Drain any stale keys from the menu
  do {
    ec = ScanMsg(&ea, &eb, 1 << MSG_KEY_DOWN);
    if (!ec) Sleep(15);
  } while (!ec);
}

// Runs inside the isolated child task spawned by RunTOOM().
U0 RelicTOOMChildMain()
{
  Bool old_silent = Silent;
  U8 *dir, *iwad;

  RelicTOOMDarkWin;
  winmgr.show_menu = FALSE;
  DocClear;
  DCFill;

  dir = RelicTOOMFindDir();
  if (!dir) {
    RelicTOOMShowError(
      "TOOM source not found in ::/Home/TOOM/\n"
      "Re-run Build.HC so it copies the TOOM files.");
    return;
  }

  iwad = RelicTOOMFindIWAD();
  if (!iwad) {
    RelicTOOMShowError(
      "No WAD file found in ::/Home/TOOM/\n"
      "Copy doom1.wad or freedoom1.wad to src/relic/TOOM/\n"
      "on the host and re-run Build.HC.");
    return;
  }

  Cd(dir);
  RelicTOOMUseIWAD(iwad);

  // ExeFile WITHOUT CCF_JUST_LOAD: this compiles SinglePlayer.HC,
  // executes all global initializers (DCNew for doom_scrn, WAD load
  // via ModMan.HC), defines TOOMStart, then auto-calls it as the last
  // function. When TOOMStart returns (user quit), ExeFile returns.
  try {
    FlushMsgs;
    RelicTOOMDarkWin;
    Silent(TRUE);
    if (FileFind("SinglePlayer.HC"))
      ExeFile("SinglePlayer.HC");
    else
      ExeFile("SinglePlayer.HC.Z");
    Silent(old_silent);
    // Clean up any TOOM sub-tasks left behind.
    try { ExePrint("TOOMStopTasks;"); } catch { Fs->catch_except = TRUE; }
  } catch {
    Silent(old_silent);
    try { ExePrint("TOOMStopTasks;"); } catch { Fs->catch_except = TRUE; }
    // RELIC_TOOM_QUIT is set by TOOM's Quit Game path — if present,
    // the user quit cleanly; no error needed.
    if (FramePtr("RELIC_TOOM_QUIT")) {
      FramePtrDel("RELIC_TOOM_QUIT");
      FlushMsgs;
      return;
    }
    RelicTOOMShowError(
      "TOOM raised an exception during startup or gameplay.\n"
      "Make sure doom1.wad (or freedoom1.wad) is valid.");
  }
}

U0 RunTOOM()
{
  CTask *task;
  CBGR48 relic_pal[COLORS_NUM];
  U8 *dir, *iwad;

  // Quick parent-side preflight — if files are missing we can show
  // the error right here without even spawning a child task.
  dir  = RelicTOOMFindDir();
  iwad = RelicTOOMFindIWAD();
  if (!dir || !iwad) {
    DocClear;
    DCFill;
    "\n\n$FG,LTRED$DOOM cannot launch.$FG$\n\n";
    if (!dir)
      "$FG,LTGRAY$Missing TOOM source. Re-run Build.HC.$FG$\n";
    if (!iwad)
      "$FG,LTGRAY$Missing WAD. Copy doom1.wad to src/relic/TOOM/ then re-run Build.HC.$FG$\n";
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

  GrPaletteGet(relic_pal);

  // Spawn an isolated child task — TOOM modifies global state heavily
  // (palette, DC, waits, sounds). Isolation lets us restore cleanly.
  relic_child_task = Spawn(&RelicTOOMChildMain, NULL, "TOOM Task", 0, Fs);
  relic_child_task->border_src  = 0;
  relic_child_task->border_attr = BLACK << 4 | DKGRAY;
  relic_child_task->text_attr   = BLACK << 4 | LTGRAY;
  DeathWait(&relic_child_task);
  relic_child_task = NULL;

  // Restore Relic palette + chrome after TOOM exits.
  GrPaletteSet(relic_pal);
  RelicTOOMRestoreChrome;
  RelicTermDark;
  DocClear;
  FlushMsgs;
}
