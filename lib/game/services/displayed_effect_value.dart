import '../../models/card_instance.dart';
import '../../models/combat_state.dart';
import '../../models/data/card_data.dart';
import '../../models/effective_card.dart';
import '../../models/entity_stats.dart';
import '../../models/signature_instance.dart';
import '../systems/power_rules.dart';
import 'effect_resolver.dart';

/// La seule règle du chiffre qu'un effet montre en combat — le badge et
/// l'infobulle d'une carte, la bande et la liste d'une signature : ce que le
/// moteur jouerait maintenant, avant ce que la cible y change (Armure,
/// Vulnérable, Faiblesse) et sans critique.
abstract final class DisplayedEffectValue {
  /// La valeur de [effect] : sa valeur plus le terme de croissance
  /// [scaleTerm], plus la part de Puissance par coup de [damageBonus] pour un
  /// `damage`, ou [statusBonus] pour un `apply_status`.
  static int of(
    CardEffect effect, {
    int damageBonus = 0,
    int scaleTerm = 0,
    int statusBonus = 0,
  }) =>
      effect.value +
      scaleTerm +
      switch (effect.type) {
        'damage' => effect.mightPerHit(damageBonus),
        'apply_status' => statusBonus,
        _ => 0,
      };

  /// [value] écrit pour un effet de [hits] coups : suivi de `×coups` dès deux
  /// coups.
  static String format(int value, {int hits = 1}) =>
      hits >= 2 ? '$value×$hits' : '$value';

  /// [value] écrit pour [effect] : seul un `damage` compte ses coups.
  static String label(CardEffect effect, int value) =>
      format(value, hits: effect.type == 'damage' ? effect.hits : 1);

  /// La valeur de [effect], de rang [order] dans l'ordre de résolution de
  /// [effective] — les effets ajoutés, puis les propres —, porté par une carte
  /// de type [type] et de cible [target], lue sur [hero] et [combat] comme le
  /// moteur la lirait. Sans héros, aucune Puissance ; sans combat, aucun terme
  /// de croissance ; une source de cible vaut 0, la cible n'étant pas choisie
  /// avant le jeu.
  static int inPlay(
    CardEffect effect,
    int order, {
    required EffectiveCard effective,
    required CardType type,
    required CardTarget target,
    required EntityStats? hero,
    required CombatState? combat,
  }) =>
      of(
        effect,
        damageBonus: hero?.damageBonusFor(type) ?? 0,
        scaleTerm: hero == null || combat == null
            ? 0
            : EffectResolver.scaleTerm(
                effect,
                hero: hero,
                combat: combat,
                targetId: null,
              ),
        statusBonus: order == EffectResolver.statusBonusIndex(effective)
            ? hero?.statusBonusFor(target) ?? 0
            : 0,
      );

  /// La valeur de l'effet propre [index] de [card], celui de
  /// `EffectiveCard.effects` que sa face montre.
  static int ofCardEffect(
    CardInstance card,
    int index, {
    required EntityStats? hero,
    required CombatState? combat,
  }) {
    final effective = card.effective;
    return inPlay(
      effective.effects[index],
      effective.addedEffects.length + index,
      effective: effective,
      type: card.data.type,
      target: card.data.target,
      hero: hero,
      combat: combat,
    );
  }

  /// Les entrées de la bande et de la liste de [signature], à leurs valeurs
  /// de combat : les mêmes que celles d'une carte de sa vue de carte.
  static List<EffectLine> signatureLines(
    SignatureInstance signature, {
    required EntityStats hero,
    required CombatState combat,
  }) {
    final card = signature.asCard;
    final effective = card.effective;
    return signature.effectLines(
      (effect, order) => inPlay(
        effect,
        order,
        effective: effective,
        type: card.data.type,
        target: card.data.target,
        hero: hero,
        combat: combat,
      ),
    );
  }
}
