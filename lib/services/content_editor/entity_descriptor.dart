import 'dart:convert';

import 'package:meta/meta.dart';

import '../../models/data/card_data.dart';
import '../../models/data/enemy_data.dart';
import '../../models/data/event_data.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/data/relic_data.dart';

/// Les sept categories d'entites editables. Elles sont en regard exact des
/// sept appels a `loadAll` de `loadGameDataRegistry` — l'audio n'en est pas
/// une, c'est un document de configuration.
enum EntityCategory { card, relic, event, passive, forgeUpgrade, heroClass, enemy }

/// Ce qu'est une categorie : un chemin, des cles, et un `fromJson`.
///
/// Tout ce qui distingue une categorie d'une autre tient dans cette table.
/// Aucune de ces informations n'a besoin d'etre du code, et aucune ne doit
/// etre recopiee ailleurs.
@immutable
class EntityDescriptor {
  const EntityDescriptor({
    required this.category,
    required this.label,
    required this.directory,
    required this.requiredKeys,
    required this.bilingualBases,
    required this.construct,
    required this.template,
    this.forbiddenKeys = const {},
    this.enumKeys = const {},
    this.enumListKeys = const {},
    this.referenceKeys = const {},
    this.supportsHeroClass = false,
    this.folderFile,
    this.imageName,
    this.imagePathKey,
  });

  final EntityCategory category;

  /// Le nom montre a l'ecran. Au singulier.
  final String label;

  /// Le repertoire sous `assets/data/`.
  final String directory;

  /// Les cles sans lesquelles l'entite n'a pas de sens. `id` n'y figure pas :
  /// il vient du triangle d'identite, pas du corps.
  final Set<String> requiredKeys;

  /// Les cles que le repertoire impose et qu'un fichier ne doit pas porter.
  /// Voir `EntitySource.redundantFields` : seul `id` est redeclarable.
  final Set<String> forbiddenKeys;

  /// Cle -> valeurs admises, lues sur l'enumeration Dart reelle.
  final Map<String, List<String>> enumKeys;

  /// Comme [enumKeys], pour une cle portant une **liste** de valeurs.
  final Map<String, List<String>> enumListKeys;

  /// Cle -> categorie que sa valeur doit designer. `passiveTrait` pointe un
  /// passif, et `referential_integrity_test` le verifie deja.
  final Map<String, EntityCategory> referenceKeys;

  /// Les bases dont les deux variantes `_fr` et `_en` sont exigees. Elles ne
  /// sont **pas** les memes partout : un evenement porte `title`, un ennemi
  /// n'a pas de description.
  final List<String> bilingualBases;

  /// Le `fromJson` reel du modele. Il ne rend rien : on ne l'appelle que pour
  /// savoir s'il leve.
  final void Function(Map<String, dynamic> json) construct;

  /// La mecanique pre-remplie, montree dans l'editeur au moment de creer.
  final String template;

  /// Vrai pour la seule carte, qui peut etre neutre ou appartenir a une classe.
  final bool supportsHeroClass;

  /// Pour les categories qui sont un **dossier** : le nom du fichier qu'il
  /// porte (`class.json`, `enemy.json`).
  final String? folderFile;

  /// Le nom de l'image que ce dossier doit porter.
  final String? imageName;

  /// La cle sous laquelle le chemin de cette image est ecrit dans le JSON.
  final String? imagePathKey;

  /// Le chemin du fichier, relatif a la racine du projet.
  String pathOf(String id, {String? heroClass}) {
    if (supportsHeroClass && heroClass != null) {
      return 'assets/data/classes/$heroClass/cards/$id.json';
    }
    if (folderFile != null) {
      return 'assets/data/$directory/$id/$folderFile';
    }
    return 'assets/data/$directory/$id.json';
  }

  /// Le chemin de l'image, pour les categories qui en portent une.
  ///
  /// [imageName] peut porter le jeton `{id}` : la carte d'une classe est
  /// nommee d'apres elle (`gambler/gambler.png`), la ou le sprite d'un ennemi
  /// porte un nom constant.
  String? imagePathOf(String id) {
    final name = imageName;
    if (name == null) return null;
    return 'assets/data/$directory/$id/${name.replaceAll('{id}', id)}';
  }

  Map<String, dynamic> decodeTemplate() =>
      jsonDecode(template) as Map<String, dynamic>;
}

List<String> _names(List<Enum> values) =>
    values.map((e) => e.name).toList(growable: false);

/// **La declaration des categories editables.** A tenir en regard des sept
/// sources de `loadGameDataRegistry` ; un test verifie qu'aucune ne manque.
final Map<EntityCategory, EntityDescriptor> kEntityDescriptors = {
  EntityCategory.card: EntityDescriptor(
    category: EntityCategory.card,
    label: 'Carte',
    directory: 'cards',
    supportsHeroClass: true,
    requiredKeys: const {'cost', 'type'},
    // Le repertoire impose l'appartenance : les declarer fait echouer le
    // chargement depuis l'expiration de la tolerance de migration (ADR-086).
    forbiddenKeys: const {'heroClass', 'category'},
    enumKeys: {
      'type': _names(CardType.values),
      'rarity': _names(CardRarity.values),
      'target': _names(CardTarget.values),
    },
    bilingualBases: const ['name', 'description'],
    construct: CardData.fromJson,
    template: '''
{
  "cost": 1,
  "type": "attack",
  "rarity": "common",
  "target": "singleEnemy",
  "animation": "melee",
  "effects": [
    { "type": "damage", "value": 6 }
  ],
  "baseMaxForgeUpgrades": 1
}''',
  ),
  EntityCategory.relic: EntityDescriptor(
    category: EntityCategory.relic,
    label: 'Relique',
    directory: 'relics',
    requiredKeys: const {'trigger', 'effectType', 'value', 'rarity'},
    enumKeys: {
      'trigger': _names(RelicTrigger.values),
      'rarity': _names(RelicRarity.values),
    },
    bilingualBases: const ['name', 'description'],
    construct: RelicData.fromJson,
    template: '''
{
  "trigger": "startOfCombat",
  "effectType": "gain_armor",
  "value": 5,
  "rarity": "common",
  "emoji": "🪙"
}''',
  ),
  EntityCategory.passive: EntityDescriptor(
    category: EntityCategory.passive,
    label: 'Passif',
    directory: 'passives',
    requiredKeys: const {'trigger', 'effectType', 'value'},
    enumKeys: {'trigger': _names(RelicTrigger.values)},
    bilingualBases: const ['name', 'description'],
    construct: PassiveData.fromJson,
    template: '''
{
  "trigger": "startOfTurn",
  "effectType": "gain_armor",
  "value": 2
}''',
  ),
  EntityCategory.event: EntityDescriptor(
    category: EntityCategory.event,
    label: 'Événement',
    directory: 'events',
    requiredKeys: const {'choices'},
    // Un evenement porte `title`, pas `name`. Les textes de ses choix sont
    // imbriques deux niveaux plus bas et restent dans la partie JSON.
    bilingualBases: const ['title', 'description'],
    construct: EventData.fromJson,
    template: '''
{
  "choices": [
    {
      "text_fr": "Accepter",
      "text_en": "Accept",
      "result_text_fr": "Vous gagnez 20 pieces.",
      "result_text_en": "You gain 20 gold.",
      "actions": [
        { "type": "gold", "value": 20 }
      ]
    }
  ]
}''',
  ),
  EntityCategory.forgeUpgrade: EntityDescriptor(
    category: EntityCategory.forgeUpgrade,
    label: 'Amélioration de forge',
    directory: 'forge_upgrades',
    // `ForgeUpgradeData.fromJson` ne leve sur rien d'autre que `id` : toutes
    // les autres cles ont un defaut. C'est la categorie ou la validation
    // declarative fait tout le travail.
    requiredKeys: const {'pools'},
    enumListKeys: {'eligibleCardTypes': _names(CardType.values)},
    bilingualBases: const ['name', 'description'],
    construct: ForgeUpgradeData.fromJson,
    template: '''
{
  "icon": "bolt",
  "color": "#FFAA00",
  "pools": ["common"],
  "valueMultiplier": 1,
  "weight": 10,
  "emoji": "🔮"
}''',
  ),
  EntityCategory.heroClass: EntityDescriptor(
    category: EntityCategory.heroClass,
    label: 'Classe',
    directory: 'classes',
    folderFile: 'class.json',
    imageName: '{id}.png',
    imagePathKey: 'classCard',
    requiredKeys: const {'maxHp', 'maxMana', 'baseDamage'},
    referenceKeys: const {'passiveTrait': EntityCategory.passive},
    bilingualBases: const ['name', 'description'],
    construct: HeroData.fromJson,
    // Ni `classCard` ni `skills` ne figurent au gabarit : l'ecrivain calcule le
    // premier, et le second se remplit carte par carte (Task 6).
    template: '''
{
  "maxHp": 100,
  "maxMana": 3,
  "baseDamage": 5,
  "luck": 0,
  "displayOrder": 99
}''',
  ),
  EntityCategory.enemy: EntityDescriptor(
    category: EntityCategory.enemy,
    label: 'Ennemi',
    directory: 'enemies',
    folderFile: 'enemy.json',
    imageName: 'sprite.png',
    imagePathKey: 'spritePath',
    requiredKeys: const {'maxHp', 'baseDamage'},
    // Un ennemi n'a **pas** de description : seulement un nom.
    bilingualBases: const ['name'],
    construct: EnemyData.fromJson,
    template: '''
{
  "maxHp": 30,
  "baseDamage": 5,
  "tier": 1,
  "xp": 35,
  "critChance": 0,
  "gold": 10,
  "intents": [
    { "type": "attack", "value": 5 }
  ]
}''',
  ),
};
