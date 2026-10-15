import 'hero_data.dart';
import 'card_data.dart';
import 'game_data_registry.dart';
import 'signature_data.dart';

extension HeroSkillsLink on HeroData {
  List<CardData> getHeroCards(GameDataRegistry gameData) {
    // Pas de filtrage silencieux : une carte de signature introuvable est un
    // bug de données. L'avaler produisait un deck de départ amputé sans la
    // moindre trace.
    return skills
        .map((skillId) => gameData.cards.firstWhere((c) => c.id == skillId))
        .toList();
  }

  /// Les signatures du héros, dans l'ordre de `skills`. Même exigence que
  /// [getHeroCards] : une signature introuvable est un bug de données, elle
  /// lève.
  List<SignatureData> getSignatures(GameDataRegistry gameData) {
    return skills
        .map((id) => gameData.signatures.firstWhere((s) => s.id == id))
        .toList();
  }
}
