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
  Size physicalSize = const Size(1600, 1200),
}) async {
  // GridView.builder only lays out visible children. The default test
  // surface (800x600) fits just one row of hero cards at the desktop
  // breakpoint, hiding the 3rd (Mage). Widen the surface so all seeded
  // heroes are simultaneously visible without needing to scroll — unless a
  // caller passes its own `physicalSize` (e.g. to exercise the mobile
  // breakpoint).
  tester.view.physicalSize = physicalSize;
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
    // Donnee reelle des deux class.json les plus charges, pour mesurer sans
    // fabriquer un pire cas artificiel : le Paladin (Maitrise, orientation a
    // trois cibles) et le Berserker (critique, une StatRule, et un nom qui
    // enjambe deux lignes en francais a largeur mobile).
    const paladinReel = HeroData(
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
    const berserkerReel = HeroData(
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

    // Les trois passifs reels de chaque classe (assets/data/passives/), avec
    // leurs descriptions completes — le pire cas de longueur de texte que le
    // jeu livre vraiment, sans en inventer un plus long.
    const regenArmor = PassiveData(
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
    const fervor = PassiveData(
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
    const blessing = PassiveData(
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
    const rage = PassiveData(
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
    const bloodthirst = PassiveData(
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
    const frenzy = PassiveData(
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

    // 360 (le plus etroit courant), 390 (le point deja couvert par la tache
    // 6), 480, 550 (mesure du rapport visuel, 212/255px de debordement) et
    // 599 (juste sous la bascule `isMobile`) : la grille mobile est desormais
    // a une seule colonne et hauteur fixe (`SliverGridDelegateWithFixedCross
    // AxisCount`, round 2 du 2026-09-18) — la largeur de carte varie donc
    // avec la largeur d'ecran (340px a 360, 579px a 599) mais sa hauteur ne
    // depend plus d'elle, ce que ce test verifie : aucune largeur de la plage
    // ne doit deborder ni casser un mot en plein milieu.
    //
    // La hauteur de viewport (1600) est volontairement genereuse : avec une
    // seule colonne, le Paladin et le Berserker s'empilent au lieu de se
    // partager une rangee, et `GridView.builder` ne construit que ce qui est
    // visible — il faut donc assez de hauteur pour que les deux cartes
    // soient realisees dans le meme pump, sans avoir a faire defiler l'ecran
    // de test.
    const largeurs = [360.0, 390.0, 480.0, 550.0, 599.0];
    for (final largeur in largeurs) {
      testWidgets(
        'a ${largeur.toInt()}px, Paladin et Berserker ne debordent pas, '
        'ni ne cassent un mot',
        (WidgetTester tester) async {
          // Une RenderFlex overflow levee pendant le pump ci-dessous ferait
          // deja echouer ce test : rendre sans erreur EST une premiere
          // assertion.
          await _buildAndReady(
            tester,
            heroes: const [paladinReel, berserkerReel],
            passives: const [
              regenArmor,
              fervor,
              blessing,
              rage,
              bloodthirst,
              frenzy,
            ],
            locale: const Locale('fr', ''),
            physicalSize: Size(largeur, 1600),
          );

          expect(find.text('Le Paladin'), findsOneWidget);
          expect(find.text('Le Berserker'), findsOneWidget);
          expect(find.text('RÉGÉNÉRATION D\'ARMURE'), findsOneWidget);
          expect(find.text('RAGE'), findsOneWidget);

          // Garde-fou contre les mots coupes en plein milieu (« Le Berse /
          // rker », « RÉGÉNÉRAT / ION D'ARMURE ») : ce mode de panne ne leve
          // aucune RenderFlex overflow (le texte se redimensionne pour
          // tenir), donc seule une assertion structurelle le detecte. Plutot
          // que d'essayer de reproduire l'algorithme de cesure de mots pour
          // verifier le nombre de lignes, on verifie la propriete qui rend la
          // coupure impossible : une carte assez large pour que le mot le
          // plus long du jeu (« RÉGÉNÉRATION D'ARMURE », 22 caracteres) ait
          // la place de se couper seulement entre les mots. 300px est la
          // largeur qui, empiriquement, loge ce nom en une seule ligne a la
          // taille de police mobile (10px) avec la puce icone ; en dessous,
          // un mot long recommencerait a se rompre en son milieu comme avant
          // ce correctif.
          final cardWidth = tester
              .getSize(find.byType(AnimatedContainer).first)
              .width;
          expect(
            cardWidth,
            greaterThanOrEqualTo(300),
            reason:
                'une carte plus etroite que 300px expose de nouveau les '
                'noms de passif a se casser en plein mot',
          );
        },
      );
    }
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
  });
}
