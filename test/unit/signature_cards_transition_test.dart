import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/reward_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// La transition E3 → E4 (spec P-43 E3, §4.13, §8) : jusqu'à E4, les
/// signatures restent des cartes du deck — exclues de la trouvaille par
/// `unique`, sans rune offerte, au rang 0 pour la difficulté. Sur le
/// registre réel.
///
/// La clause du boss « XP » — il ne monte jamais une rune de signature —
/// vient en partie 2, avec le boss.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  late Set<String> signatureIds;

  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
    // Ce que chaque classe déclare, et que son dossier porte
    // (`referential_integrity_test.dart:211-229`) — C3.1.
    signatureIds = registry.heroes.expand((h) => h.skills).toSet();
  });

  test('la trouvaille ne donne jamais une signature, ni une carte d une autre '
      'classe', () {
    // Un ensemble vide rendrait la clause vraie d'office (C3.1).
    expect(signatureIds, hasLength(6));

    for (final hero in registry.heroes) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      final rewards = container.read(rewardProvider.notifier);
      final rng = Random(7);
      final node = MapNode(
        id: 'node_0_0',
        floor: 0,
        type: MapNodeType.combat,
        connections: const [],
        position: Vector2.zero(),
      );

      for (var i = 0; i < 200; i++) {
        rewards.handleVictory(
          defeatedEnemies: const [],
          currentNode: node,
          allRelics: registry.relics,
          allCards: registry.cards,
          luck: 0,
          act: 1,
          random: rng,
        );
        // La donnée de la carte, jamais `card.rarity`, que l'instance porte
        // `common` (spec §4.1) : l'assertion ne garderait rien.
        for (final card in rewards.state.foundCards) {
          final reason = '${hero.id} : ${card.data.id}';
          expect(card.data.rarity, isNot(CardRarity.unique), reason: reason);
          expect(card.data.heroClass, anyOf(isNull, hero.id), reason: reason);
          expect(signatureIds, isNot(contains(card.data.id)), reason: reason);
        }
      }
    }
  });

  test('une signature ne recoit aucune rune offerte', () {
    for (final id in signatureIds) {
      final signature = registry.cards.singleWhere((c) => c.id == id);
      expect(
        ForgeRuneRules.drawRunes(
          CardInstance(data: signature),
          registry.forgeUpgrades,
          Random(1),
          count: 3,
        ),
        isEmpty,
        reason: id,
      );
    }
  });

  test('un deck des deux signatures et de communes pese zero pour la '
      'difficulte', () {
    final neutrals = registry.cards.where((c) => c.heroClass == null).take(5);

    for (final hero in registry.heroes) {
      final deck = DeckState(masterDeck: [
        for (final id in hero.skills)
          CardInstance(data: registry.cards.singleWhere((c) => c.id == id)),
        for (final card in neutrals)
          CardInstance(data: card, rarity: CardRarity.common),
      ]);
      expect(deck.fusionRankSum, 0, reason: hero.id);
    }
  });
}
