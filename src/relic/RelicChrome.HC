// RelicChrome.HC
// System status strip: RelicOS version, date/time, FPS.

U8 relic_top_line[STR_LEN];
// DOOM frames per second, measured by the desktop presenter; -1 = not running.
I64 relic_doom_fps = -1;
Bool relic_status_show_keys = FALSE;

U0 RelicStatusFormat()
{
  CDateStruct ds;

  Date2Struct(&ds, Now + local_time_offset);
  StrPrint(relic_top_line,
        "RelicOS V0.4.0  %3tZ %02d/%02d/%04d  %02d:%02d:%02d  FPS:%2tf",
        ds.day_of_week, "ST_DAYS_OF_WEEK", ds.mon, ds.day_of_mon, ds.year,
        ds.hour, ds.min, ds.sec, winmgr.fps);
  if (relic_doom_fps >= 0)
    CatPrint(relic_top_line, "  DOOM:%d", relic_doom_fps);
}

// Text layer: installed as gr.fp_wall_paper, so the WinMgr calls this for
// its own (bottom-most) window every frame.  Text row 0 is the only row of
// that window that is not covered by the maximised desktop, so this is the
// permanent status strip.  Never draw menus or borders here.
U0 RelicStatusWallPaper(CTask *_task)
{
  U8 *st;

  if (!_task)
    _task = Fs;

  winmgr.show_menu = FALSE;
  RelicStatusFormat;
  _task->text_attr = BLACK << 4 | LTGRAY;
  TextPrint(_task, 0, 0, BLACK << 4 | LTGRAY, relic_top_line);
  if (scrncast.record)
    TextPrint(_task, 40, 0, BLACK << 4 | RED, "*");

  if (relic_status_show_keys) {
    st = ScanCode2KeyName(kbd.last_down_scan_code);
    TextPrint(_task, 80 - 18, 0, BLACK << 4 | YELLOW, "%18ts", st);
    Free(st);
  }
}

// RelicStatusWallPaper lives in the heap of the task compiling this file.
// If that task is killed (Ctrl+Alt+X), the WinMgr would keep calling freed
// code every frame, so hand the stock wall paper back when the task ends.
U0 (*relic_old_wall_paper)(CTask *task) = gr.fp_wall_paper;

U0 RelicChromeTaskEnd()
{
  if (gr.fp_wall_paper == &RelicStatusWallPaper)
    gr.fp_wall_paper = relic_old_wall_paper;
  Exit;
}

if (!Fs->task_end_cb)
  Fs->task_end_cb = &RelicChromeTaskEnd;

U0 RelicChromeInstall()
{
  winmgr.show_menu = FALSE;
  gr.fp_wall_paper = &RelicStatusWallPaper;
}

// ---- Kernel chrome suppression ----
// DocTermNew installs the DolDoc pull-down menu ("File Edit Insert Program
// View Help") and a border doc (task title, [X], MENU) that the WinMgr draws
// on text row 0 for a borderless maximised window.  Call this after every
// DocTermNew on a Relic task so none of that ever reaches the status strip.
U0 RelicMenuOff()
{
  winmgr.show_menu = FALSE;
  Fs->win_inhibit |= WIF_FOCUS_TASK_MENU;
  if (Fs->cur_menu) {
    MenuDel(Fs->cur_menu);
    Fs->cur_menu = NULL;
  }
  if (Fs->border_doc)
    Fs->border_doc->flags |= DOCF_DONT_SHOW;
  Fs->title_src = TTS_LOCKED_CONST;
  StrCpy(Fs->task_title, "RelicOS");
}

// Terminal doc with all kernel chrome suppressed.  DocTermNew allocates
// new put/display/border docs without freeing the old ones, so only call it
// once per task; after that just clear the existing doc.
U0 RelicTermNew()
{
  if (!DocPut)
    DocTermNew;
  else
    DocClear;
  RelicMenuOff;
}
