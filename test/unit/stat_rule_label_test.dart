import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';

/// La règle de stat d'une classe, écrite en clair pour l'écran de sélection
/// (spec P-41, §8.3) — « **générée à partir de la règle**, jamais écrite
/// classe par classe ».
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('la conversion d armure du Berserker, un tour', () {
    const regle = StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
    );

    expect(regle.describe(fr), 'Son Armure devient de la Puissance pour un tour.');
    expect(regle.describe(en), 'Their Armor becomes Might for one turn.');
  });

  test('une durée de plusieurs tours se met au pluriel', () {
    // Aucune classe livrée ne le fait ; c'est justement pourquoi le texte est
    // généré et non écrit à la main.
    const regle = StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 3,
    );

    expect(regle.describe(fr), 'Son Armure devient de la Puissance pour 3 tours.');
    expect(regle.describe(en), 'Their Armor becomes Might for 3 turns.');
  });

  test('une conversion de mana a son propre texte', () {
    // `RuleStat.mana` est légal depuis le lot B ; sans libellé, l'écran
    // afficherait un vide ou lèverait.
    const regle = StatRule(
      stat: RuleStat.mana,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
    );

    expect(regle.describe(fr), 'Son Mana devient de la Puissance pour un tour.');
    expect(regle.describe(en), 'Their Mana becomes Might for one turn.');
  });
}
