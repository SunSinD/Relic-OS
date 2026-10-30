// RelicStartUp.HC
// Task start-up hooks (UserStartUp, SrvStartUp) and the boot sequence.
// Included by ~/HomeSys.HC.Z after the dev sync, so edits here take effect
// on the very next boot.

#include "::/Home/RelicOS/RelicTheme.HC"

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
  "$FD,DKGRAY$$BD,BLACK$$FG,DKGRAY$$BG,BLACK$";
  DocClear;
  if (!relic_desktop_started) {
    WinBorder(OFF);
    LBts(&Fs->display_flags, DISPLAYf_SHOW);
    WinZBufUpdate;
    try {
      relic_desktop_started = TRUE;
      RelicBootLog("UserStartUp: RelicBoot.HC");
      ExeFile("::/Home/RelicOS/RelicBoot.HC");
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
      "$FD,LTGRAY$$BD,DKGRAY$$FG,LTGRAY$$BG,BLACK$";
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
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocClear;
  RelicBootLog("StartUpTasks: User");
  User;
  RelicBootLog("StartUpTasks: done");
}

StartUpTasks;
relic_startup_ok = TRUE;
