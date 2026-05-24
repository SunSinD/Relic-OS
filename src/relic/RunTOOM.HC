// RunTOOM.HC — launch TOOM (DOOM) from the Relic desktop.
//
// DESIGN NOTES:
//
// ExeFile("SinglePlayer.HC") WITHOUT CCF_JUST_LOAD:
//   - Compiles the file.
//   - Executes all TOP-LEVEL statements (global initializers):
//       doom_scrn = DCNew(GR_WIDTH, GR_HEIGHT)   <- in MainDrawer.HC
//       ModMan.HC reads USE_IWAD and calls LoadWad(iwad)
//   - Function DEFINITIONS (U0 TOOMStart() {...}) are compiled into the
//     task's code heap but are NOT called automatically.
//   - The compiled code stays in the task's code heap after ExeFile returns.
//
// After ExeFile we call ExePrint("TOOMStart;") explicitly.  TOOMStart
// finds doom_scrn and all WAD data already initialised, runs the game,
// and when the user quits calls TOOMStopTasks internally before returning.
//
// CCF_JUST_LOAD is intentionally NOT used: it skips global initializers,
// leaving doom_scrn==NULL and the WAD unloaded, causing a silent fault.
//
// FRAME-POINTER HYGIENE:
// LoadWad (inside ModMan.HC) calls FramePtrAdd("USE_IWAD",...) every time
// it runs.  RelicTOOMUseIWAD uses FramePtrDel which only removes the FIRST
// entry.  If we don't drain all copies before each launch the second attempt
// picks up a stale pointer and throws 'NoIWAD' silently.  We drain all
// copies with while-loops before every launch.

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
  // Drain ALL accumulated copies — LoadWad adds one per run,
  // FramePtrDel only removes the first, so we loop until gone.
  while (FramePtr("USE_IWAD")) FramePtrDel("USE_IWAD");
  while (FramePtr("USE_PWAD")) FramePtrDel("USE_PWAD");
  while (FramePtr("USE_WAD"))  FramePtrDel("USE_WAD");
  while (FramePtr("RELIC_TOOM_QUIT"))  FramePtrDel("RELIC_TOOM_QUIT");
  while (FramePtr("RELIC_TOOM_FRESH")) FramePtrDel("RELIC_TOOM_FRESH");
  while (FramePtr("RELIC_DOOM_SCRN"))  FramePtrDel("RELIC_DOOM_SCRN");
  if (iwad)
    FramePtrAdd("USE_IWAD", StrNew(iwad));
}

// Visible error for at least 500 ms, then wait for any key.
// ScanMsg loop so a stale Enter can't dismiss it instantly.
U0 RelicTOOMShowError(U8 *msg)
{
  I64 ec, ea, eb;
  // Force doc rendering so the error text is visible.  If draw_it is
  // pointing at DrawDesktop (or anything else), the compositor would
  // render that instead of the doc and the error would be invisible.
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

// Called by GamesLauncher via ExePrint("RunTOOM;").
// Runs inline in whatever task loaded us (the games launcher / desktop).
U0 RunTOOM()
{
  Bool old_silent;
  CBGR48 relic_pal[COLORS_NUM];
  U8 *dir, *iwad;
  U0 (*old_wall_paper)(CTask *);

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
  // DitherPalette() in DoomGr.HC calls GrPaletteGet at runtime to map DOOM's
  // 256 colours to the nearest TempleOS 16-colour entry.  With the Relic dark
  // palette active every DOOM pixel maps to YELLOW (the only bright, visible
  // colour left in the dark palette) — producing the solid-yellow screen.
  // Switch to the stock TempleOS palette NOW so DitherPalette sees the correct
  // 16 colours.  relic_pal already holds the dark palette and is restored after
  // DOOM exits.  relic_bright_pal is compiled by GamesLauncher.HC and is in the
  // task's symbol table when this code runs.
  GrPaletteSet(relic_bright_pal);

  old_silent = Silent;

  Cd(dir);
  RelicTOOMDarkWin;
  winmgr.show_menu = FALSE;
  DocClear;
  DCFill;
  RelicTOOMUseIWAD(iwad);

  // Activate DOOM compositor suppression BEFORE ExeFile.  When TRUE,
  // DrawDesktop returns immediately and does NOT touch the framebuffer.
  // DOOM owns every pixel and writes doom_scrn directly to gr.dc via
  // GrBlot(,0,0,doom_scrn) in its render loop.  This is DOOM's original
  // design — we just suppress the desktop chrome instead of trying to
  // re-point draw_it across the ExeFile heap boundary.
  relic_doom_active = TRUE;

  // Suppress the kernel status-bar wallpaper callback so DOOM owns every
  // pixel.  Saved so we can restore it when DOOM exits.
  old_wall_paper = gr.fp_wall_paper;
  gr.fp_wall_paper = NULL;

  try {
    FlushMsgs;
    RelicTOOMDarkWin;
    Silent(TRUE);

    // Step 1: compile SinglePlayer.HC.  This runs all top-level
    // initializers: doom_scrn = DCNew(...), LoadWad(iwad) in ModMan.HC,
    // and FramePtrAdd("RELIC_DOOM_SCRN", doom_scrn) in MainDrawer.HC.
    // TOOMStart is compiled into the task's code heap but NOT called yet.
    if (FileFind("SinglePlayer.HC"))
      ExeFile("SinglePlayer.HC");
    else
      ExeFile("SinglePlayer.HC.Z");

    // Step 2: explicitly call TOOMStart.  The compiled code is still in the
    // task's code heap, doom_scrn is valid, WAD is loaded.
    // TOOMStart runs the main menu + gameplay loop and calls TOOMStopTasks
    // internally before it returns.
    ExePrint("TOOMStart;");

    Silent(old_silent);
  } catch {
    Silent(old_silent);
    // Deactivate DOOM mode BEFORE showing any error message, otherwise
    // DrawDesktop will keep rendering doom_scrn (or fallback black) and
    // hide the error.  Also restore the palette so the error renders
    // with the correct Relic colours.
    relic_doom_active = FALSE;
    gr.fp_wall_paper = old_wall_paper;
    GrPaletteSet(relic_pal);
    // RELIC_TOOM_QUIT is set by TOOM's own Quit Game handler when the
    // user selects Quit Game from the menu — clean exit, no error.
    if (FramePtr("RELIC_TOOM_QUIT")) {
      FlushMsgs;
    } else {
      RelicTOOMShowError(
        "An exception occurred during DOOM startup or gameplay.\n"
        "Make sure doom1.wad (or freedoom1.wad) is a valid WAD file.");
    }
  }

  // Deactivate DOOM compositor suppression so DrawDesktop draws normally
  // again.  (No-op if catch already did it.)
  relic_doom_active = FALSE;

  // Restore the kernel status-bar wallpaper callback.
  gr.fp_wall_paper = old_wall_paper;

  // Restore Relic palette + chrome whether DOOM exited cleanly or not.
  GrPaletteSet(relic_pal);
  RelicTOOMRestoreChrome;
  RelicTermDark;
  DocClear;
  FlushMsgs;
}
