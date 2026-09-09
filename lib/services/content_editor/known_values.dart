import 'dart:convert';

import 'content_file_system.dart';
import 'entity_catalog.dart';
import 'entity_descriptor.dart';

/// Les valeurs deja employees par les entites existantes, cle par cle et
/// triees.
///
/// **Derivee du disque, jamais ecrite a la main** : elle ne peut donc pas se
/// perimer. C'est ce qui rend `effectType` decouvrable — chaine libre cote
/// modele, vocabulaire ferme cote moteur, qu'aucune documentation ne liste.
Map<String, List<String>> knownValues(
  ContentFileSystem fs,
  String rootPath,
  EntityDescriptor descriptor,
) {
  // L'identifiant et la prose ne sont pas un vocabulaire : les montrer
  // noierait les cles qui en ont un.
  final ignored = <String>{
    'id',
    for (final base in descriptor.bilingualBases) ...{
      base,
      '${base}_fr',
      '${base}_en',
    },
  };

  final collected = <String, Set<String>>{};

  void take(String key, Object? value) {
    if (ignored.contains(key)) return;
    if (value is String) {
      if (value.isNotEmpty) (collected[key] ??= <String>{}).add(value);
    } else if (value is List) {
      for (final element in value) {
        if (element is String && element.isNotEmpty) {
          (collected[key] ??= <String>{}).add(element);
        }
      }
    }
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
    if (decoded is! Map<String, dynamic>) continue;
    decoded.forEach(take);
  }

  return {
    for (final entry in collected.entries)
      entry.key: (entry.value.toList()..sort()),
  };
}
