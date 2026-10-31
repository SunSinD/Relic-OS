// RelicApps.HC - graphical apps of the desktop.
// Included by RelicDesktop.HC after RelicAppStart; the frame, buttons and
// dialogs come from RelicChrome.HC.  Every app runs inline on the desktop
// task with its own draw_it and returns when the user presses Esc or the
// close button.

U0 RelicAppGraphics(U0 (*draw)(CTask *,CDC *))
{
  RelicAppStart;
  DocCursor(OFF);
  relic_app_notice[0]=0;
  RelicUIRolesAuto;
  Fs->draw_it=draw;
}

// Next app message, or 0 after a short sleep.
I64 RelicAppMsg(I64 *ch,I64 *sc)
{
  I64 mc=ScanMsg(ch,sc,1<<MSG_KEY_DOWN | 1<<MSG_MS_L_DOWN | 1<<MSG_MS_L_D_DOWN);
  if (!mc) Sleep(10);
  return mc;
}

// Mouse wheel steps since the last call (positive = toward the user).
I64 RelicWheel(I64 *last)
{
  I64 d=ms.pos.z-*last;
  *last=ms.pos.z;
  return d;
}

// ---- Editor ----
U0 RelicEditPath(U8 *path)
{
  RelicAppStart;
  WinBorder(ON); WinMax;
  Fs->title_src=TTS_ED_FILENAME;
  Ed(path,DOF_DONT_TEXT_ATTR);
  Fs->title_src=TTS_LOCKED_CONST;
  RelicUIMatte;
  RelicAppStart;
}

// TRUE if the file is missing or holds only blanks.
Bool RelicFileBlank(U8 *path)
{
  U8 *data;
  I64 size,i;
  Bool blank=TRUE;
  if (!FileFind(path)) return TRUE;
  data=FileRead(path,&size);
  if (!data) return FALSE;
  for (i=0;i<size;i++)
    if (data[i]>' ') blank=FALSE;
  Free(data);
  return blank;
}

// Edit opens a fresh document straight away (RelicData/Documents/UntitledN).
// Leaving it empty leaves no file behind.
U0 RelicEditorApp()
{
  U8 dir[160],path[200];
  I64 i;
  StrPrint(dir,"%s/Documents",relic_data_dir);
  if (!FileFind(dir,,FUF_JUST_DIRS)) DirMk(dir);
  for (i=1;i<1000;i++) {
    StrPrint(path,"%s/Untitled%d.TXT",dir,i);
    if (!FileFind(path)) break;
  }
  RelicEditPath(path);
  if (FileFind(path) && RelicFileBlank(path)) Del(path);
}

U0 RelicNotesApp()
{
  U8 note[160];
  StrPrint(note,"%s/Notes.TXT",relic_data_dir);
  RelicEditPath(note);
}

// ---- Files ----
#define RELIC_FILES_ROW_Y 114
#define RELIC_FILES_ROW_H 18
CDirEntry *relic_files=NULL;
CDirEntry *relic_file_rows[2048];
I64 relic_file_count=0,relic_file_sel=0,relic_file_scroll=0;
U8 relic_file_path[512]="::/Home";
U8 *relic_files_tb[9]={"Up","Open","|","New file","New folder","Rename",
  "Copy","Delete","Go to"};

I64 RelicFilesRows(I64 h)
{
  return MaxI64(1,(h-RUI_FOOT_H-8-RELIC_FILES_ROW_Y)/RELIC_FILES_ROW_H);
}

U0 RelicFilesRead()
{
  CDirEntry *de;
  U8 mask[600],*absolute;
  if (relic_files) DirTreeDel(relic_files);
  relic_files=NULL; relic_file_count=0; relic_file_sel=0; relic_file_scroll=0;
  if (!Cd(relic_file_path)) { StrCpy(relic_app_notice,"Folder unavailable."); return; }
  absolute=DirCur;
  if (StrLen(absolute)<sizeof(relic_file_path)) StrCpy(relic_file_path,absolute);
  Free(absolute);
  StrPrint(mask,"%s/*",relic_file_path);
  relic_files=FilesFind(mask);
  de=relic_files;
  while (de && relic_file_count<2048) {
    if (StrCmp(de->name,".") && StrCmp(de->name,".."))
      relic_file_rows[relic_file_count++]=de;
    de=de->next;
  }
}

U0 RelicFilesSelectName(U8 *name)
{
  I64 i;
  for (i=0;i<relic_file_count;i++)
    if (!StrICmp(relic_file_rows[i]->name,name))
      relic_file_sel=i;
}

U0 RelicFilesVisible(I64 h)
{
  I64 rows=RelicFilesRows(h);
  if (relic_file_sel<relic_file_scroll) relic_file_scroll=relic_file_sel;
  if (relic_file_sel>=relic_file_scroll+rows) relic_file_scroll=relic_file_sel-rows+1;
}

U0 RelicFilesSize(I64 size,U8 *out)
{
  if (size<1024) StrPrint(out,"%d B",size);
  else if (size<1024*1024) StrPrint(out,"%d KB",(size+1023)/1024);
  else StrPrint(out,"%d.%d MB",size/(1024*1024),size%(1024*1024)*10/(1024*1024));
}

U0 RelicFilesDraw(CTask *task,CDC *dc)
{
  I64 w=task->pix_width,h=task->pix_height,i,n,y,rows,off=0,st,tx;
  CDirEntry *de;
  U8 buf[64],*ext;
  if (!relic_file_count) off=1<<1 | 1<<5 | 1<<6 | 1<<7;
  RelicUIFrame(task,dc,"Files","Enter open  Backspace up  Del delete  Esc close",TRUE);
  RelicUIToolbar(task,dc,relic_files_tb,9,0,off);
  // Path bar (click to type a folder)
  st=RelicUIState(task,16,RUI_TOP,w-32,20);
  dc->color=BLACK; GrRect(dc,16,RUI_TOP,w-32,20);
  dc->color=RelicChoose(st==RUI_NORMAL,rc_line,rc_dim);
  RelicOutline(dc,16,RUI_TOP,w-32,20);
  dc->color=rc_text; RelicUIText(dc,24,RUI_TOP+6,(w-48)/FONT_WIDTH,relic_file_path);
  // Column header
  tx=w-200;
  dc->color=rc_dim;
  GrPrint(dc,40,RUI_TOP+30,"Name");
  GrPrint(dc,tx,RUI_TOP+30,"Type");
  GrPrint(dc,w-36-4*FONT_WIDTH,RUI_TOP+30,"Size");
  dc->color=rc_line; GrLine(dc,16,RELIC_FILES_ROW_Y-3,w-17,RELIC_FILES_ROW_Y-3);
  rows=RelicFilesRows(h);
  if (!relic_file_count) {
    dc->color=rc_dim; GrPrint(dc,40,RELIC_FILES_ROW_Y+6,"This folder is empty.");
  }
  for (i=0;i<rows;i++) {
    n=relic_file_scroll+i;
    if (n<relic_file_count) {
      y=RELIC_FILES_ROW_Y+i*RELIC_FILES_ROW_H; de=relic_file_rows[n];
      st=RelicUIState(task,16,y,w-40,RELIC_FILES_ROW_H);
      if (n==relic_file_sel) {
        dc->color=rc_sel; GrRect(dc,16,y,w-40,RELIC_FILES_ROW_H);
        dc->color=rc_strong; GrRect(dc,16,y,2,RELIC_FILES_ROW_H);
      } else if (st!=RUI_NORMAL) {
        dc->color=rc_hover; GrRect(dc,16,y,w-40,RELIC_FILES_ROW_H);
      }
      dc->color=RelicChoose(n==relic_file_sel,rc_strong,rc_text);
      if (de->attr & RS_ATTR_DIR) {
        RelicAppGlyph(dc,RELIC_GLYPH_FOLDER,20,y+1,16);
        RelicUIText(dc,40,y+5,(tx-48)/FONT_WIDTH,de->name);
        dc->color=rc_dim; GrPrint(dc,tx,y+5,"Folder");
      } else {
        RelicAppGlyph(dc,RELIC_GLYPH_FILE,20,y+1,16);
        RelicUIText(dc,40,y+5,(tx-48)/FONT_WIDTH,de->name);
        ext=StrFirstOcc(de->name,".");
        dc->color=rc_dim;
        if (ext && ext[1]) RelicUIText(dc,tx,y+5,10,ext+1);
        else GrPrint(dc,tx,y+5,"File");
        RelicFilesSize(de->size,buf);
        GrPrint(dc,w-36-StrLen(buf)*FONT_WIDTH,y+5,"%s",buf);
      }
    }
  }
  RelicUIScroll(dc,w-14,RELIC_FILES_ROW_Y,rows*RELIC_FILES_ROW_H,
        relic_file_count,rows,relic_file_scroll);
}

// Joins a typed name onto the current folder unless it is already a path.
Bool RelicFilesTarget(U8 *answer,U8 *out,I64 cap)
{
  if (!answer[0]) return FALSE;
  if (StrFirstOcc(answer,"/:")) {
    if (StrLen(answer)>=cap) return FALSE;
    StrCpy(out,answer);
    return TRUE;
  }
  if (StrLen(relic_file_path)+StrLen(answer)+2>cap) return FALSE;
  StrPrint(out,"%s/%s",relic_file_path,answer);
  return TRUE;
}

// Toolbar actions; keys map onto the same numbers.
#define RFA_UP     0
#define RFA_OPEN   1
#define RFA_NEW    3
#define RFA_FOLDER 4
#define RFA_RENAME 5
#define RFA_COPY   6
#define RFA_DELETE 7
#define RFA_GOTO   8

// Returns TRUE when the listing must be read again.
Bool RelicFilesAction(I64 act)
{
  U8 path[600],answer[512],dest[600],msg[700],name[64],*parent,*last;
  CDirEntry *de=NULL;
  if (act==RFA_UP) {
    last=StrLastOcc(relic_file_path,"/");
    name[0]=0;
    if (last && StrLen(last+1)<sizeof(name)) StrCpy(name,last+1);
    Cd(relic_file_path); parent=FileNameAbs("..");
    if (StrLen(parent)<sizeof(relic_file_path)) StrCpy(relic_file_path,parent);
    Free(parent);
    RelicFilesRead;
    if (name[0]) RelicFilesSelectName(name);
    return FALSE;
  }
  if (act==RFA_GOTO) {
    Cd(relic_file_path);
    if (RelicAskEx("Go to folder","Type a folder path, for example ::/Home or C:/.",
          answer,sizeof(answer),relic_file_path)) {
      if (answer[0] && FileFind(answer,,FUF_JUST_DIRS)) {
        parent=FileNameAbs(answer);
        if (StrLen(parent)<sizeof(relic_file_path)) StrCpy(relic_file_path,parent);
        Free(parent);
        return TRUE;
      } else StrCpy(relic_app_notice,"Folder not found.");
    }
    return FALSE;
  }
  if (act==RFA_NEW || act==RFA_FOLDER) {
    if (RelicAskEx(RelicText(act==RFA_FOLDER,"New folder","New file"),
          "Name, without a slash or drive letter.",answer,64)) {
      if (answer[0] && !StrFirstOcc(answer,"/:\\*") && StrCmp(answer,".") &&
            StrCmp(answer,"..")) {
        StrPrint(path,"%s/%s",relic_file_path,answer);
        if (FileFind(path)) StrCpy(relic_app_notice,"Name already exists.");
        else {
          if (act==RFA_FOLDER) DirMk(path);
          else FileWrite(path,"",0);
          RelicFilesRead;
          RelicFilesSelectName(answer);
        }
      } else StrCpy(relic_app_notice,"That name is not allowed.");
    }
    return FALSE;
  }
  if (!relic_file_count) return FALSE;
  de=relic_file_rows[relic_file_sel];
  StrPrint(path,"%s/%s",relic_file_path,de->name);
  if (act==RFA_OPEN) {
    if (de->attr & RS_ATTR_DIR) {
      if (StrLen(path)<sizeof(relic_file_path)) {
        StrCpy(relic_file_path,path); return TRUE;
      }
    } else if (de->size>1024*1024)
      StrCpy(relic_app_notice,"File exceeds the editor's 1 MiB limit.");
    else {
      StrCpy(name,"");
      if (StrLen(de->name)<sizeof(name)) StrCpy(name,de->name);
      RelicEditPath(path); Cd(relic_file_path);
      Fs->draw_it=&RelicFilesDraw;
      RelicFilesRead;
      if (name[0]) RelicFilesSelectName(name);
    }
    return FALSE;
  }
  if (act==RFA_RENAME || act==RFA_COPY) {
    if (de->attr & RS_ATTR_DIR) {
      StrCpy(relic_app_notice,"Folder rename/copy is available in the Shell.");
      return FALSE;
    }
    Cd(relic_file_path);
    StrPrint(msg,"%s %s to (a name in this folder, or a full path):",
          RelicText(act==RFA_COPY,"Copy","Rename"),de->name);
    if (RelicAskEx(RelicText(act==RFA_COPY,"Copy file","Rename file"),msg,
          answer,sizeof(answer),de->name)) {
      if (RelicFilesTarget(answer,dest,sizeof(dest)) && !FileFind(dest)) {
        if (act==RFA_RENAME) {
          if (!Move(path,dest)) StrCpy(relic_app_notice,"Rename failed.");
        } else if (!Copy(path,dest)) StrCpy(relic_app_notice,"Copy failed.");
        RelicFilesRead;
        if (!StrFirstOcc(answer,"/:")) RelicFilesSelectName(answer);
      } else StrCpy(relic_app_notice,"Destination empty or already exists.");
    }
    return FALSE;
  }
  if (act==RFA_DELETE) {
    if (de->attr & RS_ATTR_DIR) {
      StrCpy(relic_app_notice,"Use the Shell to remove folders.");
      return FALSE;
    }
    StrPrint(msg,"Delete %s permanently? This cannot be undone.",de->name);
    if (!RelicDialog("Delete file",msg,"Delete","Cancel",NULL,1,1)) {
      if (!Del(path)) StrCpy(relic_app_notice,"Delete failed.");
      return TRUE;
    }
  }
  return FALSE;
}

U0 RelicFilesApp()
{
  I64 ch,sc,mc,mx,my,i,w,h,rows,last_z=ms.pos.z,d,act,last_click=-1;
  F64 click_time=-1.0;
  Bool done=FALSE,refresh,follow;
  RelicFilesRead;
  RelicAppGraphics(&RelicFilesDraw);
  while (!done) {
    w=Fs->pix_width; h=Fs->pix_height; rows=RelicFilesRows(h);
    d=RelicWheel(&last_z);
    if (d) relic_file_scroll=ClampI64(relic_file_scroll+d*3,0,
          MaxI64(0,relic_file_count-rows));
    mc=RelicAppMsg(&ch,&sc);
    if (mc) {
      refresh=FALSE; follow=TRUE; act=-1;
      if (mc==MSG_MS_L_DOWN || mc==MSG_MS_L_D_DOWN) {
        follow=FALSE;
        RelicUIMouse(Fs,&mx,&my);
        if (RelicUICloseHit(w,mx,my)) done=TRUE;
        else if (RelicUIIn(mx,my,16,RUI_TOP,w-32,20)) act=RFA_GOTO;
        else if (my>=RUI_TB_Y && my<RUI_TB_Y+RUI_TB_H)
          act=RelicUIToolbarHit(relic_files_tb,9,mx,my);
        else if (mx>=16 && mx<w-24 && my>=RELIC_FILES_ROW_Y &&
              my<RELIC_FILES_ROW_Y+rows*RELIC_FILES_ROW_H) {
          i=(my-RELIC_FILES_ROW_Y)/RELIC_FILES_ROW_H+relic_file_scroll;
          if (i<relic_file_count) {
            relic_file_sel=i;
            if (mc==MSG_MS_L_D_DOWN || (last_click==i && tS-click_time<=ms.dbl_time)) {
              act=RFA_OPEN; last_click=-1; click_time=-1.0;
            } else { last_click=i; click_time=tS; }
          }
        }
      } else if (ch==CH_ESC || ch==CH_SHIFT_ESC) done=TRUE;
      else if ((sc&0xFF)==SC_CURSOR_UP && relic_file_sel>0) relic_file_sel--;
      else if ((sc&0xFF)==SC_CURSOR_DOWN && relic_file_sel+1<relic_file_count) relic_file_sel++;
      else if ((sc&0xFF)==SC_PAGE_UP) relic_file_sel=MaxI64(0,relic_file_sel-rows);
      else if ((sc&0xFF)==SC_PAGE_DOWN)
        relic_file_sel=MaxI64(0,MinI64(relic_file_count-1,relic_file_sel+rows));
      else if ((sc&0xFF)==SC_HOME) relic_file_sel=0;
      else if ((sc&0xFF)==SC_END) relic_file_sel=MaxI64(0,relic_file_count-1);
      else if ((sc&0xFF)==SC_DELETE) act=RFA_DELETE;
      else if ((sc&0xFF)==SC_F2) act=RFA_RENAME;
      else if (ch==CH_BACKSPACE) act=RFA_UP;
      else if (ch=='\n') act=RFA_OPEN;
      else if (ch=='/' || ch=='g' || ch=='G') act=RFA_GOTO;
      else if (ch=='n' || ch=='N') act=RFA_NEW;
      else if (ch=='d' || ch=='D') act=RFA_FOLDER;
      else if (ch=='r' || ch=='R') act=RFA_RENAME;
      else if (ch=='c' || ch=='C') act=RFA_COPY;
      else if (ch=='x' || ch=='X') act=RFA_DELETE;
      if (act>=0) {
        last_click=-1; click_time=-1.0;
        relic_app_notice[0]=0;
        refresh=RelicFilesAction(act);
        follow=TRUE;
      }
      if (refresh) RelicFilesRead;
      if (follow) RelicFilesVisible(h);
    }
  }
  Fs->draw_it=NULL;
  DirTreeDel(relic_files); relic_files=NULL;
}

// ---- Settings ----
#define RELIC_SET_ROWS 5
#define RELIC_SET_Y    76
#define RELIC_SET_H    50
U8 *relic_set_tb[2]={"Save","Restore defaults"};
U8 *relic_set_names[RELIC_SET_ROWS]={"Wallpaper","Show FPS","24-hour clock",
  "Animations","Screen saver"};
U8 *relic_set_desc[RELIC_SET_ROWS]={
  "Reaper wallpaper behind the desktop.",
  "Frames per second in the top bar.",
  "Use 24-hour time in the top bar.",
  "Short slide effects for menus and dialogs.",
  "Blank the desktop after this many idle minutes."};
I64 relic_set_sel=0;

Bool RelicSetValue(I64 row)
{
  if (row==0) return relic_cfg.wallpaper;
  if (row==1) return relic_cfg.stats;
  if (row==2) return relic_cfg.clock24;
  if (row==3) return relic_cfg.animations;
  return relic_cfg.saver_minutes!=0;
}

U8 *RelicSetLabel(I64 row)
{
  if (row==0) return RelicText(relic_cfg.wallpaper,"Reaper","Solid black");
  if (row==1) return RelicText(relic_cfg.stats,"On","Off");
  if (row==2) return RelicText(relic_cfg.clock24,"24-hour","12-hour");
  if (row==3) return RelicText(relic_cfg.animations,"On","Reduced");
  return "";
}

// Change a row: dir 0 toggles, +1 / -1 steps the screen saver.
U0 RelicSetChange(I64 row,I64 dir)
{
  if (row==0) relic_cfg.wallpaper=!relic_cfg.wallpaper;
  if (row==1) relic_cfg.stats=!relic_cfg.stats;
  if (row==2) relic_cfg.clock24=!relic_cfg.clock24;
  if (row==3) relic_cfg.animations=!relic_cfg.animations;
  if (row==4) {
    if (dir<0) relic_cfg.saver_minutes=MaxI64(0,relic_cfg.saver_minutes-5);
    else if (dir>0) relic_cfg.saver_minutes=MinI64(60,relic_cfg.saver_minutes+5);
    else relic_cfg.saver_minutes=(relic_cfg.saver_minutes+5)%65;
  }
}

U0 RelicSettingsDraw(CTask *task,CDC *dc)
{
  I64 w=task->pix_width,h=task->pix_height,i,y,st,sx,on;
  U8 buf[32];
  RelicUIFrame(task,dc,"Settings","Arrows select  Space change  Esc close",TRUE);
  RelicUIToolbar(task,dc,relic_set_tb,2,0,0);
  for (i=0;i<RELIC_SET_ROWS;i++) {
    y=RELIC_SET_Y+i*RELIC_SET_H;
    st=RelicUIState(task,16,y,w-32,RELIC_SET_H-6);
    dc->color=RelicChoose(st!=RUI_NORMAL,rc_hover,rc_panel);
    GrRect(dc,16,y,w-32,RELIC_SET_H-6);
    if (i==relic_set_sel) {
      dc->color=rc_strong; RelicOutline(dc,16,y,w-32,RELIC_SET_H-6);
    }
    dc->color=rc_strong; GrPrint(dc,32,y+10,"%s",relic_set_names[i]);
    dc->color=rc_dim; GrPrint(dc,32,y+26,"%s",relic_set_desc[i]);
    sx=w-32-44;
    if (i==4) {
      RelicUIButton(dc,sx-90,y+11,28,22,"-",RelicUIState(task,sx-90,y+11,28,22));
      RelicUIButton(dc,sx+16,y+11,28,22,"+",RelicUIState(task,sx+16,y+11,28,22));
      if (relic_cfg.saver_minutes) StrPrint(buf,"%d min",relic_cfg.saver_minutes);
      else StrCpy(buf,"Off");
      dc->color=rc_strong; RelicUITextC(dc,sx-62,y+18,78,buf);
    } else {
      on=RelicSetValue(i);
      dc->color=rc_text;
      GrPrint(dc,sx-12-StrLen(RelicSetLabel(i))*FONT_WIDTH,y+18,"%s",RelicSetLabel(i));
      if (on) {
        dc->color=rc_text; GrRect(dc,sx,y+14,40,16);
        dc->color=BLACK; GrRect(dc,sx+26,y+17,11,10);
      } else {
        dc->color=rc_dim; RelicOutline(dc,sx,y+14,40,16);
        GrRect(dc,sx+3,y+17,11,10);
      }
    }
  }
  y=RELIC_SET_Y+RELIC_SET_ROWS*RELIC_SET_H+8;
  dc->color=rc_dim;
  RelicUIText(dc,16,y,(w-32)/FONT_WIDTH,relic_data_dir);
  GrPrint(dc,16,y+14,"Display: 640 x 480, 16 colours. Ctrl+Alt+V switches to VGA.");
  GrPrint(dc,16,y+28,"%s",RelicText(DrvIsWritable(':'),
        "Changes are saved when you leave Settings.",
        "Live session: changes stay in memory until you restart."));
}

I64 RelicSettingsHit(I64 w,I64 mx,I64 my,I64 *dir)
{
  I64 i,y,sx=w-32-44;
  *dir=0;
  for (i=0;i<RELIC_SET_ROWS;i++) {
    y=RELIC_SET_Y+i*RELIC_SET_H;
    if (RelicUIIn(mx,my,16,y,w-32,RELIC_SET_H-6)) {
      if (i==4) {
        if (RelicUIIn(mx,my,sx-90,y+11,28,22)) *dir=-1;
        if (RelicUIIn(mx,my,sx+16,y+11,28,22)) *dir=1;
      }
      return i;
    }
  }
  return -1;
}

U0 RelicSettingsApp()
{
  I64 ch=0,sc=0,mc,mx,my,i,dir;
  Bool done=FALSE;
  CRelicSettings saved;
  MemCpy(&saved,&relic_cfg,sizeof(CRelicSettings));
  RelicAppGraphics(&RelicSettingsDraw);
  while (!done) {
    mc=RelicAppMsg(&ch,&sc);
    if (mc!=MSG_KEY_DOWN) ch=0;
    i=-2; dir=0;
    if (mc==MSG_MS_L_DOWN || mc==MSG_MS_L_D_DOWN) {
      RelicUIMouse(Fs,&mx,&my);
      if (RelicUICloseHit(Fs->pix_width,mx,my)) ch=CH_ESC;
      else {
        i=RelicUIToolbarHit(relic_set_tb,2,mx,my);
        if (i==0) ch='s';
        else if (i==1) {
          if (!RelicDialog("Restore defaults","Put every setting back to its "
                "default value?","Restore","Cancel",NULL,1,1)) {
            RelicSettingsDefault;
            StrCpy(relic_app_notice,"Defaults restored.");
          }
        }
        i=RelicSettingsHit(Fs->pix_width,mx,my,&dir);
        if (i>=0) {
          relic_set_sel=i;
          RelicSetChange(i,dir);
        }
      }
    }
    if (mc==MSG_KEY_DOWN || ch==CH_ESC || ch=='s') {
      if (ch==CH_ESC || ch==CH_SHIFT_ESC) {
        if (!MemCmp(&saved,&relic_cfg,sizeof(CRelicSettings)) || RelicSettingsSave)
          done=TRUE;
        else if (!RelicDialog("Settings not saved","Settings could not be saved. "
              "Check free disk space.","Leave anyway","Stay",NULL,1,1))
          done=TRUE;
      } else if (ch=='s' || ch=='S') {
        if (RelicSettingsSave) {
          MemCpy(&saved,&relic_cfg,sizeof(CRelicSettings));
          StrCpy(relic_app_notice,"Saved.");
        } else StrCpy(relic_app_notice,"Save failed. Check free disk space.");
      } else if (ch>='1' && ch<='5') {
        relic_set_sel=ch-'1'; RelicSetChange(relic_set_sel,0);
      } else if ((sc&0xFF)==SC_CURSOR_UP && mc==MSG_KEY_DOWN) {
        relic_set_sel=MaxI64(0,relic_set_sel-1);
      } else if ((sc&0xFF)==SC_CURSOR_DOWN && mc==MSG_KEY_DOWN) {
        relic_set_sel=MinI64(RELIC_SET_ROWS-1,relic_set_sel+1);
      } else if ((sc&0xFF)==SC_CURSOR_LEFT && mc==MSG_KEY_DOWN) {
        RelicSetChange(relic_set_sel,-1);
      } else if ((sc&0xFF)==SC_CURSOR_RIGHT && mc==MSG_KEY_DOWN) {
        RelicSetChange(relic_set_sel,1);
      } else if (ch==' ' || ch=='\n') {
        RelicSetChange(relic_set_sel,0);
      }
    }
    ch=0;
  }
  Fs->draw_it=NULL;
}

// ---- Calendar ----
I64 relic_cal_year,relic_cal_mon;
I64 relic_cal_days[12]={31,28,31,30,31,30,31,31,30,31,30,31};
U8 *relic_cal_months[12]={"January","February","March","April","May","June","July","August","September","October","November","December"};
U8 *relic_cal_dows[7]={"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};
U8 *relic_cal_tb[3]={"<","Today",">"};

I64 RelicMonthDays(I64 y,I64 m)
{
  if (m==2 && (!(y%4) && y%100 || !(y%400))) return 29;
  return relic_cal_days[m-1];
}

U0 RelicCalendarToday()
{
  CDateStruct ds;
  Date2Struct(&ds,Now+local_time_offset);
  relic_cal_year=ds.year; relic_cal_mon=ds.mon;
}

U0 RelicCalendarStep(I64 d)
{
  relic_cal_mon+=d;
  if (relic_cal_mon<1) { relic_cal_mon=12; relic_cal_year--; }
  if (relic_cal_mon>12) { relic_cal_mon=1; relic_cal_year++; }
  relic_cal_year=ClampI64(relic_cal_year,1970,9999);
}

U0 RelicCalendarDraw(CTask *task,CDC *dc)
{
  I64 w=task->pix_width,day,dow,x,y,i,cw=72,ch=40,x0;
  CDateStruct ds,today;
  U8 title[32];
  RelicUIFrame(task,dc,"Calendar","Left/Right month  PgUp/PgDn year  T today  Esc close",TRUE);
  RelicUIToolbar(task,dc,relic_cal_tb,3,0,0);
  MemSet(&ds,0,sizeof(CDateStruct));
  ds.year=relic_cal_year; ds.mon=relic_cal_mon; ds.day_of_mon=1;
  Date2Struct(&ds,Struct2Date(&ds)); dow=ds.day_of_week;
  Date2Struct(&today,Now+local_time_offset);
  x0=(w-7*cw)/2;
  StrPrint(title,"%s %d",relic_cal_months[relic_cal_mon-1],relic_cal_year);
  dc->color=rc_strong; RelicUITextC(dc,x0,RUI_TOP+8,7*cw,title);
  dc->color=rc_dim;
  for (i=0;i<7;i++) RelicUITextC(dc,x0+i*cw,RUI_TOP+32,cw,relic_cal_dows[i]);
  dc->color=rc_line; GrLine(dc,x0,RUI_TOP+46,x0+7*cw-1,RUI_TOP+46);
  for (day=1;day<=RelicMonthDays(relic_cal_year,relic_cal_mon);day++) {
    i=dow+day-1; x=x0+(i%7)*cw; y=RUI_TOP+52+(i/7)*ch;
    if (today.year==relic_cal_year && today.mon==relic_cal_mon && today.day_of_mon==day) {
      dc->color=rc_text; GrRect(dc,x+2,y+2,cw-4,ch-4);
      dc->color=BLACK;
    } else {
      dc->color=rc_panel; GrRect(dc,x+2,y+2,cw-4,ch-4);
      dc->color=rc_text;
    }
    GrPrint(dc,x+10,y+10,"%d",day);
  }
}

U0 RelicCalendarApp()
{
  I64 ch,sc,mc,mx,my,i;
  Bool done=FALSE;
  RelicCalendarToday;
  RelicAppGraphics(&RelicCalendarDraw);
  while (!done) {
    mc=RelicAppMsg(&ch,&sc);
    if (mc==MSG_MS_L_DOWN || mc==MSG_MS_L_D_DOWN) {
      RelicUIMouse(Fs,&mx,&my);
      if (RelicUICloseHit(Fs->pix_width,mx,my)) done=TRUE;
      i=RelicUIToolbarHit(relic_cal_tb,3,mx,my);
      if (i==0) RelicCalendarStep(-1);
      if (i==1) RelicCalendarToday;
      if (i==2) RelicCalendarStep(1);
    } else if (mc==MSG_KEY_DOWN) {
      if (ch==CH_ESC || ch==CH_SHIFT_ESC) done=TRUE;
      if (ch=='t' || ch=='T') RelicCalendarToday;
      if ((sc&0xFF)==SC_CURSOR_LEFT) RelicCalendarStep(-1);
      if ((sc&0xFF)==SC_CURSOR_RIGHT) RelicCalendarStep(1);
      if ((sc&0xFF)==SC_PAGE_UP) RelicCalendarStep(-12);
      if ((sc&0xFF)==SC_PAGE_DOWN) RelicCalendarStep(12);
    }
  }
  Fs->draw_it=NULL;
}

// ---- Calculator ----
// Standard calculator: operations run left to right like Windows'
// standard mode.  Results that are not finite are rejected.
#define RELIC_CALC_BW 80
#define RELIC_CALC_BH 40
#define RELIC_CALC_GAP 6
#define RELIC_CALC_KEYS 24
U8 *relic_calc_keys[RELIC_CALC_KEYS]={
  "%","CE","C","Back",
  "1/x","x^2","sqrt","/",
  "7","8","9","*",
  "4","5","6","-",
  "1","2","3","+",
  "+/-","0",".","="};
F64 relic_calc_acc=0;
I64 relic_calc_op=0,relic_calc_flash=-1;
U8 relic_calc_entry[40]="0",relic_calc_expr[96]="",relic_calc_err[48]="";
Bool relic_calc_have=FALSE,relic_calc_replace=TRUE;
F64 relic_calc_flash_t=0;

I64 RelicCalcX0(I64 w) { return (w-(4*RELIC_CALC_BW+3*RELIC_CALC_GAP))/2; }
#define RELIC_CALC_DISP_Y 52
#define RELIC_CALC_KEY_Y  128

// Plain number text: up to 15 significant digits, no trailing zeros.
U0 RelicCalcFmt(F64 v,U8 *out)
{
  U8 fmt[16];
  I64 len,digits;
  F64 a=Abs(v);
  if (a>=1e15 || a<1e-9 && a>0) {
    StrPrint(out,"%.9e",v);
    return;
  }
  digits=1;
  if (a>=1) digits=ToI64(Floor(Log10(a)))+1;
  StrPrint(fmt,"%%.%df",ClampI64(15-digits,0,10));
  StrPrint(out,fmt,v);
  if (StrFirstOcc(out,".")) {
    len=StrLen(out);
    while (len>1 && out[len-1]=='0') out[--len]=0;
    if (out[len-1]=='.') out[--len]=0;
  }
  if (!StrCmp(out,"-0")) StrCpy(out,"0");
}

// Adds thousands separators to the integer part of a plain number.
U0 RelicCalcGroup(U8 *src,U8 *out)
{
  I64 i=0,o=0,n=0,start;
  if (StrFirstOcc(src,"e")) { StrCpy(out,src); return; }
  if (src[0]=='-') out[o++]=src[i++];
  start=i;
  while (src[start+n]>='0' && src[start+n]<='9') n++;
  while (i<start+n) {
    out[o++]=src[i++];
    if (i<start+n && !((start+n-i)%3)) out[o++]=',';
  }
  while (src[i]) out[o++]=src[i++];
  out[o]=0;
}

Bool RelicCalcFinite(F64 v)
{
  return v==v && Abs(v)<1e300;
}

U0 RelicCalcReset()
{
  relic_calc_acc=0; relic_calc_op=0;
  StrCpy(relic_calc_entry,"0");
  relic_calc_expr[0]=0;
  relic_calc_have=FALSE; relic_calc_replace=TRUE;
}

U0 RelicCalcFail(U8 *msg)
{
  RelicCalcReset;
  StrCpy(relic_calc_err,msg);
}

Bool RelicCalcSet(F64 v)
{
  if (!RelicCalcFinite(v)) { RelicCalcFail("Result is too large"); return FALSE; }
  RelicCalcFmt(v,relic_calc_entry);
  return TRUE;
}

Bool RelicCalcApply(F64 a,I64 op,F64 b,F64 *res)
{
  if (op=='/' && !b) { RelicCalcFail("Cannot divide by zero"); return FALSE; }
  if (op=='+') *res=a+b;
  else if (op=='-') *res=a-b;
  else if (op=='*') *res=a*b;
  else if (op=='/') *res=a/b;
  else *res=b;
  if (!RelicCalcFinite(*res)) { RelicCalcFail("Result is too large"); return FALSE; }
  return TRUE;
}

U0 RelicCalcPress(I64 k)
{
  U8 *label=relic_calc_keys[k],a[48],b[48];
  F64 e=Str2F64(relic_calc_entry),r;
  I64 len,ch=label[0];
  relic_calc_flash=k; relic_calc_flash_t=tS;
  if (relic_calc_err[0]) {
    relic_calc_err[0]=0;
    if (k==1 || k==2) return;
  }
  if (StrLen(label)==1 && (ch>='0' && ch<='9' || ch=='.')) {
    if (relic_calc_replace) {
      StrCpy(relic_calc_entry,"0"); relic_calc_replace=FALSE;
    }
    len=StrLen(relic_calc_entry);
    if (ch=='.') {
      if (!StrFirstOcc(relic_calc_entry,".") && len<17) {
        relic_calc_entry[len]='.'; relic_calc_entry[len+1]=0;
      }
    } else if (!StrCmp(relic_calc_entry,"0")) {
      relic_calc_entry[0]=ch;
    } else if (!StrCmp(relic_calc_entry,"-0")) {
      relic_calc_entry[1]=ch;
    } else if (len<17) {
      relic_calc_entry[len]=ch; relic_calc_entry[len+1]=0;
    }
    relic_calc_have=TRUE;
  } else if (k==0) {
    if (relic_calc_op=='+' || relic_calc_op=='-') r=relic_calc_acc*e/100;
    else r=e/100;
    if (RelicCalcSet(r)) { relic_calc_have=TRUE; relic_calc_replace=TRUE; }
  } else if (k==1) {
    StrCpy(relic_calc_entry,"0"); relic_calc_have=TRUE; relic_calc_replace=FALSE;
  } else if (k==2) {
    RelicCalcReset;
  } else if (k==3) {
    if (!relic_calc_replace) {
      len=StrLen(relic_calc_entry);
      if (len>1) relic_calc_entry[len-1]=0;
      else StrCpy(relic_calc_entry,"0");
      if (!StrCmp(relic_calc_entry,"-")) StrCpy(relic_calc_entry,"0");
    }
  } else if (k==4) {
    if (!e) RelicCalcFail("Cannot divide by zero");
    else if (RelicCalcSet(1/e)) { relic_calc_have=TRUE; relic_calc_replace=TRUE; }
  } else if (k==5) {
    if (RelicCalcSet(e*e)) { relic_calc_have=TRUE; relic_calc_replace=TRUE; }
  } else if (k==6) {
    if (e<0) RelicCalcFail("Invalid input");
    else if (RelicCalcSet(Sqrt(e))) { relic_calc_have=TRUE; relic_calc_replace=TRUE; }
  } else if (k==20) {
    if (StrCmp(relic_calc_entry,"0")) {
      if (relic_calc_entry[0]=='-')
        StrCpy(relic_calc_entry,relic_calc_entry+1);
      else if (StrLen(relic_calc_entry)<38) {
        StrCpy(a,relic_calc_entry);
        StrPrint(relic_calc_entry,"-%s",a);
      }
    }
  } else if (k==23) {
    if (relic_calc_op) {
      RelicCalcFmt(relic_calc_acc,a); RelicCalcFmt(e,b);
      if (RelicCalcApply(relic_calc_acc,relic_calc_op,e,&r)) {
        StrPrint(relic_calc_expr,"%s %c %s =",a,relic_calc_op,b);
        relic_calc_acc=r; relic_calc_op=0;
        RelicCalcFmt(r,relic_calc_entry);
        relic_calc_have=FALSE; relic_calc_replace=TRUE;
      }
    }
  } else if (ch=='+' || ch=='-' || ch=='*' || ch=='/') {
    if (relic_calc_op && relic_calc_have) {
      if (!RelicCalcApply(relic_calc_acc,relic_calc_op,e,&r)) return;
      relic_calc_acc=r;
    } else if (!relic_calc_op)
      relic_calc_acc=e;
    relic_calc_op=ch;
    RelicCalcFmt(relic_calc_acc,relic_calc_entry);
    StrPrint(relic_calc_expr,"%s %c",relic_calc_entry,ch);
    relic_calc_have=FALSE; relic_calc_replace=TRUE;
  }
}

I64 RelicCalcKeyFor(I64 ch,I64 sc)
{
  I64 i;
  if ((sc&0xFF)==SC_DELETE) return 1;
  if (ch==CH_BACKSPACE) return 3;
  if (ch=='\n' || ch=='=') return 23;
  if (ch=='c' || ch=='C') return 2;
  if (ch=='r' || ch=='R') return 4;
  if (ch=='q' || ch=='Q') return 5;
  if (ch=='@') return 6;
  if (ch=='n' || ch=='N') return 20;
  if (ch==',') ch='.';
  for (i=0;i<RELIC_CALC_KEYS;i++)
    if (StrLen(relic_calc_keys[i])==1 && relic_calc_keys[i][0]==ch) return i;
  return -1;
}

U0 RelicCalcDraw(CTask *task,CDC *dc)
{
  I64 w=task->pix_width,x0=RelicCalcX0(w),kw=4*RELIC_CALC_BW+3*RELIC_CALC_GAP,
      i,x,y,st;
  U8 buf[64];
  RelicUIFrame(task,dc,"Calculator","Type numbers  Enter =  Esc close",FALSE);
  dc->color=rc_panel; GrRect(dc,x0,RELIC_CALC_DISP_Y,kw,64);
  dc->color=rc_line; RelicOutline(dc,x0,RELIC_CALC_DISP_Y,kw,64);
  dc->color=rc_dim;
  RelicFit(buf,relic_calc_expr,(kw-24)/FONT_WIDTH);
  GrPrint(dc,x0+kw-12-StrLen(buf)*FONT_WIDTH,RELIC_CALC_DISP_Y+14,"%s",buf);
  dc->color=rc_strong;
  if (relic_calc_err[0]) StrCpy(buf,relic_calc_err);
  else RelicCalcGroup(relic_calc_entry,buf);
  GrPrint(dc,x0+kw-12-StrLen(buf)*FONT_WIDTH,RELIC_CALC_DISP_Y+40,"%s",buf);
  for (i=0;i<RELIC_CALC_KEYS;i++) {
    x=x0+(i%4)*(RELIC_CALC_BW+RELIC_CALC_GAP);
    y=RELIC_CALC_KEY_Y+(i/4)*(RELIC_CALC_BH+RELIC_CALC_GAP);
    st=RelicUIState(task,x,y,RELIC_CALC_BW,RELIC_CALC_BH);
    if (i==relic_calc_flash && tS-relic_calc_flash_t<0.12) st=RUI_DOWN;
    else if (st==RUI_NORMAL && (i==23 ||
          relic_calc_op && !relic_calc_have && relic_calc_keys[i][0]==relic_calc_op &&
          StrLen(relic_calc_keys[i])==1))
      st=RUI_ON;
    RelicUIButton(dc,x,y,RELIC_CALC_BW,RELIC_CALC_BH,relic_calc_keys[i],st);
  }
}

U0 RelicCalcApp()
{
  I64 ch,sc,mc,mx,my,i,x0,x,y;
  Bool done=FALSE;
  RelicCalcReset; relic_calc_err[0]=0;
  RelicAppGraphics(&RelicCalcDraw);
  while (!done) {
    mc=RelicAppMsg(&ch,&sc);
    if (mc==MSG_MS_L_DOWN || mc==MSG_MS_L_D_DOWN) {
      RelicUIMouse(Fs,&mx,&my);
      if (RelicUICloseHit(Fs->pix_width,mx,my)) done=TRUE;
      x0=RelicCalcX0(Fs->pix_width);
      for (i=0;i<RELIC_CALC_KEYS;i++) {
        x=x0+(i%4)*(RELIC_CALC_BW+RELIC_CALC_GAP);
        y=RELIC_CALC_KEY_Y+(i/4)*(RELIC_CALC_BH+RELIC_CALC_GAP);
        if (RelicUIIn(mx,my,x,y,RELIC_CALC_BW,RELIC_CALC_BH)) RelicCalcPress(i);
      }
    } else if (mc==MSG_KEY_DOWN) {
      if (ch==CH_ESC || ch==CH_SHIFT_ESC) done=TRUE;
      else {
        i=RelicCalcKeyFor(ch,sc);
        if (i>=0) RelicCalcPress(i);
      }
    }
  }
  Fs->draw_it=NULL;
}

// ---- Paint ----
#define RELIC_PAINT_W 576
#define RELIC_PAINT_H 304
#define RELIC_PAINT_X 32
#define RELIC_PAINT_Y 76
#define RELIC_PAINT_PAL_Y 390
CDC *relic_canvas=NULL,*relic_canvas_undo=NULL;
I64 relic_paint_color=BLACK,relic_paint_brush=2,relic_paint_tool=0;
I64 relic_paint_x=100,relic_paint_y=100;
Bool relic_paint_dirty=FALSE;
U8 relic_paint_path[512]="";
U8 *relic_paint_tb[12]={"Pen","Line","Rect","Eraser","|","Undo","New","Open",
  "Save","|","-","+"};
U8 *relic_paint_tools[4]={"Pen","Line","Rectangle","Eraser"};

Bool RelicBMPSave(U8 *path,CDC *canvas)
{
  I64 stride=(canvas->width+3)&~3,size=1078+stride*canvas->height,i,y;
  U8 *data=CAlloc(size);
  CBGR48 pal[COLORS_NUM];
  Bool ok;
  data[0]='B'; data[1]='M';
  *(data+2)(U32 *)=size; *(data+10)(U32 *)=1078;
  *(data+14)(U32 *)=40; *(data+18)(I32 *)=canvas->width;
  *(data+22)(I32 *)=canvas->height;
  *(data+26)(U16 *)=1; *(data+28)(U16 *)=8;
  *(data+34)(U32 *)=stride*canvas->height; *(data+46)(U32 *)=256;
  GrPaletteGet(pal);
  for (i=0;i<16;i++) {
    data[54+i*4]=pal[i].b>>8;
    data[55+i*4]=pal[i].g>>8;
    data[56+i*4]=pal[i].r>>8;
  }
  for (y=0;y<canvas->height;y++)
    MemCpy(data+1078+(canvas->height-y-1)*stride,canvas->body+y*canvas->width_internal,canvas->width);
  ok=RelicWriteChecked(path,data,size);
  Free(data); return ok;
}

Bool RelicBMPLoad(U8 *path,CDC *canvas)
{
  U8 *data;
  I64 size,w,h,stride,off,x,y,i,k,best,dist,r,g,b,d,pal_n;
  CBGR48 pal[COLORS_NUM];
  F64 dr,dg,db;
  if (!FileFind(path)) return FALSE;
  data=FileRead(path,&size);
  if (!data) return FALSE;
  if (size<54 || data[0]!='B' || data[1]!='M') { Free(data); return FALSE; }
  w=*(data+18)(I32 *); h=*(data+22)(I32 *); off=*(data+10)(U32 *);
  pal_n=*(data+46)(U32 *); if (!pal_n) pal_n=256;
  if (pal_n<1 || pal_n>256 || w<1 || w>RELIC_PAINT_W || h<1 || h>RELIC_PAINT_H ||
      *(data+14)(U32 *)!=40 || *(data+26)(U16 *)!=1 ||
      *(data+28)(U16 *)!=8 || *(data+30)(U32 *) || off<54+pal_n*4 || off>size) {
    Free(data); return FALSE;
  }
  stride=(w+3)&~3;
  if (h*stride>size-off) { Free(data); return FALSE; }
  GrPaletteGet(pal);
  U8 map[256];
  for (i=0;i<pal_n;i++) {
    b=data[54+i*4]; g=data[55+i*4]; r=data[56+i*4];
    best=0; dist=I64_MAX;
    for (k=0;k<16;k++) {
      dr=ToF64(r)-ToF64(pal[k].r>>8);
      dg=ToF64(g)-ToF64(pal[k].g>>8);
      db=ToF64(b)-ToF64(pal[k].b>>8);
      d=dr*dr+dg*dg+db*db;
      if (d<dist) { dist=d; best=k; }
    }
    map[i]=best;
  }
  for (y=0;y<h;y++) for (x=0;x<w;x++)
    if (data[off+(h-y-1)*stride+x]>=pal_n) { Free(data); return FALSE; }
  DCFill(canvas,WHITE);
  for (y=0;y<h;y++) for (x=0;x<w;x++)
    canvas->body[y*canvas->width_internal+x]=map[data[off+(h-y-1)*stride+x]];
  Free(data); return TRUE;
}

U0 RelicPaintDraw(CTask *task,CDC *dc)
{
  I64 i,on,x;
  U8 title[96],name[48],*base;
  StrCpy(title,"Paint");
  if (relic_paint_path[0]) {
    base=StrLastOcc(relic_paint_path,"/");
    if (base) base++; else base=relic_paint_path;
    RelicFit(name,base,40);
    StrPrint(title,"Paint  -  %s%s",name,RelicText(relic_paint_dirty," (unsaved)",""));
  } else if (relic_paint_dirty)
    StrCpy(title,"Paint  -  unsaved picture");
  RelicUIFrame(task,dc,title,"Arrows move  Enter dot  Esc close",TRUE);
  on=1<<relic_paint_tool;
  RelicUIToolbar(task,dc,relic_paint_tb,12,on,0);
  x=RelicUIToolbarEnd(relic_paint_tb,12);
  dc->color=rc_text; GrPrint(dc,x+4,RUI_TB_Y+7,"Size %d",relic_paint_brush);
  dc->color=rc_line;
  RelicOutline(dc,RELIC_PAINT_X-1,RELIC_PAINT_Y-1,RELIC_PAINT_W+2,RELIC_PAINT_H+2);
  GrBlot(dc,RELIC_PAINT_X,RELIC_PAINT_Y,relic_canvas);
  for (i=0;i<16;i++) {
    dc->color=i; GrRect(dc,RELIC_PAINT_X+i*24+2,RELIC_PAINT_PAL_Y+2,20,20);
    dc->color=rc_line; RelicOutline(dc,RELIC_PAINT_X+i*24+2,RELIC_PAINT_PAL_Y+2,20,20);
    if (i==relic_paint_color) {
      dc->color=WHITE; RelicOutline(dc,RELIC_PAINT_X+i*24,RELIC_PAINT_PAL_Y,24,24);
      dc->color=BLACK; RelicOutline(dc,RELIC_PAINT_X+i*24+1,RELIC_PAINT_PAL_Y+1,22,22);
    }
  }
  dc->color=rc_text;
  GrPrint(dc,RELIC_PAINT_X+16*24+12,RELIC_PAINT_PAL_Y+8,"%s, colour %d",
        relic_paint_tools[relic_paint_tool],relic_paint_color);
  dc->color=BLACK;
  GrLine(dc,RELIC_PAINT_X+relic_paint_x-4,RELIC_PAINT_Y+relic_paint_y,
        RELIC_PAINT_X+relic_paint_x+4,RELIC_PAINT_Y+relic_paint_y);
  dc->color=WHITE;
  GrLine(dc,RELIC_PAINT_X+relic_paint_x,RELIC_PAINT_Y+relic_paint_y-4,
        RELIC_PAINT_X+relic_paint_x,RELIC_PAINT_Y+relic_paint_y+4);
}

U0 RelicPaintBackup()
{
  MemCpy(relic_canvas_undo->body,relic_canvas->body,relic_canvas->width_internal*relic_canvas->height);
}

U0 RelicPaintDot(I64 x,I64 y)
{
  relic_canvas->color=RelicChoose(relic_paint_tool==3,WHITE,relic_paint_color);
  GrRect(relic_canvas,ClampI64(x-relic_paint_brush/2,0,RELIC_PAINT_W-1),
    ClampI64(y-relic_paint_brush/2,0,RELIC_PAINT_H-1),
    MinI64(relic_paint_brush,RELIC_PAINT_W-x),MinI64(relic_paint_brush,RELIC_PAINT_H-y));
  relic_paint_dirty=TRUE;
}

// Save flow (path dialog, replace check).  TRUE only when the file was written.
Bool RelicPaintSave()
{
  U8 path[512],msg[600];
  if (!relic_paint_path[0]) StrPrint(relic_paint_path,"%s/Paint.BMP",relic_data_dir);
  if (!RelicAskEx("Save picture","Saved as an 8-bit BMP file.",path,sizeof(path),
        relic_paint_path) || !path[0])
    return FALSE;
  if (FileFind(path)) {
    StrPrint(msg,"%s already exists. Replace it?",path);
    if (RelicDialog("Replace file",msg,"Replace","Cancel",NULL,1,1)) return FALSE;
  }
  RelicThemeApply;
  if (RelicBMPSave(path,relic_canvas)) {
    StrCpy(relic_paint_path,path); relic_paint_dirty=FALSE;
    StrCpy(relic_app_notice,"Saved BMP.");
    return TRUE;
  }
  StrCpy(relic_app_notice,"Save failed.");
  return FALSE;
}

U0 RelicPaintOpen()
{
  U8 path[512];
  if (relic_paint_dirty && RelicDialog("Unsaved picture",
        "Discard the unsaved picture and open another one?","Discard","Cancel",
        NULL,1,1))
    return;
  if (RelicAskEx("Open picture","8-bit BMP, up to 576 x 304.",path,sizeof(path),
        relic_paint_path)) {
    RelicThemeApply; RelicPaintBackup;
    if (RelicBMPLoad(path,relic_canvas)) {
      StrCpy(relic_paint_path,path); relic_paint_dirty=FALSE;
      StrCpy(relic_app_notice,"Loaded BMP.");
    } else StrCpy(relic_app_notice,"Unsupported or damaged BMP.");
  }
}

U0 RelicPaintNew()
{
  if (!relic_paint_dirty || !RelicDialog("Clear canvas",
        "Clear the canvas? Unsaved changes are lost.","Clear","Cancel",NULL,1,1)) {
    RelicPaintBackup; DCFill(relic_canvas,WHITE); relic_paint_dirty=TRUE;
  }
}

// TRUE when Paint may close.
Bool RelicPaintClose()
{
  I64 r;
  if (!relic_paint_dirty) return TRUE;
  r=RelicDialog("Unsaved picture","Save changes before closing Paint?",
        "Save","Don't save","Cancel",0,2);
  if (r==0) return RelicPaintSave;
  return r==1;
}

U0 RelicPaintToolbar(I64 i)
{
  if (i>=0 && i<=3) relic_paint_tool=i;
  else if (i==5) {
    MemCpy(relic_canvas->body,relic_canvas_undo->body,relic_canvas->width_internal*relic_canvas->height);
    relic_paint_dirty=TRUE;
  } else if (i==6) RelicPaintNew;
  else if (i==7) RelicPaintOpen;
  else if (i==8) RelicPaintSave;
  else if (i==10) relic_paint_brush=MaxI64(1,relic_paint_brush-1);
  else if (i==11) relic_paint_brush=MinI64(24,relic_paint_brush+1);
}

U0 RelicPaintApp()
{
  I64 ch,sc,mc,mx,my,sx=0,sy=0,px=0,py=0,i;
  Bool down=FALSE,done=FALSE,prev_lb=TRUE;
  if (!relic_canvas) {
    relic_canvas=DCNew(RELIC_PAINT_W,RELIC_PAINT_H);
    relic_canvas_undo=DCNew(RELIC_PAINT_W,RELIC_PAINT_H);
    relic_canvas->flags|=DCF_NO_TRANSPARENTS;
    DCFill(relic_canvas,WHITE); RelicPaintBackup;
  }
  RelicUIColour;
  RelicAppGraphics(&RelicPaintDraw);
  while (!done) {
    mc=ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN);
    RelicUIMouse(Fs,&mx,&my);
    if (ms.lb && !prev_lb && !down) {
      // Fresh press: chrome first, then the canvas.
      if (RelicUICloseHit(Fs->pix_width,mx,my)) {
        if (RelicPaintClose) done=TRUE;
      } else if (my>=RUI_TB_Y && my<RUI_TB_Y+RUI_TB_H) {
        i=RelicUIToolbarHit(relic_paint_tb,12,mx,my);
        if (i>=0) RelicPaintToolbar(i);
      } else if (my>=RELIC_PAINT_PAL_Y && my<RELIC_PAINT_PAL_Y+24 &&
            mx>=RELIC_PAINT_X && mx<RELIC_PAINT_X+16*24) {
        relic_paint_color=(mx-RELIC_PAINT_X)/24;
      } else if (mx>=RELIC_PAINT_X && mx<RELIC_PAINT_X+RELIC_PAINT_W &&
            my>=RELIC_PAINT_Y && my<RELIC_PAINT_Y+RELIC_PAINT_H) {
        RelicPaintBackup; down=TRUE;
        sx=px=mx-RELIC_PAINT_X; sy=py=my-RELIC_PAINT_Y;
        relic_paint_x=sx; relic_paint_y=sy;
        if (!relic_paint_tool || relic_paint_tool==3) RelicPaintDot(sx,sy);
      }
    } else if (down && ms.lb) {
      relic_paint_x=ClampI64(mx-RELIC_PAINT_X,0,RELIC_PAINT_W-1);
      relic_paint_y=ClampI64(my-RELIC_PAINT_Y,0,RELIC_PAINT_H-1);
      relic_canvas->color=RelicChoose(relic_paint_tool==3,WHITE,relic_paint_color);
      if (!relic_paint_tool || relic_paint_tool==3) {
        GrLine(relic_canvas,px,py,relic_paint_x,relic_paint_y);
        RelicPaintDot(relic_paint_x,relic_paint_y);
        px=relic_paint_x; py=relic_paint_y;
      }
    } else if (down) {
      relic_canvas->color=relic_paint_color;
      if (relic_paint_tool==1) GrLine(relic_canvas,sx,sy,relic_paint_x,relic_paint_y);
      if (relic_paint_tool==2) RelicOutline(relic_canvas,MinI64(sx,relic_paint_x),MinI64(sy,relic_paint_y),AbsI64(sx-relic_paint_x)+1,AbsI64(sy-relic_paint_y)+1);
      relic_paint_dirty=TRUE; down=FALSE;
    }
    prev_lb=ms.lb;
    if (mc) {
      if (ch==CH_ESC || ch==CH_SHIFT_ESC) {
        if (RelicPaintClose) done=TRUE;
      } else if (ch=='p' || ch=='P') relic_paint_tool=0;
      else if (ch=='l' || ch=='L') relic_paint_tool=1;
      else if (ch=='r' || ch=='R') relic_paint_tool=2;
      else if (ch=='e' || ch=='E') relic_paint_tool=3;
      else if (ch=='+') RelicPaintToolbar(11);
      else if (ch=='-') RelicPaintToolbar(10);
      else if (ch>='0' && ch<='9') relic_paint_color=ch-'0';
      else if (ch=='\n') { RelicPaintBackup; RelicPaintDot(relic_paint_x,relic_paint_y); }
      else if (ch=='u' || ch=='U') RelicPaintToolbar(5);
      else if (ch=='n' || ch=='N') RelicPaintNew;
      else if (ch=='s' || ch=='S') RelicPaintSave;
      else if (ch=='o' || ch=='O') RelicPaintOpen;
      if ((sc&255)==SC_CURSOR_LEFT) relic_paint_x=MaxI64(0,relic_paint_x-4);
      if ((sc&255)==SC_CURSOR_RIGHT) relic_paint_x=MinI64(RELIC_PAINT_W-1,relic_paint_x+4);
      if ((sc&255)==SC_CURSOR_UP) relic_paint_y=MaxI64(0,relic_paint_y-4);
      if ((sc&255)==SC_CURSOR_DOWN) relic_paint_y=MinI64(RELIC_PAINT_H-1,relic_paint_y+4);
    }
    Sleep(10);
  }
  Fs->draw_it=NULL;
  RelicUIMatte;
}

// ---- Browser ----
// A bounded text browser: local files, about:home and plain HTTP through the
// optional network service.  No TLS, CSS, images or scripts.
#define RELIC_BROWSER_MAX 262144
#define RELIC_BROWSER_Y   80
#define RELIC_BROWSER_LH  12
U8 relic_browser_url[512]="about:home";
U8 relic_browser_lines[2048][74];
U8 relic_browser_flags[2048];
I64 relic_browser_count=0,relic_browser_scroll=0;
U8 relic_browser_history[16][512];
I64 relic_browser_hist_count=0,relic_browser_hist_pos=-1;
U8 relic_browser_links[64][512];
I64 relic_browser_link_count=0;
I64 relic_browser_link_line[64],relic_browser_link_col[64];
I64 relic_browser_link_eline[64],relic_browser_link_ecol[64];
I64 relic_browser_open=-1;
Bool relic_browser_heading=FALSE,relic_browser_editing=FALSE,
     relic_browser_fresh=FALSE;
U8 relic_browser_edit[512];
U8 *relic_browser_tb[4]={"<",">","Reload","Home"};

U0 RelicBrowserChar(I64 ch)
{
  I64 len;
  if (relic_browser_count>=2047) return;
  len=StrLen(relic_browser_lines[relic_browser_count]);
  if (ch=='\r') return;
  if (ch=='\n' || len>=72) {
    relic_browser_count++;
    relic_browser_lines[relic_browser_count][0]=0;
    relic_browser_flags[relic_browser_count]=0;
    len=0;
  }
  if (ch>=' ' && ch<127) {
    relic_browser_lines[relic_browser_count][len]=ch;
    relic_browser_lines[relic_browser_count][len+1]=0;
    if (relic_browser_heading) relic_browser_flags[relic_browser_count]=1;
  }
}

U0 RelicBrowserText(U8 *s)
{
  while (*s) RelicBrowserChar(*s++);
}

// End the current line and leave one blank line before the next block.
U0 RelicBrowserBlock()
{
  if (relic_browser_count>=2047) return;
  if (relic_browser_lines[relic_browser_count][0]) RelicBrowserChar('\n');
  if (relic_browser_count>0 && relic_browser_lines[relic_browser_count-1][0])
    RelicBrowserChar('\n');
}

U0 RelicBrowserLinkEnd()
{
  if (relic_browser_open>=0) {
    relic_browser_link_eline[relic_browser_open]=relic_browser_count;
    relic_browser_link_ecol[relic_browser_open]=
          StrLen(relic_browser_lines[relic_browser_count]);
    relic_browser_open=-1;
  }
}

U0 RelicBrowserParse(U8 *data,I64 size,Bool html)
{
  I64 i=0,j,n,skip=0,k;
  U8 tag[1024],lower[1024],*href,num[16];
  relic_browser_count=0; relic_browser_scroll=0; relic_browser_lines[0][0]=0;
  relic_browser_flags[0]=0;
  relic_browser_link_count=0; relic_browser_open=-1; relic_browser_heading=FALSE;
  while (i<size && data[i]) {
    if (html && data[i]=='<') {
      i++; n=0;
      while (i<size && data[i]!='>') {
        if (n<sizeof(tag)-1) tag[n++]=data[i];
        i++;
      }
      tag[n]=0; StrCpy(lower,tag); StrUtil(lower,SUF_TO_LOWER);
      if (!StrNCmp(lower,"script",6) || !StrNCmp(lower,"style",5)) skip=1;
      if (!StrNCmp(lower,"/script",7) || !StrNCmp(lower,"/style",6)) skip=0;
      if (!skip) {
        if (lower[0]=='h' && lower[1]>='1' && lower[1]<='6') {
          RelicBrowserBlock(); relic_browser_heading=TRUE;
        }
        if (!StrNCmp(lower,"/p",2) || !StrNCmp(lower,"/h",2)) {
          relic_browser_heading=FALSE; RelicBrowserBlock();
        } else if (!StrNCmp(lower,"br",2) || !StrNCmp(lower,"/div",4) ||
            !StrNCmp(lower,"li",2) || !StrNCmp(lower,"/tr",3)) RelicBrowserChar('\n');
        if (lower[0]=='/' && lower[1]=='a' && (!lower[2] || lower[2]==' '))
          RelicBrowserLinkEnd;
        if (lower[0]=='a' && (lower[1]==' ' || lower[1]=='\t') && relic_browser_link_count<64) {
          href=StrMatch("href=",lower);
          if (href) {
            RelicBrowserLinkEnd;
            k=relic_browser_link_count;
            j=href-lower+5;
            if (tag[j]=='\'' || tag[j]=='"') j++;
            n=0;
            while (j<StrLen(tag) && tag[j]!='\'' && tag[j]!='"' && tag[j]!=' ' && n<511)
              relic_browser_links[k][n++]=tag[j++];
            relic_browser_links[k][n]=0;
            if (StrLen(relic_browser_lines[relic_browser_count])>=68)
              RelicBrowserChar('\n');
            relic_browser_link_line[k]=relic_browser_count;
            relic_browser_link_col[k]=StrLen(relic_browser_lines[relic_browser_count]);
            relic_browser_link_eline[k]=relic_browser_count;
            relic_browser_link_ecol[k]=relic_browser_link_col[k];
            relic_browser_open=k;
            StrPrint(num,"[%d] ",++relic_browser_link_count); RelicBrowserText(num);
          }
        }
      }
      i++;
    } else if (!skip) {
      if (html && data[i]=='&') {
        if (!StrNCmp(data+i,"&amp;",5)) { RelicBrowserChar('&'); i+=5; }
        else if (!StrNCmp(data+i,"&lt;",4)) { RelicBrowserChar('<'); i+=4; }
        else if (!StrNCmp(data+i,"&gt;",4)) { RelicBrowserChar('>'); i+=4; }
        else if (!StrNCmp(data+i,"&quot;",6)) { RelicBrowserChar('"'); i+=6; }
        else if (!StrNCmp(data+i,"&nbsp;",6)) { RelicBrowserChar(' '); i+=6; }
        else RelicBrowserChar(data[i++]);
      } else {
        if (html && (data[i]=='\n' || data[i]=='\t')) RelicBrowserChar(' ');
        else RelicBrowserChar(data[i]);
        i++;
      }
    } else i++;
  }
  RelicBrowserLinkEnd;
  relic_browser_count++;
}

U0 RelicBrowserLoad(U8 *url,Bool history=TRUE)
{
  U8 *data=NULL,path[512],home[1400];
  I64 size=0,i;
  CDirEntry de;
  CHashFun *h;
  U8 *(*fetch)(U8 *,I64 *);
  Bool html=TRUE;
  StrCpy(relic_browser_url,url);
  relic_app_notice[0]=0;
  RelicBrowserParse("Loading page...",15,FALSE);
  h=HashFind("RelicHTTPGet",Fs->hash_table,HTT_FUN);
  if (!StrCmp(url,"about:home")) {
    StrPrint(home,"<h1>Relic Browser</h1><p>Type an address in the bar above and "
          "press Enter, or use Open for a local file.</p><h2>What works</h2><p>"
          "Plain http:// pages, local text files and simple HTML. Links are "
          "underlined: click one to follow it.</p><h2>Not supported</h2><p>"
          "https:// (no TLS yet), images, CSS and "
          "JavaScript.</p><h2>Network</h2><p>%s</p><p><a href=\"http://neverssl.com/\">"
          "neverssl.com</a> is a plain HTTP test page.</p>",
          RelicText(h!=NULL,"The network service is running.",
          "Offline. The network service needs a PCNet adapter (VMware: vlance) "
          "and a restart."));
    data=StrNew(home);
    size=StrLen(data);
  } else if (!StrNCmp(url,"file:",5)) {
    StrCpy(path,url+5);
    if (FileFind(path,&de)) {
      if (!(de.attr & RS_ATTR_DIR) && de.size<=RELIC_BROWSER_MAX) {
        data=FileRead(path,&size);
        html=StrIMatch(".HTM",path)!=NULL;
      }
      Free(de.full_name);
    }
    if (!data) StrCpy(relic_app_notice,"File not found, a folder, or larger than 256 KiB.");
  } else if (!StrNCmp(url,"http://",7)) {
    if (h) {
      StrCpy(relic_app_notice,"Loading...");
      fetch=h->exe_addr; data=(*fetch)(url,&size);
      relic_app_notice[0]=0;
      if (!data) StrCpy(relic_app_notice,"The server did not answer, or the page could not be read.");
    } else StrCpy(relic_app_notice,"Network service unavailable. Use a PCNet adapter and restart.");
  } else if (!StrNCmp(url,"https://",8)) {
    StrCpy(relic_app_notice,"HTTPS is not available here (no TLS). Try http:// instead.");
    data=StrNew("This page uses HTTPS. The Browser has no TLS yet, so it "
          "cannot open secure pages. Some sites also answer on plain http://.");
    size=StrLen(data); html=FALSE;
  } else StrCpy(relic_app_notice,"Use http://, file: or about:home.");
  if (!data) {
    data=StrNew("Unable to open this address. Check the path, network service or protocol.");
    size=StrLen(data); html=FALSE;
  }
  if (size>RELIC_BROWSER_MAX) { size=RELIC_BROWSER_MAX; StrCpy(relic_app_notice,"Page truncated at 256 KiB."); }
  RelicBrowserParse(data,size,html); Free(data);
  if (history) {
    relic_browser_hist_count=relic_browser_hist_pos+1;
    if (relic_browser_hist_count==16) {
      for (i=0;i<15;i++) StrCpy(relic_browser_history[i],relic_browser_history[i+1]);
      relic_browser_hist_count=15;
    }
    StrCpy(relic_browser_history[relic_browser_hist_count++],url);
    relic_browser_hist_pos=relic_browser_hist_count-1;
  }
}

// Typed address: add file: or http:// when the scheme is missing.
U0 RelicBrowserGo(U8 *raw)
{
  U8 url[512];
  if (!raw[0]) return;
  if (!StrNCmp(raw,"http://",7) || !StrNCmp(raw,"https://",8) ||
        !StrNCmp(raw,"file:",5) || !StrNCmp(raw,"about:",6))
    RelicStrCopy(url,raw,sizeof(url));
  else if (raw[0]==':' || raw[1]==':' && raw[2]=='/') {
    StrCpy(url,"file:"); RelicStrCopy(url+5,raw,sizeof(url)-5);
  } else {
    StrCpy(url,"http://"); RelicStrCopy(url+7,raw,sizeof(url)-7);
  }
  RelicBrowserLoad(url);
}

I64 RelicBrowserRows(I64 h)
{
  return MaxI64(1,(h-RUI_FOOT_H-8-RELIC_BROWSER_Y)/RELIC_BROWSER_LH);
}

U0 RelicBrowserField(I64 w,I64 *x,I64 *fw)
{
  *x=RelicUIToolbarEnd(relic_browser_tb,4)+2;
  *fw=w-12-52-6-*x;
}

U0 RelicBrowserDraw(CTask *task,CDC *dc)
{
  I64 w=task->pix_width,h=task->pix_height,i,n,k,l,c0,c1,y,rows,off=0,fx,fw,
      cols,len,start,st;
  U8 *tag="";
  RelicUIFrame(task,dc,"Browser","Click links  Arrows scroll  Esc close",TRUE);
  if (relic_browser_hist_pos<=0) off|=1;
  if (relic_browser_hist_pos+1>=relic_browser_hist_count) off|=2;
  RelicUIToolbar(task,dc,relic_browser_tb,4,0,off);
  // Address field
  RelicBrowserField(w,&fx,&fw);
  dc->color=BLACK; GrRect(dc,fx,RUI_TB_Y,fw,RUI_TB_H);
  dc->color=RelicChoose(relic_browser_editing,rc_strong,rc_line);
  RelicOutline(dc,fx,RUI_TB_Y,fw,RUI_TB_H);
  cols=(fw-16)/FONT_WIDTH;
  if (relic_browser_editing) {
    len=StrLen(relic_browser_edit);
    start=MaxI64(0,len-cols+1);
    if (relic_browser_fresh && len) {
      dc->color=rc_text;
      GrRect(dc,fx+6,RUI_TB_Y+5,MinI64(len-start,cols)*FONT_WIDTH+4,12);
      dc->color=BLACK;
    } else dc->color=rc_strong;
    GrPrint(dc,fx+8,RUI_TB_Y+7,"%s",relic_browser_edit+start);
    dc->color=rc_strong;
    GrRect(dc,fx+9+(len-start)*FONT_WIDTH,RUI_TB_Y+5,1,12);
  } else {
    if (!StrNCmp(relic_browser_url,"http://",7)) tag="Not secure  ";
    else if (!StrNCmp(relic_browser_url,"file:",5)) tag="Local  ";
    dc->color=rc_dim; GrPrint(dc,fx+8,RUI_TB_Y+7,"%s",tag);
    dc->color=rc_text;
    RelicUIText(dc,fx+8+StrLen(tag)*FONT_WIDTH,RUI_TB_Y+7,cols-StrLen(tag),
          relic_browser_url);
  }
  st=RelicUIState(task,w-12-52,RUI_TB_Y,52,RUI_TB_H);
  RelicUIButton(dc,w-12-52,RUI_TB_Y,52,RUI_TB_H,"Open",st);
  // Page
  rows=RelicBrowserRows(h);
  for (i=0;i<rows;i++) {
    n=relic_browser_scroll+i;
    if (n<relic_browser_count) {
      dc->color=RelicChoose(relic_browser_flags[n],rc_strong,rc_text);
      GrPrint(dc,16,RELIC_BROWSER_Y+i*RELIC_BROWSER_LH,"%s",relic_browser_lines[n]);
    }
  }
  dc->color=rc_text;
  for (k=0;k<relic_browser_link_count;k++) {
    for (l=relic_browser_link_line[k];l<=relic_browser_link_eline[k];l++) {
      if (l>=relic_browser_scroll && l<relic_browser_scroll+rows && l<relic_browser_count) {
        c0=0; c1=StrLen(relic_browser_lines[l]);
        if (l==relic_browser_link_line[k]) c0=relic_browser_link_col[k];
        if (l==relic_browser_link_eline[k]) c1=relic_browser_link_ecol[k];
        y=RELIC_BROWSER_Y+(l-relic_browser_scroll)*RELIC_BROWSER_LH+9;
        if (c1>c0) GrLine(dc,16+c0*FONT_WIDTH,y,16+c1*FONT_WIDTH-1,y);
      }
    }
  }
  RelicUIScroll(dc,w-12,RELIC_BROWSER_Y,rows*RELIC_BROWSER_LH,
        relic_browser_count,rows,relic_browser_scroll);
}

// Link under a page position, or -1.
I64 RelicBrowserLinkAt(I64 line,I64 col)
{
  I64 k;
  for (k=0;k<relic_browser_link_count;k++) {
    if ((line>relic_browser_link_line[k] ||
          line==relic_browser_link_line[k] && col>=relic_browser_link_col[k]) &&
          (line<relic_browser_link_eline[k] ||
          line==relic_browser_link_eline[k] && col<relic_browser_link_ecol[k]))
      return k;
  }
  return -1;
}

U0 RelicBrowserFollow(I64 link)
{
  U8 url[512],resolved[512];
  if (link<0 || link>=relic_browser_link_count) return;
  StrCpy(url,relic_browser_links[link]);
  if (RelicURLResolve(relic_browser_url,url,resolved,sizeof(resolved)))
    RelicBrowserLoad(resolved);
  else StrCpy(relic_app_notice,"Link address is invalid or too long.");
}

U0 RelicBrowserEditStart()
{
  StrCpy(relic_browser_edit,relic_browser_url);
  if (!StrCmp(relic_browser_edit,"about:home")) relic_browser_edit[0]=0;
  relic_browser_editing=TRUE;
  relic_browser_fresh=TRUE;
}

U0 RelicBrowserApp()
{
  I64 ch,sc,mc,mx,my,i,w,h,rows,fx,fw,last_z=ms.pos.z,d,len,maxs;
  U8 url[512];
  Bool done=FALSE;
  if (!relic_browser_hist_count) RelicBrowserLoad("about:home");
  relic_browser_editing=FALSE;
  RelicAppGraphics(&RelicBrowserDraw);
  while (!done) {
    w=Fs->pix_width; h=Fs->pix_height; rows=RelicBrowserRows(h);
    maxs=MaxI64(0,relic_browser_count-rows);
    d=RelicWheel(&last_z);
    if (d) relic_browser_scroll=ClampI64(relic_browser_scroll+d*3,0,maxs);
    mc=RelicAppMsg(&ch,&sc);
    if (mc==MSG_MS_L_DOWN || mc==MSG_MS_L_D_DOWN) {
      ch=0;
      RelicUIMouse(Fs,&mx,&my);
      RelicBrowserField(w,&fx,&fw);
      relic_browser_editing=FALSE;
      if (RelicUICloseHit(w,mx,my)) done=TRUE;
      else if (RelicUIIn(mx,my,fx,RUI_TB_Y,fw,RUI_TB_H)) RelicBrowserEditStart;
      else if (RelicUIIn(mx,my,w-12-52,RUI_TB_Y,52,RUI_TB_H)) ch='o'+0x100;
      else if (my>=RUI_TB_Y && my<RUI_TB_Y+RUI_TB_H) {
        i=RelicUIToolbarHit(relic_browser_tb,4,mx,my);
        if (i==0) ch='b';
        if (i==1) ch='f';
        if (i==2) ch='r';
        if (i==3) ch='h';
      } else if (mx>=16 && my>=RELIC_BROWSER_Y &&
            my<RELIC_BROWSER_Y+rows*RELIC_BROWSER_LH) {
        RelicBrowserFollow(RelicBrowserLinkAt(
              (my-RELIC_BROWSER_Y)/RELIC_BROWSER_LH+relic_browser_scroll,
              (mx-16)/FONT_WIDTH));
      }
      if (ch=='o'+0x100) {
        StrCpy(url,"::/Home/");
        if (!StrNCmp(relic_browser_url,"file:",5))
          RelicStrCopy(url,relic_browser_url+5,sizeof(url));
        if (RelicAskEx("Open file","Path of a local text or HTML file.",url,
              sizeof(url),url) && url[0])
          RelicBrowserGo(url);
        ch=0;
      }
      if (ch!='b' && ch!='f' && ch!='r' && ch!='h') ch=0;
    } else if (mc==MSG_KEY_DOWN && relic_browser_editing) {
      len=StrLen(relic_browser_edit);
      if (ch==CH_ESC || ch==CH_SHIFT_ESC) relic_browser_editing=FALSE;
      else if (ch=='\n') {
        relic_browser_editing=FALSE;
        StrCpy(url,relic_browser_edit);
        RelicBrowserGo(url);
      } else if (ch==CH_BACKSPACE) {
        if (relic_browser_fresh) relic_browser_edit[0]=0;
        else if (len) relic_browser_edit[len-1]=0;
        relic_browser_fresh=FALSE;
      } else if (ch>=' ' && ch<127 && ch!='$$') {
        if (relic_browser_fresh) { relic_browser_edit[0]=0; len=0; }
        relic_browser_fresh=FALSE;
        if (len<sizeof(relic_browser_edit)-1) {
          relic_browser_edit[len]=ch; relic_browser_edit[len+1]=0;
        }
      } else if ((sc&0xFF)==SC_CURSOR_RIGHT || (sc&0xFF)==SC_END)
        relic_browser_fresh=FALSE;
      ch=0;
    } else if (mc==MSG_KEY_DOWN) {
      if (ch==CH_ESC || ch==CH_SHIFT_ESC) done=TRUE;
      else if ((sc&0xFF)==SC_CURSOR_DOWN) relic_browser_scroll=MinI64(maxs,relic_browser_scroll+1);
      else if ((sc&0xFF)==SC_CURSOR_UP) relic_browser_scroll=MaxI64(0,relic_browser_scroll-1);
      else if ((sc&0xFF)==SC_PAGE_DOWN) relic_browser_scroll=MinI64(maxs,relic_browser_scroll+rows);
      else if ((sc&0xFF)==SC_PAGE_UP) relic_browser_scroll=MaxI64(0,relic_browser_scroll-rows);
      else if (ch=='o' || ch=='O' || ch=='/') { RelicBrowserEditStart; ch=0; }
      else if (ch=='l' || ch=='L') {
        if (RelicAskEx("Follow link","Link number, as shown in [brackets].",
              url,8)) RelicBrowserFollow(Str2I64(url)-1);
        ch=0;
      }
    } else ch=0;
    if (ch=='b' || ch=='B') {
      if (relic_browser_hist_pos>0) RelicBrowserLoad(relic_browser_history[--relic_browser_hist_pos],FALSE);
    } else if (ch=='f' || ch=='F') {
      if (relic_browser_hist_pos+1<relic_browser_hist_count) RelicBrowserLoad(relic_browser_history[++relic_browser_hist_pos],FALSE);
    } else if (ch=='r' || ch=='R') {
      StrCpy(url,relic_browser_url); RelicBrowserLoad(url,FALSE);
    } else if (ch=='h' || ch=='H') {
      RelicBrowserLoad("about:home");
    }
  }
  relic_browser_editing=FALSE;
  Fs->draw_it=NULL;
}

// ---- Help ----
// Topics on the left, the selected page on the right.  The history and
// philosophy pages keep the tribute to Terry A. Davis from the first
// RelicOS help screen; the quotes come from his TempleOS ::/Doc/Charter.DD
// and ::/Doc/AboutTempleOS.DD.
#define RELIC_HELP_N     12
#define RELIC_HELP_X     12
#define RELIC_HELP_W     148
#define RELIC_HELP_BH    22
#define RELIC_HELP_GAP   4
#define RELIC_HELP_TX    176
#define RELIC_HELP_LH    12

U8 *relic_help_heads[RELIC_HELP_N]={"Welcome","Terry A. Davis",
  "His life","TempleOS","Philosophy","RelicOS fork","Shortcuts",
  "Documents","Browser","Games","Recovery","Credits"};

U8 *relic_help_text[RELIC_HELP_N]={
// Welcome
  "RelicOS is a fork of TempleOS, the operating system written by Terry A. "
  "Davis (1969-2018). It keeps his HolyC language, his font and his "
  "tools, and adds a desktop on top.\n\n"
  "Getting around\n"
  "Click the button at the bottom left, or press Space, to open the app "
  "menu. Type to search, use the arrows to pick an app and Enter to open "
  "it. Esc or the X at the top right closes an app.\n\n"
  "Using this help\n"
  "Click a topic on the left, or use Up/Down. PgUp/PgDn, Home/End or the "
  "mouse wheel scroll a long page. Esc closes Help.",
// Terry A. Davis
  "IN MEMORY OF TERRY A. DAVIS\n"
  "December 15, 1969 - August 11, 2018\n\n"
  "Terry Andrew Davis was an American programmer and the sole creator of "
  "TempleOS - the operating system that RelicOS is built upon and "
  "dedicated to.\n\n"
  "Who he was\n"
  "Terry was a brilliant, self-taught engineer who spent over a decade "
  "building TempleOS entirely alone - every line of code, every driver, "
  "the compiler, the kernel, the graphics system, and even the "
  "programming language (HolyC) itself.\n\n"
  "He dedicated his life to his magnum opus: a pure, ring-0, "
  "single-address-space operating system he believed was built for God.\n\n"
  "Rest in peace, Terry. Your work lives on.",
// His life
  "In his own words, from ::/Doc/AboutTempleOS.DD:\n\n"
  "He was a National Merit Scholar at Arizona State University, with a "
  "bachelor's in Computer System Engineering (embedded systems) and a "
  "master's in Electrical Engineering (control systems).\n\n"
  "1990-1996  Software, hardware and mechanical engineer at Ticketmaster, "
  "where he worked as a systems programmer.\n"
  "1996-1997  Designed a 3-axis stepper-motor milling machine with a "
  "CAD/CAM package, for his own company, Home Automation and Robotic "
  "Equipment (H.A.R.E.).\n"
  "1997-1999  Xytec Corp., FPGA-based image processing equipment.\n"
  "2000-2001  Wrote SimStructure for H.A.R.E.\n"
  "2001-2002  Head software and electrical engineer at Graphic "
  "Technologies, making replacement chips for toner cartridges.\n\n"
  "After that he gave his time to the operating system that became "
  "TempleOS, released as free, public domain software.",
// TempleOS
  "His work\n"
  "TempleOS is a technical marvel. Running entirely in kernel mode with no "
  "memory protection, it is one of the few operating systems ever written "
  "from scratch by a single person, including:\n\n"
  " - HolyC: a custom C variant with JIT compilation\n"
  " - A full 64-bit protected-mode kernel\n"
  " - DolDoc: a rich text/graphics document system\n"
  " - A complete IDE, compiler, and assembler\n"
  " - 640x480, 16-color VGA with custom graphics APIs\n"
  " - The custom RedSea file system and disk drivers\n\n"
  "Everything is HolyC source on the disk. The shell is the compiler: what "
  "you type is compiled and run on the spot, so the whole system can be "
  "read, changed and rebuilt from inside itself.",
// Philosophy
  "Terry wrote the rules of TempleOS in its Charter. A few of them:\n\n"
  " - \"TempleOS is God's official temple.\" Like Solomon's temple, a "
  "community focal point where offerings are made.\n"
  " - 640x480 with 16 colors is a covenant. Graphics should be "
  "transparent, not hidden in a GPU.\n"
  " - The vision is the Commodore 64: a non-networked, simple machine "
  "where programming was the goal, not just a means to an end. But modern, "
  "64-bit and multi-cored. \"It's a kayak, not a Titanic.\"\n"
  " - Low line count is the highest good, so it is easy to learn the "
  "whole thing. 100,000 lines for all time, not counting apps and demos.\n"
  " - Minimal abstraction. \"Any genius can make it complicated. Like in "
  "physics, it takes a supra-genius to make it simple.\"\n"
  " - Ring-0-only, full access to everything, a single address map.\n"
  " - No networking, so malware is not an issue. No encryption or "
  "passwords.\n"
  " - Free and public domain, 100% open source with all source included.\n\n"
  "\"Thou madest him to have dominion over the works of thy hands.\" "
  "- Psalm 8:6",
// RelicOS fork
  "RelicOS is a modern fork of TempleOS, built as a tribute to Terry's "
  "genius and vision. It aims to bring a refined, usable desktop "
  "experience to the foundation he created - while never forgetting who "
  "made it all possible.\n\n"
  "What stays: HolyC as the main language, Terry's original font, his "
  "editor and tools, and the TempleOS sources, kept as they were in "
  "src/templeos.\n\n"
  "What is new: this desktop and its apps, a simple browser and some "
  "networking. Networking goes against the Charter on purpose, because "
  "RelicOS aims at daily use. Some parts come from later TempleOS forks "
  "(TinkerOS, ZealOS); see Credits. Every change is listed in "
  "CHANGELOG.md.\n\n"
  "RelicOS is not TempleOS, and does not speak for Terry.",
// Shortcuts
  "On the desktop, press a letter to open an app:\n\n"
  "F Files   E Editor   S Shell   G Games\n"
  "B Browser   P Paint   C Calculator\n"
  "L Calendar   O Settings   N Notes\n"
  "T Tasks   M Memory   I System   H Help\n\n"
  "Space or the button at the bottom left opens the app menu.",
// Documents
  "Editor starts a new document in RelicData/Documents; an empty one is "
  "not kept. Notes and settings are in RelicData too. Use the Shell to "
  "rename, copy or delete folders.\n\n"
  "The Shell is the TempleOS command line: type HolyC and it runs, for "
  "example Dir; or Ed(\"File.HC\");",
// Browser
  "Local text and HTML files and plain http:// pages. HTTPS, images, CSS "
  "and JavaScript are not supported. The network needs a PCNet adapter "
  "(VMware: vlance).",
// Games
  "G opens the games launcher.\n\n"
  "DOOM\n"
  "W/S move, Left/Right turn, A/D strafe, Ctrl fire, Space doors, Tab map, "
  "Esc menu.",
// Recovery
  "Esc during early boot opens the drive menu.\n\n"
  "Ctrl+Alt+V switches back to plain VGA if the display fails, and shows a "
  "crash screen if the system ever freezes.\n\n"
  "Ctrl+Alt+T opens a recovery terminal.",
// Credits
  "TempleOS by Terry A. Davis is in the public domain. RelicOS is built on "
  "it, and his HolyC, original font, editor and creative tools live on.\n\n"
  "Original RelicOS code is under the MIT License. Other parts keep their "
  "own authors and licenses, including code from TinkerOS and ZealOS, "
  "which are TempleOS forks too. All credits and licenses are in "
  "NOTICE.md.\n\n"
  "Rest in peace, Terry. Your work lives on."};

I64 relic_help_sel=0,relic_help_scroll=0;

I64 RelicHelpCols(I64 w)
{
  return MaxI64(8,(w-RELIC_HELP_TX-24)/FONT_WIDTH);
}

I64 RelicHelpRows(I64 h)
{
  return MaxI64(1,(h-RUI_TOP_PLAIN-8-RUI_FOOT_H-8)/RELIC_HELP_LH);
}

I64 RelicHelpLines(I64 w)
{
  return RelicUIWrap(NULL,0,0,RelicHelpCols(w),RELIC_HELP_LH,
        relic_help_text[relic_help_sel]);
}

// Same wrapping as RelicUIWrap, drawing only lines first..first+rows-1.
U0 RelicHelpWrap(CDC *dc,I64 x,I64 y,I64 cols,U8 *text,I64 first,I64 rows)
{
  U8 line[256];
  I64 i=0,j,brk,n,lines=0;
  if (cols>255) cols=255;
  while (text[i] && lines<first+rows) {
    j=i; brk=-1;
    while (text[j] && text[j]!='\n' && j-i<cols) {
      if (text[j]==' ') brk=j;
      j++;
    }
    if (text[j] && text[j]!='\n' && text[j]!=' ' && brk>i)
      j=brk;
    if (lines>=first) {
      n=j-i;
      MemCpy(line,text+i,n);
      line[n]=0;
      GrPrint(dc,x,y+(lines-first)*RELIC_HELP_LH,"%s",line);
    }
    lines++;
    i=j;
    if (text[i]==' ' || text[i]=='\n') i++;
  }
}

U0 RelicHelpDraw(CTask *task,CDC *dc)
{
  I64 w=task->pix_width,h=task->pix_height,i,st,y,rows,total;
  RelicUIFrame(task,dc,"Help - RelicOS, a TempleOS fork",
        "Up/Down topic  Wheel scroll  Esc",FALSE);
  y=RUI_TOP_PLAIN+4;
  for (i=0;i<RELIC_HELP_N;i++) {
    if (i==relic_help_sel) st=RUI_ON;
    else st=RelicUIState(task,RELIC_HELP_X,y,RELIC_HELP_W,RELIC_HELP_BH);
    RelicUIButton(dc,RELIC_HELP_X,y,RELIC_HELP_W,RELIC_HELP_BH,
          relic_help_heads[i],st);
    y+=RELIC_HELP_BH+RELIC_HELP_GAP;
  }
  dc->color=rc_line;
  GrLine(dc,RELIC_HELP_TX-8,RUI_TOP_PLAIN,RELIC_HELP_TX-8,h-RUI_FOOT_H-8);
  rows=RelicHelpRows(h);
  total=RelicHelpLines(w);
  dc->color=rc_text;
  RelicHelpWrap(dc,RELIC_HELP_TX,RUI_TOP_PLAIN+8,RelicHelpCols(w),
        relic_help_text[relic_help_sel],relic_help_scroll,rows);
  RelicUIScroll(dc,w-12,RUI_TOP_PLAIN+4,rows*RELIC_HELP_LH,total,rows,
        relic_help_scroll);
}

U0 RelicHelpPick(I64 i)
{
  if (i<0) i=RELIC_HELP_N-1;
  if (i>=RELIC_HELP_N) i=0;
  relic_help_sel=i;
  relic_help_scroll=0;
}

U0 RelicHelpApp()
{
  I64 ch,sc,mc,mx,my,i,d,maxs,rows,last_z=ms.pos.z;
  Bool done=FALSE;
  relic_help_scroll=0;
  RelicAppGraphics(&RelicHelpDraw);
  StrCpy(relic_app_notice,"In memory of Terry A. Davis");
  while (!done) {
    rows=RelicHelpRows(Fs->pix_height);
    maxs=MaxI64(0,RelicHelpLines(Fs->pix_width)-rows);
    d=RelicWheel(&last_z);
    if (d) relic_help_scroll=ClampI64(relic_help_scroll+d*3,0,maxs);
    mc=RelicAppMsg(&ch,&sc);
    if (mc==MSG_MS_L_DOWN || mc==MSG_MS_L_D_DOWN) {
      RelicUIMouse(Fs,&mx,&my);
      if (RelicUICloseHit(Fs->pix_width,mx,my)) done=TRUE;
      else if (mx>=RELIC_HELP_X && mx<RELIC_HELP_X+RELIC_HELP_W &&
            my>=RUI_TOP_PLAIN+4) {
        i=(my-RUI_TOP_PLAIN-4)/(RELIC_HELP_BH+RELIC_HELP_GAP);
        if (i<RELIC_HELP_N) RelicHelpPick(i);
      }
    } else if (mc==MSG_KEY_DOWN) {
      if (ch==CH_ESC || ch==CH_SHIFT_ESC) done=TRUE;
      else if (ch=='\t') RelicHelpPick(relic_help_sel+1);
      else if (ch==' ') relic_help_scroll=MinI64(maxs,relic_help_scroll+rows);
      else if ((sc&0xFF)==SC_CURSOR_UP) RelicHelpPick(relic_help_sel-1);
      else if ((sc&0xFF)==SC_CURSOR_DOWN) RelicHelpPick(relic_help_sel+1);
      else if ((sc&0xFF)==SC_PAGE_UP)
        relic_help_scroll=MaxI64(0,relic_help_scroll-rows);
      else if ((sc&0xFF)==SC_PAGE_DOWN)
        relic_help_scroll=MinI64(maxs,relic_help_scroll+rows);
      else if ((sc&0xFF)==SC_HOME) relic_help_scroll=0;
      else if ((sc&0xFF)==SC_END) relic_help_scroll=maxs;
    }
  }
  relic_app_notice[0]=0;
  Fs->draw_it=NULL;
}
