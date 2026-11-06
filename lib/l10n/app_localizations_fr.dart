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
  String get deckReshuffled => 'Défausse remélangée';

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
  String rewardCardFound(String cardName) {
    return '🃏 Carte trouvée : $cardName';
  }

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
  String passiveMasteryCurrent(String effect) {
    return 'Maîtrise : $effect';
  }

  @override
  String passiveMasteryAtStart(int mastery, String effect) {
    String _temp0 = intl.Intl.pluralLogic(
      mastery,
      locale: localeName,
      other: 'Maîtrise $mastery : $effect',
      zero: 'Maîtrise 0 au départ : $effect',
    );
    return '$_temp0';
  }

  @override
  String get passivesLabel => 'Passifs';

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
  String luckLevelRewardSubtitle(String mythicNames) {
    return 'Chances d\'obtenir chaque rareté d\'option lors de la montée de niveau (options mythiques, tirées à part : $mythicNames)';
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
  String get legendBossXp => 'Boss (XP x3)';

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
      'Un combat bien plus rude : une relique garantie, et une carte — parfois deux.';

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
  String get tooltipBossXpDesc =>
      'Le triple d\'XP et d\'or, et une rune de votre deck, si l\'une peut encore monter, gagne un niveau.';

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
  String get tooltipAttackTitle => 'Puissance';

  @override
  String get tooltipAttackDesc =>
      'Renforce ce qu\'oriente votre classe : Attaques, Compétences ou altérations.';

  @override
  String get mightTargetAttackShort => 'Attaques';

  @override
  String get mightTargetSkillShort => 'Compétences';

  @override
  String get mightTargetAlterationShort => 'Altérations';

  @override
  String get mightTargetAttackLong => 'les dégâts de vos Attaques';

  @override
  String get mightTargetSkillLong => 'les dégâts de vos Compétences';

  @override
  String get mightTargetAlterationLong => 'vos altérations';

  @override
  String get listJoinAnd => 'et';

  @override
  String mightTargetsSentence(String targets) {
    return 'Votre Puissance renforce $targets.';
  }

  @override
  String statRuleConvertArmorToMight(int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: 'Son Armure devient de la Puissance pour $duration tours.',
      one: 'Son Armure devient de la Puissance pour un tour.',
    );
    return '$_temp0';
  }

  @override
  String statRuleConvertManaToMight(int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: 'Son Mana devient de la Puissance pour $duration tours.',
      one: 'Son Mana devient de la Puissance pour un tour.',
    );
    return '$_temp0';
  }

  @override
  String statRuleRatioArmor(int percent, int amount, int converted) {
    return 'Taux : $percent%, arrondi à l\'entier supérieur — $amount Armure → $converted Puissance.';
  }

  @override
  String statRuleRatioMana(int percent, int amount, int converted) {
    return 'Taux : $percent%, arrondi à l\'entier supérieur — $amount Mana → $converted Puissance.';
  }

  @override
  String get statRuleArmorToMightTitle => 'ARMURE → PUISSANCE';

  @override
  String get statRuleManaToMightTitle => 'MANA → PUISSANCE';

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
    return 'Buff Puissance : +$value';
  }

  @override
  String get enemyStatsTitle => 'STATS DE L\'ENNEMI';

  @override
  String enemyStatsDesc(int hp, int maxHp, int might, int armor) {
    return 'Santé : $hp/$maxHp PV.\nPuissance : $might.\nArmure : $armor.';
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
  String cardDescStatusMight(int amount, int duration) {
    return 'Gagne $amount Puissance pendant $duration tours.';
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
  String cardDescStatusMightRegen(int amount, int duration) {
    return 'Gagne $amount Éveil de Puissance pendant $duration tours.';
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
  String get continueGame => 'Continuer';

  @override
  String get newGameOverwriteTitle => 'Nouvelle Partie';

  @override
  String get newGameOverwriteMessage =>
      'Une partie est en cours. La démarrer effacera définitivement votre progression actuelle. Continuer ?';

  @override
  String get newGameOverwriteConfirm => 'Écraser et continuer';

  @override
  String get missingItemsTitle => 'Sauvegarde restaurée';

  @override
  String missingItemsMessage(Object items) {
    return 'Certains éléments ne sont plus disponibles suite à une mise à jour et ont été retirés : $items. Votre progression a été conservée.';
  }

  @override
  String get newerSaveTitle => 'Partie d\'une version plus récente';

  @override
  String get newerSaveMessage =>
      'Cette partie a été sauvegardée par une version plus récente du jeu. Elle est conservée : ouvrez cette version pour la reprendre.';

  @override
  String get ok => 'OK';

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
  String get runeCapTitle => 'Choisissez la rune dont le plafond monte';

  @override
  String runeCapLine(int from, int to) {
    return 'Niveau maximal $from → $to';
  }

  @override
  String runeCapRaised(String runeName, int level) {
    return '$runeName peut désormais monter jusqu\'au niveau $level.';
  }

  @override
  String get cardCloned => 'Carte clonée !';

  @override
  String get noCardsInStock => 'Plus de cartes en stock !';

  @override
  String levelLabel(int level) {
    return 'Niv. $level';
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
  String get shopDeckCopy => 'COPIE DE VOTRE DECK';

  @override
  String get shopDeckCopyDesc => 'Même rareté, sans ses runes.';

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
  String get restCampSharpen => 'AFFÛTER';

  @override
  String get restCampSharpenDesc =>
      'Une rune d\'une de vos cartes gagne un niveau, contre de l\'or.';

  @override
  String get restCampSharpenNone =>
      'Aucune rune de votre deck ne peut gagner de niveau.';

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
  String restCampSnackbarSharpen(String runeName, int level, String cardName) {
    return '$runeName passe au niveau $level sur $cardName !';
  }

  @override
  String restCampSnackbarRemove(String cardName) {
    return '$cardName a été retirée du deck.';
  }

  @override
  String get restCampSharpenTitle => 'AFFÛTER UNE RUNE';

  @override
  String get restCampSharpenSubtitle =>
      'Choisissez une carte, puis la rune qui gagne un niveau.';

  @override
  String get forgeNoEligibleRune =>
      'Aucune rune ne peut être ajoutée à cette carte.';

  @override
  String get sharpenNothingOnCard =>
      'Aucune rune de cette carte ne peut gagner de niveau.';

  @override
  String sharpenAction(int cost) {
    return 'Affûter — $cost or';
  }

  @override
  String sharpenLevel(int from, int to) {
    return 'Niveau $from → $to';
  }

  @override
  String get runeMaxLevel => 'Niveau maximal';

  @override
  String get wellTitle => 'PUITS D\'ÉCHANGE';

  @override
  String get wellName => 'Puits d\'échange';

  @override
  String get wellDesc =>
      'Échangez une rune d\'une carte contre une autre, contre de l\'or.';

  @override
  String get wellEmpty =>
      'Aucune carte de votre deck ne porte de rune à échanger.';

  @override
  String get wellPickCard => 'Choisissez une carte, puis la rune à donner.';

  @override
  String get wellNoOption => 'Aucune autre rune ne peut la remplacer.';

  @override
  String wellReceive(int level) {
    return 'Reçue au niveau $level';
  }

  @override
  String wellExchange(int cost) {
    return 'Échanger — $cost or';
  }

  @override
  String wellDone(String oldRune, String newRune, int level) {
    return '$oldRune devient $newRune (niveau $level).';
  }

  @override
  String get wellLeave => 'Quitter le Puits';

  @override
  String get restCampRemoveTitle => 'OUBLIER UNE CARTE';

  @override
  String get restCampRemoveSubtitle =>
      'Choisissez une carte à retirer définitivement de votre deck.';

  @override
  String get draftDeckTitle => 'CONSTITUTION DU DECK';

  @override
  String get draftDeckSubtitle =>
      'Choisissez 2 cartes de votre passif et 3 cartes neutres pour constituer votre deck de départ.';

  @override
  String draftDeckSelectedCount(int count) {
    return 'Cartes sélectionnées : $count / 5';
  }

  @override
  String draftDeckLotSection(String passive) {
    return 'Cartes de $passive';
  }

  @override
  String get draftDeckNeutralSection => 'Cartes neutres';

  @override
  String draftDeckQuota(int picked, int quota) {
    return '$picked/$quota';
  }

  @override
  String get draftDeckProceed => 'ENTRER DANS L\'UMBRA';

  @override
  String draftDeckSnackbarMaxLot(int quota) {
    return 'Vous avez déjà choisi vos $quota cartes de passif.';
  }

  @override
  String draftDeckSnackbarMaxNeutral(int quota) {
    return 'Vous avez déjà choisi vos $quota cartes neutres.';
  }

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
  String mergeRunesLabel(String runes) {
    return 'Runes : $runes';
  }

  @override
  String get mergeRunesNone => 'Runes : aucune';

  @override
  String get fusionRuneTitle => 'FUSION — CHOISISSEZ UNE RUNE';

  @override
  String get fusionRuneSubtitle =>
      'La carte garde les runes de ses trois exemplaires et en reçoit une de plus, au niveau 1.';

  @override
  String get fusionRuneChoose => 'Choisir';

  @override
  String get tooltipRunes => 'Runes :';

  @override
  String statusPoison(int value) {
    return 'Poison : $value';
  }

  @override
  String statusMight(int value) {
    return 'Puissance : +$value';
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
  String statusMightRegen(int value) {
    return 'Éveil de Puissance : +$value';
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
  String eventGainMight(int amount) {
    return '+$amount Puissance';
  }

  @override
  String get eventGainRelic => '+1 Relique';

  @override
  String eventTradeRelic(String relic, int amount) {
    return 'Cède $relic : +$amount Or';
  }

  @override
  String eventGiveRelic(String relic) {
    return 'Cède $relic';
  }

  @override
  String get eventNoRelicToGive => 'Aucune relique à céder';

  @override
  String get eventNoRuneToSharpen => 'Aucune rune à affûter';

  @override
  String eventSharpenRune(int amount) {
    return '+$amount niveau de rune';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get quitGame => 'Quitter';

  @override
  String get audioSection => 'Audio';

  @override
  String get volumeMaster => 'Volume général';

  @override
  String get volumeSfx => 'Bruitages';

  @override
  String get volumeMusic => 'Musique';

  @override
  String get muteAll => 'Couper le son';

  @override
  String signatureCostAndCooldown(int cost, int cooldown) {
    String _temp0 = intl.Intl.pluralLogic(
      cooldown,
      locale: localeName,
      other: '$cooldown tours',
      one: '1 tour',
    );
    return 'Coût : $cost Mana · Recharge : $_temp0';
  }

  @override
  String signatureNextMinor(int level) {
    return 'Prochaine évolution mineure au niveau $level';
  }

  @override
  String signatureNextMajor(int level) {
    return 'Prochaine évolution majeure au niveau $level';
  }

  @override
  String get signatureEvolutionPending => 'Évolution à choisir';

  @override
  String get signatureChooseTarget => 'Choisissez une cible';

  @override
  String signatureTurnsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '1 tour',
    );
    return '$_temp0';
  }

  @override
  String effectValuePercent(int value) {
    return '+$value %';
  }

  @override
  String effectLineDamage(int amount) {
    return 'Inflige $amount dégâts';
  }

  @override
  String effectLineArmor(int amount) {
    return 'Donne $amount d\'Armure';
  }

  @override
  String effectLineHeal(int amount) {
    return 'Soigne $amount PV';
  }

  @override
  String effectLineDraw(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount cartes',
      one: '1 carte',
    );
    return 'Pioche $_temp0';
  }

  @override
  String effectLineGainMana(int amount) {
    return 'Gagne $amount Mana';
  }

  @override
  String effectLineMight(int amount, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: 'pendant $duration tours',
      one: 'ce tour-ci',
    );
    return 'Gagne $amount Puissance $_temp0';
  }

  @override
  String effectLineMightRegen(int amount, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: 'Pendant $duration tours',
      one: 'Pendant 1 tour',
    );
    return '$_temp0, gagne $amount Puissance au début du tour';
  }

  @override
  String effectLineArmorRegen(int amount, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: 'Pendant $duration tours',
      one: 'Pendant 1 tour',
    );
    return '$_temp0, gagne $amount Armure au début du tour';
  }

  @override
  String effectLineWeakness(int amount, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: '$duration tours',
      one: '1 tour',
    );
    return 'Applique $amount Faiblesse pendant $_temp0';
  }

  @override
  String effectLineVulnerable(int amount, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: '$duration tours',
      one: '1 tour',
    );
    return 'Applique $amount Vulnérable pendant $_temp0';
  }

  @override
  String effectLineBurn(int amount, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: '$duration tours',
      one: '1 tour',
    );
    return 'Applique $amount Brûlure pendant $_temp0';
  }

  @override
  String effectLineCrit(int amount) {
    return '+$amount % de critique';
  }

  @override
  String get effectLineAllEnemies => 'Touche tous les ennemis';

  @override
  String evolutionScreenTitle(String signature) {
    return 'Évolution de $signature';
  }

  @override
  String get evolutionScreenTitleBoth => 'Vos signatures évoluent';

  @override
  String get evolutionCurtainTitle => 'ÉVOLUTION';

  @override
  String evolutionCurtainOne(String signature) {
    return '$signature peut évoluer';
  }

  @override
  String get evolutionCurtainBoth => 'Vos signatures peuvent évoluer';

  @override
  String get evolutionCurtainAction => 'TOUCHEZ POUR CHOISIR';

  @override
  String evolutionBoardTierMinor(int level) {
    return 'Évolution mineure · niveau $level du héros';
  }

  @override
  String evolutionBoardTierMajor(int level) {
    return 'Évolution majeure · niveau $level du héros';
  }

  @override
  String get evolutionBoardToChoose => 'À choisir';

  @override
  String evolutionBoardUpcomingMinors(int level) {
    return 'Mineures — au niveau $level';
  }

  @override
  String evolutionBoardUpcomingMajors(int level) {
    return 'Majeures — au niveau $level';
  }

  @override
  String get evolutionBoardTaken => 'Déjà prises';

  @override
  String get evolutionBoardExcluded => 'Exclues';

  @override
  String evolutionBoardExcludedBy(String name) {
    return 'Exclue par $name';
  }

  @override
  String evolutionBoardTakenLevel(int level) {
    return 'Prise · Niv. $level';
  }

  @override
  String evolutionBoardLevelUp(int from, int to, String description) {
    return 'Niveau $from → $to : $description';
  }

  @override
  String get evolutionBoardToday => 'Aujourd\'hui';

  @override
  String get evolutionBoardAfter => 'Après ce choix';

  @override
  String get evolutionBoardPick => 'Choisissez une évolution';

  @override
  String get evolutionBoardPickBoth => 'Choisissez une évolution par signature';

  @override
  String get evolutionBoardTakeBoth => 'Valider les deux';

  @override
  String evolutionBoardTake(String name) {
    return 'Prendre $name';
  }

  @override
  String get signatures => 'Signatures';

  @override
  String statusWeaknessHint(int percent, int max) {
    return '−$percent % de dégâts infligés par point, jusqu\'à −$max %';
  }

  @override
  String statusVulnerableHint(int percent, int max) {
    return '+$percent % de dégâts subis par point, jusqu\'à +$max %';
  }

  @override
  String statusFreezeHint(int percent, int max) {
    return '−$percent % à la prochaine attaque par point, jusqu\'à −$max %';
  }

  @override
  String cardCostHp(int amount) {
    return 'Coûte $amount PV';
  }

  @override
  String cardCostArmor(int amount) {
    return 'Coûte $amount Armure';
  }

  @override
  String cardDescDamageHits(int amount, int hits) {
    return 'Inflige $amount dégâts $hits fois.';
  }

  @override
  String cardScaleArmor(String ratio) {
    return '+$ratio par point d\'Armure';
  }

  @override
  String cardScaleArmorPer(int per) {
    return '+1 par tranche de $per d\'Armure';
  }

  @override
  String cardScaleMissingHp(String ratio) {
    return '+$ratio par PV manquant';
  }

  @override
  String cardScaleMissingHpPer(int per) {
    return '+1 par tranche de $per PV manquants';
  }

  @override
  String cardScaleCardsPlayed(String ratio) {
    return '+$ratio par carte jouée ce tour';
  }

  @override
  String cardScaleCardsPlayedPer(int per) {
    return '+1 par tranche de $per cartes jouées ce tour';
  }

  @override
  String cardScaleEnemiesAlive(String ratio) {
    return '+$ratio par ennemi';
  }

  @override
  String cardScaleEnemiesAlivePer(int per) {
    return '+1 par tranche de $per ennemis';
  }

  @override
  String cardScaleTargetStatus(String ratio, String status) {
    return '+$ratio par point de $status de la cible';
  }

  @override
  String cardScaleTargetStatusPer(int per, String status) {
    return '+1 par tranche de $per points de $status de la cible';
  }

  @override
  String cardScaleTargetMissingHp(String ratio) {
    return '+$ratio par PV manquant de la cible';
  }

  @override
  String cardScaleTargetMissingHpPer(int per) {
    return '+1 par tranche de $per PV manquants de la cible';
  }
}
