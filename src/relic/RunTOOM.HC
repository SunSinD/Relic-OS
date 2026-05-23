// Run TOOM in an isolated child task so repeat launches do not corrupt the desktop.

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

Bool RelicTOOMHandleCatch(Bool old_silent)
{
  Silent(old_silent);

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
  "$FG,DKGRAY$Press any key...$FG$\n";
  GetChar(NULL, FALSE);
  return FALSE;
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

Bool RelicTOOMRunFromDir(U8 *dir, Bool *old_silent)
{
  U8 *iwad;
  U8 path[256];
  Bool ok = FALSE;

  StrPrint(path, "%s/SinglePlayer.HC", dir);
  if (!FileFind(path)) {
    StrPrint(path, "%s/SinglePlayer.HC.Z", dir);
    if (!FileFind(path))
      return FALSE;
  }

  Cd(dir);
  iwad = RelicTOOMFindIWAD();
  if (!iwad)
    return FALSE;

  RelicTOOMDarkWin;
  DocClear;
  DCFill;
  RelicTOOMUseIWAD(iwad);
  try {
    FlushMsgs;
    RelicTOOMDarkWin;
    if (FileFind("SinglePlayer.HC"))
      ExeFile("SinglePlayer.HC", CCF_JUST_LOAD);
    else
      ExeFile("SinglePlayer.HC.Z", CCF_JUST_LOAD);
    ExePrint("TOOMStart;");
    Silent(*old_silent);
    try { ExePrint("TOOMStopTasks;"); } catch {}
    ok = TRUE;
  } catch {
    RelicTOOMHandleCatch(*old_silent);
  }
  return ok;
}

// Runs inside the spawned "TOOM Task" child only.
U0 RelicTOOMChildMain()
{
  Bool old_silent = Silent;
  Bool found = FALSE;

  RelicTOOMDarkWin;
  winmgr.show_menu = FALSE;
  DocClear;
  DCFill;

  if (RelicTOOMRunFromDir("::/Home/TOOM", &old_silent))
    found = TRUE;
  else if (RelicTOOMRunFromDir("::/Home/RelicOS/TOOM", &old_silent))
    found = TRUE;
  else if (RelicTOOMRunFromDir("::/Home/TOOM/Home/TOOM", &old_silent))
    found = TRUE;

  if (!found) {
    RelicTOOMRestoreDark;
    DocClear;
    "$FG,LTRED$TOOM could not start in this task.$FG$\n";
    Sleep(500);
  }
}

U0 RunTOOM()
{
  CTask *task;
  Bool old_silent;
  CBGR48 relic_pal[COLORS_NUM];
  U8 *iwad;

  if (FileFind("::/Home/RelicOS/RelicTheme.HC"))
    ExeFile("::/Home/RelicOS/RelicTheme.HC", CCF_JUST_LOAD);

  iwad = RelicTOOMFindIWAD();
  if (!iwad) {
    DocClear;
    "\n\n$FG,LTRED$No DOOM WAD found.$FG$\n\n";
    "$FG,LTGRAY$Put $FG,CYAN$doom1.wad$FG,LTGRAY$ or $FG,CYAN$freedoom1.wad$FG,LTGRAY$ in:$FG$\n";
    "  ::/Home/TOOM/\n";
    "  ::/Home/RelicOS/TOOM/\n\n";
    "$FG,DKGRAY$On the host: copy WAD into src/relic/TOOM/,\n";
    "run MakeVHD.ps1, then Build.HC inside the VM.$FG$\n\n";
    "$FG,DKGRAY$Press any key to return to the games menu...$FG$\n";
    GetChar;
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
