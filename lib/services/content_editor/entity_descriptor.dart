import 'dart:convert';

import 'package:meta/meta.dart';

import '../../models/data/card_data.dart';
import '../../models/data/enemy_data.dart';
import '../../models/data/event_data.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/enemy_intent.dart';

/// Les sept categories d'entites editables. Elles sont en regard exact des
/// sept appels a `loadAll` de `loadGameDataRegistry` — l'audio n'en est pas
/// une, c'est un document de configuration.
enum EntityCategory { card, relic, event, passive, forgeUpgrade, heroClass, enemy }

/// Ce qu'est une ressource : un son declare dans `audio.json`, ou une image
/// dont le nom est impose par l'identifiant.
enum AssetKind { sound, image }

/// Un emplacement de ressource d'une categorie.
@immutable
class AssetSlot {
  const AssetSlot.sound()
      : kind = AssetKind.sound,
        fileName = null,
        isRequired = false;

  const AssetSlot.image(String this.fileName, {this.isRequired = true})
      : kind = AssetKind.image;

  final AssetKind kind;

  /// Le nom du fichier image, jeton `{id}` admis. `null` pour un son.
  final String? fileName;

  /// Vrai si l'entite ne se charge pas sans : l'ecrivain calcule alors la cle
  /// a chaque ecriture. Un son n'est jamais obligatoire.
  final bool isRequired;

  /// Les extensions qu'un import accepte.
  List<String> get extensions => kind == AssetKind.sound
      ? const ['wav', 'mp3', 'ogg']
      : const ['png'];
}

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
    this.hexColorKeys = const {},
    this.assetKeys = const {},
    this.vocabularyKeys = const {},
    this.supportsHeroClass = false,
    this.folderFile,
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

  /// Motif -> valeurs admises, lues sur l'enumeration Dart reelle. Un motif
  /// imbrique (`intents[].type`) vise chaque element.
  final Map<String, List<String>> enumKeys;

  /// Comme [enumKeys], pour une cle portant une **liste** de valeurs.
  final Map<String, List<String>> enumListKeys;

  /// Cle -> categorie que sa valeur doit designer. `passiveTrait` pointe un
  /// passif, et `referential_integrity_test` le verifie deja.
  final Map<String, EntityCategory> referenceKeys;

  /// Les cles dont la valeur, si presente, doit etre un `#RRGGBB` valide —
  /// `themeColor` pour une classe. Une cle absente reste optionnelle et
  /// passe : c'est au gabarit ou au remplissage de la fournir, pas a cette
  /// liste de l'imposer.
  final Set<String> hexColorKeys;

  /// Cle -> emplacement de ressource. Le formulaire rend ces cles en choix de
  /// son ou en import d'image, jamais en texte (spec §5).
  final Map<String, AssetSlot> assetKeys;

  /// Les motifs dont la valeur est une chaine libre dans le modele mais
  /// fermee dans le moteur : un type d'effet inconnu du resolveur ne fait
  /// rien. Admis : les valeurs deja employees sur le disque, et celles du
  /// gabarit (`vocabularyOf`, spec §4.5).
  final Set<String> vocabularyKeys;

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

  /// Les cles de ressource qui sont des images.
  Iterable<String> get imageKeys => assetKeys.entries
      .where((entry) => entry.value.kind == AssetKind.image)
      .map((entry) => entry.key);

  /// Vrai pour une image **obligatoire** : sa cle n'est jamais saisie,
  /// l'ecrivain la calcule a chaque ecriture.
  bool isComputedImage(String key) {
    final slot = assetKeys[key];
    return slot != null && slot.kind == AssetKind.image && slot.isRequired;
  }

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

  /// Le chemin de l'image que [key] designe pour l'entite [id]. Le nom peut
  /// porter le jeton `{id}` : la carte d'une classe est nommee d'apres elle,
  /// le sprite d'un ennemi porte un nom constant. `null` hors image.
  String? imagePathOf(String id, String key) {
    final slot = assetKeys[key];
    final name = slot?.fileName;
    if (slot == null || slot.kind != AssetKind.image || name == null) {
      return null;
    }
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
    assetKeys: const {'sfx': AssetSlot.sound()},
    vocabularyKeys: const {'animation', 'effects[].type', 'effects[].statusId'},
    // Le gabarit ne porte que ce qu'une carte emploie (spec §3.1) : ni
    // `spritePath`, qu'aucune carte ne porte et qu'aucun ecran n'affiche, ni
    // `sfx`, choisi dans le champ de ressource et absent tant qu'aucun son ne
    // l'est.
    template: '''
{
  "cost": 1,
  "type": "attack",
  "rarity": "common",
  "target": "singleEnemy",
  "animation": "melee",
  "isExhaust": false,
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
    assetKeys: const {'sfx': AssetSlot.sound()},
    vocabularyKeys: const {'effectType'},
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
    vocabularyKeys: const {'effectType'},
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
    // imbriques dans `choices` : le formulaire les rend en paires bilingues,
    // dans chaque choix, hors de la famille bilingue.
    bilingualBases: const ['title', 'description'],
    construct: EventData.fromJson,
    vocabularyKeys: const {'choices[].actions[].type'},
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
    // `color` et `icon` ne sont pas un hex ni un texte libre : ce sont des
    // noms que `forge_slot_row.dart` traduit un a un (`amberAccent`,
    // `flash_on_rounded`), et un nom inconnu y retombe en silence sur du gris
    // et `Icons.help_outline`. Les huit ameliorations livrees les emploient.
    vocabularyKeys: const {'color', 'icon'},
    bilingualBases: const ['name', 'description'],
    construct: ForgeUpgradeData.fromJson,
    // `eligibleCardTypes` porte **les quatre** types, et non la liste vide :
    // absente, la cle vaut « tous les types » (`shop_controller.dart:65` ne
    // filtre que si elle est non nulle), tandis qu'une liste vide n'aurait
    // rendu l'amelioration eligible a **rien**. Les quatre types enumeres sont
    // le seul equivalent honnete de l'absence, et l'auteur n'a qu'a retirer ce
    // qu'il ne veut pas.
    template: '''
{
  "icon": "flash_on_rounded",
  "color": "amberAccent",
  "pools": ["common"],
  "eligibleCardTypes": ["attack", "skill", "power", "status"],
  "requiresExhaust": false,
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
    assetKeys: const {
      'classCard': AssetSlot.image('{id}.png'),
      // Optionnelle : les trois classes livrees n'ont pas d'icone dessinee, et
      // `ClassIdentity.imageOf` retombe alors sur `classCard`.
      'iconPath': AssetSlot.image('icon.png', isRequired: false),
    },
    requiredKeys: const {'maxHp', 'maxMana', 'baseDamage'},
    referenceKeys: const {'passiveTrait': EntityCategory.passive},
    hexColorKeys: const {'themeColor'},
    bilingualBases: const ['name', 'description'],
    construct: HeroData.fromJson,
    // Ni `classCard` ni `skills` ne figurent au gabarit : l'ecrivain calcule
    // le premier, et `_registerSignatureCard` remplit le second a chaque carte
    // de classe ecrite. `themeColor` y figure au magenta : une classe dont la
    // couleur n'a pas ete choisie doit se voir.
    template: '''
{
  "maxHp": 100,
  "maxMana": 3,
  "baseDamage": 5,
  "luck": 0,
  "armorMastery": 0,
  "displayOrder": 99,
  "themeColor": "#FF00FF"
}''',
  ),
  EntityCategory.enemy: EntityDescriptor(
    category: EntityCategory.enemy,
    label: 'Ennemi',
    directory: 'enemies',
    folderFile: 'enemy.json',
    requiredKeys: const {'maxHp', 'baseDamage'},
    // Un ennemi n'a **pas** de description : seulement un nom.
    bilingualBases: const ['name'],
    construct: EnemyData.fromJson,
    assetKeys: const {
      'spritePath': AssetSlot.image('sprite.png'),
      'sfx': AssetSlot.sound(),
    },
    enumKeys: {'intents[].type': _names(IntentType.values)},
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
