// GamesLauncher.HC — HolyC-safe: one statement per switch case, no goto.

#define RELIC_GAMES_MENU_ROW  2

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
  Fs->draw_it = NULL;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

U0 RelicGamesStatusLine()
{
  RelicStatusFormat;
  TextPrint(Fs, 0, 0, BLACK << 4 | LTGRAY, relic_top_line);
}

U0 RelicGamesScreenClear()
{
  DocClear;
  DCFill;
  RelicGamesStatusLine;
}

U0 RelicGameRunTOOM()
{
  ExeFile("::/Home/RelicOS/RunTOOM.HC", CCF_JUST_LOAD);
  ExePrint("RunTOOM;");
}

U0 RelicGameFile(U8 *filename)
{
  RelicGamesChromeOff;
  FlushMsgs;
  RelicGamesScreenClear;
  ExePrint("#include \"%s\";", filename);
}

U0 RelicGamePopUp(U8 *cmd)
{
  RelicGamesChromeOff;
  FlushMsgs;
  RelicGamesScreenClear;
  ExePrint("%s", cmd);
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
  I64 i;

  for (i = 0; i < RELIC_GAMES_MENU_ROW; i++)
    "\n";
  "$FG,5$DOOM$FG$\n";
  "  1. DOOM\n\n";
  "$FG,5$Fun Games$FG$\n";
  "  2. Titanium          3. Black Diamond     4. Flap Bat\n";
  "  5. Varoom            6. FlatTops          7. Bomber Golf\n";
  "  8. KeepAway          9. RawHide          10. X-Caliber\n";
  " 11. Wenceslas        12. Battle Lines\n\n";
  "$FG,5$Unfun Games$FG$\n";
  "  13. Talons           14. Castle Frankenstein\n";
  "  15. ZoneOut          16. ToTheFront       17. Span\n";
  "  18. Tree Checkers    19. Digits\n\n";
  "$FG,5$More Games$FG$\n";
  "  20. Strut            21. BigGuns          22. TheDead\n";
  "  23. DunGen           24. Models\n\n";
  "$FG,DKGRAY$Type a number and press Enter. Esc returns.$FG$\n\n";
  "game> %s", buf;
  LBts(&Fs->display_flags, DISPLAYf_SHOW);
  WinZBufUpdate;
}

U0 RelicGamesLauncher()
{
  U8 buf[3];
  I64 id, ch, sc, len = 0;

  RelicGamesChromeOff;
  RelicChromeInstall;
  relic_status_show_keys = FALSE;
  DocTermNew;
  RelicGamesScreenClear;
  buf[0] = 0;

  while (TRUE) {
    RelicGamesScreenClear;
    RelicGamesDrawMenu(buf);

    GetMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (ch == CH_ESC || ch == CH_SHIFT_ESC)
      return;

    if (ch == '\n') {
      if (!len)
        return;
      id = Str2I64(buf);
      if (1 <= id && id <= 24) {
        RelicGameRun(id);
        if (id == 1) {
          RelicTermDark;
          RelicGamesChromeOff;
          RelicChromeInstall;
          relic_status_show_keys = FALSE;
          len = 0;
          buf[0] = 0;
        } else
          return;
      }
      len = 0;
      buf[0] = 0;
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
}
