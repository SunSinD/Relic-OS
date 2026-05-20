// BuildRelease.HC
// Automatically installs RelicOS to the system and generates a bootable ISO.

"\n$FG,CYAN$==============================$FG$\n";
"  $FG,LTBLUE$RelicOS Release Builder$FG$\n";
"$FG,CYAN$==============================$FG$\n\n";

"1. Installing RelicOS to ::/Home/RelicOS/...\n";
DirMk("::/Home/RelicOS");
Copy("E:/RelicBoot.HC", "::/Home/RelicOS");
Copy("E:/RelicDesktop.HC", "::/Home/RelicOS");
Copy("E:/RelicTheme.HC", "::/Home/RelicOS");
Copy("E:/RelicWallpaper.HC", "::/Home/RelicOS");
Copy("E:/wallpaper.raw", "::/Home/RelicOS");
Copy("E:/RunTOOM.HC", "::/Home/RelicOS");
Copy("E:/GamesLauncher.HC", "::/Home/RelicOS");

"Installing TOOM into ::/Home/TOOM so DOOM is ready on first boot...\n";
U8 toom_drv;
Bool toom_installed = FALSE;
if (FileFind("E:/TOOM/SinglePlayer.HC") ||
    FileFind("E:/TOOM/SinglePlayer.HC.Z")) {
  DelTree("::/Home/TOOM");
  CopyTree("E:/TOOM/", "::/Home/TOOM");
  Del("::/Home/TOOM/Install.HC");
  toom_installed = TRUE;
}
if (!toom_installed && FileFind("E:/TOOM.ISO.C")) {
  Copy("E:/TOOM.ISO.C", "::/Home/RelicOS");
  toom_drv = MountFile("::/Home/RelicOS/TOOM.ISO.C");
  Drv(toom_drv);
  Cd("/");
  ExeFile("Install.HC", CCF_CMD_LINE);
  Drv('C');
  Cd("::/Home");
  if (FileFind("::/Home/TOOM/SinglePlayer.HC") ||
      FileFind("::/Home/TOOM/SinglePlayer.HC.Z"))
    toom_installed = TRUE;
  Del("::/Home/RelicOS/TOOM.ISO.C");
}
if (!toom_installed) {
  "$FG,LTRED$WARNING: TOOM source was not found on E:/TOOM.$FG$\n";
}

"2. Completely rebranding OS and fixing Boot Script...\n";
U0 ReplaceBranding(U8 *filename) {
  I64 size;
  U8 *buf = FileRead(filename, &size);
  if (buf) {
    I64 i;
    for (i = 0; i < size - 8; i++) {
      if (!MemCmp(buf + i, "TempleOS", 8)) MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite(filename, buf, size);
    Free(buf);
  }
}

U0 PatchDoDistro() {
  I64 size;
  U8 *buf = FileRead("::/Misc/DoDistro.HC.Z", &size);
  if (buf) {
    U8 *new_buf = MAlloc(size + 100);
    I64 i;
    I64 j = 0;
    for (i = 0; i < size; i++) {
      if (i < size - 6 && !MemCmp(buf + i, "b1\n\n\n\n", 6)) {
        MemCpy(new_buf + j, "T\nt\np\n\n\n\n", 9);
        j += 9;
        i += 5;
      } else {
        new_buf[j++] = buf[i];
      }
    }
    FileWrite("::/Misc/DoDistro.HC.Z", new_buf, j);
    Free(buf);
    Free(new_buf);
  }
}

PatchDoDistro;

CDirEntry *relic_boot_de = FilesFind("::/0000Boot/*");
CDirEntry *tmp_de = relic_boot_de;
while (tmp_de) {
  if (!(tmp_de->attr & RS_ATTR_DIR)) ReplaceBranding(tmp_de->full_name);
  tmp_de = tmp_de->next;
}

ReplaceBranding("::/Kernel/KStart64.HC.Z");
ReplaceBranding("::/Kernel/KMain.HC.Z");
ReplaceBranding("::/Misc/DoDistro.HC.Z");
ReplaceBranding("::/Misc/OSInstall.HC.Z");

U0 PatchVersion() {
  I64 size;
  U8 *buf = FileRead("::/Kernel/KernelA.HH.Z", &size);
  if (buf) {
    I64 i;
    for (i = 0; i < size - 5; i++) {
      if (!MemCmp(buf + i, "5.030", 5)) MemCpy(buf + i, "1.0.0", 5);
    }
    FileWrite("::/Kernel/KernelA.HH.Z", buf, size);
    Free(buf);
  }
}
PatchVersion;

U8 *clean_homesys =
  "// RelicOS Minimal Boot Script\n\n"
  "U0 UserStartUp()\n"
  "{\n"
  "  Fs->text_attr = BLACK << 4 | LTGRAY;\n"
  "  Fs->border_attr = BLACK << 4 | DKGRAY;\n"
  "  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;\n"
  "  winmgr.show_menu = FALSE;\n"
  "  AutoComplete(OFF);\n"
  "  WinBorder(OFF);\n"
  "  WinFocus;\n"
  "  DocTermNew;\n"
  "  Print(\"$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$\");\n"
  "  DocClear;\n"
  "  LBts(&Fs->display_flags,DISPLAYf_SHOW);\n"
  "  WinZBufUpdate;\n"
  "}\n\n"
  "U0 StartUpTasks()\n"
  "{\n"
  "  CTask *user1;\n"
  "  user1=User;\n"
  "  WinToTop(user1);\n"
  "  WinMax;\n"
  "  winmgr.show_menu = FALSE;\n"
  "  XTalk(user1,\"Cd;\\n#include \\\"::/Home/RelicOS/RelicBoot.HC\\\";\\n\");\n"
  "}\n\n"
  "StartUpTasks;\n";
FileWrite("::/Home/HomeSys.HC.Z", clean_homesys, StrLen(clean_homesys));

"Stable games launcher copied.\n";

U0 FixBootHDIns() {
  CDoc *doc = DocRead("::/Adam/Opt/Boot/BootHDIns.HC");
  if (doc) {
    CDocEntry *doc_e = doc->head.next;
    U8 *old_tag;
    while (doc_e != doc) {
      if (doc_e->type_u8 == DOCT_TEXT) {
        if (!StrNCmp(doc_e->tag, "T//See", 6)) { old_tag=doc_e->tag; doc_e->tag=StrNew("//See Install Documentation."); Free(old_tag); }
        if (!StrNCmp(doc_e->tag, "e//Study", 8)) { old_tag=doc_e->tag; doc_e->tag=StrNew("//Study my account examples: Cfg Strs, Update Funs"); Free(old_tag); }
        if (!StrCmp(doc_e->tag, "r")) { old_tag=doc_e->tag; doc_e->tag=StrNew(""); Free(old_tag); }
        if (!StrNCmp(doc_e->tag, "m#include", 9)) { old_tag=doc_e->tag; doc_e->tag=StrNew("#include \"BootHD\""); Free(old_tag); }
        if (!StrNCmp(doc_e->tag, "E#help", 6)) { old_tag=doc_e->tag; doc_e->tag=StrNew("#help_index \"Install\""); Free(old_tag); }
        if (!StrCmp(doc_e->tag, "d")) { old_tag=doc_e->tag; doc_e->tag=StrNew(""); Free(old_tag); }
        if (!StrNCmp(doc_e->tag, "i#define", 8)) { old_tag=doc_e->tag; doc_e->tag=StrNew("#define KERNEL_BIN_C    \"Kernel.BIN.C\""); Free(old_tag); }
        if (!StrCmp(doc_e->tag, "t")) { old_tag=doc_e->tag; doc_e->tag=StrNew(""); Free(old_tag); }
      }
      doc_e = doc_e->next;
    }
    DocWrite(doc);
    DocDel(doc);
  }
}

"3. Building bootable ISO (This will take a moment)...\n";
U0 PatchBootBinaries() {
  FixBootHDIns();
  I64 size;
  I64 i;
  U8 *buf = FileRead("::/0000Boot/BootCD.BIN.C", &size);
  if (buf) {
    for (i = 0; i < size - 8; i++) {
      if (!MemCmp(buf + i, "TempleOS", 8)) MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite("::/0000Boot/BootCD.BIN.C", buf, size);
    Free(buf);
  }
  buf = FileRead("::/0000Boot/BootHD.BIN.C", &size);
  if (buf) {
    for (i = 0; i < size - 8; i++) {
      if (!MemCmp(buf + i, "TempleOS", 8)) MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite("::/0000Boot/BootHD.BIN.C", buf, size);
    Free(buf);
  }
}
PatchBootBinaries;

#include "::/Misc/DoDistro.HC";

"4. Freeing up space on transfer drive...\n";
DelTree("E:/TOOM");
Del("E:/TOOM.ISO.C");
Del("E:/wallpaper.raw");
Del("E:/RelicBoot.HC");
Del("E:/RelicDesktop.HC");
Del("E:/RelicTheme.HC");
Del("E:/RelicWallpaper.HC");
Del("E:/RunTOOM.HC");
Del("E:/GamesLauncher.HC");

I64 clean_i;
for (clean_i = 0; clean_i < 30; clean_i++) {
  U8 clean_chunk_name[256];
  StrPrint(clean_chunk_name, "E:/ISO.P%02d", clean_i);
  Del(clean_chunk_name);
}

"5. Splitting and copying ISO to transfer drive in 2MB chunks (Bypassing FAT32 bug)...\n";
I64 relic_iso_size;
U8 *relic_iso_buf = FileRead("::/Tmp/MyDistro.ISO.C", &relic_iso_size);
if (relic_iso_buf) {
  I64 relic_chunk_sz = 1024 * 1024 * 2;
  I64 relic_chunks = (relic_iso_size + relic_chunk_sz - 1) / relic_chunk_sz;
  I64 relic_i;
  for (relic_i = 0; relic_i < relic_chunks; relic_i++) {
    U8 relic_chunk_name[256];
    StrPrint(relic_chunk_name, "E:/ISO.P%02d", relic_i);
    I64 relic_write_sz = relic_chunk_sz;
    if (relic_i == relic_chunks - 1) relic_write_sz = relic_iso_size - relic_i * relic_chunk_sz;
    "  Writing %s...\n", relic_chunk_name;
    FileWrite(relic_chunk_name, relic_iso_buf + relic_i * relic_chunk_sz, relic_write_sz);
  }
  Free(relic_iso_buf);
}

"\n$FG,CYAN$============================================$FG$\n";
"  $FG,LTGREEN$Done! The release ISO is now in your transfer drive.$FG$\n";
"  $FG,LTGRAY$You can now shut down the VM.$FG$\n";
"$FG,CYAN$============================================$FG$\n";
