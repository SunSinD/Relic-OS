// RelicChrome.HC
// System status strip (date, FPS, clock) and the shared UI toolkit used by
// the desktop, the apps and the games launcher: colour roles, buttons,
// toolbars, the app frame, monochrome glyphs and modal dialogs.
// Compiled after RelicSettings.HC and before RelicDesktop.HC.

U8 relic_top_line[STR_LEN];
U8 relic_status_date[16],relic_status_fps[24],relic_status_clock[16];
// DOOM frames per second, measured by the desktop presenter; -1 = not running.
I64 relic_doom_fps = -1;
Bool relic_status_show_keys = FALSE;
// One line of feedback shown in the footer of every app frame.
U8 relic_app_notice[160] = "";

U0 RelicStatusFormat()
{
  CDateStruct ds;

  Date2Struct(&ds, Now + local_time_offset);
  StrPrint(relic_status_date,"%02d/%02d/%04d",ds.mon,ds.day_of_mon,ds.year);
  if (relic_cfg.clock24)
    StrPrint(relic_status_clock,"%02d:%02d",ds.hour,ds.min);
  else
    StrPrint(relic_status_clock,"%d:%02d %s",(ds.hour+11)%12+1,ds.min,
          RelicText(ds.hour<12,"AM","PM"));
  relic_status_fps[0]=0;
  if (relic_cfg.stats) {
    if (relic_doom_fps>=0)
      StrPrint(relic_status_fps,"Game %d FPS",relic_doom_fps);
    else
      StrPrint(relic_status_fps,"%d FPS",ToI64(winmgr.fps+0.5));
  }
  StrPrint(relic_top_line,"%s  %s  %s",relic_status_date,relic_status_fps,
        relic_status_clock);
}

// Text layer: installed as gr.fp_wall_paper, so the WinMgr calls this for
// its own (bottom-most) window every frame.  Text row 0 is the only row of
// that window that is not covered by the maximised desktop, so this is the
// permanent status strip.  Never draw menus or borders here.
// Right-aligned date, FPS and clock, separated by three columns.
U0 RelicStatusWallPaper(CTask *_task)
{
  U8 *st,blank[256];
  I64 cols=GR_WIDTH/FONT_WIDTH,x_date,x_fps,x_clock;

  if (!_task)
    _task = Fs;

  winmgr.show_menu = FALSE;
  RelicStatusFormat;
  _task->text_attr = BLACK << 4 | LTGRAY;
  if (cols>255) cols=255;
  MemSet(blank,' ',cols);
  blank[cols]=0;
  TextPrint(_task,0,0,BLACK << 4 | LTGRAY,"%s",blank);
  x_clock=cols-1-StrLen(relic_status_clock);
  x_fps=x_clock-3-StrLen(relic_status_fps);
  x_date=x_fps-3-StrLen(relic_status_date);
  if (!relic_status_fps[0]) x_date=x_clock-3-StrLen(relic_status_date);
  TextPrint(_task,x_date,0,BLACK << 4 | LTGRAY,"%s",relic_status_date);
  if (relic_status_fps[0] && x_fps>0)
    TextPrint(_task,x_fps,0,BLACK << 4 | LTGRAY,"%s",relic_status_fps);
  TextPrint(_task,x_clock,0,BLACK << 4 | LTGRAY,"%s",relic_status_clock);
  if (scrncast.record)
    TextPrint(_task,x_clock-5,0,BLACK << 4 | WHITE,"REC");

  if (relic_status_show_keys) {
    st = ScanCode2KeyName(kbd.last_down_scan_code);
    TextPrint(_task,(cols-18)/2,0,BLACK << 4 | LTGRAY,"%18ts",st);
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

// ---- UI toolkit ----
// Colour roles.  Under the matte palette (RelicMatteApply) the low colour
// indices are grey steps; under the game/paint palette (RelicThemeApply) they
// are real colours, so the roles fall back to black, DKGRAY, LTGRAY, WHITE.
I64 rc_bg=BLACK,rc_panel=GREEN,rc_ctrl=PURPLE,rc_hover=LTCYAN,rc_sel=DKGRAY,
    rc_line=DKGRAY,rc_dim=LTBLUE,rc_text=LTGRAY,rc_strong=WHITE;

U0 RelicUIRoles(Bool matte)
{
  rc_bg=BLACK; rc_sel=DKGRAY; rc_line=DKGRAY; rc_text=LTGRAY; rc_strong=WHITE;
  if (matte) {
    rc_panel=GREEN; rc_ctrl=PURPLE; rc_hover=LTCYAN; rc_dim=LTBLUE;
  } else {
    rc_panel=BLACK; rc_ctrl=BLACK; rc_hover=DKGRAY; rc_dim=LTGRAY;
  }
}

// Pick roles from whatever palette is loaded right now.
U0 RelicUIRolesAuto()
{
  CBGR48 pal[COLORS_NUM];
  GrPaletteGet(pal);
  RelicUIRoles(pal[GREEN].r==pal[GREEN].g && pal[GREEN].g==pal[GREEN].b);
}

U0 RelicUIMatte()
{
  RelicMatteApply;
  RelicUIRoles(TRUE);
}

U0 RelicUIColour()
{
  RelicThemeApply;
  RelicUIRoles(FALSE);
}

// Bounded copy: never writes more than cap bytes including the NUL.
U0 RelicStrCopy(U8 *dst,U8 *src,I64 cap)
{
  I64 n=StrLen(src);
  if (cap<1) return;
  if (n>cap-1) n=cap-1;
  MemCpy(dst,src,n);
  dst[n]=0;
}

// Copy src into dst (at least cols+1 bytes) and end with "..." if cut.
U0 RelicFit(U8 *dst,U8 *src,I64 cols)
{
  I64 n=StrLen(src);
  if (cols>255) cols=255;
  if (cols<0) cols=0;
  if (n<=cols) {
    StrCpy(dst,src);
  } else if (cols<4) {
    MemCpy(dst,src,cols); dst[cols]=0;
  } else {
    MemCpy(dst,src,cols-3);
    StrCpy(dst+cols-3,"...");
  }
}

U0 RelicUIText(CDC *dc,I64 x,I64 y,I64 cols,U8 *s)
{
  U8 buf[256];
  RelicFit(buf,s,cols);
  GrPrint(dc,x,y,"%s",buf);
}

// Text centred in a box of width w starting at x.
U0 RelicUITextC(CDC *dc,I64 x,I64 y,I64 w,U8 *s)
{
  U8 buf[256];
  RelicFit(buf,s,w/FONT_WIDTH);
  GrPrint(dc,x+(w-StrLen(buf)*FONT_WIDTH)/2,y,"%s",buf);
}

// Word wrap at spaces; honours '\n'.  dc=NULL only counts lines.
I64 RelicUIWrap(CDC *dc,I64 x,I64 y,I64 cols,I64 lh,U8 *text)
{
  U8 line[256];
  I64 i=0,j,brk,n,lines=0;
  if (cols>255) cols=255;
  if (cols<1) cols=1;
  while (text[i]) {
    j=i; brk=-1;
    while (text[j] && text[j]!='\n' && j-i<cols) {
      if (text[j]==' ') brk=j;
      j++;
    }
    if (text[j] && text[j]!='\n' && text[j]!=' ' && brk>i)
      j=brk;
    n=j-i;
    MemCpy(line,text+i,n);
    line[n]=0;
    if (dc) GrPrint(dc,x,y+lines*lh,"%s",line);
    lines++;
    i=j;
    if (text[i]==' ' || text[i]=='\n') i++;
  }
  return lines;
}

Bool RelicUIIn(I64 mx,I64 my,I64 x,I64 y,I64 w,I64 h)
{
  return mx>=x && mx<x+w && my>=y && my<y+h;
}

// Mouse position relative to a task's client area.
U0 RelicUIMouse(CTask *task,I64 *x,I64 *y)
{
  *x=ms.pos.x-task->pix_left;
  *y=ms.pos.y-task->pix_top;
}

#define RUI_NORMAL 0
#define RUI_HOVER  1
#define RUI_ON     2
#define RUI_OFF    3
#define RUI_FOCUS  4
#define RUI_DOWN   5

I64 RelicUIState(CTask *task,I64 x,I64 y,I64 w,I64 h)
{
  I64 mx,my;
  RelicUIMouse(task,&mx,&my);
  if (!RelicUIIn(mx,my,x,y,w,h)) return RUI_NORMAL;
  if (ms.lb) return RUI_DOWN;
  return RUI_HOVER;
}

U0 RelicUIButton(CDC *dc,I64 x,I64 y,I64 w,I64 h,U8 *label,I64 state)
{
  I64 fill=rc_ctrl,line=rc_line,ink=rc_text;
  if (state==RUI_HOVER) { fill=rc_hover; ink=rc_strong; }
  else if (state==RUI_DOWN) { fill=rc_sel; ink=rc_strong; }
  else if (state==RUI_ON) { fill=rc_text; line=rc_text; ink=BLACK; }
  else if (state==RUI_OFF) { fill=rc_panel; line=rc_panel; ink=rc_line; }
  else if (state==RUI_FOCUS) { fill=rc_hover; line=rc_strong; ink=rc_strong; }
  dc->color=fill; GrRect(dc,x,y,w,h);
  dc->color=line; RelicOutline(dc,x,y,w,h);
  dc->color=ink;
  RelicUITextC(dc,x,y+(h-FONT_HEIGHT)/2,w,label);
}

U0 RelicUIScroll(CDC *dc,I64 x,I64 y,I64 h,I64 total,I64 visible,I64 first)
{
  I64 th,ty;
  if (total<=visible || h<8) return;
  dc->color=rc_panel; GrRect(dc,x,y,4,h);
  th=MaxI64(12,h*visible/total);
  ty=y+(h-th)*first/MaxI64(1,total-visible);
  dc->color=rc_dim; GrRect(dc,x,ty,4,th);
}

// ---- App frame ----
// Every graphical app shares this layout (client pixels, 640 x 472 here):
//   header   0..31   title left, close button right (W-40, 4, 32 x 24)
//   toolbar  38..59  optional row of buttons, rule at 66
//   content  RUI_TOP (72) or RUI_TOP_PLAIN (44) down to H-32
//   footer   H-24..H notice left, keyboard hint right
#define RUI_HDR_H     32
#define RUI_TB_X      12
#define RUI_TB_Y      38
#define RUI_TB_H      22
#define RUI_TB_GAP    6
#define RUI_TOP       72
#define RUI_TOP_PLAIN 44
#define RUI_FOOT_H    24

Bool RelicUICloseHit(I64 w,I64 mx,I64 my)
{
  return RelicUIIn(mx,my,w-40,4,32,24);
}

U0 RelicUIFrame(CTask *task,CDC *dc,U8 *title,U8 *hint,Bool toolbar)
{
  I64 w=task->pix_width,h=task->pix_height,st,cx,cy,hx,hcols;
  dc->color=rc_bg; GrRect(dc,0,0,w,h);
  dc->color=rc_panel; GrRect(dc,0,0,w,RUI_HDR_H);
  dc->color=rc_line; GrLine(dc,0,RUI_HDR_H,w-1,RUI_HDR_H);
  dc->color=rc_strong; RelicUIText(dc,16,12,(w-80)/FONT_WIDTH,title);
  st=RelicUIState(task,w-40,4,32,24);
  if (st!=RUI_NORMAL) {
    dc->color=RelicChoose(st==RUI_DOWN,rc_sel,rc_hover);
    GrRect(dc,w-40,4,32,24);
  }
  cx=w-24; cy=16;
  dc->color=RelicChoose(st==RUI_NORMAL,rc_text,rc_strong);
  GrLine(dc,cx-4,cy-4,cx+4,cy+4); GrLine(dc,cx+4,cy-4,cx-4,cy+4);
  if (toolbar) {
    dc->color=rc_line; GrLine(dc,0,66,w-1,66);
  }
  dc->color=rc_panel; GrRect(dc,0,h-RUI_FOOT_H,w,RUI_FOOT_H);
  dc->color=rc_line; GrLine(dc,0,h-RUI_FOOT_H-1,w-1,h-RUI_FOOT_H-1);
  hcols=StrLen(hint);
  if (hcols>(w/2-16)/FONT_WIDTH) hcols=(w/2-16)/FONT_WIDTH;
  hx=w-16-hcols*FONT_WIDTH;
  dc->color=rc_dim; RelicUIText(dc,hx,h-16,hcols,hint);
  dc->color=rc_text;
  RelicUIText(dc,16,h-16,(hx-32)/FONT_WIDTH,relic_app_notice);
}

// Toolbar: a row of buttons from RUI_TB_X; the label "|" is a separator.
I64 RelicUIItemW(U8 *label)
{
  if (!StrCmp(label,"|")) return 9;
  return MaxI64(28,StrLen(label)*FONT_WIDTH+20);
}

I64 RelicUIToolbarEnd(U8 **labels,I64 n)
{
  I64 i,x=RUI_TB_X;
  for (i=0;i<n;i++) x+=RelicUIItemW(labels[i])+RUI_TB_GAP;
  return x;
}

// on/off: bit i set = button i shown selected / disabled.
U0 RelicUIToolbar(CTask *task,CDC *dc,U8 **labels,I64 n,I64 on,I64 off)
{
  I64 i,x=RUI_TB_X,bw,st;
  for (i=0;i<n;i++) {
    bw=RelicUIItemW(labels[i]);
    if (!StrCmp(labels[i],"|")) {
      dc->color=rc_line;
      GrLine(dc,x+4,RUI_TB_Y+3,x+4,RUI_TB_Y+RUI_TB_H-4);
    } else {
      st=RelicUIState(task,x,RUI_TB_Y,bw,RUI_TB_H);
      if ((off>>i)&1) st=RUI_OFF;
      else if ((on>>i)&1 && st!=RUI_DOWN) st=RUI_ON;
      RelicUIButton(dc,x,RUI_TB_Y,bw,RUI_TB_H,labels[i],st);
    }
    x+=bw+RUI_TB_GAP;
  }
}

I64 RelicUIToolbarHit(U8 **labels,I64 n,I64 mx,I64 my)
{
  I64 i,x=RUI_TB_X,bw;
  if (my<RUI_TB_Y || my>=RUI_TB_Y+RUI_TB_H) return -1;
  for (i=0;i<n;i++) {
    bw=RelicUIItemW(labels[i]);
    if (StrCmp(labels[i],"|") && mx>=x && mx<x+bw) return i;
    x+=bw+RUI_TB_GAP;
  }
  return -1;
}

// ---- Monochrome glyphs ----
// Authored on a 24 x 24 grid and scaled to s pixels; drawn in dc->color.
U0 RelicGL(CDC *dc,I64 x,I64 y,I64 s,I64 x1,I64 y1,I64 x2,I64 y2)
{
  GrLine(dc,x+x1*s/24,y+y1*s/24,x+x2*s/24,y+y2*s/24);
}

U0 RelicGBox(CDC *dc,I64 x,I64 y,I64 s,I64 x1,I64 y1,I64 x2,I64 y2)
{
  RelicGL(dc,x,y,s,x1,y1,x2,y1); RelicGL(dc,x,y,s,x2,y1,x2,y2);
  RelicGL(dc,x,y,s,x2,y2,x1,y2); RelicGL(dc,x,y,s,x1,y2,x1,y1);
}

U0 RelicGFill(CDC *dc,I64 x,I64 y,I64 s,I64 x1,I64 y1,I64 x2,I64 y2)
{
  GrRect(dc,x+x1*s/24,y+y1*s/24,MaxI64(1,(x2-x1+1)*s/24),
        MaxI64(1,(y2-y1+1)*s/24));
}

U0 RelicGCirc(CDC *dc,I64 x,I64 y,I64 s,I64 cx,I64 cy,I64 r)
{
  GrCircle(dc,x+cx*s/24,y+cy*s/24,MaxI64(1,r*s/24));
}

#define RELIC_GLYPH_LAUNCHER -1
#define RELIC_GLYPH_FILE     100
#define RELIC_GLYPH_FOLDER   101

// ---- Icons ----
// Icons.BIN is built by tools/relic_icons.py from Fluent UI System Icons
// (MIT) and assets/icons/relic: "RICN", U32 count, then per icon I32 id,
// U32 size and size*size coverage bytes (0-15).  Coverage is blended over
// whatever is already on screen, picking the nearest matte grey, so the
// edges stay smooth in 16 colours.
U8 *relic_icons=NULL;
I64 relic_icons_size=0,relic_icons_n=0;
// Grey level of each matte palette slot (RelicMatteApply).  RED, LTGREEN
// and LTRED are colours, so they are never picked as a blend result.
U8 relic_icon_lum[16]={0x00,0x08,0x10,0xDD,0x40,0x18,0x20,0xBB,
                       0x38,0x88,0x80,0x28,0x80,0x60,0xEE,0xFF};
U8 relic_icon_grey[16]={1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1};
U8 relic_icon_mix[16*16*16];

U0 RelicIconsLoad()
{
  I64 bg,fg,a,i,lum,d,best,best_d;
  U32 *hdr;
  if (relic_icons) Free(relic_icons);
  relic_icons=FileRead("::/Home/RelicOS/Icons.BIN",&relic_icons_size);
  relic_icons_n=0;
  if (relic_icons) {
    hdr=relic_icons;
    if (relic_icons_size<8 || MemCmp(relic_icons,"RICN",4)) {
      Free(relic_icons);
      relic_icons=NULL;
    } else
      relic_icons_n=hdr[1];
  }
  for (bg=0;bg<16;bg++)
    for (fg=0;fg<16;fg++)
      for (a=0;a<16;a++) {
        lum=relic_icon_lum[bg]+(relic_icon_lum[fg]-relic_icon_lum[bg])*a/15;
        best=bg; best_d=I64_MAX;
        for (i=0;i<16;i++) {
          d=AbsI64(relic_icon_lum[i]-lum);
          if (relic_icon_grey[i] && d<best_d) {
            best=i; best_d=d;
          }
        }
        if (a==15) best=fg;
        relic_icon_mix[(bg*16+fg)*16+a]=best;
      }
}

U8 *RelicIconFind(I64 id,I64 s)
{
  U8 *p,*end;
  I32 *e;
  I64 i;
  if (!relic_icons) return NULL;
  p=relic_icons+8;
  end=relic_icons+relic_icons_size;
  for (i=0;i<relic_icons_n && p+8<=end;i++) {
    e=p;
    if (e[1]<=0 || p+8+e[1]*e[1]>end) return NULL;
    if (e[0]==id && e[1]==s) return p+8;
    p+=8+e[1]*e[1];
  }
  return NULL;
}

// Draws in dc->color.  FALSE when Icons.BIN has no such icon.
Bool RelicIconDraw(CDC *dc,I64 id,I64 x,I64 y,I64 s)
{
  U8 *cov=RelicIconFind(id,s);
  I64 i,j,a,bg,fg=dc->color&15,old=dc->color;
  Bool matte=rc_panel!=BLACK;
  if (!cov) return FALSE;
  for (j=0;j<s;j++)
    for (i=0;i<s;i++) {
      a=*cov++;
      if (a && matte) {
        bg=GrPeek(dc,x+i,y+j);
        if (bg>=0) {
          dc->color=relic_icon_mix[((bg&15)*16+fg)*16+a];
          GrPlot(dc,x+i,y+j);
        }
      } else if (a>=8) {
        dc->color=fg;
        GrPlot(dc,x+i,y+j);
      }
    }
  dc->color=old;
  return TRUE;
}

// App icons, indexed like app_tips[] in RelicDesktop.HC.  The line
// drawings below are only used when Icons.BIN is missing.
U0 RelicAppGlyph(CDC *dc,I64 app,I64 x,I64 y,I64 s)
{
  I64 i,j;
  if (RelicIconDraw(dc,app,x,y,s)) return;
  switch (app) {
    case RELIC_GLYPH_LAUNCHER:
      RelicGFill(dc,x,y,s,4,4,10,10); RelicGFill(dc,x,y,s,13,4,19,10);
      RelicGFill(dc,x,y,s,4,13,10,19); RelicGFill(dc,x,y,s,13,13,19,19);
      break;
    case 0:
    case RELIC_GLYPH_FOLDER:
      RelicGBox(dc,x,y,s,2,8,21,20);
      RelicGFill(dc,x,y,s,3,9,20,11);
      RelicGL(dc,x,y,s,2,8,2,4); RelicGL(dc,x,y,s,2,4,9,4);
      RelicGL(dc,x,y,s,9,4,12,8); RelicGL(dc,x,y,s,3,19,20,19);
      break;
    case 1:
      RelicGBox(dc,x,y,s,5,2,18,21);
      for (i=0;i<4;i++) RelicGL(dc,x,y,s,8,7+i*4,15,7+i*4);
      break;
    case 2:
      RelicGBox(dc,x,y,s,2,4,21,19);
      RelicGL(dc,x,y,s,6,9,9,12); RelicGL(dc,x,y,s,9,12,6,15);
      RelicGL(dc,x,y,s,11,15,16,15);
      break;
    case 3:
      RelicGBox(dc,x,y,s,2,7,21,17);
      RelicGL(dc,x,y,s,5,12,10,12); RelicGL(dc,x,y,s,7,10,7,14);
      RelicGFill(dc,x,y,s,14,10,15,11); RelicGFill(dc,x,y,s,17,13,18,14);
      break;
    case 4:
      RelicGFill(dc,x,y,s,3,5,20,6); RelicGFill(dc,x,y,s,3,11,14,12);
      RelicGFill(dc,x,y,s,3,17,17,18);
      break;
    case 5:
      RelicGBox(dc,x,y,s,6,6,17,17);
      for (i=0;i<4;i++) {
        RelicGL(dc,x,y,s,8+i*2,2,8+i*2,6);
        RelicGL(dc,x,y,s,8+i*2,17,8+i*2,21);
      }
      break;
    case 6:
      RelicGBox(dc,x,y,s,2,3,21,16);
      RelicGL(dc,x,y,s,11,16,11,19); RelicGL(dc,x,y,s,7,20,16,20);
      break;
    case 7:
      RelicGCirc(dc,x,y,s,11,11,10);
      GrPrint(dc,x+11*s/24-3,y+11*s/24-3,"?");
      break;
    case 8:
      RelicGCirc(dc,x,y,s,11,11,10);
      RelicGL(dc,x,y,s,1,11,21,11);
      RelicGL(dc,x,y,s,3,6,19,6);
      RelicGL(dc,x,y,s,3,16,19,16);
      RelicGL(dc,x,y,s,11,1,8,4); RelicGL(dc,x,y,s,8,4,7,8);
      RelicGL(dc,x,y,s,7,8,7,14); RelicGL(dc,x,y,s,7,14,8,18);
      RelicGL(dc,x,y,s,8,18,11,21);
      RelicGL(dc,x,y,s,11,1,14,4); RelicGL(dc,x,y,s,14,4,15,8);
      RelicGL(dc,x,y,s,15,8,15,14); RelicGL(dc,x,y,s,15,14,14,18);
      RelicGL(dc,x,y,s,14,18,11,21);
      break;
    case 9:
      RelicGL(dc,x,y,s,3,20,13,10); RelicGL(dc,x,y,s,4,21,14,11);
      RelicGBox(dc,x,y,s,13,6,17,10);
      RelicGL(dc,x,y,s,17,6,21,2);
      break;
    case 10:
      RelicGBox(dc,x,y,s,5,2,18,21);
      RelicGBox(dc,x,y,s,7,4,16,8);
      for (j=0;j<3;j++) for (i=0;i<3;i++)
        RelicGFill(dc,x,y,s,7+i*4,11+j*3,8+i*4,12+j*3);
      break;
    case 11:
      RelicGBox(dc,x,y,s,3,5,20,20);
      RelicGL(dc,x,y,s,3,9,20,9);
      RelicGL(dc,x,y,s,8,3,8,6); RelicGL(dc,x,y,s,15,3,15,6);
      for (j=0;j<2;j++) for (i=0;i<3;i++)
        RelicGFill(dc,x,y,s,6+i*5,12+j*4,7+i*5,13+j*4);
      break;
    case 12:
      RelicGCirc(dc,x,y,s,11,11,6); RelicGCirc(dc,x,y,s,11,11,2);
      RelicGL(dc,x,y,s,11,1,11,5); RelicGL(dc,x,y,s,11,17,11,21);
      RelicGL(dc,x,y,s,1,11,5,11); RelicGL(dc,x,y,s,17,11,21,11);
      RelicGL(dc,x,y,s,4,4,7,7); RelicGL(dc,x,y,s,15,15,18,18);
      RelicGL(dc,x,y,s,18,4,15,7); RelicGL(dc,x,y,s,4,18,7,15);
      break;
    case 13:
      RelicGL(dc,x,y,s,3,3,20,3); RelicGL(dc,x,y,s,20,3,20,14);
      RelicGL(dc,x,y,s,20,14,14,20); RelicGL(dc,x,y,s,14,20,3,20);
      RelicGL(dc,x,y,s,3,20,3,3);
      RelicGL(dc,x,y,s,14,20,14,14); RelicGL(dc,x,y,s,14,14,20,14);
      RelicGL(dc,x,y,s,7,8,16,8); RelicGL(dc,x,y,s,7,11,13,11);
      break;
    case RELIC_GLYPH_FILE:
      RelicGL(dc,x,y,s,5,2,14,2); RelicGL(dc,x,y,s,14,2,18,6);
      RelicGL(dc,x,y,s,18,6,18,21); RelicGL(dc,x,y,s,18,21,5,21);
      RelicGL(dc,x,y,s,5,21,5,2);
      RelicGL(dc,x,y,s,14,2,14,6); RelicGL(dc,x,y,s,14,6,18,6);
      break;
  }
}

// ---- Modal dialogs ----
// Drawn over whatever the task was drawing (its draw_it is called first and
// restored afterwards).  Keyboard: Tab / arrows move focus, Enter activates,
// Esc cancels, the first letter of a button picks it.  Mouse: click.
U8 relic_dlg_title[64],relic_dlg_msg[1024],relic_dlg_btn[3][24];
U8 relic_dlg_text[512];
I64 relic_dlg_n=0,relic_dlg_focus=0,relic_dlg_cap=0,relic_dlg_w=400;
I64 relic_dlg_x,relic_dlg_y,relic_dlg_h,relic_dlg_fy,relic_dlg_by;
I64 relic_dlg_bx[3],relic_dlg_bw[3];
Bool relic_dlg_input=FALSE;
F64 relic_dlg_t0=0;
U0 (*relic_dlg_under)(CTask *,CDC *)=NULL;

U0 RelicDlgLayout(I64 w,I64 h)
{
  I64 i,lines,total=0,x;
  relic_dlg_w=400;
  if (StrLen(relic_dlg_msg)>200) relic_dlg_w=520;
  relic_dlg_w=MinI64(relic_dlg_w,w-32);
  lines=RelicUIWrap(NULL,0,0,(relic_dlg_w-40)/FONT_WIDTH,12,relic_dlg_msg);
  relic_dlg_h=44+lines*12;
  if (lines) relic_dlg_h+=8;
  relic_dlg_fy=relic_dlg_h;
  if (relic_dlg_input) relic_dlg_h+=24+12;
  relic_dlg_h+=8;
  relic_dlg_by=relic_dlg_h;
  relic_dlg_h+=24+16;
  relic_dlg_x=(w-relic_dlg_w)/2;
  relic_dlg_y=MaxI64(8,(h-relic_dlg_h)/2-16);
  relic_dlg_fy+=relic_dlg_y;
  relic_dlg_by+=relic_dlg_y;
  for (i=0;i<relic_dlg_n;i++) {
    relic_dlg_bw[i]=MaxI64(80,StrLen(relic_dlg_btn[i])*FONT_WIDTH+24);
    total+=relic_dlg_bw[i]+8;
  }
  x=relic_dlg_x+relic_dlg_w-20-total+8;
  for (i=0;i<relic_dlg_n;i++) {
    relic_dlg_bx[i]=x;
    x+=relic_dlg_bw[i]+8;
  }
}

U0 RelicDialogDraw(CTask *task,CDC *dc)
{
  I64 i,st,x,y,w,h,dy=0,len,cols,start;
  F64 p;
  if (relic_dlg_under) (*relic_dlg_under)(task,dc);
  RelicDlgLayout(task->pix_width,task->pix_height);
  if (relic_cfg.animations) {
    p=Clamp((tS-relic_dlg_t0)/0.167,0,1);
    p=1-(1-p)*(1-p)*(1-p);
    dy=ToI64((1-p)*10);
  }
  x=relic_dlg_x; y=relic_dlg_y+dy; w=relic_dlg_w; h=relic_dlg_h;
  dc->color=BLACK; GrRect(dc,x+3,y+3,w,h);
  dc->color=rc_panel; GrRect(dc,x,y,w,h);
  dc->color=rc_dim; RelicOutline(dc,x,y,w,h);
  dc->color=rc_strong; RelicUIText(dc,x+20,y+20,(w-40)/FONT_WIDTH,relic_dlg_title);
  dc->color=rc_text;
  RelicUIWrap(dc,x+20,y+44,(w-40)/FONT_WIDTH,12,relic_dlg_msg);
  if (relic_dlg_input) {
    dc->color=BLACK; GrRect(dc,x+20,relic_dlg_fy+dy,w-40,24);
    dc->color=RelicChoose(relic_dlg_focus<0,rc_strong,rc_line);
    RelicOutline(dc,x+20,relic_dlg_fy+dy,w-40,24);
    len=StrLen(relic_dlg_text);
    cols=(w-56)/FONT_WIDTH-1;
    start=MaxI64(0,len-cols);
    dc->color=rc_strong;
    GrPrint(dc,x+28,relic_dlg_fy+dy+8,"%s",relic_dlg_text+start);
    if (relic_dlg_focus<0)
      GrRect(dc,x+28+(len-start)*FONT_WIDTH+1,relic_dlg_fy+dy+6,1,12);
  }
  for (i=0;i<relic_dlg_n;i++) {
    st=RelicUIState(task,relic_dlg_bx[i],relic_dlg_by,relic_dlg_bw[i],24);
    if (st==RUI_NORMAL && i==relic_dlg_focus) st=RUI_FOCUS;
    RelicUIButton(dc,relic_dlg_bx[i],relic_dlg_by+dy,relic_dlg_bw[i],24,
          relic_dlg_btn[i],st);
  }
}

U0 RelicDlgSetup(U8 *title,U8 *msg,U8 *b0,U8 *b1,U8 *b2)
{
  RelicStrCopy(relic_dlg_title,title,sizeof(relic_dlg_title));
  if (msg) RelicStrCopy(relic_dlg_msg,msg,sizeof(relic_dlg_msg));
  else relic_dlg_msg[0]=0;
  relic_dlg_n=0;
  if (b0) RelicStrCopy(relic_dlg_btn[relic_dlg_n++],b0,24);
  if (b1) RelicStrCopy(relic_dlg_btn[relic_dlg_n++],b1,24);
  if (b2) RelicStrCopy(relic_dlg_btn[relic_dlg_n++],b2,24);
}

// Returns the chosen button index, or cancel for Esc.
I64 RelicDialogRun(I64 dft,I64 cancel)
{
  I64 ch,sc,mc,mx,my,i,len,res=-2,guard=0;
  U0 (*under)(CTask *,CDC *);
  under=Fs->draw_it;
  if (under!=&RelicDialogDraw)
    relic_dlg_under=under;
  if (cancel<0) cancel=relic_dlg_n-1;
  relic_dlg_focus=dft;
  if (relic_dlg_input) relic_dlg_focus=-1;
  relic_dlg_t0=tS;
  RelicUIRolesAuto;
  Fs->draw_it=&RelicDialogDraw;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  FlushMsgs;
  while (res==-2) {
    mc=ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN | 1<<MSG_MS_L_DOWN);
    if (!mc) {
      Sleep(10);
    } else if (mc==MSG_MS_L_DOWN) {
      RelicUIMouse(Fs,&mx,&my);
      RelicDlgLayout(Fs->pix_width,Fs->pix_height);
      for (i=0;i<relic_dlg_n;i++)
        if (RelicUIIn(mx,my,relic_dlg_bx[i],relic_dlg_by,relic_dlg_bw[i],24))
          res=i;
      if (relic_dlg_input &&
            RelicUIIn(mx,my,relic_dlg_x+20,relic_dlg_fy,relic_dlg_w-40,24))
        relic_dlg_focus=-1;
    } else if (ch==CH_ESC || ch==CH_SHIFT_ESC) {
      res=cancel;
    } else if (ch=='\n') {
      if (relic_dlg_focus<0) res=0;
      else res=relic_dlg_focus;
    } else if (ch=='\t' || (sc&0xFF)==SC_CURSOR_RIGHT && !relic_dlg_input ||
          (sc&0xFF)==SC_CURSOR_DOWN && !relic_dlg_input) {
      relic_dlg_focus++;
      if (relic_dlg_focus>=relic_dlg_n) {
        if (relic_dlg_input) relic_dlg_focus=-1;
        else relic_dlg_focus=0;
      }
    } else if (!relic_dlg_input &&
          ((sc&0xFF)==SC_CURSOR_LEFT || (sc&0xFF)==SC_CURSOR_UP)) {
      relic_dlg_focus=(relic_dlg_focus+relic_dlg_n-1)%relic_dlg_n;
    } else if (relic_dlg_input) {
      len=StrLen(relic_dlg_text);
      if (ch==CH_BACKSPACE) {
        if (len) relic_dlg_text[len-1]=0;
      } else if (ch>=' ' && ch<127 && ch!='$$' && len<relic_dlg_cap-1 &&
            len<sizeof(relic_dlg_text)-1) {
        relic_dlg_text[len]=ch;
        relic_dlg_text[len+1]=0;
      }
      relic_dlg_focus=-1;
    } else if (ch==' ') {
      res=relic_dlg_focus;
    } else if (ch>' ' && ch<127) {
      for (i=relic_dlg_n-1;i>=0;i--)
        if (ToUpper(ch)==ToUpper(relic_dlg_btn[i][0]))
          res=i;
    }
  }
  Fs->draw_it=under;
  relic_dlg_input=FALSE;
  // Let go of the button first, so the app does not see the same press.
  while (ms.lb && guard<300) {
    Sleep(10);
    guard++;
  }
  FlushMsgs;
  return res;
}

// Up to three buttons, left to right.  dft = focused button, cancel = value
// returned for Esc (-1: the last button).
I64 RelicDialog(U8 *title,U8 *msg,U8 *b0,U8 *b1=NULL,U8 *b2=NULL,
      I64 dft=0,I64 cancel=-1)
{
  RelicDlgSetup(title,msg,b0,b1,b2);
  relic_dlg_input=FALSE;
  return RelicDialogRun(dft,cancel);
}

U0 RelicNotify(U8 *title,U8 *msg)
{
  RelicDialog(title,msg,"OK");
}

// Text entry dialog.  The field starts with dft.  TRUE on OK.
Bool RelicAskEx(U8 *title,U8 *msg,U8 *out,I64 cap,U8 *dft=NULL)
{
  RelicDlgSetup(title,msg,"OK","Cancel",NULL);
  relic_dlg_input=TRUE;
  relic_dlg_cap=MinI64(cap,sizeof(relic_dlg_text));
  relic_dlg_text[0]=0;
  if (dft) RelicStrCopy(relic_dlg_text,dft,relic_dlg_cap);
  if (RelicDialogRun(0,1)) return FALSE;
  RelicStrCopy(out,relic_dlg_text,cap);
  return TRUE;
}

Bool RelicAsk(U8 *label,U8 *out,I64 cap,U8 *dft=NULL)
{
  return RelicAskEx(label,NULL,out,cap,dft);
}

// Yes / No.  Enter and Esc both answer No; Y answers Yes.
Bool RelicConfirm(U8 *label)
{
  return RelicDialog("Confirm",label,"Yes","No",NULL,1,1)==0;
}
