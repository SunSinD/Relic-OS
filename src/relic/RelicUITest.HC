U0 RelicUITest()
{
  U8 grouped[80],path[128];
  I64 i,blue,cyan;
  relic_test_pass=0; relic_test_fail=0; relic_test_report[0]=0;
  RelicCalcReset; relic_calc_err[0]=0;
  RelicCalcPress(21); RelicCalcPress(22); RelicCalcPress(16);
  RelicCalcPress(19);
  RelicCalcPress(21); RelicCalcPress(22); RelicCalcPress(17);
  RelicCalcPress(23);
  RelicCheck(!StrCmp(relic_calc_entry,"0.3"),"calculator decimal addition");
  RelicCalcReset; relic_calc_err[0]=0;
  RelicCalcPress(16); RelicCalcPress(7); RelicCalcPress(21); RelicCalcPress(23);
  RelicCheck(!StrCmp(relic_calc_err,"Cannot divide by zero"),"calculator zero divisor");
  RelicCalcReset; relic_calc_err[0]=0;
  RelicCalcPress(16); RelicCalcPress(20); RelicCalcPress(6);
  RelicCheck(!StrCmp(relic_calc_err,"Invalid input"),"calculator negative square root");
  RelicCalcGroup("1234567.5",grouped);
  RelicCheck(!StrCmp(grouped,"1,234,567.5"),"calculator thousands separators");
  RelicCalcReset; relic_calc_err[0]=0;
  RelicCheck(!RelicCalcSet(1e301) && relic_calc_err[0],"calculator overflow rejection");
  RelicCalcReset; relic_calc_err[0]=0;
  RelicCheck(HashFind("help",Fs->hash_table,HTT_FUN)!=NULL,"shell help available");
  RelicCheck(relic_icons_n==19,"icon file loaded");
  RelicCheck(RelicIconFind(RELIC_GLYPH_LAUNCHER,20) && RelicIconFind(8,20) &&
        RelicIconFind(RELIC_GLYPH_FOLDER,16),"launcher, browser and folder icons");
  blue=0; cyan=0;
  if (relic_wp_dc)
    for (i=0;i<640*480;i++) {
      if (relic_wp_dc->body[i]==LTGREEN) blue++;
      if (relic_wp_dc->body[i]==CYAN) cyan++;
    }
  RelicCheck(blue>1000 && !cyan,"wallpaper in Reaper blue");
  RelicCheck(relic_dock_apps[0]==8 && relic_menu_order[0]==8,"browser pinned first");
  RelicCheck(RELIC_GAMES==28,"games list has only runnable games");
  if (vmw_ms_abs) {
    VMWMsRelative;
    RelicCheck(!vmw_ms_abs,"VMware mouse switches to relative for DOOM");
    VMWMsAbsolute;
    RelicCheck(vmw_ms_abs && !ms.offset.x,"VMware mouse back to absolute");
  }
  CatPrint(relic_test_report,"RESULT %d passed, %d failed\n",relic_test_pass,relic_test_fail);
  StrPrint(path,"%c:/UITEST.TXT",relic_dev_drv);
  if (relic_dev_drv) FileWrite(path,relic_test_report,StrLen(relic_test_report));
  "%s",relic_test_report;
}
RelicUITest;
