import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';

void main() {
  SignatureData signature(String id) => SignatureData(
        id: id,
        heroClass: 'paladin',
        nameEn: id,
        nameFr: id,
        descriptionEn: id,
        descriptionFr: id,
        cost: 1,
        cooldown: 2,
        type: CardType.attack,
        effects: const [CardEffect(type: 'damage', value: 1)],
      );

  GameDataRegistry registryWith(List<SignatureData> signatures) =>
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
        signatures: signatures,
      );

  HeroData heroWith(List<String> skills) => HeroData(
        id: 'paladin',
        classCard: 'hero_paladin.png',
        maxHp: 100,
        maxMana: 3,
        skills: skills,
      );

  test('getSignatures rend les signatures dans l ordre de skills', () {
    final registry = registryWith([signature('a'), signature('b')]);

    final result = heroWith(['b', 'a']).getSignatures(registry);

    expect(result.map((s) => s.id), ['b', 'a']);
  });

  test('une signature introuvable leve au lieu d etre avalee', () {
    final registry = registryWith([signature('a')]);

    expect(() => heroWith(['absente']).getSignatures(registry),
        throwsStateError);
  });
}
