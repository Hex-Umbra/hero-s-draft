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
  String get legendBossCards => 'Boss (Récompense Cartes)';

  @override
  String get legendBossXp => 'Boss (XP x2)';

  @override
  String get legendBossRelic => 'Boss (Récompense Relique)';

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
  String get remainingManaWarning => 'Mana restant.\nTerminer le tour ?';

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
  String cardDescStatusPoisonDuration(int amount, int duration) {
    return 'Applique $amount Poison pendant $duration tours.';
  }

  @override
  String cardDescStatusWeakness(int amount) {
    return 'Applique $amount Faiblesse.';
  }

  @override
  String cardDescStatusWeaknessDuration(int amount, int duration) {
    return 'Applique $amount Faiblesse pendant $duration tours.';
  }

  @override
  String cardDescStatusVulnerable(int amount) {
    return 'Applique $amount Vulnérable.';
  }

  @override
  String cardDescStatusVulnerableDuration(int amount, int duration) {
    return 'Applique $amount Vulnérable pendant $duration tours.';
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
  String cardDescStatusBurnDuration(int amount, int duration) {
    return 'Applique $amount Brûlure pendant $duration tours.';
  }

  @override
  String cardDescStatusFreeze(int amount) {
    return 'Applique $amount Gel.';
  }

  @override
  String cardDescStatusFreezeDuration(int amount, int duration) {
    return 'Applique $amount Gel pendant $duration tours.';
  }

  @override
  String cardDescStatusShock(int amount) {
    return 'Applique $amount Électrocution.';
  }

  @override
  String cardDescStatusShockDuration(int amount, int duration) {
    return 'Applique $amount Électrocution pendant $duration tours.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get shopExpanded => 'Boutique agrandie définitivement !';

  @override
  String get shopRerolled => 'Cartes renouvelées !';

  @override
  String get chooseCardToPurge => 'Choisissez une carte à purger';

  @override
  String get cardPurged => 'Carte purgée !';

  @override
  String get chooseCardToClone => 'Choisissez une carte à cloner';

  @override
  String get cardCloned => 'Carte clonée !';

  @override
  String get noCardsInStock => 'Plus de cartes en stock !';

  @override
  String levelLabel(int level) {
    return 'Niv $level';
  }

  @override
  String get shopReroll => 'Renouveler';

  @override
  String get shopRerollDesc => 'Renouvelle les cartes en vente';

  @override
  String get shopPurge => 'Purger';

  @override
  String get shopPurgeDesc => 'Retire une carte de votre deck';

  @override
  String get shopExpand => 'Étal étendu';

  @override
  String get shopExpandDesc => 'Ajoute 1 carte de plus en vente définitivement';

  @override
  String get shopClone => 'Miroir Magique';

  @override
  String get shopCloneDesc => 'Clone une carte de votre deck';

  @override
  String get targetSingleEnemy => 'Cible unique';

  @override
  String get targetAllEnemies => 'Tous les ennemis';

  @override
  String get targetSelf => 'Soi-même';

  @override
  String get targetNone => 'Aucune';

  @override
  String get restCampTitle => 'ZONE DE REPOS';

  @override
  String get restCampSubtitle => 'Le crépitement du feu vous apaise...';

  @override
  String get restCampRest => 'SE REPOSER';

  @override
  String restCampRestDesc(int amount) {
    return 'Restaure 30% des PV Max ($amount PV)';
  }

  @override
  String get restCampForge => 'FORGER';

  @override
  String get restCampForgeDesc =>
      'Améliore définitivement une carte de votre deck.';

  @override
  String get restCampRemove => 'OUBLIER';

  @override
  String get restCampRemoveDesc =>
      'Retire définitivement une carte de votre deck.';

  @override
  String get restCampProceed => 'CONTINUER LA ROUTE';

  @override
  String restCampSnackbarHeal(int amount) {
    return 'Repos terminé. Vous avez récupéré $amount PV.';
  }

  @override
  String restCampSnackbarForge(String cardName, int level) {
    return '$cardName a été améliorée au Niveau $level !';
  }

  @override
  String restCampSnackbarRemove(String cardName) {
    return '$cardName a été retirée du deck.';
  }

  @override
  String get restCampForgeTitle => 'FORGER UNE CARTE';

  @override
  String get restCampForgeSubtitle =>
      'Choisissez une carte à améliorer définitivement.';

  @override
  String get restCampRemoveTitle => 'OUBLIER UNE CARTE';

  @override
  String get restCampRemoveSubtitle =>
      'Choisissez une carte à retirer définitivement de votre deck.';

  @override
  String get draftDeckTitle => 'CONSTITUTION DU DECK';

  @override
  String get draftDeckSubtitle =>
      'Sélectionnez précisément 5 cartes globales pour constituer votre deck de départ et lancer la run.';

  @override
  String draftDeckSelectedCount(int count) {
    return 'Cartes sélectionnées : $count / 5';
  }

  @override
  String get draftDeckProceed => 'ENTRER DANS L\'UMBRA';

  @override
  String get draftDeckSnackbarMax =>
      'Vous pouvez sélectionner jusqu\'à 5 cartes maximum.';

  @override
  String mergeLabel(int count) {
    return 'FUSIONNER ($count)';
  }

  @override
  String get mergePossible => 'Fusion possible';

  @override
  String mergeMoreRequired(int count) {
    return '$count de plus requis';
  }

  @override
  String get confirmMerge => 'Confirmer la fusion';

  @override
  String get draftChoiceVitality => 'Vitalité';

  @override
  String draftChoiceVitalityDesc(int amount) {
    return '+$amount PV Max';
  }

  @override
  String get draftChoiceSharpening => 'Aiguisage';

  @override
  String draftChoiceSharpeningDesc(int amount) {
    return '+$amount Attaque';
  }

  @override
  String get draftChoiceSteelForge => 'Forge d\'Acier';

  @override
  String draftChoiceSteelForgeDesc(int amount) {
    return '+$amount aux gains d\'Armure de votre passif';
  }

  @override
  String get draftChoiceWisdom => 'Sagesse';

  @override
  String draftChoiceWisdomDesc(int amount) {
    return '+$amount Mana Max';
  }

  @override
  String get draftChoiceClover => 'Trèfle à 4 feuilles';

  @override
  String draftChoiceCloverDesc(int amount) {
    return '+$amount Chance';
  }

  @override
  String get draftChoiceMirror => 'Miroir';

  @override
  String get draftChoiceMirrorDesc =>
      'Cloner une carte au choix parmi 3 cartes aléatoires de votre deck';

  @override
  String get draftChoicePrecision => 'Précision';

  @override
  String draftChoicePrecisionDesc(int amount) {
    return '+$amount% de chance de Critique';
  }

  @override
  String get draftChoiceFerocity => 'Férocité';

  @override
  String draftChoiceFerocityDesc(int amount) {
    return '+$amount% de dégâts de Critique';
  }

  @override
  String statusPoison(int value) {
    return 'Poison : $value';
  }

  @override
  String statusStrength(int value) {
    return 'Attaque : +$value';
  }

  @override
  String statusWeakness(int value) {
    return 'Faiblesse : $value';
  }

  @override
  String statusVulnerable(int value) {
    return 'Vulnérable : $value';
  }

  @override
  String statusStrengthRegen(int value) {
    return 'Éveil d\'Attaque : +$value';
  }

  @override
  String statusArmorRegen(int value) {
    return 'Métallisation : +$value';
  }

  @override
  String statusLifesteal(int value) {
    return 'Vol de Vie : $value';
  }

  @override
  String statusTurns(int count) {
    return '$count trs';
  }

  @override
  String deckTotalCards(int count) {
    return 'Total : $count cartes';
  }

  @override
  String deckMergeConfirm(String cardName, int level, int nextLevel) {
    return 'Voulez-vous fusionner 3 exemplaires de \"$cardName\" (Niv. $level) pour obtenir un exemplaire de Niveau $nextLevel ?';
  }

  @override
  String deckMergeSuccess(String cardName, int level) {
    return 'Fusion réussie : $cardName est maintenant Niveau $level !';
  }

  @override
  String rarityLevel(String rarity, int level) {
    return '$rarity - Niv. $level';
  }

  @override
  String get merge => 'Fusionner';

  @override
  String get cardDictionary => 'Dictionnaire des Cartes';

  @override
  String get statusCurses => 'STATUTS / MALÉDICTIONS';

  @override
  String eventGainGold(int amount) {
    return '+$amount Or';
  }

  @override
  String eventSpendGold(int amount) {
    return '-$amount Or';
  }

  @override
  String eventLoseHp(int amount) {
    return '-$amount PV';
  }

  @override
  String eventGainHp(int amount) {
    return '+$amount PV';
  }

  @override
  String eventGainMaxHp(int amount) {
    return '+$amount PV Max';
  }

  @override
  String eventGainAttack(int amount) {
    return '+$amount Attaque';
  }

  @override
  String get eventGainRelic => '+1 Relique';
}
