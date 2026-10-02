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
  });

  /// Les effets que les deltas ajoutent, résolus avant ceux de la carte.
  final List<CardEffect> addedEffects;

  /// Les effets propres de la carte, à leur valeur jouée, alignés un à un sur
  /// `CardData.effects` : un rendu peut les lire en regard.
  final List<CardEffect> effects;

  /// Vrai si un delta lève l'épuisement de la carte.
  final bool removesExhaust;

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

    for (final (delta, level) in deltas) {
      switch (delta) {
        case PercentBonusDelta():
          // Sur la valeur à la rareté, jamais sur un bonus déjà ajouté : deux
          // pourcentages sur un même effet ne se composent pas.
          for (var i = 0; i < effects.length; i++) {
            if (effects[i].type != delta.effect) continue;
            effects[i] = _withValue(
              effects[i],
              effects[i].value + delta.bonusFor(atRarity[i].value, level),
            );
          }
        case AddEffectDelta():
          added.add(delta.effectAt(level));
        case RemoveExhaustDelta():
          removesExhaust = true;
      }
    }

    return EffectiveCard._(
      addedEffects: List.unmodifiable(added),
      effects: List.unmodifiable(effects),
      removesExhaust: removesExhaust,
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

  static CardEffect _atRarity(CardEffect effect, CardRarity rarity) =>
      _withValue(effect, (effect.value * rarity.multiplier).round());

  static CardEffect _withValue(CardEffect effect, int value) => CardEffect(
        type: effect.type,
        value: value,
        statusId: effect.statusId,
        duration: effect.duration,
      );
}
