import 'dart:math' show max;

import 'data/card_data.dart';
import 'data/card_delta.dart';
import 'data/forge_upgrade_data.dart';
import 'data/game_data_registry.dart';

/// La carte telle qu'elle se joue : ses effets à sa rareté, ses runes
/// appliquées. Le moteur la lit, et lui seul calcule ces valeurs (spec P-43
/// E1, §4.2).
class EffectiveCard {
  const EffectiveCard._({
    required this.addedEffects,
    required this.effects,
    required this.removesExhaust,
    required this.cost,
    required this.critChanceBonus,
    required this.addsExhaust,
    required this.armorPiercePercent,
    required this.armorPierceLevel,
    required this.lifestealPercent,
    required this.lifestealLevel,
  });

  /// Les effets que les deltas ajoutent, résolus avant ceux de la carte.
  final List<CardEffect> addedEffects;

  /// Les effets propres de la carte, à leur valeur jouée, alignés un à un sur
  /// `CardData.effects` : un rendu peut les lire en regard.
  final List<CardEffect> effects;

  /// Vrai si un delta lève l'épuisement de la carte.
  final bool removesExhaust;

  /// Le coût en Mana que la carte demande : celui de la donnée, moins ce que
  /// les deltas lui retirent, jamais sous 0 — la rareté ne le change jamais
  /// (spec P-43 E2, §4.2).
  final int cost;

  /// Les points de pourcentage de critique que les deltas ajoutent aux dégâts
  /// de la carte (spec P-43 E2, §4.2).
  final int critChanceBonus;

  /// Vrai si un delta épuise la carte ; l'emporte sur [removesExhaust] (spec
  /// P-43 E2, A10).
  final bool addsExhaust;

  /// Le pourcentage de l'Armure de la cible que les coups de la carte ignorent,
  /// et le niveau total des deltas qui le donnent : plancher de l'Armure
  /// ignorée (spec §4.6, A16).
  final int armorPiercePercent;
  final int armorPierceLevel;

  /// Le pourcentage des dégâts infligés que la carte rend en PV, et le niveau
  /// total des deltas qui le donnent : plancher du soin (spec §4.6, A18).
  final int lifestealPercent;
  final int lifestealLevel;

  /// La couture commune aux runes et, en vague 5, aux évolutions de
  /// signature : une fonction pure, qui ne lit ni registre ni rune — elle
  /// reçoit des paires *(delta, niveau)*.
  static EffectiveCard apply(
    CardData data,
    CardRarity rarity,
    Iterable<(CardDelta, int)> deltas,
  ) {
    final atRarity = [
      for (final effect in data.effects) _atRarity(effect, rarity),
    ];
    final effects = List<CardEffect>.of(atRarity);
    final added = <CardEffect>[];
    var removesExhaust = false;
    var costReduction = 0;
    var critChanceBonus = 0;
    var addsExhaust = false;
    var armorPiercePercent = 0;
    var armorPierceLevel = 0;
    var lifestealPercent = 0;
    var lifestealLevel = 0;

    for (final (delta, level) in deltas) {
      switch (delta) {
        case PercentBonusDelta():
          // Sur la valeur à la rareté, jamais sur un bonus déjà ajouté : deux
          // pourcentages sur un même effet ne se composent pas.
          for (var i = 0; i < effects.length; i++) {
            if (effects[i].type != delta.effect) continue;
            final hits = effects[i].hits;
            final base = atRarity[i].value;
            // A14 : à plusieurs coups, le bonus se calcule sur le total des
            // coups, plancher compris, puis se répartit vers le haut.
            final perHit = hits == 1
                ? delta.bonusFor(base, level)
                : (delta.bonusFor(base * hits, level) + hits - 1) ~/ hits;
            effects[i] = effects[i].copyWithValue(effects[i].value + perHit);
          }
        case AddEffectDelta():
          added.add(delta.effectAt(level));
        case RemoveExhaustDelta():
          removesExhaust = true;
        case ReduceCostDelta():
          costReduction += delta.valuePerLevel * level;
        case CritBonusDelta():
          critChanceBonus += delta.valuePerLevel * level;
        case AddExhaustDelta():
          addsExhaust = true;
        case ArmorPierceDelta():
          armorPiercePercent += delta.valuePercentPerLevel * level;
          armorPierceLevel += level;
        case LifestealPercentDelta():
          lifestealPercent += delta.valuePercentPerLevel * level;
          lifestealLevel += level;
      }
    }

    return EffectiveCard._(
      addedEffects: List.unmodifiable(added),
      effects: List.unmodifiable(effects),
      removesExhaust: removesExhaust,
      cost: max(0, data.cost - costReduction),
      critChanceBonus: critChanceBonus,
      addsExhaust: addsExhaust,
      armorPiercePercent: armorPiercePercent,
      armorPierceLevel: armorPierceLevel,
      lifestealPercent: lifestealPercent,
      lifestealLevel: lifestealLevel,
    );
  }

  /// Les runes d'une carte traduites en paires *(delta, niveau)* : les
  /// exemplaires d'un même id additionnés (D75, A7), dans l'ordre de leur
  /// première apparition. Une référence mal formée ou de niveau nul est
  /// ignorée ; un id absent du catalogue n'a pas de delta.
  static Iterable<(CardDelta, int)> runeDeltas(
    List<String> runes,
    Iterable<ForgeUpgradeData> catalog,
  ) sync* {
    for (final MapEntry(key: id, value: level)
        in ForgeUpgradeData.levelsOf(runes).entries) {
      final rune = catalog.where((r) => r.id == id).firstOrNull;
      if (rune == null) continue;
      for (final delta in rune.deltas) {
        yield (delta, level);
      }
    }
  }

  /// [data] à [rarity], portant [runes], sur le catalogue du registre — comme
  /// `ForgeUpgradeData.getById`.
  static EffectiveCard withRunes(
    CardData data,
    CardRarity rarity,
    List<String> runes,
  ) =>
      apply(
        data,
        rarity,
        runeDeltas(runes, GameDataRegistry.instance?.forgeUpgrades ?? const []),
      );

  /// G2 : la pioche et le mana rendu ne grandissent pas avec la rareté — la
  /// seule écriture de la règle (brainstorm §4.5, spec P-43 E1, A6, §4.3).
  static const _frozenByRarity = {'draw', 'gain_mana'};

  /// L'effet à la rareté de la carte : G1 (`CardRarity.scaleValue`), sauf
  /// pour ce que G2 gèle.
  static CardEffect _atRarity(CardEffect effect, CardRarity rarity) =>
      _frozenByRarity.contains(effect.type)
          ? effect
          : effect.copyWithValue(rarity.scaleValue(effect.value));
}
