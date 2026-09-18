import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/class_selection_screen.dart';
import 'package:roguelike_card_game/ui/screens/starter_deck_draft_screen.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/class_identity.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/might_target.dart';

const _heroes = [
  HeroData(
    id: 'paladin',
    nameEn: 'Paladin',
    nameFr: 'Le Paladin',
    descriptionEn: 'Survival Oriented',
    descriptionFr: 'Orienté Survie',
    classCard: 'hero_paladin.png',
    maxHp: 100,
    maxMana: 3,
    // Declared first but sorts last: keeps the grid order dependent on
    // displayOrder rather than on declaration order or List.sort stability.
    displayOrder: 3,
  ),
  HeroData(
    id: 'berserker',
    nameEn: 'Berserker',
    nameFr: 'Le Berserker',
    descriptionEn: 'Damage Oriented',
    descriptionFr: 'Orienté Dégâts',
    classCard: 'hero_berserker.png',
    maxHp: 80,
    maxMana: 3,
    // Declared second and sorts first (lowest displayOrder).
    displayOrder: 1,
  ),
  HeroData(
    id: 'mage',
    nameEn: 'Mage',
    nameFr: 'Le Mage',
    descriptionEn: 'Alteration Oriented',
    descriptionFr: 'Orienté Altération',
    classCard: 'hero_mage.png',
    maxHp: 60,
    maxMana: 3,
    // Declared third and sorts in the middle.
    displayOrder: 2,
  ),
];

// Mock registry so ClassSelectionScreen (which calls `.requireValue` on
// gameDataLoaderProvider) can build without loading real JSON assets.
GameDataRegistry _registryOf(
  List<HeroData> heroes, {
  List<PassiveData> passives = const [],
}) => GameDataRegistry(
  enemies: const [],
  heroes: heroes,
  cards: const [],
  events: const [],
  passives: passives,
  relics: const [],
  forgeUpgrades: const [],
);

Future<ProviderContainer> _buildAndReady(
  WidgetTester tester, {
  Locale locale = const Locale('en', ''),
  List<HeroData> heroes = _heroes,
  List<PassiveData> passives = const [],
}) async {
  // GridView.builder only lays out visible children. The default test
  // surface (800x600) fits just one row of hero cards at the desktop
  // breakpoint, hiding the 3rd (Mage). Widen the surface so all seeded
  // heroes are simultaneously visible without needing to scroll.
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      gameDataLoaderProvider.overrideWith(
        (ref) => _registryOf(heroes, passives: passives),
      ),
    ],
  );
  addTearDown(container.dispose);

  // Ensure the FutureProvider has resolved before pumping, since the screen
  // calls `.requireValue` synchronously during build.
  await container.read(gameDataLoaderProvider.future);

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
        locale: locale,
        home: const ClassSelectionScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  return container;
}

void main() {
  testWidgets('ClassSelectionScreen renders all seeded hero options', (
    WidgetTester tester,
  ) async {
    await _buildAndReady(tester);

    expect(find.text('Paladin'), findsOneWidget);
    expect(find.text('Berserker'), findsOneWidget);
    expect(find.text('Mage'), findsOneWidget);
    // One "Select" button per hero card.
    expect(find.text('Select'), findsNWidgets(_heroes.length));
  });

  testWidgets('aucune classe n affiche de degats de base', (
    WidgetTester tester,
  ) async {
    // L'ecran affichait `playerClass.baseDamage` — 5 / 15 / 10 — alors que
    // toute run demarre a 0 (spec P-41, §8.3). Le champ n'existe plus ; ce
    // test empeche qu'un chiffre equivalent revienne.
    await _buildAndReady(tester);

    for (final chiffre in ['5', '15', '10']) {
      expect(find.text(chiffre), findsNothing);
    }
  });

  testWidgets(
    'Tapping a hero card navigates to StarterDeckDraftScreen with that hero',
    (WidgetTester tester) async {
      await _buildAndReady(tester);

      expect(find.byType(ClassSelectionScreen), findsOneWidget);
      expect(find.byType(StarterDeckDraftScreen), findsNothing);

      // Tap the Berserker card's "Select" button. _heroes is declared
      // paladin/berserker/mage, but each has a distinct displayOrder
      // (3/1/2), so the screen's sort renders berserker first (grid index
      // 0) — not the declaration order and not the index the old
      // equal-displayOrder mocks happened to preserve. Asserting at index 0
      // rather than the middle index 1 matters: for a 3-item list,
      // reversing the comparator swaps the first and last positions but
      // leaves the middle position unchanged, so only index 0 (or 2) can
      // actually catch a reversed or removed sort. ClassSelectionScreen
      // itself doesn't call startNewRun (that happens later, inside
      // StarterDeckDraftScreen's "start adventure" flow) — what it owns is
      // navigating onward with the tapped hero, which we verify via the
      // pushed screen's data.
      await tester.tap(find.text('Select').at(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ClassSelectionScreen), findsNothing);
      expect(find.byType(StarterDeckDraftScreen), findsOneWidget);

      final pushedScreen = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushedScreen.playerClass.id, 'berserker');
    },
  );

  group('class identity is read from the data', () {
    testWidgets('a class unknown to the code shows its own themeColor', (
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
      await _buildAndReady(tester, heroes: const [gambler]);

      final name = tester.widget<Text>(find.text('Gambler'));
      expect(name.style?.color, const Color(0xFF00A88F));
    });

    testWidgets('a known id without themeColor gets no special colour', (
      WidgetTester tester,
    ) async {
      // Proves the id-based branches are gone: 'berserker' used to be forced
      // to red whatever its data said.
      const berserker = HeroData(
        id: 'berserker',
        nameEn: 'Berserker',
        classCard: 'assets/data/classes/berserker/berserker.png',
        maxHp: 80,
        maxMana: 3,
      );
      await _buildAndReady(tester, heroes: const [berserker]);

      final name = tester.widget<Text>(find.text('Berserker'));
      expect(name.style?.color, ClassIdentity.fallbackColor);
    });

    testWidgets('each class shows its image, not a coded icon', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(tester);

      expect(find.byType(ClassAvatar), findsNWidgets(_heroes.length));
      for (final coded in [Icons.whatshot, Icons.auto_fix_high, Icons.person]) {
        expect(find.byIcon(coded), findsNothing);
      }
    });
  });

  testWidgets('ClassSelectionScreen shows French labels when locale is fr', (
    WidgetTester tester,
  ) async {
    await _buildAndReady(tester, locale: const Locale('fr', ''));

    // PageHeader upper-cases its title.
    expect(find.text('CHOISISSEZ VOTRE CLASSE'), findsOneWidget);
    expect(find.text('Le Paladin'), findsOneWidget);
    expect(find.text('Sélectionner'), findsNWidgets(_heroes.length));
  });

  group('le passif montre est lu par le point d acces unique', () {
    const ward = PassiveData(
      id: 'ward',
      nameEn: 'Ward',
      nameFr: 'Garde',
      classes: ['paladin'],
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
    );
    const aegis = PassiveData(
      id: 'aegis',
      nameEn: 'Aegis',
      nameFr: 'Egide',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 1,
    );

    testWidgets('seule la classe que le passif declare le montre', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(tester, passives: const [ward]);
      expect(find.text('WARD'), findsOneWidget);
    });

    testWidgets(
      'un passif ouvert a toutes les classes est montre sur chacune',
      (WidgetTester tester) async {
        await _buildAndReady(tester, passives: const [ward, aegis]);
        // Egide (aegis) ne restreint aucune classe : elle apparait sur les
        // trois cartes. Garde (ward) ne s'ouvre qu'au paladin, qui a donc
        // deux passifs proposes ; les deux autres classes n'en ont qu'un.
        expect(find.text('AEGIS'), findsNWidgets(3));
        expect(find.text('WARD'), findsOneWidget);
      },
    );

    testWidgets('le passif dit ce qu un point de Maitrise lui apporte', (
      WidgetTester tester,
    ) async {
      const regen = PassiveData(
        id: 'regen_armor',
        nameEn: 'Armor Regeneration',
        nameFr: "Régénération d'Armure",
        classes: ['paladin'],
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} Block at end of turn',
          descriptionFr: '+{amount} Armure en fin de tour',
        ),
      );
      await _buildAndReady(tester, passives: const [regen]);
      expect(
        find.text('Per Mastery point: +1 Block at end of turn'),
        findsOneWidget,
      );
    });
  });

  group('l identite de la classe est generee depuis sa donnee', () {
    const berserker = HeroData(
      id: 'berserker',
      nameEn: 'Berserker',
      nameFr: 'Le Berserker',
      classCard: 'hero_berserker.png',
      maxHp: 80,
      maxMana: 3,
      critChance: 10,
      mightTargets: {MightTarget.attack},
      statRules: [
        StatRule(
          stat: RuleStat.armor,
          mode: RuleMode.convert,
          to: RuleTarget.statusMight,
          duration: 1,
        ),
      ],
    );

    const mage = HeroData(
      id: 'mage',
      nameEn: 'Mage',
      nameFr: 'Le Mage',
      classCard: 'hero_mage.png',
      maxHp: 60,
      maxMana: 3,
      mightTargets: {MightTarget.skill, MightTarget.alteration},
    );

    const paladin = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Le Paladin',
      classCard: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      mastery: 1,
      mightTargets: {MightTarget.attack, MightTarget.skill, MightTarget.alteration},
    );

    testWidgets('ce que renforce la Puissance est ecrit en toutes lettres', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [mage],
        locale: const Locale('fr', ''),
      );

      expect(
        find.text(
          'Votre Puissance renforce les dégâts de vos Compétences et vos '
          'altérations.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('la regle de stat est ecrite en clair, et seulement si elle existe', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [berserker],
        locale: const Locale('fr', ''),
      );
      expect(
        find.text('Son Armure devient de la Puissance pour un tour.'),
        findsOneWidget,
      );

      await _buildAndReady(
        tester,
        heroes: const [mage],
        locale: const Locale('fr', ''),
      );
      expect(find.textContaining('devient de la Puissance'), findsNothing);
    });

    testWidgets('seules les stats de depart non nulles sont montrees', (
      WidgetTester tester,
    ) async {
      // Le Paladin : Maitrise 1, pas de critique, pas de chance.
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        locale: const Locale('fr', ''),
      );
      expect(find.text('1'), findsOneWidget, reason: 'la Maîtrise');
      expect(find.textContaining('%'), findsNothing, reason: 'aucun critique');

      // Le Mage : ni Maitrise, ni critique, ni chance — PV et mana seuls.
      await _buildAndReady(
        tester,
        heroes: const [mage],
        locale: const Locale('fr', ''),
      );
      expect(find.text('60'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsNothing, reason: 'une stat nulle ne se montre pas');
    });

    testWidgets('le critique de depart du Berserker est montre', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [berserker],
        locale: const Locale('fr', ''),
      );

      expect(find.text('10%'), findsOneWidget);
    });
  });

  group('le joueur choisit son passif', () {
    const ward = PassiveData(
      id: 'ward',
      nameEn: 'Ward',
      nameFr: 'Garde',
      descriptionFr: 'Gagne 2 Armure en fin de tour.',
      descriptionEn: 'Gain 2 Block at end of turn.',
      classes: ['paladin'],
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
      displayOrder: 1,
    );
    const zeal = PassiveData(
      id: 'zeal',
      nameEn: 'Zeal',
      nameFr: 'Zele',
      descriptionFr: 'Gagne 1 Puissance au debut du tour.',
      descriptionEn: 'Gain 1 Might at the start of the turn.',
      classes: ['paladin'],
      trigger: RelicTrigger.startOfTurn,
      effectType: 'rage',
      value: 1,
      displayOrder: 2,
    );

    const paladin = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Le Paladin',
      classCard: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
    );

    testWidgets('tous les passifs disponibles sont proposes', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward, zeal],
      );

      expect(find.text('WARD'), findsOneWidget);
      expect(find.text('ZEAL'), findsOneWidget);
    });

    testWidgets('le premier du point d acces est selectionne par defaut', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward, zeal],
      );

      // La description du passif selectionne est celle qui s'affiche.
      expect(find.text('Gain 2 Block at end of turn.'), findsOneWidget);
      expect(find.text('Gain 1 Might at the start of the turn.'), findsNothing);
    });

    testWidgets('choisir un autre passif change ce que l ecran pousse', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward, zeal],
      );

      await tester.tap(find.text('ZEAL'));
      await tester.pump();

      expect(find.text('Gain 1 Might at the start of the turn.'), findsOneWidget);

      await tester.tap(find.text('Select'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pushed = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushed.passive?.id, 'zeal');
    });

    testWidgets('un seul passif disponible : aucun selecteur, et il est pousse', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward],
      );

      expect(find.text('WARD'), findsOneWidget);

      await tester.tap(find.text('Select'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pushed = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushed.passive?.id, 'ward');
    });

    testWidgets('aucun passif disponible : l ecran reste utilisable', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(tester, heroes: const [paladin]);

      await tester.tap(find.text('Select'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pushed = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushed.passive, isNull);
    });
  });
}
