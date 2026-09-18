import 'package:meta/meta.dart';

import '../reward_rarity.dart';
import 'passive_data.dart';

/// Ce que la récompense fait quand le joueur la prend.
enum RewardEffect {
  /// Elle monte une stat du héros, celle que [LevelUpRewardData.stat] désigne.
  stat,

  /// Elle ouvre le clonage d'une carte — le Miroir. Aucune stat.
  cloneCard,
}

/// La stat qu'une récompense [RewardEffect.stat] fait monter.
///
/// [critDamage] s'écrit **en points de pourcentage entiers** : la donnée dit
/// `10`, l'application divise par 100. Le joueur lit déjà « +10 % », et le
/// catalogue reste sans un seul décimal (décision 5 du plan).
enum RewardStat { maxHp, might, mastery, maxMana, luck, critChance, critDamage }

/// D'où la récompense est tirée.
enum RewardPool {
  /// Les trois emplacements du draft, tirés uniformément dans ce groupe.
  draft,

  /// Une option mythique, offerte par son propre jet et ajoutée aux trois.
  mythic,
}

/// Une récompense de niveau, telle que son fichier la déclare
/// (spec P-41, §8.1, décision D3).
///
/// Avant ce chantier, les huit récompenses étaient huit valeurs d'énumération,
/// un `rng.nextInt(6)`, deux `switch` de valeurs et des libellés en ARB,
/// recopiés à la main dans la prose du tutoriel et dans le rouleau du
/// carrousel. Elles sont désormais huit fichiers sous
/// `assets/data/level_up_rewards/`.
@immutable
class LevelUpRewardData {
  final String id;
  final String nameFr;
  final String nameEn;

  /// Le gabarit de description. Trois substitutions possibles : `{amount}`, la
  /// valeur tirée ; `{passive}`, le nom du passif actif ; `{effect}`, ce que la
  /// Maîtrise tirée apporte à ce passif.
  final String descriptionFr;
  final String descriptionEn;

  /// Le gabarit de repli, quand `{passive}` et `{effect}` ne peuvent pas être
  /// résolus — aucun passif actif, ou un passif sans bloc `mastery`. `null` :
  /// il n'y a rien à replier, la description n'en nomme aucun.
  final String? fallbackDescriptionFr;
  final String? fallbackDescriptionEn;

  /// La ligne du rouleau de draft, qui n'a ni passif ni place. `null` : le
  /// rouleau se rabat sur [fallbackDescriptionFr] puis sur [descriptionFr].
  final String? shortDescriptionFr;
  final String? shortDescriptionEn;

  final RewardEffect effect;

  /// La stat montée ; `null` — et seulement — pour un [RewardEffect] qui n'en
  /// monte aucune.
  final RewardStat? stat;

  final RewardPool pool;

  /// La valeur du gain, palier par palier. Une récompense [RewardPool.draft]
  /// porte les cinq paliers tirables ; une mythique de stat porte
  /// [RewardRarity.mythic] seul.
  final Map<RewardRarity, int> values;

  /// Rang de la récompense dans son groupe de tirage. Donnée de présentation,
  /// comme `HeroData.displayOrder` : l'ordre ne doit dépendre ni de l'ordre de
  /// lecture des fichiers ni de l'alphabet.
  final int displayOrder;

  const LevelUpRewardData({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.descriptionFr,
    required this.descriptionEn,
    this.fallbackDescriptionFr,
    this.fallbackDescriptionEn,
    this.shortDescriptionFr,
    this.shortDescriptionEn,
    required this.effect,
    this.stat,
    required this.pool,
    this.values = const {},
    this.displayOrder = 0,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;

  /// La valeur de cette récompense au palier [rarity] ; 0 pour un palier que
  /// sa table ne déclare pas — le Miroir, qui ne monte aucune stat, comme un
  /// palier qu'un groupe de tirage n'atteint jamais.
  int amountFor(RewardRarity rarity) => values[rarity] ?? 0;

  /// La valeur affichée sur le rouleau de draft : le palier
  /// [RewardRarity.rare] quand la récompense le déclare, sinon son palier
  /// [RewardRarity.mythic].
  ///
  /// Une récompense du pool mythique (le Trèfle) ne déclare aucun palier
  /// `rare` dans sa table [values] : [amountFor] seul y rendrait 0, et le
  /// rouleau afficherait "+0 Chance". Ce repli lit alors son palier
  /// `mythic`, et ne tombe à 0 que si ni l'un ni l'autre n'existe (le
  /// Miroir, dont le gabarit n'interpole pas `{amount}`).
  int get reelAmount =>
      values[RewardRarity.rare] ?? values[RewardRarity.mythic] ?? 0;

  /// La description affichée sur la carte de draft.
  ///
  /// Un gabarit qui nomme `{passive}` ou `{effect}` a besoin d'un passif actif
  /// **qui déclare une Maîtrise** : sans lui, c'est [fallbackDescriptionFr] qui
  /// sert. C'est la règle, unique, qui remplace la branche `case affinity` de
  /// l'ancien `DraftChoiceLabels`.
  String describe(String locale, {required int amount, PassiveData? passive}) {
    final isFr = locale == 'fr';
    final main = isFr ? descriptionFr : descriptionEn;
    final fallback = isFr ? fallbackDescriptionFr : fallbackDescriptionEn;
    final mastery = passive?.mastery;
    final needsPassive = main.contains('{passive}') || main.contains('{effect}');
    final template = needsPassive && mastery == null ? fallback ?? main : main;

    return template
        .replaceAll('{amount}', '$amount')
        .replaceAll('{passive}', passive?.getName(locale) ?? '')
        .replaceAll('{effect}', mastery?.describe(locale, amount) ?? '');
  }

  /// La ligne courte du rouleau. Aucun `{passive}` ni `{effect}` n'y survit :
  /// le rouleau défile sans contexte de run.
  String shortLabel(String locale, {required int amount}) {
    final isFr = locale == 'fr';
    final template = (isFr ? shortDescriptionFr : shortDescriptionEn) ??
        (isFr ? fallbackDescriptionFr : fallbackDescriptionEn) ??
        (isFr ? descriptionFr : descriptionEn);
    return template.replaceAll('{amount}', '$amount');
  }

  /// Les récompenses d'un [pool], triées par `displayOrder` puis par `id` à
  /// rang égal.
  ///
  /// Le tri est porteur : il fixe l'ordre d'apparition des mythiques et
  /// l'ordre des noms dans la prose du tutoriel — pas celui du tirage, qui
  /// est uniforme et donc indifférent à l'ordre de la liste (ce qui
  /// préserve le tirage d'origine, c'est qu'il y ait exactement six
  /// tirables, verrouillé par un test).
  ///
  /// **Deux lecteurs** passent par ici, le tirage (`LevelUpRewardService`)
  /// et la prose du tutoriel (`tutorial_prose.dart`) : un filtre ajouté à
  /// l'un doit l'être ici, pour les deux.
  static List<LevelUpRewardData> inPool(
    List<LevelUpRewardData> rewards,
    RewardPool pool,
  ) =>
      rewards.where((reward) => reward.pool == pool).toList()
        ..sort((a, b) {
          final byOrder = a.displayOrder.compareTo(b.displayOrder);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });

  static const List<RewardRarity> _draftRarities = [
    RewardRarity.common,
    RewardRarity.uncommon,
    RewardRarity.rare,
    RewardRarity.epic,
    RewardRarity.legendary,
  ];

  static T _readEnum<T extends Enum>(Object? value, List<T> values, String key) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    throw FormatException(
      '$key : valeur "$value" inconnue — attendu : '
      '${values.map((v) => v.name).join(', ')}',
    );
  }

  /// Un texte joueur obligatoire, dans une langue. Absent ou vide : faute de
  /// donnée. La règle de `CLAUDE.md` — deux langues pour tout texte joueur —
  /// n'a de valeur que si le chargement la refuse.
  static String _readText(Map<String, dynamic> json, String key, String id) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$id : "$key" est obligatoire (texte non vide)');
    }
    return value;
  }

  /// Un couple de textes optionnel : les deux langues, ou aucune. Une seule
  /// des deux afficherait du français dans un jeu en anglais, sans que rien ne
  /// le signale.
  static (String?, String?) _readOptionalPair(
    Map<String, dynamic> json,
    String base,
    String id,
  ) {
    final fr = json['${base}_fr'] as String?;
    final en = json['${base}_en'] as String?;
    if ((fr == null) != (en == null)) {
      throw FormatException(
        '$id : "$base" doit porter ses deux langues — ${base}_fr et ${base}_en',
      );
    }
    return (fr, en);
  }

  static Map<RewardRarity, int> _readValues(Object? json, String id) {
    if (json is! Map) {
      throw FormatException('$id : values doit être un objet — reçu : $json');
    }
    return {
      for (final entry in json.entries)
        _readEnum(entry.key, RewardRarity.values, '$id : values')
            : entry.value as int,
    };
  }

  factory LevelUpRewardData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final effect = _readEnum(json['effect'], RewardEffect.values, '$id : effect');
    final pool = _readEnum(json['pool'], RewardPool.values, '$id : pool');
    final statJson = json['stat'];

    final RewardStat? stat;
    if (effect == RewardEffect.stat) {
      if (statJson == null) {
        throw FormatException('$id : stat est obligatoire pour effect "stat"');
      }
      stat = _readEnum(statJson, RewardStat.values, '$id : stat');
    } else {
      if (statJson != null) {
        throw FormatException(
          '$id : stat n\'a pas de sens pour effect "${effect.name}"',
        );
      }
      stat = null;
    }

    final values = _readValues(json['values'] ?? const <String, dynamic>{}, id);

    // Un palier manquant est le defaut exact que ce chantier corrige : une
    // cascade sans palier legendaire faisait retomber un legendaire sur la
    // valeur d'un commun (`level_up_reward_values_test.dart`). En donnee, il
    // doit rougir au chargement, pas au tirage.
    if (pool == RewardPool.draft) {
      for (final rarity in _draftRarities) {
        if (!values.containsKey(rarity)) {
          throw FormatException('$id : values ne déclare pas "${rarity.name}"');
        }
      }
    } else if (effect == RewardEffect.stat &&
        !values.containsKey(RewardRarity.mythic)) {
      throw FormatException('$id : values ne déclare pas "mythic"');
    }

    final (fallbackFr, fallbackEn) =
        _readOptionalPair(json, 'fallbackDescription', id);
    final (shortFr, shortEn) = _readOptionalPair(json, 'shortDescription', id);

    return LevelUpRewardData(
      id: id,
      nameFr: _readText(json, 'name_fr', id),
      nameEn: _readText(json, 'name_en', id),
      descriptionFr: _readText(json, 'description_fr', id),
      descriptionEn: _readText(json, 'description_en', id),
      fallbackDescriptionFr: fallbackFr,
      fallbackDescriptionEn: fallbackEn,
      shortDescriptionFr: shortFr,
      shortDescriptionEn: shortEn,
      effect: effect,
      stat: stat,
      pool: pool,
      values: values,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
