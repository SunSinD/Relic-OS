// RelicDesktop.HC - Relic OS Desktop Environment
// All apps run inline in the desktop task (no spawned child tasks
// for shell/games/etc.) so the TempleOS kernel chrome never appears.

// ---- Constants ----
#define DOCK_H      34
#define DOCK_BTN_W  52
#define DOCK_BTN_H  24
#define DOCK_GAP    4
#define NUM_APPS    8
#define TOPBAR_H    14
#define DOCK_MARGIN 28

// ---- Globals ----
I64 relic_ox = 0, relic_oy = 0;
I64 relic_w = 640, relic_h = 480;
I64 relic_pending_app = -1;
CTask *relic_child_task = NULL;

// Set TRUE by RunTOOM while SinglePlayer.HC is running inline.
// DrawDesktop blits doom_scrn (published as RELIC_DOOM_SCRN frame ptr
// by MainDrawer.HC) instead of wallpaper/dock so DOOM owns every pixel.
Bool relic_doom_active = FALSE;

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

  blkdev_text_attr[BDT_ATA] = BLACK;
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

// ---- Desktop draw_it (graphics layer) ----
U0 DrawDesktop(CTask *task, CDC *dc)
{
  CDateStruct ds;
  U8 buf[256];
  I64 w = dc->width;
  I64 h = dc->height;
  I64 i, bx, by;
  I64 dock_w, dock_x, dock_y;
  I64 mx, my, hover;

  winmgr.show_menu = FALSE;

  relic_w = w;
  relic_h = h;
  relic_ox = task->pix_left;
  relic_oy = task->pix_top;

  // DOOM mode — blit the live game framebuffer and skip ALL desktop chrome.
  if (relic_doom_active) {
    CDC *scrn = FramePtr("RELIC_DOOM_SCRN", task);
    if (scrn)
      GrBlot(dc, 0, 0, scrn);
    else {
      dc->color = BLACK;
      GrRect(dc, 0, 0, w, h);
    }
    return;
  }

  // Top strip (always black, status drawn on top)
  dc->color = BLACK;
  GrRect(dc, 0, 0, w, TOPBAR_H);

  // Wallpaper below status strip
  if (relic_wp_dc)
    GrBlot(dc, 0, TOPBAR_H, relic_wp_dc);
  else {
    dc->color = BLACK;
    GrRect(dc, 0, TOPBAR_H, w, h - TOPBAR_H);
  }

  // Status text drawn inline so it always appears
  Date2Struct(&ds, Now + local_time_offset);
  StrPrint(buf,
        "RelicOS V1.0.0 %3tZ %02d/%02d %02d:%02d:%02d FPS:%2tf",
        ds.day_of_week, "ST_DAYS_OF_WEEK", ds.mon, ds.day_of_mon,
        ds.hour, ds.min, ds.sec, winmgr.fps);
  dc->color = LTGRAY;
  GrPrint(dc, 6, 3, buf);

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

      I64 tw = StrLen(app_tips[i]) * 8 + 12;
      I64 tx = bx + (DOCK_BTN_W - tw) / 2;
      I64 ty = dock_y - 20;
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
  Fs->border_src = 0;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

U0 RelicDesktopMode()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;
  WinFocus;
  RelicDocDark;
}

// Switch desktop task into a fullscreen text-terminal mode (used by every inline app).
// Hides chrome by setting draw_it to NULL but suppressing all the kernel chrome we can.
U0 RelicAppStart()
{
  Fs->draw_it = NULL;
  winmgr.show_menu = FALSE;
  WinBorder(OFF);
  WinMax;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;
  Fs->border_src = 0;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  WinFocus;
  RelicDocDark;
  DocTermNew;
  RelicDocDark;
  DocClear;
  DCFill;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  FlushMsgs;
}

U0 RelicChildKill()
{
  if (relic_child_task && TaskValidate(relic_child_task)) {
    Kill(relic_child_task, FALSE);
    relic_child_task = NULL;
  }
}

// Kill any task on our CPU that has us as its parent.
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

// Saved compositor state while DOOM runs inline (RunTOOM calls via ExePrint).
U0 (*relic_saved_draw_it)(CTask *, CDC *) = NULL;
U0 (*relic_saved_fp_wall_paper)(CTask *) = NULL;

// Must be called from the RelicDesktop heap — sets draw_it to the REAL
// &DrawDesktop pointer.  RunTOOM must NOT assign draw_it itself because
// cross-heap function pointers cause WinMgr UndefinedExtern crashes.
U0 RelicDoomBegin()
{
  if (!relic_doom_active) {
    relic_saved_draw_it = Fs->draw_it;
    relic_saved_fp_wall_paper = gr.fp_wall_paper;
  }
  gr.fp_wall_paper = NULL;
  relic_doom_active = TRUE;
  Fs->draw_it = &DrawDesktop;
  DocClear;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  FlushMsgs;
}

U0 RelicDoomEnd()
{
  relic_doom_active = FALSE;
  while (FramePtr("RELIC_DOOM_SCRN")) FramePtrDel("RELIC_DOOM_SCRN");
  if (relic_saved_fp_wall_paper)
    gr.fp_wall_paper = relic_saved_fp_wall_paper;
  if (relic_saved_draw_it)
    Fs->draw_it = relic_saved_draw_it;
  relic_saved_draw_it = NULL;
  relic_saved_fp_wall_paper = NULL;
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
  RelicDocDark;
  DocClear;
  DCFill;
  RelicDesktopMode;
  Fs->draw_it = &DrawDesktop;
  Fs->draw_it(Fs, gr.dc);
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
  Ed("B:/RelicNote.DD", DOF_DONT_TEXT_ATTR);
}

// Inline shell — Esc or typing "exit" returns to desktop.
U0 RelicLaunchShell()
{
  U8 line[256];
  I64 len = 0, ch, sc, mc;
  Bool stop = FALSE;

  "$FG,YELLOW$Relic Shell$FG$\n";
  "$FG,DKGRAY$Run HolyC commands. Type $FG,YELLOW$exit$FG,DKGRAY$ or press $FG,YELLOW$Esc$FG,DKGRAY$ to return.$FG$\n\n";
  "$FG,LTGRAY$> $FG$";
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;

  while (!stop) {
    // Same hotkey defence as the desktop loop.
    if (RelicKillRogueChildren) {
      WinToTop(Fs);
      WinFocus;
    }

    mc = ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (!mc) {
      Sleep(15);
      WinToTop(Fs);
      WinFocus;
    } else if (ch == CH_ESC || ch == CH_SHIFT_ESC) {
      stop = TRUE;
    } else if (ch == '\n') {
      "\n";
      line[len] = 0;
      len = 0;
      if (!StrCmp(line, "exit") || !StrCmp(line, "Exit") ||
            !StrCmp(line, "EXIT")) {
        stop = TRUE;
      } else if (line[0]) {
        try {
          ExePrint("%s;", line);
        } catch {
          PutExcept;
        }
      }
      if (!stop) {
        "\n$FG,LTGRAY$> $FG$";
        LBts(&Fs->display_flags, DISPLAYf_SHOW);
        WinZBufUpdate;
      }
    } else if (ch == CH_BACKSPACE) {
      if (len > 0) {
        len--;
        // CH_BACKSPACE destructively removes the previous character
        // from the doc. Force an immediate screen refresh so the
        // erase is visible without waiting for the next auto-tick.
        "%c", CH_BACKSPACE;
        LBts(&Fs->display_flags, DISPLAYf_SHOW);
        WinZBufUpdate;
      }
    } else if (ch >= ' ' && ch < 127 && len < 255) {
      line[len++] = ch;
      "%c", ch;
      LBts(&Fs->display_flags, DISPLAYf_SHOW);
      WinZBufUpdate;
    }
  }
}

U0 RelicLaunchGames()
{
  if (!FileFind("::/Home/RelicOS/GamesLauncher.HC")) {
    "\n$FG,LTRED$GamesLauncher.HC not found in ::/Home/RelicOS.$FG$\n";
    "$FG,DKGRAY$Press any key to return...$FG$\n";
    GetChar;
    return;
  }
  ExeFile("::/Home/RelicOS/GamesLauncher.HC", CCF_JUST_LOAD);
  ExePrint("RelicGamesLauncher;");
}

U0 LaunchApp(I64 idx)
{
  winmgr.show_menu = FALSE;
  RelicAppStart;

  if (idx == 0) {
    "$FG,CYAN$=== Files ===$FG$\n\n";
    Dir;
    "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
    GetChar;
  } else if (idx == 1) {
    RelicLaunchEditor;
  } else if (idx == 2) {
    RelicLaunchShell;
  } else if (idx == 3) {
    RelicLaunchGames;
  } else if (idx == 4) {
    "$FG,CYAN$=== Task Report ===$FG$\n\n";
    TaskRep;
    "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
    GetChar;
  } else if (idx == 5) {
    "$FG,CYAN$=== Memory Report ===$FG$\n\n";
    MemRep;
    "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
    GetChar;
  } else if (idx == 6) {
    "$FG,CYAN$=== System Information ===$FG$\n\n";
    "$FG,LTGRAY$OS:        $FG,CYAN$RelicOS V1.0.0$FG$\n";
    "$FG,LTGRAY$Kernel:    $FG,CYAN$RelicOS V1.0.0$FG$\n";
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
  } else if (idx == 7) {
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
    "$FG,DKGRAY$  Press any key to return to desktop...$FG$\n";
    GetChar;
  }
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
  Fs->draw_it = &DrawDesktop;
  Fs->draw_it(Fs, gr.dc);
  WinZBufUpdate;

  while (TRUE) {
    winmgr.show_menu = FALSE;

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
          1 << MSG_KEY_DOWN | 1 << MSG_MS_L_DOWN | 1 << MSG_MS_MOVE);

    if (msg_code == MSG_KEY_DOWN) {
      if (arg1 == CH_ESC || arg1 == CH_SHIFT_ESC) {
        RelicChildKill;
        RelicDesktopRestore;
      } else if (arg1 >= ' ' && arg1 < 127) {
        relic_pending_app = RelicKeyApp(arg1);
      }
    } else if (msg_code == MSG_MS_L_DOWN) {
      relic_pending_app = RelicDockHit(arg1, arg2);
      if (relic_pending_app < 0)
        relic_pending_app = RelicDockHit(ms.pos.x - relic_ox,
              ms.pos.y - relic_oy);
    } else if (msg_code == MSG_MS_MOVE) {
      if (Fs->draw_it)
        Fs->draw_it(Fs, gr.dc);
    } else {
      // No message: yield CPU, then immediately reclaim our window on
      // top. Ctrl+Alt+T may spawn a terminal (child of Adam, not us) that
      // steals focus; WinToTop+WinFocus restores the desktop within ~15ms
      // regardless of the rogue task's parent, so it can never stay frozen.
      Sleep(15);
      WinToTop(Fs);
      WinFocus;
    }

    if (relic_pending_app >= 0) {
      i = relic_pending_app;
      relic_pending_app = -1;
      FlushMsgs;
      LaunchApp(i);
      RelicDesktopRestore;
    }
  }
}
