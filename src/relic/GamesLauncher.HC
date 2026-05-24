// GamesLauncher.HC — compiled into RelicDesktop.HC via #include.
// Stock TempleOS pattern: every game runs INLINE on this task (no Spawn).

extern U0 RelicStatusWallPaper(CTask *);
extern U0 RelicChromeInstall();
extern U0 RelicThemeApply();
extern U0 RelicDoomBegin();
extern U0 RelicDoomEnd();

U0 RelicGamesEnter()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS - WIF_SELF_BORDER;
  WinFocus;
  Fs->border_src = 0;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

// Black doc only — never touch draw_it here (DOOM uses RelicDoomBegin for that).
U0 RelicGamesDocBlack()
{
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocClear;
  DCFill;
}

U0 RelicGamesAfter()
{
  gr.fp_wall_paper = &RelicStatusWallPaper;
  RelicThemeApply;
  RelicChromeInstall;
  RelicGamesEnter;
  DocTermNew;
  relic_status_show_keys = FALSE;
  FlushMsgs;
}

// Stock demo launch: inline #include on this task, no child, no hidden parent.
U0 RelicGameInline(U8 *path)
{
  gr.fp_wall_paper = NULL;
  Fs->draw_it = NULL;
  RelicGamesDocBlack;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
  WinFocus;
  try {
    ExePrint("#include \"%s\";", path);
  } catch {
    Fs->catch_except = TRUE;
  }
  RelicGamesAfter;
}

#include "::/Home/RelicOS/RunTOOM.HC"

U0 RelicGameRun(I64 id)
{
  RelicGamesEnter;
  FlushMsgs;
  DocClear;

  switch (id) {
    case 1:
      gr.fp_wall_paper = NULL;
      RelicGamesDocBlack;
      RelicDoomBegin;
      try {
        RunTOOM;
      } catch {
        Fs->catch_except = TRUE;
      }
      RelicDoomEnd;
      RelicGamesAfter;
      break;
    case 2:  RelicGameInline("::/Apps/Titanium/Run"); break;
    case 3:  RelicGameInline("::/Demo/Games/BlackDiamond"); break;
    case 4:  RelicGameInline("::/Demo/Games/FlapBat"); break;
    case 5:  RelicGameInline("::/Demo/Games/Varoom"); break;
    case 6:  RelicGameInline("::/Demo/Games/FlatTops"); break;
    case 7:  RelicGameInline("::/Demo/Games/BomberGolf"); break;
    case 8:  RelicGameInline("::/Apps/KeepAway/Run"); break;
    case 9:  RelicGameInline("::/Demo/Games/RawHide"); break;
    case 10: RelicGameInline("::/Apps/X-Caliber/Run"); break;
    case 11: RelicGameInline("::/Demo/Games/Wenceslas"); break;
    case 12: RelicGameInline("::/Demo/Games/BattleLines"); break;
    case 13: RelicGameInline("::/Demo/Games/Talons"); break;
    case 14: RelicGameInline("::/Demo/Games/CastleFrankenstein"); break;
    case 15: RelicGameInline("::/Demo/Games/ZoneOut"); break;
    case 16: RelicGameInline("::/Apps/ToTheFront/Run"); break;
    case 17: RelicGameInline("::/Apps/Span/Run"); break;
    case 18: RelicGameInline("::/Demo/Games/TreeCheckers.HC.Z"); break;
    case 19: RelicGameInline("::/Demo/Games/Digits"); break;
    case 20: RelicGameInline("::/Apps/Strut/Run"); break;
    case 21: RelicGameInline("::/Demo/Games/BigGuns"); break;
    case 22: RelicGameInline("::/Demo/Games/TheDead"); break;
    case 23: RelicGameInline("::/Demo/Games/DunGen"); break;
    case 24:
      gr.fp_wall_paper = NULL;
      Fs->draw_it = NULL;
      RelicGamesDocBlack;
      LBts(&Fs->display_flags, DISPLAYf_SHOW);
      WinZBufUpdate;
      try {
        ExePrint("#include \"::/Apps/GrModels/Run\";View;");
      } catch {
        Fs->catch_except = TRUE;
      }
      RelicGamesAfter;
      break;
  }
}

U0 RelicGamesLauncher()
{
  U8 buf[3];
  I64 id, ch, sc, len = 0;

  RelicGamesEnter;
  DocTermNew;
  relic_status_show_keys = FALSE;
  buf[0] = 0;

  while (TRUE) {
    if (ms.pos.y < 20)
      MsSet(ms.pos.x, GR_HEIGHT / 2);
    DocClear;
    "$FG,5$DOOM$FG$\n";
    "  1. DOOM\n\n";
    "$FG,5$Fun Games$FG$\n";
    "  2. Titanium          3. Black Diamond     4. Flap Bat\n";
    "  5. Varoom            6. FlatTops          7. Bomber Golf\n";
    "  8. KeepAway          9. RawHide          10. X-Caliber\n";
    " 11. Wenceslas        12. Battle Lines\n\n";
    "$FG,5$Unfun Games$FG$\n";
    " 13. Talons           14. Castle Frankenstein\n";
    "  15. ZoneOut          16. ToTheFront       17. Span\n";
    " 18. Tree Checkers    19. Digits\n\n";
    "$FG,5$More Games$FG$\n";
    "  20. Strut            21. BigGuns          22. TheDead\n";
    "  23. DunGen           24. Models\n\n";
    "$FG,DKGRAY$Type a number and press Enter. Esc returns.$FG$\n\n";
    "game> %s", buf;
    LBts(&Fs->display_flags, DISPLAYf_SHOW);
    WinZBufUpdate;

    if (!ScanMsg(&ch, &sc, 1 << MSG_KEY_DOWN))
      continue;
    if (ch == CH_ESC || ch == CH_SHIFT_ESC)
      break;
    if (ch == '\n') {
      if (!len)
        break;
      id = Str2I64(buf);
      len = 0;
      buf[0] = 0;
      if (1 <= id && id <= 24)
        RelicGameRun(id);
      RelicGamesEnter;
      DocTermNew;
    } else if (ch == CH_BACKSPACE) {
      if (len) {
        len--;
        buf[len] = 0;
      }
    } else if ('0' <= ch && ch <= '9' && len < 2) {
      buf[len++] = ch;
      buf[len] = 0;
    }
  }
  RelicGamesAfter;
}
