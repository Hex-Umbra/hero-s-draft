import 'package:roguelike_card_game/models/data/card_data.dart';

/// Une carte de lot minimale pour [passiveId] (spec P-42 T1 et P-44 lot 1,
/// §4.8). Le masquage ne lit d'une carte que son passif : un registre
/// construit à la main qui attend un passif disponible lui en donne une.
CardData lotCardFor(String passiveId, {CardType type = CardType.skill}) =>
    CardData(
      id: 'lot_$passiveId',
      passive: passiveId,
      cost: 1,
      type: type,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: const [CardEffect(type: 'armor', value: 1)],
    );
