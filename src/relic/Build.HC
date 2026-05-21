// BuildRelease.HC
// Automatically installs RelicOS to the system and generates a bootable ISO.

U8 relic_src_drv = 'E';
if (FileFind("D:/Build.HC") || FileFind("D:/Build.HC.Z"))
  relic_src_drv = 'D';
else if (FileFind("E:/Build.HC") || FileFind("E:/Build.HC.Z"))
  relic_src_drv = 'E';

"Detected Relic transfer drive: %c:\n", relic_src_drv;

U0 RelicCopy(U8 *src_file, U8 *dst_dir) {
  U8 buf[256];
  StrPrint(buf, "%c:/%s", relic_src_drv, src_file);
  Copy(buf, dst_dir);
}

U0 RelicCopyTree(U8 *src_dir, U8 *dst_dir) {
  U8 buf[256];
  StrPrint(buf, "%c:/%s", relic_src_drv, src_dir);
  CopyTree(buf, dst_dir);
}

Bool RelicFileFind(U8 *filename) {
  U8 buf[256];
  StrPrint(buf, "%c:/%s", relic_src_drv, filename);
  return FileFind(buf);
}

U8 *RelicFileRead(U8 *filename, I64 *size_out=NULL) {
  U8 buf[256];
  StrPrint(buf, "%c:/%s", relic_src_drv, filename);
  return FileRead(buf, size_out);
}

U0 RelicFileWrite(U8 *filename, U8 *data, I64 size) {
  U8 buf[256];
  StrPrint(buf, "%c:/%s", relic_src_drv, filename);
  FileWrite(buf, data, size);
}

"\n$FG,CYAN$==============================$FG$\n";
"  $FG,LTBLUE$RelicOS Release Builder$FG$\n";
"$FG,CYAN$==============================$FG$\n\n";

"1. Installing RelicOS to ::/Home/RelicOS/...\n";
DirMk("::/Home/RelicOS");
RelicCopy("RelicBoot.HC", "::/Home/RelicOS");
RelicCopy("RelicDesktop.HC", "::/Home/RelicOS");
RelicCopy("RelicChrome.HC", "::/Home/RelicOS");
RelicCopy("RelicTheme.HC", "::/Home/RelicOS");
RelicCopy("RelicWallpaper.HC", "::/Home/RelicOS");
RelicCopy("wallpaper.raw", "::/Home/RelicOS");
RelicCopy("RunTOOM.HC", "::/Home/RelicOS");
RelicCopy("GamesLauncher.HC", "::/Home/RelicOS");

"Installing TOOM into ::/Home/TOOM so DOOM is ready on first boot...\n";
U8 toom_drv;
Bool toom_installed = FALSE;
if (RelicFileFind("TOOM/SinglePlayer.HC") ||
    RelicFileFind("TOOM/SinglePlayer.HC.Z")) {
  DelTree("::/Home/TOOM");
  RelicCopyTree("TOOM/", "::/Home/TOOM");
  Del("::/Home/TOOM/Install.HC");
  toom_installed = TRUE;
}
if (!toom_installed && RelicFileFind("TOOM.ISO.C")) {
  RelicCopy("TOOM.ISO.C", "::/Home/RelicOS");
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
  "$FG,LTRED$WARNING: TOOM source was not found on %c:/TOOM.$FG$\n", relic_src_drv;
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

// RestoreStartOS: Strip any previously-injected RelicBootPalette code
// from StartOS.HC.Z. StartOS.HC.Z is compiled at the VERY first stage
// of boot before ANY symbols exist — we must NEVER inject code into it.
// The dark palette is set later via PatchDefaultPalette on GrPalette.HC.Z
// and via RelicThemeApply in HomeSys.HC.Z.
U0 RestoreStartOS() {
  I64 size;
  U8 *buf = NULL;
  if (!FileFind("::/StartOS.HC.Z"))
    return;
  buf = FileRead("::/StartOS.HC.Z", &size);
  if (buf) {
    U8 *marker = StrFirstOcc(buf, "RelicBootPalette;");
    if (marker) {
      // Find the newline after "RelicBootPalette;\n"
      U8 *rest = StrFirstOcc(marker, "\n");
      if (rest) {
        rest++; // skip the newline
        I64 new_size = size - (rest - buf);
        if (new_size > 0)
          FileWrite("::/StartOS.HC.Z", rest, new_size);
      }
      "  Repaired StartOS.HC.Z (stripped injected palette code).\n";
    }
    Free(buf);
  }
}
RestoreStartOS;

U0 PatchDefaultPalette(U8 *filename) {
  I64 size;
  U8 *buf = NULL;
  if (!FileFind(filename))
    return;
  buf = FileRead(filename, &size);
  if (buf) {
    U8 *start = StrFirstOcc(buf, "gr_palette_std[16]");
    if (start) {
      U8 *array_start = StrFirstOcc(start, "{");
      U8 *array_end = StrFirstOcc(start, "}");
      if (array_start && array_end && array_end > array_start) {
        U8 *new_vals = 
          "{\n"
          "  0x000000000000, 0x000000000000, 0x200052002400, 0x00009000B800,\n"
          "  0xB80008000800, 0x600015007000, 0xA00052001000, 0x780078007400,\n"
          "  0x380038003A00, 0x300048009000, 0x380090004800, 0x100030003500,\n"
          "  0xFFFF38382828, 0xBBBB5000CCCC, 0xFFFFC8002800, 0x280028002600\n"
          "}";
        I64 prefix_len = array_start - buf;
        I64 suffix_len = buf + size - (array_end + 1);
        I64 new_vals_len = StrLen(new_vals);
        U8 *new_buf = MAlloc(prefix_len + new_vals_len + suffix_len + 1);
        MemCpy(new_buf, buf, prefix_len);
        MemCpy(new_buf + prefix_len, new_vals, new_vals_len);
        MemCpy(new_buf + prefix_len + new_vals_len, array_end + 1, suffix_len);
        new_buf[prefix_len + new_vals_len + suffix_len] = 0;
        FileWrite(filename, new_buf, prefix_len + new_vals_len + suffix_len);
        Free(new_buf);
      }
    }
    Free(buf);
  }
}

PatchDefaultPalette("::/Adam/Gr/GrPalette.HC.Z");

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

  if (!RelicFileFind("ADefineClean.HC"))
    return;

  buf = RelicFileRead("ADefineClean.HC", &size);
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

  if (!RelicFileFind("WallPaperClean.HC"))
    return;

  buf = RelicFileRead("WallPaperClean.HC", &size);
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
    StrPrint(relic_chunk_name, "%c:/ISO.P%02d", relic_src_drv, relic_i);
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
