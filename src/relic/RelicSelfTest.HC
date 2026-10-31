// Run from Relic Shell; creates and removes only its own scratch files.
I64 relic_test_pass=0,relic_test_fail=0;
U8 relic_test_report[4096]="";
U0 RelicCheck(Bool ok,U8 *name)
{
  if (ok) relic_test_pass++; else relic_test_fail++;
  CatPrint(relic_test_report,"%s %s\n",RelicText(ok,"PASS","FAIL"),name);
}
U0 RelicSelfTest()
{
  CDC *a=DCNew(16,8),*b=DCNew(16,8);
  U8 path[128],report_path[128],resolved[512],*large;
  U8 *html="<p>Hello &amp; world</p><script>hidden</script><a href=\"/next\">Next</a>";
  F64 start,elapsed;
  I64 frames;
  CRelicSettings saved;
  relic_test_pass=0; relic_test_fail=0; relic_test_report[0]=0;
  MemCpy(&saved,&relic_cfg,sizeof(CRelicSettings));
  RelicCheck(RelicMonthDays(2024,2)==29,"leap year February");
  RelicCheck(RelicMonthDays(1900,2)==28,"century common year");
  RelicCheck(RelicMonthDays(2000,2)==29,"400 year leap rule");
  RelicCheck(RelicMonthDays(2026,4)==30,"April length");
  StrPrint(path,"%s/RelicSelfTest.BMP",relic_data_dir);
  a->flags|=DCF_NO_TRANSPARENTS;
  b->flags|=DCF_NO_TRANSPARENTS;
  DCFill(a,WHITE); a->color=BLACK; GrRect(a,2,2,8,4);
  RelicCheck(RelicBMPSave(path,a),"BMP save");
  RelicCheck(RelicBMPLoad(path,b),"BMP load");
  RelicCheck(b->body[0]==WHITE && b->body[2*b->width_internal+2]==BLACK,"BMP palette and pixels");
  FileWrite(path,"broken",6);
  RelicCheck(!RelicBMPLoad(path,b),"reject truncated BMP");
  Del(path); DCDel(a); DCDel(b);
  RelicBrowserParse(html,StrLen(html),TRUE);
  RelicCheck(relic_browser_link_count==1 && !StrCmp(relic_browser_links[0],"/next"),"HTML links");
  RelicCheck(!StrMatch("hidden",relic_browser_lines[0]),"HTML script omitted");
  large=MAlloc(200000); MemSet(large,'x',199999); large[199999]=0;
  RelicBrowserParse(large,199999,FALSE);
  RelicCheck(relic_browser_count<=2048 && StrLen(relic_browser_lines[2047])<74,"long page bounded");
  Free(large); RelicBrowserLoad("about:home",FALSE);
  RelicSettingsDefault;
  RelicCheck(relic_cfg.animations && relic_cfg.clock24 && relic_cfg.version==2,"settings defaults");
  MemCpy(&relic_cfg,&saved,sizeof(CRelicSettings));
  RelicCheck(RelicURLResolve("http://host/folder/index.html","next.html",resolved,sizeof(resolved)) &&
    !StrCmp(resolved,"http://host/folder/next.html"),"relative page URL");
  RelicCheck(RelicURLResolve("http://host/folder/index.html","/next",resolved,sizeof(resolved)) &&
    !StrCmp(resolved,"http://host/next"),"root relative URL");
  RelicCheck(RelicURLResolve("http://host/","//other/page",resolved,sizeof(resolved)) &&
    !StrCmp(resolved,"http://other/page"),"scheme relative URL");
  start=tS; frames=winmgr.updates; Sleep(10000); elapsed=tS-start;
  CatPrint(relic_test_report,"MEASURE refresh %.3f FPS over %.3f seconds\n",(winmgr.updates-frames)/elapsed,elapsed);
  CatPrint(relic_test_report,"RESULT %d passed, %d failed\n",relic_test_pass,relic_test_fail);
  StrPrint(report_path,"%c:/SELFTEST.TXT",relic_dev_drv);
  if (relic_dev_drv) FileWrite(report_path,relic_test_report,StrLen(relic_test_report));
  "%s",relic_test_report;
}
RelicSelfTest;
