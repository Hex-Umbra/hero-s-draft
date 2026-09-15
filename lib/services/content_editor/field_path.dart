/// Un chemin dans un document JSON : des cles (`String`) et des indices
/// (`int`). `['effects', 0, 'type']` designe le type du premier effet.
typedef FieldPath = List<Object>;

/// Le motif d'un chemin, indices effaces : `effects[].type`. C'est la forme
/// sous laquelle le descripteur declare ses cles imbriquees.
String patternOf(FieldPath path) => _render(path, (_) => '[]');

/// Le libelle d'un chemin, indices compris : `effects[0].type`. C'est ce que
/// montrent une faute et la cle d'un champ.
String labelOf(FieldPath path) => _render(path, (index) => '[$index]');

String _render(FieldPath path, String Function(int index) indexed) {
  final buffer = StringBuffer();
  for (final segment in path) {
    if (segment is int) {
      buffer.write(indexed(segment));
    } else {
      if (buffer.isNotEmpty) buffer.write('.');
      buffer.write(segment);
    }
  }
  return buffer.toString();
}

/// Toutes les valeurs de [root] que [pattern] designe, avec leur chemin.
///
/// Une cle absente ne rend rien ; `[]` parcourt chaque element d'une liste.
List<(FieldPath, Object?)> valuesMatching(
  Map<String, dynamic> root,
  String pattern,
) {
  final results = <(FieldPath, Object?)>[];

  void walk(Object? node, List<String> segments, FieldPath path) {
    if (segments.isEmpty) {
      results.add((path, node));
      return;
    }
    final head = segments.first;
    final rest = segments.sublist(1);
    final isList = head.endsWith('[]');
    final key = isList ? head.substring(0, head.length - 2) : head;
    if (node is! Map<String, dynamic> || !node.containsKey(key)) return;

    final child = node[key];
    if (!isList) {
      walk(child, rest, [...path, key]);
      return;
    }
    if (child is! List) return;
    for (var i = 0; i < child.length; i++) {
      walk(child[i], rest, [...path, key, i]);
    }
  }

  walk(root, pattern.split('.'), const []);
  return results;
}
