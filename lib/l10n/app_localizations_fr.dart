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

  @override
  String get myDeck => 'Mon Deck';

  @override
  String get stats => 'Stats';

  @override
  String get relics => 'Reliques';

  @override
  String get chances => 'Chances';

  @override
  String goldCount(int count) {
    return 'Or : $count';
  }

  @override
  String get heroStatsTitle => 'Statistiques du Héros';

  @override
  String get classPassive => 'Effet Passif';

  @override
  String get relicInventory => 'Inventaire des Reliques';

  @override
  String get emptyInventory => 'Votre inventaire est vide';

  @override
  String get luckPercentageTitle => 'Taux d\'obtention des Raretés';

  @override
  String currentLuck(int luck) {
    return 'Votre Chance : $luck';
  }

  @override
  String get legendTitle => 'LÉGENDE';

  @override
  String get legendCombat => 'Combat Normal';

  @override
  String get legendElite => 'Combat Élite';

  @override
  String get legendShop => 'Boutique Marchand';

  @override
  String get legendRest => 'Camp de Repos';

  @override
  String get legendEvent => 'Événement Inconnu';

  @override
  String get legendBoss => 'Combat de Boss';

  @override
  String get tooltipCombatTitle => 'Combat Normal';

  @override
  String get tooltipCombatDesc =>
      'Affrontez un monstre standard pour gagner des cartes et de l\'or.';

  @override
  String get tooltipEliteTitle => 'Combat Élite';

  @override
  String get tooltipEliteDesc =>
      'Un combat bien plus rude, mais garantit l\'obtention d\'une relique.';

  @override
  String get tooltipShopTitle => 'Boutique du Marchand';

  @override
  String get tooltipShopDesc =>
      'Dépensez votre or durement gagné pour acheter des cartes et potions.';

  @override
  String get tooltipRestTitle => 'Camp de Repos';

  @override
  String get tooltipRestDesc =>
      'Reposez-vous pour récupérer 30% de vos PV max.';

  @override
  String get tooltipEventTitle => 'Événement Inconnu';

  @override
  String get tooltipEventDesc =>
      'Qui sait quelles surprises ou dangers vous attendent ici ?';

  @override
  String get tooltipBossTitle => 'Combat de Boss';

  @override
  String get tooltipBossDesc =>
      'Battez le gardien de cet étage pour compléter l\'acte !';

  @override
  String actLevel(int act, int level) {
    return 'Acte $act - Niveau : $level';
  }

  @override
  String get playerEffects => 'Effets du Joueur';

  @override
  String get enemyIntents => 'Intentions Ennemies';

  @override
  String get noStatusActive => 'Aucun effet actif';

  @override
  String get waitingIntents => 'En attente...';

  @override
  String get manaWarning => 'Plus de mana.\nTerminer le tour ?';

  @override
  String turnCount(int count) {
    return 'Tour $count';
  }

  @override
  String get pauseTitle => 'PAUSE';

  @override
  String get backToMainMenu => 'Retour au Menu Principal';

  @override
  String get relicTriggerRun => 'Début Run';

  @override
  String get relicTriggerCombat => 'Début Combat';

  @override
  String get relicTriggerTurnStart => 'Début Tour';

  @override
  String get relicTriggerTurnEnd => 'Fin Tour';

  @override
  String get relicTriggerCardPlayed => 'Carte Jouée';

  @override
  String get relicTriggerEnemyKilled => 'Ennemi Tué';

  @override
  String get rarityCommon => 'Commun';

  @override
  String get rarityUncommon => 'Peu Commun';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Épique';

  @override
  String get rarityLegendary => 'Légendaire';

  @override
  String get tooltipHpTitle => 'Points de Vie (PV)';

  @override
  String get tooltipHpDesc =>
      'Votre réserve de santé. S\'il tombe à 0, vous mourez.';

  @override
  String get tooltipArmorTitle => 'Blocage / Armure';

  @override
  String get tooltipArmorDesc =>
      'Absorbe les dégâts des prochaines attaques. Retiré au début du tour.';

  @override
  String get tooltipAttackTitle => 'Boost d\'Attaque (Force)';

  @override
  String get tooltipAttackDesc =>
      'Augmente les dégâts de vos cartes d\'attaque.';

  @override
  String get tooltipManaTitle => 'Mana';

  @override
  String get tooltipManaDesc =>
      'Ressource d\'énergie utilisée pour jouer des cartes chaque tour.';

  @override
  String get cardTypeAttack => 'Attaque';

  @override
  String get cardTypeSkill => 'Compétence';

  @override
  String get cardTypePower => 'Pouvoir';

  @override
  String get cardTypeStatus => 'Statut';

  @override
  String get oncePlayed => 'USAGE UNIQUE';

  @override
  String get exhaustWarning => '⚠️ USAGE UNIQUE (Épuisement)';

  @override
  String get hpAbbreviation => 'PV';

  @override
  String get enemyIntentsTitle => 'INTENTIONS ENNEMIES';

  @override
  String intentDevastatingAttack(int value) {
    return 'Attaque Dévastatrice : $value';
  }

  @override
  String intentHeavyAttack(int value) {
    return 'Attaque Lourde : $value';
  }

  @override
  String intentAttack(int value) {
    return 'Attaque : $value';
  }

  @override
  String intentQuickAttack(int value) {
    return 'Attaque Rapide : $value';
  }

  @override
  String intentDefend(int value) {
    return 'Défense : +$value';
  }

  @override
  String intentBuff(int value) {
    return 'Buff Attaque : +$value';
  }

  @override
  String intentCurse(int value) {
    return 'Malédiction : $value';
  }

  @override
  String get enemyStatsTitle => 'STATS DE L\'ENNEMI';

  @override
  String enemyStatsDesc(int hp, int maxHp, int attack, int armor) {
    return 'Santé : $hp/$maxHp PV.\nAttaque : $attack.\nArmure : $armor.';
  }

  @override
  String cardDescDamage(int amount) {
    return 'Inflige $amount dégâts.';
  }

  @override
  String cardDescDamageAll(int amount) {
    return 'Inflige $amount dégâts à tous les ennemis.';
  }

  @override
  String cardDescHeal(int amount) {
    return 'Soigne $amount PV.';
  }

  @override
  String cardDescArmor(int amount) {
    return 'Donne $amount Armure.';
  }

  @override
  String cardDescGainMana(int amount) {
    return 'Gagne $amount Mana.';
  }

  @override
  String cardDescDraw(int amount) {
    return 'Pioche $amount cartes.';
  }

  @override
  String cardDescStatusStrength(int amount, int duration) {
    return 'Gagne $amount ATK pendant $duration tours.';
  }

  @override
  String cardDescStatusArmorRegen(int amount, int duration) {
    return 'Pendant $duration tours, gagne $amount Armure au début du tour.';
  }

  @override
  String cardDescStatusPoison(int amount) {
    return 'Applique $amount Poison.';
  }

  @override
  String cardDescStatusWeakness(int amount) {
    return 'Applique $amount Faiblesse.';
  }

  @override
  String cardDescStatusVulnerable(int amount) {
    return 'Applique $amount Vulnérable.';
  }

  @override
  String cardDescStatusStrengthRegen(int amount, int duration) {
    return 'Gagne $amount Éveil d\'Attaque pendant $duration tours.';
  }

  @override
  String cardDescStatusBurn(int amount) {
    return 'Applique $amount Brûlure.';
  }

  @override
  String cardDescStatusFreeze(int amount) {
    return 'Applique $amount Gel.';
  }

  @override
  String cardDescStatusShock(int amount) {
    return 'Applique $amount Électrocution.';
  }
}
