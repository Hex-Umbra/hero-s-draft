import 'card_data.dart';

/// Le vocabulaire de `feeds`, ce qu'un passif nourrit (spec §3.3, A6) : cinq
/// formes, et la lecture inverse — ce qu'une carte montre dans ce vocabulaire.
abstract final class PassiveFeeds {
  static const cardTypes = ['attack', 'skill', 'power'];
  static const effectTypes = [
    'damage',
    'armor',
    'heal',
    'draw',
    'gain_mana',
    'apply_status',
  ];
  static const _costs = ['cost:hp', 'cost:armor'];

  /// `null` si [entry] est dans l'une des cinq formes : un type de carte, un
  /// type d'effet, `status:<id>`, `cost:hp` ou `cost:armor`, `scale:<source>` ;
  /// sinon une phrase qui nomme l'entrée.
  static String? faultOf(String entry) {
    if (cardTypes.contains(entry) ||
        effectTypes.contains(entry) ||
        _costs.contains(entry)) {
      return null;
    }
    if (entry.startsWith('status:') && entry.length > 'status:'.length) {
      return null;
    }
    if (entry.startsWith('scale:') &&
        ScaleSource.values.any((s) => 'scale:${s.name}' == entry)) {
      return null;
    }
    return 'feeds : l\'entree "$entry" n\'est dans aucune des cinq formes '
        '(type de carte, type d\'effet, status:<id>, cost:hp|armor, '
        'scale:<source>)';
  }

  /// Ce que [card] montre, dans le vocabulaire de `feeds` : son type, le type
  /// de chaque effet, les statuts posés, ses coûts en PV et en Armure (un coût
  /// est une touche, C1.3) et la source de chaque croissance.
  static Set<String> exhibitedBy(CardData card) => {
        card.type.name,
        for (final effect in card.effects) ...[
          effect.type,
          if (effect.type == 'apply_status' && effect.statusId != null)
            'status:${effect.statusId}',
          if (effect.scaleWith != null) 'scale:${effect.scaleWith!.source.name}',
        ],
        if (card.hpCost > 0) 'cost:hp',
        if (card.armorCost > 0) 'cost:armor',
      };

  static bool touches(CardData card, Iterable<String> feeds) =>
      feeds.any(exhibitedBy(card).contains);
}
