I64 relic_splash_step=0;
U8 relic_splash_text[64]="Starting RelicOS";
Bool relic_splash_active=TRUE;

U0 RelicSplashDraw(CTask *task,CDC *dc)
{
  I64 x=dc->width/2,y=dc->height/2,i,lit;
  no_warn task;
  dc->color=BLACK; GrRect(dc,0,0,dc->width,dc->height);
  dc->color=WHITE; GrPrint(dc,x-28,y-32,"RelicOS");
  dc->color=LTGRAY;
  GrPrint(dc,x-StrLen(relic_splash_text)*4,y+36,"%s",relic_splash_text);
  lit=ToI64(tS*8)%8;
  for (i=0;i<8;i++) {
    dc->color=DKGRAY;
    if (i==lit) dc->color=WHITE;
    GrRect(dc,x-31+i*9,y+4,4,4);
  }
}

U0 RelicSplashStart()
{
  WinBorder(OFF); WinMax;
  AutoComplete(OFF); DocClear; DCFill;
  DocCursor(OFF);
  Fs->draw_it=&RelicSplashDraw;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinZBufUpdate;
}
U0 RelicSplashStage(U8 *label)
{
  if (StrLen(label)<sizeof(relic_splash_text)) StrCpy(relic_splash_text,label);
}
