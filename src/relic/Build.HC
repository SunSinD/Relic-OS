// Build.HC
// Automatically installs RelicOS to the system and generates a bootable ISO.

// The transfer disk can land on any hard-drive letter depending on how the
// running kernel was configured (C/D for a stock install, E..G after
// MountIDEAuto).  Probe them all for our own Build.HC.
U8 relic_src_drv = 0;
U8 relic_src_let;
U8 relic_src_probe[32];
for (relic_src_let = 'C'; relic_src_let <= 'L' && !relic_src_drv; relic_src_let++) {
  StrPrint(relic_src_probe, "%c:/Build.HC", relic_src_let);
  try {
    if (FileFind(relic_src_probe, , FUF_Z_OR_NOT_Z))
      relic_src_drv = relic_src_let;
  } catch
    Fs->catch_except = TRUE; // unmounted letter
}
if (!relic_src_drv) {
  relic_src_drv = 'E';
  "$FG,LTRED$Build.HC not found on C:..L:; assuming %c:$FG$\n", relic_src_drv;
}

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

// StrFirstOcc is a character-set search (like strpbrk), NOT a substring
// search.  We need a real substring finder for patching source files.
U8 *RelicStrStr(U8 *haystack, I64 hay_len, U8 *needle) {
  I64 needle_len = StrLen(needle);
  I64 i;
  if (needle_len > hay_len) return NULL;
  for (i = 0; i <= hay_len - needle_len; i++) {
    if (!MemCmp(haystack + i, needle, needle_len))
      return haystack + i;
  }
  return NULL;
}

"\n$FG,CYAN$==============================$FG$\n";
"  $FG,LTBLUE$RelicOS Release Builder$FG$\n";
"$FG,CYAN$==============================$FG$\n\n";

// Single source of truth for what ships in Home/RelicOS.  Used for the
// installed system AND for the ISO staging tree so the image never depends
// on stale files left on the build disk.
U0 RelicInstallSources(U8 *dst_dir) {
  DelTree(dst_dir);
  DirMk(dst_dir);
  RelicCopy("RelicBoot.HC", dst_dir);
  RelicCopy("RelicDesktop.HC", dst_dir);
  RelicCopy("RelicChrome.HC", dst_dir);
  RelicCopy("RelicTheme.HC", dst_dir);
  RelicCopy("RelicWallpaper.HC", dst_dir);
  RelicCopy("wallpaper.raw", dst_dir);
  RelicCopy("RunTOOM.HC", dst_dir);
  RelicCopy("GamesLauncher.HC", dst_dir);
  RelicCopy("RelicInstall.HC", dst_dir);
  RelicCopy("RelicStartUp.HC", dst_dir);
  RelicCopy("RelicDisplay.HC", dst_dir);
}

"1. Installing RelicOS to ::/Home/RelicOS/...\n";
RelicInstallSources("::/Home/RelicOS");

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
  Drv(':');
  Cd("::/Home");
  if (FileFind("::/Home/TOOM/SinglePlayer.HC") ||
      FileFind("::/Home/TOOM/SinglePlayer.HC.Z"))
    toom_installed = TRUE;
  Del("::/Home/RelicOS/TOOM.ISO.C");
}
if (!toom_installed) {
  "$FG,LTRED$WARNING: TOOM source was not found on %c:/TOOM.$FG$\n", relic_src_drv;
}

"Installing DOOM IWAD (required for TOOM)...\n";
if (RelicFileFind("TOOM/doom1.wad"))
  RelicCopy("TOOM/doom1.wad", "::/Home/TOOM");
else if (RelicFileFind("TOOM/DOOM1.WAD"))
  RelicCopy("TOOM/DOOM1.WAD", "::/Home/TOOM");
else if (RelicFileFind("TOOM/freedoom1.wad"))
  RelicCopy("TOOM/freedoom1.wad", "::/Home/TOOM");
else if (RelicFileFind("TOOM/FREEDOOM1.WAD"))
  RelicCopy("TOOM/FREEDOOM1.WAD", "::/Home/TOOM");
else if (RelicFileFind("doom1.wad"))
  RelicCopy("doom1.wad", "::/Home/TOOM");
else if (RelicFileFind("freedoom1.wad"))
  RelicCopy("freedoom1.wad", "::/Home/TOOM");
else if (FileFind("::/Home/TOOM/doom1.wad") ||
      FileFind("::/Home/TOOM/freedoom1.wad"))
  "  IWAD already present in ::/Home/TOOM.\n";
else
  "$FG,LTRED$WARNING: No doom1.wad or freedoom1.wad found!$FG$\n"
  "  Copy doom1.wad into src/relic/TOOM/ on the host and run\n"
  "  tools\\relic.ps1 iso again. DOOM cannot start without a WAD.\n";

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
      if (!MemCmp(buf + i, "TempleOS V5.03", 14)) MemCpy(buf + i, "RelicOS V0.4.0", 14);
    }
    for (i = 0; i < size - 8; i++) {
      // Keep "AboutTempleOS": it names a real file (::/Doc/AboutTempleOS.DD.Z,
      // opened by Shift+F1).
      if (!MemCmp(buf + i, "TempleOS", 8) &&
            !(i >= 5 && !MemCmp(buf + i - 5, "About", 5)))
        MemCpy(buf + i, "RelicOS ", 8);
    }
    FileWrite(filename, buf, size);
    Free(buf);
  }
}

// Never rebrand ::/Kernel.BIN.C or ::/0000Boot/* on THIS drive: the boot
// sectors load them by raw disk position, and FileWrite may move a file to
// new clusters, which left the build machine unbootable.  Branding is done
// on the /Distro copies only (RelicBrandDistro, below).

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
    U8 *marker = RelicStrStr(buf, size, "RelicBootPalette;");
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
    U8 *start = RelicStrStr(buf, size, "gr_palette_std");
    if (start) {
      U8 *array_start = StrFirstOcc(start, "{");
      U8 *array_end = StrFirstOcc(start, "}");
      if (array_start && array_end && array_end > array_start) {
        U8 *new_vals = 
          "{\n"
          "  0x000000000000, 0x000000000000, 0x200052002400, 0x00009000B800,\n"
          "  0xB80008000800, 0x600015007000, 0xA00052001000, 0x780078007400,\n"
          "  0x380038003A00, 0x300048009000, 0x380090004800, 0x100030003500,\n"
          "  0xFFFF38382828, 0xBBBB5000CCCC, 0xFFFFC8002800, 0xD000D000D000\n"
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
  U8 *hit = RelicStrStr(buf, *size_ptr, old_text);
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

U0 ReplaceBrandingRecursive(U8 *filespec) {
  // FUF_JUST_FILES flattens the tree; without it only the top folder is
  // visited.  DirTreeDel frees every node (DirEntryDel frees one).
  CDirEntry *de = FilesFind(filespec, FUF_RECURSE | FUF_JUST_FILES), *tmp_de = de;
  while (tmp_de) {
    ReplaceBranding(tmp_de->full_name);
    tmp_de = tmp_de->next;
  }
  DirTreeDel(de);
}

// Kernel source patches.  These are applied to the sources the DVD kernel
// is compiled from, so the live CD is dark and branded from the very first
// kernel message.  Each replacement is idempotent (no-op when already done).
U0 PatchDarkKernel(U8 *filename) {
  // TaskInit default: every new task starts light-grey-on-black.
  RelicFileReplaceOnce(filename, "WHITE<<4+BLUE", "BLACK<<4+LTGRAY");
  // Older/alternate spellings kept for safety.
  RelicFileReplaceOnce(filename, "WHITE<<4|BLUE", "BLACK<<4|LTGRAY");
  RelicFileReplaceOnce(filename, "WHITE<<4|LTGRAY", "BLACK<<4|LTGRAY");
}

U0 PatchKernelBanner(U8 *filename) {
  // First line the kernel prints (KMain.HC).  Keep the argument count the
  // same so the Print() call stays valid.
  RelicFileReplaceOnce(filename,
        "\"TempleOS V%5.3f\\t%D %T\\n\\n\",",
        "\"RelicOS V0.4.0 (core %5.3f)\\t%D %T\\n\\n\",");
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

// The boot script lives in src/relic/HomeSys.HC (also synced by the dev
// loop).  It is installed as ~/HomeSys.HC.Z here and in the ISO staging tree.
U8 *clean_homesys = RelicFileRead("HomeSys.HC");
if (!clean_homesys) {
  "$FG,LTRED$HomeSys.HC missing on %c:. Re-run the host prepare step.$FG$\n",
        relic_src_drv;
  throw('NoHome');
}
FileWrite("::/Home/HomeSys.HC.Z", clean_homesys, StrLen(clean_homesys));

"3. Preparing ISO tooling...\n";
#define KERNEL_BIN_C "Kernel.BIN.C"
#define BOOT_DIR "/0000Boot"
#define BOOT_DIR_KERNEL_BIN_C BOOT_DIR "/0000" KERNEL_BIN_C

// Load the DVD boot-loader, RedSea ISO writer and BootDVDIns if the running
// Adam does not already have them (stock MakeBoot includes all three).
U0 RelicLoadISOHelpers()
{
  Cd("::/Adam/Opt/Boot");
  if (!HashFind("BDVD_START", Fs->hash_table, HTG_SRC_SYM))
    ExeFile("BootDVD.HC.Z", CCF_JUST_LOAD);
  if (!HashFind("RedSeaISO", Fs->hash_table, HTG_SRC_SYM))
    ExeFile("DskISORedSea.HC.Z", CCF_JUST_LOAD);
  if (!HashFind("BootDVDIns", Fs->hash_table, HTG_SRC_SYM))
    ExeFile("BootDVDIns.HC.Z", CCF_JUST_LOAD);
  Cd("::/");
}
RelicLoadISOHelpers;

// Answers for the kernel-config prompts when compiling the live-CD kernel
// (same string stock ::/Misc/DoDistro.HC uses):
//   Boot drive T (the CD), RAM drive B sized to memory, CD drive T = the
//   booted CD/DVD, default disk cache, no extra options.
#define RELIC_DISTRO_DVD_CFG "TB\nScale2Mem(2048,0x40000)\nT \n\n\n\n"

// Rebrand the 16-bit DVD boot-loader image in memory before RedSeaISO
// copies it into the ISO boot sector ("Loading TempleOS" -> "Loading RelicOS").
U0 RelicBrandBootLoader()
{
  U8 *p = BDVD_START;
  I64 n = BDVD_END - BDVD_START, i;
  for (i = 0; i + 14 <= n; i++) {
    if (!MemCmp(p + i, "TempleOS V5.03", 14)) MemCpy(p + i, "RelicOS V0.4.0", 14);
  }
  for (i = 0; i + 8 <= n; i++) {
    if (!MemCmp(p + i, "TempleOS", 8)) MemCpy(p + i, "RelicOS ", 8);
  }
}

// Patch the kernel sources on the system drive, then compile a fresh
// live-CD (DVD-config) kernel into /0000Boot/0000Kernel.BIN.C.  Previously
// the ISO reused whatever kernel the ORIGINAL TempleOS installer had copied
// there, i.e. a stock kernel.  Returns FALSE if the compile failed.
Bool RelicBuildDVDKernel()
{
  PatchDarkKernel("::/Kernel/KTask.HC.Z");
  PatchDarkKernel("::/Kernel/KernelA.HH.Z");
  PatchDarkKernel("::/Kernel/KStart64.HC.Z");
  PatchDarkKernel("::/Kernel/KMain.HC.Z");
  PatchKernelBanner("::/Kernel/KMain.HC.Z");

  "  Compiling live-CD kernel (takes a moment)...\n";
  Del(BOOT_DIR_KERNEL_BIN_C);
  In(RELIC_DISTRO_DVD_CFG);
  BootDVDIns;
  if (!FileFind(BOOT_DIR_KERNEL_BIN_C)) {
    "$FG,LTRED$Kernel compile failed: %s was not produced.$FG$\n",
          BOOT_DIR_KERNEL_BIN_C;
    return FALSE;
  }
  return TRUE;
}

U8 *relic_once_stub =
  "// RelicOS: the live-CD install offer is handled by\n"
  "// ::/Home/RelicOS/RelicInstall.HC (see RelicBoot.HC).\n";

// Make the staging tree independent of what happens to be on the build
// disk: Relic sources straight from the transfer drive, the generated
// HomeSys in BOTH places the boot path can resolve ~/HomeSys from, and a
// stub Once so the stock "Install onto hard drive?" terminal never appears.
U0 RelicStageHome()
{
  Del("/Distro/Home/RelicDev.TXT");
  Del("/Distro/Home/Boot.LOG");
  Del("/Distro/Home/RelicNoSVGA.TXT");
  // Game settings and high scores from the build machine; games recreate
  // their defaults with RegDft on first run.
  Del("/Distro/Home/Registry.HC.Z");
  // RunTOOM picks doom1.wad first; do not ship the unused 28 MB Freedoom.
  if (FileFind("/Distro/Home/TOOM/doom1.wad"))
    Del("/Distro/Home/TOOM/freedoom1.wad");
  RelicInstallSources("/Distro/Home/RelicOS");
  FileWrite("/Distro/Home/HomeSys.HC.Z", clean_homesys, StrLen(clean_homesys));
  FileWrite("/Distro/HomeSys.HC.Z", clean_homesys, StrLen(clean_homesys));
  FileWrite("/Distro/Home/Once.HC.Z", relic_once_stub, StrLen(relic_once_stub));
  FileWrite("/Distro/Once.HC.Z", relic_once_stub, StrLen(relic_once_stub));
}

// If the packed kernel looks for "RelicOS  RedSea", rewrite the volume
// descriptors (CD sectors 16 and 18) to that same 15-byte cookie.
U0 RelicSyncISOPublisher(U8 *filename)
{
  I64 size, i, n;
  U8 *buf = NULL;

  if (!FileFind(filename))
    return;
  buf = FileRead(filename, &size);
  if (!buf)
    return;
  n = size;
  if (n > 0x100000)
    n = 0x100000;
  if (!RelicStrStr(buf, n, "RelicOS  RedSea")) {
    Free(buf);
    return;
  }
  n = size;
  if (n > 0xA000)
    n = 0xA000;
  for (i = 0x8000; i + 15 <= n; i++) {
    if (!MemCmp(buf + i, "TempleOS RedSea", 15))
      MemCpy(buf + i, "RelicOS  RedSea", 15);
  }
  FileWrite(filename, buf, size);
  Free(buf);
  "  ISO publisher synced to the live-CD kernel (RelicOS RedSea).\n";
}

Bool RelicMakeISO(U8 *_out_iso_filename)
{
  U8 *out_iso_filename = FileNameAbs(_out_iso_filename);

  Drv(':');
  Cd("/");
  if (!DrvIsWritable) {
    "$FG,LTRED$The system drive must be writable before building the ISO.$FG$\n";
    Free(out_iso_filename);
    return FALSE;
  }
  if (!FileFind("/Kernel/Kernel.PRJ") && !FileFind("/Kernel/Kernel.PRJ.Z")) {
    "$FG,LTRED$Missing /Kernel sources on the system drive. Build from an installed RelicOS/TempleOS disk.$FG$\n";
    Free(out_iso_filename);
    return FALSE;
  }

  DelTree("/Distro");
  Del(out_iso_filename);
  DirMk("/Distro");

  if (!RelicBuildDVDKernel) {
    Free(out_iso_filename);
    return FALSE;
  }
  RelicBrandBootLoader;

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

  RelicStageHome;

  // Rebrand the system sources the live CD installer recompiles from
  // (kernel, Adam incl. the boot loader, compiler, Misc).  Not Home (the
  // Relic Help page names TempleOS on purpose), not Demo/Apps (games use
  // "TempleOS/..." registry keys, which would get a space in them).
  ReplaceBrandingRecursive("::/Distro/Kernel/*.HC*;*.HH*");
  ReplaceBrandingRecursive("::/Distro/Adam/*.HC*;*.HH*");
  ReplaceBrandingRecursive("::/Distro/Compiler/*.HC*;*.HH*");
  ReplaceBrandingRecursive("::/Distro/Misc/*.HC*");
  // Boot files and kernel of the ISO itself (copies, never the originals).
  ReplaceBrandingRecursive("::/Distro/0000Boot/*");
  ReplaceBranding("::/Distro/StartOS.HC.Z");

  RedSeaISO(out_iso_filename, "/Distro", "/Distro" BOOT_DIR_KERNEL_BIN_C);
  // Branding rewrites the kernel cookie "TempleOS RedSea" into
  // "RelicOS  RedSea", but RedSeaISO still stamps the original cookie into
  // the ISO9660 publisher field.  ISOInit mounts RedSea only when those
  // two strings match; otherwise the CD stays ISO9660 and Drv() reports
  // "File System Not Supported".
  RelicSyncISOPublisher(out_iso_filename);
  Free(out_iso_filename);
  return TRUE;
}

// Split the ISO into 2MB pieces on the (FAT32) transfer drive so the host
// can reassemble it (tools\relic.ps1 extract).
U0 RelicWriteChunks(U8 *iso_filename)
{
  I64 size, chunk_sz = 1024 * 1024 * 2, chunks, i, write_sz;
  U8 name[256];
  U8 *buf = NULL;

  // Drop the manifest and chunks of an earlier build first, so a shorter or
  // interrupted build can never leave stale pieces behind.
  StrPrint(name, "%c:/ISO.SIZE", relic_src_drv);
  Del(name);
  StrPrint(name, "%c:/ISO.P*", relic_src_drv);
  Del(name);

  if (FileFind(iso_filename))
    buf = FileRead(iso_filename, &size);
  if (!buf) {
    "$FG,LTRED$ISO build failed before %s was created.$FG$\n", iso_filename;
    return;
  }
  chunks = (size + chunk_sz - 1) / chunk_sz;
  for (i = 0; i < chunks; i++) {
    StrPrint(name, "%c:/ISO.P%02d", relic_src_drv, i);
    write_sz = chunk_sz;
    if (i == chunks - 1)
      write_sz = size - i * chunk_sz;
    "  Writing %s...\n", name;
    if (!FileWrite(name, buf + i * chunk_sz, write_sz)) {
      "$FG,LTRED$Could not write %s (transfer disk full?).$FG$\n", name;
      Free(buf);
      return;
    }
  }
  // The manifest goes last: the host only trusts chunks once it exists.
  StrPrint(name, "%c:/ISO.SIZE", relic_src_drv);
  StrPrint(name + 64, "%d\n", size);
  FileWrite(name, name + 64, StrLen(name + 64));
  Free(buf);
  "  ISO size: %d bytes in %d chunk(s).\n", size, chunks;
}

"4. Building bootable ISO (This will take a moment)...\n";
Bool relic_iso_ok = RelicMakeISO("::/Tmp/RelicOS.ISO.C");

"5. Writing ISO chunks to transfer drive...\n";
if (relic_iso_ok)
  RelicWriteChunks("::/Tmp/RelicOS.ISO.C");
else {
  "$FG,LTRED$Skipped: ISO was not built.$FG$\n";
  // Tell the host right away instead of letting it wait for its timeout.
  StrPrint(relic_src_probe, "%c:/ISO.SIZE", relic_src_drv);
  FileWrite(relic_src_probe, "FAILED\n", 7);
}

"\n$FG,CYAN$========================$FG$\n";
if (relic_iso_ok)
  "  $FG,LTGREEN$Done. ISO chunks ready.$FG$\n";
else
  "  $FG,LTRED$Build failed, see the messages above.$FG$\n";
"  $FG,LTGRAY$Shut down the VM.$FG$\n";
"$FG,CYAN$========================$FG$\n";
