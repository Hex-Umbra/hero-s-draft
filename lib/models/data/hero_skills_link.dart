import 'hero_data.dart';
import 'game_data_registry.dart';
import 'signature_data.dart';

extension HeroSkillsLink on HeroData {
  /// Les signatures du héros, dans l'ordre de `skills`. Pas de filtrage
  /// silencieux : une signature introuvable est un bug de données, elle
  /// lève.
  List<SignatureData> getSignatures(GameDataRegistry gameData) {
    return skills
        .map((id) => gameData.signatures.firstWhere((s) => s.id == id))
        .toList();
  }
}
