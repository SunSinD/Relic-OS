// RelicDesktop.HC
// Relic OS Desktop — dark dock launcher

#define DOCK_H     34
#define DOCK_BTN_W 52
#define DOCK_BTN_H 24
#define DOCK_GAP   4
#define NUM_APPS   9
#define TOPBAR_H   14
#define DOCK_MARGIN 28

I64 relic_ox = 0, relic_oy = 0;
I64 relic_w = 640, relic_h = 480;

I64 app_colors[NUM_APPS] = {
  CYAN, CYAN, CYAN, LTBLUE,
  LTBLUE, LTBLUE, YELLOW,
  LTGREEN, RED
};

U8 app_icons[NUM_APPS][4] = {
  "Fi", "Ed", ">_", "Mt",
  "Tk", "Mm", "Gx",
  "?", "X"
};

U8 app_tips[NUM_APPS][16] = {
  "Files", "Editor", "Shell", "Mount",
  "Tasks", "Memory", "Graphics",
  "Help", "Exit"
};

// ---- Drawing ----
U0 DrawDesktop(CTask *task, CDC *dc)
{
  I64 w = dc->width;
  I64 h = dc->height;
  I64 i, bx, by;
  I64 dock_w, dock_x, dock_y;
  I64 mx, my, hover;

  relic_w = w;
  relic_h = h;
  relic_ox = task->pix_left;
  relic_oy = task->pix_top;

  // ---- Wallpaper ----
  if (relic_wp_dc)
    GrBlot(dc, 0, 0, relic_wp_dc);
  else {
    dc->color = BLACK;
    GrRect(dc, 0, 0, w, h);
  }

  // ---- Top bar ----
  dc->color = BLACK;
  GrRect(dc, 0, 0, w, TOPBAR_H);
  dc->color = DKGRAY;
  GrLine(dc, 0, TOPBAR_H, w, TOPBAR_H);
  dc->color = CYAN;
  GrPrint(dc, 6, 3, "Relic OS");
  dc->color = DKGRAY;
  GrPrint(dc, 80, 3, "|");
  dc->color = LTGRAY;
  GrPrint(dc, 96, 3, "Desktop v0.1");

  // ---- Dock ----
  dock_w = NUM_APPS * (DOCK_BTN_W + DOCK_GAP) + DOCK_GAP + 16;
  dock_x = (w - dock_w) / 2;
  dock_y = h - DOCK_H - DOCK_MARGIN;

  // Solid black dock background
  dc->color = BLACK;
  GrRect(dc, dock_x, dock_y, dock_w, DOCK_H);

  // Thin cyan border on top
  dc->color = CYAN;
  GrLine(dc, dock_x + 4, dock_y, dock_x + dock_w - 4, dock_y);

  // Thin dark border on bottom and sides
  dc->color = DKGRAY;
  GrLine(dc, dock_x + 4, dock_y + DOCK_H - 1, dock_x + dock_w - 4, dock_y + DOCK_H - 1);
  GrLine(dc, dock_x, dock_y + 4, dock_x, dock_y + DOCK_H - 4);
  GrLine(dc, dock_x + dock_w - 1, dock_y + 4, dock_x + dock_w - 1, dock_y + DOCK_H - 4);

  // ---- Dock buttons ----
  mx = ms.pos.x - relic_ox;
  my = ms.pos.y - relic_oy;

  for (i = 0; i < NUM_APPS; i++) {
    bx = dock_x + 8 + i * (DOCK_BTN_W + DOCK_GAP);
    by = dock_y + 5;

    hover = (mx >= bx && mx <= bx + DOCK_BTN_W &&
             my >= by && my <= by + DOCK_BTN_H);

    if (hover) {
      // Highlighted: colored fill
      dc->color = app_colors[i];
      GrRect(dc, bx, by, DOCK_BTN_W, DOCK_BTN_H);

      // Icon text (dark on bright)
      dc->color = BLACK;
      GrPrint(dc, bx + 14, by + 8, app_icons[i]);

      // Tooltip above
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
      // Normal: dark button with colored accent
      dc->color = DKGRAY;
      GrRect(dc, bx, by, DOCK_BTN_W, DOCK_BTN_H);

      // Colored top accent line
      dc->color = app_colors[i];
      GrLine(dc, bx + 2, by, bx + DOCK_BTN_W - 2, by);

      // Icon text (colored on dark)
      dc->color = app_colors[i];
      GrPrint(dc, bx + 14, by + 8, app_icons[i]);
    }
  }

  // Small cyan dot under dock center
  dc->color = CYAN;
  GrPlot(dc, w / 2, dock_y + DOCK_H + 3);
  GrPlot(dc, w / 2 + 1, dock_y + DOCK_H + 3);

  // Navigation hint at very bottom
  dc->color = DKGRAY;
  GrPrint(dc, w / 2 - 100, h - 12, "Ctrl+Alt+N: switch windows");
}

// ---- Launch handler ----
U0 LaunchApp(I64 idx)
{
  switch (idx) {
    case 0: User("Dir;\n"); break;
    case 1: User("Ed(\"::/Home/PersonalMenu.DD\");\n"); break;
    case 2: User("\n"); break;
    case 3: User("Mount;\n"); break;
    case 4: User("TaskRep;\n"); break;
    case 5: User("MemRep;\n"); break;
    case 6: User("#include \"C:/Demo/Graphics/Transform.HC.Z\"\n"); break;
    case 7: User("Help;\n"); break;
    case 8: break;
  }
}

// ---- Main loop ----
U0 RelicDesktop()
{
  I64 mx, my, i, bx, by;
  I64 dock_w, dock_x, dock_y;
  Bool running = TRUE;

  WinMax;
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_BORDER - WIF_SELF_CTRLS;
  DocClear;
  Fs->draw_it = &DrawDesktop;

  while (running) {
    if (ms.lb) {
      mx = ms.pos.x - relic_ox;
      my = ms.pos.y - relic_oy;

      dock_w = NUM_APPS * (DOCK_BTN_W + DOCK_GAP) + DOCK_GAP + 16;
      dock_x = (relic_w - dock_w) / 2;
      dock_y = relic_h - DOCK_H - DOCK_MARGIN;

      for (i = 0; i < NUM_APPS; i++) {
        bx = dock_x + 8 + i * (DOCK_BTN_W + DOCK_GAP);
        by = dock_y + 5;

        if (mx >= bx && mx <= bx + DOCK_BTN_W &&
            my >= by && my <= by + DOCK_BTN_H) {
          if (i == 8) {
            running = FALSE;
          } else {
            LaunchApp(i);
          }
          break;
        }
      }

      while (ms.lb) Sleep(10);
    }
    Sleep(30);
  }

  Fs->draw_it = NULL;
  Fs->win_inhibit = WIG_TASK_DFT;
  DocClear;
  "$FG,CYAN$Desktop closed.$FG$ #include \"E:/RelicBoot.HC\"; to restart.\n";
}
