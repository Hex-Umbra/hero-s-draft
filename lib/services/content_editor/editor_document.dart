import 'dart:convert';

import 'entity_validator.dart';
import 'field_path.dart';

/// L'etat du formulaire : **un document**, et non une table de controleurs
/// (spec D4). Le formulaire et la vue « JSON brut » en sont deux vues.
///
/// `EntityDraft.mechanics` reste du texte : [toMechanics] le produit, et la
/// validation le juge comme avant.
class EditorDocument {
  EditorDocument(
    Map<String, dynamic> seed, {
    this.requiredKeys = const {},
    Map<String, dynamic> template = const {},
  })  : _root = _copy(seed),
        _template = template;

  /// Les cles de premier niveau que la regle d'omission ne retire jamais.
  final Set<String> requiredKeys;

  final Map<String, dynamic> _root;
  final Map<String, dynamic> _template;
  final Map<String, String> _conversions = {};

  /// Le document tel qu'il est. A lire seulement : toute ecriture passe par
  /// [setAt], qui efface la faute de conversion du meme chemin.
  Map<String, dynamic> get root => _root;

  static Map<String, dynamic> _copy(Map<String, dynamic> source) =>
      jsonDecode(jsonEncode(source)) as Map<String, dynamic>;

  Object? valueAt(FieldPath path) {
    Object? node = _root;
    for (final segment in path) {
      if (segment is String && node is Map<String, dynamic>) {
        node = node[segment];
      } else if (segment is int && node is List && segment < node.length) {
        node = node[segment];
      } else {
        return null;
      }
    }
    return node;
  }

  void setAt(FieldPath path, Object? value) {
    final parent = valueAt(path.sublist(0, path.length - 1));
    final last = path.last;
    if (parent is Map<String, dynamic> && last is String) {
      parent[last] = value;
    } else if (parent is List && last is int && last < parent.length) {
      parent[last] = value;
    } else {
      throw ArgumentError('chemin introuvable : ${labelOf(path)}');
    }
    clearConversion(path);
  }

  void removeAt(FieldPath path) {
    final parent = valueAt(path.sublist(0, path.length - 1));
    final last = path.last;
    if (parent is Map<String, dynamic> && last is String) parent.remove(last);
    clearConversion(path);
  }

  /// L'element qu'« Ajouter » clone : le premier de la meme liste au gabarit,
  /// a defaut le premier du document. `null` s'il n'y en a aucun.
  Map<String, dynamic>? modelElementFor(FieldPath listPath) {
    final pattern = patternOf(listPath);
    for (final source in [_template, _root]) {
      for (final (_, value) in valuesMatching(source, pattern)) {
        if (value is List &&
            value.isNotEmpty &&
            value.first is Map<String, dynamic>) {
          return _copy(value.first as Map<String, dynamic>);
        }
      }
    }
    return null;
  }

  bool addElement(FieldPath listPath) {
    final list = valueAt(listPath);
    final model = modelElementFor(listPath);
    if (list is! List || model == null) return false;
    list.add(model);
    return true;
  }

  void removeElement(FieldPath listPath, int index) {
    final list = valueAt(listPath);
    if (list is! List || index < 0 || index >= list.length) return;
    list.removeAt(index);
    // Les indices suivants se decalent : une faute rattachee a l'un d'eux
    // designerait desormais un autre element.
    final prefix = '${labelOf(listPath)}[';
    _conversions.removeWhere((label, _) => label.startsWith(prefix));
  }

  void reportConversion(FieldPath path, String message) =>
      _conversions[labelOf(path)] = message;

  void clearConversion(FieldPath path) => _conversions.remove(labelOf(path));

  List<ValidationFault> get conversionFaults => [
        for (final entry in _conversions.entries)
          ValidationFault(entry.value, field: entry.key),
      ];

  /// Le texte de `EntityDraft.mechanics`, **regle d'omission appliquee**
  /// (spec §3.3) : une chaine vide n'est jamais ecrite, sauf pour une cle
  /// requise de premier niveau — la validation dira alors pourquoi.
  String toMechanics() {
    final copy = _copy(_root);
    copy.removeWhere((key, value) => value == '' && !requiredKeys.contains(key));
    _omitNested(copy.values);
    return const JsonEncoder.withIndent('  ').convert(copy);
  }

  static void _omitNested(Iterable<Object?> values) {
    for (final value in values) {
      if (value is Map<String, dynamic>) {
        value.removeWhere((_, nested) => nested == '');
        _omitNested(value.values);
      } else if (value is List) {
        _omitNested(value);
      }
    }
  }
}
