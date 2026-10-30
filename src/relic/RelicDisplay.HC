// RelicDisplay.HC - fast display output on virtual machines.
//
// TempleOS draws 640x480 in 16 colours through planar VGA.  Virtual
// machines emulate planar VGA by trapping every video-memory write: in
// VMware one full-screen update measured 270 ms, so anything that moves
// (DOOM, demo games, scrolling) ran at 4-10 fps.  This module finds a
// linear-framebuffer display device instead and, once it is up, the
// WinMgr's final screen hook copies gr.dc2 (one byte per pixel, colour in
// the low nibble) into it as 32-bit pixels and the slow VGA writer is
// switched off.
//
// Backends (tried in this order):
//   1 VMware SVGA II (PCI 15AD:0405): VMware, VirtualBox "VBoxSVGA",
//     QEMU -vga vmware.  Updates go through the command FIFO.
//   2 Bochs VBE / DISPI (ports 0x1CE/0x1CF): QEMU -vga std, Bochs,
//     VirtualBox "VBoxVGA".  Plain framebuffer, no update commands.
// Real hardware keeps plain VGA (real VGA memory is not trapped).
//
// Stays on VGA when no device is found, when any step fails, or when
// ::/Home/RelicNoSVGA.TXT exists.  RelicDisplayOff or Ctrl+Alt+V returns to
// plain VGA, and so does any raw-mode output (crash/debugger screens).

#define DISP_NONE   0
#define DISP_VMWARE 1
#define DISP_BOCHS  2

#define SVGA_PCI_ID          0x040515AD
#define SVGA_ID_2            0x90000002
#define SVGA_REG_ID          0
#define SVGA_REG_ENABLE      1
#define SVGA_REG_WIDTH       2
#define SVGA_REG_HEIGHT      3
#define SVGA_REG_BPP         7
#define SVGA_REG_PITCH       12
#define SVGA_REG_FB_START    13
#define SVGA_REG_FB_OFFSET   14
#define SVGA_REG_MEM_START   18
#define SVGA_REG_MEM_SIZE    19
#define SVGA_REG_CONFIG_DONE 20
#define SVGA_REG_SYNC        21
#define SVGA_REG_BUSY        22
#define SVGA_FIFO_MIN        0
#define SVGA_FIFO_MAX        1
#define SVGA_FIFO_NEXT_CMD   2
#define SVGA_FIFO_STOP       3
#define SVGA_CMD_UPDATE      1

#define VBE_PORT_INDEX  0x1CE
#define VBE_PORT_DATA   0x1CF
#define VBE_REG_ID      0
#define VBE_REG_XRES    1
#define VBE_REG_YRES    2
#define VBE_REG_BPP     3
#define VBE_REG_ENABLE  4
#define VBE_REG_VIRT_W  6
#define VBE_REG_VIRT_H  7
#define VBE_REG_X_OFF   8
#define VBE_REG_Y_OFF   9
#define VBE_ENABLED     0x01
#define VBE_LFB         0x40
#define VBE_PCI_QEMU    0x11111234 // QEMU/Bochs stdvga
#define VBE_PCI_VBOX    0xBEEF80EE // VirtualBox VBoxVGA

I64 relic_disp_kind = DISP_NONE;
Bool relic_disp_on = FALSE;
U8 *relic_disp_fb = NULL;
I64 relic_disp_pitch = 0;
U8 *relic_disp_cache = NULL;  // last frame sent, GR_WIDTH*GR_HEIGHT bytes
U32 relic_disp_lut[COLORS_NUM];
CBGR48 relic_disp_pal[COLORS_NUM]; // last palette seen, to restore VGA
I64 relic_disp_frames = 0;
U8 relic_disp_vga_byte = 0;   // first byte of GrUpdateVGAGraphics
U8 relic_disp_blot4[3];       // first 3 bytes of DCBlotColor4
U0 (*relic_disp_old_final)(CDC *dc) = NULL;
I64 relic_svga_io = 0;
U32 *relic_svga_fifo = NULL;

// ---- VMware SVGA II ----
U32 RelicSVGARead(I64 index)
{
  OutU32(relic_svga_io, index);
  return InU32(relic_svga_io + 1);
}

U0 RelicSVGAWrite(I64 index, I64 val)
{
  OutU32(relic_svga_io, index);
  OutU32(relic_svga_io + 1, val);
}

U0 RelicSVGAFifoPut(U32 val)
{
  U32 *f = relic_svga_fifo;
  I64 next = f[SVGA_FIFO_NEXT_CMD], guard = 0;

  // Full: let the host drain it (bounded so the WinMgr can never hang).
  while ((next + 4 == f[SVGA_FIFO_STOP] ||
        (next + 4 == f[SVGA_FIFO_MAX] && f[SVGA_FIFO_STOP] == f[SVGA_FIFO_MIN]))
        && guard++ < 100000) {
    RelicSVGAWrite(SVGA_REG_SYNC, 1);
    RelicSVGARead(SVGA_REG_BUSY);
  }
  *((f(U8 *) + next)(U32 *)) = val;
  next += 4;
  if (next == f[SVGA_FIFO_MAX])
    next = f[SVGA_FIFO_MIN];
  f[SVGA_FIFO_NEXT_CMD] = next;
}

U0 RelicSVGAUpdate(I64 x, I64 y, I64 w, I64 h)
{
  RelicSVGAFifoPut(SVGA_CMD_UPDATE);
  RelicSVGAFifoPut(x);
  RelicSVGAFifoPut(y);
  RelicSVGAFifoPut(w);
  RelicSVGAFifoPut(h);
  RelicSVGAWrite(SVGA_REG_SYNC, 1);
}

// PCI slot of the first device with this vendor/device id, or -1.
I64 RelicPCIFind(U32 id, I64 *_bus)
{
  I64 b, d;
  for (b = 0; b < 4; b++)
    for (d = 0; d < 32; d++)
      if (PCIReadU32(b, d, 0, 0) == id) {
        *_bus = b;
        return d;
      }
  return -1;
}

Bool RelicSVGAStart()
{
  I64 bus, slot, fb_phys, fifo_phys, fifo_size;
  U32 *f;

  slot = RelicPCIFind(SVGA_PCI_ID, &bus);
  if (slot < 0)
    return FALSE;
  relic_svga_io = PCIReadU32(bus, slot, 0, 0x10) & ~3;
  RelicSVGAWrite(SVGA_REG_ID, SVGA_ID_2);
  if (RelicSVGARead(SVGA_REG_ID) != SVGA_ID_2)
    return FALSE;
  fb_phys = RelicSVGARead(SVGA_REG_FB_START);
  fifo_phys = RelicSVGARead(SVGA_REG_MEM_START);
  fifo_size = RelicSVGARead(SVGA_REG_MEM_SIZE);
  // Both must lie inside TempleOS's identity-mapped physical range.
  if (!fb_phys || !fifo_phys || fifo_size < 4096 ||
        fb_phys + 0x400000 > mem_mapped_space ||
        fifo_phys + fifo_size > mem_mapped_space)
    return FALSE;

  RelicSVGAWrite(SVGA_REG_WIDTH, GR_WIDTH);
  RelicSVGAWrite(SVGA_REG_HEIGHT, GR_HEIGHT);
  RelicSVGAWrite(SVGA_REG_BPP, 32);
  RelicSVGAWrite(SVGA_REG_ENABLE, 1);
  relic_disp_pitch = RelicSVGARead(SVGA_REG_PITCH);
  relic_disp_fb = (fb_phys + RelicSVGARead(SVGA_REG_FB_OFFSET))(U8 *);
  if (relic_disp_pitch < GR_WIDTH * 4) {
    RelicSVGAWrite(SVGA_REG_ENABLE, 0);
    return FALSE;
  }

  f = fifo_phys(U32 *);
  f[SVGA_FIFO_MIN] = 16;
  f[SVGA_FIFO_MAX] = fifo_size;
  f[SVGA_FIFO_NEXT_CMD] = 16;
  f[SVGA_FIFO_STOP] = 16;
  relic_svga_fifo = f;
  RelicSVGAWrite(SVGA_REG_CONFIG_DONE, 1);
  relic_disp_kind = DISP_VMWARE;
  return TRUE;
}

// Leaving DISPI mode does not bring QEMU's planar VGA back by itself:
// reprogram standard mode 12h (640x480x16) with the identity attribute
// palette TempleOS uses, and the last DAC colours.  Port writes only (no
// semaphores), so it is safe inside the Ctrl+Alt+V keyboard IRQ.
U8 relic_vga12_seq[5] = {0x03, 0x01, 0x0F, 0x00, 0x06};
U8 relic_vga12_crtc[25] = {
  0x5F, 0x4F, 0x50, 0x82, 0x54, 0x80, 0x0B, 0x3E, 0x00, 0x40, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xEA, 0x0C, 0xDF, 0x28, 0x00, 0xE7, 0x04, 0xE3,
  0xFF};
U8 relic_vga12_gc[9] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x0F, 0xFF};

U0 RelicVGAMode12()
{
  I64 i;

  OutU8(VGAP_MISC_OUTPUT, 0xE3);
  for (i = 0; i < 5; i++) {
    OutU8(VGAP_IDX, i);
    OutU8(VGAP_DATA, relic_vga12_seq[i]);
  }
  OutU8(VGAP_CRTC_INDEX, 0x11); // unlock CRTC 0-7
  OutU8(VGAP_CRTC_DATA, relic_vga12_crtc[0x11] & 0x7F);
  for (i = 0; i < 25; i++) {
    OutU8(VGAP_CRTC_INDEX, i);
    OutU8(VGAP_CRTC_DATA, relic_vga12_crtc[i]);
  }
  for (i = 0; i < 9; i++) {
    OutU8(0x3CE, i);
    OutU8(0x3CF, relic_vga12_gc[i]);
  }
  InU8(VGAP_INPUT_STAT); // reset the attribute flip-flop
  for (i = 0; i < COLORS_NUM; i++) {
    OutU8(VGAP_ATTR_INDEX, i);
    OutU8(VGAP_ATTR_DATA_WRITE, i);
  }
  OutU8(VGAP_ATTR_INDEX, 0x10); OutU8(VGAP_ATTR_DATA_WRITE, 0x01);
  OutU8(VGAP_ATTR_INDEX, 0x11); OutU8(VGAP_ATTR_DATA_WRITE, 0x00);
  OutU8(VGAP_ATTR_INDEX, 0x12); OutU8(VGAP_ATTR_DATA_WRITE, 0x0F);
  OutU8(VGAP_ATTR_INDEX, 0x13); OutU8(VGAP_ATTR_DATA_WRITE, 0x00);
  OutU8(VGAP_ATTR_INDEX, 0x14); OutU8(VGAP_ATTR_DATA_WRITE, 0x00);
  OutU8(VGAP_ATTR_INDEX, 0x20); // video on
  InU8(VGAP_INPUT_STAT);
  OutU8(VGAP_PALETTE_MASK, 0xFF);
  for (i = 0; i < COLORS_NUM; i++) {
    OutU8(VGAP_REG_WRITE, i);
    OutU8(VGAP_PALETTE_DATA, relic_disp_pal[i].r >> 10);
    OutU8(VGAP_PALETTE_DATA, relic_disp_pal[i].g >> 10);
    OutU8(VGAP_PALETTE_DATA, relic_disp_pal[i].b >> 10);
  }
}

// ---- Bochs VBE (DISPI) ----
U16 RelicVBERead(I64 index)
{
  OutU16(VBE_PORT_INDEX, index);
  return InU16(VBE_PORT_DATA);
}

U0 RelicVBEWrite(I64 index, I64 val)
{
  OutU16(VBE_PORT_INDEX, index);
  OutU16(VBE_PORT_DATA, val);
}

Bool RelicVBEStart()
{
  I64 bus, slot, id, fb_phys;

  slot = RelicPCIFind(VBE_PCI_QEMU, &bus);
  if (slot < 0)
    slot = RelicPCIFind(VBE_PCI_VBOX, &bus);
  if (slot < 0)
    return FALSE;
  id = RelicVBERead(VBE_REG_ID);
  if (id < 0xB0C2 || id > 0xB0CF) // 32 bpp needs DISPI version 2+
    return FALSE;
  fb_phys = PCIReadU32(bus, slot, 0, 0x10) & ~0xF;
  if (!fb_phys || fb_phys + 0x400000 > mem_mapped_space)
    return FALSE;

  RelicVBEWrite(VBE_REG_ENABLE, 0);
  RelicVBEWrite(VBE_REG_XRES, GR_WIDTH);
  RelicVBEWrite(VBE_REG_YRES, GR_HEIGHT);
  RelicVBEWrite(VBE_REG_BPP, 32);
  RelicVBEWrite(VBE_REG_VIRT_W, GR_WIDTH);
  RelicVBEWrite(VBE_REG_VIRT_H, GR_HEIGHT);
  RelicVBEWrite(VBE_REG_X_OFF, 0);
  RelicVBEWrite(VBE_REG_Y_OFF, 0);
  RelicVBEWrite(VBE_REG_ENABLE, VBE_ENABLED | VBE_LFB);
  if (RelicVBERead(VBE_REG_XRES) != GR_WIDTH ||
        RelicVBERead(VBE_REG_BPP) != 32) {
    RelicVBEWrite(VBE_REG_ENABLE, 0);
    RelicVGAMode12;
    return FALSE;
  }
  relic_disp_fb = fb_phys(U8 *);
  relic_disp_pitch = GR_WIDTH * 4;
  relic_disp_kind = DISP_BOCHS;
  return TRUE;
}

// ---- Common ----

// TRUE when the 16-colour palette changed since the last call.
Bool RelicDisplayPaletteSync()
{
  CBGR48 pal[COLORS_NUM];
  I64 i;
  U32 c;
  Bool changed = FALSE;

  GrPaletteGet(pal);
  MemCpy(relic_disp_pal, pal, sizeof(pal));
  for (i = 0; i < COLORS_NUM; i++) {
    c = ((pal[i].r >> 8) << 16) | ((pal[i].g >> 8) << 8) | (pal[i].b >> 8);
    if (c != relic_disp_lut[i]) {
      relic_disp_lut[i] = c;
      changed = TRUE;
    }
  }
  return changed;
}

// Copy the changed 8-pixel blocks of gr.dc2 into the framebuffer.
U0 RelicDisplayCopy()
{
  I64 x, y, miny = GR_HEIGHT, maxy = -1;
  U64 *src, *old;
  U8 *s8;
  U32 *dst;

  for (y = 0; y < GR_HEIGHT; y++) {
    src = (gr.dc2->body + y * gr.dc2->width_internal)(U64 *);
    old = (relic_disp_cache + y * GR_WIDTH)(U64 *);
    for (x = 0; x < GR_WIDTH / 8; x++) {
      if (src[x] != old[x]) {
        old[x] = src[x];
        s8 = (&src[x])(U8 *);
        dst = (relic_disp_fb + y * relic_disp_pitch + x * 32)(U32 *);
        dst[0] = relic_disp_lut[s8[0] & 15];
        dst[1] = relic_disp_lut[s8[1] & 15];
        dst[2] = relic_disp_lut[s8[2] & 15];
        dst[3] = relic_disp_lut[s8[3] & 15];
        dst[4] = relic_disp_lut[s8[4] & 15];
        dst[5] = relic_disp_lut[s8[5] & 15];
        dst[6] = relic_disp_lut[s8[6] & 15];
        dst[7] = relic_disp_lut[s8[7] & 15];
        if (y < miny)
          miny = y;
        maxy = y;
      }
    }
  }
  if (maxy >= miny && relic_disp_kind == DISP_VMWARE)
    RelicSVGAUpdate(0, miny, GR_WIDTH, maxy - miny + 1);
}

// Installed as gr.fp_final_scrn_update: runs on the WinMgr every frame,
// after the whole screen is composed in gr.dc2.
U0 RelicDisplayFinal(CDC *dc)
{
  if (relic_disp_old_final)
    (*relic_disp_old_final)(dc); // mouse cursor
  if (!relic_disp_on)
    return;
  if (!(relic_disp_frames++ & 7) && RelicDisplayPaletteSync)
    MemSet(relic_disp_cache, 0xFF, GR_WIDTH * GR_HEIGHT);
  RelicDisplayCopy;
}

U0 RelicDisplayOff()
{
  if (!relic_disp_on)
    return;
  relic_disp_on = FALSE;
  PUSHFD
  CLI // no task switch while the routine is half restored
  MemCpy((&DCBlotColor4)(U8 *), relic_disp_blot4, 3);
  POPFD
  // Its change cache is stale now: force the next frame to rebuild dc1.
  MemSet(gr.dc_cache->body, 0xFF, gr.dc2->width_internal * gr.dc2->height);
  *((&GrUpdateVGAGraphics)(U8 *)) = relic_disp_vga_byte;
  gr.fp_final_scrn_update = relic_disp_old_final;
  if (relic_disp_kind == DISP_VMWARE)
    RelicSVGAWrite(SVGA_REG_ENABLE, 0);
  else if (relic_disp_kind == DISP_BOCHS) {
    RelicVBEWrite(VBE_REG_ENABLE, 0);
    RelicVGAMode12;
  }
  VGAFlush;
}

// Ctrl+Alt+V (runs inside the keyboard IRQ, so it also works in the kernel
// debugger): leave the fast display and show plain VGA, where crash and
// debugger text is drawn.  Without a fast display it is the stock flush.
U0 RelicCtrlAltV(I64 sc)
{
  no_warn sc;
  if (relic_disp_on)
    RelicDisplayOff;
  else
    VGAFlush;
}

// Crash screens: Fault2/Panic print the debugger in raw mode straight into
// VGA memory with interrupts off, so not even Ctrl+Alt+V gets through.  This
// stdout hook sits just before the raw printer (KeyDev priority 0x60000000)
// and drops back to VGA the moment anything prints in raw mode, so the
// debugger text shows up by itself.  Normal RelicOS output is never raw.
Bool relic_disp_raw_hooked = FALSE;

Bool RelicRawPutKey(I64 ch, I64 sc)
{
  no_warn ch;
  no_warn sc;
  if (relic_disp_on && IsRaw)
    RelicDisplayOff;
  return FALSE; // let the raw printer draw it
}

Bool RelicRawPutS(U8 *st)
{
  no_warn st;
  if (relic_disp_on && IsRaw)
    RelicDisplayOff;
  return FALSE;
}

// Returns the backend in use (DISP_NONE = plain VGA).
F64 relic_disp_vga_ms = 0, relic_disp_fb_ms = 0; // measured at init

I64 RelicDisplayInit()
{
  F64 t0;
  if (relic_disp_on)
    return relic_disp_kind;
  if (FileFind("::/Home/RelicNoSVGA.TXT"))
    return DISP_NONE;
  relic_disp_kind = DISP_NONE;

  // Time one full-screen update the stock VGA way (planes + VGA writes).
  t0 = tS;
  MemSet(gr.dc_cache->body, 0xFF, gr.dc2->width_internal * gr.dc2->height);
  DCBlotColor4(gr.dc1->body, gr.dc2->body, gr.dc_cache->body,
        gr.dc2->height * gr.dc2->width_internal >> 3);
  LBts(&sys_semas[SEMA_FLUSH_VGA_IMAGE], 0);
  GrUpdateVGAGraphics;
  relic_disp_vga_ms = (tS - t0) * 1000.0;

  if (!RelicSVGAStart && !RelicVBEStart)
    return DISP_NONE;

  if (!relic_disp_cache)
    relic_disp_cache = MAlloc(GR_WIDTH * GR_HEIGHT);
  MemSet(relic_disp_lut, 0xFF, sizeof(relic_disp_lut));
  RelicDisplayPaletteSync;

  // ...and the same full screen through the framebuffer.  Keep whichever is
  // faster: a framebuffer is not always the quicker path (QEMU without
  // hardware acceleration emulates every instruction, so plain VGA wins).
  MemSet(relic_disp_cache, 0xFF, GR_WIDTH * GR_HEIGHT);
  t0 = tS;
  RelicDisplayCopy;
  relic_disp_fb_ms = (tS - t0) * 1000.0;
  if (relic_disp_fb_ms >= relic_disp_vga_ms) {
    if (relic_disp_kind == DISP_VMWARE)
      RelicSVGAWrite(SVGA_REG_ENABLE, 0);
    else {
      RelicVBEWrite(VBE_REG_ENABLE, 0);
      RelicVGAMode12;
    }
    VGAFlush;
    relic_disp_kind = DISP_NONE;
    return DISP_NONE;
  }

  // Hand the screen over: new output hook first, then mute the VGA writer.
  relic_disp_old_final = gr.fp_final_scrn_update;
  relic_disp_on = TRUE;
  gr.fp_final_scrn_update = &RelicDisplayFinal;
  relic_disp_vga_byte = *((&GrUpdateVGAGraphics)(U8 *));
  *((&GrUpdateVGAGraphics)(U8 *)) = 0xC3; // RET
  // DCBlotColor4 only prepares VGA planes; skip it too.  It is asm ending in
  // RET1 32 (pops its 4 arguments), so the patch is RET 0x20 (C2 20 00).
  MemCpy(relic_disp_blot4, (&DCBlotColor4)(U8 *), 3);
  PUSHFD
  CLI // no task switch while the routine is half patched
  *((&DCBlotColor4)(U8 *)) = 0xC2;
  *((&DCBlotColor4)(U8 *) + 1) = 0x20;
  *((&DCBlotColor4)(U8 *) + 2) = 0x00;
  POPFD
  CtrlAltCBSet('V', &RelicCtrlAltV, "Cmd /VGA (show crash or debugger screen)",, TRUE);
  if (!relic_disp_raw_hooked) {
    KeyDevAdd(&RelicRawPutKey, &RelicRawPutS, 0x5FFFFFFF);
    relic_disp_raw_hooked = TRUE;
  }
  return relic_disp_kind;
}
