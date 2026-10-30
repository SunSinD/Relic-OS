// RelicOS boot script.  Installed as ::/Home/HomeSys.HC.Z by Build.HC and
// compiled by the Adam task at the end of StartOS.

// ---- Dev sync ----
// When the host dev loop (tools\relic.ps1) attached a transfer disk
// carrying RelicDev.TXT, copy the fresh sources onto this install BEFORE
// anything below is compiled, so every boot runs the latest code.
//
// Opt-in: this only runs on an install that has ::/Home/RelicDev.TXT (the
// dev VM; DevSetup.HC creates it).  A normal install never probes the IDE
// buses at boot: MountIDEAuto hung / panicked during boot on a fresh
// install whose CD drive was empty.
//
// RelicDev.TXT holds "dev" (sync only) or "build" (sync, then RelicBoot.HC
// runs RelicBuild; to write the ISO chunks for tools\relic.ps1 iso).

// ---- Boot log ----
// Each boot step appends a line to ::/Home/Boot.LOG (rewritten every boot),
// so a boot that hangs or lands in the debugger can be diagnosed by reading
// the disk from the host.
U8 relic_boot_log[2048];
I64 relic_boot_log_len = 0;

U0 RelicBootLog(U8 *msg)
{
  I64 n = StrLen(msg);
  if (relic_boot_log_len + n + 2 < sizeof(relic_boot_log)) {
    MemCpy(relic_boot_log + relic_boot_log_len, msg, n);
    relic_boot_log_len += n;
    relic_boot_log[relic_boot_log_len++] = '\n';
    try {
      if (DrvIsWritable(':'))
        FileWrite("::/Home/Boot.LOG", relic_boot_log, relic_boot_log_len);
    } catch
      Fs->catch_except = TRUE;
  }
}

RelicBootLog("HomeSys: start");

U8 relic_dev_drv = 0;
I64 relic_dev_action = 0; // 0 none, 1 dev, 2 build

U8 RelicDevFindDrv()
{
  I64 l;
  U8 path[32], res = 0;
  Bool hit;
  CDrv *dv;

  for (l = 'A'; l <= 'Z' && !res; l++) {
    dv = Let2Drv(l, FALSE);
    if (dv && dv->bd->type == BDT_ATA && dv->fs_type == FSt_FAT32) {
      StrPrint(path, "%c:/RelicDev.TXT", l);
      hit = FALSE;
      try {
        hit = FileFind(path);
      } catch
        Fs->catch_except = TRUE;
      if (hit)
        res = l;
    }
  }
  return res;
}

U0 RelicDevSync()
{
  U8 drv, src[64], *mark;
  Bool old_silent = Silent(ON);

  drv = RelicDevFindDrv;
  if (!drv) {
    // tools\relic.ps1 always wires the transfer disk as IDE 0:0
    // (primary master, ports 0x1F0/0x3F4, unit 0).
    try {
      ATAMount(blkdev.first_hd_drv_let, BDT_ATA, 0x1F0, 0x3F4, 0);
    } catch
      Fs->catch_except = TRUE;
    drv = RelicDevFindDrv;
  }
  if (drv && DrvIsWritable(':')) {
    relic_dev_drv = drv;
    relic_dev_action = 1;
    try {
      StrPrint(src, "%c:/RelicDev.TXT", drv);
      mark = FileRead(src);
      if (mark) {
        if (StrMatch("build", mark))
          relic_dev_action = 2;
        Free(mark);
      }
      DirMk("::/Home/RelicOS");
      StrPrint(src, "%c:/*.HC", drv);
      Copy(src, "::/Home/RelicOS");
      StrPrint(src, "%c:/wallpaper.raw", drv);
      Copy(src, "::/Home/RelicOS");
      StrPrint(src, "%c:/HomeSys.HC", drv);
      Copy(src, "::/Home/HomeSys.HC.Z");
      StrPrint(src, "%c:/TOOM/*.HC", drv);
      if (FileFind("::/Home/TOOM", , FUF_JUST_DIRS))
        Copy(src, "::/Home/TOOM");
    } catch
      Fs->catch_except = TRUE;
  }
  Silent(old_silent);
}

if (FileFind("::/Home/RelicDev.TXT")) {
  RelicBootLog("HomeSys: dev sync");
  RelicDevSync;
}
// Plain terminal start-up hooks first.  RelicStartUp.HC replaces them; if
// it fails to compile (a broken edit), these keep the machine usable: a
// normal terminal instead of a boot into the kernel debugger.
U0 UserStartUp()
{
  DocTermNew;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
}

U0 SrvStartUp()
{
  DocTermNew;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
}

Bool relic_startup_ok = FALSE; // RelicStartUp.HC sets it on its last line

U0 RelicStartUpRun()
{
  try
    ExeFile("::/Home/RelicOS/RelicStartUp.HC");
  catch
    Fs->catch_except = TRUE;
  // ExeFile reports compile errors itself and returns, so check the flag.
  if (!relic_startup_ok) {
    RelicBootLog("HomeSys: RelicStartUp.HC failed, plain terminal");
    User("\"RelicStartUp.HC failed (see ::/Home/Boot.LOG).\\n\";\n");
  }
}

// During the boot phase the compiler sends every compile error straight to
// the kernel debugger (CExcept.HC LexExcept) instead of throwing.  HomeSys
// is the last step of StartOS and KMain sets this flag right after it, so
// set it now: a broken Relic file then throws into the catch above.
LBts(&sys_run_level, RLf_ADAM_SERVER);
RelicBootLog("HomeSys: RelicStartUp");
RelicStartUpRun;
