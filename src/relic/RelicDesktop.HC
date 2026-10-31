// RelicDesktop.HC - Relic OS Desktop Environment
//
// The desktop, dock and the small text apps run on this task.  The Shell
// (">_") runs as an independent child task (RelicShellTaskMain) so the
// desktop loop never blocks on it and can never dead-lock behind it.
// Games run inline on this task (see GamesLauncher.HC).

// ---- Constants ----
// Taskbar along the bottom edge: launcher button anchored bottom-left,
// pinned apps to its right.  The app menu opens above the launcher.
#define NUM_APPS     14
#define DOCK_COUNT   2
#define TOPBAR_H     14
#define TASKBAR_H    36
#define TASK_BTN_W   40
#define TASK_BTN_H   28
#define TASK_BTN_GAP 4
#define TASK_PIN_X   56
#define MENU_W       392
#define MENU_H       320
#define MENU_COLS    4
#define MENU_TILE_W  90
#define MENU_TILE_H  60

// WinMgr frames (~1 s) without a newly published DOOM frame before the
// presenter falls back to snapshotting doom_scrn directly.
#define RELIC_DOOM_STALE_MAX 30

// ---- Globals ----
I64 relic_ox = 0, relic_oy = 0;
I64 relic_w = 640, relic_h = 472;
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

extern U8 blkdev_text_attr[BDT_TYPES_NUM];
extern U8 drv_text_attr[3];
U8 relic_old_blkdev_text_attr[BDT_TYPES_NUM];
U8 relic_old_drv_text_attr[3];
Bool relic_drive_colors_saved = FALSE;
U8 app_icons[NUM_APPS][8] = {"Files","Edit","Shell","Games","Tasks","Memory","System","Help","Web","Paint","Calc","Date","Prefs","Notes"};
U8 app_tips[NUM_APPS][16] = {"Files","Editor","Shell","Games","Tasks","Memory","System","Help","Browser","Paint","Calculator","Calendar","Settings","Notes"};
I64 relic_dock_apps[DOCK_COUNT]={8,0};
// Start menu order: everyday apps first, system tools last.
I64 relic_menu_order[NUM_APPS]={8,0,1,2,9,10,11,13,3,12,7,4,5,6};
Bool relic_menu=FALSE;
F64 relic_menu_progress=0,relic_menu_from=0,relic_menu_t=0;
I64 relic_menu_offset=0,relic_menu_sel=0;
F64 relic_dock_hover[DOCK_COUNT];
F64 relic_draw_last=0;

U0 RelicMenuSet(Bool show)
{
  relic_menu_from=relic_menu_progress;
  relic_menu_t=tS;
  relic_menu=show;
  relic_menu_sel=0;
}

U8 relic_search[64]="";
F64 relic_last_input=0;
Bool relic_saver=FALSE;

Bool RelicMenuMatch(I64 i)
{
  U8 a[64],b[64];
  StrCpy(a,app_tips[i]); StrCpy(b,relic_search);
  return !b[0] || StrIMatch(b,a)!=NULL;
}

// Apps shown in the menu right now (search applied), in menu order.
I64 RelicMenuList(I64 *out)
{
  I64 i,n=0;
  for (i=0;i<NUM_APPS;i++)
    if (RelicMenuMatch(relic_menu_order[i]))
      out[n++]=relic_menu_order[i];
  return n;
}

// Menu panel origin; it sits above the launcher, anchored bottom-left.
U0 RelicMenuGeom(I64 h,I64 *x,I64 *y)
{
  *x=8;
  *y=h-TASKBAR_H-8-MENU_H+relic_menu_offset;
}

U0 RelicMenuTile(I64 n,I64 mx0,I64 my0,I64 *x,I64 *y)
{
  *x=mx0+16+(n%MENU_COLS)*MENU_TILE_W;
  *y=my0+68+(n/MENU_COLS)*MENU_TILE_H;
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
// Taskbar button i (i=-1 is the launcher) in client pixels.
U0 RelicTaskBtn(I64 i,I64 h,I64 *x,I64 *y)
{
  if (i<0) *x=8;
  else *x=TASK_PIN_X+i*(TASK_BTN_W+TASK_BTN_GAP);
  *y=h-TASKBAR_H+(TASKBAR_H-TASK_BTN_H)/2;
}

U0 RelicDrawMenu(CTask *task,CDC *dc,I64 h,I64 mx,I64 my)
{
  I64 list[NUM_APPS],n,i,x0,y0,tx,ty,cols;
  U8 buf[80];
  RelicMenuGeom(h,&x0,&y0);
  n=RelicMenuList(list);
  if (relic_menu_sel>=n) relic_menu_sel=MaxI64(0,n-1);
  dc->color=rc_panel; GrRect(dc,x0,y0,MENU_W,MENU_H);
  dc->color=rc_line; RelicOutline(dc,x0,y0,MENU_W,MENU_H);
  // Search field
  dc->color=BLACK; GrRect(dc,x0+16,y0+16,MENU_W-32,24);
  dc->color=RelicChoose(relic_search[0]!=0,rc_strong,rc_line);
  RelicOutline(dc,x0+16,y0+16,MENU_W-32,24);
  cols=(MENU_W-56)/FONT_WIDTH;
  if (relic_search[0]) {
    dc->color=rc_strong; RelicFit(buf,relic_search,cols);
    GrPrint(dc,x0+28,y0+24,"%s",buf);
    GrRect(dc,x0+28+StrLen(buf)*FONT_WIDTH+1,y0+22,1,12);
  } else {
    dc->color=rc_dim; GrPrint(dc,x0+28,y0+24,"Type to search");
  }
  dc->color=rc_text;
  if (relic_search[0]) GrPrint(dc,x0+16,y0+52,"Results");
  else GrPrint(dc,x0+16,y0+52,"All apps");
  if (!n) {
    dc->color=rc_dim; GrPrint(dc,x0+16,y0+76,"No app matches that name.");
  }
  for (i=0;i<n;i++) {
    RelicMenuTile(i,x0,y0,&tx,&ty);
    if (RelicUIIn(mx,my,tx,ty,MENU_TILE_W-4,MENU_TILE_H-4)) {
      dc->color=rc_hover; GrRect(dc,tx,ty,MENU_TILE_W-4,MENU_TILE_H-4);
    }
    if (i==relic_menu_sel) {
      dc->color=rc_strong; RelicOutline(dc,tx,ty,MENU_TILE_W-4,MENU_TILE_H-4);
    }
    dc->color=rc_strong;
    RelicAppGlyph(dc,list[i],tx+(MENU_TILE_W-4-20)/2,ty+10,20);
    dc->color=RelicChoose(i==relic_menu_sel,rc_strong,rc_text);
    RelicUITextC(dc,tx,ty+40,MENU_TILE_W-4,app_tips[list[i]]);
  }
}

U0 DrawDesktop(CTask *task, CDC *dc)
{
  I64 w = task->pix_width;
  I64 h = task->pix_height;
  I64 i, bx, by, wp_y, app;
  I64 mx, my, st, tw, tx, ty;
  F64 dt=Clamp(tS-relic_draw_last,0,0.1),motion,target,dur;
  relic_draw_last=tS;
  // Open: 167 ms decelerate; close: 100 ms.  Reduced motion snaps.
  dur=0.167;
  if (!relic_menu) dur=0.1;
  motion=Clamp((tS-relic_menu_t)/dur,0,1);
  motion=1-(1-motion)*(1-motion)*(1-motion);
  target=RelicChoose(relic_menu,1,0);
  relic_menu_progress=relic_menu_from+(target-relic_menu_from)*motion;
  if (!relic_cfg.animations) relic_menu_progress=target;
  relic_menu_offset=ToI64((1-relic_menu_progress)*16);

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

  if (relic_wp_dc && relic_cfg.wallpaper)
    GrBlot(dc, 0, wp_y, relic_wp_dc);
  else {
    dc->color = BLACK;
    GrRect(dc, 0, wp_y, w, h - wp_y);
  }

  if (relic_saver) {
    dc->color=BLACK; GrRect(dc,0,0,w,h);
    dc->color=LTGRAY; GrPrint(dc,32+(ToI64(tS/8)%8)*56,180,"RelicOS");
    return;
  }

  mx=ms.pos.x-relic_ox; my=ms.pos.y-relic_oy;

  // Taskbar
  dc->color=rc_panel; GrRect(dc,0,h-TASKBAR_H,w,TASKBAR_H);
  dc->color=rc_line; GrLine(dc,0,h-TASKBAR_H,w-1,h-TASKBAR_H);
  RelicTaskBtn(-1,h,&bx,&by);
  st=RelicUIState(task,bx,by,TASK_BTN_W,TASK_BTN_H);
  if (relic_menu) {
    dc->color=rc_sel; GrRect(dc,bx,by,TASK_BTN_W,TASK_BTN_H);
    dc->color=rc_text; GrRect(dc,bx+10,by+TASK_BTN_H-2,TASK_BTN_W-20,2);
  } else if (st!=RUI_NORMAL) {
    dc->color=RelicChoose(st==RUI_DOWN,rc_sel,rc_hover);
    GrRect(dc,bx,by,TASK_BTN_W,TASK_BTN_H);
  }
  dc->color=rc_strong;
  RelicAppGlyph(dc,RELIC_GLYPH_LAUNCHER,bx+(TASK_BTN_W-20)/2,by+(TASK_BTN_H-20)/2,20);
  dc->color=rc_line;
  GrLine(dc,TASK_PIN_X-5,by+6,TASK_PIN_X-5,by+TASK_BTN_H-7);

  for (i=0;i<DOCK_COUNT;i++) {
    app=relic_dock_apps[i];
    RelicTaskBtn(i,h,&bx,&by);
    st=RelicUIState(task,bx,by,TASK_BTN_W,TASK_BTN_H);
    if (relic_menu_progress>0.005) st=RUI_NORMAL;
    target=RelicChoose(st!=RUI_NORMAL,1,0);
    if (relic_cfg.animations)
      relic_dock_hover[i]+=(target-relic_dock_hover[i])*Min(1.0,dt/0.083);
    else
      relic_dock_hover[i]=target;
    if (st!=RUI_NORMAL) {
      dc->color=RelicChoose(st==RUI_DOWN,rc_sel,rc_hover);
      GrRect(dc,bx,by,TASK_BTN_W,TASK_BTN_H);
    }
    by-=ToI64(relic_dock_hover[i]*2+0.5);
    dc->color=RelicChoose(st==RUI_NORMAL,rc_text,rc_strong);
    RelicAppGlyph(dc,app,bx+(TASK_BTN_W-20)/2,by+(TASK_BTN_H-20)/2,20);
    if (st!=RUI_NORMAL) {
      tw=StrLen(app_tips[app])*FONT_WIDTH+16;
      tx=ClampI64(bx+(TASK_BTN_W-tw)/2,4,w-tw-4);
      ty=h-TASKBAR_H-26;
      dc->color=rc_panel; GrRect(dc,tx,ty,tw,20);
      dc->color=rc_line; RelicOutline(dc,tx,ty,tw,20);
      dc->color=rc_strong; GrPrint(dc,tx+8,ty+6,"%s",app_tips[app]);
    }
  }

  if (relic_menu_progress>0.005)
    RelicDrawMenu(task,dc,h,mx,my);
}

U0 RelicDocDark()
{
  RelicDriveColorsDark;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->border_src = BDS_CONST;
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
  VMWMsRelative;
  Fs->draw_it = &DrawDesktop;
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
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
  // DOOM pins the cursor by moving ms.offset; give the desktop its mouse back.
  ms.offset.x = ms.offset.y = 0;
  VMWMsAbsolute;
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
  RelicUIMatte;
  RelicChromeInstall;
  RelicDesktopMode;
  DocClear;
  DCFill;
  Fs->draw_it = &DrawDesktop;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  FlushMsgs;
}

// Click on the desktop: returns the app to launch, or -1.
I64 RelicDockHit(I64 x,I64 y)
{
  I64 list[NUM_APPS],i,n,bx,by,x0,y0;
  if (relic_menu) {
    RelicMenuGeom(relic_h,&x0,&y0);
    if (RelicUIIn(x,y,x0,y0,MENU_W,MENU_H)) {
      n=RelicMenuList(list);
      for (i=0;i<n;i++) {
        RelicMenuTile(i,x0,y0,&bx,&by);
        if (RelicUIIn(x,y,bx,by,MENU_TILE_W-4,MENU_TILE_H-4)) {
          RelicMenuSet(FALSE);
          return list[i];
        }
      }
      return -1;
    }
  }
  RelicTaskBtn(-1,relic_h,&bx,&by);
  if (RelicUIIn(x,y,bx,by,TASK_BTN_W,TASK_BTN_H)) {
    RelicMenuSet(!relic_menu); relic_search[0]=0; return -1;
  }
  for (i=0;i<DOCK_COUNT;i++) {
    RelicTaskBtn(i,relic_h,&bx,&by);
    if (RelicUIIn(x,y,bx,by,TASK_BTN_W,TASK_BTN_H)) {
      RelicMenuSet(FALSE);
      return relic_dock_apps[i];
    }
  }
  if (relic_menu) RelicMenuSet(FALSE);
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
  if (ch=='b' || ch=='B') return 8;
  if (ch=='p' || ch=='P') return 9;
  if (ch=='c' || ch=='C') return 10;
  if (ch=='l' || ch=='L') return 11;
  if (ch=='o' || ch=='O') return 12;
  if (ch=='n' || ch=='N') return 13;
  return -1;
}

// ---- Shell (independent child task) ----
U8 relic_shell_history[16][1024];
I64 relic_shell_history_count=0;
U0 RelicShellRecall(U8 *line,I64 *len,U8 *replacement)
{
  while (*len>0) { "%c",CH_BACKSPACE; (*len)--; }
  StrCpy(line,replacement); *len=StrLen(line);
  "%s",line;
}

U0 RelicShellPrompt()
{
  "\n> ";
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
  U8 line[1024],draft[1024];
  draft[0]=0;
  I64 len = 0, ch, sc, mc,i,hpos=relic_shell_history_count;
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
  DocClear;
  "$WW,1$"; // wrap long lines instead of scrolling the shell sideways
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  WinToTop(Fs);
  WinFocus(Fs);
  FlushMsgs;

  "Relic Shell\n";
  "Type help for commands, or exit to return.\n";
  RelicShellPrompt;

  while (!stop) {
    mc = ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (!mc) {
      Sleep(10);
    } else if (ch == CH_ESC || ch == CH_SHIFT_ESC) {
      stop = TRUE;
    } else if ((sc&255)==SC_CURSOR_UP) {
      if (hpos==relic_shell_history_count) { line[len]=0; StrCpy(draft,line); }
      if (hpos>0) RelicShellRecall(line,&len,relic_shell_history[--hpos]);
    } else if ((sc&255)==SC_CURSOR_DOWN) {
      if (hpos<relic_shell_history_count) {
        hpos++;
        if (hpos==relic_shell_history_count) RelicShellRecall(line,&len,draft);
        else RelicShellRecall(line,&len,relic_shell_history[hpos]);
      }
    } else if (ch == '\n') {
      line[len] = 0;
      if (len && (relic_shell_history_count==0 || StrCmp(line,relic_shell_history[relic_shell_history_count-1]))) {
        if (relic_shell_history_count==16) {
          for (i=0;i<15;i++) StrCpy(relic_shell_history[i],relic_shell_history[i+1]);
          relic_shell_history_count=15;
        }
        StrCpy(relic_shell_history[relic_shell_history_count++],line);
      }
      hpos=relic_shell_history_count; draft[0]=0;
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
    RelicGamesAfter;
    DocClear;
    PutExcept;
    RelicUIMatte;
    RelicNotify("Games","The games launcher stopped because of an error. "
          "You will return to the desktop.");
  }
}

#include "::/Home/RelicOS/RelicApps.HC"
U0 RelicAppFiles() { RelicFilesApp; }

U0 RelicAppTasks()
{
  "Tasks\n\n";
  TaskRep;
  "\nUp/Down or PageUp/PageDown scroll. Esc returns.\n";
  DocTop; View;
}

U0 RelicAppMemory()
{
  "Memory\n\n";
  MemRep;
  "\nUp/Down or PageUp/PageDown scroll. Esc returns.\n";
  DocTop; View;
}

U0 RelicAppSysInfo()
{
  "System\n\n";
  "OS:         RelicOS V0.5.0 (a TempleOS fork)\n";
  "Display:    640 x 480, 16 colours\n\n";
  "CPU Info:\n";
  CPURep;
  "\nDisk Info:\n";
  RelicDriveColorsDark;
  DrvRep;
  RelicDriveColorsRestore;
  "\nUp/Down or PageUp/PageDown scroll. Esc returns.\n";
  DocTop; View;
}

U0 RelicAppHelp()
{
  RelicHelpApp;
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

  RelicMenuSet(FALSE);
  RelicAppStart;
  if (idx == 0)
    RelicAppFiles;
  else if (idx == 1)
    RelicEditorApp;
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
  else if (idx == 8) RelicBrowserApp;
  else if (idx == 9) RelicPaintApp;
  else if (idx == 10) RelicCalcApp;
  else if (idx == 11) RelicCalendarApp;
  else if (idx == 12) RelicSettingsApp;
  else if (idx == 13) RelicNotesApp;
  return TRUE;
}

// ---- Main desktop loop ----
U0 RelicDesktop()
{
  I64 msg_code, arg1, arg2, i, len, n, sc, list[NUM_APPS];
  I64 last_mx=ms.pos.x,last_my=ms.pos.y;
  relic_last_input=tS;

  SettingsPush;
  AutoComplete(OFF);
  RelicUIMatte;
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

      if (ms.pos.x!=last_mx || ms.pos.y!=last_my) {
        relic_last_input=tS; relic_saver=FALSE;
        last_mx=ms.pos.x; last_my=ms.pos.y;
      }
      if (relic_cfg.saver_minutes && tS-relic_last_input>relic_cfg.saver_minutes*60)
        relic_saver=TRUE;
      if (msg_code) relic_last_input=tS;
      if (msg_code && relic_saver) { relic_saver=FALSE; msg_code=0; }
      if (msg_code == MSG_KEY_DOWN) {
        if (arg1 == CH_ESC || arg1 == CH_SHIFT_ESC) {
          RelicMenuSet(FALSE); RelicDesktopRestore;
        } else if (arg1==' ' && (!relic_menu || !relic_search[0])) {
          RelicMenuSet(!relic_menu); relic_search[0]=0;
        } else if (relic_menu) {
          len=StrLen(relic_search);
          n=RelicMenuList(list);
          sc=arg2&0xFF;
          if (sc==SC_CURSOR_LEFT && relic_menu_sel>0) relic_menu_sel--;
          else if (sc==SC_CURSOR_RIGHT && relic_menu_sel+1<n) relic_menu_sel++;
          else if (sc==SC_CURSOR_UP && relic_menu_sel>=MENU_COLS)
            relic_menu_sel-=MENU_COLS;
          else if (sc==SC_CURSOR_DOWN && relic_menu_sel+MENU_COLS<n)
            relic_menu_sel+=MENU_COLS;
          else if (arg1==CH_BACKSPACE && len) {
            relic_search[len-1]=0; relic_menu_sel=0;
          } else if (arg1=='\n') {
            if (relic_menu_sel<n) {
              relic_pending_app=list[relic_menu_sel];
              RelicMenuSet(FALSE);
            }
          } else if (arg1>=' ' && arg1<127 && arg1!='$$' && len<sizeof(relic_search)-1) {
            relic_search[len]=arg1; relic_search[len+1]=0; relic_menu_sel=0;
          }
        } else if (arg1 >= ' ' && arg1 < 127)
          relic_pending_app = RelicKeyApp(arg1);
      } else if (msg_code == MSG_MS_L_DOWN) {
        relic_pending_app=RelicDockHit(ms.pos.x-relic_ox,ms.pos.y-relic_oy);
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
        relic_last_input=tS;
      }
    }
  }
}
