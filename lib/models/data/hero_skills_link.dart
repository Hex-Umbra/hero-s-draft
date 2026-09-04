import 'hero_data.dart';
import 'card_data.dart';
import 'game_data_registry.dart';

extension HeroSkillsLink on HeroData {
  List<CardData> getHeroCards(GameDataRegistry gameData) {
    // Pas de filtrage silencieux : une carte de signature introuvable est un
    // bug de données. L'avaler produisait un deck de départ amputé sans la
    // moindre trace.
    return skills
        .map((skillId) => gameData.cards.firstWhere((c) => c.id == skillId))
        .toList();
  }
}
