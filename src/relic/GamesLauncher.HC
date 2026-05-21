extern U0 RunTOOM();

U0 RelicGamesChromeOff()
{
  WinBorder(OFF);
  WinMax;
  winmgr.show_menu = FALSE;
  AutoComplete(OFF);
  Fs->win_inhibit = WIG_TASK_DFT - WIF_SELF_FOCUS -
        WIF_SELF_BORDER;
  WinFocus;
  Fs->text_attr = BLACK << 4 | LTGRAY;
  Fs->border_attr = BLACK << 4 | DKGRAY;
  "$FD,LTGRAY$$BD,BLACK$$FG,LTGRAY$$BG,BLACK$";
}

U0 RelicGamesHideTextPlane()
{
  Fs->text_attr = BLACK << 4 | BLACK;
  Fs->border_attr = BLACK << 4 | BLACK;
  "$FD,BLACK$$BD,BLACK$$FG,BLACK$$BG,BLACK$";
  DocClear;
}

U0 RelicGameFile(U8 *filename)
{
  RelicGamesChromeOff;
  FlushMsgs;
  DocClear;
  ExePrint("#include \"%s\";", filename);
}

U0 RelicGamePopUp(U8 *cmd)
{
  RelicGamesChromeOff;
  FlushMsgs;
  DocClear;
  ExePrint("%s", cmd);
}

U0 RelicGameRun(I64 id)
{
  RelicGamesChromeOff;
  DocClear;
  FlushMsgs;

  switch (id) {
    case 1:
      RelicGamesHideTextPlane;
      ExeFile("::/Home/RelicOS/RunTOOM.HC", CCF_JUST_LOAD);
      RunTOOM;
      break;
    case 2:  RelicGameFile("::/Apps/Titanium/Run"); break;
    case 3:  RelicGameFile("::/Demo/Games/BlackDiamond"); break;
    case 4:  RelicGameFile("::/Demo/Games/FlapBat"); break;
    case 5:  RelicGameFile("::/Demo/Games/Varoom"); break;
    case 6:  RelicGameFile("::/Demo/Games/FlatTops"); break;
    case 7:  RelicGameFile("::/Demo/Games/BomberGolf"); break;
    case 8:  RelicGameFile("::/Apps/KeepAway/Run"); break;
    case 9:  RelicGameFile("::/Demo/Games/RawHide"); break;
    case 10: RelicGameFile("::/Apps/X-Caliber/Run"); break;
    case 11: RelicGameFile("::/Demo/Games/Wenceslas"); break;
    case 12: RelicGameFile("::/Demo/Games/BattleLines"); break;
    case 13: RelicGameFile("::/Demo/Games/Talons"); break;
    case 14: RelicGameFile("::/Demo/Games/CastleFrankenstein"); break;
    case 15: RelicGameFile("::/Demo/Games/ZoneOut"); break;
    case 16: RelicGameFile("::/Apps/ToTheFront/Run"); break;
    case 17: RelicGameFile("::/Apps/Span/Run"); break;
    case 18: RelicGameFile("::/Demo/Games/TreeCheckers.HC.Z"); break;
    case 19: RelicGameFile("::/Demo/Games/Digits"); break;
    case 20: RelicGameFile("::/Apps/Strut/Run"); break;
    case 21: RelicGameFile("::/Demo/Games/BigGuns"); break;
    case 22: RelicGameFile("::/Demo/Games/TheDead"); break;
    case 23: RelicGameFile("::/Demo/Games/DunGen"); break;
    case 24: RelicGamePopUp("#include \"::/Apps/GrModels/Run\";View;"); break;
  }
}

U0 RelicGamesLauncher()
{
  U8 buf[3];
  I64 id, ch, sc, len = 0;

  RelicGamesChromeOff;
  DocTermNew;
  RelicGamesChromeOff;
  DocClear;
  buf[0] = 0;

  while (TRUE) {
    RelicGamesChromeOff;
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
    " 15. ZoneOut          16. ToTheFront       17. Span\n";
    " 18. Tree Checkers    19. Digits\n\n";
    "$FG,5$More Games$FG$\n";
    " 20. Strut            21. BigGuns          22. TheDead\n";
    " 23. DunGen           24. Models\n\n";
    "$FG,DKGRAY$Type a number and press Enter. Esc returns.$FG$\n\n";
    "game> %s", buf;

    GetMsg(&ch, &sc, 1 << MSG_KEY_DOWN);
    if (ch == CH_ESC || ch == CH_SHIFT_ESC)
      break;

    if (ch == '\n') {
      if (!len)
        break;
      id = Str2I64(buf);
      if (1 <= id <= 24) {
        RelicGameRun(id);
        if (id == 1) {
          RelicGamesChromeOff;
          DocTermNew;
          RelicGamesChromeOff;
          DocClear;
          len = 0;
          buf[0] = 0;
          continue;
        }
        break;
      }
      len = 0;
      buf[0] = 0;
    } else if (ch == CH_BACKSPACE) {
      if (len) {
        len--;
        buf[len] = 0;
      }
    } else if ('0' <= ch <= '9' && len < 2) {
      buf[len++] = ch;
      buf[len] = 0;
    }
  }
}
