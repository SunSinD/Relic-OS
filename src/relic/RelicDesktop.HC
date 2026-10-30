// RelicDesktop.HC - Relic OS Desktop Environment
//
// The desktop, dock and the small text apps run on this task.  The Shell
// (">_") runs as an independent child task (RelicShellTaskMain) so the
// desktop loop never blocks on it and can never dead-lock behind it.
// Games run inline on this task (see GamesLauncher.HC).

// ---- Constants ----
#define DOCK_H      34
#define DOCK_BTN_W  52
#define DOCK_BTN_H  24
#define DOCK_GAP    4
#define NUM_APPS    8
#define TOPBAR_H    14
#define DOCK_MARGIN 28

// WinMgr frames (~1 s) without a newly published DOOM frame before the
// presenter falls back to snapshotting doom_scrn directly.
#define RELIC_DOOM_STALE_MAX 30

// ---- Globals ----
I64 relic_ox = 0, relic_oy = 0;
I64 relic_w = 640, relic_h = 480;
I64 relic_pending_app = -1;

// Spawned shell task (child of the desktop). NULL when no shell is open.
CTask *relic_child_task = NULL;
// Set by the shell task right before it returns so the desktop can restore.
Bool relic_shell_done = FALSE;

// Set TRUE by RelicDoomBegin while SinglePlayer.HC is running inline.
// DrawDesktop then blits the last COMPLETE game frame instead of the
// wallpaper/dock so DOOM owns every pixel of the window.
Bool relic_doom_active = FALSE;
// Presentation buffer: copy of doom_scrn taken only when the game is not
// in the middle of drawing (RELIC_DOOM_BUSY frame ptr). Allocated once in
// the desktop heap and never freed so the WinMgr can never blit freed memory.
CDC *relic_doom_present = NULL;
I64 relic_doom_stale = 0;
I64 relic_doom_last_frames = -1;
F64 relic_doom_fps_t0 = 0;
I64 relic_doom_fps_frames = 0;

I64 app_colors[NUM_APPS] = {
  CYAN, CYAN, CYAN, LTBLUE,
  LTBLUE, LTBLUE, YELLOW,
  LTGREEN
};

extern U8 blkdev_text_attr[BDT_TYPES_NUM];
extern U8 drv_text_attr[3];

U8 relic_old_blkdev_text_attr[BDT_TYPES_NUM];
U8 relic_old_drv_text_attr[3];
Bool relic_drive_colors_saved = FALSE;

U8 app_icons[NUM_APPS][4] = {
  "Fi", "Ed", ">_", "Gm",
  "Tk", "Mm", "Si",
  "?"
};

U8 app_tips[NUM_APPS][16] = {
  "Files", "Editor", "Shell", "Games",
  "Tasks", "Memory", "SysInfo",
  "Help"
};

U0 RelicDriveColorsDark()
{
  I64 i;

  if (!relic_drive_colors_saved) {
    for (i = 0; i < BDT_TYPES_NUM; i++)
      relic_old_blkdev_text_attr[i] = blkdev_text_attr[i];
    for (i = 0; i < 3; i++)
      relic_old_drv_text_attr[i] = drv_text_attr[i];
    relic_drive_colors_saved = TRUE;
  }

  for (i = 0; i < BDT_TYPES_NUM; i++)
    blkdev_text_attr[i] = BLACK;
  drv_text_attr[0] = CYAN;
  drv_text_attr[1] = LTGRAY;
  drv_text_attr[2] = LTRED;
}

U0 RelicDriveColorsRestore()
{
  I64 i;

  if (relic_drive_colors_saved) {
    for (i = 0; i < BDT_TYPES_NUM; i++)
      blkdev_text_attr[i] = relic_old_blkdev_text_attr[i];
    for (i = 0; i < 3; i++)
      drv_text_attr[i] = relic_old_drv_text_attr[i];
  }
}

// Kernel chrome suppression (RelicMenuOff / RelicTermNew) lives in
// RelicChrome.HC, which is compiled before this file.

// ---- DOOM presentation (runs on the WinMgr task via draw_it) ----
U0 RelicDrawDoomFrame(CTask *task, CDC *dc)
{
  CDC *scrn = FramePtr("RELIC_DOOM_SCRN", task);
  CDC *front = FramePtr("RELIC_DOOM_FRONT", task);
  I64 *busy = FramePtr("RELIC_DOOM_BUSY", task);
  CDC *show = NULL;
  I64 frames = 0;

  // Bits above bit 0 of the busy word count frames TOOMPresent published.
  if (busy)
    frames = *busy >> 1;
  if (frames != relic_doom_last_frames) {
    relic_doom_last_frames = frames;
    relic_doom_stale = 0;
  } else
    relic_doom_stale++;

  if (front && frames && relic_doom_stale < RELIC_DOOM_STALE_MAX) {
    // Normal case: the last COMPLETE frame the game published.
    show = front;
  } else if (scrn && relic_doom_present &&
        scrn->width_internal == relic_doom_present->width_internal &&
        scrn->height == relic_doom_present->height) {
    // Fallback for any screen that draws without publishing frames:
    // snapshot doom_scrn while the game is not in the middle of a frame.
    if (!busy || !(*busy & 1))
      MemCpy(relic_doom_present->body, scrn->body,
            scrn->width_internal * scrn->height);
    show = relic_doom_present;
  } else if (scrn)
    show = scrn;

  if (busy && tS - relic_doom_fps_t0 >= 1.0) {
    relic_doom_fps = frames - relic_doom_fps_frames;
    relic_doom_fps_frames = frames;
    relic_doom_fps_t0 = tS;
  }

  // The window starts below the status row (pix_top = 8); shift the frame
  // up so DOOM's 480 rows line up with the screen and the HUD is not cut.
  if (show)
    GrBlot(dc, 0, -task->pix_top, show);
  else {
    dc->color = BLACK;
    GrRect(dc, 0, 0, dc->width, dc->height);
  }
}

// ---- Desktop draw_it (graphics layer) ----
U0 DrawDesktop(CTask *task, CDC *dc)
{
  I64 w = dc->width;
  I64 h = dc->height;
  I64 i, bx, by, wp_y;
  I64 dock_w, dock_x, dock_y;
  I64 mx, my, hover;
  I64 tw, tx, ty;

  winmgr.show_menu = FALSE;

  relic_w = w;
  relic_h = h;
  relic_ox = task->pix_left;
  relic_oy = task->pix_top;

  // DOOM mode: blit the last complete game frame and skip all desktop chrome.
  if (relic_doom_active) {
    RelicDrawDoomFrame(task, dc);
    return;
  }

  // The status strip itself lives on text row 0 (RelicStatusWallPaper,
  // drawn by the WinMgr).  Pad with black down to TOPBAR_H screen pixels,
  // then hang the wallpaper directly below it.
  wp_y = TOPBAR_H - relic_oy;
  if (wp_y < 0)
    wp_y = 0;
  dc->color = BLACK;
  GrRect(dc, 0, 0, w, wp_y);

  if (relic_wp_dc)
    GrBlot(dc, 0, wp_y, relic_wp_dc);
  else {
    dc->color = BLACK;
    GrRect(dc, 0, wp_y, w, h - wp_y);
  }

  // Dock background
  dock_w = NUM_APPS * (DOCK_BTN_W + DOCK_GAP) + DOCK_GAP + 16;
  dock_x = (w - dock_w) / 2;
  dock_y = h - DOCK_H - DOCK_MARGIN;

  dc->color = BLACK;
  GrRect(dc, dock_x, dock_y, dock_w, DOCK_H);

  // Dock borders
  dc->color = CYAN;
  GrLine(dc, dock_x + 4, dock_y, dock_x + dock_w - 4, dock_y);
  dc->color = DKGRAY;
  GrLine(dc, dock_x + 4, dock_y + DOCK_H - 1, dock_x + dock_w - 4, dock_y + DOCK_H - 1);
  GrLine(dc, dock_x, dock_y + 4, dock_x, dock_y + DOCK_H - 4);
  GrLine(dc, dock_x + dock_w - 1, dock_y + 4, dock_x + dock_w - 1, dock_y + DOCK_H - 4);

  // Dock buttons
  mx = ms.pos.x - relic_ox;
  my = ms.pos.y - relic_oy;

  for (i = 0; i < NUM_APPS; i++) {
    bx = dock_x + 8 + i * (DOCK_BTN_W + DOCK_GAP);
    by = dock_y + 5;
    hover = (mx >= bx && mx <= bx + DOCK_BTN_W &&
             my >= by && my <= by + DOCK_BTN_H);

    if (hover) {
      dc->color = app_colors[i];
      GrRect(dc, bx, by, DOCK_BTN_W, DOCK_BTN_H);
      dc->color = BLACK;
      GrPrint(dc, bx + 14, by + 8, app_icons[i]);

      tw = StrLen(app_tips[i]) * 8 + 12;
      tx = bx + (DOCK_BTN_W - tw) / 2;
      ty = dock_y - 20;
      dc->color = BLACK;
      GrRect(dc, tx, ty, tw, 16);
      dc->color = CYAN;
      GrLine(dc, tx, ty, tx + tw - 1, ty);
      dc->color = LTGRAY;
      GrPrint(dc, tx + 6, ty + 4, app_tips[i]);
    } else {
      dc->color = DKGRAY;
      GrRect(dc, bx, by, DOCK_BTN_W, DOCK_BTN_H);
      dc->color = app_colors[i];
      GrLine(dc, bx + 2, by, bx + DOCK_BTN_W - 2, by);
      dc->color = app_colors[i];
      GrPrint(dc, bx + 14, by + 8, app_icons[i]);
    }
  }

  dc->color = CYAN;
  GrPlot(dc, w / 2, dock_y + DOCK_H + 3);
  GrPlot(dc, w / 2 + 1, dock_y + DOCK_H + 3);
}

U0 RelicDocDark()
{
  RelicDriveColorsDark;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->border_src = BDS_CONST;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

// Borderless, maximised, focusable, menu inhibited.
U0 RelicWinFull()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;
}

U0 RelicDesktopMode()
{
  RelicWinFull;
  WinFocus;
  RelicDocDark;
  RelicMenuOff;
}

// Switch the desktop task into a fullscreen dark text terminal for an
// inline app.  draw_it is removed so the DolDoc text layer shows.
U0 RelicAppStart()
{
  Fs->draw_it = NULL;
  RelicWinFull;
  AutoComplete(OFF);
  Fs->border_src = BDS_CONST;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  WinFocus;
  RelicTermNew;
  RelicDocDark;
  DocClear;
  DCFill;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  FlushMsgs;
}

U0 RelicChildKill()
{
  if (relic_child_task && TaskValidate(relic_child_task))
    Kill(relic_child_task, FALSE);
  relic_child_task = NULL;
  relic_shell_done = FALSE;
}

// TRUE if t is anc or a descendant of anc.
Bool RelicTaskUnder(CTask *t, CTask *anc)
{
  I64 guard = 0;

  while (t && guard < 64) {
    if (!TaskValidate(t))
      return FALSE;
    if (t == anc)
      return TRUE;
    t = t->parent_task;
    guard++;
  }
  return FALSE;
}

// Kill any task on our CPU that has us as its parent, except the shell.
// This catches the kernel terminal spawned by Ctrl+Alt+T (and similar
// hotkeys) before it can hold focus and freeze the desktop.
// Returns TRUE if it killed anything.
Bool RelicKillRogueChildren()
{
  CTask *t, *next, *me = Fs;
  Bool killed = FALSE;

  t = me->next_task;
  while (t && t != me) {
    next = t->next_task;
    if (t != relic_child_task && t->parent_task == me) {
      try {
        Kill(t, FALSE);
        killed = TRUE;
      } catch {
        Fs->catch_except = TRUE;
      }
    }
    t = next;
  }
  return killed;
}

// Saved compositor state while DOOM runs inline.
U0 (*relic_saved_draw_it)(CTask *, CDC *) = NULL;

// Prepare screen for DOOM. DrawDesktop presents RELIC_DOOM_SCRN (published
// by MainDrawer.HC from the ExeFile compile) through relic_doom_present.
U0 RelicDoomBegin()
{
  if (!relic_doom_present) {
    relic_doom_present = DCNew(GR_WIDTH, GR_HEIGHT, Fs);
    relic_doom_present->flags |= DCF_NO_TRANSPARENTS;
  }
  DCFill(relic_doom_present, BLACK);
  relic_doom_stale = 0;
  relic_doom_last_frames = -1;
  relic_doom_fps_frames = 0;
  relic_doom_fps_t0 = tS;
  if (!relic_doom_active)
    relic_saved_draw_it = Fs->draw_it;
  relic_doom_active = TRUE;
  Fs->draw_it = &DrawDesktop;
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocClear;
  DCFill;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  FlushMsgs;
}

U0 RelicDoomEnd()
{
  // Flip the mode first so the WinMgr stops presenting before we unpublish.
  relic_doom_active = FALSE;
  relic_doom_fps = -1;
  Fs->draw_it = relic_saved_draw_it;
  relic_saved_draw_it = NULL;
  while (FramePtr("RELIC_DOOM_BUSY")) FramePtrDel("RELIC_DOOM_BUSY");
  while (FramePtr("RELIC_DOOM_SCRN")) FramePtrDel("RELIC_DOOM_SCRN");
  while (FramePtr("RELIC_DOOM_FRONT")) FramePtrDel("RELIC_DOOM_FRONT");
  FlushMsgs;
}

U0 RelicDesktopRestore()
{
  if (relic_doom_active)
    RelicDoomEnd;
  winmgr.show_menu = FALSE;
  relic_pending_app = -1;
  RelicThemeApply;
  RelicChromeInstall;
  RelicDesktopMode;
  DocClear;
  DCFill;
  Fs->draw_it = &DrawDesktop;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  FlushMsgs;
}

I64 RelicDockHit(I64 x, I64 y)
{
  I64 dock_w, dock_x, dock_y;
  I64 i, bx, by;

  dock_w = NUM_APPS * (DOCK_BTN_W + DOCK_GAP) + DOCK_GAP + 16;
  dock_x = (relic_w - dock_w) / 2;
  dock_y = relic_h - DOCK_H - DOCK_MARGIN;

  for (i = 0; i < NUM_APPS; i++) {
    bx = dock_x + 8 + i * (DOCK_BTN_W + DOCK_GAP);
    by = dock_y + 5;
    if (x >= bx && x <= bx + DOCK_BTN_W &&
        y >= by && y <= by + DOCK_BTN_H)
      return i;
  }

  return -1;
}

I64 RelicKeyApp(I64 ch)
{
  if (ch == 'f' || ch == 'F')
    return 0;
  if (ch == 'e' || ch == 'E')
    return 1;
  if (ch == 's' || ch == 'S')
    return 2;
  if (ch == 'g' || ch == 'G')
    return 3;
  if (ch == 't' || ch == 'T')
    return 4;
  if (ch == 'm' || ch == 'M')
    return 5;
  if (ch == 'i' || ch == 'I')
    return 6;
  if (ch == 'h' || ch == 'H' || ch == '?')
    return 7;
  return -1;
}

U0 RelicLaunchEditor()
{
  U8 *doc;
  U8 *init_str = "$BG,BLACK$$FG,LTGRAY$";
  doc = FileRead("B:/RelicNote.DD");
  if (!doc || !StrMatch("$BG,BLACK$", doc))
    FileWrite("B:/RelicNote.DD", init_str, StrLen(init_str));
  if (doc)
    Free(doc);
  // The editor gets a bordered window so its own title/[X] border doc is
  // drawn on the window frame (row 1) and never on the status strip.
  WinBorder(ON);
  WinMax;
  Fs->title_src = TTS_ED_FILENAME;
  Ed("B:/RelicNote.DD", DOF_DONT_TEXT_ATTR);
  Fs->title_src = TTS_LOCKED_CONST;
  StrCpy(Fs->task_title, "RelicOS");
}

// ---- Shell (independent child task) ----
U0 RelicShellPrompt()
{
  "\n$FG,LTGRAY$> $FG$";
}

U0 RelicShellExe(U8 *line)
{
  try {
    ExePrint("%s;", line);
  } catch {
    Fs->catch_except = TRUE;
    PutExcept;
  }
}

// Entry point of the spawned shell task.  Never blocks the desktop: the
// desktop only polls TaskValidate()/relic_shell_done while this runs.
// Esc or "exit" returns, which ends the task cleanly via Exit.
U0 RelicShellTaskMain(I64 arg)
{
  U8 line[1024];
  I64 len = 0, ch, sc, mc;
  Bool stop = FALSE;

  no_warn arg;

  Fs->draw_it = NULL;
  RelicWinFull;
  AutoComplete(OFF);
  Fs->border_src = BDS_CONST;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  RelicTermNew;
  StrCpy(Fs->task_title, "Relic Shell");
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
  DocClear;
  "$WW,1$"; // wrap long lines instead of scrolling the shell sideways
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  WinToTop(Fs);
  WinFocus(Fs);
  FlushMsgs;

  "$FG,YELLOW$Relic Shell$FG$\n";
  "$FG,DKGRAY$Run HolyC commands. Type $FG,YELLOW$exit$FG,DKGRAY$ or press $FG,YELLOW$Esc$FG,DKGRAY$ to return.$FG$\n";
  RelicShellPrompt;

  while (!stop) {
    mc = ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (!mc) {
      Sleep(10);
    } else if (ch == CH_ESC || ch == CH_SHIFT_ESC) {
      stop = TRUE;
    } else if (ch == '\n') {
      line[len] = 0;
      len = 0;
      "\n";
      if (!StrICmp(line, "exit"))
        stop = TRUE;
      else if (line[0])
        RelicShellExe(line);
      if (!stop)
        RelicShellPrompt;
    } else if (ch == CH_BACKSPACE) {
      if (len > 0) {
        len--;
        "%c", CH_BACKSPACE;
      }
    } else if (ch >= ' ' && ch < 127 && len < 1023) {
      line[len++] = ch;
      "%c", ch;
    }
  }

  FlushMsgs;
  relic_shell_done = TRUE;
}

// Spawn the shell as a child of the desktop and return immediately.
U0 RelicLaunchShell()
{
  RelicChildKill;
  relic_shell_done = FALSE;
  FlushMsgs;
  relic_child_task = Spawn(&RelicShellTaskMain, NULL, "Relic Shell", , Fs);
}

// Called by the desktop loop every tick while a shell task exists.
U0 RelicShellTick()
{
  I64 guard = 0;

  if (!relic_child_task)
    return;

  if (relic_shell_done || !TaskValidate(relic_child_task)) {
    // Let the child finish dying: the kernel resets the palette when the
    // focus task ends, so restore the theme only after it is gone.
    while (TaskValidate(relic_child_task) && guard < 100) {
      Sleep(10);
      guard++;
    }
    if (TaskValidate(relic_child_task))
      Kill(relic_child_task, FALSE);
    relic_child_task = NULL;
    relic_shell_done = FALSE;
    Sleep(20);
    RelicDesktopRestore;
    WinToTop(Fs);
    WinFocus;
    return;
  }

  // Keep the keyboard on the shell family (a Ctrl+Alt+T terminal or other
  // rogue task must not strand the user with an unfocused shell).
  if (!RelicTaskUnder(sys_focus_task, relic_child_task)) {
    WinToTop(relic_child_task);
    WinFocus(relic_child_task);
  }
  Sleep(30);
}

// Compile games launcher into the SAME heap as the desktop so internal
// calls never hit UndefinedExtern across ExeFile/CCF_JUST_LOAD boundaries.
#include "::/Home/RelicOS/GamesLauncher.HC"

U0 RelicWaitKey()
{
  I64 ec, ea, eb;

  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  do {
    ec = ScanMsg(&ea, &eb, 1 << MSG_KEY_DOWN);
    if (!ec)
      Sleep(15);
  } while (!ec);
}

U0 RelicLaunchGames()
{
  try {
    RelicGamesLauncher;
  } catch {
    Fs->catch_except = TRUE;
    "\n\n$FG,LTRED$Games launcher failed.$FG$\n\n";
    PutExcept;
    "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
    RelicWaitKey;
  }
}

U0 RelicAppFiles()
{
  "$FG,CYAN$=== Files ===$FG$\n\n";
  Dir;
  "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
  GetChar;
}

U0 RelicAppTasks()
{
  "$FG,CYAN$=== Task Report ===$FG$\n\n";
  TaskRep;
  "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
  GetChar;
}

U0 RelicAppMemory()
{
  "$FG,CYAN$=== Memory Report ===$FG$\n\n";
  MemRep;
  "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
  GetChar;
}

U0 RelicAppSysInfo()
{
  "$FG,CYAN$=== System Information ===$FG$\n\n";
  "$FG,LTGRAY$OS:        $FG,CYAN$RelicOS V0.4.0$FG$\n";
  "$FG,LTGRAY$Kernel:    $FG,CYAN$RelicOS V0.4.0$FG$\n";
  "$FG,LTGRAY$Resolution:$FG,CYAN$ 640x480$FG$\n";
  "$FG,LTGRAY$Colors:    $FG,CYAN$16-color (custom dark palette)$FG$\n\n";
  "$FG,LTGRAY$CPU Info:$FG$\n";
  CPURep;
  "\n$FG,LTGRAY$Disk Info:$FG$\n";
  RelicDriveColorsDark;
  DrvRep;
  RelicDriveColorsRestore;
  "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
  GetChar;
}

U0 RelicAppHelp()
{
  "$FG,CYAN$\n";
  "  =========================================\n";
  "   IN MEMORY OF TERRY A. DAVIS\n";
  "   December 15, 1969 - August 11, 2018\n";
  "  =========================================\n";
  "$FG$\n";
  "$FG,LTGRAY$  Terry Andrew Davis was an American programmer$FG$\n";
  "$FG,LTGRAY$  and the sole creator of TempleOS - the operating$FG$\n";
  "$FG,LTGRAY$  system that Relic OS is built upon and dedicated to.$FG$\n\n";
  "$FG,CYAN$  Who He Was$FG$\n";
  "$FG,DKGRAY$  -----------------------------------------$FG$\n";
  "  Terry was a brilliant, self-taught engineer who\n";
  "  spent over a decade building TempleOS entirely\n";
  "  alone - every line of code, every driver, the\n";
  "  compiler, the kernel, the graphics system, and\n";
  "  even the programming language (HolyC) itself.\n\n";
  "  He held a degree in Electrical Engineering and\n";
  "  previously worked at Ticketmaster as a systems\n";
  "  programmer before dedicating his life to his\n";
  "  magnum opus: a pure, ring-0, single-address-space\n";
  "  operating system he believed was built for God.\n\n";
  "$FG,CYAN$  His Work$FG$\n";
  "$FG,DKGRAY$  -----------------------------------------$FG$\n";
  "  TempleOS is a technical marvel. Running entirely\n";
  "  in kernel mode with no memory protection, it is\n";
  "  one of the few operating systems ever written\n";
  "  from scratch by a single person, including:\n\n";
  "$FG,LTGRAY$   - HolyC: a custom C variant with JIT compilation\n";
  "   - A full 64-bit protected-mode kernel\n";
  "   - DolDoc: a rich text/graphics document system\n";
  "   - A complete IDE, compiler, and assembler\n";
  "   - 640x480, 16-color VGA with custom graphics APIs\n";
  "   - The custom RedSea file system and disk drivers$FG$\n\n";
  "$FG,CYAN$  Relic OS$FG$\n";
  "$FG,DKGRAY$  -----------------------------------------$FG$\n";
  "  Relic OS is a modern fork of TempleOS, built as\n";
  "  a tribute to Terry's genius and vision. It aims\n";
  "  to bring a refined, usable desktop experience to\n";
  "  the foundation he created - while never forgetting\n";
  "  who made it all possible.\n\n";
  "$FG,CYAN$  \"Thou madest him to have dominion over the works\n";
  "   of thy hands.\" - Psalm 8:6$FG$\n\n";
  "$FG,DKGRAY$  Rest in peace, Terry. Your work lives on.\n\n";
  "$FG,CYAN$  Keys$FG$\n";
  "$FG,DKGRAY$  -----------------------------------------$FG$\n";
  "  Desktop:  F Files  E Editor  S Shell  G Games\n";
  "            T Tasks  M Memory  I SysInfo  H Help\n";
  "  DOOM:     W/S move, Left/Right turn, A/D strafe,\n";
  "            Ctrl fire, Space doors, Tab map, Esc menu\n";
  "  Ctrl+Alt+V  back to plain VGA (shows a crash screen\n";
  "              if the system ever freezes)\n\n";
  "$FG,DKGRAY$  Press any key to return to desktop...$FG$\n";
  GetChar;
}

// Returns TRUE when the app ran inline and the desktop must be restored now.
// The shell returns FALSE: it runs in its own task and the desktop loop
// restores when that task ends.
Bool LaunchApp(I64 idx)
{
  winmgr.show_menu = FALSE;

  if (idx == 2) {
    RelicLaunchShell;
    return FALSE;
  }

  RelicAppStart;
  if (idx == 0)
    RelicAppFiles;
  else if (idx == 1)
    RelicLaunchEditor;
  else if (idx == 3)
    RelicLaunchGames;
  else if (idx == 4)
    RelicAppTasks;
  else if (idx == 5)
    RelicAppMemory;
  else if (idx == 6)
    RelicAppSysInfo;
  else if (idx == 7)
    RelicAppHelp;
  return TRUE;
}

// ---- Main desktop loop ----
U0 RelicDesktop()
{
  I64 msg_code, arg1, arg2, i;

  SettingsPush;
  AutoComplete(OFF);
  RelicChromeInstall;
  RelicDesktopMode;
  DocClear;
  DCFill;
  Fs->draw_it = &DrawDesktop;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;

  while (TRUE) {
    winmgr.show_menu = FALSE;

    if (relic_child_task) {
      // Shell open: stay out of its way. No focus stealing, no blocking.
      RelicShellTick;
    } else {
      // Defensive: kernel hotkeys like Ctrl+Alt+T spawn a child user task
      // that steals focus. Kill any such child every tick so the desktop
      // can never be deadlocked behind one.
      if (RelicKillRogueChildren) {
        WinToTop(Fs);
        WinFocus;
        RelicDesktopRestore;
      }

      // Non-blocking message poll so we never deadlock waiting on a queue
      // when something else has focus.
      msg_code = ScanMsg(&arg1, &arg2,
            1 << MSG_KEY_DOWN | 1 << MSG_MS_L_DOWN);

      if (msg_code == MSG_KEY_DOWN) {
        if (arg1 == CH_ESC || arg1 == CH_SHIFT_ESC)
          RelicDesktopRestore;
        else if (arg1 >= ' ' && arg1 < 127)
          relic_pending_app = RelicKeyApp(arg1);
      } else if (msg_code == MSG_MS_L_DOWN) {
        relic_pending_app = RelicDockHit(arg1, arg2);
        if (relic_pending_app < 0)
          relic_pending_app = RelicDockHit(ms.pos.x - relic_ox,
                ms.pos.y - relic_oy);
      } else {
        // No message: yield, then reclaim the window. A rogue terminal
        // (child of Adam, not us) may have taken focus; WinToTop+WinFocus
        // restores the desktop within ~15ms so it can never stay frozen.
        Sleep(15);
        if (sys_focus_task != Fs) {
          WinToTop(Fs);
          WinFocus;
        }
      }

      if (relic_pending_app >= 0) {
        i = relic_pending_app;
        relic_pending_app = -1;
        FlushMsgs;
        if (LaunchApp(i))
          RelicDesktopRestore;
      }
    }
  }
}
