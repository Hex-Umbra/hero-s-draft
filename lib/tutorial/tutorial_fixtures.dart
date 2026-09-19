import '../game/systems/passive_availability.dart';
import '../models/data/card_data.dart';
import '../models/data/enemy_data.dart';
import '../models/data/game_data_registry.dart';
import '../models/data/hero_data.dart';
import '../models/data/passive_data.dart';
import '../models/data/relic_data.dart';

/// Ids des entrées de `assets/data/` sur lesquelles le tutoriel s'appuie.
///
/// Le tutoriel ne nomme les données du jeu qu'ici. Toute autre référence en
/// dur à un id de carte, d'ennemi ou de relique dans `lib/tutorial/` est un
/// défaut.
class TutorialFixtureIds {
  const TutorialFixtureIds._();

  static const String strike = 'strike_basic';
  static const String defend = 'defend_basic';
  static const String fireball = 'fireball';
  static const String trainingEnemy = 'slime';
  static const String goblin = 'gobelin';
  static const String sampleRelic = 'iron_talisman';
  static const List<String> heroes = ['paladin', 'berserker', 'mage'];
}

/// Résout les fixtures du tutoriel contre le registre de données du jeu.
///
/// La résolution est délibérément *fail-fast* : `firstWhere` sans `orElse`.
/// Un repli réintroduirait les valeurs en dur que ce module supprime, et le
/// garde-fou `test/tutorial/tutorial_fixtures_test.dart` attrape l'absence
/// en CI avant qu'elle n'atteigne l'exécution.
class TutorialFixtures {
  final GameDataRegistry registry;

  const TutorialFixtures(this.registry);

  CardData card(String id) => registry.cards.firstWhere((c) => c.id == id);

  EnemyData get trainingEnemy =>
      registry.enemies.firstWhere((e) => e.id == TutorialFixtureIds.trainingEnemy);

  /// Le Gobelin de démonstration de l'étape XP : son `xp` (35 dans le JSON)
  /// alimente le libellé du bouton sans jamais être recopié en dur.
  EnemyData get goblin =>
      registry.enemies.firstWhere((e) => e.id == TutorialFixtureIds.goblin);

  RelicData get sampleRelic =>
      registry.relics.firstWhere((r) => r.id == TutorialFixtureIds.sampleRelic);

  List<HeroData> get heroes => TutorialFixtureIds.heroes
      .map((id) => registry.heroes.firstWhere((h) => h.id == id))
      .toList();

  /// Le passif de la classe au tutoriel : le premier que lui ouvre le point
  /// d'accès unique — le choix par défaut de l'écran de sélection (spec
  /// P-49, §4.2), qui lui laisse au joueur la main pour en retenir un autre.
  PassiveData passiveFor(HeroData hero) =>
      availablePassivesFor(hero, registry).first;

  /// Le pool du draft de départ, filtré et trié comme `StarterDeckDraftScreen`.
  List<CardData> get starterPool => registry.cards
      .where((c) => c.category == CardCategory.global && c.type != CardType.status)
      .toList()
    ..sort(CardData.compareByDisplayOrder);
}
