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

  // D37, A7 (spec P-43 E0, §5.1) : a un ratio autre que 1, une seconde phrase
  // dit le taux, et l'exemple de D37 tel que le moteur le calcule.
  test('a 0,5, la conversion d armure dit son taux et son exemple', () {
    const regle = StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    );

    expect(
      regle.describe(fr),
      'Son Armure devient de la Puissance pour un tour. '
      "Taux : 50%, arrondi à l'entier supérieur — 6 Armure → 3 Puissance.",
    );
    expect(
      regle.describe(en),
      'Their Armor becomes Might for one turn. '
      'Rate: 50%, rounded up — 6 Armor → 3 Might.',
    );
  });

  test('a 0,5, la conversion de mana dit son taux et son exemple', () {
    const regle = StatRule(
      stat: RuleStat.mana,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    );

    expect(
      regle.describe(fr),
      'Son Mana devient de la Puissance pour un tour. '
      "Taux : 50%, arrondi à l'entier supérieur — 6 Mana → 3 Puissance.",
    );
    expect(
      regle.describe(en),
      'Their Mana becomes Might for one turn. '
      'Rate: 50%, rounded up — 6 Mana → 3 Might.',
    );
  });
}
