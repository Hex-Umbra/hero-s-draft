import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/models/might_target.dart';

/// Ce que renforce la Puissance, en abrégé (spec P-41, §7.4).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('une cible', () {
    expect({MightTarget.attack}.shortLabel(fr), 'Attaques');
    expect({MightTarget.attack}.shortLabel(en), 'Attacks');
  });

  test('plusieurs cibles, dans l ordre de MightTarget quel que soit le Set', () {
    expect(
      {MightTarget.alteration, MightTarget.skill}.shortLabel(fr),
      'Compétences · Altérations',
    );
    expect(
      MightTarget.values.toSet().shortLabel(en),
      'Attacks · Skills · Alterations',
    );
  });
}
