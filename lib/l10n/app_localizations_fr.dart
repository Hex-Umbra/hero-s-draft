// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Hero\'s Draft';

  @override
  String get worldMap => 'Carte du Monde';

  @override
  String get shop => 'Boutique';

  @override
  String get selectClass => 'Choisissez votre Classe';

  @override
  String get youAreDead => 'VOUS ÊTES MORT';

  @override
  String get mainMenu => 'Menu Principal';

  @override
  String get changeClass => 'Changer de Classe';

  @override
  String get currentLevel => 'Niveau actuel';

  @override
  String get endTurn => 'Fin de Tour';

  @override
  String drawPile(int count) {
    return 'Pioche: $count';
  }

  @override
  String discardPile(int count) {
    return 'Défausse: $count';
  }

  @override
  String get pause => 'PAUSE';

  @override
  String get resumeCombat => 'Reprendre le Combat';

  @override
  String get playerTurn => 'TOUR JOUEUR';

  @override
  String get enemyTurn => 'TOUR ENNEMI';

  @override
  String get notEnoughGold => 'Pas assez d\'or !';

  @override
  String purchased(String item) {
    return 'Acheté : $item';
  }

  @override
  String get healApplied => 'Soin appliqué !';

  @override
  String get fullHp => 'Vous avez déjà tous vos PV !';

  @override
  String get cardsForSale => 'Cartes à vendre';

  @override
  String get services => 'Services';

  @override
  String get healingPotion => 'Potion de Soin';

  @override
  String restoresHp(int amount) {
    return 'Restaure $amount PV';
  }

  @override
  String get leaveShop => 'Quitter la boutique';

  @override
  String get combatReward => 'RÉCOMPENSE DE COMBAT';

  @override
  String get chooseUpgrade => 'Choisissez une amélioration pour votre héros';

  @override
  String get select => 'Sélectionner';

  @override
  String get nextAction => 'Prochaine action';
}
