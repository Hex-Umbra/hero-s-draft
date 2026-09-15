import 'dart:convert';

import 'content_file_system.dart';
import 'entity_catalog.dart';
import 'entity_descriptor.dart';
import 'field_path.dart';

/// Les valeurs deja employees par les entites existantes, **par motif** et
/// triees : `rarity`, mais aussi `effects[].type`.
///
/// **Derivee du disque, jamais ecrite a la main** : elle ne peut donc pas se
/// perimer. C'est ce qui rend `effectType` decouvrable — chaine libre cote
/// modele, vocabulaire ferme cote moteur, qu'aucune documentation ne liste.
Map<String, List<String>> knownValues(
  ContentFileSystem fs,
  String rootPath,
  EntityDescriptor descriptor,
) {
  final collected = <String, Set<String>>{};

  void add(String pattern, String value) {
    if (value.isNotEmpty) (collected[pattern] ??= <String>{}).add(value);
  }

  // L'identifiant et la prose ne sont pas un vocabulaire : les montrer
  // noierait les cles qui en ont un. La prose imbriquee (`text_fr` d'un choix)
  // non plus.
  bool ignored(String prefix, String key) {
    if (key.endsWith('_fr') || key.endsWith('_en')) return true;
    return prefix.isEmpty &&
        (key == 'id' || descriptor.bilingualBases.contains(key));
  }

  void take(String prefix, Map<String, dynamic> map) {
    map.forEach((key, value) {
      if (ignored(prefix, key)) return;
      final pattern = prefix.isEmpty ? key : '$prefix.$key';
      if (value is String) {
        add(pattern, value);
      } else if (value is List) {
        for (final element in value) {
          if (element is String) {
            add(pattern, element);
          } else if (element is Map<String, dynamic>) {
            take('$pattern[]', element);
          }
        }
      } else if (value is Map<String, dynamic>) {
        take(pattern, value);
      }
    });
  }

  for (final relative in entityFiles(fs, rootPath, descriptor)) {
    final Object? decoded;
    try {
      decoded = jsonDecode(fs.readFile('$rootPath/$relative'));
    } catch (_) {
      // Un fichier illisible ne doit pas priver du panneau entier : il sera
      // signale par le chargement du jeu, pas par un panneau d'aide.
      continue;
    }
    if (decoded is Map<String, dynamic>) take('', decoded);
  }

  return {
    for (final entry in collected.entries)
      entry.key: (entry.value.toList()..sort()),
  };
}

/// Ce que chaque `vocabularyKey` admet : l'usage de **toute** la categorie,
/// fichier edite compris, plus les valeurs du gabarit.
///
/// Exclure le fichier edite refuserait de modifier toute carte portant une
/// valeur unique — l'animation `fire`, le statut `burn`, chacun porte par une
/// seule carte (spec §4.5).
Map<String, List<String>> vocabularyOf(
  EntityDescriptor descriptor,
  Map<String, List<String>> known,
) {
  final template = descriptor.decodeTemplate();
  return {
    for (final pattern in descriptor.vocabularyKeys)
      pattern: ({
        ...?known[pattern],
        for (final (_, value) in valuesMatching(template, pattern))
          if (value is String && value.isNotEmpty) value,
      }.toList()
        ..sort()),
  };
}
