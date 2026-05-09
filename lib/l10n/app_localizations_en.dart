// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hero\'s Draft';

  @override
  String get worldMap => 'World Map';

  @override
  String get shop => 'Shop';

  @override
  String get selectClass => 'Choose your Class';

  @override
  String get youAreDead => 'YOU ARE DEAD';

  @override
  String get mainMenu => 'Main Menu';

  @override
  String get changeClass => 'Change Class';

  @override
  String get currentLevel => 'Current Level';

  @override
  String get endTurn => 'End Turn';

  @override
  String drawPile(int count) {
    return 'Draw: $count';
  }

  @override
  String discardPile(int count) {
    return 'Discard: $count';
  }

  @override
  String get pause => 'PAUSE';

  @override
  String get resumeCombat => 'Resume Combat';

  @override
  String get playerTurn => 'PLAYER TURN';

  @override
  String get enemyTurn => 'ENEMY TURN';

  @override
  String get notEnoughGold => 'Not enough gold!';

  @override
  String purchased(String item) {
    return 'Purchased: $item';
  }

  @override
  String get healApplied => 'Healing applied!';

  @override
  String get fullHp => 'You already have max HP!';

  @override
  String get cardsForSale => 'Cards for Sale';

  @override
  String get services => 'Services';

  @override
  String get healingPotion => 'Healing Potion';

  @override
  String restoresHp(int amount) {
    return 'Restores $amount HP';
  }

  @override
  String get leaveShop => 'Leave Shop';

  @override
  String get combatReward => 'COMBAT REWARD';

  @override
  String get chooseUpgrade => 'Choose an upgrade for your hero';

  @override
  String get select => 'Select';

  @override
  String get nextAction => 'Next action';
}
