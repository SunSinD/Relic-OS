// DevSetup.HC - one-time setup of the dev loop on an installed RelicOS.
// In the Relic Shell on the VM (transfer disk attached by tools\relic.ps1):
//   ATAMount('G',BDT_ATA,0x1F0,0x3F4,0);  (Enter, separate line)
//   #include "G:/DevSetup.HC";
// (use the transfer disk's letter if it is not G:), then reboot.

// RelicDevFindDrv (HomeSys.HC) finds the disk carrying RelicDev.TXT.
U8 relic_setup_drv = RelicDevFindDrv;
if (!relic_setup_drv)
  throw('NoXfer');
U8 relic_setup_src[64];

DirMk("::/Home/RelicOS");
StrPrint(relic_setup_src, "%c:/*.HC", relic_setup_drv);
Copy(relic_setup_src, "::/Home/RelicOS");
StrPrint(relic_setup_src, "%c:/wallpaper.raw", relic_setup_drv);
Copy(relic_setup_src, "::/Home/RelicOS");
StrPrint(relic_setup_src, "%c:/HomeSys.HC", relic_setup_drv);
Copy(relic_setup_src, "::/Home/HomeSys.HC.Z");
FileWrite("::/Home/RelicDev.TXT", "dev\n", 4);
"$FG,LTGREEN$Dev loop enabled. Reboot, then run relic.ps1 dev on the host.$FG$\n";
