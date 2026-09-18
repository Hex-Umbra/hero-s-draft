import '../../models/data/game_data_registry.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';

/// Le point d'accès unique aux passifs qu'une classe peut prendre
/// (spec P-49, §4).
///
/// Tout lecteur qui choisit un passif passe par ici : l'écran de sélection,
/// le tutoriel, et demain l'éligibilité des récompenses. Aucun ne lit
/// `PassiveData.classes` lui-même : le jour où la méta-progression (P-13)
/// filtrera les passifs débloqués, elle le fera dans cette fonction, sans
/// toucher à ses lecteurs. D'ici là, « débloqué » vaut « tous ».
///
/// Triés par `displayOrder` puis par `id` : le rang est déclaré par la donnée,
/// et l'`id` tranche à rang égal — pour ne dépendre ni de l'ordre de lecture
/// des fichiers ni de l'alphabet (spec P-41, §8.3).
/// Fonction pure, sans provider : le tutoriel l'appelle comme le jeu (ADR-081).
List<PassiveData> availablePassivesFor(
  HeroData hero,
  GameDataRegistry registry,
) {
  return registry.passives
      .where((passive) => passive.classes?.contains(hero.id) ?? true)
      .toList()
    ..sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
}
