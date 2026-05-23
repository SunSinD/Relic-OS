// RelicChrome.HC
// System status strip: RelicOS version, date/time, FPS.

U8 relic_top_line[STR_LEN];
Bool relic_status_show_keys = TRUE;

U0 RelicStatusFormat()
{
  CDateStruct ds;

  Date2Struct(&ds, Now + local_time_offset);
  StrPrint(relic_top_line,
        "RelicOS V1.0.0 %3tZ %02d/%02d %02d:%02d:%02d FPS:%2tf",
        ds.day_of_week, "ST_DAYS_OF_WEEK", ds.mon, ds.day_of_mon,
        ds.hour, ds.min, ds.sec, winmgr.fps);
}

// Text layer (shell, games, any DocTerm window)
U0 RelicStatusWallPaper(CTask *_task)
{
  U8 *st;

  if (!_task)
    _task = Fs;

  RelicStatusFormat;
  _task->text_attr = BLACK << 4 | LTGRAY;
  TextPrint(_task, 0, 0, BLACK << 4 | LTGRAY, relic_top_line);
  if (scrncast.record)
    TextPrint(_task, 44 - 4, 0, BLACK << 4 | RED, "*");

  if (relic_status_show_keys) {
    st = ScanCode2KeyName(kbd.last_down_scan_code);
    TextPrint(_task, 80 - 18, 0, BLACK << 4 | YELLOW, "%18ts", st);
    Free(st);
  }
}

// Graphics layer (desktop draw_it — TextPrint is hidden under GrBlot)
U0 RelicStatusGrDraw(CDC *dc)
{
  RelicStatusFormat;
  dc->color = LTGRAY;
  GrPrint(dc, 6, 3, relic_top_line);
}

U0 RelicChromeInstall()
{
  winmgr.show_menu = FALSE;
  gr.fp_wall_paper = &RelicStatusWallPaper;
}
