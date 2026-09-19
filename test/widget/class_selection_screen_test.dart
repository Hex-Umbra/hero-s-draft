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

// Donnee reelle des deux class.json les plus charges, partagee entre le
// groupe qui teste la plage de largeurs mobile et celui qui teste les
// largeurs desktop au point le plus etroit de chaque palier de colonnes
// (defaut 1 et 2 du 2026-09-19) : le Paladin (Maitrise, orientation a trois
// cibles) et le Berserker (critique, une StatRule, et un nom qui enjambe
// deux lignes en francais a largeur mobile), avec leurs trois passifs reels
// chacun (assets/data/passives/) — le pire cas de longueur de texte que le
// jeu livre vraiment, sans en inventer un plus long pour ceux-la.
const _paladinReel = HeroData(
  id: 'paladin',
  nameEn: 'Paladin',
  nameFr: 'Le Paladin',
  descriptionEn: 'Survival Oriented',
  descriptionFr: 'Orienté Survie',
  classCard: 'hero_paladin.png',
  maxHp: 100,
  maxMana: 3,
  mastery: 1,
  mightTargets: {
    MightTarget.attack,
    MightTarget.skill,
    MightTarget.alteration,
  },
  displayOrder: 1,
);
const _berserkerReel = HeroData(
  id: 'berserker',
  nameEn: 'Berserker',
  nameFr: 'Le Berserker',
  descriptionEn: 'Damage Oriented',
  descriptionFr: 'Orienté Dégâts',
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
  displayOrder: 2,
);

const _regenArmor = PassiveData(
  id: 'regen_armor',
  nameEn: 'Armor Regeneration',
  nameFr: "Régénération d'Armure",
  descriptionEn: 'Gain 2 Block automatically at the end of each turn.',
  descriptionFr:
      'Gagne 2 points d\'Armure automatiquement à la fin de chaque tour.',
  classes: ['paladin'],
  trigger: RelicTrigger.endOfTurn,
  effectType: 'gain_armor',
  value: 2,
  displayOrder: 1,
);
const _fervor = PassiveData(
  id: 'fervor',
  nameEn: 'Fervor',
  nameFr: 'Ferveur',
  descriptionEn: 'When your Block absorbs damage, gain 1 Might for 2 turns.',
  descriptionFr:
      'Quand votre Armure encaisse des dégâts, gagne 1 Puissance pendant '
      '2 tours.',
  classes: ['paladin'],
  trigger: RelicTrigger.onDamageTaken,
  effectType: 'fervor',
  value: 1,
  displayOrder: 2,
);
const _blessing = PassiveData(
  id: 'blessing',
  nameEn: 'Blessing',
  nameFr: 'Bénédiction',
  descriptionEn:
      'At the start of your turn, every 5 points of surviving Block '
      'becomes 1 HP.',
  descriptionFr:
      "Au début du tour, chaque tranche de 5 points d'Armure survivante "
      'devient 1 PV.',
  classes: ['paladin'],
  trigger: RelicTrigger.startOfTurn,
  effectType: 'blessing',
  value: 1,
  displayOrder: 3,
);
const _rage = PassiveData(
  id: 'rage',
  nameEn: 'Rage',
  nameFr: 'Rage',
  descriptionEn:
      'At the start of your turn, gain 1 Might for the turn, plus 1 per '
      '10 missing HP.',
  descriptionFr:
      'Au début du tour, gagne 1 Puissance pour le tour, plus 1 par '
      'tranche de 10 PV manquants.',
  classes: ['berserker'],
  trigger: RelicTrigger.startOfTurn,
  effectType: 'rage',
  value: 1,
  duration: 1,
  displayOrder: 1,
);
const _bloodthirst = PassiveData(
  id: 'bloodthirst',
  nameEn: 'Bloodthirst',
  nameFr: 'Soif de Sang',
  descriptionEn:
      'Playing an Attack arms Lifesteal for 2 turns: 1 HP per damaging '
      'card, plus 1 per quarter of missing HP.',
  descriptionFr:
      'Jouer une Attaque arme le Vol de Vie pendant 2 tours : 1 PV par '
      'carte de dégâts, plus 1 par quart de PV manquants.',
  classes: ['berserker'],
  trigger: RelicTrigger.onAttackPlayed,
  effectType: 'bloodthirst',
  value: 1,
  duration: 2,
  displayOrder: 2,
);
const _frenzy = PassiveData(
  id: 'frenzy',
  nameEn: 'Frenzy',
  nameFr: 'Frénésie',
  descriptionEn:
      'Each enemy killed grants 2 Might for the turn and draws 1 card.',
  descriptionFr:
      'Chaque ennemi abattu donne 2 Puissance pour le tour et fait '
      'piocher 1 carte.',
  classes: ['berserker'],
  trigger: RelicTrigger.onEnemyKilled,
  effectType: 'frenzy',
  value: 2,
  duration: 1,
  draw: 1,
  displayOrder: 3,
);

// Passif synthetique, jamais joue : sert uniquement a stresser le retour a
// la ligne du nom de passif, independamment de la police qui le rend.
//
// Verification du defaut 4 (2026-09-19) : un rapport anterieur de ce lot
// affirmait que la largeur de texte mesuree dans l'environnement de test
// *sous-estime* d'environ 45% la largeur reelle rendue par l'app — c'est
// l'inverse. `flutter_tools` restreint le repli de police au cache de
// l'engin pour `flutter test` (aucun `flutter_test_config.dart` ne charge
// de police reelle dans ce depot), donc le texte y est rendu avec la police
// de secours du framework, ou chaque glyphe avance a peu pres 1em. Mesure
// directement ici : « RÉGÉNÉRATION D'ARMURE » (21 caracteres, interlettrage
// 0.8) fait 226.8px a fontSize 10 et 247.8px a fontSize 11, soit ~1.0-1.08
// em/glyphe — quand une police proportionnelle reelle, meme en capitales,
// avance en moyenne plutot ~0.6-0.75em/glyphe. Donc, a `fontSize` nominal
// egal, l'environnement de test est le cas *conservateur* (plus large), pas
// celui qui sous-estime : charger de vraies polices rendrait ces tests
// moins stricts, pas plus.
//
// L'axe reellement non modelise est ailleurs : la mise a l'echelle de texte
// du systeme (`MediaQuery.textScaler`), qu'aucun test de ce fichier ne
// fixait avant le defaut 4 — c'est elle qui peut faire rendre un texte plus
// grand que son `fontSize` nominal, dans l'app reelle comme en test. Le
// groupe plus bas rejoue desormais la plage de largeurs mobile a
// `TextScaler.linear(1.3)` pour l'exercer.
//
// `_stressWrapTest` reste utile malgre cette correction : son nom est
// volontairement plus long que le plus long nom reel du jeu, pour rester
// plus large que l'espace disponible quelle que soit la police ou l'echelle
// qui le rend — sa bonne prise en charge (retour a la ligne via `Flexible`,
// jamais de `RenderFlex overflowed`) demontre une propriete structurelle du
// layout, pas une mesure de police precise.
const _stressWrapTest = PassiveData(
  id: 'stress_wrap_test',
  nameEn: 'Blessing Of Miraculous And Continuous Regeneration',
  nameFr: 'Bénédiction De Régénération Miraculeuse Et Continuelle',
  classes: ['paladin'],
  trigger: RelicTrigger.endOfTurn,
  effectType: 'gain_armor',
  value: 1,
  displayOrder: 4,
);

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
  Size physicalSize = const Size(1600, 1200),
  // Axe non modelise par le reste de ce fichier avant le defaut 4 du
  // 2026-09-19 : aucun test ici ne fixait de `textScaler`, alors que c'est
  // le seul axe sur lequel l'app reelle peut rendre un texte plus large que
  // l'environnement de test (voir le groupe qui l'exerce plus bas). `null`
  // laisse le comportement par defaut (pas de mise a l'echelle).
  TextScaler? textScaler,
}) async {
  // GridView.builder only lays out visible children. The default test
  // surface (800x600) fits just one row of hero cards at the desktop
  // breakpoint, hiding the 3rd (Mage). Widen the surface so all seeded
  // heroes are simultaneously visible without needing to scroll — unless a
  // caller passes its own `physicalSize` (e.g. to exercise the mobile
  // breakpoint).
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
        builder: textScaler == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child!,
                ),
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

  group('les badges de stats restent sur une seule ligne (defaut 1)', () {
    const heavy = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Le Paladin',
      classCard: 'hero_paladin.png',
      maxHp: 77,
      maxMana: 4,
      mastery: 2,
      critChance: 15,
      luck: 6,
    );

    testWidgets(
      'cinq stats non nulles partagent la meme ligne, pas une par ligne',
      (WidgetTester tester) async {
        // `_buildStatBadge` rendait un `Row` a `MainAxisSize.max`, ce qui
        // etait sans consequence tant que les badges etaient les enfants
        // directs d'un `Row`. La tache 5 les a deplaces dans un `Wrap`, ou un
        // enfant a largeur maximale revendique toute la largeur disponible et
        // force chaque badge suivant sur sa propre ligne. Comparer le `dy` de
        // deux badges est le seul moyen honnete de detecter cette
        // regression : un test qui ne verifie que la presence du texte passe
        // dans les deux cas, avant comme apres la regression.
        await _buildAndReady(tester, heroes: const [heavy]);

        final hp = tester.getTopLeft(find.text('77'));
        final mana = tester.getTopLeft(find.text('4'));
        final mastery = tester.getTopLeft(find.text('2'));
        final crit = tester.getTopLeft(find.text('15%'));
        final luck = tester.getTopLeft(find.text('6'));

        expect(
          mana.dy,
          hp.dy,
          reason: 'le mana devrait partager la ligne des PV',
        );
        expect(
          mastery.dy,
          hp.dy,
          reason: 'la Maitrise devrait partager la ligne des PV',
        );
        expect(
          crit.dy,
          hp.dy,
          reason: 'le critique devrait partager la ligne des PV',
        );
        expect(
          luck.dy,
          hp.dy,
          reason: 'la chance devrait partager la ligne des PV',
        );
      },
    );
  });

  group('la carte tient a chaque largeur mobile, pas seulement a 390 (defaut 2)', () {
    // 320 (le plus etroit reellement rencontre — iPhone SE et equivalents ;
    // absent du round 2, ce qui a laisse passer un debordement reel a une
    // largeur bien plus etroite), 360, 390, 480, 550 et 599 (juste sous la
    // bascule `isMobile`) : la grille mobile est desormais un
    // `ListView.separated` a une colonne, ou chaque carte se dimensionne a
    // son propre contenu au lieu de recevoir une hauteur deduite de la
    // largeur ou une hauteur fixe partagee (defaut 1 et 2, 2026-09-19) — la
    // largeur de carte varie avec la largeur d'ecran mais sa hauteur suit
    // desormais son propre contenu. Ce test verifie qu'aucune largeur de la
    // plage ne deborde ; le second passage de chaque largeur, plus bas,
    // rejoue la meme chose a `textScaler` 1.3 (defaut 4).
    //
    // La hauteur de viewport (1600) est volontairement genereuse : avec une
    // seule colonne, le Paladin et le Berserker s'empilent au lieu de se
    // partager une rangee, et `ListView.separated` ne construit que ce qui
    // est visible — il faut donc assez de hauteur pour que les deux cartes
    // soient realisees dans le meme pump, sans avoir a faire defiler l'ecran
    // de test.
    const largeurs = [320.0, 360.0, 390.0, 480.0, 550.0, 599.0];

    Future<void> pumpAndExpectNoOverflow(
      WidgetTester tester, {
      required double largeur,
      TextScaler? textScaler,
    }) async {
      await _buildAndReady(
        tester,
        heroes: const [_paladinReel, _berserkerReel],
        passives: const [
          _regenArmor,
          _fervor,
          _blessing,
          _stressWrapTest,
          _rage,
          _bloodthirst,
          _frenzy,
        ],
        locale: const Locale('fr', ''),
        physicalSize: Size(largeur, 1600),
        textScaler: textScaler,
      );

      expect(find.text('Le Paladin'), findsOneWidget);
      expect(find.text('Le Berserker'), findsOneWidget);
      expect(find.text('RÉGÉNÉRATION D\'ARMURE'), findsOneWidget);
      expect(find.text('RAGE'), findsOneWidget);
      // Le nom-stress se retrouve entier dans l'arbre (pas coupe, pas
      // tronque) : `Text` ne segmente jamais sa propre chaine, donc son
      // seul moyen de tenir sur un `Flexible` trop etroit est d'occuper
      // plusieurs lignes — le retrouver ici prouve que le rendu a eu lieu
      // (par opposition a une exception qui aurait empeche le pump d'aller
      // a son terme).
      expect(find.text(_stressWrapTest.nameFr.toUpperCase()), findsOneWidget);

      // Garde-fou direct contre le debordement horizontal du nom de passif
      // (round 3 du 2026-09-18, confirme par le defaut 4 du 2026-09-19) :
      // ce garde-fou ne repose sur aucune largeur de texte mesuree dans
      // l'environnement de test (voir le commentaire au-dessus de
      // `_stressWrapTest`) — il repose sur la structure (`Flexible` autour
      // du `Text`), qui rend le retour a la ligne possible quelle que soit
      // la police ou l'echelle qui rend le nom. `_stressWrapTest` est
      // construit pour deborder de l'espace disponible a chaque largeur de
      // la plage, meme dans la police de test : si `Flexible` disparaissait
      // de nouveau, cette assertion echouerait.
      expect(
        tester.takeException(),
        isNull,
        reason:
            'un debordement horizontal du nom de passif indique que '
            'Flexible a disparu autour de son Text',
      );
    }

    for (final largeur in largeurs) {
      testWidgets(
        'a ${largeur.toInt()}px, Paladin et Berserker ne debordent pas',
        (WidgetTester tester) async {
          await pumpAndExpectNoOverflow(tester, largeur: largeur);
        },
      );

      testWidgets(
        'a ${largeur.toInt()}px avec textScaler 1.3, ils ne debordent pas '
        'non plus (defaut 4)',
        (WidgetTester tester) async {
          // Axe non modelise par le reste de cette plage avant le defaut 4
          // du 2026-09-19 : aucun test de ce fichier ne simulait la mise a
          // l'echelle de texte du systeme (accessibilite, ou simplement les
          // reglages d'affichage de l'appareil), alors que c'est le seul
          // axe sur lequel l'app reelle peut rendre un texte plus grand que
          // son `fontSize` nominal — l'environnement de test lui-meme rend
          // deja plus large qu'une police reelle a `fontSize` egal (voir le
          // commentaire au-dessus de `_stressWrapTest`).
          await pumpAndExpectNoOverflow(
            tester,
            largeur: largeur,
            textScaler: const TextScaler.linear(1.3),
          );
        },
      );
    }
  });

  group(
    'la carte tient a chaque largeur desktop, pas seulement a 1600 (defaut 1)',
    () {
      // Le motif en dents de scie de `SliverGridDelegateWithMaxCrossAxisExtent`
      // (maxCrossAxisExtent: 400) fait tomber la carte la plus etroite juste
      // apres chaque palier de colonnes : 600px -> 2 colonnes -> carte
      // 270px ; 1000px -> 3 colonnes -> 307px ; 1400px -> 4 colonnes ->
      // 325px. Tous les widget tests d'avant ce lot tournaient a 1600×1200 —
      // l'un des points les plus favorables — donc aucun ne couvrait ces
      // minima. Donnee reelle du Paladin et du Berserker, 3 passifs chacun.
      const largeurs = [600.0, 1000.0, 1400.0];
      for (final largeur in largeurs) {
        testWidgets(
          'a ${largeur.toInt()}px, Paladin et Berserker ne debordent pas',
          (WidgetTester tester) async {
            await _buildAndReady(
              tester,
              heroes: const [_paladinReel, _berserkerReel],
              passives: const [
                _regenArmor,
                _fervor,
                _blessing,
                _rage,
                _bloodthirst,
                _frenzy,
              ],
              locale: const Locale('fr', ''),
              physicalSize: Size(largeur, 1200),
            );

            expect(find.text('Le Paladin'), findsOneWidget);
            expect(find.text('Le Berserker'), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'a ${largeur.toInt()}px, la carte desktop la plus etroite '
                  'du palier de colonnes ne doit plus deborder '
                  '(_kDesktopCardHeight mesure, pas deduit de la largeur)',
            );
          },
        );
      }
    },
  );

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

    testWidgets(
      'le passif selectionne parmi plusieurs est souligne, les autres non',
      (WidgetTester tester) async {
        // Le test existant ('un seul passif disponible...') ne prouve que
        // l'absence de soulignement quand il n'y a rien a choisir — il ne
        // pinne pas la moitie utile de la regle (round 3 du 2026-09-18) :
        // que le passif *retenu*, parmi plusieurs, est bien souligne.
        await _buildAndReady(
          tester,
          heroes: const [paladin],
          passives: const [ward, zeal],
        );

        // ward (displayOrder 1) est le choix par defaut.
        final wardStyle = tester.widget<Text>(find.text('WARD')).style;
        expect(
          wardStyle?.decoration,
          TextDecoration.underline,
          reason: 'le passif retenu par defaut doit etre souligne',
        );
        final zealStyle = tester.widget<Text>(find.text('ZEAL')).style;
        expect(zealStyle?.decoration, isNull);

        await tester.tap(find.text('ZEAL'));
        await tester.pump();

        final zealStyleAfter = tester.widget<Text>(find.text('ZEAL')).style;
        expect(
          zealStyleAfter?.decoration,
          TextDecoration.underline,
          reason: 'le soulignement suit le nouveau choix',
        );
        final wardStyleAfter = tester.widget<Text>(find.text('WARD')).style;
        expect(wardStyleAfter?.decoration, isNull);
      },
    );

    testWidgets('le premier du point d acces est selectionne par defaut', (
      WidgetTester tester,
    ) async {
      // Declares zeal before ward, so declaration order is the reverse of
      // sorted order (ward's displayOrder 1 < zeal's 2). If the screen ever
      // read the registry directly instead of going through
      // availablePassivesFor, this would select zeal instead of ward.
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [zeal, ward],
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
      // Un seul passif : le nom garde exactement l'apparence d'aujourd'hui,
      // pas de soulignement (qui n'a de sens que quand il y a un choix).
      final wardStyle = tester.widget<Text>(find.text('WARD')).style;
      expect(wardStyle?.decoration, isNull);

      // Le tap est inerte : rien a selectionner avec un seul passif.
      await tester.tap(find.text('WARD'));
      await tester.pump();
      expect(find.byType(StarterDeckDraftScreen), findsNothing);
      expect(find.text('WARD'), findsOneWidget);
      final wardStyleAfterTap = tester.widget<Text>(find.text('WARD')).style;
      expect(wardStyleAfterTap?.decoration, isNull);

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

    testWidgets(
      'trois passifs a largeur mobile ne debordent pas',
      (WidgetTester tester) async {
        // Chaque classe livree a exactement trois passifs (spec §8.3) mais
        // aucun test avant celui-ci n'en montre plus de deux : le risque est
        // que la rangee de puces, sur la largeur mobile, pousse la carte a
        // deborder — le meme mode d'echec que la tache 5 a corrige a 3px
        // pres. Une description longue maximise la pression sur l'espace
        // vertical restant.
        const valor = PassiveData(
          id: 'valor',
          nameEn: 'Valor',
          nameFr: 'Vaillance',
          descriptionFr: 'Gagne 1 Puissance par ennemi vaincu ce combat.',
          descriptionEn: 'Gain 1 Might per enemy defeated this combat.',
          classes: ['paladin'],
          trigger: RelicTrigger.endOfTurn,
          effectType: 'rage',
          value: 1,
          displayOrder: 3,
        );
        const longWinded = HeroData(
          id: 'paladin',
          nameEn: 'Paladin',
          nameFr: 'Le Paladin',
          descriptionEn:
              'A stalwart defender forged in a hundred sieges, sworn to a '
              'code older than the kingdom itself, who bears the weight of '
              'every ally still standing at the end of the battle and every '
              'one who did not make it home from the last one.',
          classCard: 'hero_paladin.png',
          maxHp: 100,
          maxMana: 3,
        );

        await _buildAndReady(
          tester,
          heroes: const [longWinded],
          passives: const [ward, zeal, valor],
          physicalSize: const Size(390, 844),
        );

        // Une RenderFlex overflow leve pendant le pump ci-dessus ferait deja
        // echouer ce test : rendre sans erreur EST l'assertion.
        expect(find.text('WARD'), findsOneWidget);
        expect(find.text('ZEAL'), findsOneWidget);
        expect(find.text('VALOR'), findsOneWidget);
      },
    );

    testWidgets(
      'le bouton Selectionner reste atteignable sur un telephone bas '
      '(667px, defaut 2)',
      (WidgetTester tester) async {
        // L'ancienne hauteur mobile fixe (`_kMobileCardHeight = 660`)
        // pouvait laisser le bouton — le seul appel a l'action de l'ecran —
        // hors-champ sur un telephone bas : `ScreenScaffold` ajoute une
        // `SafeArea`, `PageHeader` prend `kToolbarHeight` (56px), et le
        // padding du corps en retire encore 20px, ce qu'aucun test d'avant
        // ce lot ne pouvait voir (tous fixaient une hauteur de viewport de
        // 1600 ou 844). Le degat reel du defaut 2 est ce bouton hors-champ,
        // pas seulement une absence d'exception — ce test garde donc qu'il
        // est reellement atteignable (visible et tapable), pas seulement
        // present dans l'arbre.
        await _buildAndReady(
          tester,
          heroes: const [paladin],
          passives: const [ward, zeal],
          locale: const Locale('fr', ''),
          physicalSize: const Size(375, 667),
        );

        final button = find.text('Sélectionner');
        expect(button, findsOneWidget);

        await tester.scrollUntilVisible(button, 200.0);
        await tester.pump();

        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.byType(StarterDeckDraftScreen),
          findsOneWidget,
          reason:
              'le bouton doit rester reellement tapable une fois amene a '
              "l'ecran, pas seulement present hors-champ dans l'arbre",
        );
      },
    );
  });
}
