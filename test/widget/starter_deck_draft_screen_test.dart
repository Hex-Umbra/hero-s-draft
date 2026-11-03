import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/starter_deck_draft_screen.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/draft/card_draft_layout.dart';

void main() {
  final mockCards = [
    // Global cards for selection
    const CardData(
      id: 'slash_1',
      nameEn: 'Slash 1',
      nameFr: 'Entaille 1',
      descriptionEn: 'Deal 6 damage',
      descriptionFr: 'Inflige 6 dégâts',
      cost: 1,
      type: CardType.attack,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    ),
    const CardData(
      id: 'slash_2',
      nameEn: 'Slash 2',
      nameFr: 'Entaille 2',
      descriptionEn: 'Deal 6 damage',
      descriptionFr: 'Inflige 6 dégâts',
      cost: 1,
      type: CardType.attack,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    ),
    const CardData(
      id: 'slash_3',
      nameEn: 'Slash 3',
      nameFr: 'Entaille 3',
      descriptionEn: 'Deal 6 damage',
      descriptionFr: 'Inflige 6 dégâts',
      cost: 1,
      type: CardType.attack,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    ),
    const CardData(
      id: 'slash_4',
      nameEn: 'Slash 4',
      nameFr: 'Entaille 4',
      descriptionEn: 'Deal 6 damage',
      descriptionFr: 'Inflige 6 dégâts',
      cost: 1,
      type: CardType.attack,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    ),
    const CardData(
      id: 'slash_5',
      nameEn: 'Slash 5',
      nameFr: 'Entaille 5',
      descriptionEn: 'Deal 6 damage',
      descriptionFr: 'Inflige 6 dégâts',
      cost: 1,
      type: CardType.attack,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    ),
    const CardData(
      id: 'shield_1',
      nameEn: 'Shield 1',
      nameFr: 'Bouclier 1',
      descriptionEn: 'Gain 5 armor',
      descriptionFr: 'Gagne 5 armure',
      cost: 1,
      type: CardType.skill,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
    ),
    const CardData(
      id: 'shield_2',
      nameEn: 'Shield 2',
      nameFr: 'Bouclier 2',
      descriptionEn: 'Gain 5 armor',
      descriptionFr: 'Gagne 5 armure',
      cost: 1,
      type: CardType.skill,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
    ),
    const CardData(
      id: 'shield_3',
      nameEn: 'Shield 3',
      nameFr: 'Bouclier 3',
      descriptionEn: 'Gain 5 armor',
      descriptionFr: 'Gagne 5 armure',
      cost: 1,
      type: CardType.skill,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
    ),
    const CardData(
      id: 'shield_4',
      nameEn: 'Shield 4',
      nameFr: 'Bouclier 4',
      descriptionEn: 'Gain 5 armor',
      descriptionFr: 'Gagne 5 armure',
      cost: 1,
      type: CardType.skill,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
    ),
    const CardData(
      id: 'shield_5',
      nameEn: 'Shield 5',
      nameFr: 'Bouclier 5',
      descriptionEn: 'Gain 5 armor',
      descriptionFr: 'Gagne 5 armure',
      cost: 1,
      type: CardType.skill,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
    ),
    // Le lot du passif de l'ecran, et une carte d'un autre lot.
    for (var i = 1; i <= 3; i++)
      CardData(
        id: 'lot_$i',
        nameEn: 'Lot $i',
        nameFr: 'Lot $i',
        descriptionEn: 'Regen card',
        descriptionFr: 'Carte de regen',
        cost: 1,
        type: CardType.skill,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: const [],
        passive: 'regen_armor',
      ),
    const CardData(
      id: 'fervor_1',
      nameEn: 'Fervor 1',
      nameFr: 'Ferveur 1',
      descriptionEn: 'Fervor card',
      descriptionFr: 'Carte de ferveur',
      cost: 1,
      type: CardType.skill,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
      passive: 'fervor',
    ),
  ];

  final mockHero = const HeroData(
    id: 'paladin',
    nameEn: 'Paladin',
    nameFr: 'Paladin',
    descriptionEn: 'A holy knight',
    descriptionFr: 'Un saint chevalier',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    luck: 0,
    mastery: 0,
    skills: ['holy_shield'],
  );

  final mockPassive = const PassiveData(
    id: 'regen_armor',
    nameEn: 'Armor Regeneration',
    nameFr: "Régénération d'Armure",
    descriptionEn: 'Regen armor each turn',
    descriptionFr: "Régénère l'armure chaque tour",
    trigger: RelicTrigger.endOfTurn,
    effectType: 'gain_armor',
    value: 2,
  );

  // Le draft fini, l'écran pousse la carte du monde, dont le panneau du
  // héros lit le palier d'XP : le registre porte une courbe (spec P-43 E3,
  // §8, « Le piège du montage » — le chargeur est résolu à ce moment-là).
  final mockRegistry = GameDataRegistry(
    enemies: [],
    heroes: [mockHero],
    cards: mockCards,
    events: [],
    passives: [mockPassive],
    relics: [],
    forgeUpgrades: [],
    xpCurve: const XpCurveData([115, 200]),
    signatures: const [
      SignatureData(
        id: 'holy_shield',
        heroClass: 'paladin',
        nameEn: 'Holy Shield',
        nameFr: 'Bouclier Sacré',
        cost: 1,
        cooldown: 2,
        type: CardType.skill,
        target: CardTarget.self,
        effects: [],
      ),
    ],
  );

  // Les deux sections sont dans un seul defilement : une fenetre haute les
  // garde toutes a l'ecran, et `tapCard` fait defiler au besoin.
  Future<void> tapCard(WidgetTester tester, int index) async {
    final card = find.byType(UiCard).at(index);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpDraft(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('fr', '')],
          locale: const Locale('fr', ''),
          home: StarterDeckDraftScreen(
            playerClass: mockHero,
            passive: mockPassive,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  AppLocalizations frL10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(CardDraftLayout)))!;

  testWidgets('deux sections titrees, chacune son compteur', (tester) async {
    await pumpDraft(tester);
    final l10n = frL10n(tester);

    expect(
      find.text(l10n.draftDeckLotSection("Régénération d'Armure")),
      findsOneWidget,
    );
    expect(find.text(l10n.draftDeckNeutralSection), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);

    await tapCard(tester, 0);

    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('au-dela d un quota, refus et notification', (tester) async {
    final container = await pumpDraft(tester);
    final l10n = frL10n(tester);
    // L'ecran ne monte pas le GameNotificationOverlay : on lit la file.
    final notifier = container.read(notificationProvider.notifier);
    List<NotificationType> types() =>
        container.read(notificationProvider).map((n) => n.type).toList();
    List<String> messages() =>
        container.read(notificationProvider).map((n) => n.message).toList();

    for (final i in [0, 1, 2]) {
      await tapCard(tester, i);
    }
    expect(find.text('2/2'), findsOneWidget);
    expect(
      tester.widget<UiCard>(find.byType(UiCard).at(2)).isSelected,
      isFalse,
    );
    expect(messages(), [l10n.draftDeckSnackbarMaxLot(2)]);
    expect(types(), [NotificationType.warning]);

    for (final i in [3, 4, 5, 6]) {
      await tapCard(tester, i);
    }
    expect(find.text('3/3'), findsOneWidget);
    expect(
      tester.widget<UiCard>(find.byType(UiCard).at(6)).isSelected,
      isFalse,
    );
    expect(messages().last, l10n.draftDeckSnackbarMaxNeutral(3));
    expect(types().last, NotificationType.warning);

    // Les minuteurs d auto-fermeture ne sont annules que par le dispose.
    notifier.clearAll();
  });

  testWidgets('Valider ne s active qu a 2 + 3', (tester) async {
    await pumpDraft(tester);
    bool enabled() => tester
        .widget<CardDraftLayout>(find.byType(CardDraftLayout))
        .isConfirmEnabled;

    for (final i in [0, 1, 3, 4]) {
      await tapCard(tester, i);
    }
    expect(enabled(), isFalse); // 2 + 2

    await tapCard(tester, 1); // 1 + 2
    await tapCard(tester, 5); // 1 + 3
    expect(enabled(), isFalse);

    await tapCard(tester, 1); // 2 + 3
    expect(enabled(), isTrue);
  });

  testWidgets('StarterDeckDraftScreen allows independent duplicate card selection', (
    WidgetTester tester,
  ) async {
    // Set a large screen size
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
    );
    addTearDown(container.dispose);

    // Build the screen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('fr', '')],
          locale: const Locale('fr', ''),
          home: StarterDeckDraftScreen(
            playerClass: mockHero,
            passive: mockPassive,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 3 cartes du lot de regen_armor puis 10 neutres ; la carte de fervor
    // n'est pas offerte.
    expect(find.byType(UiCard), findsNWidgets(13));

    // Tap the first card in the grid (index 0)
    await tapCard(tester, 0);

    // Check that exactly 1 card is selected
    expect(find.text('Cartes sélectionnées : 1 / 5'), findsOneWidget);

    // Tap it again to deselect
    await tapCard(tester, 0);
    expect(find.text('Cartes sélectionnées : 0 / 5'), findsOneWidget);

    // Deux cartes du lot (indexes 0 et 1) puis trois neutres (3, 4 et 5).
    for (final i in [0, 1, 3, 4, 5]) {
      await tapCard(tester, i);
    }

    expect(find.text('Cartes sélectionnées : 5 / 5'), findsOneWidget);

    // Verify the "ENTRER DANS L'UMBRA" button is enabled and we can click it.
    // Wait, the button has the text "ENTRER DANS L'UMBRA"
    final enterButton = find.text("ENTRER DANS L'UMBRA");
    expect(enterButton, findsOneWidget);

    // Let's tap the button to start the adventure!
    await tester.tap(enterButton);
    await tester.pump(const Duration(milliseconds: 500));

    // Le deck de depart est fait des 5 cartes choisies, rien d'autre : la
    // signature du paladin ('holy_shield') n'est plus une carte du deck.
    final deckState = container.read(deckProvider);
    expect(deckState.masterDeck.length, 5);
    for (final card in deckState.masterDeck) {
      final id = card.data.id;
      expect(
        id.startsWith('slash') || id.startsWith('shield') || id.startsWith('lot'),
        isTrue,
      );
    }
    expect(
      deckState.masterDeck.map((c) => c.data.id),
      ['lot_1', 'lot_2', 'shield_1', 'shield_2', 'shield_3'],
    );
    expect(
      deckState.masterDeck.map((c) => c.data.id),
      isNot(contains('holy_shield')),
    );
    expect(
      container.read(runProvider).signatures.map((s) => s.data.id),
      ['holy_shield'],
    );
    container.dispose();
  });

  testWidgets(
    'le pool du draft de depart est celui d isOfferable : neutres et lot du '
    'passif choisi, jamais un statut',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Le pool porte un statut : il ne doit pas apparaitre au draft. Les
      // signatures ne sont plus des cartes : rien ne peut les y faire figurer.
      final registry = GameDataRegistry(
        enemies: const [],
        heroes: [mockHero],
        cards: [
          ...mockCards,
          const CardData(
            id: 'blessure',
            nameEn: 'Wound',
            nameFr: 'Blessure',
            cost: 1,
            type: CardType.status,
            rarity: CardRarity.common,
            target: CardTarget.self,
            effects: [],
          ),
          // Une carte du lot du passif de l'ecran, une d'un autre lot.
          const CardData(
            id: 'lot_regen',
            nameEn: 'Regen Card',
            nameFr: 'Carte Regen',
            cost: 1,
            type: CardType.skill,
            rarity: CardRarity.common,
            target: CardTarget.self,
            effects: [],
            passive: 'regen_armor',
          ),
          const CardData(
            id: 'lot_fervor',
            nameEn: 'Fervor Card',
            nameFr: 'Carte Ferveur',
            cost: 1,
            type: CardType.skill,
            rarity: CardRarity.common,
            target: CardTarget.self,
            effects: [],
            passive: 'fervor',
          ),
        ],
        events: const [],
        passives: [mockPassive],
        relics: const [],
        forgeUpgrades: const [],
      );

      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', ''), Locale('fr', '')],
            locale: const Locale('fr', ''),
            home: StarterDeckDraftScreen(
              playerClass: mockHero,
              passive: mockPassive,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Finder cardsOf(String section) => find.descendant(
        of: find.byKey(ValueKey(section)),
        matching: find.byType(UiCard),
      );
      expect(cardsOf('starter-draft-lot'), findsNWidgets(4));
      expect(cardsOf('starter-draft-neutral'), findsNWidgets(10));
      expect(find.byType(UiCard), findsNWidgets(14));
      expect(find.text('BOUCLIER SACRÉ'), findsNothing);
      expect(find.text('BLESSURE'), findsNothing);
    },
  );

  testWidgets('the draft is tinted with the themeColor of the class data', (
    WidgetTester tester,
  ) async {
    const gambler = HeroData(
      id: 'gambler',
      nameEn: 'Gambler',
      nameFr: 'Le Parieur',
      classCard: 'assets/data/classes/gambler/gambler.png',
      themeColor: 0xFF00A88F,
      maxHp: 70,
      maxMana: 3,
    );
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('fr', '')],
          locale: const Locale('fr', ''),
          home: const StarterDeckDraftScreen(playerClass: gambler, passive: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final layout = tester.widget<CardDraftLayout>(find.byType(CardDraftLayout));
    expect(layout.themeColor, const Color(0xFF00A88F));
  });
}
