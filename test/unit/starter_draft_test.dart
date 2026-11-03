import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/starter_draft.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

CardData _card(
  String id, {
  String? passive,
  CardRarity rarity = CardRarity.common,
  int cost = 1,
  CardType type = CardType.attack,
}) => CardData(
  id: id,
  nameEn: id,
  nameFr: id,
  cost: cost,
  type: type,
  rarity: rarity,
  target: CardTarget.singleEnemy,
  effects: const [],
  passive: passive,
);

List<CardData> _lot(int n) => [
  for (var i = 0; i < n; i++) _card('lot_$i', passive: 'rage'),
];

List<CardData> _neutrals(int n) => [
  for (var i = 0; i < n; i++) _card('neutral_$i'),
];

void main() {
  test('le pool : le lot du passif actif puis les neutres, chacun trie ; '
      'ni statut ni autre lot', () {
    final rageRare = _card('r_rare', passive: 'rage', rarity: CardRarity.rare);
    final rageCost2 = _card('r_cost2', passive: 'rage', cost: 2);
    final rageCost1 = _card('r_cost1', passive: 'rage');
    final cards = [
      rageRare,
      _card('f_a', passive: 'fervor'),
      _card('n_rare', rarity: CardRarity.rare),
      rageCost2,
      _card('f_b', passive: 'fervor'),
      _card('wound', type: CardType.status),
      rageCost1,
      _card('n_cost2', cost: 2),
      _card('n_cost1'),
    ];

    final draft = StarterDraft.of(cards, 'rage');

    expect(draft.lot.map((c) => c.id), ['r_cost1', 'r_cost2', 'r_rare']);
    expect(draft.neutrals.map((c) => c.id), ['n_cost1', 'n_cost2', 'n_rare']);
    expect(draft.pool.map((c) => c.id), [
      'r_cost1',
      'r_cost2',
      'r_rare',
      'n_cost1',
      'n_cost2',
      'n_rare',
    ]);
    expect(StarterDraft.of(cards, null).lot, isEmpty);
  });

  test('les quotas : 2 et 3, ajustes quand le lot a moins de deux cartes', () {
    for (final (size, lotQuota, neutralQuota) in [
      (6, 2, 3),
      (1, 1, 4),
      (0, 0, 5),
    ]) {
      final draft = StarterDraft.of([..._lot(size), ..._neutrals(8)], 'rage');
      expect(draft.lotQuota, lotQuota, reason: 'lot de $size');
      expect(draft.neutralQuota, neutralQuota, reason: 'lot de $size');
    }
  });

  test('accepts refuse au-dela du quota de son groupe', () {
    final draft = StarterDraft.of([..._lot(6), ..._neutrals(8)], 'rage');

    final twoLot = [draft.lot[0], draft.lot[1]];
    expect(draft.accepts(twoLot, draft.lot[2]), isFalse);
    expect(draft.accepts(twoLot, draft.neutrals[0]), isTrue);

    final threeNeutrals = draft.neutrals.take(3).toList();
    expect(draft.accepts(threeNeutrals, draft.neutrals[3]), isFalse);
    expect(draft.accepts(threeNeutrals, draft.lot[0]), isTrue);
  });

  test('isComplete a 2 + 3, ou aux quotas ajustes', () {
    final full = StarterDraft.of([..._lot(6), ..._neutrals(8)], 'rage');
    List<CardData> pick(StarterDraft d, int lot, int neutral) => [
      ...d.lot.take(lot),
      ...d.neutrals.take(neutral),
    ];

    expect(full.isComplete(pick(full, 2, 3)), isTrue);
    expect(full.isComplete(pick(full, 1, 4)), isFalse);
    expect(full.isComplete(pick(full, 2, 2)), isFalse);
    expect(full.isComplete(pick(full, 3, 2)), isFalse);

    final single = StarterDraft.of([..._lot(1), ..._neutrals(8)], 'rage');
    expect(single.isComplete(pick(single, 1, 4)), isTrue);

    final none = StarterDraft.of(_neutrals(8), null);
    expect(none.isComplete(pick(none, 0, 5)), isTrue);
  });
}
