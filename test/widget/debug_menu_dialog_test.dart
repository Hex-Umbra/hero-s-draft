import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
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
import 'package:roguelike_card_game/ui/widgets/debug/debug_menu_dialog.dart';

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

/// Le registre doit etre **peuple** : avec des catalogues vides, les onglets
/// Deck et Reliques ne construisent aucun `ListTile`, et ce test passerait au
/// travers du defaut qu'il existe pour attraper.
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

/// Le menu doit etre **ouvert par `showDialog`**, comme dans le jeu, et non
/// monte directement dans le `body` d'un `Scaffold`.
///
/// La difference decide de la valeur de ce fichier : un `Scaffold` fournit
/// lui-meme un `Material`, si bien qu'un menu monte dedans se construit
/// parfaitement — y compris lorsqu'il lui manque le sien. `showDialog` place
/// le dialogue dans l'overlay, au-dessus du `Scaffold` et hors de son
/// `Material` : c'est la condition reelle, et la seule ou le defaut se voit.
Widget _harness(ProviderContainer container, {required bool inCombat}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.darkNeonTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                DebugMenuDialog.show(context, inCombat: inCombat),
            child: const Text('ouvrir le menu'),
          ),
        ),
      ),
    ),
  );
}

/// Monte le harnais puis ouvre reellement le dialogue.
Future<void> _openMenu(
  WidgetTester tester,
  ProviderContainer container, {
  required bool inCombat,
}) async {
  await tester.pumpWidget(_harness(container, inCombat: inCombat));
  await tester.tap(find.text('ouvrir le menu'));
  await tester.pumpAndSettle();
}

ProviderContainer _debugRunContainer() {
  final container = ProviderContainer();
  container.read(debugRunProvider.notifier).requestDebugRun();
  container.read(runProvider.notifier).startNewRun(_paladin);
  container.read(combatProvider.notifier).updateState(
    CombatState(
      enemies: [
        EnemyInstance(
          data: _goblinData,
          stats: EntityStats(
            maxPv: 20,
            currentPv: 20,
            armure: 0,
            attaque: 5,
          ),
        ),
      ],
    ),
  );
  return container;
}

void main() {
  setUp(_populateRegistry);

  testWidgets('les quatre onglets se construisent sans exception', (
    tester,
  ) async {
    // Regression : `GameDialog` est un conteneur stylé maison, sans `Material`
    // dans son arbre. `TextField` (onglets Heros, Run) et `ListTile` (Deck,
    // Reliques) en exigent un et refusaient de se construire — le menu
    // affichait un pave d'erreur rouge a la place de son contenu.
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _debugRunContainer();
    addTearDown(container.dispose);

    await _openMenu(tester, container, inCombat: true);
    expect(tester.takeException(), isNull, reason: 'construction initiale');

    // A chaque onglet, un contenu qui lui est propre : sans cette seconde
    // assertion, un onglet qui ne s'afficherait pas du tout passerait le test,
    // faute d'exception a lever.
    const tabs = <String, String>{
      'Run': 'Or',
      'Deck': 'Ajouter une carte',
      'Reliques': 'Ajouter une relique',
      'Heros': 'PV',
    };

    for (final entry in tabs.entries) {
      // La barre d'onglets defile : le dernier onglet sort du cadre, et le tap
      // manquerait sa cible sans deplacer la vue jusqu'a lui.
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

  testWidgets('les actions de combat ne sont jamais dans ce dialogue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _debugRunContainer();
    addTearDown(container.dispose);

    // Elles vivent dans `DebugCombatDrawer`, ancre a l'ecran de combat.
    await _openMenu(tester, container, inCombat: true);

    expect(find.text('Combat'), findsNothing);
    expect(find.text('Heros'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l acte suivant n est propose que hors combat', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // `advanceToNextAct` regenere la carte et efface la position : le
    // proposer en combat laisserait la run sans noeud courant.
    final inCombat = _debugRunContainer();
    addTearDown(inCombat.dispose);
    await _openMenu(tester, inCombat, inCombat: true);
    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acte suivant'), findsNothing);
  });
}
