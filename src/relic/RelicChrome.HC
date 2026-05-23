// RelicChrome.HC
// Runtime status strip override. Do not patch Adam/WallPaper.HC.Z.

U8 relic_top_line[STR_LEN];

U0 RelicStatusWallPaper(CTask *_task)
{
  CDateStruct ds;
  U8 *st;

  _task->text_attr = BLACK << 4 | LTGRAY;

  if (!(winmgr.updates & 31) || !*relic_top_line) {
    Date2Struct(&ds, Now + local_time_offset);
    StrPrint(relic_top_line,
          "RelicOS V1.0.0 %3tZ %02d/%02d %02d:%02d:%02d FPS:%2tf",
          ds.day_of_week, "ST_DAYS_OF_WEEK", ds.mon, ds.day_of_mon,
          ds.hour, ds.min, ds.sec, winmgr.fps);
  }

  TextPrint(Fs, 0, 0, BLACK << 4 + LTGRAY, relic_top_line);
  if (scrncast.record)
    TextPrint(Fs, 44 - 4, 0, BLACK << 4 + RED, "*");

  st = ScanCode2KeyName(kbd.last_down_scan_code);
  TextPrint(Fs, 80 - 18, 0, BLACK << 4 + YELLOW, "%18ts", st);
  Free(st);
}

U0 RelicChromeInstall()
{
  winmgr.show_menu = FALSE;
  gr.fp_wall_paper = &RelicStatusWallPaper;
}
