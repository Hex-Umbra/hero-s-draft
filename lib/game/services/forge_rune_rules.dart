import 'dart:math';

import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/effective_card.dart';

/// Une rune d'une carte du deck, au niveau [level] que la carte porte.
typedef SharpenablePair = ({
  CardInstance card,
  ForgeUpgradeData rune,
  int level,
});

/// Une rune que *Transcendance* peut relever, à son plafond effectif [cap].
typedef RaisableCap = ({ForgeUpgradeData rune, int cap});

/// Les règles des runes de forge, notées `id:niveau` : l'héritage de la
/// fusion 3→1 (D13), son offre, l'affûtage au feu de camp et l'échange au
/// Puits (spec P-43 E2). Les références se lisent par l'analyseur unique du
/// modèle, `ForgeUpgradeData.parseRef` (ADR-094 D5).
class ForgeRuneRules {
  const ForgeRuneRules._();

  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// leurs niveaux s'additionnent, bornés par son `maxLevel` — le surplus se
  /// perd, une rune de plafond 1 reste au niveau 1 (spec P-43 E1, A9 ; spec
  /// P-43 E2, §4.6). Une référence mal formée ou de niveau nul est
  /// ignorée. Deux runes qui s'excluent (`excludesRunes`, dans un sens ou
  /// l'autre) ne sont jamais réunies : la première arrivée est gardée, car la
  /// fusion ne doit pas rouvrir ce que ferment D44, D51 et D61.
  static List<String> consolidate(Iterable<String> runes) {
    final kept = <String>[];
    final result = <String>[];
    for (final MapEntry(key: id, value: tier)
        in ForgeUpgradeData.levelsOf(runes).entries) {
      if (kept.any((other) => _exclude(id, other))) continue;
      kept.add(id);
      result.add('$id:${_bounded(id, tier)}');
    }
    return result;
  }

  /// Les runes [a] et [b] s'excluent-elles ? Symétrique, lu dans le registre ;
  /// une rune absente du registre n'exclut rien et n'est exclue par rien.
  static bool _exclude(String a, String b) =>
      (ForgeUpgradeData.getById(a)?.excludesRunes.contains(b) ?? false) ||
      (ForgeUpgradeData.getById(b)?.excludesRunes.contains(a) ?? false);

  /// [tier] borné par le plafond de la rune [id] (D72) ; une rune absente du
  /// registre n'en a pas.
  static int _bounded(String id, int tier) =>
      ForgeUpgradeData.getById(id)?.boundLevel(tier) ?? tier;

  /// La rune [rune] peut-elle s'offrir à [card] ? Le prédicat unique de
  /// l'éligibilité (D3, D44, D48, D51, D61 ; spec P-43 E1, A3, §4.6 ; spec
  /// P-43 E2, §4.3) : une fonction pure, sur le modèle de
  /// `CardData.isOfferableTo` — toute règle est un champ du fichier de rune,
  /// aucune n'est un `case` par id. [card] est la carte qui reçoit la rune, à
  /// son rang : la carte fusionnée au rang qu'elle atteint, la carte
  /// elle-même en boutique et au Puits. [catalog] sert à lire les exclusions
  /// des runes que la carte porte déjà.
  static bool isEligible(
    ForgeUpgradeData rune,
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog,
  ) {
    final types = rune.eligibleCardTypes;
    if (types != null && !types.contains(card.data.type.name)) return false;

    // Les effets propres de la carte, jamais ceux qu'une rune lui ajoute.
    final own = {for (final effect in card.data.effects) effect.type};
    final wanted = rune.eligibleEffects;
    if (wanted != null && !wanted.any(own.contains)) return false;
    if (rune.excludesEffects.any(own.contains)) return false;

    if (rune.requiresExhaust && !card.data.isExhaust) return false;

    // Le coût courant, par l'applicateur sur [catalog] — jamais sur le
    // registre global : le tutoriel juge sur le sien (spec P-43 E2, A15).
    final cost = EffectiveCard.apply(
      card.data,
      card.rarity,
      EffectiveCard.runeDeltas(card.forgeUpgrades, catalog),
    ).cost;
    if (cost < rune.requiresMinCost) return false;

    // D48 : le rang de la carte qui reçoit la rune ; une commune et une
    // carte `unique`, de rang 0, n'en reçoivent aucune.
    if (rune.minFusionRank > card.rarity.fusionRank) return false;

    // La symétrie des exclusions : une rune portée absente du catalogue est
    // ignorée.
    final carried = ForgeUpgradeData.levelsOf(card.forgeUpgrades);
    for (final id in carried.keys) {
      final other = catalog.where((r) => r.id == id).firstOrNull;
      if (other == null) continue;
      if (rune.excludesRunes.contains(id) ||
          other.excludesRunes.contains(rune.id)) {
        return false;
      }
    }

    // D3 : une seule rune de chaque type par carte — une rune portée ne se
    // repropose jamais, plafond atteint ou non (D75 en est un cas).
    return !carried.containsKey(rune.id);
  }

  /// Jusqu'à [count] ids **distincts** de runes du [catalog] que le prédicat
  /// accepte sur [card], tirés pondérés par `weight`, sans remise (D3, D65 ;
  /// spec P-43 E2, A2, §4.4) : moins s'il y en a moins, aucun s'il n'y en a
  /// pas. Une fonction pure, sur ses entrées ; [card] est la carte qui reçoit
  /// la rune — la carte fusionnée, au rang qu'elle atteint. Un poids nul ou
  /// négatif ne pèse rien ; des runes éligibles qui ne pèsent rien se tirent
  /// encore, à parts égales : jamais aucune tant qu'une existe (D65).
  static List<String> drawRunes(
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog,
    Random rng, {
    required int count,
  }) {
    final pool = [
      for (final rune in catalog)
        if (isEligible(rune, card, catalog)) rune,
    ];
    final drawn = <String>[];
    while (drawn.length < count && pool.isNotEmpty) {
      final weights = [for (final rune in pool) max(0, rune.weight)];
      final total = weights.fold(0, (sum, weight) => sum + weight);
      var index = 0;
      if (total == 0) {
        index = rng.nextInt(pool.length);
      } else {
        var pick = rng.nextInt(total);
        while (pick >= weights[index]) {
          pick -= weights[index];
          index++;
        }
      }
      drawn.add(pool.removeAt(index).id);
    }
    return drawn;
  }

  /// Les runes de [deck] que *Transcendance* peut relever (spec P-43 E3,
  /// §4.8 ; D42(c), A15, A16) : celles qu'une carte porte à leur plafond
  /// effectif — `maxLevel` plus [capBonus] pour leur id —, ni sans plafond
  /// ni `binary`, une fois chacune, dans l'ordre du [catalog], avec ce
  /// plafond. Lues par l'écran de draft, pour la condition `raisableRune`
  /// et pour la modale.
  static List<RaisableCap> raisableCaps(
    Iterable<CardInstance> deck,
    Iterable<ForgeUpgradeData> catalog, {
    Map<String, int> capBonus = const {},
  }) {
    final carried = <String, int>{};
    for (final card in deck) {
      for (final MapEntry(key: id, value: level)
          in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries) {
        carried[id] = max(carried[id] ?? 0, level);
      }
    }
    return [
      for (final rune in catalog)
        if (rune.maxLevel case final maxLevel?
            when !rune.binary &&
                (carried[rune.id] ?? 0) >=
                    maxLevel + (capBonus[rune.id] ?? 0))
          (rune: rune, cap: maxLevel + (capBonus[rune.id] ?? 0)),
    ];
  }

  /// `b`, le coût d'un niveau d'affûtage par niveau porté (D63 ; spec P-43
  /// E2, §4.7).
  static const sharpenBaseCost = 50;

  /// Le coût pour monter d'un niveau une rune portée au niveau [level] : il
  /// croît avec le niveau de la rune, pas avec le rang de la carte (D20).
  static int sharpenCost(int level) => sharpenBaseCost * level;

  /// La rune [rune], portée au niveau [level], peut-elle monter d'un niveau ?
  /// Son plafond effectif le dit — `maxLevel` plus [capBonus] pour son id —,
  /// par la borne (D72 ; spec P-43 E3, A17).
  static bool canSharpen(
    ForgeUpgradeData rune,
    int level, {
    Map<String, int> capBonus = const {},
  }) =>
      rune.boundLevel(1, carried: level, capBonus: capBonus[rune.id] ?? 0) >=
      1;

  /// [card] porte-t-elle une rune que l'affûtage peut monter, sous son
  /// plafond effectif ([capBonus], spec P-43 E3, A17) ? Une rune absente du
  /// [catalog] ne se monte pas. Lu par l'option du feu, par sa sélection
  /// (spec P-43 E2, A4) et par la condition du *Rémouleur*,
  /// `EventController.isChoiceSelectable` (spec P-43 E3, §4.9).
  static bool hasSharpenableRune(
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog, {
    Map<String, int> capBonus = const {},
  }) =>
      ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries.any((entry) {
        final rune = catalog.where((r) => r.id == entry.key).firstOrNull;
        return rune != null &&
            canSharpen(rune, entry.value, capBonus: capBonus);
      });

  /// Les paires (carte, rune) de [deck] dont la rune peut encore monter d'un
  /// niveau sous son plafond effectif ([capBonus], A17) — celles que tire le
  /// boss « XP » (spec P-43 E3, §4.6, A14) —, dans l'ordre du deck puis des
  /// runes de chaque carte. Une rune absente du [catalog] ne se monte pas.
  static List<SharpenablePair> sharpenablePairs(
    Iterable<CardInstance> deck,
    Iterable<ForgeUpgradeData> catalog, {
    Map<String, int> capBonus = const {},
  }) {
    final pairs = <SharpenablePair>[];
    for (final card in deck) {
      for (final MapEntry(key: id, value: level)
          in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries) {
        final rune = catalog.where((r) => r.id == id).firstOrNull;
        if (rune != null && canSharpen(rune, level, capBonus: capBonus)) {
          pairs.add((card: card, rune: rune, level: level));
        }
      }
    }
    return pairs;
  }

  /// [refs] où la référence de la rune [runeId] cède la place à
  /// [replacement], à sa place (spec P-43 E2, §4.7, §4.8) : l'affûtage la
  /// réécrit `id:n+1`, le Puits y met la rune reçue. Une référence mal formée
  /// reste telle quelle.
  static List<String> replaceRune(
    List<String> refs,
    String runeId,
    String replacement,
  ) =>
      [
        for (final ref in refs)
          ForgeUpgradeData.parseRef(ref)?.$1 == runeId ? replacement : ref,
      ];

  /// La base du prix du Puits d'échange (spec P-43 E2, A6) : distincte de
  /// [sharpenBaseCost] — deux prix que la mesure fait varier séparément.
  static const wellBaseCost = 50;

  /// Le coût d'un échange au Puits : la base fois le niveau de la rune
  /// donnée (D6, D39).
  static int wellCost(int givenLevel) => wellBaseCost * givenLevel;

  /// Le niveau auquel [received] entre au Puits contre une rune de niveau
  /// [givenLevel] (D39) : les deux tiers, arrondis au plus proche — deux
  /// tiers d'un entier ne tombent jamais sur une demie —, au moins 1 dès le
  /// niveau 1, puis bornés par le plafond effectif de [received] — son
  /// `maxLevel` plus [capBonus] pour son id (D72 ; spec P-43 E3, A17).
  static int wellLevel(
    ForgeUpgradeData received,
    int givenLevel, {
    Map<String, int> capBonus = const {},
  }) =>
      received.boundLevel(
        (2 * givenLevel + 1) ~/ 3,
        capBonus: capBonus[received.id] ?? 0,
      );

  /// Les runes du [catalog] qui peuvent remplacer la rune [givenId] de
  /// [card] au Puits (spec P-43 E2, A5, §4.8) : toutes celles que le
  /// prédicat accepte sur la carte **sans** la rune donnée, à son rang — une
  /// exclusion que l'échange défait ne refuse rien —, la rune donnée
  /// exclue. Dans l'ordre du catalogue.
  static List<ForgeUpgradeData> wellOptions(
    CardInstance card,
    String givenId,
    Iterable<ForgeUpgradeData> catalog,
  ) {
    final without = card.copyWith(forgeUpgrades: [
      for (final ref in card.forgeUpgrades)
        if (ForgeUpgradeData.parseRef(ref)?.$1 != givenId) ref,
    ]);
    return [
      for (final rune in catalog)
        if (rune.id != givenId && isEligible(rune, without, catalog)) rune,
    ];
  }
}
