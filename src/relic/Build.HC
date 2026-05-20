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
ReplaceBranding("::/Kernel/KEnd.HC.Z");
ReplaceBranding("::/Kernel/KDbg.HC.Z");
ReplaceBranding("::/Adam/ADefine.HC.Z");
ReplaceBranding("::/Misc/DoDistro.HC.Z");
ReplaceBranding("::/Misc/OSInstall.HC.Z");

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
  U8 *buf = FileRead(filename, &size);
  Bool changed = FALSE;

  if (buf) {
    changed = RelicReplaceOnce(&buf, &size, old_text, new_text);
    if (changed)
      FileWrite(filename, buf, size);
    Free(buf);
  }
  return changed;
}

U0 RepairWallPaper()
{
  I64 size;
  U8 *buf = FileRead("::/Adam/WallPaper.HC.Z", &size);
  Bool changed = FALSE;
  U8 *old_top =
    "    Date2Struct(&ds,Now+local_time_offset);\n"
    "    i=sys_code_bp->alloced_u8s-sys_code_bp->used_u8s;\n"
    "    if (sys_data_bp)\n"
    "      i+=sys_data_bp->alloced_u8s-sys_data_bp->used_u8s;\n"
    "    StrPrint(wall->top_line,\n"
    "\t  \"%3tZ %02d/%02d %02d:%02d:%02d FPS:%2tf Mem:%010X CPU\",\n"
    "\t  ds.day_of_week,\"ST_DAYS_OF_WEEK\",ds.mon,ds.day_of_mon,\n"
    "\t  ds.hour,ds.min,ds.sec,winmgr.fps,i);\n";
  U8 *bad_top =
    "    Date2Struct(&ds,Now+local_time_offset);\n"
    "    StrPrint(wall->top_line,\n"
    "\t  \"%3tZ %02d/%02d %02d:%02d:%02d FPS:%2tf\",\n"
    "\t  ds.day_of_week,\"ST_DAYS_OF_WEEK\",ds.mon,ds.day_of_mon,\n"
    "\t  ds.hour,ds.min,ds.sec,winmgr.fps);\n";
  U8 *cpu_loop =
    "  for (i=0;i<mp_cnt;i++) {\n"
    "    c=&cpu_structs[i];\n"
    "    if (i&1)\n"
    "      TextPrint(Fs,44+i*2,0,BLUE<<4+WHITE,\"%2tf\",100.0*(1.0-c->idle_factor));\n"
    "    else\n"
    "      TextPrint(Fs,44+i*2,0,BLUE<<4+YELLOW,\"%2tf\",100.0*(1.0-c->idle_factor));\n"
    "  }\n\n";
  U8 *bad_cpu_gap =
    "  if (scrncast.record)\n"
    "    TextPrint(Fs,44-4,0,BLUE<<4+RED,\"*\");\n\n"
    "  st=ScanCode2KeyName(kbd.last_down_scan_code);\n";
  U8 *fixed_cpu_gap =
    "  if (scrncast.record)\n"
    "    TextPrint(Fs,44-4,0,BLUE<<4+RED,\"*\");\n"
    "  for (i=0;i<mp_cnt;i++) {\n"
    "    c=&cpu_structs[i];\n"
    "    if (i&1)\n"
    "      TextPrint(Fs,44+i*2,0,BLUE<<4+WHITE,\"%2tf\",100.0*(1.0-c->idle_factor));\n"
    "    else\n"
    "      TextPrint(Fs,44+i*2,0,BLUE<<4+YELLOW,\"%2tf\",100.0*(1.0-c->idle_factor));\n"
    "  }\n\n"
    "  st=ScanCode2KeyName(kbd.last_down_scan_code);\n";

  if (buf) {
    if (RelicReplaceOnce(&buf, &size, bad_top, old_top))
      changed = TRUE;
    if (RelicReplaceOnce(&buf, &size,
          "  TextPrint(Fs,0,0,BLACK<<4+LTGRAY,wall->top_line);",
          "  TextPrint(Fs,0,0,BLUE<<4+WHITE,wall->top_line);"))
      changed = TRUE;
    if (RelicReplaceOnce(&buf, &size,
          "    TextPrint(Fs,44-4,0,BLACK<<4+LTRED,\"*\");",
          "    TextPrint(Fs,44-4,0,BLUE<<4+RED,\"*\");"))
      changed = TRUE;
    if (!StrFirstOcc(buf, cpu_loop))
      if (RelicReplaceOnce(&buf, &size, bad_cpu_gap, fixed_cpu_gap))
        changed = TRUE;
    if (RelicReplaceOnce(&buf, &size,
          "  TextPrint(Fs,80-18,0,BLACK<<4+YELLOW,\"%18ts\",st);",
          "  TextPrint(Fs,80-18,0,BLUE<<4+YELLOW,\"%18ts\",st);"))
      changed = TRUE;
    if (changed)
      FileWrite("::/Adam/WallPaper.HC.Z", buf, size);
    Free(buf);
  }
}
RepairWallPaper;

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
  RelicFileReplaceOnce("::/Kernel/KGlbls.HC.Z",
        "sys_os_version=5.030;", "sys_os_version=1.000;");
  RelicFileReplaceOnce("::/Kernel/KMain.HC.Z",
        "RelicOS  V%5.3f\\t%D %T\\n\\n",
        "RelicOS V1.0.0\\t%D %T\\n\\n");
  RelicFileReplaceOnce("::/Kernel/KMain.HC.Z",
        "TempleOS V%5.3f\\t%D %T\\n\\n",
        "RelicOS V1.0.0\\t%D %T\\n\\n");
  RelicFileReplaceOnce("::/Kernel/KEnd.HC.Z",
        "RelicOS  V%5.3f\\t%D %T\\n\\n",
        "RelicOS V1.0.0\\t%D %T\\n\\n");
  RelicFileReplaceOnce("::/Kernel/KEnd.HC.Z",
        "TempleOS V%5.3f\\t%D %T\\n\\n",
        "RelicOS V1.0.0\\t%D %T\\n\\n");
  RelicFileReplaceOnce("::/Adam/ADefine.HC.Z",
        "DefinePrint(\"DD_OS_NAME_VERSION\",\"TempleOS V%0.2f\",sys_os_version);",
        "DefinePrint(\"DD_OS_NAME_VERSION\",\"RelicOS V1.0.0\");");
  RelicFileReplaceOnce("::/Adam/ADefine.HC.Z",
        "DefinePrint(\"DD_OS_NAME_VERSION\",\"RelicOS  V%0.2f\",sys_os_version);",
        "DefinePrint(\"DD_OS_NAME_VERSION\",\"RelicOS V1.0.0\");");
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
Del("E:/RelicChrome.HC");
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
