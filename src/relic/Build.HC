// BuildRelease.HC
// Automatically installs RelicOS to the system and generates a bootable ISO.

"\n$FG,CYAN$==============================$FG$\n";
"  $FG,LTBLUE$RelicOS Release Builder$FG$\n";
"$FG,CYAN$==============================$FG$\n\n";

"1. Installing RelicOS to ::/Home/RelicOS/...\n";
DirMk("::/Home/RelicOS");
Copy("E:/RelicBoot.HC", "::/Home/RelicOS");
Copy("E:/RelicDesktop.HC", "::/Home/RelicOS");
Copy("E:/RelicChrome.HC", "::/Home/RelicOS");
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
  U8 *buf = NULL;
  if (!FileFind(filename))
    return;
  buf = FileRead(filename, &size);
  if (buf) {
    I64 i;
    for (i = 0; i < size - 14; i++) {
      if (!MemCmp(buf + i, "TempleOS V5.03", 14)) MemCpy(buf + i, "RelicOS V1.0.0", 14);
    }
    for (i = 0; i < size - 8; i++) {
      if (!MemCmp(buf + i, "TempleOS", 8)) MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite(filename, buf, size);
    Free(buf);
  }
}

CDirEntry *relic_boot_de = FilesFind("::/0000Boot/*");
CDirEntry *tmp_de = relic_boot_de;
while (tmp_de) {
  if (!(tmp_de->attr & RS_ATTR_DIR)) ReplaceBranding(tmp_de->full_name);
  tmp_de = tmp_de->next;
}

ReplaceBranding("::/Misc/DoDistro.HC.Z");
ReplaceBranding("::/Misc/OSInstall.HC.Z");
ReplaceBranding("::/Kernel.BIN.C");
ReplaceBranding("::/0000Boot/0000Kernel.BIN.C");
ReplaceBranding("::/StartOS.HC.Z");

U0 PrependTheme(U8 *filename) {
  I64 size;
  U8 *buf = NULL;
  if (!FileFind(filename))
    return;
  buf = FileRead(filename, &size);
  if (buf) {
    if (StrMatch("RelicBootPalette", buf)) {
      Free(buf);
      return;
    }
    U8 *theme_code = 
      "U0 RelicBootPalette() {\n"
      "  CBGR48 pal[16];\n"
      "  MemSet(pal, 0, sizeof(CBGR48) * 16);\n"
      "  pal[0].r=0x0000; pal[0].g=0x0000; pal[0].b=0x0000;\n"
      "  pal[1].r=0x0000; pal[1].g=0x0000; pal[1].b=0x0000;\n"
      "  pal[2].r=0x2000; pal[2].g=0x5200; pal[2].b=0x2400;\n"
      "  pal[3].r=0x0000; pal[3].g=0x9000; pal[3].b=0xB800;\n"
      "  pal[4].r=0xB800; pal[4].g=0x0800; pal[4].b=0x0800;\n"
      "  pal[5].r=0x6000; pal[5].g=0x1500; pal[5].b=0x7000;\n"
      "  pal[6].r=0xA000; pal[6].g=0x5200; pal[6].b=0x1000;\n"
      "  pal[7].r=0x7800; pal[7].g=0x7800; pal[7].b=0x7400;\n"
      "  pal[8].r=0x3800; pal[8].g=0x3800; pal[8].b=0x3A00;\n"
      "  pal[9].r=0x3000; pal[9].g=0x4800; pal[9].b=0x9000;\n"
      "  pal[10].r=0x3800; pal[10].g=0x9000; pal[10].b=0x4800;\n"
      "  pal[11].r=0x1000; pal[11].g=0x3000; pal[11].b=0x3500;\n"
      "  pal[12].r=0xFFFF; pal[12].g=0x3838; pal[12].b=0x2828;\n"
      "  pal[13].r=0xBBBB; pal[13].g=0x5000; pal[13].b=0xCCCC;\n"
      "  pal[14].r=0xFFFF; pal[14].g=0xC800; pal[14].b=0x2800;\n"
      "  pal[15].r=0x2800; pal[15].g=0x2800; pal[15].b=0x2600;\n"
      "  GrPaletteSet(pal);\n"
      "}\n"
      "RelicBootPalette;\n";
    I64 theme_len = StrLen(theme_code);
    U8 *new_buf = MAlloc(size + theme_len + 1);
    MemCpy(new_buf, theme_code, theme_len);
    MemCpy(new_buf + theme_len, buf, size);
    new_buf[size + theme_len] = 0;
    FileWrite(filename, new_buf, size + theme_len);
    Free(buf);
    Free(new_buf);
  }
}

PrependTheme("::/StartOS.HC.Z");

Bool RelicReplaceOnce(U8 **buf_ptr, I64 *size_ptr, U8 *old_text, U8 *new_text)
{
  U8 *buf = *buf_ptr;
  U8 *hit = StrFirstOcc(buf, old_text);
  U8 *new_buf;
  I64 old_len, new_len, prefix_len, suffix_len, new_size;

  if (!hit)
    return FALSE;

  old_len = StrLen(old_text);
  new_len = StrLen(new_text);
  prefix_len = hit - buf;
  suffix_len = *size_ptr - prefix_len - old_len;
  new_size = *size_ptr - old_len + new_len;
  new_buf = MAlloc(new_size + 1);

  MemCpy(new_buf, buf, prefix_len);
  MemCpy(new_buf + prefix_len, new_text, new_len);
  MemCpy(new_buf + prefix_len + new_len, hit + old_len, suffix_len);
  new_buf[new_size] = 0;

  Free(buf);
  *buf_ptr = new_buf;
  *size_ptr = new_size;
  return TRUE;
}

Bool RelicFileReplaceOnce(U8 *filename, U8 *old_text, U8 *new_text)
{
  I64 size;
  U8 *buf = NULL;
  Bool changed = FALSE;

  if (!FileFind(filename))
    return FALSE;
  buf = FileRead(filename, &size);
  if (buf) {
    changed = RelicReplaceOnce(&buf, &size, old_text, new_text);
    if (changed)
      FileWrite(filename, buf, size);
    Free(buf);
  }
  return changed;
}

U0 RestoreADefine()
{
  I64 size;
  U8 *buf = NULL;

  if (!FileFind("E:/ADefineClean.HC"))
    return;

  buf = FileRead("E:/ADefineClean.HC", &size);
  if (buf) {
    FileWrite("::/Adam/ADefine.HC.Z", buf, size);
    Free(buf);
  }
}
RestoreADefine;

U0 RestoreWallPaper()
{
  I64 size;
  U8 *buf = NULL;

  if (!FileFind("E:/WallPaperClean.HC"))
    return;

  buf = FileRead("E:/WallPaperClean.HC", &size);
  if (buf) {
    FileWrite("::/Adam/WallPaper.HC.Z", buf, size);
    Free(buf);
  }
}
RestoreWallPaper;

U8 *clean_homesys =
  "// RelicOS Minimal Boot Script\n\n"
  "#include \"::/Home/RelicOS/RelicTheme.HC\"\n\n"
  "Bool relic_desktop_started = FALSE;\n\n"
  "U0 UserStartUp()\n"
  "{\n"
  "  RelicThemeApply;\n"
  "  Fs->text_attr = BLACK << 4 | DKGRAY;\n"
  "  Fs->border_attr = BLACK << 4 | BLACK;\n"
  "  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS;\n"
  "  winmgr.show_menu = FALSE;\n"
  "  AutoComplete(OFF);\n"
  "  WinFocus;\n"
  "  Print(\"$FD,DKGRAY$$BD,BLACK$$FG,DKGRAY$$BG,BLACK$\");\n"
  "  DocClear;\n"
  "  if (!relic_desktop_started) {\n"
  "    relic_desktop_started = TRUE;\n"
  "    WinBorder(OFF);\n"
  "    LBts(&Fs->display_flags,DISPLAYf_SHOW);\n"
  "    WinZBufUpdate;\n"
  "    try {\n"
  "      ExeFile(\"::/Home/RelicOS/RelicBoot.HC\");\n"
  "    } catch {\n"
  "      winmgr.show_menu = FALSE;\n"
  "      WinBorder(ON);\n"
  "      Print(\"$FD,DKGRAY$$BD,BLACK$$FG,DKGRAY$$BG,BLACK$\");\n"
  "      DocClear;\n"
  "      \"RelicOS desktop failed to start. Terminal fallback ready.\\n\";\n"
  "    }\n"
  "  } else {\n"
  "    WinBorder(ON);\n"
  "    DocTermNew;\n"
  "    Print(\"$FD,DKGRAY$$BD,BLACK$$FG,DKGRAY$$BG,BLACK$\");\n"
  "    DocClear;\n"
  "    LBts(&Fs->display_flags,DISPLAYf_SHOW);\n"
  "    WinZBufUpdate;\n"
  "  }\n"
  "}\n\n"
  "U0 StartUpTasks()\n"
  "{\n"
  "  RelicThemeApply;\n"
  "  winmgr.show_menu = FALSE;\n"
  "  Fs->text_attr = BLACK << 4 | BLACK;\n"
  "  Fs->border_attr = BLACK << 4 | BLACK;\n"
  "  Print(\"$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$\");\n"
  "  DocClear;\n"
  "  User;\n"
  "}\n\n"
  "StartUpTasks;\n";
FileWrite("::/Home/HomeSys.HC.Z", clean_homesys, StrLen(clean_homesys));

"Stable games launcher copied.\n";

U0 FixBootHDIns() {
  CDoc *doc = NULL;
  if (!FileFind("::/Adam/Opt/Boot/BootHDIns.HC"))
    return;
  doc = DocRead("::/Adam/Opt/Boot/BootHDIns.HC");
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
#define KERNEL_BIN_C "Kernel.BIN.C"
#define BOOT_DIR "/0000Boot"
#define BOOT_DIR_KERNEL_BIN_C BOOT_DIR "/0000" KERNEL_BIN_C

U0 PatchBootBinaries() {
  FixBootHDIns();
  I64 size;
  I64 i;
  U8 *buf = NULL;
  if (FileFind("::/0000Boot/BootCD.BIN.C"))
    buf = FileRead("::/0000Boot/BootCD.BIN.C", &size);
  if (buf) {
    for (i = 0; i < size - 14; i++) {
      if (!MemCmp(buf + i, "TempleOS V5.03", 14)) MemCpy(buf + i, "RelicOS V1.0.0", 14);
    }
    for (i = 0; i < size - 8; i++) {
      if (!MemCmp(buf + i, "TempleOS", 8)) MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite("::/0000Boot/BootCD.BIN.C", buf, size);
    Free(buf);
  }
  buf = NULL;
  if (FileFind("::/0000Boot/BootHD.BIN.C"))
    buf = FileRead("::/0000Boot/BootHD.BIN.C", &size);
  if (buf) {
    for (i = 0; i < size - 14; i++) {
      if (!MemCmp(buf + i, "TempleOS V5.03", 14)) MemCpy(buf + i, "RelicOS V1.0.0", 14);
    }
    for (i = 0; i < size - 8; i++) {
      if (!MemCmp(buf + i, "TempleOS", 8)) MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite("::/0000Boot/BootHD.BIN.C", buf, size);
    Free(buf);
  }
  buf = NULL;
  if (FileFind("::/0000Boot/0000Kernel.BIN.C"))
    buf = FileRead("::/0000Boot/0000Kernel.BIN.C", &size);
  if (buf) {
    for (i = 0; i < size - 14; i++) {
      if (!MemCmp(buf + i, "TempleOS V5.03", 14)) MemCpy(buf + i, "RelicOS V1.0.0", 14);
    }
    for (i = 0; i < size - 8; i++) {
      if (!MemCmp(buf + i, "TempleOS", 8)) MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite("::/0000Boot/0000Kernel.BIN.C", buf, size);
    Free(buf);
  }
}

U0 RelicLoadISOHelpers()
{
  Cd("::/Adam/Opt/Boot");
  if (!HashFind("BDVD_START", Fs->hash_table, HTG_SRC_SYM))
    ExeFile("BootDVD.HC.Z", CCF_JUST_LOAD);
  if (!HashFind("RedSeaISO", Fs->hash_table, HTG_SRC_SYM))
    ExeFile("DskISORedSea.HC.Z", CCF_JUST_LOAD);
  Cd("::/");
}
RelicLoadISOHelpers;

U0 RelicMakeISO(U8 *_out_iso_filename)
{
  U8 *out_iso_filename = FileNameAbs(_out_iso_filename);

  Drv('C');
  Cd("/");
  if (!DrvIsWritable) {
    "$FG,LTRED$Drive C must be writable before building the ISO.$FG$\n";
    Free(out_iso_filename);
    return;
  }

  DelTree("/Distro");
  Del(out_iso_filename);

  DirMk("/Distro");
  if (!FileFind(BOOT_DIR_KERNEL_BIN_C)) {
    "$FG,LTRED$Missing %s. Reboot from a clean installed disk before building ISO.$FG$\n",
          BOOT_DIR_KERNEL_BIN_C;
    Free(out_iso_filename);
    return;
  }
  PatchBootBinaries;

  Copy("/*", "/Distro");
  Del("/Distro/" KERNEL_BIN_C);

  CopyTree(BOOT_DIR, "/Distro" BOOT_DIR);
  CopyTree("/Home", "/Distro/Home");
  CopyTree("/Adam", "/Distro/Adam");
  CopyTree("/Apps", "/Distro/Apps");
  CopyTree("/Compiler", "/Distro/Compiler");
  CopyTree("/Demo", "/Distro/Demo");
  CopyTree("/Doc", "/Distro/Doc");
  CopyTree("/Kernel", "/Distro/Kernel");
  CopyTree("/Misc", "/Distro/Misc");
  if (FileFind("/Downloads"))
    CopyTree("/Downloads", "/Distro/Downloads");
  DirMk("/Distro/Tmp");
  DirMk("/Distro/Tmp/ScrnShots");

  RedSeaISO(out_iso_filename, "/Distro", "/Distro" BOOT_DIR_KERNEL_BIN_C);
  Free(out_iso_filename);
}

RelicMakeISO("::/Tmp/MyDistro.ISO.C");

"4. Keeping transfer sources intact.\n";

"5. Writing ISO chunks to transfer drive...\n";
I64 relic_iso_size;
U8 *relic_iso_buf = NULL;
if (FileFind("::/Tmp/MyDistro.ISO.C"))
  relic_iso_buf = FileRead("::/Tmp/MyDistro.ISO.C", &relic_iso_size);
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
} else {
  "$FG,LTRED$ISO build failed before ::/Tmp/MyDistro.ISO.C was created.$FG$\n";
}

"\n$FG,CYAN$========================$FG$\n";
"  $FG,LTGREEN$Done. ISO chunks ready.$FG$\n";
"  $FG,LTGRAY$Shut down the VM.$FG$\n";
"$FG,CYAN$========================$FG$\n";
