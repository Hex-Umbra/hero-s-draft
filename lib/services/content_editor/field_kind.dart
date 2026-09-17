import 'entity_descriptor.dart';
import 'field_path.dart';

/// Le widget qu'une valeur recoit (spec §4.3).
enum FieldKind {
  asset,
  reference,
  referenceList,
  color,
  enumChoice,
  enumMulti,
  vocabulary,
  boolean,
  integer,
  decimal,
  text,
  objectList,
  stringList,
  object,
  rawJson,
}

/// **La premiere regle qui s'applique l'emporte** : les metadonnees du
/// descripteur d'abord, le type JSON ensuite. [hasModelElement] dit si une
/// liste vide a un element a cloner — sans lui, « Ajouter » n'aurait rien a
/// ajouter.
FieldKind inferFieldKind({
  required FieldPath path,
  required Object? value,
  required EntityDescriptor descriptor,
  bool hasModelElement = false,
}) {
  final pattern = patternOf(path);
  if (descriptor.assetKeys.containsKey(pattern)) return FieldKind.asset;
  if (descriptor.referenceKeys.containsKey(pattern)) return FieldKind.reference;
  if (descriptor.referenceListKeys.containsKey(pattern)) {
    return FieldKind.referenceList;
  }
  if (descriptor.hexColorKeys.contains(pattern)) return FieldKind.color;
  if (descriptor.enumKeys.containsKey(pattern)) return FieldKind.enumChoice;
  if (descriptor.enumListKeys.containsKey(pattern)) return FieldKind.enumMulti;
  if (descriptor.vocabularyKeys.contains(pattern)) return FieldKind.vocabulary;

  if (value is bool) return FieldKind.boolean;
  if (value is int) return FieldKind.integer;
  if (value is double) return FieldKind.decimal;
  if (value is String) return FieldKind.text;
  if (value is List) {
    if (value.isEmpty) {
      return hasModelElement ? FieldKind.objectList : FieldKind.rawJson;
    }
    if (value.every((element) => element is Map<String, dynamic>)) {
      return FieldKind.objectList;
    }
    if (value.every((element) => element is String)) {
      return FieldKind.stringList;
    }
    return FieldKind.rawJson;
  }
  if (value is Map<String, dynamic>) return FieldKind.object;
  return FieldKind.rawJson;
}
