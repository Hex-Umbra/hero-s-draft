import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';

/// Une récompense de niveau est de la donnée (spec P-41, §8.1, décision D3).
void main() {
  Map<String, dynamic> vitalityJson() => {
        'id': 'vitality',
        'name_fr': 'Vitalité',
        'name_en': 'Vitality',
        'description_fr': '+{amount} PV Max',
        'description_en': '+{amount} Max HP',
        'effect': 'stat',
        'stat': 'maxHp',
        'pool': 'draft',
        'displayOrder': 1,
        'values': {
          'common': 5,
          'uncommon': 8,
          'rare': 10,
          'epic': 15,
          'legendary': 20,
        },
      };

  Map<String, dynamic> affinityJson() => {
        'id': 'affinity',
        'name_fr': 'Affinité',
        'name_en': 'Affinity',
        'description_fr': '{passive} : {effect}',
        'description_en': '{passive}: {effect}',
        'fallbackDescription_fr': '+{amount} Maîtrise, sans effet sur votre passif',
        'fallbackDescription_en': '+{amount} Mastery, no effect on your passive',
        'shortDescription_fr': '+{amount} Maîtrise',
        'shortDescription_en': '+{amount} Mastery',
        'effect': 'stat',
        'stat': 'mastery',
        'pool': 'draft',
        'displayOrder': 3,
        'values': {
          'common': 1,
          'uncommon': 2,
          'rare': 3,
          'epic': 5,
          'legendary': 7,
        },
      };

  Map<String, dynamic> mirrorJson() => {
        'id': 'mirror',
        'name_fr': 'Miroir',
        'name_en': 'Mirror',
        'description_fr': 'Cloner une carte au choix parmi 3 cartes aléatoires de votre deck',
        'description_en': 'Clone a card chosen from 3 random cards in your deck',
        'shortDescription_fr': 'Cloner une carte',
        'shortDescription_en': 'Clone a card',
        'effect': 'cloneCard',
        'pool': 'mythic',
        'displayOrder': 8,
        'values': <String, dynamic>{},
      };

  PassiveData regen({PassiveMastery? mastery}) => PassiveData(
        id: 'regen_armor',
        nameEn: 'Armor Regeneration',
        nameFr: "Régénération d'Armure",
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: mastery,
      );

  const masteryBlock = PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} Block at end of turn',
    descriptionFr: '+{amount} Armure en fin de tour',
  );

  group('lecture', () {
    test('une récompense de stat porte sa table par rareté', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());

      expect(vitality.id, 'vitality');
      expect(vitality.effect, RewardEffect.stat);
      expect(vitality.stat, RewardStat.maxHp);
      expect(vitality.pool, RewardPool.draft);
      expect(vitality.amountFor(RewardRarity.epic), 15);
      // Un palier qu'une récompense `draft` ne peut pas atteindre rend 0
      // plutôt que de lever en plein tirage.
      expect(vitality.amountFor(RewardRarity.mythic), 0);
    });

    test('une récompense sans stat déclare son effet propre', () {
      final mirror = LevelUpRewardData.fromJson(mirrorJson());

      expect(mirror.effect, RewardEffect.cloneCard);
      expect(mirror.stat, isNull);
      expect(mirror.pool, RewardPool.mythic);
    });
  });

  group('lectures refusées', () {
    void refuse(Map<String, dynamic> json, String fragment) {
      expect(
        () => LevelUpRewardData.fromJson(json),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', contains(fragment)),
        ),
      );
    }

    test('un effet inconnu', () {
      refuse(vitalityJson()..['effect'] = 'gain_gold', 'effect');
    });

    test('une stat inconnue', () {
      refuse(vitalityJson()..['stat'] = 'charisma', 'stat');
    });

    test('un groupe de tirage inconnu', () {
      refuse(vitalityJson()..['pool'] = 'shop', 'pool');
    });

    test('une récompense de stat sans stat', () {
      refuse(vitalityJson()..remove('stat'), 'stat');
    });

    test('une récompense sans stat qui en déclare une', () {
      refuse(mirrorJson()..['stat'] = 'luck', 'stat');
    });

    test('un palier manquant dans une récompense tirable', () {
      final json = vitalityJson();
      (json['values'] as Map<String, dynamic>).remove('epic');
      refuse(json, 'epic');
    });

    test('un palier inconnu dans la table', () {
      final json = vitalityJson();
      (json['values'] as Map<String, dynamic>)['fabuleux'] = 99;
      refuse(json, 'fabuleux');
    });

    // Les trois suivants rendent vérifiable la règle de `CLAUDE.md` : tout
    // texte joueur porte ses deux langues. Une traduction perdue au passage en
    // donnée doit faire échouer le chargement, pas s'afficher en anglais dans
    // un jeu en français.

    test('un nom sans sa variante anglaise', () {
      refuse(vitalityJson()..remove('name_en'), 'name_en');
    });

    test('une description sans sa variante française', () {
      refuse(vitalityJson()..remove('description_fr'), 'description_fr');
    });

    test('un texte optionnel traduit à moitié', () {
      refuse(affinityJson()..remove('shortDescription_en'), 'shortDescription');
    });
  });

  group('description', () {
    test('{amount} devient la valeur tirée', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());

      expect(vitality.describe('fr', amount: 15), '+15 PV Max');
      expect(vitality.describe('en', amount: 15), '+15 Max HP');
    });

    test('{passive} et {effect} composent avec le passif actif', () {
      final affinity = LevelUpRewardData.fromJson(affinityJson());

      expect(
        affinity.describe('fr', amount: 2, passive: regen(mastery: masteryBlock)),
        "Régénération d'Armure : +2 Armure en fin de tour",
      );
      expect(
        affinity.describe('en', amount: 2, passive: regen(mastery: masteryBlock)),
        'Armor Regeneration: +2 Block at end of turn',
      );
    });

    test('sans passif, ou sans Maîtrise déclarée, le gabarit de repli sert', () {
      final affinity = LevelUpRewardData.fromJson(affinityJson());

      expect(
        affinity.describe('fr', amount: 3),
        '+3 Maîtrise, sans effet sur votre passif',
      );
      expect(
        affinity.describe('fr', amount: 3, passive: regen()),
        '+3 Maîtrise, sans effet sur votre passif',
      );
    });

    test('une description sans placeholder de passif ignore le passif', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());

      expect(
        vitality.describe('fr', amount: 5, passive: regen(mastery: masteryBlock)),
        '+5 PV Max',
      );
    });
  });

  group('libellé court', () {
    test('il sert quand il est déclaré', () {
      final affinity = LevelUpRewardData.fromJson(affinityJson());
      expect(affinity.shortLabel('fr', amount: 3), '+3 Maîtrise');
      expect(affinity.shortLabel('en', amount: 3), '+3 Mastery');
    });

    test('absent, il se rabat sur la description, jamais sur un placeholder', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());
      expect(vitality.shortLabel('fr', amount: 10), '+10 PV Max');
      // Le rouleau n'a pas de passif : un `{passive}` qui fuirait à l'écran
      // serait le défaut que ce repli existe pour empêcher.
      expect(vitality.shortLabel('fr', amount: 10), isNot(contains('{')));
    });
  });
}
