#exe {Cd(__DIR__);};;
#include "MainDrawer.HC";

// The game loop is TOP-LEVEL code, not wrapped in a function.
// ExeFile("SinglePlayer.HC") executes top-level statements directly, so
// the loop starts as soon as DOOM finishes compiling.  Wrapping this in
// `U0 TOOMStart()` would make ExeFile only DEFINE the function and never
// call it — DOOM would compile and immediately exit, leaving the desktop
// frozen on a blank screen.
WinBorder(OFF);
WinMax;
winmgr.show_menu=FALSE;
AutoComplete(OFF);
Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS -
      WIF_SELF_BORDER - WIF_FOCUS_TASK_MENU;
MsSet(GR_WIDTH/2,GR_HEIGHT/2);
gameExit=FALSE;
FramePtrAdd("RELIC_TOOM_FRESH", StrNew("1"));
FlushMsgs;
U64 r;
CDC *title=GetGrLump("TITLEPIC");
DocClear;
while(TRUE) {
  winmgr.show_menu=FALSE;
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
DocClear;
