// RelicDesktop.HC - Relic OS Desktop Environment
// Dark dock launcher with wallpaper, direct app execution

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

// ---- Drawing (defined first — HolyC requires it) ----
U0 DrawDesktop(CTask *task, CDC *dc)
{
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

  // Wallpaper
  if (relic_wp_dc)
    GrBlot(dc, 0, 0, relic_wp_dc);
  else {
    dc->color = BLACK;
    GrRect(dc, 0, 0, w, h);
  }

  // Top bar
  dc->color = BLACK;
  GrRect(dc, 0, 0, w, TOPBAR_H);
  dc->color = CYAN;
  GrPrint(dc, 6, 3, "Relic OS");
  dc->color = DKGRAY;
  GrPrint(dc, 80, 3, "|");
  dc->color = LTGRAY;
  GrPrint(dc, 96, 3, "Desktop");
  dc->color = DKGRAY;
  GrLine(dc, 0, TOPBAR_H, w, TOPBAR_H);

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

      // Tooltip
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

  // Center dot
  dc->color = CYAN;
  GrPlot(dc, w / 2, dock_y + DOCK_H + 3);
  GrPlot(dc, w / 2 + 1, dock_y + DOCK_H + 3);
}

U0 RelicDocDark()
{
  Fs->text_attr = BLACK << 4 | LTGRAY;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

U0 RelicDesktopMode()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS -
        WIF_SELF_BORDER - WIF_FOCUS_TASK_MENU;
  WinFocus;
  RelicDocDark;
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

// ---- Launch handler ----
// Runs apps directly in the desktop task.
// Pauses wallpaper, runs the app, then resumes.
U0 LaunchApp(I64 idx)
{
  Fs->draw_it = NULL;
  winmgr.show_menu = FALSE;
  RelicDocDark;
  DocClear;
  RelicDocDark;

  switch (idx) {
    case 0:  // Files
      "\n\n$FG,CYAN$=== Files ===$FG$\n\n";
      Dir;
      "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
      GetChar;
      break;

    case 1:  // Editor
      // Edit in RAM drive (B:) to prevent Read-Only crashes on LiveCD
      U8 *doc = FileRead("B:/RelicNote.DD");
      if (!doc || !StrMatch("$BG,BLACK$", doc)) {
        U8 *init_str = "$BG,BLACK$$FG,LTGRAY$";
        FileWrite("B:/RelicNote.DD", init_str, StrLen(init_str));
      }
      if (doc) Free(doc);
      Ed("B:/RelicNote.DD", DOF_DONT_TEXT_ATTR);
      break;

    case 2:  // Shell (interactive mini-shell)
      "\n\n$FG,CYAN$=== Relic Shell ===$FG$\n";
      "$FG,DKGRAY$Type HolyC commands. Type 'exit' to return to desktop.$FG$\n\n";
      U8 *cmd;
      while (TRUE) {
        cmd = GetStr("relic> ");
        if (!StrCmp(cmd, "exit")) {
          Free(cmd);
          break;
        }
        try {
          ExePrint("%s;", cmd);
        } catch {
          "$FG,RED$Error running command.$FG$\n";
        }
        Free(cmd);
      }
      break;

    case 3:  // Games
      if (FileFind("::/Home/RelicOS/GamesLauncher.HC")) {
        try {
          ExeFile("::/Home/RelicOS/GamesLauncher.HC", CCF_JUST_LOAD);
          ExePrint("RelicGamesLauncher;");
        } catch {
          "\n$FG,LTRED$Games launcher failed to compile/run.$FG$\n";
          "$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
          GetChar;
        }
      } else {
        "\n$FG,LTRED$GamesLauncher.HC not found in ::/Home/RelicOS.$FG$\n";
        "$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
        GetChar;
      }
      break;

    case 4:  // Tasks
      "\n\n$FG,CYAN$=== Task Report ===$FG$\n\n";
      TaskRep;
      "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
      GetChar;
      break;

    case 5:  // Memory
      "\n\n$FG,CYAN$=== Memory Report ===$FG$\n\n";
      MemRep;
      "\n$FG,DKGRAY$Press any key to return to desktop...$FG$\n";
      GetChar;
      break;

    case 6:  // System Info
      "\n\n$FG,CYAN$=== System Information ===$FG$\n\n";
      "$FG,LTGRAY$OS:        $FG,CYAN$Relic OS v0.1$FG$\n";
      "$FG,LTGRAY$Kernel:    $FG,CYAN$TempleOS V5.03$FG$\n";
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
      break;

    case 7:  // Help - Terry Davis Tribute
      DocClear;
      "\n\n$FG,CYAN$\n";
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
      break;

  }

  DocClear;
  RelicDesktopMode;
  Fs->draw_it = &DrawDesktop;
  winmgr.show_menu = FALSE;
}

// ---- Main loop (runs forever as default shell) ----
U0 RelicDesktop()
{
  I64 msg_code, arg1, arg2, i;

  SettingsPush;
  AutoComplete(OFF);
  RelicDesktopMode;
  DocClear;
  Fs->draw_it = &DrawDesktop;

  while (TRUE) {
    winmgr.show_menu = FALSE;
    msg_code = GetMsg(&arg1, &arg2, 1 << MSG_KEY_DOWN | 1 << MSG_MS_L_DOWN);
    switch (msg_code) {
      case MSG_KEY_DOWN:
        relic_pending_app = RelicKeyApp(arg1);
        break;

      case MSG_MS_L_DOWN:
        relic_pending_app = RelicDockHit(arg1, arg2);
        if (relic_pending_app < 0)
          relic_pending_app = RelicDockHit(ms.pos.x - relic_ox,
                ms.pos.y - relic_oy);
        break;
    }

    if (relic_pending_app >= 0) {
      i = relic_pending_app;
      relic_pending_app = -1;
      while (ms.lb)
        Sleep(10);
      FlushMsgs;
      LaunchApp(i);
    }
  }
}
