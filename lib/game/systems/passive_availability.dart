import '../../models/data/game_data_registry.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';

/// Le point d'accès unique aux passifs qu'une classe peut prendre
/// (spec P-49, §4 ; spec P-42 T1 et P-44 lot 1, §4.8).
///
/// Tout lecteur qui choisit un passif passe par ici : l'écran de sélection,
/// le tutoriel. Aucun ne lit `PassiveData.classes` ni les lots lui-même.
/// Disponible vaut **éligible et pourvu d'un lot** : la classe figure dans
/// `classes`, et au moins une carte du registre porte ce passif, de quelque
/// type qu'elle soit (O5 : un passif dont le dossier `cards/<passif>/` est
/// vide ne se propose pas — un dossier vide n'existant pas au manifeste, la
/// règle se lit sur le registre, A4). Aucune liste de passifs n'est écrite
/// nulle part : le lot d'une tranche suivante ouvre son passif sans rien
/// changer ici. Le jour où la méta-progression (P-13) filtrera les passifs
/// débloqués, elle ajoutera sa condition dans cette fonction, sans toucher à
/// ses lecteurs.
///
/// Triés par `displayOrder` puis par `id` : le rang est déclaré par la donnée,
/// et l'`id` tranche à rang égal — pour ne dépendre ni de l'ordre de lecture
/// des fichiers ni de l'alphabet (spec P-41, §8.3).
/// Fonction pure, sans provider : le tutoriel l'appelle comme le jeu (ADR-081).
List<PassiveData> availablePassivesFor(
  HeroData hero,
  GameDataRegistry registry,
) {
  final withLot = registry.cards.map((card) => card.passive).nonNulls.toSet();
  return registry.passives
      .where((passive) =>
          (passive.classes?.contains(hero.id) ?? true) &&
          withLot.contains(passive.id))
      .toList()
    ..sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
}
