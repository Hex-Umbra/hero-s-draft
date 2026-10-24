import 'card_instance.dart';
import 'data/card_data.dart';
import 'data/signature_data.dart';

/// Une signature en jeu : sa donnée, et sa vue de carte (spec P-43 E4, §4.1).
class SignatureInstance {
  final SignatureData data;

  const SignatureInstance(this.data);

  /// Le coût à payer. La vague 5 y appliquera les évolutions.
  int get cost => data.cost;

  /// La recharge, en tours. La vague 5 y appliquera les évolutions.
  int get cooldown => data.cooldown;

  /// La signature sous la forme d'une carte, pour que le moteur de jeu et le
  /// rendu la lisent comme une carte. Neuve à chaque appel : commune, sans
  /// rune, et jamais épuisée.
  CardInstance get asCard => CardInstance(
        data: CardData(
          id: data.id,
          nameEn: data.nameEn,
          nameFr: data.nameFr,
          descriptionEn: data.descriptionEn,
          descriptionFr: data.descriptionFr,
          cost: cost,
          type: data.type,
          rarity: CardRarity.common,
          target: data.target,
          animation: data.animation,
          sfx: data.sfx,
          isExhaust: false,
          effects: data.effects,
        ),
      );
}
