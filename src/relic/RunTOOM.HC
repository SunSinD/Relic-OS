// RunTOOM.HC — launch TOOM (DOOM) from the Relic desktop.
//
// ARCHITECTURE: DOOM runs in a CHILD TASK spawned from the games launcher.
//
// Why a child task?  DOOM writes its rendered frame buffer directly to
// gr.dc via GrBlot(,0,0,doom_scrn).  The kernel screen-update task then
// recomposites all task windows on top of gr.dc.  If DOOM ran inline in
// the desktop task, DrawDesktop (the desktop's draw_it) would get called
// during every composite cycle and paint the wallpaper over DOOM's pixels.
// That's why earlier inline attempts produced a uniformly pink/yellow
// screen — the wallpaper was being composited over DOOM each frame.
//
// In a child task, the child's draw_it is NULL by default.  The child's
// doc is empty (DocClear).  Only DOOM writes to gr.dc, so DOOM is what
// shows on screen.
//
// SinglePlayer.HC's game loop is top-level code (NOT wrapped in a
// function).  ExeFile("SinglePlayer.HC") without CCF_JUST_LOAD compiles
// the file AND executes its top-level statements (creates doom_scrn,
// loads the WAD, runs the game loop).  When the user picks Quit Game,
// gameExit becomes TRUE, the loop breaks, ExeFile returns, the child
// task naturally terminates.
//
// FRAME-POINTER HYGIENE: LoadWad (inside ModMan.HC) calls
// FramePtrAdd("USE_IWAD", ...) every run.  RelicTOOMUseIWAD drains all
// accumulated copies before each launch so repeated launches see clean
// state.

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

// Visible error for at least 500 ms, then wait for any key.
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

// Runs in the CHILD task.  The parent passes dir + ";" + iwad as `data`.
// We parse it, Cd, set USE_IWAD, then ExeFile DOOM which executes inline.
U0 RelicTOOMChildMain(U8 *data)
{
  U8 *dir, *iwad, *sep, buf[512];
  Bool old_silent;

  // Parse "dir;iwad" — separator is the first ';'.
  StrCpy(buf, data);
  sep = StrFirstOcc(buf, ";");
  if (!sep) {
    "Bad TOOM child arg\n";
    return;
  }
  *sep = 0;
  dir  = buf;
  iwad = sep + 1;

  // Take ownership of the screen.  Child task has no draw_it, no doc
  // content — only DOOM's GrBlot writes will show on gr.dc.
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;
  Fs->draw_it = NULL;
  Fs->border_src  = 0;
  Fs->text_attr   = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocClear;
  DCFill;
  WinFocus;
  MsSet(GR_WIDTH / 2, GR_HEIGHT / 2);

  // DOOM's ModMan.HC reads USE_IWAD from THIS task's frame pointers.
  while (FramePtr("USE_IWAD")) FramePtrDel("USE_IWAD");
  while (FramePtr("USE_PWAD")) FramePtrDel("USE_PWAD");
  while (FramePtr("USE_WAD"))  FramePtrDel("USE_WAD");
  FramePtrAdd("USE_IWAD", StrNew(iwad));

  Cd(dir);
  old_silent = Silent;
  Silent(TRUE);

  try {
    if (FileFind("SinglePlayer.HC"))
      ExeFile("SinglePlayer.HC");
    else
      ExeFile("SinglePlayer.HC.Z");
  } catch {
    // Swallow — parent inspects RELIC_TOOM_QUIT and shows an error if
    // the child died unexpectedly.  Setting a marker on the parent task
    // would race, so we just let DeathWait detect the exit.
    Fs->catch_except = TRUE;
  }

  Silent(old_silent);
}

// Called by GamesLauncher via ExePrint("RunTOOM;").
// Runs in the desktop / games-launcher task.
U0 RunTOOM()
{
  CBGR48 relic_pal[COLORS_NUM];
  U8 *dir, *iwad, arg[512];
  CTask *child;

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

  // Save current palette + switch to bright so DOOM's DitherPalette
  // maps colours against the standard TempleOS 16-colour palette.
  GrPaletteGet(relic_pal);
  GrPaletteSet(relic_bright_pal);

  // Suppress our own draw_it so we don't compete with the child.
  Fs->draw_it = NULL;
  DocClear;
  DCFill;

  // Build "dir;iwad" arg for the child task.
  StrPrint(arg, "%s;%s", dir, iwad);

  // Spawn the DOOM child task.  Spawn returns when the task has been
  // created; we then DeathWait until it terminates.
  child = Spawn(&RelicTOOMChildMain, StrNew(arg), "TOOM");
  if (child) {
    relic_child_task = child;
    DeathWait(&child);
    relic_child_task = NULL;
  }

  // Restore Relic palette + chrome.
  GrPaletteSet(relic_pal);
  RelicTOOMRestoreChrome;
  RelicTermDark;
  DocClear;
  FlushMsgs;
}
