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
