// RunTOOM.HC — launch TOOM (DOOM) from the Relic desktop.
//
// DESIGN: ExeFile("SinglePlayer.HC") with NO flags runs inline in the
// current task.  This is the same design as commit 23b66fd (the version
// that actually launched DOOM).
//
// Why no CCF_JUST_LOAD?  With CCF_JUST_LOAD TempleOS compiles the code
// but does NOT execute it, so:
//   - doom_scrn = DCNew(...)  never runs   -> doom_scrn is NULL
//   - ModMan.HC WAD load code never runs  -> WAD is not loaded
// TOOMStart then faults on doom_scrn==NULL and the child dies silently.
//
// Why no child task?  ExeFile (no flags) compiles + executes the file AND
// then frees the compiled code heap when it returns.  Any subsequent
// ExePrint("TOOMStopTasks;") fails because the code is gone.  TOOMStart
// already calls TOOMStopTasks internally, so we just need ExeFile to
// run it as the "last function" — which is exactly what ExeFile does when
// no CCF_JUST_LOAD flag is passed.

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

// Return the TOOM source dir, or NULL if not installed.
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

// Return IWAD filename (relative, caller must Cd first), or NULL.
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
  FramePtrDel("USE_IWAD");
  FramePtrDel("USE_PWAD");
  FramePtrDel("USE_WAD");
  if (iwad)
    FramePtrAdd("USE_IWAD", StrNew(iwad));
}

// Visible error for at least 500 ms, then wait for any key.
// ScanMsg loop so a stale Enter can't dismiss it instantly.
U0 RelicTOOMShowError(U8 *msg)
{
  I64 ec, ea, eb;
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

// Called by GamesLauncher via ExePrint("RunTOOM;").
// Runs inline in whatever task loaded us (the games launcher / desktop).
U0 RunTOOM()
{
  Bool old_silent;
  CBGR48 relic_pal[COLORS_NUM];
  U8 *dir, *iwad;

  dir  = RelicTOOMFindDir();
  iwad = RelicTOOMFindIWAD();

  if (!dir || !iwad) {
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

  GrPaletteGet(relic_pal);
  old_silent = Silent;

  Cd(dir);
  RelicTOOMDarkWin;
  winmgr.show_menu = FALSE;
  DocClear;
  DCFill;
  RelicTOOMUseIWAD(iwad);

  // ExeFile WITHOUT CCF_JUST_LOAD:
  //   1. Compiles SinglePlayer.HC (includes MainDrawer.HC, Wad.HC, …)
  //   2. Executes all global initializers inline:
  //        doom_scrn = DCNew(GR_WIDTH, GR_HEIGHT)
  //        ModMan.HC reads USE_IWAD and calls LoadWad(iwad)
  //   3. Calls TOOMStart as the last compiled function.
  //   4. TOOMStart runs the main menu + gameplay loop.
  //   5. When user presses Quit Game, TOOMStart calls TOOMStopTasks
  //      and returns.  ExeFile then returns here.
  try {
    FlushMsgs;
    RelicTOOMDarkWin;
    Silent(TRUE);
    if (FileFind("SinglePlayer.HC"))
      ExeFile("SinglePlayer.HC");
    else
      ExeFile("SinglePlayer.HC.Z");
    Silent(old_silent);
  } catch {
    Silent(old_silent);
    // RELIC_TOOM_QUIT is set by TOOM's own Quit Game handler.
    // If it is present the user quit cleanly — no error needed.
    if (FramePtr("RELIC_TOOM_QUIT")) {
      FramePtrDel("RELIC_TOOM_QUIT");
      FlushMsgs;
    } else {
      RelicTOOMShowError(
        "An exception occurred during DOOM startup or gameplay.\n"
        "Make sure doom1.wad (or freedoom1.wad) is a valid WAD file.");
    }
  }

  // Restore Relic palette + chrome whether DOOM exited cleanly or not.
  GrPaletteSet(relic_pal);
  RelicTOOMRestoreChrome;
  RelicTermDark;
  DocClear;
  FlushMsgs;
}
