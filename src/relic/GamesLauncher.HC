// GamesLauncher.HC: compiled into RelicDesktop.HC via #include.
// Stock TempleOS pattern: every game runs INLINE on this task (no Spawn).
//
// Do NOT add `extern` prototypes here for functions that are already
// defined (RelicThemeApply, RelicChromeInstall, RelicDoomBegin, ...).  In
// HolyC an extern after the definition replaces the real symbol with an
// unresolved one, and every later call throws "Undefined Extern".

U0 RelicGamesEnter()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;
  WinFocus;
  Fs->border_src = BDS_CONST;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->text_attr = BLACK << 4 | LTGRAY;
}

// Black doc only: never touch draw_it here (DOOM uses RelicDoomBegin for that).
U0 RelicGamesDocBlack()
{
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  DocClear;
  DCFill;
}

// Fresh dark terminal under the launcher (kernel menu/border chrome off).
U0 RelicGamesTerm()
{
  RelicGamesEnter;
  RelicTermNew;
  RelicGamesEnter;
  relic_status_show_keys = FALSE;
}

U0 RelicGamesAfter()
{
  Cd("::/Home"); // games Cd into their own folder; Files would list it
  Fs->draw_it = NULL;
  RelicThemeApply;
  RelicChromeInstall;
  RelicGamesTerm;
  FlushMsgs;
}

// Stock demo launch: inline #include on this task, no child, no hidden parent.
U0 RelicGameExe(U8 *code)
{
  Fs->draw_it = NULL;
  RelicGamesDocBlack;
  // Games print their intro/score text; keep it readable on black.
  Fs->text_attr = BLACK << 4 | LTGRAY;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  WinFocus;
  try {
    ExePrint("%s", code);
  } catch {
    Fs->catch_except = TRUE;
  }
  RelicGamesAfter;
}

U0 RelicGameInline(U8 *path)
{
  U8 code[128];
  StrPrint(code, "#include \"%s\";", path);
  RelicGameExe(code);
}

// Stock Titanium.HC.Z bug: the mesh sprite CIA_neeger_imgs[3] (<9>) ends
// in garbage (28 38) where its twin <8> ends in 00 00, so it has no
// SPT_END marker.  Drawing it walks off the sprite and faults in
// SpriteSize; it only shows when a blinking CIA unit is on screen, so the
// crash looked random.  Load the game, mend the tail, then run it.
U0 RelicGameTitanium()
{
  RelicGameExe(
    "#include \"::/Apps/Titanium/Load\";\n"
    "U0 RelicTitaniumMend(){U8 *s=CIA_neeger_imgs[3];I32 *v=s+1,*t=s+5;"
    "I64 n=9+*v*12+*t*16;if(s[0]==SPT_MESH&&s[n])"
    "{s[n-1]=0;s[n]=0;}}RelicTitaniumMend;Titanium;");
}

#include "::/Home/RelicOS/RunTOOM.HC"

U0 RelicGameDoom()
{
  RelicGamesDocBlack;
  RelicDoomBegin;
  try {
    RunTOOM;
  } catch {
    Fs->catch_except = TRUE;
  }
  RelicDoomEnd;
  RelicGamesAfter;
}

U0 RelicGameModels()
{
  RelicGameExe("#include \"::/Apps/GrModels/Run\";View;");
}

U0 RelicGameRun(I64 id)
{
  RelicGamesEnter;
  FlushMsgs;
  DocClear;

  switch (id) {
    case 1:  RelicGameDoom; break;
    case 2:  RelicGameTitanium; break;
    case 3:  RelicGameInline("::/Demo/Games/BlackDiamond"); break;
    case 4:  RelicGameInline("::/Demo/Games/FlapBat"); break;
    case 5:  RelicGameInline("::/Demo/Games/Varoom"); break;
    case 6:  RelicGameInline("::/Demo/Games/FlatTops"); break;
    case 7:  RelicGameInline("::/Demo/Games/BomberGolf"); break;
    case 8:  RelicGameInline("::/Apps/KeepAway/Run"); break;
    case 9:  RelicGameInline("::/Demo/Games/RawHide"); break;
    case 10: RelicGameInline("::/Apps/X-Caliber/Run"); break;
    case 11: RelicGameInline("::/Demo/Games/Wenceslas"); break;
    case 12: RelicGameInline("::/Demo/Games/BattleLines"); break;
    case 13: RelicGameInline("::/Demo/Games/Talons"); break;
    case 14: RelicGameInline("::/Demo/Games/CastleFrankenstein"); break;
    case 15: RelicGameInline("::/Demo/Games/ZoneOut"); break;
    case 16: RelicGameInline("::/Apps/ToTheFront/Run"); break;
    case 17: RelicGameInline("::/Apps/Span/Run"); break;
    case 18: RelicGameInline("::/Demo/Games/TreeCheckers.HC.Z"); break;
    case 19: RelicGameInline("::/Demo/Games/Digits"); break;
    case 20: RelicGameInline("::/Apps/Strut/Run"); break;
    case 21: RelicGameInline("::/Demo/Games/BigGuns"); break;
    case 22: RelicGameInline("::/Demo/Games/TheDead"); break;
    case 23: RelicGameInline("::/Demo/Games/DunGen"); break;
    case 24: RelicGameModels; break;
    case 25: RelicGameInline("::/Home/RelicOS/Games/Tetris/Tetris.HC"); break;
    case 26: RelicGameInline("::/Home/RelicOS/Games/Scorch/Scorch.HC"); break;
    case 27: RelicGameInline("::/Home/RelicOS/Games/Sudoku/Run.HC"); break;
    case 28: RelicGameInline("::/Home/RelicOS/Games/Chess/Run.HC"); break;
  }
}

// ---- Graphical launcher ----
// Catalogue order is display order; ids go to RelicGameRun.  Only titles
// that run on this desktop are listed.
#define RELIC_GAMES 28
#define RELIC_GCAT_ALL      0
#define RELIC_GCAT_ACTION   1
#define RELIC_GCAT_PUZZLE   2
#define RELIC_GCAT_PORTS    3
#define RELIC_GCAT_CREATIVE 4
#define RELIC_GCATS         5
#define RELIC_GTILE_H   92
#define RELIC_GTILE_GAP 8
#define RELIC_GCOLS     4

I64 relic_game_ids[RELIC_GAMES]={
  1,25,26,27,28,
  2,3,4,5,7,8,9,10,11,13,20,21,22,
  12,6,14,15,16,17,18,19,23,
  24};
U8 *relic_game_names[RELIC_GAMES]={
  "DOOM","Tetris","Scorch","Sudoku","Chess",
  "Titanium","Black Diamond","Flap Bat","Varoom","Bomber Golf","KeepAway",
  "RawHide","X-Caliber","Wenceslas","Talons","Strut","BigGuns","TheDead",
  "Battle Lines","FlatTops","Frankenstein","ZoneOut","ToTheFront","Span",
  "Tree Checkers","Digits","DunGen",
  "Models"};
I64 relic_game_cats[RELIC_GAMES]={
  3,3,3,3,3,
  1,1,1,1,1,1,1,1,1,1,1,1,1,
  2,2,2,2,2,2,2,2,2,
  4};
U8 *relic_game_cat_subs[RELIC_GCATS]={"","TempleOS","TempleOS","TinkerOS port",
  "TempleOS demo"};
U8 *relic_games_tabs[7]={"All","Action","Puzzles","Ports","Creative",
  "|","Help & credits"};

I64 relic_games_cat=RELIC_GCAT_ALL,relic_games_sel=0;

U0 RelicGameGlyph(CDC *dc,I64 id,I64 x,I64 y,I64 s)
{
  I64 i,j;
  switch (id) {
    case 1:
      RelicGCirc(dc,x,y,s,11,10,7);
      RelicGFill(dc,x,y,s,8,9,9,10); RelicGFill(dc,x,y,s,13,9,14,10);
      RelicGL(dc,x,y,s,8,17,8,21); RelicGL(dc,x,y,s,14,17,14,21);
      RelicGL(dc,x,y,s,8,21,14,21);
      RelicGL(dc,x,y,s,6,5,2,1); RelicGL(dc,x,y,s,16,5,20,1);
      break;
    case 2:
      RelicGL(dc,x,y,s,11,2,3,18); RelicGL(dc,x,y,s,11,2,19,18);
      RelicGL(dc,x,y,s,3,18,19,18); RelicGL(dc,x,y,s,11,18,11,22);
      break;
    case 3:
      RelicGL(dc,x,y,s,11,2,20,11); RelicGL(dc,x,y,s,20,11,11,21);
      RelicGL(dc,x,y,s,11,21,2,11); RelicGL(dc,x,y,s,2,11,11,2);
      RelicGL(dc,x,y,s,2,11,20,11);
      break;
    case 4:
      RelicGCirc(dc,x,y,s,11,12,2);
      RelicGL(dc,x,y,s,10,11,6,6); RelicGL(dc,x,y,s,6,6,1,9);
      RelicGL(dc,x,y,s,1,9,5,15); RelicGL(dc,x,y,s,5,15,10,13);
      RelicGL(dc,x,y,s,12,11,16,6); RelicGL(dc,x,y,s,16,6,21,9);
      RelicGL(dc,x,y,s,21,9,17,15); RelicGL(dc,x,y,s,17,15,12,13);
      break;
    case 5:
      RelicGBox(dc,x,y,s,2,11,21,16);
      RelicGL(dc,x,y,s,6,11,8,7); RelicGL(dc,x,y,s,8,7,15,7);
      RelicGL(dc,x,y,s,15,7,17,11);
      RelicGCirc(dc,x,y,s,6,17,2); RelicGCirc(dc,x,y,s,17,17,2);
      break;
    case 6:
      RelicGL(dc,x,y,s,1,13,22,13); RelicGL(dc,x,y,s,1,13,5,18);
      RelicGL(dc,x,y,s,5,18,18,18); RelicGL(dc,x,y,s,18,18,22,13);
      RelicGBox(dc,x,y,s,13,8,16,13);
      break;
    case 7:
      RelicGL(dc,x,y,s,8,3,8,21); RelicGL(dc,x,y,s,8,3,18,7);
      RelicGL(dc,x,y,s,18,7,8,11); RelicGL(dc,x,y,s,3,21,20,21);
      RelicGFill(dc,x,y,s,14,18,15,19);
      break;
    case 8:
      RelicGCirc(dc,x,y,s,6,12,4); RelicGCirc(dc,x,y,s,17,12,4);
      RelicGFill(dc,x,y,s,11,11,12,12);
      break;
    case 9:
      RelicGL(dc,x,y,s,5,3,5,14); RelicGL(dc,x,y,s,5,14,8,19);
      RelicGL(dc,x,y,s,8,19,15,19); RelicGL(dc,x,y,s,15,19,18,14);
      RelicGL(dc,x,y,s,18,14,18,3);
      RelicGFill(dc,x,y,s,7,6,7,6); RelicGFill(dc,x,y,s,16,6,16,6);
      RelicGFill(dc,x,y,s,7,11,7,11); RelicGFill(dc,x,y,s,16,11,16,11);
      break;
    case 10:
      RelicGL(dc,x,y,s,11,2,11,16); RelicGL(dc,x,y,s,6,16,16,16);
      RelicGL(dc,x,y,s,11,16,11,21); RelicGCirc(dc,x,y,s,11,22,1);
      break;
    case 11:
      RelicGL(dc,x,y,s,11,2,11,20); RelicGL(dc,x,y,s,3,7,19,15);
      RelicGL(dc,x,y,s,3,15,19,7);
      break;
    case 12:
      for (i=0;i<6;i++) {
        RelicGL(dc,x,y,s,3+i*3,4,3+i*3,9);
        RelicGL(dc,x,y,s,3+i*3,14,3+i*3,19);
      }
      break;
    case 13:
      RelicGL(dc,x,y,s,5,4,8,18); RelicGL(dc,x,y,s,11,3,11,19);
      RelicGL(dc,x,y,s,17,4,14,18); RelicGL(dc,x,y,s,6,21,16,21);
      break;
    case 14:
      RelicGBox(dc,x,y,s,4,9,19,21);
      RelicGFill(dc,x,y,s,4,6,6,9); RelicGFill(dc,x,y,s,10,6,13,9);
      RelicGFill(dc,x,y,s,17,6,19,9); RelicGBox(dc,x,y,s,10,15,13,21);
      break;
    case 15:
      RelicGCirc(dc,x,y,s,11,11,9); RelicGCirc(dc,x,y,s,11,11,5);
      RelicGFill(dc,x,y,s,11,11,11,11);
      break;
    case 16:
      RelicGL(dc,x,y,s,7,3,16,3); RelicGL(dc,x,y,s,16,3,21,11);
      RelicGL(dc,x,y,s,21,11,16,20); RelicGL(dc,x,y,s,16,20,7,20);
      RelicGL(dc,x,y,s,7,20,2,11); RelicGL(dc,x,y,s,2,11,7,3);
      RelicGFill(dc,x,y,s,11,11,12,12);
      break;
    case 17:
      RelicGL(dc,x,y,s,1,14,22,14); RelicGL(dc,x,y,s,3,14,11,6);
      RelicGL(dc,x,y,s,11,6,19,14); RelicGL(dc,x,y,s,7,10,7,14);
      RelicGL(dc,x,y,s,11,6,11,14); RelicGL(dc,x,y,s,15,10,15,14);
      break;
    case 18:
      RelicGBox(dc,x,y,s,3,3,20,20);
      for (j=0;j<4;j++) for (i=0;i<4;i++)
        if (!((i+j)&1))
          RelicGFill(dc,x,y,s,4+i*4,4+j*4,6+i*4,6+j*4);
      break;
    case 19:
      RelicGBox(dc,x,y,s,7,3,16,11); RelicGBox(dc,x,y,s,7,11,16,20);
      break;
    case 20:
      RelicGL(dc,x,y,s,2,18,21,18); RelicGL(dc,x,y,s,2,18,7,8);
      RelicGL(dc,x,y,s,7,8,12,18); RelicGL(dc,x,y,s,12,18,17,8);
      RelicGL(dc,x,y,s,17,8,21,18); RelicGL(dc,x,y,s,7,8,17,8);
      break;
    case 21:
      RelicGCirc(dc,x,y,s,8,16,4);
      RelicGL(dc,x,y,s,8,12,20,6); RelicGL(dc,x,y,s,10,16,21,10);
      RelicGL(dc,x,y,s,20,6,21,10);
      break;
    case 22:
      RelicGL(dc,x,y,s,6,21,6,9); RelicGL(dc,x,y,s,6,9,8,5);
      RelicGL(dc,x,y,s,8,5,15,5); RelicGL(dc,x,y,s,15,5,17,9);
      RelicGL(dc,x,y,s,17,9,17,21);
      RelicGL(dc,x,y,s,11,9,11,16); RelicGL(dc,x,y,s,8,12,14,12);
      RelicGL(dc,x,y,s,2,21,21,21);
      break;
    case 23:
      RelicGL(dc,x,y,s,2,20,21,20); RelicGL(dc,x,y,s,2,20,2,16);
      RelicGL(dc,x,y,s,2,16,7,16); RelicGL(dc,x,y,s,7,16,7,12);
      RelicGL(dc,x,y,s,7,12,12,12); RelicGL(dc,x,y,s,12,12,12,8);
      RelicGL(dc,x,y,s,12,8,17,8); RelicGL(dc,x,y,s,17,8,17,4);
      RelicGL(dc,x,y,s,17,4,21,4); RelicGL(dc,x,y,s,21,4,21,20);
      break;
    case 24:
      RelicGBox(dc,x,y,s,3,8,15,20); RelicGBox(dc,x,y,s,8,3,20,15);
      RelicGL(dc,x,y,s,3,8,8,3); RelicGL(dc,x,y,s,15,8,20,3);
      RelicGL(dc,x,y,s,15,20,20,15); RelicGL(dc,x,y,s,3,20,8,15);
      break;
    case 25:
      RelicGBox(dc,x,y,s,3,7,8,12); RelicGBox(dc,x,y,s,9,7,14,12);
      RelicGBox(dc,x,y,s,15,7,20,12); RelicGBox(dc,x,y,s,9,13,14,18);
      break;
    case 26:
      RelicGL(dc,x,y,s,1,21,7,14); RelicGL(dc,x,y,s,7,14,16,14);
      RelicGL(dc,x,y,s,16,14,22,21);
      RelicGBox(dc,x,y,s,9,10,14,14); RelicGL(dc,x,y,s,13,10,18,5);
      break;
    case 27:
      RelicGBox(dc,x,y,s,3,3,20,20);
      RelicGL(dc,x,y,s,9,3,9,20); RelicGL(dc,x,y,s,14,3,14,20);
      RelicGL(dc,x,y,s,3,9,20,9); RelicGL(dc,x,y,s,3,14,20,14);
      break;
    case 28:
      RelicGCirc(dc,x,y,s,11,6,3);
      RelicGL(dc,x,y,s,10,9,8,18); RelicGL(dc,x,y,s,13,9,15,18);
      RelicGBox(dc,x,y,s,5,18,17,21);
      break;
  }
}

// Catalogue indices visible in the current category.
I64 RelicGamesList(I64 *out)
{
  I64 i,n=0;
  for (i=0;i<RELIC_GAMES;i++)
    if (relic_games_cat==RELIC_GCAT_ALL || relic_game_cats[i]==relic_games_cat)
      out[n++]=i;
  return n;
}

I64 RelicGamesRows(I64 h)
{
  return MaxI64(1,(h-RUI_TOP-4-RUI_FOOT_H-48+RELIC_GTILE_GAP)/
        (RELIC_GTILE_H+RELIC_GTILE_GAP));
}

I64 RelicGamesTileW(I64 w)
{
  return (w-32-(RELIC_GCOLS-1)*RELIC_GTILE_GAP)/RELIC_GCOLS;
}

// k = position on the current page.
U0 RelicGamesTile(I64 k,I64 w,I64 *x,I64 *y)
{
  *x=16+(k%RELIC_GCOLS)*(RelicGamesTileW(w)+RELIC_GTILE_GAP);
  *y=RUI_TOP+4+(k/RELIC_GCOLS)*(RELIC_GTILE_H+RELIC_GTILE_GAP);
}

// Pager row: "<" button, page label, ">" button, centred.
U0 RelicGamesPager(I64 w,I64 h,I64 *px,I64 *py)
{
  *px=w/2-80;
  *py=h-RUI_FOOT_H-36;
}

U0 RelicGamesNote()
{
  I64 list[RELIC_GAMES],n,g;
  n=RelicGamesList(list);
  if (!n) { relic_app_notice[0]=0; return; }
  g=list[relic_games_sel];
  if (relic_game_ids[g]==1)
    StrPrint(relic_app_notice,"%s: TOOM port",relic_game_names[g]);
  else
    StrPrint(relic_app_notice,"%s: %s",relic_game_names[g],
          relic_game_cat_subs[relic_game_cats[g]]);
}

U0 RelicGamesDraw(CTask *task,CDC *dc)
{
  I64 w=task->pix_width,h=task->pix_height,list[RELIC_GAMES],n,per,page,pages,
      k,i,g,x,y,tw,st,px,py;
  RelicUIFrame(task,dc,"Games","Arrows select  Enter play  Tab category  Esc back",TRUE);
  RelicUIToolbar(task,dc,relic_games_tabs,7,1<<relic_games_cat,0);
  n=RelicGamesList(list);
  per=RELIC_GCOLS*RelicGamesRows(h);
  page=relic_games_sel/per;
  pages=MaxI64(1,(n+per-1)/per);
  tw=RelicGamesTileW(w);
  for (k=0;k<per;k++) {
    i=page*per+k;
    if (i<n) {
      g=list[i];
      RelicGamesTile(k,w,&x,&y);
      st=RelicUIState(task,x,y,tw,RELIC_GTILE_H);
      dc->color=rc_ctrl;
      if (st==RUI_HOVER) dc->color=rc_hover;
      if (st==RUI_DOWN || i==relic_games_sel) dc->color=rc_sel;
      GrRect(dc,x,y,tw,RELIC_GTILE_H);
      dc->color=rc_line; RelicOutline(dc,x,y,tw,RELIC_GTILE_H);
      if (i==relic_games_sel) {
        dc->color=rc_strong;
        RelicOutline(dc,x,y,tw,RELIC_GTILE_H);
        RelicOutline(dc,x+1,y+1,tw-2,RELIC_GTILE_H-2);
      }
      dc->color=rc_strong;
      RelicGameGlyph(dc,relic_game_ids[g],x+(tw-24)/2,y+14,24);
      RelicUITextC(dc,x+4,y+50,tw-8,relic_game_names[g]);
      dc->color=rc_dim;
      if (relic_game_ids[g]==1)
        RelicUITextC(dc,x+4,y+66,tw-8,"TOOM port");
      else
        RelicUITextC(dc,x+4,y+66,tw-8,relic_game_cat_subs[relic_game_cats[g]]);
    }
  }
  if (!n) {
    dc->color=rc_dim; GrPrint(dc,16,RUI_TOP+12,"No games in this category.");
  }
  if (pages>1) {
    RelicGamesPager(w,h,&px,&py);
    st=RelicUIState(task,px,py,28,22);
    if (!page) st=RUI_OFF;
    RelicUIButton(dc,px,py,28,22,"<",st);
    st=RelicUIState(task,px+132,py,28,22);
    if (page+1>=pages) st=RUI_OFF;
    RelicUIButton(dc,px+132,py,28,22,">",st);
    dc->color=rc_text;
    GrPrint(dc,px+80-6*FONT_WIDTH,py+7,"Page %d of %d",page+1,pages);
  }
}

U0 RelicGamesShow()
{
  RelicGamesTerm;
  RelicUIMatte;
  DocClear;
  DocCursor(OFF);
  Fs->draw_it=&RelicGamesDraw;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinZBufUpdate;
  RelicGamesNote;
  FlushMsgs;
}

U0 RelicGamesCredits()
{
  RelicDialog("Help and credits",
        "DOOM: TOOM port by Rhodes and Sierra. W/S move, arrows turn, "
        "A/D strafe, Ctrl fire, Space use, Tab map, Esc menu.\n\n"
        "Tetris, Scorch, Sudoku, Chess: TinkerOS community games "
        "(Unlicense). Controls are in each game's own menu.\n\n"
        "TempleOS games and demos by Terry A. Davis. Esc leaves most of them.\n\n"
        "Original game licenses and data rules still apply.","Close");
}

U0 RelicGamesPlay(I64 g)
{
  Bool failed=FALSE;
  Fs->draw_it=NULL;
  relic_app_notice[0]=0;
  RelicUIColour;
  try {
    RelicGameRun(relic_game_ids[g]);
  } catch {
    Fs->catch_except=TRUE;
    failed=TRUE;
  }
  RelicGamesShow;
  if (failed)
    RelicNotify(relic_game_names[g],"The game stopped because of an error.");
}

U0 RelicGamesLauncher()
{
  I64 list[RELIC_GAMES],ch,sc,mc,n,per,page,k,i,x,y,tw,mx,my,px,py,
      last_z=ms.pos.z,w,h;
  Bool done=FALSE;

  RelicGamesShow;

  while (!done) {
    if (ms.pos.y < 8)
      MsSet(ms.pos.x, 8);
    w=Fs->pix_width; h=Fs->pix_height;
    n=RelicGamesList(list);
    per=RELIC_GCOLS*RelicGamesRows(h);
    if (relic_games_sel>=n) relic_games_sel=MaxI64(0,n-1);
    page=relic_games_sel/per;
    if (ms.pos.z!=last_z) {
      if (ms.pos.z>last_z) relic_games_sel=MinI64(MaxI64(0,n-1),(page+1)*per);
      else if (page) relic_games_sel=(page-1)*per;
      last_z=ms.pos.z;
      RelicGamesNote;
    }

    mc = ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN | 1 << MSG_MS_L_DOWN);
    if (!mc) {
      Sleep(10);
    } else if (mc==MSG_MS_L_DOWN) {
      RelicUIMouse(Fs,&mx,&my);
      tw=RelicGamesTileW(w);
      if (RelicUICloseHit(w,mx,my)) done=TRUE;
      i=RelicUIToolbarHit(relic_games_tabs,7,mx,my);
      if (i>=0 && i<RELIC_GCATS) {
        relic_games_cat=i; relic_games_sel=0;
      } else if (i==6)
        RelicGamesCredits;
      for (k=0;k<per;k++) {
        RelicGamesTile(k,w,&x,&y);
        if (page*per+k<n && RelicUIIn(mx,my,x,y,tw,RELIC_GTILE_H)) {
          relic_games_sel=page*per+k;
          RelicGamesNote;
          RelicGamesPlay(list[relic_games_sel]);
        }
      }
      RelicGamesPager(w,h,&px,&py);
      if (RelicUIIn(mx,my,px,py,28,22) && page)
        relic_games_sel=(page-1)*per;
      if (RelicUIIn(mx,my,px+132,py,28,22) && (page+1)*per<n)
        relic_games_sel=(page+1)*per;
    } else if (ch == CH_ESC || ch == CH_SHIFT_ESC) {
      done = TRUE;
    } else if (ch=='d' || ch=='D' || ch=='?') {
      RelicGamesCredits;
    } else if (ch=='\t') {
      if (sc & SCF_SHIFT)
        relic_games_cat=(relic_games_cat+RELIC_GCATS-1)%RELIC_GCATS;
      else
        relic_games_cat=(relic_games_cat+1)%RELIC_GCATS;
      relic_games_sel=0;
    } else if (ch=='\n' || ch==' ') {
      if (n) RelicGamesPlay(list[relic_games_sel]);
    } else if ((sc&0xFF)==SC_CURSOR_LEFT) {
      if (relic_games_sel>0) relic_games_sel--;
    } else if ((sc&0xFF)==SC_CURSOR_RIGHT) {
      if (relic_games_sel+1<n) relic_games_sel++;
    } else if ((sc&0xFF)==SC_CURSOR_UP) {
      if (relic_games_sel>=RELIC_GCOLS) relic_games_sel-=RELIC_GCOLS;
    } else if ((sc&0xFF)==SC_CURSOR_DOWN) {
      relic_games_sel=MinI64(MaxI64(0,n-1),relic_games_sel+RELIC_GCOLS);
    } else if ((sc&0xFF)==SC_PAGE_UP) {
      relic_games_sel=MaxI64(0,relic_games_sel-per);
    } else if ((sc&0xFF)==SC_PAGE_DOWN) {
      relic_games_sel=MinI64(MaxI64(0,n-1),relic_games_sel+per);
    } else if ((sc&0xFF)==SC_HOME) {
      relic_games_sel=0;
    } else if ((sc&0xFF)==SC_END) {
      relic_games_sel=MaxI64(0,n-1);
    }
    if (mc) RelicGamesNote;
  }
  Fs->draw_it=NULL;
  relic_app_notice[0]=0;
  RelicGamesAfter;
}
