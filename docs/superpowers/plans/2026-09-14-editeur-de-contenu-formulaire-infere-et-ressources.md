# Éditeur de contenu — formulaire inféré et ressources liées — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** remplacer la boîte JSON et les champs texte de l'éditeur de contenu par un formulaire inféré du document, et permettre de lier un son ou une image à une entité.

**Architecture:** trois étapes ordonnées. **A** (tâche 1) retire des gabarits les clés qu'aucune entité n'emploie. **B** (tâches 2-4, 9-10) introduit un document éditable (`EditorDocument`), l'inférence du widget par valeur (`inferFieldKind`), les vocabulaires fermés côté moteur, puis le formulaire récursif et son branchement dans l'écran. **C** (tâches 5-8, 11) déclare les ressources au descripteur, apprend à l'écrivain à copier un fichier et à déclarer un son dans `audio.json` sous rollback, ajoute la validation « ressources », puis le sélecteur de fichier. Le moteur est bâti et testé en Dart pur **avant** tout widget.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11, Riverpod 2.x, `flutter_test`, `flutter_colorpicker` (déjà là), `file_picker` (ajouté en tâche 11).

**Spec:** `docs/superpowers/specs/2026-09-14-editeur-de-contenu-formulaire-infere-et-ressources-design.md` (v3)

## Global Constraints

- **`dart analyze` doit être propre — zéro problème — après chaque tâche.**
- **Ne jamais lancer `dart format`** : le dépôt n'y a jamais été passé. Le code nouveau suit son voisinage.
- **Commits : un par tâche, mais le propriétaire valide la liste des lots avant tout commit.** Le pas « Commit » de chaque tâche prépare le lot ; il ne se fait qu'après validation. Messages en français, conventional commits, sujet sans accent, corps terminé par `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- **Un test doit pouvoir échouer** : écrit d'abord, vu rouge, rendu vert.
- **`lib/` n'importe `dart:io` que dans `content_file_system_io.dart`** — le jeu est publié en build web. Aucun widget ne lit le disque autrement que par `ContentFileSystem`.
- **Les données du jeu (`assets/data/`) ne sont pas modifiées par ce plan**, hormis par les imports explicites d'un usager. Le modèle `CardData` garde `spritePath` (spec D2).
- **`assets/data/patch_notes.json`** appartient à `patch-notes-writer` ; **`.obsidian_vault/`** à `memory-bank-sync`. Ce plan ne touche ni l'un ni l'autre.
- Commentaires de code en français, sans accent, comme le voisinage ; libellés d'écran en français accentué, sans clé ARB (exception bornée à l'éditeur).
- Suite complète : `flutter test`. Un fichier : `flutter test <chemin>`. Un test : `flutter test <chemin> --plain-name "<nom>"`.

---

## Structure des fichiers

**Créés**

| Fichier | Responsabilité |
|:---|:---|
| `lib/services/content_editor/field_path.dart` | Chemins dans un document JSON : motif (`effects[].type`), libellé (`effects[0].type`), valeurs désignées par un motif |
| `lib/services/content_editor/editor_document.dart` | Le document du formulaire : lecture, écriture par chemin, éléments de liste, fautes de conversion, règle d'omission |
| `lib/services/content_editor/field_kind.dart` | Le type de champ d'une valeur, selon le descripteur puis le type JSON |
| `lib/services/content_editor/audio_catalog.dart` | Lire les sons d'`audio.json`, y insérer une ligne sans réécrire le fichier |
| `lib/services/content_editor/pending_import.dart` | Un fichier choisi, en attente d'« Écrire », et sa destination |
| `lib/services/content_editor/asset_picker.dart` | Le seam du sélecteur de fichier, et son implémentation `file_picker` |
| `lib/ui/widgets/content_editor/document_form.dart` | Le formulaire récursif d'un document |
| `lib/ui/widgets/content_editor/asset_field.dart` | Le champ d'un son ou d'une image |

**Modifiés**

| Fichier | Ce qui change |
|:---|:---|
| `lib/services/content_editor/entity_descriptor.dart` | `AssetSlot`, `assetKeys`, `vocabularyKeys`, gabarits, `enumKeys` imbriquées ; `imageName`/`imagePathKey` absorbés |
| `lib/services/content_editor/entity_draft.dart` | `compose()` calcule les images depuis les emplacements |
| `lib/services/content_editor/known_values.dart` | Valeurs par motif imbriqué ; `vocabularyOf` |
| `lib/services/content_editor/entity_validator.dart` | Énumérations par motif, familles « vocabulaire » et « ressources » |
| `lib/services/content_editor/entity_writer.dart` | Imports : copie sous sauvegarde, déclaration des sons, rollback binaire |
| `lib/services/content_editor/content_file_system.dart`, `content_file_system_io.dart` | `readBytes` |
| `lib/services/content_editor/content_editor_providers.dart` | `assetPickerProvider` |
| `lib/ui/widgets/content_editor/entity_form.dart` | Délègue la mécanique ; bascule « JSON brut » |
| `lib/ui/screens/content_editor_screen.dart` | `EditorDocument` + `DocumentForm` ; imports |
| `pubspec.yaml` | `file_picker` |

---

## Task 1 : des gabarits qui disent le schéma

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart`
- Test: `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/content_editor/entity_draft_test.dart`, `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Produces: `enum AssetKind { sound, image }` ; `class AssetSlot` avec `const AssetSlot.sound()`, `const AssetSlot.image(String fileName, {bool isRequired = true})`, champs `kind`, `fileName`, `isRequired`, getter `List<String> extensions` ; `EntityDescriptor.assetKeys : Map<String, AssetSlot>`.

- [ ] **Step 1 : écrire les tests qui échouent**

Dans `entity_descriptor_test.dart`, table *chaque gabarit porte exactement les cles attendues* : retirer `'spritePath'` et `'sfx'` de la carte, `'sfx'` de la relique et de l'ennemi. Remplacer dans le commentaire qui précède la table la ligne sur `classCard` / `spritePath` par :

```dart
  // - `sfx`, ressource son de la carte, de la relique et de l'ennemi : le
  //   formulaire le rend en liste de sons (`assetKeys`), jamais en texte ;
  // - `spritePath` d'une carte : lu par `CardData`, reserve aux illustrations
  //   a venir, sans lecteur a l'ecran. Exclusion nommee, test ci-dessous ;
  // - `classCard` / `spritePath` d'une classe et d'un ennemi, calcules par
  //   `EntityWriter` a partir de l'identifiant ;
```

Ajouter à la fin de `main()` :

```dart
  test('sfx est une ressource son des trois categories qui le lisent', () {
    for (final category in const [
      EntityCategory.card,
      EntityCategory.relic,
      EntityCategory.enemy,
    ]) {
      final descriptor = kEntityDescriptors[category]!;
      expect(descriptor.assetKeys['sfx']?.kind, AssetKind.sound,
          reason: descriptor.label);
      expect(descriptor.decodeTemplate().containsKey('sfx'), isFalse,
          reason: descriptor.label);
    }
  });

  // Exclusion nommee (spec §3.4) : le modele lit la cle, le gabarit ne
  // l'ecrit pas. Si `CardData` cesse de la lire, retirer ce test ; si un ecran
  // affiche un jour l'illustration, la cle revient au gabarit avec son champ.
  test('spritePath de carte : lu par le modele, absent du gabarit', () {
    final card = kEntityDescriptors[EntityCategory.card]!;
    expect(card.decodeTemplate().containsKey('spritePath'), isFalse);
    expect(card.assetKeys.containsKey('spritePath'), isFalse);

    final read = CardData.fromJson({
      'id': 'x',
      'cost': 1,
      'type': 'attack',
      'spritePath': 'assets/illustration.png',
    });
    expect(read.spritePath, 'assets/illustration.png');
  });
```

Dans `entity_draft_test.dart`, test *le chemin d image n existe que pour les categories en dossier*, remplacer le bloc `expect(composed['spritePath'], descriptor.decodeTemplate()['spritePath'], …)` et son commentaire par :

```dart
        // Aucune categorie a plat ne porte de `spritePath` au gabarit — la
        // carte l'a perdu (spec §3.1) — et `compose()` n'en fabrique pas.
        expect(composed.containsKey('spritePath'), isFalse,
            reason: descriptor.label);
```

Dans `test/widget/content_editor_screen_test.dart`, après le test *creer une relique avec le seul identifiant ecrit un fichier valide* :

```dart
  testWidgets('une creation sans son ni illustration n ecrit ni sfx ni spritePath',
      (tester) async {
    // `audio_catalogue_test` refuse tout `sfx` non declare : un `"sfx": ""`
    // ecrit par le gabarit faisait rougir la suite a chaque creation.
    Directory('$root/assets/data/cards').createSync(recursive: true);

    for (final (type, id, path) in const [
      ('Relique', 'talisman', 'assets/data/relics/talisman.json'),
      ('Carte', 'frappe', 'assets/data/cards/frappe.json'),
      ('Ennemi', 'troll', 'assets/data/enemies/troll/enemy.json'),
    ]) {
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text(type));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), id);
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      final written = jsonDecode(File('$root/$path').readAsStringSync())
          as Map<String, dynamic>;
      expect(written.containsKey('sfx'), isFalse, reason: type);
      if (type == 'Carte') {
        expect(written.containsKey('spritePath'), isFalse);
      }
    }
  });
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/entity_descriptor_test.dart`
Expected : échec de compilation — `AssetKind` et `assetKeys` n'existent pas.

Run : `flutter test test/widget/content_editor_screen_test.dart --plain-name "ni sfx ni spritePath"`
Expected : FAIL, `written.containsKey('sfx')` vaut `true`.

- [ ] **Step 3 : implémenter**

Dans `entity_descriptor.dart`, après l'enum `EntityCategory` :

```dart
/// Ce qu'est une ressource : un son declare dans `audio.json`, ou une image
/// dont le nom est impose par l'identifiant.
enum AssetKind { sound, image }

/// Un emplacement de ressource d'une categorie.
@immutable
class AssetSlot {
  const AssetSlot.sound()
      : kind = AssetKind.sound,
        fileName = null,
        isRequired = false;

  const AssetSlot.image(String this.fileName, {this.isRequired = true})
      : kind = AssetKind.image;

  final AssetKind kind;

  /// Le nom du fichier image, jeton `{id}` admis. `null` pour un son.
  final String? fileName;

  /// Vrai si l'entite ne se charge pas sans : l'ecrivain calcule alors la cle
  /// a chaque ecriture. Un son n'est jamais obligatoire.
  final bool isRequired;

  /// Les extensions qu'un import accepte.
  List<String> get extensions => kind == AssetKind.sound
      ? const ['wav', 'mp3', 'ogg']
      : const ['png'];
}
```

Au constructeur d'`EntityDescriptor`, ajouter `this.assetKeys = const {},` après `this.hexColorKeys = const {},`, et le champ après `hexColorKeys` :

```dart
  /// Cle -> emplacement de ressource. Le formulaire rend ces cles en choix de
  /// son ou en import d'image, jamais en texte (spec §5).
  final Map<String, AssetSlot> assetKeys;
```

Carte : ajouter `assetKeys: const {'sfx': AssetSlot.sound()},`, remplacer le commentaire du gabarit et le gabarit :

```dart
    // Le gabarit ne porte que ce qu'une carte emploie (spec §3.1) : ni
    // `spritePath`, qu'aucune carte ne porte et qu'aucun ecran n'affiche, ni
    // `sfx`, choisi dans le champ de ressource et absent tant qu'aucun son ne
    // l'est.
    template: '''
{
  "cost": 1,
  "type": "attack",
  "rarity": "common",
  "target": "singleEnemy",
  "animation": "melee",
  "isExhaust": false,
  "effects": [
    { "type": "damage", "value": 6 }
  ],
  "baseMaxForgeUpgrades": 1
}''',
```

Relique : ajouter `assetKeys: const {'sfx': AssetSlot.sound()},` et retirer la ligne `"sfx": ""` du gabarit (la ligne `"emoji": "🪙"` perd sa virgule finale). Ennemi : idem — `assetKeys: const {'sfx': AssetSlot.sound()},`, `"sfx": ""` retiré, `]` de `intents` sans virgule finale.

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor test/widget/content_editor_screen_test.dart`
Expected : PASS. Run : `dart analyze` → `No issues found!`

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/entity_descriptor.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_draft_test.dart test/widget/content_editor_screen_test.dart
git commit -m "fix(editeur): ne plus ecrire sfx ni spritePath vides a la creation"
```

---

## Task 2 : le document éditable

**Files:**
- Create: `lib/services/content_editor/field_path.dart`, `lib/services/content_editor/editor_document.dart`
- Test: `test/unit/content_editor/field_path_test.dart`, `test/unit/content_editor/editor_document_test.dart`

**Interfaces:**
- Consumes: `ValidationFault` (`entity_validator.dart`).
- Produces : `typedef FieldPath = List<Object>` ; `String patternOf(FieldPath)` ; `String labelOf(FieldPath)` ; `List<(FieldPath, Object?)> valuesMatching(Map<String, dynamic> root, String pattern)` ; `class EditorDocument` : `EditorDocument(Map<String, dynamic> seed, {Set<String> requiredKeys, Map<String, dynamic> template})`, `Map<String, dynamic> get root`, `Object? valueAt(FieldPath)`, `void setAt(FieldPath, Object?)`, `void removeAt(FieldPath)`, `Map<String, dynamic>? modelElementFor(FieldPath)`, `bool addElement(FieldPath)`, `void removeElement(FieldPath, int)`, `void reportConversion(FieldPath, String)`, `void clearConversion(FieldPath)`, `List<ValidationFault> get conversionFaults`, `String toMechanics()`.

- [ ] **Step 1 : écrire les tests qui échouent**

`test/unit/content_editor/field_path_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/field_path.dart';

void main() {
  test('le motif efface les indices, le libelle les garde', () {
    const path = <Object>['choices', 1, 'actions', 0, 'type'];
    expect(patternOf(path), 'choices[].actions[].type');
    expect(labelOf(path), 'choices[1].actions[0].type');
    expect(patternOf(const ['rarity']), 'rarity');
  });

  group('valuesMatching', () {
    final document = <String, dynamic>{
      'rarity': 'common',
      'effects': [
        {'type': 'damage', 'value': 6},
        {'type': 'apply_status', 'statusId': 'burn', 'value': 2},
      ],
      'choices': [
        {
          'actions': [
            {'type': 'heal'},
          ],
        },
      ],
    };

    // Les chemins sont des listes : `==` n'y compare que l'identite, on
    // compare donc leurs libelles.
    test('une cle de premier niveau', () {
      final found = valuesMatching(document, 'rarity');
      expect(found.map((e) => labelOf(e.$1)), ['rarity']);
      expect(found.map((e) => e.$2), ['common']);
    });

    test('chaque element d une liste, avec son indice', () {
      final found = valuesMatching(document, 'effects[].type');
      expect(found.map((e) => labelOf(e.$1)),
          ['effects[0].type', 'effects[1].type']);
      expect(found.map((e) => e.$2), ['damage', 'apply_status']);
    });

    test('une cle absente d un element ne rend rien pour lui', () {
      expect(valuesMatching(document, 'effects[].statusId').map((e) => e.$2),
          ['burn']);
    });

    test('deux niveaux de listes', () {
      expect(
        valuesMatching(document, 'choices[].actions[].type')
            .map((e) => labelOf(e.$1)),
        ['choices[0].actions[0].type'],
      );
    });

    test('un motif sans correspondance rend une liste vide', () {
      expect(valuesMatching(document, 'intents[].type'), isEmpty);
    });
  });
}
```

`test/unit/content_editor/editor_document_test.dart` :

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/editor_document.dart';

void main() {
  Map<String, dynamic> card() => {
        'cost': 1,
        'animation': 'melee',
        'effects': [
          {'type': 'damage', 'value': 6},
        ],
      };

  test('le document copie sa graine', () {
    final seed = card();
    final document = EditorDocument(seed);
    document.setAt(const ['cost'], 3);
    expect(seed['cost'], 1);
  });

  test('lecture et ecriture par chemin imbrique', () {
    final document = EditorDocument(card());
    document.setAt(const ['effects', 0, 'value'], 9);
    expect(document.valueAt(const ['effects', 0, 'value']), 9);
    expect(document.valueAt(const ['effects', 5, 'value']), isNull);
  });

  test('ecrire une cle absente l ajoute, removeAt la retire', () {
    final document = EditorDocument(card());
    document.setAt(const ['sfx'], 'clang');
    expect(document.root['sfx'], 'clang');
    document.removeAt(const ['sfx']);
    expect(document.root.containsKey('sfx'), isFalse);
  });

  test('ajouter un element clone celui du gabarit, en profondeur', () {
    final template = card();
    final document = EditorDocument({'effects': <dynamic>[]}, template: template);

    expect(document.addElement(const ['effects']), isTrue);
    expect(document.root['effects'], [
      {'type': 'damage', 'value': 6},
    ]);

    document.setAt(const ['effects', 0, 'value'], 99);
    expect((template['effects'] as List).first['value'], 6);
  });

  test('sans gabarit, l element modele est le premier du document', () {
    final document = EditorDocument(card());
    expect(document.addElement(const ['effects']), isTrue);
    expect(document.root['effects'], hasLength(2));
  });

  test('sans modele, rien n est ajoute', () {
    final document = EditorDocument({'effects': <dynamic>[]});
    expect(document.addElement(const ['effects']), isFalse);
  });

  test('retirer un element', () {
    final document = EditorDocument(card());
    document.removeElement(const ['effects'], 0);
    expect(document.root['effects'], isEmpty);
  });

  test('une saisie non convertible devient une faute, effacee par setAt', () {
    final document = EditorDocument(card());
    document.reportConversion(const ['effects', 0, 'value'], 'pas un entier');
    expect(document.conversionFaults.single.field, 'effects[0].value');

    document.setAt(const ['effects', 0, 'value'], 7);
    expect(document.conversionFaults, isEmpty);
  });

  test('toMechanics omet une chaine optionnelle vide, a tout niveau', () {
    final document = EditorDocument(
      {
        'cost': 1,
        'type': '',
        'sfx': '',
        'effects': [
          {'type': 'apply_status', 'statusId': '', 'value': 2},
        ],
      },
      requiredKeys: const {'cost', 'type'},
    );

    final mechanics = jsonDecode(document.toMechanics()) as Map<String, dynamic>;
    expect(mechanics.containsKey('sfx'), isFalse);
    expect(mechanics['type'], '', reason: 'une cle requise n est jamais omise');
    expect((mechanics['effects'] as List).first.containsKey('statusId'), isFalse);
    expect(document.root['sfx'], '', reason: 'le document lui-meme est intact');
  });
}
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/field_path_test.dart test/unit/content_editor/editor_document_test.dart`
Expected : échec de compilation — fichiers absents.

- [ ] **Step 3 : implémenter**

`lib/services/content_editor/field_path.dart` :

```dart
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
```

`lib/services/content_editor/editor_document.dart` :

```dart
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
```

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor/field_path_test.dart test/unit/content_editor/editor_document_test.dart` → PASS. `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/field_path.dart lib/services/content_editor/editor_document.dart test/unit/content_editor/field_path_test.dart test/unit/content_editor/editor_document_test.dart
git commit -m "feat(editeur): un document editable par chemin, source du formulaire"
```

---

## Task 3 : vocabulaires fermés et énumérations imbriquées

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart`, `lib/services/content_editor/known_values.dart`, `lib/services/content_editor/entity_validator.dart`
- Test: `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/content_editor/known_values_test.dart`, `test/unit/content_editor/entity_validator_test.dart`

**Interfaces:**
- Consumes: `valuesMatching`, `labelOf` (tâche 2).
- Produces : `EntityDescriptor.vocabularyKeys : Set<String>` ; `enumKeys` accepte un motif (`intents[].type`) ; `knownValues(fs, root, descriptor)` range les valeurs imbriquées sous leur motif ; `Map<String, List<String>> vocabularyOf(EntityDescriptor, Map<String, List<String>> known)`.

- [ ] **Step 1 : écrire les tests qui échouent**

`entity_descriptor_test.dart`, ajouter l'import `package:roguelike_card_game/models/enemy_intent.dart` et :

```dart
  test('les vocabulaires fermes cote moteur sont declares', () {
    expect(kEntityDescriptors[EntityCategory.card]!.vocabularyKeys,
        {'animation', 'effects[].type', 'effects[].statusId'});
    expect(kEntityDescriptors[EntityCategory.relic]!.vocabularyKeys,
        {'effectType'});
    expect(kEntityDescriptors[EntityCategory.passive]!.vocabularyKeys,
        {'effectType'});
    expect(kEntityDescriptors[EntityCategory.event]!.vocabularyKeys,
        {'choices[].actions[].type'});
  });

  test('le type d intention d un ennemi est une enumeration imbriquee', () {
    // `EnemyIntent.fromJson` retombe en silence sur `attack` : sans cette
    // declaration, une faute de frappe devient une attaque.
    expect(
      kEntityDescriptors[EntityCategory.enemy]!.enumKeys['intents[].type'],
      IntentType.values.map((e) => e.name).toList(),
    );
  });

  test('la couleur d une amelioration de forge est une couleur', () {
    expect(kEntityDescriptors[EntityCategory.forgeUpgrade]!.hexColorKeys,
        {'color'});
  });
```

`known_values_test.dart` :

```dart
  test('les valeurs imbriquees sont rangees sous leur motif', () {
    write('assets/data/cards/a.json',
        '{"effects": [{"type": "damage", "value": 6}, '
        '{"type": "apply_status", "statusId": "burn", "value": 2}]}');
    write('assets/data/events/e.json',
        '{"choices": [{"text_fr": "Oui", "text_en": "Yes", '
        '"actions": [{"type": "heal", "value": 5}]}]}');

    final cards =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.card]!);
    expect(cards['effects[].type'], ['apply_status', 'damage']);
    expect(cards['effects[].statusId'], ['burn']);

    final events =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.event]!);
    expect(events['choices[].actions[].type'], ['heal']);
    expect(events.keys.where((key) => key.contains('text_')), isEmpty,
        reason: 'la prose imbriquee n est pas un vocabulaire');
  });

  test('vocabularyOf ajoute les valeurs du gabarit a celles du disque', () {
    final relic = kEntityDescriptors[EntityCategory.relic]!;
    expect(vocabularyOf(relic, const {'effectType': ['heal']})['effectType'],
        ['gain_armor', 'heal']);
    expect(vocabularyOf(relic, const {})['effectType'], ['gain_armor']);
  });
```

`entity_validator_test.dart`, nouveau groupe à la fin de `main()` :

```dart
  group('vocabulaires et enumerations imbriquees', () {
    const prose = {
      'name_fr': 'x',
      'name_en': 'x',
      'description_fr': 'x',
      'description_en': 'x',
    };

    EntityDraft cardDraft(String mechanics) => EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.card]!,
          id: 'coup',
          bilingual: prose,
          mechanics: mechanics,
        );

    test('une valeur employee par un fichier passe', () {
      File('$root/assets/data/relics/amulette.json')
          .writeAsStringSync('{"effectType": "heal"}');
      final faults = validatorWith().validate(fixtureRelicDraft(
        mechanics: '{"trigger": "startOfCombat", "effectType": "heal", '
            '"value": 5, "rarity": "common"}',
      ));
      expect(faults, isEmpty);
    });

    test('une valeur inconnue du disque et du gabarit est refusee', () {
      final faults = validatorWith().validate(fixtureRelicDraft(
        mechanics: '{"trigger": "startOfCombat", "effectType": "heall", '
            '"value": 5, "rarity": "common"}',
      ));
      expect(faults.single.field, 'effectType');
    });

    test('la valeur du gabarit passe dans une arborescence vide', () {
      expect(validatorWith().validate(fixtureRelicDraft()), isEmpty);
    });

    test('un type d effet de carte inconnu est refuse, avec son chemin', () {
      final faults = validatorWith().validate(cardDraft(
        '{"cost": 1, "type": "attack", '
        '"effects": [{"type": "skill", "value": 3}]}',
      ));
      expect(faults.single.field, 'effects[0].type');
    });

    test('un type d intention inconnu est refuse', () {
      final enemy = kEntityDescriptors[EntityCategory.enemy]!;
      final faults = validatorWith().validate(EntityDraft(
        descriptor: enemy,
        id: 'troll',
        bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
        mechanics: '{"maxHp": 30, "baseDamage": 5, '
            '"intents": [{"type": "fly", "value": 5}]}',
      ));
      expect(faults.single.field, 'intents[0].type');
    });

    test('une couleur de forge malformee est refusee', () {
      final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
      final faults = validatorWith().validate(EntityDraft(
        descriptor: forge,
        id: 'eclat',
        bilingual: prose,
        mechanics: '{"pools": ["common"], "color": "orange"}',
      ));
      expect(faults.single.field, 'color');
    });
  });
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/known_values_test.dart test/unit/content_editor/entity_validator_test.dart`
Expected : échec de compilation (`vocabularyKeys`, `vocabularyOf`).

- [ ] **Step 3 : implémenter**

`entity_descriptor.dart` : importer `'../../models/enemy_intent.dart'`. Constructeur : `this.vocabularyKeys = const {},` après `this.assetKeys`. Champ :

```dart
  /// Les motifs dont la valeur est une chaine libre dans le modele mais
  /// fermee dans le moteur : un type d'effet inconnu du resolveur ne fait
  /// rien. Admis : les valeurs deja employees sur le disque, et celles du
  /// gabarit (`vocabularyOf`, spec §4.5).
  final Set<String> vocabularyKeys;
```

Compléter le commentaire d'`enumKeys` : `/// Motif -> valeurs admises, lues sur l'enumeration Dart reelle. Un motif imbrique (`intents[].type`) vise chaque element.`

Déclarations : carte `vocabularyKeys: const {'animation', 'effects[].type', 'effects[].statusId'},` ; relique et passif `vocabularyKeys: const {'effectType'},` ; événement `vocabularyKeys: const {'choices[].actions[].type'},` ; forge `hexColorKeys: const {'color'},` ; ennemi `enumKeys: {'intents[].type': _names(IntentType.values)},`.

`known_values.dart` — remplacer la fonction entière :

```dart
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
```

`entity_validator.dart` : importer `'field_path.dart'` et `'known_values.dart'`. Dans `validate`, insérer `() => _vocabulary(draft, mechanics),` juste après `() => _enums(draft, mechanics),`. Remplacer la boucle `enumKeys` de `_enums` :

```dart
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
```

Ajouter après `_enums` :

```dart
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
```

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor test/widget/content_editor_screen_test.dart` → PASS (les sandbox des tests existants n'emploient que des valeurs du gabarit). `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/entity_descriptor.dart lib/services/content_editor/known_values.dart lib/services/content_editor/entity_validator.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/known_values_test.dart test/unit/content_editor/entity_validator_test.dart
git commit -m "feat(editeur): refuser les valeurs que le moteur ne connait pas"
```

---

## Task 4 : l'inférence du type de champ

**Files:**
- Create: `lib/services/content_editor/field_kind.dart`
- Test: `test/unit/content_editor/field_kind_test.dart`

**Interfaces:**
- Consumes: `patternOf`, `FieldPath` (tâche 2) ; `assetKeys` (tâche 1), `vocabularyKeys` (tâche 3).
- Produces : `enum FieldKind { asset, reference, color, enumChoice, enumMulti, vocabulary, boolean, integer, decimal, text, objectList, stringList, object, rawJson }` ; `FieldKind inferFieldKind({required FieldPath path, required Object? value, required EntityDescriptor descriptor, bool hasModelElement = false})`.

- [ ] **Step 1 : écrire le test qui échoue**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/field_kind.dart';
import 'package:roguelike_card_game/services/content_editor/field_path.dart';

void main() {
  final card = kEntityDescriptors[EntityCategory.card]!;
  final relic = kEntityDescriptors[EntityCategory.relic]!;
  final hero = kEntityDescriptors[EntityCategory.heroClass]!;
  final enemy = kEntityDescriptors[EntityCategory.enemy]!;
  final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;

  FieldKind kindOf(
    EntityDescriptor descriptor,
    FieldPath path,
    Object? value, {
    bool model = false,
  }) =>
      inferFieldKind(
        path: path,
        value: value,
        descriptor: descriptor,
        hasModelElement: model,
      );

  test('les metadonnees du descripteur passent avant le type JSON', () {
    expect(kindOf(relic, const ['sfx'], 'clang'), FieldKind.asset);
    expect(kindOf(hero, const ['passiveTrait'], null), FieldKind.reference);
    expect(kindOf(hero, const ['themeColor'], '#FF00FF'), FieldKind.color);
    // `rarity` est une chaine, mais une enumeration d'abord.
    expect(kindOf(card, const ['rarity'], 'common'), FieldKind.enumChoice);
    expect(kindOf(enemy, const ['intents', 0, 'type'], 'attack'),
        FieldKind.enumChoice);
    expect(kindOf(forge, const ['eligibleCardTypes'], ['attack']),
        FieldKind.enumMulti);
    expect(kindOf(card, const ['effects', 0, 'type'], 'damage'),
        FieldKind.vocabulary);
  });

  test('le type JSON decide ensuite', () {
    expect(kindOf(card, const ['isExhaust'], false), FieldKind.boolean);
    expect(kindOf(card, const ['cost'], 1), FieldKind.integer);
    expect(kindOf(forge, const ['valueMultiplier'], 1.5), FieldKind.decimal);
    expect(kindOf(relic, const ['emoji'], '🪙'), FieldKind.text);
    expect(kindOf(card, const ['effects'], [
      {'type': 'damage'},
    ]), FieldKind.objectList);
    expect(kindOf(forge, const ['pools'], ['common']), FieldKind.stringList);
    expect(kindOf(card, const ['meta'], {'a': 1}), FieldKind.object);
  });

  test('une liste vide depend de son element modele', () {
    expect(kindOf(card, const ['effects'], <dynamic>[], model: true),
        FieldKind.objectList);
    expect(kindOf(card, const ['effects'], <dynamic>[]), FieldKind.rawJson);
  });

  test('ce qui ne se classe pas devient un petit champ JSON', () {
    expect(kindOf(card, const ['inconnu'], null), FieldKind.rawJson);
    expect(kindOf(card, const ['melange'], [1, 'a']), FieldKind.rawJson);
  });
}
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/field_kind_test.dart` → échec de compilation.

- [ ] **Step 3 : implémenter**

```dart
import 'entity_descriptor.dart';
import 'field_path.dart';

/// Le widget qu'une valeur recoit (spec §4.3).
enum FieldKind {
  asset,
  reference,
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
```

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor/field_kind_test.dart` → PASS. `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/field_kind.dart test/unit/content_editor/field_kind_test.dart
git commit -m "feat(editeur): inferer le type de champ d une valeur"
```

---

## Task 5 : les images deviennent des emplacements de ressource

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart`, `lib/services/content_editor/entity_draft.dart`, `lib/services/content_editor/entity_writer.dart:128-172`, `lib/ui/screens/content_editor_screen.dart:362-371`
- Test: `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/content_editor/entity_draft_test.dart`

**Interfaces:**
- Consumes: `AssetSlot.image` (tâche 1).
- Produces : `String? EntityDescriptor.imagePathOf(String id, String key)` ; `Iterable<String> get imageKeys` ; `bool isComputedImage(String key)`. **Supprimés** : `imageName`, `imagePathKey`, `imagePathOf(String id)`.

- [ ] **Step 1 : réécrire les tests (rouges)**

`entity_descriptor_test.dart` — remplacer les quatre tests *seules la classe et l ennemi sont des dossiers a image*, *le chemin d image d une classe porte son identifiant*, *le chemin d image d un ennemi reste constant* et *la classe ecrit son image sous classCard* par :

```dart
  test('seules la classe et l ennemi portent des emplacements image', () {
    final withImage = kEntityDescriptors.values
        .where((d) => d.imageKeys.isNotEmpty)
        .map((d) => d.category)
        .toSet();
    expect(withImage, {EntityCategory.heroClass, EntityCategory.enemy});
    for (final category in withImage) {
      expect(kEntityDescriptors[category]!.folderFile, isNotNull);
    }
  });

  test('la classe : classCard obligatoire, iconPath optionnel', () {
    final hero = kEntityDescriptors[EntityCategory.heroClass]!;
    expect(hero.imagePathOf('gambler', 'classCard'),
        'assets/data/classes/gambler/gambler.png');
    expect(hero.imagePathOf('gambler', 'iconPath'),
        'assets/data/classes/gambler/icon.png');
    expect(hero.isComputedImage('classCard'), isTrue);
    expect(hero.isComputedImage('iconPath'), isFalse);
  });

  test('le sprite d un ennemi garde un nom constant', () {
    final enemy = kEntityDescriptors[EntityCategory.enemy]!;
    expect(enemy.imagePathOf('gobelin', 'spritePath'),
        'assets/data/enemies/gobelin/sprite.png');
    expect(enemy.imagePathOf('gobelin', 'sfx'), isNull,
        reason: 'un son n est pas une image');
  });
```

`entity_draft_test.dart`, test *le chemin d image n existe que pour les categories en dossier* — remplacer `final key = descriptor.imagePathKey;` par :

```dart
      final required = descriptor.imageKeys.where(descriptor.isComputedImage);
      final key = required.isEmpty ? null : required.first;
```

et `descriptor.imagePathOf('entite_de_test')` par `descriptor.imagePathOf('entite_de_test', key)` dans la branche `else` ; dans la branche `null`, remplacer l'assertion `expect(descriptor.imagePathOf('entite_de_test'), isNull, …)` par `expect(descriptor.imageKeys, isEmpty, reason: descriptor.label);`.

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/entity_descriptor_test.dart` → échec de compilation (`imageKeys`, `isComputedImage`).

- [ ] **Step 3 : implémenter**

`entity_descriptor.dart` : retirer `this.imageName`, `this.imagePathKey`, leurs champs et l'ancien `imagePathOf`. Ajouter :

```dart
  /// Les cles de ressource qui sont des images.
  Iterable<String> get imageKeys => assetKeys.entries
      .where((entry) => entry.value.kind == AssetKind.image)
      .map((entry) => entry.key);

  /// Vrai pour une image **obligatoire** : sa cle n'est jamais saisie,
  /// l'ecrivain la calcule a chaque ecriture.
  bool isComputedImage(String key) {
    final slot = assetKeys[key];
    return slot != null && slot.kind == AssetKind.image && slot.isRequired;
  }

  /// Le chemin de l'image que [key] designe pour l'entite [id]. Le nom peut
  /// porter le jeton `{id}` : la carte d'une classe est nommee d'apres elle,
  /// le sprite d'un ennemi porte un nom constant. `null` hors image.
  String? imagePathOf(String id, String key) {
    final slot = assetKeys[key];
    final name = slot?.fileName;
    if (slot == null || slot.kind != AssetKind.image || name == null) {
      return null;
    }
    return 'assets/data/$directory/$id/${name.replaceAll('{id}', id)}';
  }
```

Classe : remplacer `imageName`/`imagePathKey` par

```dart
    assetKeys: const {
      'classCard': AssetSlot.image('{id}.png'),
      // Optionnelle : les trois classes livrees n'ont pas d'icone dessinee, et
      // `ClassIdentity.imageOf` retombe alors sur `classCard`.
      'iconPath': AssetSlot.image('icon.png', isRequired: false),
    },
```

Ennemi : `assetKeys: const {'spritePath': AssetSlot.image('sprite.png'), 'sfx': AssetSlot.sound()},` (remplace l'`assetKeys` de la tâche 1).

`entity_draft.dart`, `compose()` : retirer `final imagePath = descriptor.imagePathOf(id);`, et remplacer la dernière entrée `?descriptor.imagePathKey: imagePath,` et son commentaire par :

```dart
      // Le chemin d'une image est **derive de l'identifiant**, donc calcule et
      // jamais saisi. Obligatoire, il est toujours ecrit ; optionnel
      // (`iconPath`), il ne l'est que si le corps le porte. Place apres la
      // mecanique pour que l'outil ait le dernier mot.
      for (final key in descriptor.imageKeys)
        if (descriptor.isComputedImage(key) || decoded.containsKey(key))
          key: descriptor.imagePathOf(id, key),
```

`entity_writer.dart`, `_placeImage` :

```dart
  void _placeImage(EntityDraft draft) {
    final descriptor = draft.descriptor;
    for (final key in descriptor.imageKeys.where(descriptor.isComputedImage)) {
      final absolute = '$rootPath/${descriptor.imagePathOf(draft.id, key)}';
      if (fs.fileExists(absolute)) continue;

      final source = '$rootPath/$kPlaceholderImage';
      if (!fs.fileExists(source)) return; // rien a copier : on n'invente pas
      fs.copyFile(source, absolute);
    }
  }
```

`_placeClassIcon` : remplacer `'$rootPath/assets/data/classes/${draft.id}/icon.png'` par `'$rootPath/${draft.descriptor.imagePathOf(draft.id, 'iconPath')}'`.

`content_editor_screen.dart`, `_load` : remplacer `entry.key != _descriptor.imagePathKey &&` par `!_descriptor.isComputedImage(entry.key) &&`, et dans le commentaire qui précède « le chemin de l'image, que l'ecrivain calcule » par « une image obligatoire, que l'ecrivain calcule ».

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor test/widget/content_editor_screen_test.dart` → PASS. `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/entity_descriptor.dart lib/services/content_editor/entity_draft.dart lib/services/content_editor/entity_writer.dart lib/ui/screens/content_editor_screen.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_draft_test.dart
git commit -m "refactor(editeur): declarer les images comme emplacements de ressource"
```

---

## Task 6 : le catalogue audio

**Files:**
- Create: `lib/services/content_editor/audio_catalog.dart`
- Test: `test/unit/content_editor/audio_catalog_test.dart`

**Interfaces:**
- Produces : `const String kAudioCatalogPath = 'assets/data/audio.json'` ; `List<String> soundIds(ContentFileSystem fs, String rootPath)` ; `String insertSound(String source, {required String id, required String file})` — lève `StateError` si `sounds` manque, si `id` est déjà déclaré, ou si le résultat décodé n'est pas l'original plus l'entrée.

- [ ] **Step 1 : écrire le test qui échoue**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/audio_catalog.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';

void main() {
  group('soundIds', () {
    late Directory sandbox;
    late String root;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('audio_catalog_');
      root = IoContentFileSystem.toSlashes(sandbox.path);
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    test('lit les cles de sounds, triees', () {
      File('$root/$kAudioCatalogPath')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{"sounds": {"zap": {}, "clang": {}}}');
      expect(soundIds(const IoContentFileSystem(), root), ['clang', 'zap']);
    });

    test('rend une liste vide sans audio.json', () {
      expect(soundIds(const IoContentFileSystem(), root), isEmpty);
    });
  });

  group('insertSound', () {
    test('ajoute une ligne en fin de bloc, sans toucher aux autres', () {
      final source = File('assets/data/audio.json').readAsStringSync();
      final result =
          insertSound(source, id: 'clang_test', file: 'sfx/clang_test.wav');

      final before = source.split('\n');
      final after = result.split('\n');
      expect(after, hasLength(before.length + 1));

      String bare(String line) =>
          line.trimRight().replaceAll(RegExp(r',$'), '');
      final kept = after.map(bare).toSet();
      for (final line in before) {
        expect(kept, contains(bare(line)));
      }

      final sounds = (jsonDecode(result) as Map<String, dynamic>)['sounds']
          as Map<String, dynamic>;
      expect(sounds['clang_test'], {'file': 'sfx/clang_test.wav'});
    });

    test('suit les fins de ligne CRLF', () {
      const source = '{\r\n  "sounds": {\r\n    "a": { "file": "sfx/a.wav" }\r\n'
          '  },\r\n  "music": {}\r\n}\r\n';
      expect(
        insertSound(source, id: 'b', file: 'sfx/b.wav'),
        '{\r\n  "sounds": {\r\n    "a": { "file": "sfx/a.wav" },\r\n'
        '    "b": { "file": "sfx/b.wav" }\r\n  },\r\n  "music": {}\r\n}\r\n',
      );
    });

    test('remplit un bloc vide', () {
      const source = '{\n  "sounds": {},\n  "music": {}\n}\n';
      expect(
        insertSound(source, id: 'b', file: 'sfx/b.wav'),
        '{\n  "sounds": {\n    "b": { "file": "sfx/b.wav" }\n  },\n'
        '  "music": {}\n}\n',
      );
    });

    test('refuse un identifiant deja declare', () {
      const source = '{"sounds": {"a": {"file": "sfx/a.wav"}}}';
      expect(() => insertSound(source, id: 'a', file: 'sfx/a.wav'),
          throwsStateError);
    });

    test('refuse un document sans bloc sounds', () {
      expect(() => insertSound('{"music": {}}', id: 'a', file: 'sfx/a.wav'),
          throwsStateError);
    });
  });
}
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/audio_catalog_test.dart` → échec de compilation.

- [ ] **Step 3 : implémenter**

```dart
import 'dart:convert';

import 'content_file_system.dart';

/// Le catalogue des sons, relatif a la racine du projet.
const String kAudioCatalogPath = 'assets/data/audio.json';

/// Les identifiants declares sous `sounds`, tries. Vide si le fichier manque
/// ou ne decode pas : un champ de son sans catalogue ne propose rien.
List<String> soundIds(ContentFileSystem fs, String rootPath) {
  final absolute = '$rootPath/$kAudioCatalogPath';
  if (!fs.fileExists(absolute)) return const [];
  try {
    final decoded = jsonDecode(fs.readFile(absolute));
    final sounds = decoded is Map<String, dynamic> ? decoded['sounds'] : null;
    if (sounds is! Map<String, dynamic>) return const [];
    return sounds.keys.toList()..sort();
  } on FormatException {
    return const [];
  }
}

/// [source] augmente d'une ligne `"<id>": { "file": "<file>" }` en fin du
/// bloc `sounds`.
///
/// **Insertion textuelle, pas reencodage** : `audio.json` est aligne a la
/// main, et le reencoder reecrirait ses cent lignes. Le resultat est controle
/// en le decodant — il doit valoir l'original plus l'entrée, sinon rien n'est
/// rendu.
String insertSound(String source, {required String id, required String file}) {
  final original = jsonDecode(source);
  final sounds = original is Map<String, dynamic> ? original['sounds'] : null;
  if (original is! Map<String, dynamic> || sounds is! Map<String, dynamic>) {
    throw StateError('audio.json ne porte pas de bloc "sounds"');
  }
  if (sounds.containsKey(id)) {
    throw StateError('le son "$id" est déjà déclaré');
  }

  final open = source.indexOf('{', source.indexOf('"sounds"'));
  final close = _matchingBrace(source, open);
  final newline = source.contains('\r\n') ? '\r\n' : '\n';
  final entry = '"$id": { "file": "$file" }';

  final String result;
  if (source.substring(open + 1, close).trim().isEmpty) {
    final indent = _indentOfLine(source, close);
    result = '${source.substring(0, open + 1)}$newline$indent  $entry'
        '$newline$indent${source.substring(close)}';
  } else {
    var last = close - 1;
    while (source[last].trim().isEmpty) {
      last--;
    }
    final indent = _indentOfLine(source, last);
    result = '${source.substring(0, last + 1)},$newline$indent$entry'
        '${source.substring(last + 1)}';
  }

  final expected = Map<String, dynamic>.from(original)
    ..['sounds'] = {
      ...sounds,
      id: {'file': file},
    };
  if (jsonEncode(jsonDecode(result)) != jsonEncode(expected)) {
    throw StateError('insertion dans audio.json non conforme : rien n\'est écrit');
  }
  return result;
}

int _matchingBrace(String source, int open) {
  var depth = 0;
  var inString = false;
  for (var i = open; i < source.length; i++) {
    final char = source[i];
    if (inString) {
      if (char == '\\') {
        i++;
      } else if (char == '"') {
        inString = false;
      }
      continue;
    }
    if (char == '"') {
      inString = true;
    } else if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  throw StateError('bloc "sounds" non refermé');
}

String _indentOfLine(String source, int index) {
  final start = source.lastIndexOf('\n', index) + 1;
  return RegExp(r'^[ \t]*').stringMatch(source.substring(start)) ?? '';
}
```

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor/audio_catalog_test.dart` → PASS. `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/audio_catalog.dart test/unit/content_editor/audio_catalog_test.dart
git commit -m "feat(editeur): lire audio.json et y inserer un son sans le reecrire"
```

---

## Task 7 : l'écrivain importe, sous rollback

**Files:**
- Create: `lib/services/content_editor/pending_import.dart`
- Modify: `lib/services/content_editor/entity_writer.dart`
- Test: `test/unit/content_editor/entity_writer_test.dart`

**Interfaces:**
- Consumes: `AssetSlot`, `imagePathOf` (tâches 1, 5) ; `insertSound`, `kAudioCatalogPath` (tâche 6).
- Produces : `class PendingImport` (`key`, `slot`, `sourcePath`, `destination`, `soundId`, getters `extension`, `audioFile`) avec `PendingImport.sound({required String key, required String sourcePath, required String soundId})` et `PendingImport.image({required EntityDescriptor descriptor, required String id, required String key, required String sourcePath})` ; `EntityWriter.writeAll(List<EntityDraft> drafts, {List<PendingImport> imports = const []})`.

- [ ] **Step 1 : écrire les tests qui échouent**

Dans `entity_writer_test.dart`, importer `package:roguelike_card_game/services/content_editor/pending_import.dart`, puis ajouter avant la fin de `main()` :

```dart
  group('ressources importees', () {
    const audio = '{\n  "schemaVersion": 1,\n  "sounds": {\n'
        '    "clang": { "file": "sfx/clang.wav" }\n  },\n'
        '  "moments": {},\n  "music": {}\n}\n';

    late String sound;
    late String image;

    setUp(() {
      File('$root/assets/data/audio.json').writeAsStringSync(audio);
      Directory('$root/import').createSync();
      sound = '$root/import/nouveau.wav';
      File(sound).writeAsStringSync('octets du son');
      image = '$root/import/troll.png';
      File(image).writeAsStringSync('nouvelle');

      Directory('$root/assets/data/enemies/troll').createSync(recursive: true);
      File('$root/assets/data/enemies/troll/sprite.png')
          .writeAsStringSync('ancienne');
      File('$root/assets/data/enemies/troll/enemy.json')
          .writeAsStringSync('{}');
    });

    List<String> backups() => Directory('$root/assets')
        .listSync(recursive: true)
        .map((entity) => entity.path)
        .where((path) => path.endsWith('.editor-backup'))
        .toList();

    EntityDraft trollModification() {
      final enemy = kEntityDescriptors[EntityCategory.enemy]!;
      return EntityDraft(
        descriptor: enemy,
        id: 'troll',
        isModification: true,
        bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
        mechanics: enemy.template,
      );
    }

    PendingImport trollSprite() => PendingImport.image(
          descriptor: kEntityDescriptors[EntityCategory.enemy]!,
          id: 'troll',
          key: 'spritePath',
          sourcePath: image,
        );

    test('un son importe est copie et declare', () async {
      final report = await EntityWriter(fs: RecordingFileSystem(root), rootPath: root)
          .writeAll([fixtureRelicDraft()], imports: [
        PendingImport.sound(
            key: 'sfx', sourcePath: sound, soundId: 'talisman_clang'),
      ]);

      expect(
        File('$root/assets/audio/sfx/talisman_clang.wav').readAsStringSync(),
        'octets du son',
      );
      final sounds = (jsonDecode(
        File('$root/assets/data/audio.json').readAsStringSync(),
      ) as Map<String, dynamic>)['sounds'] as Map<String, dynamic>;
      expect(sounds['talisman_clang'], {'file': 'sfx/talisman_clang.wav'});
      expect(report.written, containsAll([
        'assets/audio/sfx/talisman_clang.wav',
        'assets/data/audio.json',
      ]));
    });

    test('une image importee remplace celle du nom impose', () async {
      await EntityWriter(fs: RecordingFileSystem(root), rootPath: root)
          .writeAll([trollModification()], imports: [trollSprite()]);

      expect(
        File('$root/assets/data/enemies/troll/sprite.png').readAsStringSync(),
        'nouvelle',
      );
      expect(backups(), isEmpty, reason: 'la sauvegarde est retiree au succes');
    });

    test('un echec apres les imports defait tout, sauvegarde comprise',
        () async {
      // Ecriture 1 : audio.json. Ecriture 2 : enemy.json, qui leve.
      final flaky = FailingOnNthWrite(root, failAt: 2);

      await expectLater(
        EntityWriter(fs: flaky, rootPath: root).writeAll(
          [trollModification()],
          imports: [
            trollSprite(),
            PendingImport.sound(
                key: 'sfx', sourcePath: sound, soundId: 'troll_cri'),
          ],
        ),
        throwsA(anything),
      );

      expect(
        File('$root/assets/data/enemies/troll/sprite.png').readAsStringSync(),
        'ancienne',
      );
      expect(File('$root/assets/audio/sfx/troll_cri.wav').existsSync(), isFalse);
      expect(File('$root/assets/data/audio.json').readAsStringSync(), audio);
      expect(File('$root/assets/data/enemies/troll/enemy.json').readAsStringSync(),
          '{}');
      expect(backups(), isEmpty);
    });
  });
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/entity_writer_test.dart` → échec de compilation (`PendingImport`, paramètre `imports`).

- [ ] **Step 3 : implémenter**

`lib/services/content_editor/pending_import.dart` :

```dart
import 'package:meta/meta.dart';

import 'entity_descriptor.dart';

/// Un fichier choisi par l'usager, en attente d'« Écrire » (spec D12).
///
/// Rien n'est copie au moment du choix : l'import entre dans la meme
/// transaction que l'entite, et se defait avec elle.
@immutable
class PendingImport {
  const PendingImport({
    required this.key,
    required this.slot,
    required this.sourcePath,
    required this.destination,
    this.soundId,
  });

  /// Un son : copie sous `assets/audio/sfx/<soundId>.<extension>`, puis
  /// declare dans `audio.json`.
  factory PendingImport.sound({
    required String key,
    required String sourcePath,
    required String soundId,
  }) =>
      PendingImport(
        key: key,
        slot: const AssetSlot.sound(),
        sourcePath: sourcePath,
        destination: 'assets/audio/sfx/$soundId.${_extensionOf(sourcePath)}',
        soundId: soundId,
      );

  /// Une image : copiee sous le nom que l'emplacement impose.
  factory PendingImport.image({
    required EntityDescriptor descriptor,
    required String id,
    required String key,
    required String sourcePath,
  }) =>
      PendingImport(
        key: key,
        slot: descriptor.assetKeys[key]!,
        sourcePath: sourcePath,
        destination: descriptor.imagePathOf(id, key)!,
      );

  /// La cle de l'entite que l'import alimente : `sfx`, `spritePath`…
  final String key;
  final AssetSlot slot;

  /// Chemin absolu du fichier choisi, separe par `/`.
  final String sourcePath;

  /// Chemin de la copie, relatif a la racine du projet.
  final String destination;

  /// L'identifiant du son a declarer. `null` pour une image.
  final String? soundId;

  String get extension => _extensionOf(sourcePath);

  /// Le chemin qu'`audio.json` enregistre, relatif a `assets/audio/`.
  String get audioFile => destination.substring('assets/audio/'.length);

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  }
}
```

`entity_writer.dart` — importer `'audio_catalog.dart'` et `'pending_import.dart'`. Remplacer `WriteStep` :

```dart
/// Une ecriture, et de quoi la defaire.
@immutable
class WriteStep {
  /// Un fichier texte : [previous] est son contenu d'avant, `null` s'il
  /// n'existait pas.
  const WriteStep(this.relative, this.previous)
      : isAsset = false,
        backup = null;

  /// Une ressource copiee : [backup] est la sauvegarde de l'image ecrasee,
  /// `null` si la destination n'existait pas.
  const WriteStep.asset(this.relative, this.backup)
      : isAsset = true,
        previous = null;

  final String relative;
  final String? previous;
  final bool isAsset;
  final String? backup;
}
```

Remplacer `writeAll` et `_writeFiles` :

```dart
  /// Ecrit plusieurs brouillons, et les ressources importees, comme **un seul
  /// geste**.
  ///
  /// Ordre : dossiers, ressources, `audio.json`, puis chaque entite. Tout
  /// partage une pile de rollback ; une image ecrasee est sauvegardee avant
  /// copie, restauree en cas d'echec, supprimee au succes.
  ///
  /// `sync_assets` ne tourne qu'une fois, a la fin.
  Future<WriteReport> writeAll(
    List<EntityDraft> drafts, {
    List<PendingImport> imports = const [],
  }) async {
    final steps = <WriteStep>[];
    try {
      for (final draft in drafts) {
        _prepareFolder(draft);
      }
      for (final pending in imports) {
        _copyAsset(pending, steps);
      }
      _declareSounds(imports, steps);
      for (final draft in drafts) {
        _writeFiles(draft, steps);
      }
    } catch (_) {
      _rollback(steps);
      rethrow;
    }
    _dropBackups(steps);

    final sync = await _runSyncAssets();

    return WriteReport(
      written: [for (final step in steps) step.relative],
      sync: sync,
      createdEntity: drafts.any((draft) => !draft.isModification),
    );
  }

  void _writeFiles(EntityDraft draft, List<WriteStep> steps) {
    _placeImage(draft);
    _placeClassIcon(draft);
    _writeJson(draft.path, draft.compose(), steps);
    _registerSignatureCard(draft, steps);
  }

  /// Copie un fichier importe a sa destination. Une destination existante est
  /// d'abord sauvegardee : l'etape est empilee **avant** la copie, pour qu'une
  /// copie ratee a mi-chemin se defasse aussi.
  void _copyAsset(PendingImport pending, List<WriteStep> steps) {
    final absolute = '$rootPath/${pending.destination}';
    fs.createDirectory(absolute.substring(0, absolute.lastIndexOf('/')));

    String? backup;
    if (fs.fileExists(absolute)) {
      backup = '${pending.destination}.editor-backup';
      fs.copyFile(absolute, '$rootPath/$backup');
    }
    steps.add(WriteStep.asset(pending.destination, backup));
    fs.copyFile(pending.sourcePath, absolute);
  }

  /// Declare chaque son importe dans `audio.json`, en une ecriture.
  void _declareSounds(List<PendingImport> imports, List<WriteStep> steps) {
    final sounds = [for (final p in imports) if (p.soundId != null) p];
    if (sounds.isEmpty) return;

    final absolute = '$rootPath/$kAudioCatalogPath';
    final before = fs.readFile(absolute);
    var text = before;
    for (final pending in sounds) {
      text = insertSound(text, id: pending.soundId!, file: pending.audioFile);
    }
    steps.add(WriteStep(kAudioCatalogPath, before));
    fs.writeFile(absolute, text);
  }

  void _dropBackups(List<WriteStep> steps) {
    for (final step in steps) {
      final backup = step.backup;
      if (backup != null && fs.fileExists('$rootPath/$backup')) {
        fs.deleteFile('$rootPath/$backup');
      }
    }
  }
```

Retirer l'appel `_prepareFolder(draft);` qui figurait dans l'ancien `_writeFiles`. Dans `_rollback`, en tête du corps de boucle, après `final absolute = …` :

```dart
      if (step.isAsset) {
        final backup = step.backup;
        if (backup != null) {
          fs.copyFile('$rootPath/$backup', absolute);
          fs.deleteFile('$rootPath/$backup');
        } else if (fs.fileExists(absolute)) {
          fs.deleteFile(absolute);
        }
        continue;
      }
```

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor` → PASS. `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/pending_import.dart lib/services/content_editor/entity_writer.dart test/unit/content_editor/entity_writer_test.dart
git commit -m "feat(editeur): copier les ressources importees et declarer les sons sous rollback"
```

---

## Task 8 : la validation « ressources »

**Files:**
- Modify: `lib/services/content_editor/entity_validator.dart`
- Test: `test/unit/content_editor/entity_validator_test.dart`, `test/widget/content_editor_screen_test.dart` (`seedRelic`)

**Interfaces:**
- Consumes: `soundIds` (tâche 6), `PendingImport` (tâche 7), `imageKeys`/`isComputedImage`/`imagePathOf` (tâche 5).
- Produces : `EntityValidator({required fs, required rootPath, registry, List<PendingImport> imports = const []})`.

- [ ] **Step 1 : écrire les tests qui échouent**

`entity_validator_test.dart` — importer `pending_import.dart`, puis :

```dart
  group('famille ressources', () {
    void seedAudio() => File('$root/assets/data/audio.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{"sounds": {"clang": {"file": "sfx/clang.wav"}}}');

    EntityDraft relicWithSfx(Object? sfx) => fixtureRelicDraft(
          mechanics: jsonEncode({
            ...kEntityDescriptors[EntityCategory.relic]!.decodeTemplate(),
            'sfx': sfx,
          }),
        );

    String sourceFile(String name) {
      final file = File('$root/import/$name')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('octets');
      return IoContentFileSystem.toSlashes(file.path);
    }

    EntityValidator withImports(List<PendingImport> imports) => EntityValidator(
          fs: fs,
          rootPath: root,
          registry: fixtureRegistry(),
          imports: imports,
        );

    test('un son declare passe', () {
      seedAudio();
      expect(validatorWith().validate(relicWithSfx('clang')), isEmpty);
    });

    test('un son non declare est refuse', () {
      seedAudio();
      expect(validatorWith().validate(relicWithSfx('inconnu')).single.field,
          'sfx');
    });

    test('un son vide est refuse', () {
      seedAudio();
      expect(validatorWith().validate(relicWithSfx('')).single.field, 'sfx');
    });

    test('un son en attente d import passe', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: sourceFile('neuf.wav'), soundId: 'neuf'),
      ]).validate(relicWithSfx('neuf'));
      expect(faults, isEmpty);
    });

    test('un import de son deja declare est refuse', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: sourceFile('clang.wav'), soundId: 'clang'),
      ]).validate(relicWithSfx('clang'));
      expect(faults.map((f) => f.message).join(), contains('existe déjà'));
    });

    test('une extension refusee est refusee', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: sourceFile('notes.txt'), soundId: 'notes'),
      ]).validate(relicWithSfx('notes'));
      expect(faults.map((f) => f.message).join(), contains('extension'));
    });

    test('un fichier source absent est refuse', () {
      seedAudio();
      final faults = withImports([
        PendingImport.sound(
            key: 'sfx', sourcePath: '$root/import/absent.wav', soundId: 'absent'),
      ]).validate(relicWithSfx('absent'));
      expect(faults.map((f) => f.message).join(), contains('introuvable'));
    });

    test('une image obligatoire absente est refusee en modification', () {
      final enemy = kEntityDescriptors[EntityCategory.enemy]!;
      File('$root/assets/data/enemies/troll/enemy.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{}');
      final faults = validatorWith().validate(EntityDraft(
        descriptor: enemy,
        id: 'troll',
        isModification: true,
        bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
        mechanics: enemy.template,
      ));
      expect(faults.single.field, 'spritePath');
    });
  });
```

Dans `test/widget/content_editor_screen_test.dart`, `seedRelic()` du groupe *mode Modifier* : sa relique porte `sfx: clang_distinctif`, désormais contrôlé. Ajouter en tête du corps de `seedRelic()` :

```dart
      File('$root/assets/data/audio.json').writeAsStringSync(
        '{"sounds": {"clang_distinctif": {"file": "sfx/clang_distinctif.wav"}}}',
      );
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/unit/content_editor/entity_validator_test.dart` → échec de compilation (paramètre `imports`).

- [ ] **Step 3 : implémenter**

`entity_validator.dart` : importer `'audio_catalog.dart'` et `'pending_import.dart'`. Constructeur : ajouter `this.imports = const [],` ; champ :

```dart
  /// Les fichiers choisis, en attente d'« Écrire » : un son importe est
  /// declare pour cette validation, comme il le sera a l'ecriture.
  final List<PendingImport> imports;
```

Dans `validate`, insérer `() => _assets(draft, mechanics),` juste après `() => _references(draft, mechanics),`. Ajouter :

```dart
  /// Les ressources : un son doit etre declare, un import doit pouvoir etre
  /// copie, une image obligatoire doit exister.
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
      for (final key in descriptor.imageKeys.where(descriptor.isComputedImage)) {
        final relative = descriptor.imagePathOf(draft.id, key)!;
        final importing = imports.any((pending) => pending.key == key);
        if (!importing && !fs.fileExists('$rootPath/$relative')) {
          faults.add(ValidationFault('image absente : $relative', field: key));
        }
      }
    }
    return faults;
  }
```

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/unit/content_editor test/widget/content_editor_screen_test.dart` → PASS. `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/services/content_editor/entity_validator.dart test/unit/content_editor/entity_validator_test.dart test/widget/content_editor_screen_test.dart
git commit -m "feat(editeur): valider les sons, les imports et les images obligatoires"
```

---

## Task 9 : le formulaire récursif et le champ de ressource

**Files:**
- Create: `lib/ui/widgets/content_editor/document_form.dart`, `lib/ui/widgets/content_editor/asset_field.dart`
- Test: `test/widget/content_editor/document_form_test.dart`, `test/widget/content_editor/asset_field_test.dart`

**Interfaces:**
- Consumes: `EditorDocument` (tâche 2), `inferFieldKind`/`FieldKind` (tâche 4), `labelOf`/`patternOf`, `ChoiceButton`, `ColorField`, `hexToColor`, `colorToHex`.
- Produces : `DocumentForm({required EditorDocument document, required EntityDescriptor descriptor, required VoidCallback onChanged, required VoidCallback onStructureChanged, required Widget Function(String key, AssetSlot slot) assetField, Map<String, List<String>> referenceOptions, Map<String, List<String>> vocabulary})` — chaque saisie porte `Key('editeur-champ-<libellé>')`, « Ajouter » `Key('editeur-ajouter-<libellé>')`, « Retirer » `Key('editeur-retirer-<libellé>')`. `AssetField({required String fieldKey, required AssetSlot slot, String? value, List<String> soundIds, Uint8List? imageBytes, String? pendingLabel, ValueChanged<String>? onSelectSound, VoidCallback? onClear, VoidCallback? onImport})` — importer : `Key('editeur-importer-<clé>')`.

- [ ] **Step 1 : écrire les tests qui échouent**

`test/widget/content_editor/document_form_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/editor_document.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/document_form.dart';

void main() {
  final card = kEntityDescriptors[EntityCategory.card]!;
  final relic = kEntityDescriptors[EntityCategory.relic]!;
  final hero = kEntityDescriptors[EntityCategory.heroClass]!;
  final event = kEntityDescriptors[EntityCategory.event]!;

  var structureChanges = 0;

  Future<void> pump(
    WidgetTester tester,
    EditorDocument document,
    EntityDescriptor descriptor, {
    Map<String, List<String>> references = const {},
    Map<String, List<String>> vocabulary = const {},
  }) async {
    structureChanges = 0;
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DocumentForm(
            document: document,
            descriptor: descriptor,
            onChanged: () {},
            onStructureChanged: () => structureChanges++,
            referenceOptions: references,
            vocabulary: vocabulary,
            assetField: (key, slot) => Text('ressource $key'),
          ),
        ),
      ),
    ));
  }

  EditorDocument templateOf(EntityDescriptor d) => EditorDocument(
        d.decodeTemplate(),
        requiredKeys: d.requiredKeys,
        template: d.decodeTemplate(),
      );

  testWidgets('une enumeration se choisit par bouton', (tester) async {
    final document = templateOf(relic);
    await pump(tester, document, relic);

    await tester.tap(find.text('legendary'));
    expect(document.root['rarity'], 'legendary');
  });

  testWidgets('un entier reste un entier, une saisie illisible est une faute',
      (tester) async {
    final document = templateOf(relic);
    await pump(tester, document, relic);

    await tester.enterText(find.byKey(const Key('editeur-champ-value')), '12');
    expect(document.root['value'], 12);

    await tester.enterText(find.byKey(const Key('editeur-champ-value')), '1a');
    expect(document.root['value'], 12);
    expect(document.conversionFaults.single.field, 'value');
  });

  testWidgets('une cle inconnue du gabarit a son champ', (tester) async {
    final document = EditorDocument({...relic.decodeTemplate(), 'custom_flag': true});
    await pump(tester, document, relic);

    await tester.tap(find.byKey(const Key('editeur-champ-custom_flag')));
    expect(document.root['custom_flag'], isFalse);
  });

  testWidgets('Ajouter clone l element modele d une liste', (tester) async {
    final document = templateOf(card);
    await pump(tester, document, card, vocabulary: const {
      'effects[].type': ['damage'],
    });

    await tester.tap(find.byKey(const Key('editeur-ajouter-effects')));
    expect(document.root['effects'], hasLength(2));
    expect(structureChanges, 1);
  });

  testWidgets('une ressource absente du document a quand meme son champ',
      (tester) async {
    await pump(tester, templateOf(relic), relic);
    expect(find.text('ressource sfx'), findsOneWidget);
  });

  testWidgets('une reference absente se choisit dans son catalogue',
      (tester) async {
    final document = templateOf(hero);
    await pump(tester, document, hero, references: const {
      'passiveTrait': ['regen_armor'],
    });

    await tester.tap(find.text('regen_armor'));
    expect(document.root['passiveTrait'], 'regen_armor');
  });

  testWidgets('un vocabulaire montre aussi la valeur fautive', (tester) async {
    final document = EditorDocument({
      'effects': [
        {'type': 'skill', 'value': 3},
      ],
    });
    await pump(tester, document, card, vocabulary: const {
      'effects[].type': ['damage'],
    });

    expect(find.text('damage'), findsOneWidget);
    expect(find.text('skill'), findsOneWidget);
  });

  testWidgets('une paire bilingue imbriquee tient sur une rangee',
      (tester) async {
    await pump(tester, templateOf(event), event);
    final fr = tester.getTopLeft(
        find.byKey(const Key('editeur-champ-choices[0].text_fr')));
    final en = tester.getTopLeft(
        find.byKey(const Key('editeur-champ-choices[0].text_en')));
    expect(en.dy, fr.dy);
    expect(en.dx, greaterThan(fr.dx));
  });

  testWidgets('ni id, ni prose, ni skills ne deviennent des champs',
      (tester) async {
    await pump(
      tester,
      EditorDocument({'id': 'x', 'name_fr': 'X', 'skills': ['a'], 'maxHp': 1}),
      hero,
    );
    expect(find.byKey(const Key('editeur-champ-id')), findsNothing);
    expect(find.byKey(const Key('editeur-champ-name_fr')), findsNothing);
    expect(find.byKey(const Key('editeur-champ-skills')), findsNothing);
    expect(find.byKey(const Key('editeur-champ-maxHp')), findsOneWidget);
  });
}
```

`test/widget/content_editor/asset_field_test.dart` :

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/asset_field.dart';

/// Un PNG de 1 x 1 pixel transparent.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  Future<void> pump(WidgetTester tester, AssetField field) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(body: field),
      ));

  testWidgets('un son se choisit parmi les sons declares, ou aucun',
      (tester) async {
    String? picked;
    var cleared = false;
    await pump(
      tester,
      AssetField(
        fieldKey: 'sfx',
        slot: const AssetSlot.sound(),
        value: null,
        soundIds: const ['clang', 'zap'],
        onSelectSound: (id) => picked = id,
        onClear: () => cleared = true,
      ),
    );

    await tester.tap(find.text('zap'));
    expect(picked, 'zap');
    await tester.tap(find.text('aucun'));
    expect(cleared, isTrue);
  });

  testWidgets('Importer n apparait qu avec son geste', (tester) async {
    await pump(tester,
        const AssetField(fieldKey: 'sfx', slot: AssetSlot.sound()));
    expect(find.byKey(const Key('editeur-importer-sfx')), findsNothing);

    var imported = false;
    await pump(
      tester,
      AssetField(
        fieldKey: 'sfx',
        slot: const AssetSlot.sound(),
        onImport: () => imported = true,
      ),
    );
    await tester.tap(find.byKey(const Key('editeur-importer-sfx')));
    expect(imported, isTrue);
  });

  testWidgets('une image montre son apercu, et « aucune » si optionnelle',
      (tester) async {
    await pump(
      tester,
      AssetField(
        fieldKey: 'iconPath',
        slot: const AssetSlot.image('icon.png', isRequired: false),
        value: 'assets/data/classes/x/icon.png',
        imageBytes: _pixel,
        onClear: () {},
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('aucune'), findsOneWidget);

    await pump(
      tester,
      const AssetField(
        fieldKey: 'spritePath',
        slot: AssetSlot.image('sprite.png'),
        value: 'assets/data/enemies/x/sprite.png',
      ),
    );
    expect(find.text('aucune'), findsNothing);
  });
}
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/widget/content_editor/document_form_test.dart test/widget/content_editor/asset_field_test.dart` → échec de compilation.

- [ ] **Step 3 : implémenter**

`lib/ui/widgets/content_editor/asset_field.dart` :

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';
import 'choice_button.dart';

/// Le champ d'une ressource : un son choisi parmi `audio.json`, ou une image
/// au nom impose (spec §5.2, §5.3).
///
/// **Purement presentationnel** : l'ecran lit le disque et fournit les octets
/// de l'image — un widget qui importerait `dart:io` casserait le build web.
class AssetField extends StatelessWidget {
  const AssetField({
    super.key,
    required this.fieldKey,
    required this.slot,
    this.value,
    this.soundIds = const [],
    this.imageBytes,
    this.pendingLabel,
    this.onSelectSound,
    this.onClear,
    this.onImport,
  });

  final String fieldKey;
  final AssetSlot slot;

  /// L'identifiant du son choisi, ou le chemin de l'image.
  final String? value;
  final List<String> soundIds;

  /// L'image actuelle, ou celle en attente d'import. `null` si aucune.
  final Uint8List? imageBytes;

  /// « à importer : … », tant que l'import attend « Écrire ».
  final String? pendingLabel;

  final ValueChanged<String>? onSelectSound;

  /// « aucun » pour un son, « aucune » pour une image optionnelle.
  final VoidCallback? onClear;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fieldKey, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (slot.kind == AssetKind.sound) _sounds() else _image(),
          if (pendingLabel != null)
            Text(pendingLabel!, style: const TextStyle(color: AppColors.warning)),
          if (onImport != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton(
                key: Key('editeur-importer-$fieldKey'),
                onPressed: onImport,
                child: const Text('Importer…'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sounds() {
    final current = value;
    return Wrap(
      key: Key('editeur-champ-$fieldKey'),
      spacing: 4,
      runSpacing: 4,
      children: [
        ChoiceButton(
          label: 'aucun',
          isSelected: current == null,
          onTap: () => onClear?.call(),
        ),
        // Un son en attente d'import n'est pas encore dans `audio.json` : il
        // reste affiche, et choisi.
        for (final id in {...soundIds, ?current})
          ChoiceButton(
            label: id,
            isSelected: current == id,
            onTap: () => onSelectSound?.call(id),
          ),
      ],
    );
  }

  Widget _image() {
    final bytes = imageBytes;
    return Row(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: bytes == null
              ? const Center(child: Text('—'))
              : Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(child: Text('?')),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ?? '(aucune)',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        if (!slot.isRequired && onClear != null)
          TextButton(onPressed: onClear, child: const Text('aucune')),
      ],
    );
  }
}
```

`lib/ui/widgets/content_editor/document_form.dart` :

```dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../services/content_editor/editor_document.dart';
import '../../../services/content_editor/entity_descriptor.dart';
import '../../../services/content_editor/field_kind.dart';
import '../../../services/content_editor/field_path.dart';
import 'choice_button.dart';
import 'color_field.dart';

/// La mecanique d'une entite, **inferee du document** (spec §4).
///
/// Les champs viennent du document, plus les ressources et les references
/// qu'il ne porte pas encore. Aucune cle du fichier n'est perdue : une cle
/// inconnue recoit le widget de son type.
///
/// L'ecran recree ce widget (`ValueKey`) quand la structure change — un
/// element ajoute ou retire decale les libelles, donc les controleurs.
class DocumentForm extends StatefulWidget {
  const DocumentForm({
    super.key,
    required this.document,
    required this.descriptor,
    required this.onChanged,
    required this.onStructureChanged,
    required this.assetField,
    this.referenceOptions = const {},
    this.vocabulary = const {},
  });

  final EditorDocument document;
  final EntityDescriptor descriptor;

  /// Une valeur a change.
  final VoidCallback onChanged;

  /// Un element a ete ajoute ou retire.
  final VoidCallback onStructureChanged;

  final Widget Function(String key, AssetSlot slot) assetField;
  final Map<String, List<String>> referenceOptions;
  final Map<String, List<String>> vocabulary;

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  final Map<String, TextEditingController> _controllers = {};

  EditorDocument get _document => widget.document;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final root = _document.root;
    final descriptor = widget.descriptor;
    final keys = <String>[
      for (final key in root.keys)
        if (_isField(key)) key,
      for (final key in descriptor.assetKeys.keys)
        if (!root.containsKey(key)) key,
      for (final key in descriptor.referenceKeys.keys)
        if (!root.containsKey(key)) key,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final key in keys) _field([key], root[key])],
    );
  }

  /// `id` a son champ, la prose de premier niveau aussi ; `skills` est derive
  /// par l'ecrivain ; une cle interdite ne s'ecrit pas.
  bool _isField(String key) {
    final descriptor = widget.descriptor;
    if (key == 'id' || key == 'skills') return false;
    if (descriptor.forbiddenKeys.contains(key)) return false;
    for (final base in descriptor.bilingualBases) {
      if (key == base || key == '${base}_fr' || key == '${base}_en') {
        return false;
      }
    }
    return true;
  }

  void _set(FieldPath path, Object? value) {
    _document.setAt(path, value);
    widget.onChanged();
  }

  Widget _field(FieldPath path, Object? value) {
    final descriptor = widget.descriptor;
    final pattern = patternOf(path);
    final kind = inferFieldKind(
      path: path,
      value: value,
      descriptor: descriptor,
      hasModelElement: value is List && _document.modelElementFor(path) != null,
    );

    switch (kind) {
      case FieldKind.asset:
        return widget.assetField(pattern, descriptor.assetKeys[pattern]!);
      case FieldKind.reference:
        return _choices(
          path,
          widget.referenceOptions[pattern] ?? const [],
          isSelected: (option) => value == option,
          onTap: (option) => _set(path, option),
          noneSelected: value == null,
          onNone: () {
            _document.removeAt(path);
            widget.onChanged();
          },
        );
      case FieldKind.color:
        return _labelled(
          path,
          ColorField(
            key: Key('editeur-champ-${labelOf(path)}'),
            value: hexToColor(value is String ? value : '') ??
                const Color(0xFFFF00FF),
            onChanged: (color) => _set(path, colorToHex(color)),
          ),
        );
      case FieldKind.enumChoice:
        return _choices(
          path,
          descriptor.enumKeys[pattern]!,
          isSelected: (option) => value == option,
          onTap: (option) => _set(path, option),
        );
      case FieldKind.enumMulti:
        final options = descriptor.enumListKeys[pattern]!;
        final selected = {...?(value as List?)?.whereType<String>()};
        return _choices(
          path,
          options,
          isSelected: selected.contains,
          onTap: (option) => _set(path, [
            for (final o in options)
              if (selected.contains(o) != (o == option)) o,
          ]),
        );
      case FieldKind.vocabulary:
        // La valeur fautive reste visible, et choisie : la validation dira
        // pourquoi elle est refusee.
        final options = {
          ...?widget.vocabulary[pattern],
          if (value is String && value.isNotEmpty) value,
        }.toList();
        return _choices(
          path,
          options,
          isSelected: (option) => value == option,
          onTap: (option) => _set(path, option),
        );
      case FieldKind.boolean:
        return SwitchListTile(
          key: Key('editeur-champ-${labelOf(path)}'),
          contentPadding: EdgeInsets.zero,
          title: Text(_name(path)),
          value: value! as bool,
          onChanged: (checked) => _set(path, checked),
        );
      case FieldKind.integer:
        return _textField(path, '$value', (text) {
          final parsed = int.tryParse(text.trim());
          if (parsed == null) {
            _document.reportConversion(path, '« $text » n\'est pas un entier');
            widget.onChanged();
          } else {
            _set(path, parsed);
          }
        }, keyboard: TextInputType.number);
      case FieldKind.decimal:
        return _textField(path, '$value', (text) {
          final parsed = double.tryParse(text.trim());
          if (parsed == null) {
            _document.reportConversion(path, '« $text » n\'est pas un nombre');
            widget.onChanged();
          } else {
            _set(path, parsed);
          }
        }, keyboard: const TextInputType.numberWithOptions(decimal: true));
      case FieldKind.text:
        return _textField(path, value! as String, (text) => _set(path, text));
      case FieldKind.objectList:
        return _objectList(path, value! as List);
      case FieldKind.stringList:
        return _stringList(path, (value! as List).cast<String>());
      case FieldKind.object:
        return _labelled(
          path,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _objectFields(path, value! as Map<String, dynamic>),
          ),
        );
      case FieldKind.rawJson:
        return _textField(path, jsonEncode(value), (text) {
          try {
            _set(path, jsonDecode(text));
          } on FormatException {
            _document.reportConversion(path, 'JSON invalide');
            widget.onChanged();
          }
        });
    }
  }

  /// Le dernier segment nomme du chemin : `type` pour `effects[0].type`.
  String _name(FieldPath path) =>
      path.lastWhere((segment) => segment is String) as String;

  Widget _labelled(FieldPath path, Widget child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name(path), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            child,
          ],
        ),
      );

  Widget _choices(
    FieldPath path,
    List<String> options, {
    required bool Function(String option) isSelected,
    required void Function(String option) onTap,
    VoidCallback? onNone,
    bool noneSelected = false,
  }) {
    return _labelled(
      path,
      Wrap(
        key: Key('editeur-champ-${labelOf(path)}'),
        spacing: 4,
        runSpacing: 4,
        children: [
          if (onNone != null)
            ChoiceButton(label: 'aucun', isSelected: noneSelected, onTap: onNone),
          for (final option in options)
            ChoiceButton(
              label: option,
              isSelected: isSelected(option),
              onTap: () => onTap(option),
            ),
        ],
      ),
    );
  }

  Widget _textField(
    FieldPath path,
    String initial,
    ValueChanged<String> onChanged, {
    TextInputType? keyboard,
  }) {
    final label = labelOf(path);
    final controller = _controllers.putIfAbsent(
      label,
      () => TextEditingController(text: initial),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        key: Key('editeur-champ-$label'),
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: _name(path),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _objectList(FieldPath path, List<dynamic> list) {
    final label = labelOf(path);
    return _labelled(
      path,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < list.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._objectFields(
                        [...path, i], list[i] as Map<String, dynamic>),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: Key('editeur-retirer-$label[$i]'),
                        onPressed: () {
                          _document.removeElement(path, i);
                          widget.onStructureChanged();
                        },
                        child: const Text('Retirer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            key: Key('editeur-ajouter-$label'),
            onPressed: () {
              if (_document.addElement(path)) widget.onStructureChanged();
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  /// Les champs d'un objet ; une paire `x_fr` / `x_en` tient sur une rangee,
  /// francais a gauche.
  List<Widget> _objectFields(FieldPath prefix, Map<String, dynamic> map) {
    final widgets = <Widget>[];
    for (final entry in map.entries) {
      final key = entry.key;
      if (key.endsWith('_en') &&
          map.containsKey('${key.substring(0, key.length - 3)}_fr')) {
        continue; // rendu avec sa paire francaise
      }
      final english = key.endsWith('_fr')
          ? '${key.substring(0, key.length - 3)}_en'
          : null;
      if (english != null && map[english] is String && entry.value is String) {
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field([...prefix, key], entry.value)),
            const SizedBox(width: 8),
            Expanded(child: _field([...prefix, english], map[english])),
          ],
        ));
        continue;
      }
      widgets.add(_field([...prefix, key], entry.value));
    }
    return widgets;
  }

  Widget _stringList(FieldPath path, List<String> list) {
    final label = labelOf(path);
    return _labelled(
      path,
      Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < list.length; i++)
            InputChip(
              label: Text(list[i]),
              onDeleted: () {
                _document.setAt(path, [...list]..removeAt(i));
                widget.onStructureChanged();
              },
            ),
          SizedBox(
            width: 160,
            child: TextField(
              key: Key('editeur-ajouter-$label'),
              decoration: const InputDecoration(hintText: 'ajouter…'),
              onSubmitted: (text) {
                final added = text.trim();
                if (added.isEmpty) return;
                _document.setAt(path, [...list, added]);
                widget.onStructureChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

> Note d'exécution : `{...soundIds, ?current}` (élément nul-conscient de collection) et les jokers `(_, _, _)` exigent Dart ≥ 3.8 ; le SDK du dépôt est 3.11. Si `dart analyze` les refuse, écrire `if (current != null) current` et `(context, error, stack)`.

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/widget/content_editor` → PASS. `dart analyze` → propre.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/ui/widgets/content_editor/document_form.dart lib/ui/widgets/content_editor/asset_field.dart test/widget/content_editor/document_form_test.dart test/widget/content_editor/asset_field_test.dart
git commit -m "feat(editeur): formulaire recursif infere du document et champ de ressource"
```

---

## Task 10 : l'écran compose depuis le document

**Files:**
- Modify: `lib/ui/screens/content_editor_screen.dart`, `lib/ui/widgets/content_editor/entity_form.dart`
- Test: `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: `EditorDocument` (2), `DocumentForm`/`AssetField` (9), `vocabularyOf` (3), `soundIds` (6), `isComputedImage`/`imagePathOf` (5).
- Produces : `EntityForm` perd `mechanicsController`, `templateFieldControllers`, `themeColor`, `onThemeColorChanged`, `referenceOptions`, `referenceSelections`, `onReferenceSelected` ; gagne `required Widget mechanics`, `required bool rawView`, `required VoidCallback onToggleRaw`. Bascule : `Key('editeur-bascule-json')` ; vue brute : `Key('editeur-json-brut')`.

- [ ] **Step 1 : adapter et écrire les tests (rouges)**

Dans `test/widget/content_editor_screen_test.dart`, groupe *mode Modifier*, remplacer l'aide `mechanicsBox` :

```dart
    /// Le document du formulaire, lu dans la vue brute puis refermee.
    Future<Map<String, dynamic>> mechanicsBox(WidgetTester tester) async {
      final toggle = find.byKey(const Key('editeur-bascule-json'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final box =
          tester.widget<TextField>(find.byKey(const Key('editeur-json-brut')));
      final decoded = jsonDecode(box.controller!.text) as Map<String, dynamic>;
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      return decoded;
    }
```

Puis, dans ce groupe : chaque `mechanicsBox(tester)` devient `await mechanicsBox(tester)` ; dans *une cible absente est signalee*, remplacer `expect(find.textContaining('startOfCombat'), findsOneWidget);` par `expect((await mechanicsBox(tester))['trigger'], 'startOfCombat');` ; dans *le type reste choisissable*, remplacer `expect(find.textContaining('"maxHp": 100'), findsOneWidget);` par :

```dart
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('editeur-champ-maxHp')))
            .controller!
            .text,
        '100',
      );
```

Ajouter à la fin du groupe *mode Modifier* :

```dart
    testWidgets('une cle inconnue du gabarit a son champ et survit a Ecrire',
        (tester) async {
      seedRelic();
      final path = '$root/assets/data/relics/talisman_de_fer.json';
      File(path).writeAsStringSync(jsonEncode({
        ...jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
        'custom_flag': true,
      }));
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('talisman_de_fer'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editeur-champ-custom_flag')), findsOneWidget);

      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();
      expect(jsonDecode(File(path).readAsStringSync()),
          containsPair('custom_flag', true));
    });
```

Ajouter hors groupe, après *le passif se choisit dans le catalogue, pas dans l usage* :

```dart
  testWidgets('une saisie non entiere est une faute, et rien n est ecrit',
      (tester) async {
    final before = _dataTreeSnapshot(root);
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    final value = find.byKey(const Key('editeur-champ-value'));
    await tester.ensureVisible(value);
    await tester.enterText(value, '1a');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    expect(find.textContaining('n\'est pas un entier'), findsOneWidget);
    expect(_dataTreeSnapshot(root), equals(before));
  });

  testWidgets('une vue brute illisible reste brute, texte intact',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('editeur-bascule-json'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('editeur-json-brut')), '{ pas du json');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final box =
        tester.widget<TextField>(find.byKey(const Key('editeur-json-brut')));
    expect(box.controller!.text, '{ pas du json');
    expect(find.textContaining('ne se relit pas'), findsOneWidget);
  });

  testWidgets('ajouter un effet a une carte l ecrit', (tester) async {
    Directory('$root/assets/data/cards').createSync(recursive: true);
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'double_coup');
    final add = find.byKey(const Key('editeur-ajouter-effects'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final written = jsonDecode(
      File('$root/assets/data/cards/double_coup.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written['effects'], hasLength(2));
  });

  testWidgets('un son se choisit puis se retire, et aucun n ecrit rien',
      (tester) async {
    File('$root/assets/data/audio.json').writeAsStringSync(
        '{"sounds": {"clang": {"file": "sfx/clang.wav"}}}');
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');

    await tester.ensureVisible(find.text('clang'));
    await tester.tap(find.text('clang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('aucun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final written = jsonDecode(
      File('$root/assets/data/relics/talisman.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written.containsKey('sfx'), isFalse);
  });
```

- [ ] **Step 2 : vérifier l'échec**

Run : `flutter test test/widget/content_editor_screen_test.dart`
Expected : FAIL — `editeur-bascule-json`, `editeur-champ-value`, `editeur-ajouter-effects` introuvables.

- [ ] **Step 3 : implémenter**

**`entity_form.dart`.** Retirer l'import de `color_field.dart`, les paramètres et champs `mechanicsController`, `templateFieldControllers`, `themeColor`, `onThemeColorChanged`, `referenceOptions`, `referenceSelections`, `onReferenceSelected`, et les méthodes `_mechanicsBox`, `_mechanicsFields`, `_themeColorRow`, `_referenceField`. Ajouter au constructeur `required this.mechanics, required this.rawView, required this.onToggleRaw,` et les champs :

```dart
  /// La mecanique : le formulaire infere, ou la vue JSON brute.
  final Widget mechanics;
  final bool rawView;
  final VoidCallback onToggleRaw;
```

Dans `build`, remplacer `if (isModification) _mechanicsBox() else ..._mechanicsFields(),` par :

```dart
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('editeur-bascule-json'),
                    onPressed: onToggleRaw,
                    child: Text(rawView ? 'Formulaire' : 'JSON brut'),
                  ),
                ),
                mechanics,
                if (showSignatureCards) _signatureCards(),
```

Remplacer la liste « Deux visages » de la doc de classe par : `/// **Un seul visage** (spec D6) : creation et modification partagent le formulaire infere du document ; seules les pastilles de proprietaire et la recette de classe restent propres a la creation.`

**`content_editor_screen.dart`.**

1. Imports : ajouter `'../../services/content_editor/audio_catalog.dart'`, `'../../services/content_editor/editor_document.dart'`, `'../widgets/content_editor/asset_field.dart'`, `'../widgets/content_editor/document_form.dart'`. Retirer `_kUnsetThemeColor`.
2. État : retirer `_mechanics`, `_mechanicsFields`, `_themeColor`, `_referenceSelections`. Ajouter :

```dart
  /// Le document de la mecanique — voir `EditorDocument`.
  EditorDocument? _document;

  /// Change a chaque remplacement ou changement de structure du document :
  /// `DocumentForm` est alors recree, ses controleurs avec lui.
  int _revision = 0;

  /// La vue « JSON brut », et son texte.
  bool _rawView = false;
  final TextEditingController _raw = TextEditingController();

  /// Les sons d'`audio.json`, lus avec le catalogue de la categorie.
  List<String> _soundIds = const [];
```

3. `dispose` : retirer les boucles sur `_mechanics` / `_mechanicsFields`, ajouter `_raw.dispose();`.
4. Ajouter :

```dart
  /// Remplace le document, et referme la vue brute.
  void _seedDocument(Map<String, dynamic> seed) {
    _document = EditorDocument(
      seed,
      requiredKeys: _descriptor.requiredKeys,
      template: _descriptor.decodeTemplate(),
    );
    _revision++;
    _rawView = false;
  }

  /// Le texte que juge la validation : la vue brute telle quelle, ou le
  /// document, regle d'omission appliquee.
  String _mechanicsText() => _rawView ? _raw.text : _document!.toMechanics();

  void _toggleRaw() {
    if (!_rawView) {
      setState(() {
        _raw.text = _indented.convert(_document!.root);
        _rawView = true;
      });
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(_raw.text);
    } on FormatException catch (e) {
      _refuse('le JSON brut ne se relit pas : ${e.message}');
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      _refuse('le JSON brut ne se relit pas : il doit être un objet');
      return;
    }
    setState(() {
      _seedDocument(decoded);
      _faults = const [];
    });
  }
```

5. `_loadCategory` : remplacer la ligne `_mechanics.text = _descriptor.template;` et tout le bloc `_mechanicsFields` / `themeHex` / `_themeColor` / `_referenceSelections` par `_seedDocument(_descriptor.decodeTemplate());`. Supprimer `_initialFieldText`, `_coerce`, `_composeCreateMechanics`.
6. Niveau « Action », `onSelected` : ajouter après `_targetOwner = null;` les lignes `_seedDocument(_descriptor.decodeTemplate());` et `_loadedPath = null;`.
7. `_draft()` : `mechanics: _mechanicsText(),`. `_recipe()` : `mechanics: _mechanicsText(),`.
8. `_judge` : première ligne de la liste `faults` — `if (!_rawView) ..._document!.conversionFaults,` — avant les fautes de la recette.
9. `_load` : remplacer l'affectation `_mechanics.text = _indented.convert({...});` par :

```dart
      _seedDocument({
        for (final entry in document.entries)
          if (entry.key != 'id' &&
              !_descriptor.isComputedImage(entry.key) &&
              !_prose.containsKey(entry.key))
            entry.key: entry.value,
      });
```

10. `_ensureCatalog` : avant `_ownerJson.clear();`, ajouter `_soundIds = soundIds(fs, root);`.
11. `_entityFormRow` : retirer les arguments supprimés d'`EntityForm`, ajouter `mechanics: _mechanicsView(root), rawView: _rawView, onToggleRaw: _toggleRaw,`. Ajouter :

```dart
  Widget _mechanicsView(String root) {
    if (_rawView) {
      return TextField(
        key: const Key('editeur-json-brut'),
        controller: _raw,
        maxLines: 14,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: const InputDecoration(
          labelText: 'Mécanique (JSON)',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          alignLabelWithHint: true,
        ),
      );
    }
    return DocumentForm(
      key: ValueKey(_revision),
      document: _document!,
      descriptor: _descriptor,
      onChanged: () => setState(() {}),
      onStructureChanged: () => setState(() => _revision++),
      referenceOptions: _references,
      vocabulary: vocabularyOf(_descriptor, _knownValuesFor(root)),
      assetField: _assetField,
    );
  }

  Widget _assetField(String key, AssetSlot slot) {
    final document = _document!;
    if (slot.kind == AssetKind.sound) {
      final value = document.root[key];
      return AssetField(
        fieldKey: key,
        slot: slot,
        value: value is String ? value : null,
        soundIds: _soundIds,
        onSelectSound: (id) => setState(() => document.setAt([key], id)),
        onClear: () => setState(() => document.removeAt([key])),
      );
    }
    final present = slot.isRequired || document.root.containsKey(key);
    return AssetField(
      fieldKey: key,
      slot: slot,
      value: present ? _descriptor.imagePathOf(_id.text.trim(), key) : null,
      onClear: () => setState(() => document.removeAt([key])),
    );
  }
```

- [ ] **Step 4 : vérifier le vert**

Run : `flutter test test/widget/content_editor_screen_test.dart test/widget/content_editor test/unit/content_editor` → PASS. `dart analyze` → propre.

Si *taper dans le champ identifiant ne relit pas le disque* rougit : `_mechanicsView` ne doit lire le disque qu'à travers `_knownValuesFor` et `_ensureCatalog`, tous deux retenus par catégorie.

- [ ] **Step 5 : commit (après validation du lot)**

```bash
git add lib/ui/screens/content_editor_screen.dart lib/ui/widgets/content_editor/entity_form.dart test/widget/content_editor_screen_test.dart
git commit -m "feat(editeur): composer la mecanique depuis le formulaire infere, vue JSON brute"
```

---

## Task 11 : importer un son ou une image

**Files:**
- Create: `lib/services/content_editor/asset_picker.dart`
- Modify: `pubspec.yaml`, `lib/services/content_editor/content_file_system.dart`, `lib/services/content_editor/content_file_system_io.dart`, `lib/services/content_editor/content_editor_providers.dart`, `lib/ui/screens/content_editor_screen.dart`
- Test: `test/widget/content_editor_screen_test.dart`, `test/unit/content_editor/entity_writer_test.dart` (faux système de fichiers)

**Interfaces:**
- Consumes: `PendingImport` (7), `EntityValidator.imports` (8), `writeAll(imports:)` (7), `AssetField` (9).
- Produces : `abstract class AssetPicker { Future<String?> pickFile({required List<String> extensions}); }` ; `FilePickerAssetPicker` ; `assetPickerProvider` ; `Uint8List ContentFileSystem.readBytes(String path)`.

- [ ] **Step 1 : ajouter la dépendance**

Run : `flutter pub add file_picker`
Expected : `file_picker` sous `dependencies:` de `pubspec.yaml`. Lire l'exemple du README de la version résolue (`$LOCALAPPDATA/Pub/Cache/hosted/pub.dev/file_picker-<version>/README.md`) : si l'API n'est plus `FilePicker.platform.pickFiles`, adapter l'étape 4 à ce que le README montre.

- [ ] **Step 2 : écrire les tests qui échouent**

Dans `test/widget/content_editor_screen_test.dart` : importer `package:roguelike_card_game/services/content_editor/asset_picker.dart` ; au harness, ajouter le paramètre `AssetPicker? picker` et l'override `assetPickerProvider.overrideWithValue(picker ?? const _FakePicker(null)),` ; en fin de fichier :

```dart
/// Rend toujours le meme chemin, sans ouvrir de fenetre.
class _FakePicker implements AssetPicker {
  const _FakePicker(this.path);

  final String? path;

  @override
  Future<String?> pickFile({required List<String> extensions}) async => path;
}
```

Ajouter `readBytes` à `_NoProcessFileSystem` (`Uint8List readBytes(String path) => _disk.readBytes(path);`) et à `_CountingFileSystem` (`Uint8List readBytes(String path) { reads++; return _inner.readBytes(path); }`), avec l'import `dart:typed_data`. Dans `entity_writer_test.dart`, `_FlakyFileSystem` : `Uint8List readBytes(String path) => Uint8List.fromList(utf8.encode(files[path]!));` (import `dart:typed_data`).

Tests, en fin de `main()` :

```dart
  group('imports', () {
    const audio = '{\n  "sounds": {\n    "clang": { "file": "sfx/clang.wav" }\n  }\n}\n';

    String sourceFile(String name, String content) {
      final file = File('$root/import/$name')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
      return IoContentFileSystem.toSlashes(file.path);
    }

    Future<void> importSound(WidgetTester tester, String soundId) async {
      final button = find.byKey(const Key('editeur-importer-sfx'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('editeur-import-son-id')), soundId);
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();
    }

    testWidgets('importer un son le copie, le declare et le lie', (tester) async {
      File('$root/assets/data/audio.json').writeAsStringSync(audio);
      final source = sourceFile('clang.wav', 'octets');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');

      await importSound(tester, 'talisman_clang');
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Écrit :'), findsWidgets);
      expect(
        File('$root/assets/audio/sfx/talisman_clang.wav').readAsStringSync(),
        'octets',
      );
      final sounds = (jsonDecode(
        File('$root/assets/data/audio.json').readAsStringSync(),
      ) as Map<String, dynamic>)['sounds'] as Map<String, dynamic>;
      expect(sounds.keys, contains('talisman_clang'));
      expect(
        jsonDecode(File('$root/assets/data/relics/talisman.json')
            .readAsStringSync()),
        containsPair('sfx', 'talisman_clang'),
      );
    });

    testWidgets('un son deja declare est refuse, rien n est copie',
        (tester) async {
      File('$root/assets/data/audio.json').writeAsStringSync(audio);
      final source = sourceFile('clang.wav', 'octets');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');

      await importSound(tester, 'clang');
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(find.textContaining('existe déjà dans audio.json'), findsOneWidget);
      expect(Directory('$root/assets/audio').existsSync(), isFalse);
    });

    testWidgets('importer une image d ennemi remplace son sprite',
        (tester) async {
      Directory('$root/assets/data/enemies/gobelin').createSync(recursive: true);
      File('$root/assets/data/enemies/gobelin/sprite.png')
          .writeAsStringSync('ancienne');
      File('$root/assets/data/enemies/gobelin/enemy.json').writeAsStringSync(
        jsonEncode({
          'id': 'gobelin',
          'name_en': 'Goblin',
          'name_fr': 'Gobelin',
          'maxHp': 30,
          'baseDamage': 5,
          'spritePath': 'assets/data/enemies/gobelin/sprite.png',
          'intents': [
            {'type': 'attack', 'value': 5},
          ],
        }),
      );
      final source = sourceFile('gobelin.png', 'nouvelle');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Ennemi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('gobelin'));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('editeur-importer-spritePath'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(
        File('$root/assets/data/enemies/gobelin/sprite.png').readAsStringSync(),
        'nouvelle',
      );
    });
  });
```

- [ ] **Step 3 : vérifier l'échec**

Run : `flutter test test/widget/content_editor_screen_test.dart --plain-name "imports"`
Expected : échec de compilation (`asset_picker.dart`, `readBytes`, `assetPickerProvider`).

- [ ] **Step 4 : implémenter**

`content_file_system.dart` : importer `dart:typed_data` et ajouter après `readFile` :

```dart
  /// Les octets d'un fichier — l'apercu d'une image, que l'interface ne peut
  /// pas lire elle-meme sans importer `dart:io`.
  Uint8List readBytes(String path);
```

`content_file_system_io.dart` : `@override Uint8List readBytes(String path) => File(path).readAsBytesSync();` (import `dart:typed_data`).

`lib/services/content_editor/asset_picker.dart` :

```dart
import 'package:file_picker/file_picker.dart';

/// Le choix d'un fichier par l'usager. Seam injectable : les tests le
/// remplacent, pour qu'aucune fenetre ne s'ouvre (spec §5.5).
abstract class AssetPicker {
  /// Chemin absolu choisi, ou `null` si l'usager annule.
  Future<String?> pickFile({required List<String> extensions});
}

/// L'implementation reelle, sur `file_picker`.
class FilePickerAssetPicker implements AssetPicker {
  const FilePickerAssetPicker();

  @override
  Future<String?> pickFile({required List<String> extensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    return result?.files.single.path;
  }
}
```

`content_editor_providers.dart` : importer `asset_picker.dart` et ajouter :

```dart
/// Le selecteur de fichier de l'editeur. Surcharge dans les tests.
final assetPickerProvider =
    Provider<AssetPicker>((ref) => const FilePickerAssetPicker());
```

`content_editor_screen.dart` :

1. Imports : `dart:typed_data`, `'../../services/content_editor/pending_import.dart'`.
2. État :

```dart
  /// Les imports en attente d'« Écrire » : cle de ressource -> fichier choisi.
  /// La destination est recalculee au moment de juger, l'identifiant pouvant
  /// changer d'ici la.
  final Map<String, String> _importSources = {};
  final Map<String, String> _importSoundIds = {};

  /// Les octets d'image deja lus, par chemin : une carte de classe pese
  /// 6,5 Mo, et `build` est relance a chaque frappe.
  final Map<String, Uint8List?> _images = {};
```

3. Vider `_importSources`, `_importSoundIds` et `_images` là où une **autre entité** prend la place : dans `_loadCategory`, dans le `onSelected` du niveau « Action », dans `_load`, et après une écriture réussie dans `_write` (à côté de `_catalogFor = null;`). **Pas dans `_seedDocument`** : le retour de la vue brute le rappelle, et effacerait un import que le document référence encore.
4. Ajouter :

```dart
  List<PendingImport> _pendingImports() {
    final id = _id.text.trim();
    return [
      for (final entry in _importSources.entries)
        if (_descriptor.assetKeys[entry.key]!.kind == AssetKind.sound)
          PendingImport.sound(
            key: entry.key,
            sourcePath: entry.value,
            soundId: _importSoundIds[entry.key]!,
          )
        else
          PendingImport.image(
            descriptor: _descriptor,
            id: id,
            key: entry.key,
            sourcePath: entry.value,
          ),
    ];
  }

  Future<void> _importAsset(String key, AssetSlot slot) async {
    final picked =
        await ref.read(assetPickerProvider).pickFile(extensions: slot.extensions);
    if (picked == null || !mounted) return;
    final source = picked.replaceAll(r'\', '/');

    if (slot.kind == AssetKind.sound) {
      final soundId = await showDialog<String>(
        context: context,
        builder: (_) => _SoundIdDialog(initial: _id.text.trim()),
      );
      if (soundId == null || soundId.isEmpty || !mounted) return;
      setState(() {
        _importSources[key] = source;
        _importSoundIds[key] = soundId;
        _document!.setAt([key], soundId);
      });
      return;
    }

    setState(() {
      _importSources[key] = source;
      // Une image optionnelle (`iconPath`) n'est ecrite que si le corps la
      // porte : l'importer la fait entrer. Pas avec `''`, que la regle
      // d'omission retirerait — avec le chemin, que `compose()` recalcule.
      if (!slot.isRequired) {
        _document!.setAt([key], _descriptor.imagePathOf(_id.text.trim(), key));
      }
      _images.remove(source);
    });
  }

  Uint8List? _bytesOf(String absolute) => _images.putIfAbsent(absolute, () {
        final fs = ref.read(contentFileSystemProvider)!;
        return fs.fileExists(absolute) ? fs.readBytes(absolute) : null;
      });
```

Le chemin posé pour `iconPath` est recalculé par `compose()` (tâche 5), qui écrit toute image optionnelle présente dans le corps avec l'identifiant du moment.

5. `_judge` : `EntityValidator(…, imports: _pendingImports())`. `_write` : `writer.writeAll(drafts, imports: _pendingImports())`.
6. `_mechanicsView` : `assetField: (key, slot) => _assetField(root, key, slot),`. Remplacer `_assetField` :

```dart
  Widget _assetField(String root, String key, AssetSlot slot) {
    final document = _document!;
    final source = _importSources[key];
    final pending = source == null
        ? null
        : 'à importer : ${source.substring(source.lastIndexOf('/') + 1)}';

    if (slot.kind == AssetKind.sound) {
      final value = document.root[key];
      return AssetField(
        fieldKey: key,
        slot: slot,
        value: value is String ? value : null,
        soundIds: _soundIds,
        pendingLabel: pending,
        onSelectSound: (id) => setState(() {
          _importSources.remove(key);
          _importSoundIds.remove(key);
          document.setAt([key], id);
        }),
        onClear: () => setState(() {
          _importSources.remove(key);
          _importSoundIds.remove(key);
          document.removeAt([key]);
        }),
        onImport: () => _importAsset(key, slot),
      );
    }

    final id = _id.text.trim();
    final relative = _descriptor.imagePathOf(id, key);
    final present = slot.isRequired || document.root.containsKey(key);
    return AssetField(
      fieldKey: key,
      slot: slot,
      value: present ? relative : null,
      imageBytes: source != null
          ? _bytesOf(source)
          : (present && id.isNotEmpty && relative != null
              ? _bytesOf('$root/$relative')
              : null),
      pendingLabel: pending,
      onClear: () => setState(() {
        _importSources.remove(key);
        document.removeAt([key]);
      }),
      onImport: () => _importAsset(key, slot),
    );
  }
```

7. En fin de fichier :

```dart
/// Demande l'identifiant d'un son importe. Un `StatefulWidget` pour que son
/// controleur vive exactement autant que le dialogue — le liberer a la
/// fermeture le ferait servir, dispose, pendant l'animation de sortie.
class _SoundIdDialog extends StatefulWidget {
  const _SoundIdDialog({required this.initial});

  final String initial;

  @override
  State<_SoundIdDialog> createState() => _SoundIdDialogState();
}

class _SoundIdDialogState extends State<_SoundIdDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Identifiant du son'),
      content: TextField(
        key: const Key('editeur-import-son-id'),
        controller: _controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Importer'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5 : vérifier le vert**

Run : `flutter test test/widget test/unit/content_editor` → PASS. `dart analyze` → propre.

- [ ] **Step 6 : commit (après validation du lot)**

```bash
git add pubspec.yaml pubspec.lock lib/services/content_editor/asset_picker.dart lib/services/content_editor/content_file_system.dart lib/services/content_editor/content_file_system_io.dart lib/services/content_editor/content_editor_providers.dart lib/ui/screens/content_editor_screen.dart test/widget/content_editor_screen_test.dart test/unit/content_editor/entity_writer_test.dart
git commit -m "feat(editeur): importer un son ou une image depuis le formulaire"
```

---

## Task 12 : vérification de bout en bout

**Files:** aucun fichier nouveau.

- [ ] **Step 1 : la suite complète et l'analyse**

Run : `dart analyze` → `No issues found!`
Run : `flutter test` → tous les tests passent. Relever le `+N` final pour le rapport.

- [ ] **Step 2 : le garde-fou audio sur le contenu réel**

Run : `flutter test test/unit/audio/audio_catalogue_test.dart` → PASS : aucune entité livrée ne porte de `sfx` non déclaré.

- [ ] **Step 3 : le build web n'importe pas `dart:io` hors du seam**

Run : `grep -rn "import 'dart:io'" lib`
Expected : une seule ligne, `lib/services/content_editor/content_file_system_io.dart`.

- [ ] **Step 4 : vérification manuelle, par le propriétaire, sous Windows (`flutter run -d windows`)**

À faire dans une arborescence de travail jetable ou avec des entités de test supprimées ensuite :

1. Créer une carte : le formulaire montre `rarity`, `target`, `type` en boutons, `effects` en cartes avec « Ajouter ». Écrire, puis vérifier le fichier : ni `sfx`, ni `spritePath`.
2. Modifier une carte livrée : ses valeurs apparaissent ; « JSON brut » montre le même document.
3. Créer une relique et importer un son : le `.wav` est copié sous `assets/audio/sfx/`, `audio.json` gagne une ligne et **aucune autre ne bouge** (`git diff assets/data/audio.json`).
4. Modifier un ennemi et importer une image : l'aperçu montre la nouvelle image ; après un redémarrage à chaud, l'ennemi l'affiche en combat.
5. Saisir `"type": "skill"` dans un effet par la vue brute : « Écrire » refuse avec `effects[0].type`.

- [ ] **Step 5 : proposer les lots de commit au propriétaire**

Lister les commits des tâches 1 à 11 non encore faits, avec leurs fichiers, et attendre la validation. Rappeler que la spec et ce plan se commitent ensemble, et que `memory-bank-sync` documentera la livraison ensuite.

---

## Auto-revue du plan

**Couverture de la spec.** D1/§3.1 → tâche 1. D2/§3.2 → tâche 1 (exclusion nommée, `CardData` intact). D3/§3.3 → tâche 2 (`toMechanics`), doublée par la tâche 8 (`"sfx": ""` refusé). §3.4 → tâche 1. D4/§4.1 → tâches 2 et 10. D5/§4.2 → tâches 9 et 10 (clés du document, ressources et références absentes). §4.3 → tâches 4 et 9. §4.4/§4.5, D8 → tâche 3. D6 → tâche 10. D7 → tâches 2, 9, 10. D9/§5.1 → tâches 1 et 5. D10/§5.2 → tâches 6, 7, 11. D11/§5.3 → tâches 7, 9, 11. D12/§5.4 → tâche 7. D13/§5.5 → tâche 11. §5.6 → tâche 8. Tests §6 : 1 → tâche 1 ; 2 → tâche 1 ; 3 → tâche 2 ; 4 → tâche 4 ; 5 → tâches 9 et 10 ; 6 → tâche 10 ; 7 → tâche 10 ; 8 → tâche 3 ; 9 → tâche 3 ; 10 → tâche 10 ; 11 → tâches 7 et 11 ; 12 → tâche 11 ; 13 → tâche 7 ; 14 → tâches 7 et 11.

**Cohérence des noms.** `AssetSlot.isRequired` (tâches 1, 5, 8, 9, 11) ; `imagePathOf(id, key)` (5, 7, 8, 10, 11) ; `PendingImport.sound(key:, sourcePath:, soundId:)` (7, 8, 11) ; `writeAll(drafts, imports:)` (7, 11) ; `EntityValidator(imports:)` (8, 11) ; `DocumentForm(onChanged:, onStructureChanged:, assetField:)` (9, 10) ; clés de widget `editeur-champ-<libellé>`, `editeur-ajouter-<libellé>`, `editeur-importer-<clé>`, `editeur-bascule-json`, `editeur-json-brut`, `editeur-import-son-id` (9, 10, 11).

**Risques d'exécution signalés.** API de `file_picker` selon la version résolue (tâche 11, étape 1) ; syntaxe `?element` et jokers (tâche 9, note) ; le test *taper dans le champ identifiant ne relit pas le disque* surveille que le formulaire inféré ne relise pas le disque à chaque frappe (tâches 10, 11 : lectures retenues par catégorie et par chemin).
