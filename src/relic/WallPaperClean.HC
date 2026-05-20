#help_index "Windows"

class CWallPaperGlbls
{
  U8 top_line[STR_LEN];
} *wall=CAlloc(sizeof(CWallPaperGlbls));

U0 WallPaper(CTask *_task)
{
  CDateStruct ds;
  U8 *st;

  _task->text_attr=BLACK<<4+LTGRAY;

  if (!(winmgr.updates&31) || !*wall->top_line) {
    Date2Struct(&ds,Now+local_time_offset);
    StrPrint(wall->top_line,
          "RelicOS V1.0.0 %3tZ %02d/%02d %02d:%02d:%02d FPS:%2tf",
          ds.day_of_week,"ST_DAYS_OF_WEEK",ds.mon,ds.day_of_mon,
          ds.hour,ds.min,ds.sec,winmgr.fps);
  }

  TextPrint(Fs,0,0,BLACK<<4+LTGRAY,wall->top_line);

  if (scrncast.record)
    TextPrint(Fs,44-4,0,BLACK<<4+RED,"*");

  st=ScanCode2KeyName(kbd.last_down_scan_code);
  TextPrint(Fs,80-18,0,BLACK<<4+YELLOW,"%18ts",st);
  Free(st);
}

U0 WallPaperInit()
{
  gr.fp_wall_paper=&WallPaper;
}
