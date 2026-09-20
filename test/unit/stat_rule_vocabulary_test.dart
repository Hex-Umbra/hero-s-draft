import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';

/// Le vocabulaire que `class.json` ecrit, expose pour l'editeur de contenu.
///
/// Il n'est lisible nulle part ailleurs : `RuleTarget.statusMight` s'ecrit
/// `"status:might"` dans le fichier, et `_names(RuleTarget.values)` rendrait
/// donc une valeur qu'aucun fichier ne porte. Le seul endroit qui connait la
/// correspondance est le parseur — precedent : `PassiveMastery.fields`.
void main() {
  test('chaque nom expose se relit par fromJson', () {
    for (final stat in StatRule.statNames) {
      for (final mode in StatRule.modeNames) {
        for (final to in StatRule.targetNames) {
          expect(
            () => StatRule.fromJson({'stat': stat, 'mode': mode, 'to': to}),
            returnsNormally,
            reason: '$stat / $mode / $to',
          );
        }
      }
    }
  });

  test('les trois listes sont non vides et sans doublon', () {
    for (final noms in [
      StatRule.statNames,
      StatRule.modeNames,
      StatRule.targetNames,
    ]) {
      expect(noms, isNotEmpty);
      expect(noms.toSet(), hasLength(noms.length));
    }
  });
}
