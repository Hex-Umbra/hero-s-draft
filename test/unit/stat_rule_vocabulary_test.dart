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

  // Le vrai trou : `StatRuleLabel.describe` force, par un switch exhaustif, a
  // visiter `model_extensions.dart` des qu'un `RuleStat` (ou `RuleMode`, ou
  // `RuleTarget`) gagne une valeur — mais rien ne force a l'ajouter aussi a
  // `_stats` (ou `_modes`, ou `_targets`) dans `stat_rule.dart`, et
  // `_nameOf`, sans `orElse` (`stat_rule.dart:68`), leve alors `StateError`
  // au clic, dans le menu de debug. Une liste plus courte que son
  // enumeration le dit ici, a l'execution des tests plutot qu'au clic.
  test('chaque valeur d enum porte un nom de vocabulaire fichier', () {
    expect(StatRule.statNames, hasLength(RuleStat.values.length));
    expect(StatRule.modeNames, hasLength(RuleMode.values.length));
    expect(StatRule.targetNames, hasLength(RuleTarget.values.length));
    for (final noms in [
      StatRule.statNames,
      StatRule.modeNames,
      StatRule.targetNames,
    ]) {
      expect(noms, isNotEmpty);
    }
  });

  // toString() est le vocabulaire du menu de debug : un test qui ne
  // verifierait que le rendu du widget (find.text(rule.toString())) passerait
  // encore si toString() rendait le nom d'enum Dart (statusMight) plutot que
  // le vocabulaire du fichier (status:might) — cette assertion fixe la chaine
  // rendue elle-meme.
  test('toString rend le vocabulaire du fichier, pas les noms d enum', () {
    expect(
      const StatRule(
        stat: RuleStat.armor,
        mode: RuleMode.convert,
        to: RuleTarget.statusMight,
        duration: 1,
      ).toString(),
      'armor convert status:might, 1 tour(s)',
    );
    expect(
      const StatRule(
        stat: RuleStat.mana,
        mode: RuleMode.convert,
        to: RuleTarget.statusMight,
        duration: 3,
      ).toString(),
      'mana convert status:might, 3 tour(s)',
    );
  });
}
