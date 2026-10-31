// Adapted from TempleOS WinMgrSleep (Terry A. Davis, public domain).
// Preserve message, input, music and screen-capture handling at a 75 Hz target, leaving pacing headroom above 60 FPS.
I64 RelicWinMgrSleep(Bool flush_msgs=FALSE)
{
  I64 timeout_val,msg_code=0;
  CCtrl *c;
  Bool que;
  F64 t,t_delta;
  U8 *st;
  CDC *diff;
  CDate cdt;

  TimeCal;
  if ((t_delta=(t=tS)-winmgr.last_refresh_tS)>0.01)
    winmgr.fps=Max(1.0/t_delta,1);
  else
    winmgr.fps=99;
  winmgr.last_refresh_tS=t;
  WinCalcIdles;

  if (flush_msgs)
    FifoI64Flush(kbd.scan_code_fifo);
  else if (TaskValidate(sys_focus_task)) {
    KbdMsgsQue;

    que=TRUE;
    if (TaskValidate(sys_focus_task) &&
	  !Bt(&sys_focus_task->win_inhibit,WIf_FOCUS_TASK_CTRLS)) {
      c=sys_focus_task->next_ctrl;
      while (c!=&sys_focus_task->next_ctrl) {
	if (CtrlInside(c,ms.pos.x,ms.pos.y)) {
	  que=FALSE;
	  break;
	}
	c=c->next;
      }
    }
    msg_code=WinQueIPMsgs(que);
  } else {
    WinRefocus(sys_focus_task);
    if (!TaskValidate(sys_focus_task))
      FifoI64Flush(kbd.scan_code_fifo);
  }
  if (sys_focus_task)
    LBtr(&sys_focus_task->task_flags,TASKf_HAS_SONG);
  WinMsUpdate;

  if (!LBtr(&sys_semas[SEMA_JUST_PUMP_MSGS],0)) {
    t=tS+(1.0/75.0)/8;
    while (winmgr.ideal_refresh_tS<t)
      winmgr.ideal_refresh_tS+=(1.0/75.0);
    timeout_val=cnts.jiffies+(winmgr.ideal_refresh_tS-tS)*JIFFY_FREQ;
    LBts(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0);
    GrUpdateScrn;
    LBtr(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0);
    if (scrncast.record  && !scrncast.just_audio) {
      cdt=scrncast.t0_now(I64)+ToI64(CDATE_FREQ*(tS-scrncast.t0_tS));
      if (!scrncast.dc) {
	scrncast.dc=DCCopy(scrncast.dc2_alias);
	scrncast.dc->cdt=cdt;
	st=MStrPrint(scrncast.print_fmt,cdt);
	GRWrite(st,scrncast.dc);
	Free(st);
      } else if (MemCmp(scrncast.dc->body,
	    scrncast.dc2_alias->body,MSize(scrncast.dc2_alias->body))) {
	diff=DCDiff(scrncast.dc,scrncast.dc2_alias);
	diff->cdt=cdt;
	st=MStrPrint(scrncast.print_fmt,cdt);
	GRWrite(st,diff);
	Free(st);
	DCDel(diff);
	Free(scrncast.dc->body);
	scrncast.dc->body=MAllocIdent(scrncast.dc2_alias->body);
      }
    } else if (scrncast.dc) {
      DCDel(scrncast.dc); //TODO: $LK,"MemRep",A="MN:MemRep"$ can crash.
      scrncast.dc=NULL;
    }
    if (sys_focus_task && !Bt(&sys_focus_task->task_flags,TASKf_HAS_SONG)) {
      Free(music.cur_song);
      music.cur_song=NULL;
    }
    if (music.cur_song) {
      if (!music.cur_song_task)
	music.cur_song_task=Spawn(&CurSongTask,NULL,"Song");
    } else if (music.cur_song_task) {
      Kill(music.cur_song_task);
      music.cur_song_task=NULL;
    }
    winmgr.updates++;
    if (ms_hard.install_attempts) //Don't call before boot mouse install attempt
      KbdMsHndlr(FALSE,TRUE);
    SleepUntil(timeout_val);
  }
  return msg_code;
}

Bool relic_refresh_installed=FALSE;
U8 relic_refresh_original[5];
U0 RelicRefreshRestore()
{
  if (relic_refresh_installed) {
    PUSHFD
    CLI
    MemCpy((&WinMgrSleep)(U8 *),relic_refresh_original,5);
    POPFD
    relic_refresh_installed=FALSE;
  }
}

Bool RelicRefreshInstall()
{
  I64 delta;
  U8 *entry=(&WinMgrSleep)(U8 *);
  if (relic_refresh_installed) return TRUE;
  if (!relic_disp_on || FileFind("::/Home/RelicNo60.TXT")) return FALSE;
  delta=(&RelicWinMgrSleep)(U8 *)-(entry+5);
  if (delta<I32_MIN || delta>I32_MAX || entry[0]==0xE9) return FALSE;
  MemCpy(relic_refresh_original,entry,5);
  PUSHFD
  CLI
  entry[0]=0xE9;
  *(entry+1)(I32 *)=delta;
  winmgr.ideal_refresh_tS=tS;
  relic_refresh_installed=TRUE;
  POPFD
  return TRUE;
}
RelicRefreshInstall;
