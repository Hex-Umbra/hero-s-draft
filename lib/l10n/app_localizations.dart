import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Hero\'s Draft'**
  String get appTitle;

  /// No description provided for @worldMap.
  ///
  /// In en, this message translates to:
  /// **'World Map'**
  String get worldMap;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Choose your Class'**
  String get selectClass;

  /// No description provided for @youAreDead.
  ///
  /// In en, this message translates to:
  /// **'YOU ARE DEAD'**
  String get youAreDead;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenu;

  /// No description provided for @changeClass.
  ///
  /// In en, this message translates to:
  /// **'Change Class'**
  String get changeClass;

  /// No description provided for @currentLevel.
  ///
  /// In en, this message translates to:
  /// **'Current Level'**
  String get currentLevel;

  /// No description provided for @endTurn.
  ///
  /// In en, this message translates to:
  /// **'End Turn'**
  String get endTurn;

  /// No description provided for @drawPile.
  ///
  /// In en, this message translates to:
  /// **'Draw: {count}'**
  String drawPile(int count);

  /// No description provided for @discardPile.
  ///
  /// In en, this message translates to:
  /// **'Discard: {count}'**
  String discardPile(int count);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pause;

  /// No description provided for @resumeCombat.
  ///
  /// In en, this message translates to:
  /// **'Resume Combat'**
  String get resumeCombat;

  /// No description provided for @playerTurn.
  ///
  /// In en, this message translates to:
  /// **'PLAYER TURN'**
  String get playerTurn;

  /// No description provided for @enemyTurn.
  ///
  /// In en, this message translates to:
  /// **'ENEMY TURN'**
  String get enemyTurn;

  /// No description provided for @notEnoughGold.
  ///
  /// In en, this message translates to:
  /// **'Not enough gold!'**
  String get notEnoughGold;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased: {item}'**
  String purchased(String item);

  /// No description provided for @healApplied.
  ///
  /// In en, this message translates to:
  /// **'Healing applied!'**
  String get healApplied;

  /// No description provided for @fullHp.
  ///
  /// In en, this message translates to:
  /// **'You already have max HP!'**
  String get fullHp;

  /// No description provided for @cardsForSale.
  ///
  /// In en, this message translates to:
  /// **'Cards for Sale'**
  String get cardsForSale;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @healingPotion.
  ///
  /// In en, this message translates to:
  /// **'Healing Potion'**
  String get healingPotion;

  /// No description provided for @restoresHp.
  ///
  /// In en, this message translates to:
  /// **'Restores {amount} HP'**
  String restoresHp(int amount);

  /// No description provided for @leaveShop.
  ///
  /// In en, this message translates to:
  /// **'Leave Shop'**
  String get leaveShop;

  /// No description provided for @combatReward.
  ///
  /// In en, this message translates to:
  /// **'COMBAT REWARD'**
  String get combatReward;

  /// No description provided for @chooseUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Choose an upgrade for your hero'**
  String get chooseUpgrade;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next action'**
  String get nextAction;

  /// No description provided for @myDeck.
  ///
  /// In en, this message translates to:
  /// **'My Deck'**
  String get myDeck;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @relics.
  ///
  /// In en, this message translates to:
  /// **'Relics'**
  String get relics;

  /// No description provided for @chances.
  ///
  /// In en, this message translates to:
  /// **'Chances'**
  String get chances;

  /// No description provided for @goldCount.
  ///
  /// In en, this message translates to:
  /// **'Gold: {count}'**
  String goldCount(int count);

  /// No description provided for @heroStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hero Statistics'**
  String get heroStatsTitle;

  /// No description provided for @classPassive.
  ///
  /// In en, this message translates to:
  /// **'Class Passive'**
  String get classPassive;

  /// No description provided for @relicInventory.
  ///
  /// In en, this message translates to:
  /// **'Relic Inventory'**
  String get relicInventory;

  /// No description provided for @emptyInventory.
  ///
  /// In en, this message translates to:
  /// **'Your inventory is empty'**
  String get emptyInventory;

  /// No description provided for @luckPercentageTitle.
  ///
  /// In en, this message translates to:
  /// **'Rarity Loot Rates'**
  String get luckPercentageTitle;

  /// No description provided for @currentLuck.
  ///
  /// In en, this message translates to:
  /// **'Your Luck: {luck}'**
  String currentLuck(int luck);

  /// No description provided for @legendTitle.
  ///
  /// In en, this message translates to:
  /// **'LEGEND'**
  String get legendTitle;

  /// No description provided for @legendCombat.
  ///
  /// In en, this message translates to:
  /// **'Normal Combat'**
  String get legendCombat;

  /// No description provided for @legendElite.
  ///
  /// In en, this message translates to:
  /// **'Elite Combat'**
  String get legendElite;

  /// No description provided for @legendShop.
  ///
  /// In en, this message translates to:
  /// **'Merchant Shop'**
  String get legendShop;

  /// No description provided for @legendRest.
  ///
  /// In en, this message translates to:
  /// **'Rest Camp'**
  String get legendRest;

  /// No description provided for @legendEvent.
  ///
  /// In en, this message translates to:
  /// **'Unknown Event'**
  String get legendEvent;

  /// No description provided for @legendBoss.
  ///
  /// In en, this message translates to:
  /// **'Boss Combat'**
  String get legendBoss;

  /// No description provided for @tooltipCombatTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal Combat'**
  String get tooltipCombatTitle;

  /// No description provided for @tooltipCombatDesc.
  ///
  /// In en, this message translates to:
  /// **'Face a standard monster to earn cards and gold.'**
  String get tooltipCombatDesc;

  /// No description provided for @tooltipEliteTitle.
  ///
  /// In en, this message translates to:
  /// **'Elite Combat'**
  String get tooltipEliteTitle;

  /// No description provided for @tooltipEliteDesc.
  ///
  /// In en, this message translates to:
  /// **'A much tougher fight, but guarantees a relic reward.'**
  String get tooltipEliteDesc;

  /// No description provided for @tooltipShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Merchant Shop'**
  String get tooltipShopTitle;

  /// No description provided for @tooltipShopDesc.
  ///
  /// In en, this message translates to:
  /// **'Spend your hard-earned gold to buy cards and potions.'**
  String get tooltipShopDesc;

  /// No description provided for @tooltipRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest Camp'**
  String get tooltipRestTitle;

  /// No description provided for @tooltipRestDesc.
  ///
  /// In en, this message translates to:
  /// **'Rest to recover 30% of your max HP.'**
  String get tooltipRestDesc;

  /// No description provided for @tooltipEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Event'**
  String get tooltipEventTitle;

  /// No description provided for @tooltipEventDesc.
  ///
  /// In en, this message translates to:
  /// **'Who knows what surprises or dangers await here?'**
  String get tooltipEventDesc;

  /// No description provided for @tooltipBossTitle.
  ///
  /// In en, this message translates to:
  /// **'Boss Combat'**
  String get tooltipBossTitle;

  /// No description provided for @tooltipBossDesc.
  ///
  /// In en, this message translates to:
  /// **'Defeat the guardian of this floor to complete the act!'**
  String get tooltipBossDesc;

  /// No description provided for @actLevel.
  ///
  /// In en, this message translates to:
  /// **'Act {act} - Level: {level}'**
  String actLevel(int act, int level);

  /// No description provided for @playerEffects.
  ///
  /// In en, this message translates to:
  /// **'Player Effects'**
  String get playerEffects;

  /// No description provided for @enemyIntents.
  ///
  /// In en, this message translates to:
  /// **'Enemy Intentions'**
  String get enemyIntents;

  /// No description provided for @noStatusActive.
  ///
  /// In en, this message translates to:
  /// **'No active effect'**
  String get noStatusActive;

  /// No description provided for @waitingIntents.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get waitingIntents;

  /// No description provided for @manaWarning.
  ///
  /// In en, this message translates to:
  /// **'No mana left.\nEnd your turn?'**
  String get manaWarning;

  /// No description provided for @turnCount.
  ///
  /// In en, this message translates to:
  /// **'Turn {count}'**
  String turnCount(int count);

  /// No description provided for @pauseTitle.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pauseTitle;

  /// No description provided for @backToMainMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Main Menu'**
  String get backToMainMenu;

  /// No description provided for @relicTriggerRun.
  ///
  /// In en, this message translates to:
  /// **'Run Start'**
  String get relicTriggerRun;

  /// No description provided for @relicTriggerCombat.
  ///
  /// In en, this message translates to:
  /// **'Combat Start'**
  String get relicTriggerCombat;

  /// No description provided for @relicTriggerTurnStart.
  ///
  /// In en, this message translates to:
  /// **'Turn Start'**
  String get relicTriggerTurnStart;

  /// No description provided for @relicTriggerTurnEnd.
  ///
  /// In en, this message translates to:
  /// **'Turn End'**
  String get relicTriggerTurnEnd;

  /// No description provided for @relicTriggerCardPlayed.
  ///
  /// In en, this message translates to:
  /// **'Card Played'**
  String get relicTriggerCardPlayed;

  /// No description provided for @relicTriggerEnemyKilled.
  ///
  /// In en, this message translates to:
  /// **'Enemy Killed'**
  String get relicTriggerEnemyKilled;

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityUncommon.
  ///
  /// In en, this message translates to:
  /// **'Uncommon'**
  String get rarityUncommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get rarityLegendary;

  /// No description provided for @tooltipHpTitle.
  ///
  /// In en, this message translates to:
  /// **'Hit Points (HP)'**
  String get tooltipHpTitle;

  /// No description provided for @tooltipHpDesc.
  ///
  /// In en, this message translates to:
  /// **'Your health pool. If it reaches 0, you die.'**
  String get tooltipHpDesc;

  /// No description provided for @tooltipArmorTitle.
  ///
  /// In en, this message translates to:
  /// **'Block / Armor'**
  String get tooltipArmorTitle;

  /// No description provided for @tooltipArmorDesc.
  ///
  /// In en, this message translates to:
  /// **'Absorbs next attacks\' damage. Removed at turn start.'**
  String get tooltipArmorDesc;

  /// No description provided for @tooltipAttackTitle.
  ///
  /// In en, this message translates to:
  /// **'Attack Damage Boost'**
  String get tooltipAttackTitle;

  /// No description provided for @tooltipAttackDesc.
  ///
  /// In en, this message translates to:
  /// **'Increases the damage of your attack cards.'**
  String get tooltipAttackDesc;

  /// No description provided for @tooltipManaTitle.
  ///
  /// In en, this message translates to:
  /// **'Mana'**
  String get tooltipManaTitle;

  /// No description provided for @tooltipManaDesc.
  ///
  /// In en, this message translates to:
  /// **'Energy resource used to play cards each turn.'**
  String get tooltipManaDesc;

  /// No description provided for @cardTypeAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get cardTypeAttack;

  /// No description provided for @cardTypeSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get cardTypeSkill;

  /// No description provided for @cardTypePower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get cardTypePower;

  /// No description provided for @cardTypeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get cardTypeStatus;

  /// No description provided for @oncePlayed.
  ///
  /// In en, this message translates to:
  /// **'ONCE PLAYED'**
  String get oncePlayed;

  /// No description provided for @exhaustWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ ONCE PLAYED (Exhaust)'**
  String get exhaustWarning;

  /// No description provided for @hpAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get hpAbbreviation;

  /// No description provided for @enemyIntentsTitle.
  ///
  /// In en, this message translates to:
  /// **'ENEMY INTENTIONS'**
  String get enemyIntentsTitle;

  /// No description provided for @intentDevastatingAttack.
  ///
  /// In en, this message translates to:
  /// **'Devastating Attack: {value}'**
  String intentDevastatingAttack(int value);

  /// No description provided for @intentHeavyAttack.
  ///
  /// In en, this message translates to:
  /// **'Heavy Attack: {value}'**
  String intentHeavyAttack(int value);

  /// No description provided for @intentAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack: {value}'**
  String intentAttack(int value);

  /// No description provided for @intentQuickAttack.
  ///
  /// In en, this message translates to:
  /// **'Quick Attack: {value}'**
  String intentQuickAttack(int value);

  /// No description provided for @intentDefend.
  ///
  /// In en, this message translates to:
  /// **'Defend: +{value}'**
  String intentDefend(int value);

  /// No description provided for @intentBuff.
  ///
  /// In en, this message translates to:
  /// **'Buff Attack: +{value}'**
  String intentBuff(int value);

  /// No description provided for @intentCurse.
  ///
  /// In en, this message translates to:
  /// **'Curse: {value}'**
  String intentCurse(int value);

  /// No description provided for @enemyStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'ENEMY STATS'**
  String get enemyStatsTitle;

  /// No description provided for @enemyStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Health: {hp}/{maxHp} HP.\nAttack: {attack}.\nArmor: {armor}.'**
  String enemyStatsDesc(int hp, int maxHp, int attack, int armor);

  /// No description provided for @cardDescDamage.
  ///
  /// In en, this message translates to:
  /// **'Deals {amount} damage.'**
  String cardDescDamage(int amount);

  /// No description provided for @cardDescDamageAll.
  ///
  /// In en, this message translates to:
  /// **'Deals {amount} damage to all enemies.'**
  String cardDescDamageAll(int amount);

  /// No description provided for @cardDescHeal.
  ///
  /// In en, this message translates to:
  /// **'Heals {amount} HP.'**
  String cardDescHeal(int amount);

  /// No description provided for @cardDescArmor.
  ///
  /// In en, this message translates to:
  /// **'Gives {amount} Block.'**
  String cardDescArmor(int amount);

  /// No description provided for @cardDescGainMana.
  ///
  /// In en, this message translates to:
  /// **'Gains {amount} Mana.'**
  String cardDescGainMana(int amount);

  /// No description provided for @cardDescDraw.
  ///
  /// In en, this message translates to:
  /// **'Draws {amount} cards.'**
  String cardDescDraw(int amount);

  /// No description provided for @cardDescStatusStrength.
  ///
  /// In en, this message translates to:
  /// **'Gains {amount} ATK for {duration} turns.'**
  String cardDescStatusStrength(int amount, int duration);

  /// No description provided for @cardDescStatusArmorRegen.
  ///
  /// In en, this message translates to:
  /// **'For {duration} turns, gains {amount} Block at turn start.'**
  String cardDescStatusArmorRegen(int amount, int duration);

  /// No description provided for @cardDescStatusPoison.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Poison.'**
  String cardDescStatusPoison(int amount);

  /// No description provided for @cardDescStatusPoisonDuration.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Poison for {duration} turns.'**
  String cardDescStatusPoisonDuration(int amount, int duration);

  /// No description provided for @cardDescStatusWeakness.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Weakness.'**
  String cardDescStatusWeakness(int amount);

  /// No description provided for @cardDescStatusWeaknessDuration.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Weakness for {duration} turns.'**
  String cardDescStatusWeaknessDuration(int amount, int duration);

  /// No description provided for @cardDescStatusVulnerable.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Vulnerable.'**
  String cardDescStatusVulnerable(int amount);

  /// No description provided for @cardDescStatusVulnerableDuration.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Vulnerable for {duration} turns.'**
  String cardDescStatusVulnerableDuration(int amount, int duration);

  /// No description provided for @cardDescStatusStrengthRegen.
  ///
  /// In en, this message translates to:
  /// **'Gains {amount} Attack Awakening for {duration} turns.'**
  String cardDescStatusStrengthRegen(int amount, int duration);

  /// No description provided for @cardDescStatusBurn.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Burn.'**
  String cardDescStatusBurn(int amount);

  /// No description provided for @cardDescStatusBurnDuration.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Burn for {duration} turns.'**
  String cardDescStatusBurnDuration(int amount, int duration);

  /// No description provided for @cardDescStatusFreeze.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Freeze.'**
  String cardDescStatusFreeze(int amount);

  /// No description provided for @cardDescStatusFreezeDuration.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Freeze for {duration} turns.'**
  String cardDescStatusFreezeDuration(int amount, int duration);

  /// No description provided for @cardDescStatusShock.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Shock.'**
  String cardDescStatusShock(int amount);

  /// No description provided for @cardDescStatusShockDuration.
  ///
  /// In en, this message translates to:
  /// **'Applies {amount} Shock for {duration} turns.'**
  String cardDescStatusShockDuration(int amount, int duration);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @shopExpanded.
  ///
  /// In en, this message translates to:
  /// **'Shop expanded permanently!'**
  String get shopExpanded;

  /// No description provided for @shopRerolled.
  ///
  /// In en, this message translates to:
  /// **'Cards renewed!'**
  String get shopRerolled;

  /// No description provided for @chooseCardToPurge.
  ///
  /// In en, this message translates to:
  /// **'Choose a card to purge'**
  String get chooseCardToPurge;

  /// No description provided for @cardPurged.
  ///
  /// In en, this message translates to:
  /// **'Card purged!'**
  String get cardPurged;

  /// No description provided for @chooseCardToClone.
  ///
  /// In en, this message translates to:
  /// **'Choose a card to clone'**
  String get chooseCardToClone;

  /// No description provided for @cardCloned.
  ///
  /// In en, this message translates to:
  /// **'Card cloned!'**
  String get cardCloned;

  /// No description provided for @noCardsInStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock!'**
  String get noCardsInStock;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Lvl {level}'**
  String levelLabel(int level);

  /// No description provided for @shopReroll.
  ///
  /// In en, this message translates to:
  /// **'Reroll'**
  String get shopReroll;

  /// No description provided for @shopRerollDesc.
  ///
  /// In en, this message translates to:
  /// **'Reroll cards for sale'**
  String get shopRerollDesc;

  /// No description provided for @shopPurge.
  ///
  /// In en, this message translates to:
  /// **'Purge'**
  String get shopPurge;

  /// No description provided for @shopPurgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove a card from your deck'**
  String get shopPurgeDesc;

  /// No description provided for @shopExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand Shop'**
  String get shopExpand;

  /// No description provided for @shopExpandDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently add 1 more card for sale'**
  String get shopExpandDesc;

  /// No description provided for @shopClone.
  ///
  /// In en, this message translates to:
  /// **'Mirror Magic'**
  String get shopClone;

  /// No description provided for @shopCloneDesc.
  ///
  /// In en, this message translates to:
  /// **'Clone a card from your deck'**
  String get shopCloneDesc;

  /// No description provided for @targetSingleEnemy.
  ///
  /// In en, this message translates to:
  /// **'Single enemy'**
  String get targetSingleEnemy;

  /// No description provided for @targetAllEnemies.
  ///
  /// In en, this message translates to:
  /// **'All enemies'**
  String get targetAllEnemies;

  /// No description provided for @targetSelf.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get targetSelf;

  /// No description provided for @targetNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get targetNone;

  /// No description provided for @restCampTitle.
  ///
  /// In en, this message translates to:
  /// **'REST CAMP'**
  String get restCampTitle;

  /// No description provided for @restCampSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The crackling fire calms you...'**
  String get restCampSubtitle;

  /// No description provided for @restCampRest.
  ///
  /// In en, this message translates to:
  /// **'REST'**
  String get restCampRest;

  /// No description provided for @restCampRestDesc.
  ///
  /// In en, this message translates to:
  /// **'Restores 30% of Max HP ({amount} HP)'**
  String restCampRestDesc(int amount);

  /// No description provided for @restCampForge.
  ///
  /// In en, this message translates to:
  /// **'FORGE'**
  String get restCampForge;

  /// No description provided for @restCampForgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently upgrade a card in your deck.'**
  String get restCampForgeDesc;

  /// No description provided for @restCampRemove.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get restCampRemove;

  /// No description provided for @restCampRemoveDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove a card from your deck.'**
  String get restCampRemoveDesc;

  /// No description provided for @restCampProceed.
  ///
  /// In en, this message translates to:
  /// **'PROCEED ONWARD'**
  String get restCampProceed;

  /// No description provided for @restCampSnackbarHeal.
  ///
  /// In en, this message translates to:
  /// **'Rest complete. You recovered {amount} HP.'**
  String restCampSnackbarHeal(int amount);

  /// No description provided for @restCampSnackbarForge.
  ///
  /// In en, this message translates to:
  /// **'{cardName} was upgraded to Level {level}!'**
  String restCampSnackbarForge(String cardName, int level);

  /// No description provided for @restCampSnackbarRemove.
  ///
  /// In en, this message translates to:
  /// **'{cardName} was removed from your deck.'**
  String restCampSnackbarRemove(String cardName);

  /// No description provided for @restCampForgeTitle.
  ///
  /// In en, this message translates to:
  /// **'FORGE A CARD'**
  String get restCampForgeTitle;

  /// No description provided for @restCampForgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a card to permanently upgrade.'**
  String get restCampForgeSubtitle;

  /// No description provided for @restCampRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'REMOVE A CARD'**
  String get restCampRemoveTitle;

  /// No description provided for @restCampRemoveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a card to permanently remove from your deck.'**
  String get restCampRemoveSubtitle;

  /// No description provided for @draftDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'DECK CONSTITUTION'**
  String get draftDeckTitle;

  /// No description provided for @draftDeckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select exactly 5 global cards from the 10 offered to launch the run.'**
  String get draftDeckSubtitle;

  /// No description provided for @draftDeckSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected cards: {count} / 5'**
  String draftDeckSelectedCount(int count);

  /// No description provided for @draftDeckProceed.
  ///
  /// In en, this message translates to:
  /// **'ENTER THE UMBRA'**
  String get draftDeckProceed;

  /// No description provided for @draftDeckSnackbarMax.
  ///
  /// In en, this message translates to:
  /// **'You can only select up to 5 cards.'**
  String get draftDeckSnackbarMax;

  /// No description provided for @mergeLabel.
  ///
  /// In en, this message translates to:
  /// **'MERGE ({count})'**
  String mergeLabel(int count);

  /// No description provided for @mergePossible.
  ///
  /// In en, this message translates to:
  /// **'Merge possible'**
  String get mergePossible;

  /// No description provided for @mergeMoreRequired.
  ///
  /// In en, this message translates to:
  /// **'{count} more required'**
  String mergeMoreRequired(int count);

  /// No description provided for @confirmMerge.
  ///
  /// In en, this message translates to:
  /// **'Confirm Merge'**
  String get confirmMerge;

  /// No description provided for @draftChoiceVitality.
  ///
  /// In en, this message translates to:
  /// **'Vitality'**
  String get draftChoiceVitality;

  /// No description provided for @draftChoiceVitalityDesc.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Max HP'**
  String draftChoiceVitalityDesc(int amount);

  /// No description provided for @draftChoiceSharpening.
  ///
  /// In en, this message translates to:
  /// **'Sharpening'**
  String get draftChoiceSharpening;

  /// No description provided for @draftChoiceSharpeningDesc.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Attack'**
  String draftChoiceSharpeningDesc(int amount);

  /// No description provided for @draftChoiceSteelForge.
  ///
  /// In en, this message translates to:
  /// **'Steel Forge'**
  String get draftChoiceSteelForge;

  /// No description provided for @draftChoiceSteelForgeDesc.
  ///
  /// In en, this message translates to:
  /// **'+{amount} to your passive\'s Block gain'**
  String draftChoiceSteelForgeDesc(int amount);

  /// No description provided for @draftChoiceWisdom.
  ///
  /// In en, this message translates to:
  /// **'Wisdom'**
  String get draftChoiceWisdom;

  /// No description provided for @draftChoiceWisdomDesc.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Max Mana'**
  String draftChoiceWisdomDesc(int amount);

  /// No description provided for @draftChoiceClover.
  ///
  /// In en, this message translates to:
  /// **'4-Leaf Clover'**
  String get draftChoiceClover;

  /// No description provided for @draftChoiceCloverDesc.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Luck'**
  String draftChoiceCloverDesc(int amount);

  /// No description provided for @draftChoiceMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get draftChoiceMirror;

  /// No description provided for @draftChoiceMirrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Clone a card chosen from 3 random cards in your deck'**
  String get draftChoiceMirrorDesc;

  /// No description provided for @statusPoison.
  ///
  /// In en, this message translates to:
  /// **'Poison: {value}'**
  String statusPoison(int value);

  /// No description provided for @statusStrength.
  ///
  /// In en, this message translates to:
  /// **'Attack: +{value}'**
  String statusStrength(int value);

  /// No description provided for @statusWeakness.
  ///
  /// In en, this message translates to:
  /// **'Weakness: {value}'**
  String statusWeakness(int value);

  /// No description provided for @statusVulnerable.
  ///
  /// In en, this message translates to:
  /// **'Vulnerable: {value}'**
  String statusVulnerable(int value);

  /// No description provided for @statusStrengthRegen.
  ///
  /// In en, this message translates to:
  /// **'Attack Awakening: +{value}'**
  String statusStrengthRegen(int value);

  /// No description provided for @statusArmorRegen.
  ///
  /// In en, this message translates to:
  /// **'Plated Armor: +{value}'**
  String statusArmorRegen(int value);

  /// No description provided for @statusLifesteal.
  ///
  /// In en, this message translates to:
  /// **'Lifesteal: {value}'**
  String statusLifesteal(int value);

  /// No description provided for @statusTurns.
  ///
  /// In en, this message translates to:
  /// **'{count} turns'**
  String statusTurns(int count);

  /// No description provided for @deckTotalCards.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} cards'**
  String deckTotalCards(int count);

  /// No description provided for @deckMergeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to merge 3 copies of \"{cardName}\" (Lvl. {level}) to obtain a Lvl. {nextLevel} copy?'**
  String deckMergeConfirm(String cardName, int level, int nextLevel);

  /// No description provided for @deckMergeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Merge successful: {cardName} is now Level {level}!'**
  String deckMergeSuccess(String cardName, int level);

  /// No description provided for @rarityLevel.
  ///
  /// In en, this message translates to:
  /// **'{rarity} - Lvl. {level}'**
  String rarityLevel(String rarity, int level);

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @cardDictionary.
  ///
  /// In en, this message translates to:
  /// **'Card Dictionary'**
  String get cardDictionary;

  /// No description provided for @statusCurses.
  ///
  /// In en, this message translates to:
  /// **'STATUS / CURSES'**
  String get statusCurses;

  /// No description provided for @eventGainGold.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Gold'**
  String eventGainGold(int amount);

  /// No description provided for @eventSpendGold.
  ///
  /// In en, this message translates to:
  /// **'-{amount} Gold'**
  String eventSpendGold(int amount);

  /// No description provided for @eventLoseHp.
  ///
  /// In en, this message translates to:
  /// **'-{amount} HP'**
  String eventLoseHp(int amount);

  /// No description provided for @eventGainHp.
  ///
  /// In en, this message translates to:
  /// **'+{amount} HP'**
  String eventGainHp(int amount);

  /// No description provided for @eventGainMaxHp.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Max HP'**
  String eventGainMaxHp(int amount);

  /// No description provided for @eventGainAttack.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Attack'**
  String eventGainAttack(int amount);

  /// No description provided for @eventGainRelic.
  ///
  /// In en, this message translates to:
  /// **'+1 Relic'**
  String get eventGainRelic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
