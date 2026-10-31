// RelicStartUp.HC
// Task start-up hooks (UserStartUp, SrvStartUp) and the boot sequence.
// Included by ~/HomeSys.HC.Z after the dev sync, so edits here take effect
// on the very next boot.

#include "::/Home/RelicOS/RelicTheme.HC"
#include "::/Home/RelicOS/RelicShellHelp.HC"

// Fast display on virtual machines (VMware SVGA II or Bochs/QEMU VBE);
// plain VGA otherwise.  Compiled here in the Adam task so the WinMgr hook
// outlives every user task.
#include "::/Home/RelicOS/RelicDisplay.HC"
U0 RelicDisplayStart()
{
  I64 kind;
  U8 msg[STR_LEN];
  try {
    kind = RelicDisplayInit;
    StrPrint(msg, "Display: full screen VGA %0.1f ms, framebuffer %0.1f ms",
          relic_disp_vga_ms, relic_disp_fb_ms);
    RelicBootLog(msg);
    if (kind == DISP_VMWARE)
      RelicBootLog("Display: VMware SVGA II");
    else if (kind == DISP_BOCHS)
      RelicBootLog("Display: Bochs/QEMU VBE");
    else
      RelicBootLog("Display: VGA");
  } catch {
    Fs->catch_except = TRUE;
    RelicDisplayOff;
    RelicBootLog("Display: init failed, VGA");
  }
}
RelicDisplayStart;
#include "::/Home/RelicOS/RelicVMMouse.HC"
#include "::/Home/RelicOS/RelicRefresh.HC"

#include "::/Home/RelicOS/RelicSplash.HC"
#include "::/Home/RelicOS/RelicURL.HC"

Bool relic_network_ready=FALSE;
U0 RelicNetworkStart()
{
  I64 b,d;
  Bool found=FALSE;
  for (b=0;b<256 && !found;b++) for (d=0;d<32 && !found;d++)
    if (PCIReadU32(b,d,0,0)==0x20001022) found=TRUE;
  if (found && FileFind("::/Home/RelicOS/Net/Load.HC")) {
    try {
      ExeFile("::/Home/RelicOS/Net/Load.HC");
      relic_network_ready=HashFind("RelicHTTPGet",Fs->hash_table,HTT_FUN)!=NULL;
      RelicBootLog("Network: PCNet service loaded");
    } catch {
      Fs->catch_except=TRUE;
      RelicBootLog("Network: load failed, offline desktop");
    }
  }
}
Bool relic_desktop_started = FALSE;

U0 UserStartUp()
{
  RelicBootLog("UserStartUp: begin");
  RelicThemeApply;
  DocTermNew;
  Fs->text_attr = BLACK << 4 | DKGRAY;
  Fs->border_attr = BLACK << 4 | BLACK;
  Fs->border_src = 0;
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  WinFocus;
  DocClear;
  if (!relic_desktop_started) {
    WinBorder(OFF);
    LBts(&Fs->display_flags, DISPLAYf_SHOW);
    WinZBufUpdate;
    try {
      relic_desktop_started = TRUE;
      RelicBootLog("UserStartUp: RelicBoot.HC");
      RelicSplashStart;
      ExeFile("::/Home/RelicOS/RelicBoot.HC");
      throw('RelicDsk');
    } catch {
      Fs->catch_except = TRUE;
      RelicBootLog("UserStartUp: desktop failed, terminal fallback");
      relic_desktop_started = FALSE;
      // RelicDesktopRestore left the desktop painter installed; drop it or
      // the wallpaper keeps covering this terminal.
      Fs->draw_it = NULL;
      DCFill;
      winmgr.show_menu = FALSE;
      Fs->border_src = 0;
      Fs->border_attr = BLACK << 4 | DKGRAY;
      Fs->text_attr = BLACK << 4 | LTGRAY;
      WinBorder(ON);
          DocClear;
      "RelicOS desktop failed to start. Terminal fallback ready.\n";
    }
  } else {
    RelicTermDark;
    WinBorder(ON);
    DocClear;
    LBts(&Fs->display_flags, DISPLAYf_SHOW);
    WinZBufUpdate;
  }
}

// Servant tasks (PopUp, PopUpOk, menus, file pickers) call this.  Without
// it their window never gets DISPLAYf_SHOW and every popup is invisible
// while the caller waits on it (games looked frozen on a black screen).
U0 SrvStartUp()
{
  DocTermNew;
  RelicTermDark;
  winmgr.show_menu = FALSE;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
}

U0 StartUpTasks()
{
  RelicThemeApply;
  winmgr.show_menu = FALSE;
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  Fs->border_src = 0;
  DocClear;
  RelicNetworkStart;
  RelicBootLog("StartUpTasks: User");
  User;
  RelicBootLog("StartUpTasks: done");
}

StartUpTasks;
relic_startup_ok = TRUE;
