import 'hero_data.dart';
import 'card_data.dart';
import 'game_data_registry.dart';

extension HeroSkillsLink on HeroData {
  List<CardData> getHeroCards(GameDataRegistry gameData) {
    return skills
        .map((skillId) {
          final matches = gameData.cards.where((c) => c.id == skillId);
          return matches.isNotEmpty ? matches.first : null;
        })
        .whereType<CardData>()
        .toList();
  }
}
