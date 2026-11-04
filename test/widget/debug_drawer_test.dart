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
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/might_target.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/debug/debug_drawer.dart';

const _paladin = HeroData(
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
);

const _berserker = HeroData(
  id: 'berserker',
  nameEn: 'Berserker',
  nameFr: 'Berserker',
  descriptionEn: 'Damage oriented',
  descriptionFr: 'Oriente degats',
  classCard: 'berserker.png',
  maxHp: 80,
  maxMana: 3,
  luck: 0,
  mastery: 0,
  critChance: 10,
  mightTargets: {MightTarget.attack},
  statRules: [
    StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    ),
  ],
);

const _strike = CardData(
  id: 'strike_basic',
  nameEn: 'Strike',
  nameFr: 'Frappe',
  descriptionEn: 'Deals 6 damage.',
  descriptionFr: 'Inflige 6 degats.',
  cost: 1,
  type: CardType.attack,
  rarity: CardRarity.common,
  target: CardTarget.singleEnemy,
  effects: [CardEffect(type: 'damage', value: 6)],
);

const _talisman = RelicData(
  id: 'iron_talisman',
  nameEn: 'Iron Talisman',
  nameFr: 'Talisman de fer',
  trigger: RelicTrigger.startOfRun,
  effectType: 'gain_might',
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

ProviderContainer _debugRunContainer({
  List<EnemyInstance> enemies = const [],
  HeroData hero = _paladin,
  PassiveData? activePassive,
}) {
  // Hors combat, le premier onglet, « Heros », lit le palier d'XP de l'acte
  // (`debug_hero_tab.dart`) : la courbe est surchargée ici, pour tous les
  // appelants (spec P-43 E3, §8, « Le piège du montage »).
  final container = ProviderContainer(
    overrides: [
      xpCurveProvider.overrideWithValue(const XpCurveData([115, 200])),
    ],
  );
  container.read(debugRunProvider.notifier).requestDebugRun();
  container.read(runProvider.notifier).startNewRun(hero, activePassive);
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

/// Fait defiler la liste d'un onglet jusqu'a [target].
///
/// Le `scrollable` est designe explicitement : le `TabBarView` en est un lui
/// aussi, et laisser `scrollUntilVisible` choisir seul echoue sur « trop
/// d'elements ».
Future<void> _scrollTo(WidgetTester tester, Finder target) {
  return tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
}

void main() {
  setUp(_populateRegistry);

  void sizeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('la derniere cible de Puissance ne peut pas etre retiree', (tester) async {
    sizeScreen(tester);
    final container = _debugRunContainer(hero: _berserker);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: false));
    await _openDrawer(tester);
    await tester.tap(find.text('Heros'));
    await tester.pumpAndSettle();

    // Le Berserker n'a que `attack` : la decocher laisserait une run dont la
    // Puissance ne renforce rien, etat que `HeroData.fromJson` refuse de
    // relire (`might_target.dart:20-25`).
    await _scrollTo(tester, find.text(MightTarget.attack.name));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text(MightTarget.attack.name),
        matching: find.byType(FilterChip),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(runProvider).heroStats.mightTargets,
      {MightTarget.attack},
    );

    // En revanche, en ajouter une marche.
    await _scrollTo(tester, find.text(MightTarget.skill.name));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text(MightTarget.skill.name),
        matching: find.byType(FilterChip),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(runProvider).heroStats.mightTargets,
      {MightTarget.attack, MightTarget.skill},
    );
  });

}
