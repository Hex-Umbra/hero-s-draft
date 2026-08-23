import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';

/// Verrouille la valeur de chaque type de récompense de draft, palier de
/// rareté par palier de rareté.
///
/// Rien ne couvrait ces valeurs : `probabilities_test.dart` ne teste que les
/// probabilités de tirage, jamais l'ampleur du gain. C'est ce trou qui a
/// laissé la Forge d'Acier légendaire retomber sur la valeur d'un commun
/// (+1 Maîtrise au lieu de +7), sans que rien ne le signale.

/// La table attendue, une entrée par type et par rareté.
///
/// Les six types passent par deux courbes distinctes : un multiplicateur
/// générique (×1 / ×1,5 / ×2 / ×3 / ×4) pour Vitalité, Aiguisage et Sagesse,
/// et des tables propres pour Forge d'Acier, Précision et Férocité. Les
/// arrondis sont ceux de `num.round()`, qui écarte de zéro : 7,5 donne 8.
const Map<LevelUpRewardType, Map<RewardRarity, num>> _attendu = {
  LevelUpRewardType.vitality: {
    RewardRarity.common: 5,
    RewardRarity.uncommon: 8,
    RewardRarity.rare: 10,
    RewardRarity.epic: 15,
    RewardRarity.legendary: 20,
  },
  LevelUpRewardType.sharpening: {
    RewardRarity.common: 2,
    RewardRarity.uncommon: 3,
    RewardRarity.rare: 4,
    RewardRarity.epic: 6,
    RewardRarity.legendary: 8,
  },
  LevelUpRewardType.steelForge: {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 3,
    RewardRarity.epic: 5,
    RewardRarity.legendary: 7,
  },
  // Sagesse plafonne à 2 sur deux paliers consécutifs : `round(1 × 1,5)` et
  // `round(1 × 2,0)` donnent tous deux 2. Comportement existant, verrouillé
  // ici tel quel plutôt que corrigé au passage.
  LevelUpRewardType.wisdom: {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 2,
    RewardRarity.epic: 3,
    RewardRarity.legendary: 4,
  },
  LevelUpRewardType.precision: {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 3,
    RewardRarity.epic: 4,
    RewardRarity.legendary: 5,
  },
  LevelUpRewardType.ferocity: {
    RewardRarity.common: 0.10,
    RewardRarity.uncommon: 0.20,
    RewardRarity.rare: 0.30,
    RewardRarity.epic: 0.40,
    RewardRarity.legendary: 0.50,
  },
};

/// Extrait la valeur portée par un choix, quel que soit son type.
num? _valeurDe(DraftChoice choix) {
  switch (choix.type) {
    case LevelUpRewardType.vitality:
      return choix.pvBoost;
    case LevelUpRewardType.sharpening:
      return choix.atkBoost;
    case LevelUpRewardType.steelForge:
      return choix.armorBoost;
    case LevelUpRewardType.wisdom:
      return choix.manaBoost;
    case LevelUpRewardType.precision:
      return choix.critChanceBoost;
    case LevelUpRewardType.ferocity:
      return choix.critDamageBoost;
    // Trèfle et Miroir n'ont pas de courbe de rareté : ils ne sortent qu'en
    // mythique, avec une valeur unique.
    case LevelUpRewardType.luckyClover:
    case LevelUpRewardType.mirror:
      return null;
  }
}

void main() {
  group('Valeurs de récompense par palier de rareté', () {
    test('la table est respectée sur les 30 combinaisons', () {
      // `generateChoices` tire son type et sa rareté au hasard. On balaie
      // assez large pour voir les 30 combinaisons : la plus rare est un
      // légendaire d'un type donné, à environ 0,33 % par choix à chance 0,
      // soit ~100 occurrences attendues sur 30 000 tirages.
      final observe = <LevelUpRewardType, Map<RewardRarity, Set<num>>>{};

      for (var i = 0; i < 10000; i++) {
        for (final choix in LevelUpRewardService.generateChoices(luck: 0)) {
          final valeur = _valeurDe(choix);
          if (valeur == null) continue;
          observe
              .putIfAbsent(choix.type, () => {})
              .putIfAbsent(choix.rarity, () => {})
              .add(valeur);
        }
      }

      for (final entree in _attendu.entries) {
        final type = entree.key;
        expect(
          observe[type],
          isNotNull,
          reason: '$type n\'a jamais été tiré sur 30 000 choix',
        );

        for (final palier in entree.value.entries) {
          final valeurs = observe[type]![palier.key];
          expect(
            valeurs,
            isNotNull,
            reason: '$type en ${palier.key} n\'a jamais été tiré',
          );
          expect(
            valeurs,
            hasLength(1),
            reason: '$type en ${palier.key} rend plusieurs valeurs : $valeurs',
          );
          expect(
            valeurs!.single,
            closeTo(palier.value, 0.0001),
            reason: '$type en ${palier.key}',
          );
        }
      }
    });

    test('chaque type progresse strictement avec la rareté', () {
      // L'invariant que le bug violait : un légendaire donnait moins qu'un
      // épique, et exactement autant qu'un commun.
      const ordre = [
        RewardRarity.common,
        RewardRarity.uncommon,
        RewardRarity.rare,
        RewardRarity.epic,
        RewardRarity.legendary,
      ];

      for (final entree in _attendu.entries) {
        // Sagesse a un plateau assumé entre peu commun et rare.
        final strict = entree.key != LevelUpRewardType.wisdom;

        for (var i = 1; i < ordre.length; i++) {
          final precedent = entree.value[ordre[i - 1]]!;
          final courant = entree.value[ordre[i]]!;
          expect(
            courant,
            strict ? greaterThan(precedent) : greaterThanOrEqualTo(precedent),
            reason:
                '${entree.key} : ${ordre[i]} ($courant) ne devrait pas être '
                'sous ${ordre[i - 1]} ($precedent)',
          );
        }
      }
    });

    test('une chance très élevée force le légendaire sur les trois choix', () {
      // `legendaryChance = 2 + luck × 0,5` dépasse 100 dès `luck: 200` : le
      // tirage est alors déterministe, ce qui donne un test non statistique
      // du palier qui était cassé.
      for (var i = 0; i < 50; i++) {
        final choix = LevelUpRewardService.generateChoices(luck: 200);
        for (final c in choix.take(3)) {
          expect(c.rarity, RewardRarity.legendary);
          final attendu = _attendu[c.type]?[RewardRarity.legendary];
          if (attendu == null) continue;
          expect(_valeurDe(c), closeTo(attendu, 0.0001), reason: '${c.type}');
        }
      }
    });

    test('la Forge d\'Acier légendaire vaut plus que l\'épique', () {
      // Non-régression directe du défaut trouvé : la cascade de `if` sans
      // palier légendaire renvoyait 1, soit la valeur d'un commun.
      final forge = _attendu[LevelUpRewardType.steelForge]!;
      expect(forge[RewardRarity.legendary], greaterThan(forge[RewardRarity.epic]!));
      expect(forge[RewardRarity.legendary], isNot(forge[RewardRarity.common]));
    });
  });
}
