import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
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
}
