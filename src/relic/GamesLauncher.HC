// GamesLauncher.HC — compiled into RelicDesktop.HC via #include.
// Must live in the desktop heap; do NOT ExeFile/CCF_JUST_LOAD this file.

CBGR48 relic_bright_pal[COLORS_NUM] = {
  0x000000000000, // BLACK
  0x00000000A800, // BLUE
  0x0000A8000000, // GREEN
  0x0000A800A800, // CYAN
  0xA80000000000, // RED
  0xA8000000A800, // PURPLE
  0xA80054000000, // BROWN
  0xA800A800A800, // LTGRAY
  0x540054005400, // DKGRAY
  0x54005400FCFC, // LTBLUE
  0x5400FCFC5400, // LTGREEN
  0x5400FCFCFCFC, // LTCYAN
  0xFCFC54005400, // LTRED
  0xFCFC5400FCFC, // LTPURPLE
  0xFCFCFCFC5400, // YELLOW
  0xFCFCFCFCFCFC  // WHITE
};

CBGR48 relic_saved_pal[COLORS_NUM];
Bool relic_pal_saved = FALSE;

U0 RelicGamesPaletteBright()
{
  if (!relic_pal_saved) {
    GrPaletteGet(relic_saved_pal);
    relic_pal_saved = TRUE;
  }
  GrPaletteSet(relic_bright_pal);
}

U0 RelicGamesPaletteRestore()
{
  if (relic_pal_saved) {
    GrPaletteSet(relic_saved_pal);
    relic_pal_saved = FALSE;
  }
}

U0 RelicGamesChromeOff()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS -
        WIF_SELF_BORDER;
  WinFocus;
  RelicTermDark;
  Fs->border_src = 0;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

// Hide the DolDoc text plane so it cannot paint over game GrBlot output.
// Pink/lavender fullscreen = LTPURPLE (index 13) DolDoc bleeding over graphics.
U0 RelicGamesHideTextPlane()
{
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocTermNew;
  DocClear;
  DCFill;
}

// Run a demo game in a child task; hide this (parent) window so its DolDoc
// cannot composite over the child. Parent polls Esc and kills the child.
U0 RelicGameChildMain(U8 *filename)
{
  RelicGamesHideTextPlane;
  gr.fp_wall_paper = NULL;
  RelicGamesPaletteBright;
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  WinFocus;
  try {
    ExePrint("#include \"%s\";", filename);
  } catch {
    Fs->catch_except = TRUE;
  }
}

U0 RelicGameSpawnWait(U0 (*entry)(), U8 *arg1, U8 *task_name)
{
  I64 ch, sc, mc;

  RelicChildKill;
  FlushMsgs;
  LBtr(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  relic_child_task = Spawn(entry, arg1, task_name,, Fs);
  if (TaskValidate(relic_child_task))
    WinToTop(relic_child_task);
  while (TaskValidate(relic_child_task)) {
    mc = ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (mc && (ch == CH_ESC || ch == CH_SHIFT_ESC)) {
      Kill(relic_child_task, FALSE);
      break;
    }
    Sleep(20);
  }
  relic_child_task = NULL;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  WinToTop(Fs);
  WinFocus;
  FlushMsgs;
}

U0 RelicGamesScreenClear()
{
  DocClear;
  DCFill;
  // Row 0 is reserved for the status bar (fp_wall_paper).
  // Two blank rows push menu content safely past it.
  "\n\n";
}

#include "::/Home/RelicOS/RunTOOM.HC"

U0 RelicGameRunTOOM()
{
  RelicGamesPaletteBright;
  RelicGamesHideTextPlane;
  gr.fp_wall_paper = NULL;
  RelicGameSpawnWait(&RelicTOOMChildMain, NULL, "TOOM");
  RelicDoomEnd;
}

U0 RelicGameAfter()
{
  RelicGamesPaletteRestore;
  RelicThemeApply;
  RelicTermDark;
  RelicGamesChromeOff;
  DocTermNew;
  relic_status_show_keys = FALSE;
  FlushMsgs;
}

U0 RelicGameFile(U8 *filename)
{
  RelicGamesChromeOff;
  RelicGamesPaletteBright;
  gr.fp_wall_paper = NULL;
  FlushMsgs;
  RelicGameSpawnWait(&RelicGameChildMain, filename, "RelicGame");
  RelicGameAfter;
}

U0 RelicGamePopUp(U8 *cmd)
{
  RelicGamesChromeOff;
  RelicGamesPaletteBright;
  FlushMsgs;
  RelicGamesScreenClear;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  try {
    ExePrint("%s", cmd);
  } catch {
    Fs->catch_except = TRUE;
  }
  RelicGameAfter;
}

U0 RelicGameRun(I64 id)
{
  RelicGamesChromeOff;
  RelicGamesScreenClear;
  FlushMsgs;

  if (id == 1)
    RelicGameRunTOOM;
  else if (id == 2)
    RelicGameFile("::/Apps/Titanium/Run");
  else if (id == 3)
    RelicGameFile("::/Demo/Games/BlackDiamond");
  else if (id == 4)
    RelicGameFile("::/Demo/Games/FlapBat");
  else if (id == 5)
    RelicGameFile("::/Demo/Games/Varoom");
  else if (id == 6)
    RelicGameFile("::/Demo/Games/FlatTops");
  else if (id == 7)
    RelicGameFile("::/Demo/Games/BomberGolf");
  else if (id == 8)
    RelicGameFile("::/Apps/KeepAway/Run");
  else if (id == 9)
    RelicGameFile("::/Demo/Games/RawHide");
  else if (id == 10)
    RelicGameFile("::/Apps/X-Caliber/Run");
  else if (id == 11)
    RelicGameFile("::/Demo/Games/Wenceslas");
  else if (id == 12)
    RelicGameFile("::/Demo/Games/BattleLines");
  else if (id == 13)
    RelicGameFile("::/Demo/Games/Talons");
  else if (id == 14)
    RelicGameFile("::/Demo/Games/CastleFrankenstein");
  else if (id == 15)
    RelicGameFile("::/Demo/Games/ZoneOut");
  else if (id == 16)
    RelicGameFile("::/Apps/ToTheFront/Run");
  else if (id == 17)
    RelicGameFile("::/Apps/Span/Run");
  else if (id == 18)
    RelicGameFile("::/Demo/Games/TreeCheckers.HC.Z");
  else if (id == 19)
    RelicGameFile("::/Demo/Games/Digits");
  else if (id == 20)
    RelicGameFile("::/Apps/Strut/Run");
  else if (id == 21)
    RelicGameFile("::/Demo/Games/BigGuns");
  else if (id == 22)
    RelicGameFile("::/Demo/Games/TheDead");
  else if (id == 23)
    RelicGameFile("::/Demo/Games/DunGen");
  else if (id == 24)
    RelicGamePopUp("#include \"::/Apps/GrModels/Run\";View;");
}

U0 RelicGamesDrawMenu(U8 *buf)
{
  "$FG,5$DOOM$FG$\n";
  "  1. DOOM\n\n";
  "$FG,5$Fun Games$FG$\n";
  "  2. Titanium          3. Black Diamond     4. Flap Bat\n";
  "  5. Varoom            6. FlatTops          7. Bomber Golf\n";
  "  8. KeepAway          9. RawHide          10. X-Caliber\n";
  " 11. Wenceslas        12. Battle Lines\n\n";
  "$FG,5$Unfun Games$FG$\n";
  " 13. Talons           14. Castle Frankenstein\n";
  " 15. ZoneOut          16. ToTheFront       17. Span\n";
  " 18. Tree Checkers    19. Digits\n\n";
  "$FG,5$More Games$FG$\n";
  " 20. Strut            21. BigGuns          22. TheDead\n";
  " 23. DunGen           24. Models\n\n";
  "$FG,DKGRAY$Type a number and press Enter. Esc returns (also during games).$FG$\n\n";
  "game> %s", buf;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
}

U0 RelicGamesLauncher()
{
  U8 buf[3];
  I64 id, ch, sc, mc, len = 0;
  Bool need_redraw = TRUE;

  RelicGamesChromeOff;
  DocTermNew;
  relic_status_show_keys = FALSE;
  buf[0] = 0;

  while (TRUE) {
    if (need_redraw) {
      RelicGamesScreenClear;
      RelicGamesDrawMenu(buf);
      need_redraw = FALSE;
    }

    if (RelicKillRogueChildren) {
      WinToTop(Fs);
      WinFocus;
      need_redraw = TRUE;
    }

    mc = ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (!mc) {
      Sleep(15);
      WinToTop(Fs);
      WinFocus;
    } else if (ch == CH_ESC || ch == CH_SHIFT_ESC) {
      return;
    } else if (ch == '\n') {
      if (!len)
        return;
      id = Str2I64(buf);
      len = 0;
      buf[0] = 0;
      need_redraw = TRUE;
      if (1 <= id && id <= 24) {
        RelicGameRun(id);
        // After any game exits, restore chrome and redraw the menu.
        RelicTermDark;
        RelicGamesChromeOff;
        DocTermNew;
        relic_status_show_keys = FALSE;
      }
    } else if (ch == CH_BACKSPACE) {
      if (len) {
        len--;
        buf[len] = 0;
        need_redraw = TRUE;
      }
    } else if ('0' <= ch && ch <= '9' && len < 2) {
      buf[len++] = ch;
      buf[len] = 0;
      need_redraw = TRUE;
    }
  }
}
