import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/starter_deck_draft_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
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
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: [],
    ),
    // Class specific cards (will be auto-added)
    const CardData(
      id: 'holy_shield',
      nameEn: 'Holy Shield',
      nameFr: 'Bouclier Sacré',
      descriptionEn: 'Gain 8 armor and heal 2 HP',
      descriptionFr: 'Gagne 8 armure et soigne 2 PV',
      cost: 2,
      type: CardType.skill,
      category: CardCategory.characterSpecific,
      heroClass: 'paladin',
      rarity: CardRarity.rare,
      target: CardTarget.self,
      effects: [],
    ),
  ];

  final mockHero = const HeroData(
    id: 'paladin',
    nameEn: 'Paladin',
    nameFr: 'Paladin',
    descriptionEn: 'A holy knight',
    descriptionFr: 'Un saint chevalier',
    iconPath: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
    luck: 0,
    armorMastery: 0,
    passiveTrait: 'regenArmor',
    skills: ['holy_shield'],
  );

  final mockPassive = const PassiveData(
    id: 'regenArmor',
    nameEn: 'Armor Regeneration',
    nameFr: "Régénération d'Armure",
    descriptionEn: 'Regen armor each turn',
    descriptionFr: "Régénère l'armure chaque tour",
    trigger: RelicTrigger.endOfTurn,
    effectType: 'gain_armor',
    value: 2,
  );

  final mockRegistry = GameDataRegistry(
    enemies: [],
    heroes: [mockHero],
    cards: mockCards,
    events: [],
    passives: [mockPassive],
    relics: [],
    forgeUpgrades: [],
  );

  testWidgets('StarterDeckDraftScreen allows independent duplicate card selection', (
    WidgetTester tester,
  ) async {
    // Set a large screen size
    tester.view.physicalSize = const Size(1200, 900);
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

    // Since our pool now directly contains all global non-status cards:
    // With 10 mock global cards, the generator will show exactly those 10 cards.
    // Let's verify that 10 cards are shown in the grid.
    expect(find.byType(UiCard), findsNWidgets(10));

    // Tap the first card in the grid (index 0)
    await tester.tap(find.byType(UiCard).at(0));
    await tester.pumpAndSettle();

    // Check that exactly 1 card is selected
    expect(find.text('Cartes sélectionnées : 1 / 5'), findsOneWidget);

    // Tap it again to deselect
    await tester.tap(find.byType(UiCard).at(0));
    await tester.pumpAndSettle();
    expect(find.text('Cartes sélectionnées : 0 / 5'), findsOneWidget);

    // Tap 5 distinct cards in the grid to satisfy the 5 cards requirement
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.byType(UiCard).at(i));
      await tester.pumpAndSettle();
    }

    expect(find.text('Cartes sélectionnées : 5 / 5'), findsOneWidget);

    // Verify the "ENTRER DANS L'UMBRA" button is enabled and we can click it.
    // Wait, the button has the text "ENTRER DANS L'UMBRA"
    final enterButton = find.text("ENTRER DANS L'UMBRA");
    expect(enterButton, findsOneWidget);

    // Let's tap the button to start the adventure!
    await tester.tap(enterButton);
    await tester.pump(const Duration(milliseconds: 500));

    // After starting, the run should be initialized and the deck should contain 6 cards:
    // 5 drafted global cards + 1 class-specific card ('Bouclier Sacré')
    final deckState = container.read(deckProvider);
    expect(deckState.masterDeck.length, 6);

    // The first card should be the class specific card
    expect(deckState.masterDeck[0].data.id, 'holy_shield');

    // The other 5 cards should be Slash or Shield variants
    for (int i = 1; i < 6; i++) {
      final id = deckState.masterDeck[i].data.id;
      expect(id.startsWith('slash') || id.startsWith('shield'), isTrue);
    }
    container.dispose();
  });
}
