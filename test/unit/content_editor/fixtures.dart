import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';

/// Les entites sont construites par leur **vrai** `fromJson`, jamais par leur
/// constructeur : une fixture ecrite a la main derive du modele sans que rien
/// ne le signale.
CardData fixtureCard(String id) => CardData.fromJson({
      'id': id,
      'name_en': 'x',
      'name_fr': 'x',
      'description_en': 'x',
      'description_fr': 'x',
      'cost': 1,
      'type': 'attack',
      'category': 'global',
      'rarity': 'common',
      'target': 'singleEnemy',
    });

PassiveData fixturePassive(String id) => PassiveData.fromJson({
      'id': id,
      'name_en': 'x',
      'name_fr': 'x',
      'description_en': 'x',
      'description_fr': 'x',
      'trigger': 'startOfTurn',
      'effectType': 'gain_armor',
      'value': 1,
    });

HeroData fixtureHero(String id) => HeroData.fromJson({
      'id': id,
      'name_en': 'x',
      'name_fr': 'x',
      'classCard': 'assets/data/classes/$id/$id.png',
      'maxHp': 80,
      'maxMana': 3,
      'mightTargets': ['attack'],
    });

GameDataRegistry fixtureRegistry({
  List<CardData> cards = const [],
  List<HeroData> heroes = const [],
  List<PassiveData> passives = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: heroes,
      cards: cards,
      events: const [],
      passives: passives,
      relics: const [],
      forgeUpgrades: const [],
      audio: const AudioData.disabled(),
    );

/// Un brouillon de relique valide, dont chaque test ne change que ce qu'il
/// veut casser.
EntityDraft fixtureRelicDraft({
  String id = 'talisman_de_fer',
  String? mechanics,
  Map<String, String>? bilingual,
  bool isModification = false,
}) {
  final descriptor = kEntityDescriptors[EntityCategory.relic]!;
  return EntityDraft(
    descriptor: descriptor,
    id: id,
    isModification: isModification,
    bilingual: bilingual ??
        const {
          'name_fr': 'Talisman de fer',
          'name_en': 'Iron Talisman',
          'description_fr': 'Donne 5 armure au debut du combat.',
          'description_en': 'Gain 5 armor at the start of combat.',
        },
    mechanics: mechanics ?? descriptor.template,
  );
}
