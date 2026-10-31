#define RELIC_CFG_MAGIC 0x524C4346
class CRelicSettings
{
  I64 magic, version, wallpaper, stats, clock24, saver_minutes, animations;
};
CRelicSettings relic_cfg;
U8 relic_data_dir[64];

U0 RelicSettingsDefault()
{
  MemSet(&relic_cfg, 0, sizeof(CRelicSettings));
  relic_cfg.magic = RELIC_CFG_MAGIC;
  relic_cfg.version = 2;
  relic_cfg.animations=1;
  relic_cfg.wallpaper = 1;
  relic_cfg.clock24 = 1;
  relic_cfg.saver_minutes = 10;
}

U0 RelicSettingsLoad()
{
  U8 *data;
  I64 size;
  U8 path[128];
  RelicSettingsDefault;
  StrCpy(relic_data_dir, "::/Home/RelicData");
  if (!DrvIsWritable(':'))
    StrCpy(relic_data_dir, "B:/RelicData");
  DirMk(relic_data_dir);
  data=NULL;
  StrPrint(path,"%s/Settings.BIN",relic_data_dir);
  if (FileFind(path)) data=FileRead(path,&size);
  if (data) {
    if ((size == sizeof(CRelicSettings) || size == 48) &&
        data(CRelicSettings *)->magic == RELIC_CFG_MAGIC &&
        (data(CRelicSettings *)->version == 1 || data(CRelicSettings *)->version == 2)) {
      MemCpy(&relic_cfg, data, size);
      relic_cfg.version=2;
      relic_cfg.animations=!!relic_cfg.animations;
      relic_cfg.wallpaper = !!relic_cfg.wallpaper;
      relic_cfg.stats = !!relic_cfg.stats;
      relic_cfg.clock24 = !!relic_cfg.clock24;
      if (relic_cfg.saver_minutes < 0 || relic_cfg.saver_minutes > 60)
        relic_cfg.saver_minutes = 10;
    }
    Free(data);
  }
}

Bool RelicWriteChecked(U8 *path,U8 *data,I64 size)
{
  U8 *readback;
  I64 actual;
  Bool ok;
  if (!FileWrite(path,data,size)) return FALSE;
  readback=FileRead(path,&actual);
  if (!readback) return FALSE;
  ok=actual==size && !MemCmp(data,readback,size);
  Free(readback);
  return ok;
}

Bool RelicSettingsSave()
{
  U8 path[128];
  StrPrint(path, "%s/Settings.BIN", relic_data_dir);
  return RelicWriteChecked(path,&relic_cfg,sizeof(CRelicSettings));
}

U0 RelicMatteApply()
{
  CBGR48 pal[COLORS_NUM];
  RelicThemeApply;
  GrPaletteGet(pal);
  pal[BLUE].r = pal[BLUE].g = pal[BLUE].b = 0x0808;
  pal[GREEN].r = pal[GREEN].g = pal[GREEN].b = 0x1010;
  pal[PURPLE].r = pal[PURPLE].g = pal[PURPLE].b = 0x1818;
  pal[BROWN].r = pal[BROWN].g = pal[BROWN].b = 0x2020;
  pal[LTCYAN].r = pal[LTCYAN].g = pal[LTCYAN].b = 0x2828;
  pal[DKGRAY].r = pal[DKGRAY].g = pal[DKGRAY].b = 0x3838;
  pal[LTBLUE].r = pal[LTBLUE].g = pal[LTBLUE].b = 0x8888;
  pal[LTGRAY].r = pal[LTGRAY].g = pal[LTGRAY].b = 0xBBBB;
  pal[CYAN].r = pal[CYAN].g = pal[CYAN].b = 0xDDDD;
  pal[YELLOW].r = pal[YELLOW].g = pal[YELLOW].b = 0xEEEE;
  pal[WHITE].r = pal[WHITE].g = pal[WHITE].b = 0xFFFF;
  // Icon anti-aliasing step between DKGRAY and LTBLUE.
  pal[LTPURPLE].r = pal[LTPURPLE].g = pal[LTPURPLE].b = 0x6060;
  // Reaper wallpaper blue (RelicWallpaperLoad moves the artwork here).
  pal[LTGREEN].r = 0x0000; pal[LTGREEN].g = 0x9292; pal[LTGREEN].b = 0xBABA;
  GrPaletteSet(pal);
}

U0 RelicOutline(CDC *dc,I64 x,I64 y,I64 w,I64 h)
{
  GrLine(dc,x,y,x+w-1,y); GrLine(dc,x,y+h-1,x+w-1,y+h-1);
  GrLine(dc,x,y,x,y+h-1); GrLine(dc,x+w-1,y,x+w-1,y+h-1);
}

I64 RelicChoose(Bool condition,I64 yes,I64 no)
{
  if (condition) return yes;
  return no;
}
U8 *RelicText(Bool condition,U8 *yes,U8 *no)
{
  if (condition) return yes;
  return no;
}
