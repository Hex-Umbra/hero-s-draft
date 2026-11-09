import 'package:flutter/services.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import '../unit/lot_card_fixture.dart';

/// Registre bati sur les vraies donnees du depot, par le vrai chargeur.
///
/// Les tests du tutoriel utilisent les vraies donnees plutot que des fixtures
/// inventees : c est precisement la fidelite qu on cherche a garantir. Passer
/// par `loadGameDataRegistry` plutot que par `dart:io` ajoute une garantie —
/// ces tests exercent desormais le meme chemin de chargement que
/// l application, motifs de chemin et injection compris.
///
/// **Asynchrone** parce que le chargeur lit le bundle. Les fichiers de
/// `test/tutorial/` construisent le registre une seule fois, dans un
/// `setUpAll`. Ceux de `test/widget/` (`tutorial_class_step_test.dart`,
/// `tutorial_starter_draft_test.dart`, `tutorial_merge_transition_test.dart`)
/// le reconstruisent a chaque `testWidgets` : `GameDataRegistry` ecrit un
/// singleton statique dans son constructeur (`game_data_registry.dart:33`),
/// mais `cache: false` (`game_data_loader.dart`) rend chaque reconstruction
/// sure — sans lui, le `Future` de lecture mis en cache dans la zone d un
/// test deja termine ne se resoudrait jamais depuis le suivant.
///
/// Le registre livré n'ouvre qu'un passif par classe (O5, spec P-42 T1 et
/// P-44 lot 1, §4.8). [openedPassives] en ouvre d'autres, chacun par une
/// carte de lot de test : un test qui change de passif garde ainsi un choix
/// à faire, au lieu de « changer » pour le même.
Future<GameDataRegistry> buildTutorialTestRegistry({
  Set<String> openedPassives = const {},
}) async {
  final shipped = await loadGameDataRegistry(rootBundle);
  if (openedPassives.isEmpty) return shipped;
  return GameDataRegistry(
    enemies: shipped.enemies,
    heroes: shipped.heroes,
    cards: [
      ...shipped.cards,
      for (final id in openedPassives) lotCardFor(id),
    ],
    events: shipped.events,
    passives: shipped.passives,
    relics: shipped.relics,
    forgeUpgrades: shipped.forgeUpgrades,
    levelUpRewards: shipped.levelUpRewards,
    signatures: shipped.signatures,
    xpCurve: shipped.xpCurve,
    effectIcons: shipped.effectIcons,
    audio: shipped.audio,
  );
}
