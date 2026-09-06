import 'dart:convert';

import 'package:meta/meta.dart';

import '../../models/data/game_data_registry.dart';
import 'content_file_system.dart';
import 'entity_descriptor.dart';
import 'entity_draft.dart';

/// Une raison de ne pas ecrire.
@immutable
class ValidationFault {
  const ValidationFault(this.message, {this.field});

  final String message;

  /// La cle concernee, quand il y en a une.
  final String? field;

  @override
  String toString() => field == null ? message : '$field : $message';
}

/// Refuse tout ce qui ne doit pas etre ecrit.
///
/// Les familles sont evaluees dans l'ordre, du moins cher au plus structurel,
/// et **on s'arrete a la premiere en echec**. Un corps JSON qui ne decode pas
/// produit mecaniquement une dizaine de cles manquantes ; un rapport qui
/// melangerait les deux serait illisible, et la seule faute a corriger est la
/// premiere.
class EntityValidator {
  const EntityValidator({
    required this.fs,
    required this.rootPath,
    this.registry,
  });

  final ContentFileSystem fs;
  final String rootPath;

  /// Le registre charge. `null` quand il n'est pas disponible : les controles
  /// qui en dependent sont alors sautes, jamais devines.
  final GameDataRegistry? registry;

  static final RegExp _idPattern = RegExp(r'^[a-z0-9_]+$');

  List<ValidationFault> validate(EntityDraft draft) {
    final identity = _identity(draft);
    if (identity.isNotEmpty) return identity;

    final Map<String, dynamic> mechanics;
    try {
      final decoded = jsonDecode(draft.mechanics);
      if (decoded is! Map<String, dynamic>) {
        return const [
          ValidationFault(
            'le corps doit etre un objet JSON, entre accolades',
          ),
        ];
      }
      mechanics = decoded;
    } on FormatException catch (e) {
      return [ValidationFault('JSON invalide : ${e.message}')];
    }

    return _keys(draft, mechanics);
  }

  /// Famille 1 — l'identifiant, sa forme, et son unicite.
  List<ValidationFault> _identity(EntityDraft draft) {
    if (draft.id.isEmpty) {
      return const [ValidationFault('un identifiant est requis', field: 'id')];
    }
    if (!_idPattern.hasMatch(draft.id)) {
      return [
        ValidationFault(
          'seuls les minuscules ASCII, les chiffres et le souligne sont '
          'admis (trouve : "${draft.id}")',
          field: 'id',
        ),
      ];
    }
    final heroClass = draft.heroClass;
    if (heroClass != null && !_idPattern.hasMatch(heroClass)) {
      return [
        ValidationFault('nom de classe invalide : "$heroClass"',
            field: 'heroClass'),
      ];
    }

    final faults = <ValidationFault>[];
    final exists = fs.fileExists('$rootPath/${draft.path}');

    if (draft.isModification && !exists) {
      faults.add(ValidationFault('aucun fichier a modifier en ${draft.path}'));
    }
    if (!draft.isModification) {
      if (exists) {
        faults.add(ValidationFault('${draft.path} existe deja'));
      }
      // Le controle disque ne voit qu'un chemin. Le registre voit tous ceux
      // d'une categorie — dont le cas d'une carte neutre homonyme d'une carte
      // de classe, que le chargeur rejette comme un doublon.
      if (_idsOf(draft.descriptor.category)?.contains(draft.id) ?? false) {
        faults.add(
          ValidationFault(
            'l identifiant "${draft.id}" est deja porte par une entite de '
            'cette categorie, sous un autre chemin',
            field: 'id',
          ),
        );
      }
    }
    return faults;
  }

  /// Famille 3 — les cles obligatoires, et celles que le repertoire impose.
  List<ValidationFault> _keys(
    EntityDraft draft,
    Map<String, dynamic> mechanics,
  ) {
    final faults = <ValidationFault>[];

    for (final key in draft.descriptor.forbiddenKeys) {
      if (mechanics.containsKey(key)) {
        faults.add(
          ValidationFault(
            'ce champ est impose par le repertoire et ne doit pas figurer '
            'dans le fichier',
            field: key,
          ),
        );
      }
    }

    // `id` est le seul champ injecte redeclarable, et seulement a l'identique.
    final restated = mechanics['id'];
    if (restated != null && restated != draft.id) {
      faults.add(
        ValidationFault(
          'le corps declare "$restated" alors que l identifiant est '
          '"${draft.id}"',
          field: 'id',
        ),
      );
    }

    for (final key in draft.descriptor.requiredKeys) {
      if (!mechanics.containsKey(key)) {
        faults.add(ValidationFault('champ obligatoire absent', field: key));
      }
    }

    return faults;
  }

  Set<String>? _idsOf(EntityCategory category) {
    final r = registry;
    if (r == null) return null;
    switch (category) {
      case EntityCategory.card:
        return r.cards.map((e) => e.id).toSet();
      case EntityCategory.relic:
        return r.relics.map((e) => e.id).toSet();
      case EntityCategory.event:
        return r.events.map((e) => e.id).toSet();
      case EntityCategory.passive:
        return r.passives.map((e) => e.id).toSet();
      case EntityCategory.forgeUpgrade:
        return r.forgeUpgrades.map((e) => e.id).toSet();
      case EntityCategory.heroClass:
        return r.heroes.map((e) => e.id).toSet();
      case EntityCategory.enemy:
        return r.enemies.map((e) => e.id).toSet();
    }
  }
}
