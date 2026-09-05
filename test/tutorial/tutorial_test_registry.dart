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
/// **Asynchrone** parce que le chargeur lit le bundle. Les fichiers appelants
/// construisent le registre dans un `setUpAll`, jamais dans un `setUp` :
/// `GameDataRegistry` ecrit un singleton statique dans son constructeur
/// (`game_data_registry.dart:33`), donc deux registres dans un meme fichier
/// se marcheraient dessus.
Future<GameDataRegistry> buildTutorialTestRegistry() =>
    loadGameDataRegistry(rootBundle);
