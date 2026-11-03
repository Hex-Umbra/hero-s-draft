import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/lot_rules.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/passive_feeds.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les cartes et signatures livrées, vues comme (id, coût, effets).
Iterable<(String, int, List<CardEffect>)> _costed(GameDataRegistry registry) =>
    [
      for (final c in registry.cards) (c.id, c.cost, c.effects),
      for (final s in registry.signatures) (s.id, s.cost, s.effects),
    ];

/// (type, statusId, value, duration, hits, mightRatio, scaleWith.source,
/// scaleWith.ratio) d'un effet.
typedef _Fx = (String, String?, int, int?, int, double, String?, double?);

_Fx _fx(
  String type,
  int value, {
  String? status,
  int? duration,
  int hits = 1,
  double mightRatio = 1,
  String? scale,
  double? ratio,
}) =>
    (type, status, value, duration, hits, mightRatio, scale, ratio);

/// Spec §3.4 : passif, mana, PV, Armure, type, cible, effets.
final _lots = <String, (String, int, int, int, String, String, List<_Fx>)>{
  'bulwark': ('regen_armor', 2, 0, 0, 'skill', 'self', [_fx('armor', 12)]),
  'bastion': (
    'regen_armor', 3, 0, 0, 'power', 'self',
    [_fx('apply_status', 3, status: 'armor_regen', duration: 4)],
  ),
  'rampart_slam': (
    'regen_armor', 1, 0, 0, 'attack', 'singleEnemy',
    [_fx('damage', 2, scale: 'armor', ratio: 1)],
  ),
  'fortify': (
    'regen_armor', 1, 0, 0, 'skill', 'self',
    [_fx('armor', 6, scale: 'armor', ratio: 0.2)],
  ),
  'breach': (
    'regen_armor', 0, 0, 4, 'attack', 'singleEnemy', [_fx('damage', 10)],
  ),
  'shield_burst': (
    'regen_armor', 1, 0, 6, 'attack', 'allEnemies', [_fx('damage', 8)],
  ),
  'bloodletting': (
    'rage', 0, 4, 0, 'attack', 'singleEnemy', [_fx('damage', 8)],
  ),
  'blood_pact': ('rage', 1, 3, 0, 'skill', 'self', [_fx('draw', 2)]),
  'last_breath': (
    'rage', 2, 0, 0, 'attack', 'singleEnemy',
    [_fx('damage', 4, scale: 'missingHp', ratio: 0.2)],
  ),
  'blood_fury': (
    'rage', 1, 0, 0, 'skill', 'self',
    [
      _fx('apply_status', 1,
          status: 'might', duration: 1, scale: 'missingHp', ratio: 0.1),
    ],
  ),
  'trance': (
    'rage', 2, 0, 0, 'power', 'self',
    [_fx('apply_status', 1, status: 'might_regen', duration: 3)],
  ),
  'demon_form': (
    'rage', 2, 0, 0, 'power', 'self',
    [_fx('apply_status', 2, status: 'might', duration: 4)],
  ),
  'arcane_shard': (
    'mana_flux', 1, 0, 0, 'skill', 'singleEnemy', [_fx('damage', 5)],
  ),
  'arcane_wave': (
    'mana_flux', 2, 0, 0, 'skill', 'allEnemies', [_fx('damage', 4)],
  ),
  'kindle': (
    'mana_flux', 1, 0, 0, 'skill', 'singleEnemy',
    [_fx('apply_status', 4, status: 'burn', duration: 3)],
  ),
  'spark_barrage': (
    'mana_flux', 2, 0, 0, 'skill', 'singleEnemy',
    [
      _fx('apply_status', 1, status: 'shock', duration: 1),
      _fx('damage', 3, hits: 3, mightRatio: 0.5),
    ],
  ),
  'frost_nova': (
    'mana_flux', 2, 0, 0, 'skill', 'allEnemies',
    [_fx('apply_status', 2, status: 'freeze', duration: 1)],
  ),
  'discharge': (
    'mana_flux', 3, 0, 0, 'skill', 'singleEnemy',
    [
      _fx('damage', 12),
      _fx('apply_status', 2, status: 'vulnerable', duration: 2),
    ],
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async => registry = await loadGameDataRegistry(rootBundle));

  test(
      'D38 : la somme hits x mightRatio ne depasse pas le cout en mana + 1, '
      'cartes et signatures', () {
    final faulty = [
      for (final (id, cost, effects) in _costed(registry))
        if (effects
                .where((e) => e.type == 'damage')
                .fold<double>(0, (sum, e) => sum + e.hits * e.mightRatio) >
            cost + 1 + 1e-9)
          id,
    ];
    expect(faulty, isEmpty);
  });

  test('D17 : aucune neutre ne porte de cout autre que du mana', () {
    final faulty = [
      for (final c in registry.cards)
        if (c.passive == null && (c.hpCost != 0 || c.armorCost != 0)) c.id,
    ];
    expect(faulty, isEmpty);
  });

  test('les 18 cartes de lot sont celles de spec 3.4', () {
    // Les enregistrements portent une liste : on compare leur texte.
    expect({
      for (final c in registry.cards.where((c) => c.passive != null))
        c.id: (
          c.passive!,
          c.cost,
          c.hpCost,
          c.armorCost,
          c.type.name,
          c.target.name,
          [
            for (final e in c.effects)
              (
                e.type,
                e.statusId,
                e.value,
                e.duration,
                e.hits,
                e.mightRatio,
                e.scaleWith?.source.name,
                e.scaleWith?.ratio,
              ),
          ],
        ).toString(),
    }, {for (final e in _lots.entries) e.key: e.value.toString()});
  });

  test('les trois lots : six cartes chacun, communes, aucune isExhaust', () {
    final lotCards = registry.cards.where((c) => c.passive != null);
    expect(
      {
        for (final id in const ['regen_armor', 'rage', 'mana_flux'])
          id: lotCards.where((c) => c.passive == id).length,
      },
      {'regen_armor': 6, 'rage': 6, 'mana_flux': 6},
    );
    expect(lotCards.length, 18);
    expect(lotCards.every((c) => c.rarity == CardRarity.common), isTrue);
    expect(lotCards.any((c) => c.isExhaust), isFalse);
  });

  PassiveData passiveOf(String id) =>
      registry.passives.singleWhere((p) => p.id == id);

  test('D45 : chaque carte de lot touche une entree des feeds de son passif',
      () {
    final faulty = [
      for (final c in registry.cards.where((c) => c.passive != null))
        if (!PassiveFeeds.touches(c, passiveOf(c.passive!).feeds)) c.id,
    ];
    expect(faulty, isEmpty);
  });

  test(
      'A7 : aucune carte de lot ne coute d Armure sous une classe qui '
      'convertit l Armure', () {
    final faulty = [
      for (final c in registry.cards.where((c) => c.passive != null))
        ...LotRules.faultsOf(
          c,
          passive: passiveOf(c.passive!),
          heroClass: registry.heroes.singleWhere(
            (h) => h.id == passiveOf(c.passive!).classes!.single,
          ),
        ).map((f) => '${c.id} : $f'),
    ];
    expect(faulty, isEmpty);
  });

  test(
      'D50 : par passif pourvu d un lot, au plus deux cartes offertes a cout '
      'total nul, toutes isExhaust ; aucun lot n en porte plus d une', () {
    int total(CardData c) => c.cost + c.hpCost + c.armorCost;
    final signatureIds = registry.signatures.map((s) => s.id).toSet();
    for (final p in registry.passives) {
      if (!registry.cards.any((c) => c.passive == p.id)) continue;
      final free = registry.cards.where(
        (c) =>
            !signatureIds.contains(c.id) &&
            c.isOfferable(p.id) &&
            total(c) == 0,
      );
      expect(free.length, lessThanOrEqualTo(2), reason: p.id);
      expect(free.every((c) => c.isExhaust), isTrue, reason: p.id);
      expect(
        registry.cards.where((c) => c.passive == p.id && total(c) == 0).length,
        lessThanOrEqualTo(1),
        reason: p.id,
      );
    }
  });

  test('D12 : chaque mecanisme a ses cartes', () {
    final cards = registry.cards;
    int withScale(String source) => cards
        .where((c) => c.effects.any((e) => e.scaleWith?.source.name == source))
        .length;
    expect(cards.where((c) => c.hpCost > 0).length, greaterThanOrEqualTo(2));
    expect(cards.where((c) => c.armorCost > 0).length, greaterThanOrEqualTo(2));
    expect(withScale('armor'), greaterThanOrEqualTo(2));
    expect(withScale('missingHp'), greaterThanOrEqualTo(2));
    expect(
      cards.where((c) => c.effects.any((e) => e.hits >= 2)).length,
      greaterThanOrEqualTo(1),
    );
  });

  test('une carte a scaleWith garde une valeur de base d au moins 1', () {
    final faulty = [
      for (final c in registry.cards)
        for (final e in c.effects)
          if (e.scaleWith != null && e.value < 1) c.id,
    ];
    expect(faulty, isEmpty);
  });

  test('D38 : un effet a plusieurs coups declare mightRatio < 1', () {
    final faulty = [
      for (final (id, _, effects) in _costed(registry))
        if (effects.any((e) => e.hits >= 2 && e.mightRatio >= 1)) id,
    ];
    expect(faulty, isEmpty);
  });
}
