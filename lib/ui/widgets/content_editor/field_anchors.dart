import 'package:flutter/widgets.dart';

/// Les ancres des champs du formulaire, par nom de champ — celui que porte
/// `ValidationFault.field` : une cle de premier niveau (`id`), ou le libelle
/// d'un chemin (`effects[0].value`).
///
/// Une `GlobalKey` par champ, posee par le widget qui le rend : le bandeau
/// d'issue n'a qu'a demander a le revoir.
class FieldAnchors {
  final Map<String, GlobalKey> _keys = {};

  GlobalKey keyFor(String field) =>
      _keys.putIfAbsent(field, () => GlobalKey(debugLabel: field));

  /// Fait defiler le formulaire jusqu'au champ. Sans effet si aucun widget ne
  /// le porte : une faute peut viser un champ que le formulaire ne montre pas.
  Future<void> reveal(String field) async {
    final context = _keys[field]?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}
