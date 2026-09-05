import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/debug/debug_combat_drawer.dart';

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

ProviderContainer _combatContainer(List<EnemyInstance> enemies) {
  final container = ProviderContainer();
  container.read(debugRunProvider.notifier).requestDebugRun();
  container.read(runProvider.notifier).startNewRun(_paladin);
  container
      .read(combatProvider.notifier)
      .updateState(CombatState(enemies: enemies));
  return container;
}

Widget _harness(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: const Scaffold(
        body: Stack(children: [DebugCombatDrawer()]),
      ),
    ),
  );
}

void main() {
  testWidgets('la poignee ouvre le tiroir et revele les ennemis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _combatContainer([_freshGoblin(), _freshGoblin()]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));

    // Ferme : la poignee seule, aucune commande.
    expect(find.text('DEBUG'), findsOneWidget);
    expect(find.text('Gagner le combat'), findsNothing);

    await tester.tap(find.text('DEBUG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Gagner le combat'), findsOneWidget);
    // Les deux ennemis, distingues par leur rang dans la vague.
    expect(find.textContaining('1. Gobelin'), findsOneWidget);
    expect(find.textContaining('2. Gobelin'), findsOneWidget);
  });

  testWidgets('mettre un ennemi a 0 PV ne touche pas la pile de navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _combatContainer([_freshGoblin(), _freshGoblin()]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.tap(find.text('DEBUG'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('0 PV').first);
    await tester.pumpAndSettle();

    // L'ennemi meurt, le tiroir reste ouvert : un panneau ancre n'est pas une
    // route, donc rien ne peut le fermer par megarde — c'est la raison d'etre
    // de ce panneau.
    expect(container.read(combatProvider).enemies.length, 1);
    expect(find.text('Gagner le combat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
