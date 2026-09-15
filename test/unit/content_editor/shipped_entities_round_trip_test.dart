import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/editor_document.dart';
import 'package:roguelike_card_game/services/content_editor/entity_catalog.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
import 'package:roguelike_card_game/services/content_editor/entity_validator.dart';
import 'package:roguelike_card_game/services/content_editor/placeholder_filler.dart';

/// **Chaque entite livree se modifie sans rien toucher.**
///
/// Charger un fichier de `assets/data/` en mode Modifier, puis Ecrire sans
/// rien changer, doit passer la validation et reecrire le meme document. Les
/// tests voisins jugent des bacs a sable ecrits a la main ; seul celui-ci voit
/// les donnees reelles — c'est lui qui a attrape la couleur de forge declaree
/// hex quand les huit fichiers livres portent des noms du moteur, et le
/// gabarit qui completait trente-deux fichiers livres a chaque ecriture.
void main() {
  const fs = IoContentFileSystem();
  final root = IoContentFileSystem.toSlashes(Directory.current.path);

  /// Le brouillon que l'ecran construit apres `_load`, tel que `_judge` le
  /// juge : prose dans ses champs, mecanique passee par `EditorDocument`.
  EntityDraft modifierDraft(
    EntityDescriptor descriptor,
    String relative,
    Map<String, dynamic> file,
  ) {
    final segments = relative.split('/');
    final isClassCard = descriptor.supportsHeroClass &&
        segments.length > 4 &&
        segments[2] == 'classes';
    final id = descriptor.folderFile != null
        ? segments[segments.length - 2]
        : segments.last.substring(0, segments.last.length - '.json'.length);

    final prose = <String, String>{
      for (final base in descriptor.bilingualBases)
        for (final suffix in const ['fr', 'en'])
          '${base}_$suffix': switch (file['${base}_$suffix']) {
            final String text => text,
            _ => '',
          },
    };

    final seed = <String, dynamic>{
      for (final entry in file.entries)
        if (entry.key != 'id' &&
            !descriptor.isComputedImage(entry.key) &&
            !prose.containsKey(entry.key))
          entry.key: entry.value,
    };

    return fillPlaceholders(EntityDraft(
      descriptor: descriptor,
      id: id,
      heroClass: isClassCard ? segments[3] : null,
      isModification: true,
      bilingual: prose,
      mechanics: EditorDocument(
        seed,
        requiredKeys: descriptor.requiredKeys,
        template: descriptor.decodeTemplate(),
      ).toMechanics(),
    ));
  }

  for (final descriptor in kEntityDescriptors.values) {
    test('${descriptor.label} : chaque fichier livre se modifie a l identique',
        () {
      final files = entityFiles(fs, root, descriptor);
      expect(files, isNotEmpty,
          reason: 'aucun fichier livre : le test ne prouverait rien');

      final validator = EntityValidator(fs: fs, rootPath: root);
      final failures = <String>[];
      for (final relative in files) {
        final file =
            jsonDecode(fs.readFile('$root/$relative')) as Map<String, dynamic>;
        final draft = modifierDraft(descriptor, relative, file);

        final faults = validator.validate(draft);
        if (faults.isNotEmpty) {
          failures.add('$relative refuse : ${faults.join(' ; ')}');
          continue;
        }
        final composed = draft.compose();
        // Egalite profonde, l'ordre des cles d'un objet excepte.
        if (!equals(file).matches(composed, <dynamic, dynamic>{})) {
          failures.add('$relative reecrit autrement :\n'
              '  livre  : ${jsonEncode(file)}\n'
              '  ecrit  : ${jsonEncode(composed)}');
        }
      }

      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }
}
