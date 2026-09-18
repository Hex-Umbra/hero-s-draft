import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/models/might_target.dart';

/// La forme longue de ce que renforce la Puissance, pour l'écran de sélection
/// (spec P-41, §7.4 et §8.3). Générée, jamais écrite classe par classe :
/// aucun écran ne compare `hero.id` (ADR-090).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('une seule cible : pas de joint', () {
    // Le Berserker.
    expect(
      {MightTarget.attack}.sentence(fr),
      'Votre Puissance renforce les dégâts de vos Attaques.',
    );
    expect(
      {MightTarget.attack}.sentence(en),
      'Your Might strengthens your Attack damage.',
    );
  });

  test('deux cibles : jointes par « et »', () {
    // Le Mage.
    expect(
      {MightTarget.skill, MightTarget.alteration}.sentence(fr),
      'Votre Puissance renforce les dégâts de vos Compétences et vos altérations.',
    );
    expect(
      {MightTarget.skill, MightTarget.alteration}.sentence(en),
      'Your Might strengthens your Skill damage and your alterations.',
    );
  });

  test('trois cibles : une virgule, puis « et »', () {
    // Le Paladin.
    expect(
      {MightTarget.attack, MightTarget.skill, MightTarget.alteration}.sentence(fr),
      'Votre Puissance renforce les dégâts de vos Attaques, les dégâts de vos '
      'Compétences et vos altérations.',
    );
    expect(
      {MightTarget.attack, MightTarget.skill, MightTarget.alteration}.sentence(en),
      'Your Might strengthens your Attack damage, your Skill damage and your '
      'alterations.',
    );
  });

  test('l ordre est celui de MightTarget, pas celui du Set', () {
    // Un `Set` littéral conserve l'ordre d'insertion : sans tri explicite, ce
    // test verrait « vos altérations et les dégâts de vos Attaques ».
    expect(
      {MightTarget.alteration, MightTarget.attack}.longLabel(fr),
      'les dégâts de vos Attaques et vos altérations',
    );
  });

  test('la forme courte n a pas bougé', () {
    // Elle sert au dialogue de stats (spec §7.4) et ne doit pas dériver.
    expect(
      {MightTarget.skill, MightTarget.alteration}.shortLabel(fr),
      'Compétences · Altérations',
    );
  });
}
