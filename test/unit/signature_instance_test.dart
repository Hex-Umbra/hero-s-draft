import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/effect_kind.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/data/signature_evolution_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';

const _data = SignatureData(
  id: 'holy_shield',
  heroClass: 'paladin',
  nameEn: 'Holy Shield',
  nameFr: 'Bouclier Sacre',
  descriptionEn: 'Gain 8 armor and heal 2.',
  descriptionFr: 'Gagne 8 armure et soigne 2.',
  cost: 1,
  cooldown: 2,
  type: CardType.skill,
  target: CardTarget.self,
  animation: 'buff',
  sfx: 'shield',
  effects: [
    CardEffect(type: 'armor', value: 8),
    CardEffect(type: 'heal', value: 2),
  ],
);

const _smitePool = [
  SignatureEvolutionData(
    id: 'zeal',
    tier: EvolutionTier.minor,
    deltas: [FlatBonusDelta(effect: 'damage', valuePerLevel: 2)],
    descriptionFr: '+{val} dégâts',
    descriptionEn: '+{val} damage',
  ),
  SignatureEvolutionData(
    id: 'aegis',
    tier: EvolutionTier.minor,
    deltas: [FlatBonusDelta(effect: 'armor', valuePerLevel: 2)],
    descriptionFr: '+{val} Armure',
    descriptionEn: '+{val} Block',
  ),
  SignatureEvolutionData(
    id: 'ardor',
    tier: EvolutionTier.minor,
    deltas: [CritBonusDelta(valuePerLevel: 5)],
    descriptionFr: '+{val} % de critique',
    descriptionEn: '+{val}% critical chance',
  ),
  SignatureEvolutionData(
    id: 'haste',
    tier: EvolutionTier.major,
    cooldown: -1,
    descriptionFr: "Recharge réduite d'un tour",
    descriptionEn: 'Cooldown one turn shorter',
  ),
  SignatureEvolutionData(
    id: 'sentence',
    tier: EvolutionTier.major,
    deltas: [
      AddEffectDelta(
        effect: 'apply_status',
        valuePerLevel: 1,
        statusId: 'weakness',
        durationPerLevel: 2,
      ),
    ],
    descriptionFr: 'Applique 1 Faiblesse pendant 2 tours',
    descriptionEn: 'Apply 1 Weakness for 2 turns',
  ),
  SignatureEvolutionData(
    id: 'radiance',
    tier: EvolutionTier.major,
    target: CardTarget.allEnemies,
    descriptionFr: 'Touche tous les ennemis',
    descriptionEn: 'Hits all enemies',
  ),
  SignatureEvolutionData(
    id: 'devotion',
    tier: EvolutionTier.major,
    deltas: [ReduceCostDelta(valuePerLevel: 1)],
    descriptionFr: 'Coûte 1 Mana de moins',
    descriptionEn: 'Costs 1 less Mana',
  ),
  SignatureEvolutionData(
    id: 'devastation',
    tier: EvolutionTier.major,
    deltas: [FlatBonusDelta(effect: 'damage', valuePerLevel: 10)],
    cooldown: 1,
    excludes: ['haste'],
    descriptionFr: "+10 dégâts, recharge allongée d'un tour",
    descriptionEn: '+10 damage, cooldown one turn longer',
  ),
];

SignatureData _smite({int cost = 1, int cooldown = 2}) => SignatureData(
      id: 'smite',
      heroClass: 'paladin',
      nameEn: 'Smite',
      nameFr: 'Châtiment',
      descriptionEn: 'Deal {damage} damage and gain {armor} Block.',
      descriptionFr: "Inflige {damage} dégâts et donne {armor} d'Armure.",
      cost: cost,
      cooldown: cooldown,
      type: CardType.attack,
      effects: const [
        CardEffect(type: 'damage', value: 6),
        CardEffect(type: 'armor', value: 4),
      ],
      evolutions: _smitePool,
    );

SignatureInstance _taken(List<String> refs, {SignatureData? data}) =>
    SignatureInstance(data ?? _smite(), evolutions: refs);

void main() {
  const signature = SignatureInstance(_data);

  test('cost et cooldown rendent la donnee', () {
    expect(signature.cost, 1);
    expect(signature.cooldown, 2);
  });

  test('asCard reprend id, noms, descriptions, type, cible, cout, animation, '
      'sfx et effets', () {
    final card = signature.asCard.data;
    expect(card.id, 'holy_shield');
    expect(card.nameEn, 'Holy Shield');
    expect(card.nameFr, 'Bouclier Sacre');
    expect(card.descriptionEn, 'Gain 8 armor and heal 2.');
    expect(card.descriptionFr, 'Gagne 8 armure et soigne 2.');
    expect(card.type, CardType.skill);
    expect(card.target, CardTarget.self);
    expect(card.cost, 1);
    expect(card.animation, 'buff');
    expect(card.sfx, 'shield');
    expect(card.effects.map((e) => e.value), [8, 2]);
  });

  test('asCard est commune, sans rune, et ne s epuise pas', () {
    final card = signature.asCard;
    expect(card.rarity, CardRarity.common);
    expect(card.data.rarity, CardRarity.common);
    expect(card.forgeUpgrades, isEmpty);
    expect(card.data.isExhaust, isFalse);
    expect(card.exhaustsOnPlay, isFalse);
  });

  test('effective rend les valeurs du fichier', () {
    final card = signature.asCard;
    expect(card.effective.cost, 1);
    expect(card.effective.effects.map((e) => e.value), [8, 2]);
    expect(card.currentCost, 1);
  });

  test('level et taken : la somme des niveaux, les paires dans l ordre de '
      'premiere prise', () {
    final s = _taken(['zeal:2', 'sentence:1', 'aegis:1', 'ghost:3']);
    expect(s.level, 4);
    expect([for (final (e, n) in s.taken) (e.id, n)],
        [('zeal', 2), ('sentence', 1), ('aegis', 1)]);
  });

  test('asCard : flatBonus sur les degats et l Armure', () {
    final card = _taken(['zeal:2', 'aegis:1']).asCard;
    expect(card.effective.effects.map((e) => e.value), [10, 6]);
  });

  test('asCard : reduceCost baisse le cout, jamais sous 0, et cost le lit',
      () {
    expect(_taken(['devotion:1']).cost, 0);
    expect(_taken(['devotion:1'], data: _smite(cost: 0)).cost, 0);
  });

  test('cooldown : la recharge et celle des majeures, jamais sous 1', () {
    expect(_taken(['haste:1']).cooldown, 1);
    expect(_taken(['haste:1'], data: _smite(cooldown: 1)).cooldown, 1);
    expect(_taken(['devastation:1']).cooldown, 3);
  });

  test('asCard : la cible est celle de la derniere majeure target prise, '
      'sinon la sienne', () {
    expect(_taken([]).asCard.data.target, CardTarget.singleEnemy);
    expect(_taken(['radiance:1']).asCard.data.target, CardTarget.allEnemies);
  });

  test('asCard : addEffect et critBonus passent par effective', () {
    final effective = _taken(['sentence:1', 'ardor:1']).asCard.effective;
    final added = effective.addedEffects.single;
    expect(added.type, 'apply_status');
    expect(added.statusId, 'weakness');
    expect(added.value, 1);
    expect(added.duration, 2);
    expect(effective.critChanceBonus, 5);
  });

  test('la description : le gabarit rempli des valeurs evoluees, puis les '
      'phrases verbales ; une chiffree n ajoute rien', () {
    final both = _taken(['zeal:2', 'sentence:1']).asCard.data;
    expect(
      both.descriptionFr,
      "Inflige 10 dégâts et donne 4 d'Armure. "
      'Applique 1 Faiblesse pendant 2 tours.',
    );
    expect(
      both.descriptionEn,
      'Deal 10 damage and gain 4 Block. Apply 1 Weakness for 2 turns.',
    );

    final numeric = _taken(['zeal:1']).asCard.data;
    expect(numeric.descriptionFr, "Inflige 8 dégâts et donne 4 d'Armure.");
    expect(numeric.descriptionEn, 'Deal 8 damage and gain 4 Block.');
  });

  test('effectLines : les effets propres puis les verbales, dans l ordre de '
      'premiere prise, a leurs valeurs evoluees', () {
    expect(
      _taken(['zeal:2', 'sentence:1', 'ardor:1', 'radiance:1']).effectLines,
      [
        (kind: 'damage', value: 10, duration: null),
        (kind: 'armor', value: 4, duration: null),
        (kind: 'status:weakness', value: 1, duration: 2),
        (kind: 'crit', value: 5, duration: null),
        (kind: 'target:allEnemies', value: null, duration: null),
      ],
    );
    expect(EffectKind.crit, 'crit');
    expect(EffectKind.allEnemies, 'target:allEnemies');
  });

  test('effectLines : une chiffree n ajoute aucune entree', () {
    expect(_taken(['zeal:1', 'devotion:1', 'haste:1']).effectLines, [
      (kind: 'damage', value: 8, duration: null),
      (kind: 'armor', value: 4, duration: null),
    ]);
  });

  test('effectLines : deux effets de meme sorte restent deux entrees', () {
    const surge = SignatureData(
      id: 'mana_surge',
      heroClass: 'mage',
      cost: 0,
      cooldown: 2,
      type: CardType.skill,
      target: CardTarget.self,
      effects: [
        CardEffect(type: 'gain_mana', value: 1),
        CardEffect(type: 'draw', value: 1),
      ],
      evolutions: [
        SignatureEvolutionData(
          id: 'clarity',
          tier: EvolutionTier.minor,
          deltas: [AddEffectDelta(effect: 'heal', valuePerLevel: 1)],
        ),
        SignatureEvolutionData(
          id: 'serenity',
          tier: EvolutionTier.major,
          deltas: [AddEffectDelta(effect: 'heal', valuePerLevel: 4)],
        ),
      ],
    );
    expect(
      _taken(['clarity:1', 'serenity:1'], data: surge)
          .effectLines
          .map((l) => (l.kind, l.value)),
      [('gain_mana', 1), ('draw', 1), ('heal', 1), ('heal', 4)],
    );
  });

  test('pendingFor : niveau du heros / 5 moins level, jamais negatif', () {
    final none = _taken([]);
    expect([4, 5, 12].map(none.pendingFor), [0, 1, 2]);
    expect(_taken(['zeal:1']).pendingFor(10), 1);
    expect(_taken(['zeal:3']).pendingFor(10), 0);
  });

  test('nextTier : niveau de heros 5 -> mineure, 10 -> majeure', () {
    expect(
      [
        <String>[],
        ['zeal:1'],
        ['zeal:1', 'aegis:1'],
        ['zeal:1', 'aegis:1', 'ardor:1'],
      ].map((refs) => _taken(refs).nextTier),
      [
        EvolutionTier.minor,
        EvolutionTier.major,
        EvolutionTier.minor,
        EvolutionTier.major,
      ],
    );
  });

  test('canAfford lit le cout evolue : a 0 mana, Chatiment est refusee, '
      'avec Devotion acceptee', () {
    final broke = EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0);
    expect(EffectResolver.canAfford(_taken([]).asCard, broke), isFalse);
    expect(EffectResolver.canAfford(_taken(['devotion:1']).asCard, broke),
        isTrue);
  });
}
