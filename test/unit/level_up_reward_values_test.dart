import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Verrouille la valeur de chaque récompense de draft, palier de rareté par
/// palier de rareté — **sur la donnée** désormais (spec P-41, §8.1).
///
/// Rien ne couvrait ces valeurs avant que ce fichier n'existe :
/// `probabilities_test.dart` ne teste que les probabilités de tirage, jamais
/// l'ampleur du gain. C'est ce trou qui a laissé la Forge d'Acier — aujourd'hui
/// l'Affinité — légendaire retomber sur la valeur d'un commun (+1 Maîtrise au
/// lieu de +7), sans que rien ne le signale.
///
/// Ce que ce fichier prouve maintenant, en plus : ce que le **tirage** rend est
/// bien ce que la **donnée** déclare. `level_up_rewards_catalog_test.dart`
/// verrouille la donnée elle-même.

/// La table attendue, une entrée par récompense tirable et par rareté.
/// Recopiée à l'identique de la version qui lisait le code : c'est la clause
/// « à valeurs identiques » de la spec.
const Map<String, Map<RewardRarity, int>> _attendu = {
  'vitality': {
    RewardRarity.common: 5,
    RewardRarity.uncommon: 8,
    RewardRarity.rare: 10,
    RewardRarity.epic: 15,
    RewardRarity.legendary: 20,
  },
  'sharpening': {
    RewardRarity.common: 2,
    RewardRarity.uncommon: 3,
    RewardRarity.rare: 4,
    RewardRarity.epic: 6,
    RewardRarity.legendary: 8,
  },
  'affinity': {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 3,
    RewardRarity.epic: 5,
    RewardRarity.legendary: 7,
  },
  // Sagesse plafonne à 2 sur deux paliers consécutifs : `round(1 × 1,5)` et
  // `round(1 × 2,0)` donnaient tous deux 2. Comportement existant, recopié
  // dans `wisdom.json` tel quel plutôt que corrigé au passage (spec §8.4).
  'wisdom': {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 2,
    RewardRarity.epic: 3,
    RewardRarity.legendary: 4,
  },
  'precision': {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 3,
    RewardRarity.epic: 4,
    RewardRarity.legendary: 5,
  },
  // En points de pourcentage : la donnée écrit ce que le joueur lit, et
  // l'application divise par 100 (décision 5 du plan).
  'ferocity': {
    RewardRarity.common: 10,
    RewardRarity.uncommon: 20,
    RewardRarity.rare: 30,
    RewardRarity.epic: 40,
    RewardRarity.legendary: 50,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<LevelUpRewardData> rewards;

  // Fixture passive with mastery block, so Affinity is eligible for drawing
  // (required by task 1 filter: Affinity requires an active passive with mastery).
  final activePassive = PassiveData(
    id: 'ward',
    nameEn: 'Ward',
    nameFr: 'Garde',
    trigger: RelicTrigger.endOfTurn,
    effectType: 'gain_armor',
    value: 2,
    mastery: const PassiveMastery(
      field: 'value',
      perPoint: 1,
      descriptionEn: '+{amount} Block at end of turn',
      descriptionFr: '+{amount} Armure en fin de tour',
    ),
  );

  /// Les valeurs réellement rendues par `generateChoices`, palier par palier —
  /// échantillonnées une fois pour tout le fichier, sur le même volume que le
  /// test d'acceptation ci-dessous. Sert aux deux tests qui, avant la revue de
  /// tâche 4 (tour 1), ne lisaient que la table littérale `_attendu` sans
  /// jamais appeler le service : ils vérifient désormais le tirage réel.
  /// Échantillon distinct de celui, local, du test d'acceptation — laissé
  /// intact, à dessein, par cette correction.
  late Map<String, Map<RewardRarity, Set<int>>> observedValues;

  setUpAll(() async {
    rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;

    observedValues = <String, Map<RewardRarity, Set<int>>>{};
    for (var i = 0; i < 10000; i++) {
      for (final choix in LevelUpRewardService.generateChoices(
        rewards: rewards,
        luck: 0,
        activePassive: activePassive,
      )) {
        if (choix.data.pool != RewardPool.draft) continue;
        observedValues
            .putIfAbsent(choix.data.id, () => {})
            .putIfAbsent(choix.rarity, () => {})
            .add(choix.amount);
      }
    }
  });

  group('Valeurs de récompense par palier de rareté', () {
    test('la table est respectée sur les 30 combinaisons', () {
      // `generateChoices` tire sa récompense et sa rareté au hasard. On balaie
      // assez large pour voir les 30 combinaisons : la plus rare est un
      // légendaire d'une récompense donnée, à environ 0,33 % par choix à
      // chance 0, soit ~100 occurrences attendues sur 30 000 tirages.
      final observe = <String, Map<RewardRarity, Set<int>>>{};

      for (var i = 0; i < 10000; i++) {
        for (final choix in LevelUpRewardService.generateChoices(
          rewards: rewards,
          luck: 0,
          activePassive: activePassive,
        )) {
          if (choix.data.pool != RewardPool.draft) continue;
          observe
              .putIfAbsent(choix.data.id, () => {})
              .putIfAbsent(choix.rarity, () => {})
              .add(choix.amount);
        }
      }

      for (final entree in _attendu.entries) {
        final id = entree.key;
        expect(
          observe[id],
          isNotNull,
          reason: '$id n\'a jamais été tirée sur 30 000 choix',
        );

        for (final palier in entree.value.entries) {
          final valeurs = observe[id]![palier.key];
          expect(
            valeurs,
            isNotNull,
            reason: '$id en ${palier.key.name} n\'a jamais été tirée',
          );
          expect(
            valeurs,
            hasLength(1),
            reason: '$id en ${palier.key.name} rend plusieurs valeurs : $valeurs',
          );
          expect(valeurs!.single, palier.value, reason: '$id en ${palier.key.name}');
        }
      }
    });

    test('les six récompenses tirables sont toutes atteignables', () {
      // L'ancien `rng.nextInt(6)` garantissait ce compte par construction.
      // En donnée, une récompense mal rangée le briserait en silence.
      final tirees = <String>{};
      for (var i = 0; i < 2000; i++) {
        for (final choix in LevelUpRewardService.generateChoices(
          rewards: rewards,
          luck: 0,
          activePassive: activePassive,
        )) {
          if (choix.data.pool == RewardPool.draft) tirees.add(choix.data.id);
        }
      }
      expect(tirees, _attendu.keys.toSet());
    });

    test('chaque récompense progresse strictement avec la rareté', () {
      // L'invariant que le bug violait : un légendaire donnait moins qu'un
      // épique, et exactement autant qu'un commun. Vérifié sur les valeurs
      // réellement rendues par le tirage (`observedValues`), pas sur la seule
      // table littérale `_attendu` (revue de tâche 4, tour 1).
      const ordre = [
        RewardRarity.common,
        RewardRarity.uncommon,
        RewardRarity.rare,
        RewardRarity.epic,
        RewardRarity.legendary,
      ];

      for (final id in _attendu.keys) {
        // Sagesse a un plateau assumé entre peu commun et rare.
        final strict = id != 'wisdom';

        for (var i = 1; i < ordre.length; i++) {
          final precedent = observedValues[id]![ordre[i - 1]]!.single;
          final courant = observedValues[id]![ordre[i]]!.single;
          expect(
            courant,
            strict ? greaterThan(precedent) : greaterThanOrEqualTo(precedent),
            reason:
                '$id : ${ordre[i].name} ($courant) ne devrait pas '
                'être sous ${ordre[i - 1].name} ($precedent)',
          );
        }
      }
    });

    test('une chance très élevée force le légendaire sur les trois choix', () {
      // `legendaryChance = 2 + luck × 0,5` dépasse 100 dès `luck: 200` : le
      // tirage est alors déterministe, ce qui donne un test non statistique
      // du palier qui était cassé.
      for (var i = 0; i < 50; i++) {
        final choix =
            LevelUpRewardService.generateChoices(rewards: rewards, luck: 200);
        for (final c in choix.take(3)) {
          expect(c.rarity, RewardRarity.legendary);
          final attendu = _attendu[c.data.id]?[RewardRarity.legendary];
          if (attendu == null) continue;
          expect(c.amount, attendu, reason: c.data.id);
        }
      }
    });

    test('l\'Affinité légendaire vaut plus que l\'épique', () {
      // Non-régression directe du défaut trouvé : la cascade de `if` sans
      // palier légendaire renvoyait 1, soit la valeur d'un commun. Vérifié
      // sur les valeurs réellement rendues par le tirage (`observedValues`),
      // pas sur la seule table littérale `_attendu` (revue de tâche 4, tour
      // 1) : c'est le tirage qu'un `if` incomplet aurait fait régresser, pas
      // la table qui le décrit.
      final affinity = observedValues['affinity']!;
      expect(
        affinity[RewardRarity.legendary]!.single,
        greaterThan(affinity[RewardRarity.epic]!.single),
      );
      expect(
        affinity[RewardRarity.legendary]!.single,
        isNot(affinity[RewardRarity.common]!.single),
      );
    });
  });

  group('Les mythiques restent une surprise', () {
    // Ce que le passage en donnée ne doit surtout pas changer : le Trèfle et
    // le Miroir n'entrent jamais dans la table des trois emplacements, et
    // chacun a son propre jet, à 0,5 % à chance nulle. Avant ce chantier, les
    // deux étaient construits hors du tirage, ce qui le garantissait par
    // construction ; en donnée, c'est `pool` qui le garantit — donc un test.

    test('les trois emplacements ne contiennent jamais un mythique', () {
      for (var i = 0; i < 5000; i++) {
        final choix =
            LevelUpRewardService.generateChoices(rewards: rewards, luck: 0);
        expect(choix.length, greaterThanOrEqualTo(3));
        for (final c in choix.take(3)) {
          expect(c.data.pool, RewardPool.draft, reason: c.data.id);
          expect(c.rarity, isNot(RewardRarity.mythic), reason: c.data.id);
        }
      }
    });

    test('chaque mythique a son propre jet, à environ 0,5 % à chance nulle', () {
      // `mythicChance = 0,5 + chance × 0,15`, et `rollRarity` est appelée une
      // fois par récompense mythique : ~100 occurrences attendues sur 20 000
      // tirages, écart-type ~10. Les bornes sont larges — elles ne visent pas
      // la précision statistique mais une dérive d'un ordre de grandeur : un
      // mythique versé dans la table des trois, ou un jet perdu.
      const tirages = 20000;
      final comptes = <String, int>{'lucky_clover': 0, 'mirror': 0};

      for (var i = 0; i < tirages; i++) {
        for (final c in LevelUpRewardService.generateChoices(
          rewards: rewards,
          luck: 0,
        ).skip(3)) {
          comptes[c.data.id] = (comptes[c.data.id] ?? 0) + 1;
        }
      }

      for (final entree in comptes.entries) {
        expect(
          entree.value,
          inInclusiveRange(30, 220),
          reason: '${entree.key} : ${entree.value} sur $tirages tirages, '
              'attendu ~100 (0,5 %)',
        );
      }
    });
  });
}
