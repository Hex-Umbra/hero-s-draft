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
            'le corps doit être un objet JSON, entre accolades',
          ),
        ];
      }
      mechanics = decoded;
    } on FormatException catch (e) {
      return [ValidationFault('JSON invalide : ${e.message}')];
    }

    for (final family in <List<ValidationFault> Function()>[
      () => _keys(draft, mechanics),
      () => _enums(draft, mechanics),
      () => _bilingual(draft),
      () => _references(draft, mechanics),
      () => _construct(draft),
    ]) {
      final faults = family();
      if (faults.isNotEmpty) return faults;
    }
    return const [];
  }

  /// Famille 1 — l'identifiant, sa forme, et son unicite.
  List<ValidationFault> _identity(EntityDraft draft) {
    if (draft.id.isEmpty) {
      return const [ValidationFault('un identifiant est requis', field: 'id')];
    }
    if (!_idPattern.hasMatch(draft.id)) {
      return [
        ValidationFault(
          'seuls les minuscules ASCII, les chiffres et le souligné sont '
          'admis (trouvé : "${draft.id}")',
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
      faults.add(ValidationFault('aucun fichier à modifier en ${draft.path}'));
    }
    if (!draft.isModification) {
      if (exists) {
        faults.add(ValidationFault('${draft.path} existe déjà'));
      }
      // Le controle disque ne voit qu'un chemin. Le registre voit tous ceux
      // d'une categorie — dont le cas d'une carte neutre homonyme d'une carte
      // de classe, que le chargeur rejette comme un doublon.
      if (_idsOf(draft.descriptor.category)?.contains(draft.id) ?? false) {
        faults.add(
          ValidationFault(
            'l\'identifiant "${draft.id}" est déjà porté par une entité de '
            'cette catégorie, sous un autre chemin',
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
            'ce champ est imposé par le répertoire et ne doit pas figurer '
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
          'le corps déclare "$restated" alors que l\'identifiant est '
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

  /// Famille 4 — les valeurs enumerees, contre les enumerations Dart reelles.
  ///
  /// **C'est le controle que `fromJson` avale** : `CardRarity`, `CardTarget` et
  /// `CardCategory` ont un `orElse` qui retombe en silence sur une valeur par
  /// defaut. La carte existe alors, et elle est fausse.
  List<ValidationFault> _enums(
    EntityDraft draft,
    Map<String, dynamic> mechanics,
  ) {
    final faults = <ValidationFault>[];

    draft.descriptor.enumKeys.forEach((key, allowed) {
      final value = mechanics[key];
      if (value == null) return; // absente : c'est l'affaire de la famille 3
      if (value is! String || !allowed.contains(value)) {
        faults.add(
          ValidationFault(
            'valeur inconnue "$value" — attendu : ${allowed.join(', ')}',
            field: key,
          ),
        );
      }
    });

    draft.descriptor.enumListKeys.forEach((key, allowed) {
      final value = mechanics[key];
      if (value == null) return;
      if (value is! List) {
        faults.add(ValidationFault('doit être une liste', field: key));
        return;
      }
      for (final element in value) {
        if (element is! String || !allowed.contains(element)) {
          faults.add(
            ValidationFault(
              'valeur inconnue "$element" — attendu : ${allowed.join(', ')}',
              field: key,
            ),
          );
        }
      }
    });

    return faults;
  }

  /// Famille 5 — les deux variantes linguistiques, presentes et non vides.
  ///
  /// Les bases ne sont **pas** les memes partout : un evenement porte `title`,
  /// un ennemi n'a pas de description. C'est le descripteur qui le dit.
  List<ValidationFault> _bilingual(EntityDraft draft) {
    final faults = <ValidationFault>[];
    for (final base in draft.descriptor.bilingualBases) {
      for (final suffix in const ['fr', 'en']) {
        final key = '${base}_$suffix';
        if ((draft.bilingual[key] ?? '').trim().isEmpty) {
          faults.add(
            ValidationFault(
              'les deux variantes linguistiques sont exigées, et non vides',
              field: key,
            ),
          );
        }
      }
    }
    return faults;
  }

  /// Famille 6 — les references vers une autre categorie.
  ///
  /// `passiveTrait` doit designer un passif existant : `referential_integrity_test`
  /// le verifie deja, et une reference pendante ferait rougir la suite bien
  /// apres l'ecriture.
  List<ValidationFault> _references(
    EntityDraft draft,
    Map<String, dynamic> mechanics,
  ) {
    final faults = <ValidationFault>[];
    draft.descriptor.referenceKeys.forEach((key, category) {
      final value = mechanics[key];
      if (value == null) return; // la cle est optionnelle
      final ids = _idsOf(category);
      if (ids == null) return; // registre indisponible : on ne devine pas
      if (value is! String || !ids.contains(value)) {
        faults.add(
          ValidationFault(
            'aucune entité de la catégorie '
            '"${kEntityDescriptors[category]!.label}" ne porte l\'identifiant '
            '"$value"',
            field: key,
          ),
        );
      }
    });
    return faults;
  }

  /// Famille 7 — le filet structurel, en dernier.
  ///
  /// Elle attrape ce que les six autres n'ont pas prevu : un `cost` textuel,
  /// un `choices` absent, un effet malforme. Elle ne les remplace pas — les
  /// familles 4 et 5 existent precisement parce qu'elle est trop permissive.
  List<ValidationFault> _construct(EntityDraft draft) {
    try {
      draft.descriptor.construct(draft.compose());
    } catch (e) {
      return [
        ValidationFault(
          'le modèle refuse ce document : ${e.toString().replaceAll('\n', ' ')}',
        ),
      ];
    }
    return const [];
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
