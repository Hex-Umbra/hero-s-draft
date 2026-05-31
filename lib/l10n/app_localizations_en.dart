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

  @override
  String get myDeck => 'My Deck';

  @override
  String get stats => 'Stats';

  @override
  String get relics => 'Relics';

  @override
  String get chances => 'Chances';

  @override
  String goldCount(int count) {
    return 'Gold: $count';
  }

  @override
  String get heroStatsTitle => 'Hero Statistics';

  @override
  String get classPassive => 'Class Passive';

  @override
  String get relicInventory => 'Relic Inventory';

  @override
  String get emptyInventory => 'Your inventory is empty';

  @override
  String get luckPercentageTitle => 'Rarity Loot Rates';

  @override
  String currentLuck(int luck) {
    return 'Your Luck: $luck';
  }

  @override
  String get legendTitle => 'LEGEND';

  @override
  String get legendCombat => 'Normal Combat';

  @override
  String get legendElite => 'Elite Combat';

  @override
  String get legendShop => 'Merchant Shop';

  @override
  String get legendRest => 'Rest Camp';

  @override
  String get legendEvent => 'Unknown Event';

  @override
  String get legendBoss => 'Boss Combat';

  @override
  String get tooltipCombatTitle => 'Normal Combat';

  @override
  String get tooltipCombatDesc =>
      'Face a standard monster to earn cards and gold.';

  @override
  String get tooltipEliteTitle => 'Elite Combat';

  @override
  String get tooltipEliteDesc =>
      'A much tougher fight, but guarantees a relic reward.';

  @override
  String get tooltipShopTitle => 'Merchant Shop';

  @override
  String get tooltipShopDesc =>
      'Spend your hard-earned gold to buy cards and potions.';

  @override
  String get tooltipRestTitle => 'Rest Camp';

  @override
  String get tooltipRestDesc => 'Rest to recover 30% of your max HP.';

  @override
  String get tooltipEventTitle => 'Unknown Event';

  @override
  String get tooltipEventDesc =>
      'Who knows what surprises or dangers await here?';

  @override
  String get tooltipBossTitle => 'Boss Combat';

  @override
  String get tooltipBossDesc =>
      'Defeat the guardian of this floor to complete the act!';

  @override
  String actLevel(int act, int level) {
    return 'Act $act - Level: $level';
  }

  @override
  String get playerEffects => 'Player Effects';

  @override
  String get enemyIntents => 'Enemy Intentions';

  @override
  String get noStatusActive => 'No active effect';

  @override
  String get waitingIntents => 'Waiting...';

  @override
  String get manaWarning => 'No mana left.\nEnd your turn?';

  @override
  String turnCount(int count) {
    return 'Turn $count';
  }

  @override
  String get pauseTitle => 'PAUSE';

  @override
  String get backToMainMenu => 'Back to Main Menu';

  @override
  String get relicTriggerRun => 'Run Start';

  @override
  String get relicTriggerCombat => 'Combat Start';

  @override
  String get relicTriggerTurnStart => 'Turn Start';

  @override
  String get relicTriggerTurnEnd => 'Turn End';

  @override
  String get relicTriggerCardPlayed => 'Card Played';

  @override
  String get relicTriggerEnemyKilled => 'Enemy Killed';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityUncommon => 'Uncommon';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String get tooltipHpTitle => 'Hit Points (HP)';

  @override
  String get tooltipHpDesc => 'Your health pool. If it reaches 0, you die.';

  @override
  String get tooltipArmorTitle => 'Block / Armor';

  @override
  String get tooltipArmorDesc =>
      'Absorbs next attacks\' damage. Removed at turn start.';

  @override
  String get tooltipAttackTitle => 'Attack Damage Boost';

  @override
  String get tooltipAttackDesc => 'Increases the damage of your attack cards.';

  @override
  String get tooltipManaTitle => 'Mana';

  @override
  String get tooltipManaDesc => 'Energy resource used to play cards each turn.';

  @override
  String get cardTypeAttack => 'Attack';

  @override
  String get cardTypeSkill => 'Skill';

  @override
  String get cardTypePower => 'Power';

  @override
  String get cardTypeStatus => 'Status';

  @override
  String get oncePlayed => 'ONCE PLAYED';

  @override
  String get exhaustWarning => '⚠️ ONCE PLAYED (Exhaust)';

  @override
  String get hpAbbreviation => 'HP';

  @override
  String get enemyIntentsTitle => 'ENEMY INTENTIONS';

  @override
  String intentDevastatingAttack(int value) {
    return 'Devastating Attack: $value';
  }

  @override
  String intentHeavyAttack(int value) {
    return 'Heavy Attack: $value';
  }

  @override
  String intentAttack(int value) {
    return 'Attack: $value';
  }

  @override
  String intentQuickAttack(int value) {
    return 'Quick Attack: $value';
  }

  @override
  String intentDefend(int value) {
    return 'Defend: +$value';
  }

  @override
  String intentBuff(int value) {
    return 'Buff Attack: +$value';
  }

  @override
  String intentCurse(int value) {
    return 'Curse: $value';
  }

  @override
  String get enemyStatsTitle => 'ENEMY STATS';

  @override
  String enemyStatsDesc(int hp, int maxHp, int attack, int armor) {
    return 'Health: $hp/$maxHp HP.\nAttack: $attack.\nArmor: $armor.';
  }

  @override
  String cardDescDamage(int amount) {
    return 'Deals $amount damage.';
  }

  @override
  String cardDescDamageAll(int amount) {
    return 'Deals $amount damage to all enemies.';
  }

  @override
  String cardDescHeal(int amount) {
    return 'Heals $amount HP.';
  }

  @override
  String cardDescArmor(int amount) {
    return 'Gives $amount Block.';
  }

  @override
  String cardDescGainMana(int amount) {
    return 'Gains $amount Mana.';
  }

  @override
  String cardDescDraw(int amount) {
    return 'Draws $amount cards.';
  }

  @override
  String cardDescStatusStrength(int amount, int duration) {
    return 'Gains $amount ATK for $duration turns.';
  }

  @override
  String cardDescStatusArmorRegen(int amount, int duration) {
    return 'For $duration turns, gains $amount Block at turn start.';
  }

  @override
  String cardDescStatusPoison(int amount) {
    return 'Applies $amount Poison.';
  }

  @override
  String cardDescStatusPoisonDuration(int amount, int duration) {
    return 'Applies $amount Poison for $duration turns.';
  }

  @override
  String cardDescStatusWeakness(int amount) {
    return 'Applies $amount Weakness.';
  }

  @override
  String cardDescStatusWeaknessDuration(int amount, int duration) {
    return 'Applies $amount Weakness for $duration turns.';
  }

  @override
  String cardDescStatusVulnerable(int amount) {
    return 'Applies $amount Vulnerable.';
  }

  @override
  String cardDescStatusVulnerableDuration(int amount, int duration) {
    return 'Applies $amount Vulnerable for $duration turns.';
  }

  @override
  String cardDescStatusStrengthRegen(int amount, int duration) {
    return 'Gains $amount Attack Awakening for $duration turns.';
  }

  @override
  String cardDescStatusBurn(int amount) {
    return 'Applies $amount Burn.';
  }

  @override
  String cardDescStatusBurnDuration(int amount, int duration) {
    return 'Applies $amount Burn for $duration turns.';
  }

  @override
  String cardDescStatusFreeze(int amount) {
    return 'Applies $amount Freeze.';
  }

  @override
  String cardDescStatusFreezeDuration(int amount, int duration) {
    return 'Applies $amount Freeze for $duration turns.';
  }

  @override
  String cardDescStatusShock(int amount) {
    return 'Applies $amount Shock.';
  }

  @override
  String cardDescStatusShockDuration(int amount, int duration) {
    return 'Applies $amount Shock for $duration turns.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get shopExpanded => 'Shop expanded permanently!';

  @override
  String get shopRerolled => 'Cards renewed!';

  @override
  String get chooseCardToPurge => 'Choose a card to purge';

  @override
  String get cardPurged => 'Card purged!';

  @override
  String get chooseCardToClone => 'Choose a card to clone';

  @override
  String get cardCloned => 'Card cloned!';

  @override
  String get noCardsInStock => 'Out of stock!';

  @override
  String levelLabel(int level) {
    return 'Lvl $level';
  }

  @override
  String get shopReroll => 'Reroll';

  @override
  String get shopRerollDesc => 'Reroll cards for sale';

  @override
  String get shopPurge => 'Purge';

  @override
  String get shopPurgeDesc => 'Remove a card from your deck';

  @override
  String get shopExpand => 'Expand Shop';

  @override
  String get shopExpandDesc => 'Permanently add 1 more card for sale';

  @override
  String get shopClone => 'Mirror Magic';

  @override
  String get shopCloneDesc => 'Clone a card from your deck';

  @override
  String get targetSingleEnemy => 'Single enemy';

  @override
  String get targetAllEnemies => 'All enemies';

  @override
  String get targetSelf => 'Self';

  @override
  String get targetNone => 'None';

  @override
  String get restCampTitle => 'REST CAMP';

  @override
  String get restCampSubtitle => 'The crackling fire calms you...';

  @override
  String get restCampRest => 'REST';

  @override
  String restCampRestDesc(int amount) {
    return 'Restores 30% of Max HP ($amount HP)';
  }

  @override
  String get restCampForge => 'FORGE';

  @override
  String get restCampForgeDesc => 'Permanently upgrade a card in your deck.';

  @override
  String get restCampRemove => 'REMOVE';

  @override
  String get restCampRemoveDesc => 'Permanently remove a card from your deck.';

  @override
  String get restCampProceed => 'PROCEED ONWARD';

  @override
  String restCampSnackbarHeal(int amount) {
    return 'Rest complete. You recovered $amount HP.';
  }

  @override
  String restCampSnackbarForge(String cardName, int level) {
    return '$cardName was upgraded to Level $level!';
  }

  @override
  String restCampSnackbarRemove(String cardName) {
    return '$cardName was removed from your deck.';
  }

  @override
  String get restCampForgeTitle => 'FORGE A CARD';

  @override
  String get restCampForgeSubtitle => 'Choose a card to permanently upgrade.';

  @override
  String get restCampRemoveTitle => 'REMOVE A CARD';

  @override
  String get restCampRemoveSubtitle =>
      'Choose a card to permanently remove from your deck.';

  @override
  String get draftDeckTitle => 'DECK CONSTITUTION';

  @override
  String get draftDeckSubtitle =>
      'Select exactly 5 global cards from the 10 offered to launch the run.';

  @override
  String draftDeckSelectedCount(int count) {
    return 'Selected cards: $count / 5';
  }

  @override
  String get draftDeckProceed => 'ENTER THE UMBRA';

  @override
  String get draftDeckSnackbarMax => 'You can only select up to 5 cards.';

  @override
  String mergeLabel(int count) {
    return 'MERGE ($count)';
  }

  @override
  String get mergePossible => 'Merge possible';

  @override
  String mergeMoreRequired(int count) {
    return '$count more required';
  }

  @override
  String get confirmMerge => 'Confirm Merge';

  @override
  String get draftChoiceVitality => 'Vitality';

  @override
  String draftChoiceVitalityDesc(int amount) {
    return '+$amount Max HP';
  }

  @override
  String get draftChoiceSharpening => 'Sharpening';

  @override
  String draftChoiceSharpeningDesc(int amount) {
    return '+$amount Attack';
  }

  @override
  String get draftChoiceSteelForge => 'Steel Forge';

  @override
  String draftChoiceSteelForgeDesc(int amount) {
    return '+$amount to your passive\'s Block gain';
  }

  @override
  String get draftChoiceWisdom => 'Wisdom';

  @override
  String draftChoiceWisdomDesc(int amount) {
    return '+$amount Max Mana';
  }

  @override
  String get draftChoiceClover => '4-Leaf Clover';

  @override
  String draftChoiceCloverDesc(int amount) {
    return '+$amount Luck';
  }

  @override
  String get draftChoiceMirror => 'Mirror';

  @override
  String get draftChoiceMirrorDesc =>
      'Clone a card chosen from 3 random cards in your deck';

  @override
  String statusPoison(int value) {
    return 'Poison: $value';
  }

  @override
  String statusStrength(int value) {
    return 'Attack: +$value';
  }

  @override
  String statusWeakness(int value) {
    return 'Weakness: $value';
  }

  @override
  String statusVulnerable(int value) {
    return 'Vulnerable: $value';
  }

  @override
  String statusStrengthRegen(int value) {
    return 'Attack Awakening: +$value';
  }

  @override
  String statusArmorRegen(int value) {
    return 'Plated Armor: +$value';
  }

  @override
  String statusLifesteal(int value) {
    return 'Lifesteal: $value';
  }

  @override
  String statusTurns(int count) {
    return '$count turns';
  }

  @override
  String deckTotalCards(int count) {
    return 'Total: $count cards';
  }

  @override
  String deckMergeConfirm(String cardName, int level, int nextLevel) {
    return 'Do you want to merge 3 copies of \"$cardName\" (Lvl. $level) to obtain a Lvl. $nextLevel copy?';
  }

  @override
  String deckMergeSuccess(String cardName, int level) {
    return 'Merge successful: $cardName is now Level $level!';
  }

  @override
  String rarityLevel(String rarity, int level) {
    return '$rarity - Lvl. $level';
  }

  @override
  String get merge => 'Merge';

  @override
  String get cardDictionary => 'Card Dictionary';

  @override
  String get statusCurses => 'STATUS / CURSES';

  @override
  String eventGainGold(int amount) {
    return '+$amount Gold';
  }

  @override
  String eventSpendGold(int amount) {
    return '-$amount Gold';
  }

  @override
  String eventLoseHp(int amount) {
    return '-$amount HP';
  }

  @override
  String eventGainHp(int amount) {
    return '+$amount HP';
  }

  @override
  String eventGainMaxHp(int amount) {
    return '+$amount Max HP';
  }

  @override
  String eventGainAttack(int amount) {
    return '+$amount Attack';
  }

  @override
  String get eventGainRelic => '+1 Relic';
}
