import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Une categorie d entites : ou les trouver, comment les construire, et ce
/// que leur emplacement dit d elles.
///
/// Le motif de chemin porte a la fois la **selection** et l **injection** :
/// les segments captures alimentent [inject]. C est ce qui permet a
/// `classes/paladin/cards/smite.json` d etre, par construction, une carte du
/// paladin — sans qu aucun champ du fichier n ait a le dire.
class EntitySource<T> {
  const EntitySource(
    this.pattern,
    this.fromJson, {
    this.inject,
    this.redundantFields = const {'id'},
  });

  /// Motif de chemin d asset. Chaque segment est soit un litteral, soit `*`
  /// (un segment quelconque, capture tel quel), soit `*.json` (un segment
  /// finissant par `.json`, capture sans son extension).
  ///
  /// Le nombre de segments doit correspondre exactement : c est ce qui
  /// separe `classes/*/class.json` de `classes/*/cards/*.json`, et ce qui
  /// ecarte les assets de paquets, sous `packages/<nom>/...`.
  final String pattern;

  final T Function(Map<String, dynamic>) fromJson;

  /// Les champs que le repertoire impose, calcules depuis les segments
  /// captures par [pattern], dans l ordre ou ils apparaissent.
  final Map<String, dynamic> Function(List<String> captures)? inject;

  /// Les champs injectes qu un fichier a le droit de redeclarer, a condition
  /// que la valeur soit identique. Tout autre champ injecte present dans le
  /// JSON fait echouer le chargement.
  ///
  /// `id` y figure a titre permanent : le porter dans le fichier le rend
  /// lisible hors contexte et inspectable en masse. `heroClass` et
  /// `category` n y sont que le temps de la migration.
  final Set<String> redundantFields;
}

class _Match {
  const _Match(this.key, this.captures);
  final String key;
  final List<String> captures;
}

class _Entry<T> {
  const _Entry(this.key, this.id, this.raw, this.fromJson);
  final String key;
  final String id;
  final Map<String, dynamic> raw;
  final T Function(Map<String, dynamic>) fromJson;
}

/// Charge les entites du jeu depuis un [AssetBundle], une categorie a la fois,
/// en accumulant les erreurs plutot qu en levant a la premiere.
///
/// Le [bundle] est un parametre et non `rootBundle` en dur : c est le seul
/// point qui rend le chargeur testable sur une arborescence choisie.
class GameDataLoader {
  GameDataLoader(this.bundle);

  final AssetBundle bundle;

  AssetManifest? _manifest;
  Future<void>? _preparing;
  final List<String> _errors = [];

  /// Charge le manifeste d assets. Idempotent : les appels suivants rendent
  /// le meme futur. [loadAll] l appelle lui-meme, de sorte qu aucun appelant
  /// ne puisse l oublier.
  Future<void> prepare() {
    return _preparing ??= () async {
      _manifest = await AssetManifest.loadFromAssetBundle(bundle);
    }();
  }

  /// Charge, fusionne, trie par `id` et deduplique les entites de [sources].
  ///
  /// Une entite dont le JSON est illisible ou dont `fromJson` leve est
  /// **exclue** du resultat : le chargement va jusqu au bout pour collecter
  /// toutes les fautes, que [throwIfFailed] remonte en une fois.
  Future<List<T>> loadAll<T>(List<EntitySource<T>> sources) async {
    await prepare();

    final entries = <_Entry<T>>[];

    for (final source in sources) {
      final matches = _match(source.pattern);
      final raws = await Future.wait(matches.map(_read));

      for (var i = 0; i < matches.length; i++) {
        final raw = raws[i];
        if (raw == null) continue;

        final merged = _applyInjection(source, matches[i], raw);
        if (merged == null) continue;

        final id = merged['id'];
        if (id is! String || id.isEmpty) {
          _errors.add('${matches[i].key} : champ "id" absent ou non textuel');
          continue;
        }
        entries.add(_Entry<T>(matches[i].key, id, merged, source.fromJson));
      }
    }

    entries.sort((a, b) => a.id.compareTo(b.id));

    final result = <T>[];
    final seen = <String, String>{};
    for (final entry in entries) {
      final previous = seen[entry.id];
      if (previous != null) {
        _errors.add('id "${entry.id}" declare deux fois : $previous et ${entry.key}');
        continue;
      }
      seen[entry.id] = entry.key;
      try {
        result.add(entry.fromJson(entry.raw));
      } catch (e) {
        _errors.add('${entry.key} : ${e.toString().replaceAll('\n', ' ')}');
      }
    }

    return result;
  }

  /// Leve une fois, a la fin, si une seule faute a ete collectee — toutes
  /// categories confondues.
  void throwIfFailed() {
    if (_errors.isEmpty) return;

    debugPrint(
      '[data] ${_errors.length} erreur(s) de chargement :\n${_errors.join('\n')}',
    );

    final shown = _errors.take(10).join('\n');
    final rest = _errors.length > 10
        ? '\n… et ${_errors.length - 10} autres (liste complete en debug)'
        : '';
    throw Exception(
      'Chargement des donnees : ${_errors.length} erreur(s).\n$shown$rest',
    );
  }

  Future<Map<String, dynamic>?> _read(_Match match) async {
    try {
      final decoded = jsonDecode(await bundle.loadString(match.key));
      if (decoded is! Map<String, dynamic>) {
        _errors.add(
          '${match.key} : le fichier doit contenir un objet JSON, pas un ${decoded.runtimeType}',
        );
        return null;
      }
      return decoded;
    } catch (e) {
      _errors.add('${match.key} : ${e.toString().replaceAll('\n', ' ')}');
      return null;
    }
  }

  /// Fusionne les champs imposes par le repertoire dans [raw].
  ///
  /// Regle de conflit (option C de la spec) : le repertoire injecte, le JSON
  /// a le droit de confirmer a l identique s il figure dans
  /// [EntitySource.redundantFields], et la contradiction echoue en nommant le
  /// fichier, le champ, l attendu et le trouve.
  Map<String, dynamic>? _applyInjection<T>(
    EntitySource<T> source,
    _Match match,
    Map<String, dynamic> raw,
  ) {
    final injected = source.inject?.call(match.captures);
    if (injected == null) return raw;

    final merged = Map<String, dynamic>.of(raw);
    var ok = true;

    injected.forEach((field, value) {
      if (!raw.containsKey(field)) {
        merged[field] = value;
        return;
      }
      if (!source.redundantFields.contains(field)) {
        _errors.add(
          '${match.key} : le champ "$field" est impose par le repertoire et '
          'ne doit pas figurer dans le fichier (trouve : "${raw[field]}")',
        );
        ok = false;
        return;
      }
      if (raw[field] != value) {
        _errors.add(
          '${match.key} : champ "$field" — le repertoire impose "$value", '
          'le fichier declare "${raw[field]}"',
        );
        ok = false;
      }
    });

    return ok ? merged : null;
  }

  List<_Match> _match(String pattern) {
    final patternSegments = pattern.split('/');
    final matches = <_Match>[];

    for (final key in _manifest!.listAssets()) {
      final keySegments = key.split('/');
      if (keySegments.length != patternSegments.length) continue;

      final captures = <String>[];
      var ok = true;

      for (var i = 0; i < patternSegments.length; i++) {
        final p = patternSegments[i];
        final s = keySegments[i];

        if (p == '*') {
          captures.add(s);
        } else if (p.startsWith('*.')) {
          final extension = p.substring(1);
          if (!s.endsWith(extension) || s.length <= extension.length) {
            ok = false;
            break;
          }
          captures.add(s.substring(0, s.length - extension.length));
        } else if (p != s) {
          ok = false;
          break;
        }
      }

      if (ok) matches.add(_Match(key, captures));
    }

    return matches;
  }
}
