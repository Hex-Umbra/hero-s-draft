import 'package:flutter/services.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

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
/// `setUpAll`.
///
/// Le registre livré ouvre les neuf passifs, trois par classe (spec P-42
/// tranche 3, §3.5) : un test qui change de passif a toujours un choix à
/// faire, sans carte de lot de test.
Future<GameDataRegistry> buildTutorialTestRegistry() =>
    loadGameDataRegistry(rootBundle);
