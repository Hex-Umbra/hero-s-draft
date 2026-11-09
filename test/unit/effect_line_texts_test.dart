import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/effect_line_texts.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';

/// La seule écriture des lignes de la liste de l'appui long (spec A41, §6.1).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  EffectLine line(String kind, [int? value, int? duration]) =>
      (kind: kind, value: value, duration: duration);

  /// Les treize sortes, chacune avec une valeur et, pour un statut, une durée.
  final thirteen = [
    line('damage', 10),
    line('armor', 4),
    line('heal', 3),
    line('draw', 2),
    line('gain_mana', 1),
    line('status:might', 2, 2),
    line('status:might_regen', 1, 3),
    line('status:armor_regen', 2, 3),
    line('status:weakness', 1, 2),
    line('status:vulnerable', 1, 2),
    line('status:burn', 3, 2),
    line('crit', 5),
    line('target:allEnemies'),
  ];

  test('les treize sortes ont leur phrase, en francais et en anglais', () {
    // La phrase exacte de chaque sorte, en français ; en anglais pour
    // quelques-unes (null : non nulle seulement).
    final expected = <String, (String, String?)>{
      'damage': ('Inflige 10 dégâts', 'Deal 10 damage'),
      'armor': ("Donne 4 d'Armure", 'Gain 4 Block'),
      'heal': ('Soigne 3 PV', null),
      'draw': ('Pioche 2 cartes', null),
      'gain_mana': ('Gagne 1 Mana', null),
      'status:might': ('Gagne 2 Puissance pendant 2 tours', null),
      'status:might_regen': (
        'Pendant 3 tours, gagne 1 Puissance au début du tour',
        null
      ),
      'status:armor_regen': (
        'Pendant 3 tours, gagne 2 Armure au début du tour',
        null
      ),
      'status:weakness': (
        'Applique 1 Faiblesse pendant 2 tours',
        'Apply 1 Weakness for 2 turns'
      ),
      'status:vulnerable': (
        'Applique 1 Vulnérable pendant 2 tours',
        'Apply 1 Vulnerable for 2 turns'
      ),
      'status:burn': (
        'Applique 3 Brûlure pendant 2 tours',
        'Apply 3 Burn for 2 turns'
      ),
      'crit': ('+5 % de critique', '+5% critical chance'),
      'target:allEnemies': ('Touche tous les ennemis', 'Hits all enemies'),
    };
    expect(expected.keys, unorderedEquals([for (final l in thirteen) l.kind]));
    for (final l in thirteen) {
      final (phraseFr, phraseEn) = expected[l.kind]!;
      expect(EffectLineTexts.phrase(fr, l), phraseFr, reason: l.kind);
      expect(EffectLineTexts.phrase(en, l), phraseEn ?? isNotNull,
          reason: l.kind);
    }
  });

  test('les pluriels se lisent sur la valeur et la duree', () {
    expect(EffectLineTexts.phrase(fr, line('draw', 1)), 'Pioche 1 carte');
    expect(EffectLineTexts.phrase(fr, line('draw', 2)), 'Pioche 2 cartes');
    expect(EffectLineTexts.phrase(fr, line('status:might', 2, 1)),
        'Gagne 2 Puissance ce tour-ci');
    expect(EffectLineTexts.phrase(fr, line('status:might', 2, 2)),
        'Gagne 2 Puissance pendant 2 tours');
    expect(EffectLineTexts.phrase(fr, line('status:burn', 1, 1)),
        'Applique 1 Brûlure pendant 1 tour');
  });

  test('aucune phrase ne finit par un point', () {
    for (final l10n in [fr, en]) {
      for (final l in thirteen) {
        expect(EffectLineTexts.phrase(l10n, l), isNot(endsWith('.')),
            reason: '${l.kind} (${l10n.localeName})');
      }
    }
  });

  test('hors des treize sortes, aucune phrase', () {
    for (final l10n in [fr, en]) {
      for (final kind in ['status:poison', 'status:freeze', 'status:shock']) {
        expect(EffectLineTexts.phrase(l10n, line(kind, 2, 2)), isNull,
            reason: kind);
      }
    }
  });
}
