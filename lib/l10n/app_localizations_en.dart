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
  String get deckReshuffled => 'Discard pile reshuffled';

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
  String rewardCardFound(String cardName) {
    return '🃏 Card found: $cardName';
  }

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
  String passiveMasteryCurrent(String effect) {
    return 'Mastery: $effect';
  }

  @override
  String passiveMasteryAtStart(int mastery, String effect) {
    String _temp0 = intl.Intl.pluralLogic(
      mastery,
      locale: localeName,
      other: 'Mastery $mastery: $effect',
      zero: 'Mastery 0 at start: $effect',
    );
    return '$_temp0';
  }

  @override
  String get passivesLabel => 'Passives';

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
  String luckLevelRewardSubtitle(String mythicNames) {
    return 'Chances of getting each option rarity when leveling up (mythic options, rolled separately: $mythicNames)';
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
  String get legendBossCards => 'Boss (Cards Reward)';

  @override
  String get legendBossXp => 'Boss (3x XP)';

  @override
  String get legendBossRelic => 'Boss (Relic Reward)';

  @override
  String get tooltipCombatTitle => 'Normal Combat';

  @override
  String get tooltipCombatDesc =>
      'Face a standard monster to earn cards and gold.';

  @override
  String get tooltipEliteTitle => 'Elite Combat';

  @override
  String get tooltipEliteDesc =>
      'A much tougher fight: a guaranteed relic, and a card — sometimes two.';

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
  String get tooltipBossXpDesc =>
      'Triple XP and gold, and one rune in your deck gains a level, if any still can.';

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
  String get remainingManaWarning => 'Mana remaining.\nEnd your turn?';

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
  String get tooltipAttackTitle => 'Might';

  @override
  String get tooltipAttackDesc =>
      'Strengthens what your class channels it into: Attacks, Skills or alterations.';

  @override
  String get mightTargetAttackShort => 'Attacks';

  @override
  String get mightTargetSkillShort => 'Skills';

  @override
  String get mightTargetAlterationShort => 'Alterations';

  @override
  String get mightTargetAttackLong => 'your Attack damage';

  @override
  String get mightTargetSkillLong => 'your Skill damage';

  @override
  String get mightTargetAlterationLong => 'your alterations';

  @override
  String get listJoinAnd => 'and';

  @override
  String mightTargetsSentence(String targets) {
    return 'Your Might strengthens $targets.';
  }

  @override
  String statRuleConvertArmorToMight(int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: 'Their Armor becomes Might for $duration turns.',
      one: 'Their Armor becomes Might for one turn.',
    );
    return '$_temp0';
  }

  @override
  String statRuleConvertManaToMight(int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      duration,
      locale: localeName,
      other: 'Their Mana becomes Might for $duration turns.',
      one: 'Their Mana becomes Might for one turn.',
    );
    return '$_temp0';
  }

  @override
  String statRuleRatioArmor(int percent, int amount, int converted) {
    return 'Rate: $percent%, rounded up — $amount Armor → $converted Might.';
  }

  @override
  String statRuleRatioMana(int percent, int amount, int converted) {
    return 'Rate: $percent%, rounded up — $amount Mana → $converted Might.';
  }

  @override
  String get statRuleArmorToMightTitle => 'ARMOR → MIGHT';

  @override
  String get statRuleManaToMightTitle => 'MANA → MIGHT';

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
    return 'Buff Might: +$value';
  }

  @override
  String get enemyStatsTitle => 'ENEMY STATS';

  @override
  String enemyStatsDesc(int hp, int maxHp, int might, int armor) {
    return 'Health: $hp/$maxHp HP.\nMight: $might.\nArmor: $armor.';
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
  String cardDescStatusMight(int amount, int duration) {
    return 'Gains $amount Might for $duration turns.';
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
  String cardDescStatusMightRegen(int amount, int duration) {
    return 'Gains $amount Might Awakening for $duration turns.';
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
  String get continueGame => 'Continue';

  @override
  String get newGameOverwriteTitle => 'New Game';

  @override
  String get newGameOverwriteMessage =>
      'A game is currently in progress. Starting a new one will permanently erase your current progress. Continue?';

  @override
  String get newGameOverwriteConfirm => 'Overwrite and continue';

  @override
  String get missingItemsTitle => 'Save restored';

  @override
  String missingItemsMessage(Object items) {
    return 'Some items are no longer available due to an update and have been removed: $items. Your progress has been kept.';
  }

  @override
  String get newerSaveTitle => 'Game from a newer version';

  @override
  String get newerSaveMessage =>
      'This game was saved by a newer version of the game. It has been kept: open that version to resume it.';

  @override
  String get ok => 'OK';

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
  String get runeCapTitle => 'Choose the rune whose cap rises';

  @override
  String runeCapLine(int from, int to) {
    return 'Max level $from → $to';
  }

  @override
  String runeCapRaised(String runeName, int level) {
    return '$runeName can now reach level $level.';
  }

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
  String get shopDeckCopy => 'COPY FROM YOUR DECK';

  @override
  String get shopDeckCopyDesc => 'Same rarity, without its runes.';

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
  String get restCampSharpen => 'SHARPEN';

  @override
  String get restCampSharpenDesc =>
      'One rune on one of your cards gains a level, for gold.';

  @override
  String get restCampSharpenNone => 'No rune in your deck can gain a level.';

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
  String restCampSnackbarSharpen(String runeName, int level, String cardName) {
    return '$runeName reaches level $level on $cardName!';
  }

  @override
  String restCampSnackbarRemove(String cardName) {
    return '$cardName was removed from your deck.';
  }

  @override
  String get restCampSharpenTitle => 'SHARPEN A RUNE';

  @override
  String get restCampSharpenSubtitle =>
      'Choose a card, then the rune that gains a level.';

  @override
  String get forgeNoEligibleRune => 'No rune can be added to this card.';

  @override
  String get sharpenNothingOnCard => 'No rune on this card can gain a level.';

  @override
  String sharpenAction(int cost) {
    return 'Sharpen — $cost gold';
  }

  @override
  String sharpenLevel(int from, int to) {
    return 'Level $from → $to';
  }

  @override
  String get runeMaxLevel => 'Max level';

  @override
  String get wellTitle => 'EXCHANGE WELL';

  @override
  String get wellName => 'Exchange Well';

  @override
  String get wellDesc => 'Swap one of a card\'s runes for another, for gold.';

  @override
  String get wellEmpty => 'No card in your deck carries a rune to swap.';

  @override
  String get wellPickCard => 'Choose a card, then the rune to give up.';

  @override
  String get wellNoOption => 'No other rune can replace it.';

  @override
  String wellReceive(int level) {
    return 'Received at level $level';
  }

  @override
  String wellExchange(int cost) {
    return 'Swap — $cost gold';
  }

  @override
  String wellDone(String oldRune, String newRune, int level) {
    return '$oldRune becomes $newRune (level $level).';
  }

  @override
  String get wellLeave => 'Leave the Well';

  @override
  String get restCampRemoveTitle => 'REMOVE A CARD';

  @override
  String get restCampRemoveSubtitle =>
      'Choose a card to permanently remove from your deck.';

  @override
  String get draftDeckTitle => 'DECK CONSTITUTION';

  @override
  String get draftDeckSubtitle =>
      'Select exactly 5 global cards to build your starting deck and launch the run.';

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
  String mergeRunesLabel(String runes) {
    return 'Runes: $runes';
  }

  @override
  String get mergeRunesNone => 'Runes: none';

  @override
  String get fusionRuneTitle => 'MERGE — CHOOSE A RUNE';

  @override
  String get fusionRuneSubtitle =>
      'The card keeps its three copies\' runes and gains one more, at level 1.';

  @override
  String get fusionRuneChoose => 'Choose';

  @override
  String get tooltipRunes => 'Runes:';

  @override
  String statusPoison(int value) {
    return 'Poison: $value';
  }

  @override
  String statusMight(int value) {
    return 'Might: +$value';
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
  String statusMightRegen(int value) {
    return 'Might Awakening: +$value';
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
  String eventGainMight(int amount) {
    return '+$amount Might';
  }

  @override
  String get eventGainRelic => '+1 Relic';

  @override
  String eventTradeRelic(String relic, int amount) {
    return 'Give up $relic: +$amount Gold';
  }

  @override
  String eventGiveRelic(String relic) {
    return 'Give up $relic';
  }

  @override
  String get eventNoRelicToGive => 'No relic to give up';

  @override
  String eventSharpenRune(int amount) {
    return '+$amount rune level';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get quitGame => 'Quit';

  @override
  String get audioSection => 'Audio';

  @override
  String get volumeMaster => 'Master volume';

  @override
  String get volumeSfx => 'Sound effects';

  @override
  String get volumeMusic => 'Music';

  @override
  String get muteAll => 'Mute all';
}
