#exe {Cd(__DIR__);};;
#include "MainDrawer.HC";

U0 TOOMStart() {
  TOOMChromeOff;
  MsSet(GR_WIDTH/2,GR_HEIGHT/2);
  gameExit=FALSE;
  FramePtrAdd("RELIC_TOOM_FRESH", StrNew("1"));
  FlushMsgs;
  U64 r;
  CDC *title=GetGrLump("TITLEPIC");
  DocClear;
  while(TRUE) {
    TOOMChromeOff;
    if(gameExit)
      break;
    if(ms.pos.y<20)
      MsSet(ms.pos.x,GR_HEIGHT/2);
    TallBlot(doom_scrn,0,0,GR_HEIGHT,title);
    r=MainMenu;
    GrBlot(,0,0,doom_scrn);
    Refresh;
    if(!r || gameExit) {
       gameExit=TRUE;
       DocClear;
       break;
    }
  }
  gameExit=TRUE;
  active_menu=NULL;
  paused=FALSE;
  in_level=FALSE;
  TOOMStopTasks;
  FlushMsgs;
  TOOMChromeOff;
  DocClear;
}
