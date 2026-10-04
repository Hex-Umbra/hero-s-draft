import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/systems/card_drops.dart';
import 'package:roguelike_card_game/models/map_node.dart';

import 'scripted_random.dart';

/// Le tirage de la trouvaille (spec P-43 E3, §4.1, §8 ; D1, D31, D57) :
/// combien de cartes un combat gagné fait trouver.
void main() {
  final combat = GameConstants.cardDrops[MapNodeType.combat];
  final elite = GameConstants.cardDrops[MapNodeType.elite];

  test('un combat normal : une carte garantie', () {
    expect(CardDrops.roll(combat, rng: ScriptedRandom([0])), 1);
    expect(CardDrops.roll(combat, rng: ScriptedRandom([99])), 1);
  });

  test('extraGuaranteed s ajoute aux cartes garanties', () {
    expect(
      CardDrops.roll(combat, extraGuaranteed: 1, rng: ScriptedRandom([0])),
      2,
    );
  });

  test('une elite : une seconde carte si le jet passe sous 25', () {
    expect(CardDrops.roll(elite, rng: ScriptedRandom([24])), 2);
    expect(CardDrops.roll(elite, rng: ScriptedRandom([25])), 1);
  });

  test('le bonus ne vaut que pour le premier jet : a 75 et au-dela de 100, '
      'toujours deux cartes', () {
    for (var roll = 0; roll < 100; roll++) {
      expect(
        CardDrops.roll(elite, firstExtraBonus: 75, rng: ScriptedRandom([roll])),
        2,
        reason: 'jet $roll, bonus 75',
      );
      // Quatre Registres des primes : 125 — deux cartes, jamais trois.
      expect(
        CardDrops.roll(elite, firstExtraBonus: 100, rng: ScriptedRandom([roll])),
        2,
        reason: 'jet $roll, bonus 100',
      );
    }
  });

  test('une regle absente — le boss — ne donne rien', () {
    expect(GameConstants.cardDrops[MapNodeType.boss], isNull);
    expect(
      CardDrops.roll(
        null,
        extraGuaranteed: 1,
        firstExtraBonus: 75,
        rng: ScriptedRandom([0]),
      ),
      0,
    );
  });

  test('les jets s arretent au premier rate', () {
    const rule = (guaranteed: 1, extraChances: [50, 50]);

    expect(CardDrops.roll(rule, rng: ScriptedRandom([10, 10])), 3);
    expect(CardDrops.roll(rule, rng: ScriptedRandom([10, 90])), 2);
    // Le premier jet rate : le second, qui passerait, n'est pas tire.
    expect(CardDrops.roll(rule, rng: ScriptedRandom([90, 10])), 1);
    // Le bonus ne porte que le premier jet : le second rate a 90.
    expect(
      CardDrops.roll(rule, firstExtraBonus: 50, rng: ScriptedRandom([90, 90])),
      2,
    );
  });
}
