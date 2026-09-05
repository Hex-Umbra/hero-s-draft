import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/debug/debug_drawer.dart';

const _paladin = HeroData(
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
  passiveTrait: 'regen_armor',
);

const _strike = CardData(
  id: 'strike_basic',
  nameEn: 'Strike',
  nameFr: 'Frappe',
  descriptionEn: 'Deals 6 damage.',
  descriptionFr: 'Inflige 6 degats.',
  cost: 1,
  type: CardType.attack,
  category: CardCategory.global,
  rarity: CardRarity.common,
  target: CardTarget.singleEnemy,
  effects: [CardEffect(type: 'damage', value: 6)],
);

const _talisman = RelicData(
  id: 'iron_talisman',
  nameEn: 'Iron Talisman',
  nameFr: 'Talisman de fer',
  trigger: RelicTrigger.startOfRun,
  effectType: 'gain_strength',
  value: 2,
  rarity: RelicRarity.common,
  emoji: '🛡️',
);

final _goblinData = EnemyData(
  id: 'goblin',
  nameEn: 'Goblin',
  nameFr: 'Gobelin',
  maxHp: 20,
  baseDamage: 5,
  spritePath: 'goblin.png',
  tier: 1,
  intents: [EnemyIntent(type: IntentType.attack, value: 5)],
);

EnemyInstance _freshGoblin() => EnemyInstance(
  data: _goblinData,
  stats: EntityStats(maxPv: 20, currentPv: 20, armure: 0, attaque: 5),
);

/// Le registre doit etre **peuple** : avec des catalogues vides, les onglets
/// Deck et Reliques ne construisent aucun `ListTile`, et ces tests passeraient
/// au travers de tout defaut de construction les concernant.
void _populateRegistry() {
  GameDataRegistry(
    enemies: [_goblinData],
    heroes: const [_paladin],
    cards: const [_strike],
    events: const [],
    passives: const [],
    relics: const [_talisman],
    forgeUpgrades: const [],
  );
}

ProviderContainer _debugRunContainer({List<EnemyInstance> enemies = const []}) {
  final container = ProviderContainer();
  container.read(debugRunProvider.notifier).requestDebugRun();
  container.read(runProvider.notifier).startNewRun(_paladin);
  container
      .read(combatProvider.notifier)
      .updateState(CombatState(enemies: enemies));
  return container;
}

/// Le tiroir est monte dans le `Stack` d'un ecran, sous son `Scaffold` —
/// exactement comme `GameScreen` et `MapScreen` le font.
Widget _harness(ProviderContainer container, {required bool inCombat}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(
        body: Stack(children: [DebugDrawer(inCombat: inCombat)]),
      ),
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.text('DEBUG'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(_populateRegistry);

  void sizeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('ferme, le tiroir ne montre que sa poignee', (tester) async {
    sizeScreen(tester);
    final container = _debugRunContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: false));

    expect(find.text('DEBUG'), findsOneWidget);
    expect(find.text('Heros'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en combat, les cinq onglets se construisent sans exception', (
    tester,
  ) async {
    sizeScreen(tester);
    final container = _debugRunContainer(
      enemies: [_freshGoblin(), _freshGoblin()],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: true));
    await _openDrawer(tester);
    expect(tester.takeException(), isNull, reason: 'ouverture');

    // A chaque onglet, un contenu qui lui est propre : sans cette seconde
    // assertion, un onglet qui ne s'afficherait pas du tout passerait le test,
    // faute d'exception a lever.
    const tabs = <String, String>{
      'Run': 'Or',
      'Deck': 'Ajouter une carte',
      'Reliques': 'Ajouter une relique',
      'Combat': 'Gagner le combat',
      'Heros': 'PV',
    };

    for (final entry in tabs.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.pump();
      await tester.tap(find.text(entry.key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'onglet ${entry.key}');
      expect(
        find.text(entry.value),
        findsWidgets,
        reason: 'contenu de l onglet ${entry.key}',
      );
    }
  });

  testWidgets('sur la carte, pas d onglet Combat mais l acte suivant', (
    tester,
  ) async {
    sizeScreen(tester);
    final container = _debugRunContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: false));
    await _openDrawer(tester);

    expect(find.text('Combat'), findsNothing);

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acte suivant'), findsOneWidget);
  });

  testWidgets('en combat, l acte suivant est retire', (tester) async {
    sizeScreen(tester);
    final container = _debugRunContainer(enemies: [_freshGoblin()]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: true));
    await _openDrawer(tester);

    // `advanceToNextAct` regenere la carte et efface la position : le proposer
    // en combat laisserait la run sans noeud courant.
    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acte suivant'), findsNothing);
  });

  testWidgets('mettre un ennemi a 0 PV ne ferme pas le tiroir', (tester) async {
    sizeScreen(tester);
    final container = _debugRunContainer(
      enemies: [_freshGoblin(), _freshGoblin()],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: true));
    await _openDrawer(tester);
    // La barre d'onglets defile : « Combat » est le cinquieme et sort du
    // cadre, le tap manquerait sa cible sans amener la vue jusqu'a lui.
    await tester.ensureVisible(find.text('Combat'));
    await tester.pump();
    await tester.tap(find.text('Combat'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1. Gobelin'), findsOneWidget);
    expect(find.textContaining('2. Gobelin'), findsOneWidget);

    await tester.tap(find.text('0 PV').first);
    await tester.pumpAndSettle();

    // L'ennemi meurt et le tiroir reste ouvert : un panneau ancre n'est pas
    // une route, donc rien ne peut le fermer par megarde. C'est la propriete
    // qui motive tout ce composant — sa perte reproduirait le defaut ou la
    // sortie de combat fermait le menu au lieu de l'ecran.
    expect(container.read(combatProvider).enemies.length, 1);
    expect(find.text('Gagner le combat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
