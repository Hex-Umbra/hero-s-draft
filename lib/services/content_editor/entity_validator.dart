import 'dart:convert';

import 'package:meta/meta.dart';

import '../../models/data/game_data_registry.dart';
import 'audio_catalog.dart';
import 'content_file_system.dart';
import 'entity_descriptor.dart';
import 'entity_draft.dart';
import 'field_path.dart';
import 'known_values.dart';
import 'pending_import.dart';

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
    this.imports = const [],
    this.pendingIds = const {},
  });

  final ContentFileSystem fs;
  final String rootPath;

  /// Le registre charge. `null` quand il n'est pas disponible : les controles
  /// qui en dependent sont alors sautes, jamais devines.
  final GameDataRegistry? registry;

  /// Les fichiers choisis, en attente d'« Écrire » : un son importe est
  /// declare pour cette validation, comme il le sera a l'ecriture.
  final List<PendingImport> imports;

  /// Les identifiants que **la même transaction** va écrire, et que le
  /// registre chargé au démarrage ne connaît donc pas encore.
  ///
  /// Une recette de classe écrit la classe, puis un passif qui la nomme : au
  /// moment où ce passif est jugé, la classe n'existe ni dans le registre ni
  /// sur le disque. `_signatureCards` contournait le problème en n'étant pas
  /// un contrôle par référence (voir sa documentation) ; le passif, lui, en
  /// est un. C'est ce seam, nommé.
  final Map<EntityCategory, Set<String>> pendingIds;

  static final RegExp _idPattern = RegExp(r'^[a-z0-9_]+$');
  static final RegExp _hexColorPattern = RegExp(r'^#[0-9a-fA-F]{6}$');

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
      () => _vocabulary(draft, mechanics),
      () => _hexColors(draft, mechanics),
      () => _bilingual(draft),
      () => _references(draft, mechanics),
      () => _assets(draft, mechanics),
      () => _signatureCards(draft, mechanics),
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
      //
      // `_registryIdsOf`, et non `_idsOf` : cette derniere unit les
      // identifiants en attente, et une recette de classe annonce son propre
      // identifiant comme pendant pour que le passif qui la nomme ne soit pas
      // refuse (famille 6). L'unicite, elle, ne doit jamais se comparer a
      // elle-meme — sans quoi la classe qu'une recette s'apprete a ecrire se
      // trouverait deja « portee par une entite de cette categorie ».
      if (_registryIdsOf(draft.descriptor.category)?.contains(draft.id) ??
          false) {
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

    draft.descriptor.enumKeys.forEach((pattern, allowed) {
      for (final (path, value) in valuesMatching(mechanics, pattern)) {
        if (value == null) continue; // absente : l'affaire de la famille 3
        if (value is! String || !allowed.contains(value)) {
          faults.add(
            ValidationFault(
              'valeur inconnue "$value" — attendu : ${allowed.join(', ')}',
              field: labelOf(path),
            ),
          );
        }
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

  /// Les chaines libres cote modele mais fermees cote moteur.
  ///
  /// `dice_throw` portait `"type": "skill"` — un type de carte, pas d'effet :
  /// `CardData.fromJson` l'accepte, et la carte ne fait rien en jeu. Admis :
  /// l'usage de la categorie sur le disque, et le gabarit.
  List<ValidationFault> _vocabulary(
    EntityDraft draft,
    Map<String, dynamic> mechanics,
  ) {
    final descriptor = draft.descriptor;
    if (descriptor.vocabularyKeys.isEmpty) return const [];

    final admitted =
        vocabularyOf(descriptor, knownValues(fs, rootPath, descriptor));
    final faults = <ValidationFault>[];
    for (final pattern in descriptor.vocabularyKeys) {
      final values = admitted[pattern] ?? const <String>[];
      for (final (path, value) in valuesMatching(mechanics, pattern)) {
        if (value == null) continue;
        if (value is! String || !values.contains(value)) {
          faults.add(
            ValidationFault(
              '« $value » n\'est employé ni par un fichier ni par le gabarit : '
              'le moteur ne le connaît pas',
              field: labelOf(path),
            ),
          );
        }
      }
    }
    return faults;
  }

  /// Les cles couleur du descripteur — `themeColor` pour une classe —
  /// doivent porter un `#RRGGBB` valide quand elles sont presentes. Une cle
  /// absente reste optionnelle et passe : c'est au gabarit ou au remplissage
  /// de la fournir, jamais a cette famille de l'imposer.
  ///
  /// Sans ce controle, un hex mal forme (tape dans la vue JSON brute, ou deja
  /// dans un fichier retouche a la main) est ecrit tel quel, puis avale en
  /// silence au chargement — `HeroData._parseHexColor` rend `null` et la
  /// classe retombe au bleu par defaut, sans que personne sache pourquoi.
  List<ValidationFault> _hexColors(
    EntityDraft draft,
    Map<String, dynamic> mechanics,
  ) {
    final faults = <ValidationFault>[];
    for (final key in draft.descriptor.hexColorKeys) {
      final value = mechanics[key];
      if (value == null) continue; // absente : optionnelle
      if (value is! String || !_hexColorPattern.hasMatch(value)) {
        faults.add(
          ValidationFault(
            'doit être une couleur hexadécimale valide (#RRGGBB), trouvé '
            '"$value"',
            field: key,
          ),
        );
      }
    }
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
  /// Une reference doit designer une entite existante : une reference
  /// pendante ferait rougir `referential_integrity_test` bien apres
  /// l'ecriture.
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
    draft.descriptor.referenceListKeys.forEach((key, category) {
      final value = mechanics[key];
      if (value == null) return; // absente : toute la categorie
      if (value is! List) {
        faults.add(ValidationFault('doit être une liste', field: key));
        return;
      }
      if (value.isEmpty) {
        faults.add(
          ValidationFault(
            'une liste vide ne désigne personne — retirer la clé pour viser '
            'toute la catégorie',
            field: key,
          ),
        );
        return;
      }
      final ids = _idsOf(category);
      if (ids == null) return; // registre indisponible : on ne devine pas
      for (final element in value) {
        if (element is! String || !ids.contains(element)) {
          faults.add(
            ValidationFault(
              'aucune entité de la catégorie '
              '"${kEntityDescriptors[category]!.label}" ne porte l\'identifiant '
              '"$element"',
              field: key,
            ),
          );
        }
      }
    });
    return faults;
  }

  /// Les ressources : un son doit etre declare, un import doit pouvoir etre
  /// copie, une image obligatoire — ou optionnelle et declaree — doit exister.
  ///
  /// `audio_catalogue_test` refuse tout `sfx` non declare : ce controle
  /// l'avance au moment de l'ecriture, `"sfx": ""` compris.
  List<ValidationFault> _assets(
    EntityDraft draft,
    Map<String, dynamic> mechanics,
  ) {
    final descriptor = draft.descriptor;
    final faults = <ValidationFault>[];
    final declared = soundIds(fs, rootPath).toSet();
    final pendingSounds = {
      for (final pending in imports)
        if (pending.soundId != null) pending.soundId!,
    };

    descriptor.assetKeys.forEach((key, slot) {
      if (slot.kind != AssetKind.sound || !mechanics.containsKey(key)) return;
      final value = mechanics[key];
      if (value is! String ||
          !(declared.contains(value) || pendingSounds.contains(value))) {
        faults.add(ValidationFault(
          '« $value » n\'est déclaré ni dans audio.json ni par un import en '
          'attente',
          field: key,
        ));
      }
    });

    for (final pending in imports) {
      if (!fs.fileExists(pending.sourcePath)) {
        faults.add(ValidationFault(
          'fichier introuvable : ${pending.sourcePath}',
          field: pending.key,
        ));
      }
      if (!pending.slot.extensions.contains(pending.extension)) {
        faults.add(ValidationFault(
          'extension « ${pending.extension} » refusée — attendu : '
          '${pending.slot.extensions.join(', ')}',
          field: pending.key,
        ));
      }
      final soundId = pending.soundId;
      if (soundId == null) continue;
      if (!_idPattern.hasMatch(soundId)) {
        faults.add(ValidationFault(
          'identifiant de son invalide : "$soundId"',
          field: pending.key,
        ));
      }
      if (declared.contains(soundId)) {
        faults.add(ValidationFault(
          'le son « $soundId » existe déjà dans audio.json',
          field: pending.key,
        ));
      }
      if (fs.fileExists('$rootPath/${pending.destination}')) {
        faults.add(ValidationFault(
          '${pending.destination} existe déjà',
          field: pending.key,
        ));
      }
    }

    if (draft.isModification) {
      // Une image obligatoire doit toujours exister ; une optionnelle
      // (`iconPath`), des que le corps la declare.
      for (final key in descriptor.imageKeys.where((key) =>
          descriptor.isComputedImage(key) || mechanics.containsKey(key))) {
        final relative = descriptor.imagePathOf(draft.id, key)!;
        final importing = imports.any((pending) => pending.key == key);
        if (!importing && !fs.fileExists('$rootPath/$relative')) {
          faults.add(ValidationFault('image absente : $relative', field: key));
        }
      }
    }
    return faults;
  }

  /// Le tableau `skills` d'une classe doit etre **exactement** l'ensemble des
  /// cartes de son dossier `cards/`.
  ///
  /// Le controle lit le **disque** et non le registre : les cartes qu'une
  /// recette vient d'ecrire ne sont pas dans le registre charge au demarrage,
  /// et un controle par reference refuserait la sortie meme de l'outil. C'est
  /// aussi l'invariant exact qu'exige `referential_integrity_test`, avance au
  /// moment de l'ecriture plutot qu'a celui des tests.
  List<ValidationFault> _signatureCards(
    EntityDraft draft,
    Map<String, dynamic> mechanics,
  ) {
    if (draft.descriptor.category != EntityCategory.heroClass) {
      return const [];
    }

    final declared = <String>{};
    final raw = mechanics['skills'];
    if (raw != null) {
      if (raw is! List) {
        return const [
          ValidationFault(
            'doit être une liste d\'identifiants de cartes',
            field: 'skills',
          ),
        ];
      }
      for (final element in raw) {
        if (element is! String) {
          return const [
            ValidationFault(
              'chaque élément doit être un identifiant de carte',
              field: 'skills',
            ),
          ];
        }
        declared.add(element);
      }
    }

    final folder = '$rootPath/assets/data/classes/${draft.id}/cards';
    final onDisk = fs.directoryExists(folder)
        ? fs
            .listDirectory(folder)
            .where((name) => name.endsWith('.json'))
            .map((name) => name.substring(0, name.length - '.json'.length))
            .toSet()
        : const <String>{};

    return [
      for (final missing in declared.difference(onDisk))
        ValidationFault(
          'la carte "$missing" est déclarée mais absente de cards/',
          field: 'skills',
        ),
      for (final orphan in onDisk.difference(declared))
        ValidationFault(
          'la carte "$orphan" est dans cards/ mais absente de skills',
          field: 'skills',
        ),
    ];
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
    final known = _registryIdsOf(category);
    final pending = pendingIds[category];
    if (known == null) return pending == null || pending.isEmpty ? null : pending;
    return pending == null ? known : {...known, ...pending};
  }

  Set<String>? _registryIdsOf(EntityCategory category) {
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
