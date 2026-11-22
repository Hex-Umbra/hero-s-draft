import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/armor_veil.dart';

/// Le voile d'armure d'une barre de PV ennemie : une règle pure sur le plus
/// haut montant d'armure atteint (spec P-05, §4.1).
void main() {
  test('6 gagnes remplissent le voile', () {
    final peak = ArmorVeil.nextPeak(peak: 0, oldArmor: 0, newArmor: 6);

    expect(peak, 6);
    expect(ArmorVeil.fraction(armor: 6, peak: peak), 1.0);
  });

  test('un coup qui laisse 2 sur 6 couvre un tiers', () {
    final peak = ArmorVeil.nextPeak(peak: 6, oldArmor: 6, newArmor: 2);

    expect(peak, 6);
    expect(ArmorVeil.fraction(armor: 2, peak: peak), closeTo(1 / 3, 1e-9));
  });

  test('a 0 le voile disparait et son plein s efface', () {
    final peak = ArmorVeil.nextPeak(peak: 6, oldArmor: 2, newArmor: 0);

    expect(peak, 0);
    expect(ArmorVeil.fraction(armor: 0, peak: peak), 0);
  });

  test('un boss a 40 : 1, puis 0,625 a 25, puis 0,2 a 8', () {
    var peak = ArmorVeil.nextPeak(peak: 0, oldArmor: 0, newArmor: 40);
    expect(ArmorVeil.fraction(armor: 40, peak: peak), 1.0);

    peak = ArmorVeil.nextPeak(peak: peak, oldArmor: 40, newArmor: 25);
    expect(peak, 40);
    expect(ArmorVeil.fraction(armor: 25, peak: peak), closeTo(0.625, 1e-9));

    peak = ArmorVeil.nextPeak(peak: peak, oldArmor: 25, newArmor: 8);
    expect(peak, 40);
    expect(ArmorVeil.fraction(armor: 8, peak: peak), closeTo(0.2, 1e-9));
  });

  test('de l armure regagnee avant 0 remplit le voile (B16)', () {
    final peak = ArmorVeil.nextPeak(peak: 6, oldArmor: 2, newArmor: 7);

    expect(peak, 7);
    expect(ArmorVeil.fraction(armor: 7, peak: peak), 1.0);
  });

  test('la part ne lit pas les PV (B15)', () {
    // 6 gagnes par un ennemi de 14 PV, 40 par un boss de 250 PV : les PV
    // n'entrent dans aucune des deux fonctions.
    final enemyPeak = ArmorVeil.nextPeak(peak: 0, oldArmor: 0, newArmor: 6);
    final bossPeak = ArmorVeil.nextPeak(peak: 0, oldArmor: 0, newArmor: 40);

    expect(ArmorVeil.fraction(armor: 6, peak: enemyPeak), 1.0);
    expect(ArmorVeil.fraction(armor: 40, peak: bossPeak), 1.0);
  });

  test('un plein nul ne couvre rien, et le plein ne passe jamais sous l armure',
      () {
    expect(ArmorVeil.fraction(armor: 3, peak: 0), 0);
    expect(ArmorVeil.nextPeak(peak: 2, oldArmor: 3, newArmor: 3), 3);
  });
}
