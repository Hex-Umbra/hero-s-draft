import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
import 'package:roguelike_card_game/services/content_editor/placeholder_filler.dart';

void main() {
  EntityDraft draft({
    Map<String, String> bilingual = const {},
    String mechanics = '{}',
    String? heroClass,
    bool isModification = false,
  }) =>
      EntityDraft(
        descriptor: kEntityDescriptors[EntityCategory.relic]!,
        id: 'talisman',
        bilingual: bilingual,
        mechanics: mechanics,
        heroClass: heroClass,
        isModification: isModification,
      );

  test('la prose vide recoit un placeholder criard', () {
    final filled = fillPlaceholders(draft());
    expect(filled.bilingual['name_fr'], '[À REMPLIR] talisman');
    expect(filled.bilingual['description_en'], '[À REMPLIR] talisman');
  });

  test('la prose saisie n est jamais ecrasee', () {
    final filled = fillPlaceholders(
      draft(bilingual: const {'name_fr': 'Talisman de fer'}),
    );
    expect(filled.bilingual['name_fr'], 'Talisman de fer');
    expect(filled.bilingual['name_en'], '[À REMPLIR] talisman');
  });

  test('une cle absente du corps prend la valeur du gabarit', () {
    final filled = fillPlaceholders(draft(mechanics: '{"value": 7}'));
    final decoded = jsonDecode(filled.mechanics) as Map<String, dynamic>;
    final template =
        kEntityDescriptors[EntityCategory.relic]!.decodeTemplate();

    expect(decoded['value'], 7, reason: 'la saisie prime sur le gabarit');
    for (final key in template.keys) {
      expect(decoded.containsKey(key), isTrue, reason: 'clé absente : $key');
    }
  });

  // Le fichier fait foi : les valeurs du gabarit ne sont pas les defauts du
  // modele, et les verser dans un fichier ecrit a la main changerait le jeu
  // en silence. Seule la prose vide recoit encore son placeholder.
  test('une modification ne recoit aucune cle du gabarit', () {
    final filled = fillPlaceholders(
      draft(mechanics: '{"value": 7}', isModification: true),
    );
    final decoded = jsonDecode(filled.mechanics) as Map<String, dynamic>;

    expect(decoded.keys, ['value']);
    expect(decoded['value'], 7);
    expect(filled.bilingual['name_fr'], '[À REMPLIR] talisman');
    expect(filled.bilingual['description_en'], '[À REMPLIR] talisman');
  });

  // Un corps illisible n'est pas l'affaire du remplisseur : le validateur sait
  // dire *pourquoi* il ne decode pas, et ce message-la vaut mieux qu'un
  // ecrasement silencieux par le gabarit.
  test('un corps JSON invalide ressort inchange', () {
    final broken = draft(mechanics: '{ pas du json');
    expect(fillPlaceholders(broken).mechanics, '{ pas du json');
  });

  test('les champs optionnels ne sont jamais perdus', () {
    final filled = fillPlaceholders(
      draft(heroClass: 'paladin', isModification: true),
    );
    expect(filled.heroClass, 'paladin');
    expect(filled.isModification, isTrue);
  });
}
