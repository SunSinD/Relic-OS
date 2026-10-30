// RelicInstall.HC
// First-boot installation prompt for the RelicOS live CD/ISO.
//
// Included by RelicBoot.HC before the desktop starts.  When the machine
// booted from the DVD/ISO image and a hard drive is present, a dark-themed
// prompt offers to install RelicOS to that drive and reboot.  Declining
// continues straight into the live desktop.  On an installed system the
// prompt never appears.
//
// The actual copy/boot-loader work is delegated to the stock TempleOS
// installer (::/Misc/OSInstall.HC) which already handles the VMware /
// QEMU / VirtualBox auto-partition path and the "Reboot Now" question.

Bool relic_install_declined = FALSE;

Bool RelicBootedFromDVD()
{
  return sys_boot_src.u16[0] == BOOT_SRC_DVD;
}

// Probe the IDE buses silently (same call the stock VM installer uses) and
// report whether a hard disk, as opposed to only the CD/DVD, is present.
Bool RelicHasHardDrive()
{
  CATARep *head = NULL, *ata_drv = NULL, *atapi_drv = NULL;
  Bool old_silent = Silent(ON), res;

  ATARep(FALSE, TRUE, &head);
  ATAIDDrvs(head, &ata_drv, &atapi_drv);
  res = ata_drv != NULL;
  LinkedLstDel(head);
  Silent(old_silent);
  return res;
}

// TRUE when the live-CD install offer should be shown this boot.
Bool RelicInstallPromptNeeded()
{
  if (relic_install_declined)
    return FALSE;
  if (!RelicBootedFromDVD)
    return FALSE;
  if (!FileFind("::/Misc/OSInstall.HC") && !FileFind("::/Misc/OSInstall.HC.Z"))
    return FALSE;
  return TRUE;
}

U0 RelicInstallScreen()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;
  RelicMenuOff;
  WinFocus;
  Fs->border_src = BDS_CONST;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
  DocClear;
  "$WW,1$"; // wrap long lines instead of scrolling sideways
  DCFill;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
}

U0 RelicInstallBanner()
{
  "\n\n";
  "$FG,CYAN$  =========================================$FG$\n";
  "$FG,CYAN$   RelicOS V0.4.0 Setup$FG$\n";
  "$FG,CYAN$  =========================================$FG$\n\n";
  "$FG,LTGRAY$  You are running RelicOS from the live CD image.$FG$\n\n";
  if (RelicHasHardDrive)
    "$FG,LTGRAY$  A hard drive was detected ($FG,CYAN$%C:$FG,LTGRAY$).$FG$\n\n",
          blkdev.first_hd_drv_let;
  else
    "$FG,YELLOW$  No hard drive was detected. Installation may not be possible.$FG$\n\n";
  "$FG,LTGRAY$  Install RelicOS to the hard drive and reboot into it?$FG$\n\n";
  "$FG,YELLOW$    I$FG,LTGRAY$  Install to drive and reboot\n";
  "$FG,YELLOW$    C$FG,LTGRAY$  Continue to the live desktop (no changes)$FG$\n\n";
  "$FG,DKGRAY$  The installer will ask whether this is a virtual machine and\n";
  "  offers to reboot when it is done.$FG$\n\n";
  "$FG,LTGRAY$  Choice: $FG$";
}

// Hand over to the stock installer.  Returns when it finishes or is
// cancelled; if the user accepted "Reboot Now" the machine restarts inside.
U0 RelicInstallRun()
{
  "\n\n$FG,CYAN$  Starting installer...$FG$\n\n";
  try {
    RunFile("::/Misc/OSInstall",,TRUE);
  } catch {
    Fs->catch_except = TRUE;
    "\n$FG,LTRED$  Installer stopped with an error.$FG$\n";
    PutExcept;
  }
  AutoComplete(OFF);
  "\n$FG,LTGRAY$  Press any key to continue to the live desktop...$FG$\n";
  GetChar;
}

// ---- Release build helper (used from the Relic Shell) ----
// Mounts any extra IDE hard disks (e.g. the FAT32 transfer disk written by
// tools\relic.ps1 prepare) at the next free drive letters, then
// finds Build.HC on any mounted hard drive and runs it.  Equivalent to
// typing  MountIDEAuto;DrvRep;  and then  #include "X:/Build.HC";
Bool RelicBuild()
{
  U8 name[32];
  I64 l;
  Bool found = FALSE, old_silent;

  // The dev boot already mounted the transfer disk; a full MountIDEAuto
  // can hang when a CD drive has no disc, so only use it as a fallback.
  if (!relic_dev_drv) {
    old_silent = Silent(ON);
    MountIDEAuto;
    Silent(old_silent);
  }

  name[0] = 0;
  for (l = 'C'; l <= 'L' && !found; l++) {
    StrPrint(name, "%c:/Build.HC", l);
    try {
      if (FileFind(name, , FUF_Z_OR_NOT_Z))
        found = TRUE;
    } catch {
      Fs->catch_except = TRUE;
      name[0] = 0;
    }
  }
  if (!found || !name[0]) {
    "$FG,LTRED$No Build.HC found on drives C:..L:.$FG$\n"
    "Attach the transfer disk (host: tools\\relic.ps1 prepare) and retry.\n";
    return FALSE;
  }
  "$FG,CYAN$Running %s$FG$\n", name;
  ExeFile(name);
  return TRUE;
}

// Dark full-screen prompt.  Blocks (on this task only) until I or C.
U0 RelicInstallPrompt()
{
  I64 ch, sc, mc;
  Bool done = FALSE;

  RelicInstallScreen;
  RelicInstallBanner;
  FlushMsgs;

  while (!done) {
    mc = ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (!mc) {
      Sleep(15);
    } else if (ch == 'i' || ch == 'I') {
      done = TRUE;
      RelicInstallRun;
    } else if (ch == 'c' || ch == 'C' || ch == CH_ESC || ch == CH_SHIFT_ESC) {
      done = TRUE;
      relic_install_declined = TRUE;
    }
  }
  DocClear;
  DCFill;
  FlushMsgs;
}
