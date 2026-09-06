# Menu de debug — lot 2 : éditeur de contenu — Plan d'implémentation

> **Pour les agents exécutants :** SOUS-COMPÉTENCE REQUISE — utiliser
> `superpowers:subagent-driven-development` (recommandé) ou `superpowers:executing-plans`
> pour dérouler ce plan tâche par tâche. Les étapes sont cochables (`- [ ]`).

**But :** pouvoir créer et modifier, depuis le jeu et hors run, les sept catégories d'entités du
dépôt — carte, classe, ennemi, événement, passif, relique, amélioration de forge — en écrivant des
fichiers JSON qui franchissent les mêmes gardes que ceux écrits à la main.

**Architecture :** quatre unités sans état partagé. `ProjectRoot` trouve l'arborescence source
depuis l'exécutable ; `EntityDescriptor` décrit chaque catégorie de façon déclarative ;
`EntityValidator` refuse tout ce qui ne doit pas être écrit ; `EntityWriter` écrit et enchaîne les
effets de bord. Toutes reçoivent un `ContentFileSystem` en paramètre — le joint qui les rend
testables et qui isole `dart:io`.

**Pile technique :** Flutter, Riverpod 2.x (`Notifier` / `NotifierProvider`), `flutter_test`,
`dart:io` derrière un import conditionnel. **Aucune dépendance nouvelle.**

**Spec :** [`docs/superpowers/specs/2026-09-06-menu-debug-lot-2-editeur-de-contenu-design.md`](../specs/2026-09-06-menu-debug-lot-2-editeur-de-contenu-design.md)

---

> [!IMPORTANT]
> **Un écart à la spec, décidé après vérification du dépôt, et qui la précède en autorité.**
>
> La spec fait recevoir à `EntityWriter` un `Directory` de `dart:io` (§3.4). C'est impossible tel
> quel : **le jeu est publié en build web** — `web/` existe et le site distribue des URL jouables —
> et **`lib/` n'importe aujourd'hui `dart:io` nulle part**. Un import direct casserait cette cible,
> et il casserait le *produit*, pas seulement une commande de build.
>
> Le plan introduit donc une interface `ContentFileSystem` portant les huit opérations dont
> l'éditeur a besoin, choisie par **import conditionnel** : l'implémentation `dart:io` sur les
> plateformes qui en disposent, `null` sur le web — où l'éditeur refuse alors de s'ouvrir, du même
> refus que lorsqu'il ne trouve pas la racine (§3.1 de la spec).
>
> Bénéfice second, non recherché : les unités qui écrivent ne mentionnent plus aucun type de
> `dart:io`, et le chemin de la racine circule comme une simple `String`.
>
> **Une famille de validation s'ajoute aux six de la spec §3.3** : les **références**.
> `referential_integrity_test.dart:35` exige que `passiveTrait` désigne un passif existant ; une
> classe écrite avec une référence pendante casserait la suite. Elle est déclarative comme les
> autres, et passe avant la construction, qui reste la dernière.

---

## Contraintes globales

- **`dart analyze` doit rendre zéro problème** après chaque tâche, avant tout commit.
- **`dart:io` n'est importé que dans `content_file_system_io.dart`.** Aucun autre fichier de `lib/`
  ne doit le mentionner. Une tâche qui semble en réclamer un second import se trompe : l'opération
  manquante s'ajoute à l'interface.
- **Aucune dépendance nouvelle.** Ni sélecteur de fichiers, ni `package:path` — les chemins se
  composent avec `/`, que les API de `dart:io` acceptent sous Windows comme ailleurs.
- **Une seule convention de séparateur : `/`.** Toute valeur venant de la plateforme est normalisée
  à l'entrée (`replaceAll('\\', '/')`), jamais comparée telle quelle.
- **Rien n'est écrit avant que la validation entière passe** (décision **E6** de la spec). Un
  fichier à demi écrit fait échouer le chargement de toute sa catégorie.
- **Pas de localisation ARB pour cet éditeur.** Les libellés sont en français directement dans le
  code, comme pour le lot 1 — exception délibérée, limitée à `lib/ui/screens/content_editor_screen.dart`
  et `lib/ui/widgets/content_editor/`.
- **Tout point d'entrée UI est enveloppé dans `if (kDebugMode)`**, constante de compilation, pour
  que le sous-arbre soit éliminé au tree-shaking en release.
- **Messages de commit en français**, conventional commits, **sans accents dans la ligne de sujet**
  (le corps peut en porter), terminés par
  `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Branche de travail : `feat/menu-debug-lot-2`, déjà créée.

---

## Structure des fichiers

| Fichier | Responsabilité |
|:---|:---|
| `lib/services/content_editor/content_file_system.dart` *(créé)* | L'interface, et `ProcessOutcome`. Aucun `dart:io` |
| `lib/services/content_editor/content_file_system_io.dart` *(créé)* | **Le seul fichier de `lib/` qui importe `dart:io`** |
| `lib/services/content_editor/content_file_system_stub.dart` *(créé)* | Le bouchon web : aucune implémentation |
| `lib/services/content_editor/platform_file_system.dart` *(créé)* | L'import conditionnel, et lui seul |
| `lib/services/content_editor/project_root.dart` *(créé)* | La remontée vers l'arborescence source |
| `lib/services/content_editor/entity_descriptor.dart` *(créé)* | La table déclarative des sept catégories |
| `lib/services/content_editor/entity_draft.dart` *(créé)* | Ce que l'écran compose et que le validateur juge |
| `lib/services/content_editor/entity_validator.dart` *(créé)* | Sept familles, dans l'ordre, arrêt à la première en échec |
| `lib/services/content_editor/entity_writer.dart` *(créé)* | L'écriture, ses effets de bord, et le retour en arrière |
| `lib/ui/screens/content_editor_screen.dart` *(créé)* | L'écran |
| `lib/ui/widgets/content_editor/*.dart` *(créés)* | Les morceaux de l'écran |
| `lib/ui/screens/home_screen.dart` *(modifié)* | Le bouton d'entrée, sous `kDebugMode` |
| `assets/images/placeholder_entity.png` *(créé)* | L'image déposée dans un dossier de classe ou d'ennemi |

Les tests vivent sous `test/unit/content_editor/`, sur le précédent de `test/unit/audio/`.

---

### Task 1 : Le seam de plateforme et la racine du projet

**Files:**
- Create: `lib/services/content_editor/content_file_system.dart`
- Create: `lib/services/content_editor/content_file_system_io.dart`
- Create: `lib/services/content_editor/content_file_system_stub.dart`
- Create: `lib/services/content_editor/platform_file_system.dart`
- Create: `lib/services/content_editor/project_root.dart`
- Test: `test/unit/content_editor/project_root_test.dart`

**Interfaces:**
- Consumes: rien.
- Produces: `ContentFileSystem` (interface), `ProcessOutcome(int exitCode, String output)`,
  `IoContentFileSystem`, `ContentFileSystem? platformFileSystem()`,
  `ProjectRoot.find(ContentFileSystem)`, `ProjectRoot.findFrom(ContentFileSystem, String)`,
  `ProjectRoot.isProjectRoot(ContentFileSystem, String)`.

- [ ] **Step 1 : Écrire l'interface**

Fichier `lib/services/content_editor/content_file_system.dart` :

```dart
import 'package:meta/meta.dart';

/// Ce que rend un processus lance par l'editeur.
@immutable
class ProcessOutcome {
  const ProcessOutcome(this.exitCode, this.output);

  final int exitCode;
  final String output;

  bool get succeeded => exitCode == 0;
}

/// Les seules operations disque dont l'editeur de contenu a besoin.
///
/// Cette abstraction existe pour une raison de plateforme, et une seule :
/// `lib/` n'importait jusqu'ici `dart:io` nulle part, et le jeu est publie en
/// build web. Un import direct casserait cette cible. L'implementation reelle
/// est choisie par import conditionnel dans `platform_file_system.dart` ; sur
/// le web il n'y en a aucune, et l'editeur refuse de s'ouvrir.
///
/// Les chemins sont **toujours** separes par `/`, y compris sous Windows : les
/// API de `dart:io` l'acceptent, et une convention unique evite d'avoir a
/// normaliser a chaque comparaison.
abstract class ContentFileSystem {
  /// Repertoire d'ou part la remontee vers la racine du projet.
  String get startDirectory;

  bool fileExists(String path);

  bool directoryExists(String path);

  String readFile(String path);

  void writeFile(String path, String contents);

  void deleteFile(String path);

  /// Cree [path] et tous ses parents manquants.
  void createDirectory(String path);

  void copyFile(String from, String to);

  /// Les noms des entrees de [path], sans leur chemin. Rend une liste vide si
  /// le repertoire n'existe pas — l'appelant n'a pas a s'en premunir.
  List<String> listDirectory(String path);

  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  });
}
```

- [ ] **Step 2 : Écrire l'implémentation `dart:io`**

Fichier `lib/services/content_editor/content_file_system_io.dart` :

```dart
import 'dart:io';

import 'content_file_system.dart';

/// **Le seul fichier de `lib/` qui importe `dart:io`.** Il n'est compile que
/// sur les plateformes qui en disposent, l'import etant conditionnel dans
/// `platform_file_system.dart`.
class IoContentFileSystem implements ContentFileSystem {
  const IoContentFileSystem();

  @override
  String get startDirectory =>
      toSlashes(File(Platform.resolvedExecutable).parent.path);

  @override
  bool fileExists(String path) => File(path).existsSync();

  @override
  bool directoryExists(String path) => Directory(path).existsSync();

  @override
  String readFile(String path) => File(path).readAsStringSync();

  @override
  void writeFile(String path, String contents) =>
      File(path).writeAsStringSync(contents);

  @override
  void deleteFile(String path) => File(path).deleteSync();

  @override
  void createDirectory(String path) =>
      Directory(path).createSync(recursive: true);

  @override
  void copyFile(String from, String to) => File(from).copySync(to);

  @override
  List<String> listDirectory(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) return const [];
    return directory
        .listSync()
        .map((entity) => toSlashes(entity.path).split('/').last)
        .toList();
  }

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    // `runInShell: true` est INDISPENSABLE. L'hote de `flutter test` n'est pas
    // un shell : sans ce drapeau, `Process.run` leve une `ProcessException`
    // sous Windows. Meme constat, meme remede que dans
    // `test/unit/sync_assets_test.dart`.
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    return ProcessOutcome(
      result.exitCode,
      '${result.stdout}${result.stderr}',
    );
  }

  /// Windows rend des chemins a antislash ; tout le reste de l'editeur n'en
  /// connait qu'un seul, `/`.
  static String toSlashes(String path) => path.replaceAll('\\', '/');
}

/// Consomme par l'import conditionnel de `platform_file_system.dart`.
ContentFileSystem? create() => const IoContentFileSystem();
```

- [ ] **Step 3 : Écrire le bouchon et l'import conditionnel**

Fichier `lib/services/content_editor/content_file_system_stub.dart` :

```dart
import 'content_file_system.dart';

/// Plateforme sans systeme de fichiers accessible — le web. Aucune
/// implementation n'est possible, et l'editeur refuse de s'ouvrir plutot que
/// de faire semblant d'ecrire.
ContentFileSystem? create() => null;
```

Fichier `lib/services/content_editor/platform_file_system.dart` :

```dart
import 'content_file_system.dart';
import 'content_file_system_stub.dart'
    if (dart.library.io) 'content_file_system_io.dart' as impl;

/// L'implementation de la plateforme courante, ou `null` sur le web.
///
/// **Seul endroit du depot ou l'import conditionnel est ecrit.** L'ajouter
/// ailleurs ferait entrer `dart:io` dans un second fichier.
ContentFileSystem? platformFileSystem() => impl.create();
```

- [ ] **Step 4 : Écrire le test de la racine (il doit échouer)**

Fichier `test/unit/content_editor/project_root_test.dart` :

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/project_root.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('project_root_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
    File('$root/pubspec.yaml').writeAsStringSync('name: test\n');
    Directory('$root/assets/data').createSync(recursive: true);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  test('remonte depuis le repertoire de build jusqu a la racine', () {
    final deep = '$root/build/windows/x64/runner/Debug';
    Directory(deep).createSync(recursive: true);

    expect(ProjectRoot.findFrom(fs, deep), root);
  });

  test('rend la racine elle-meme quand on y est deja', () {
    expect(ProjectRoot.findFrom(fs, root), root);
  });

  test('un pubspec sans assets/data n est pas une racine', () {
    final decoy = Directory('$root/decoy')..createSync();
    File('${decoy.path}/pubspec.yaml').writeAsStringSync('name: decoy\n');

    // La remontee ne s'arrete pas sur le leurre : elle continue jusqu'a la
    // vraie racine, qui porte les deux marqueurs.
    expect(
      ProjectRoot.findFrom(fs, IoContentFileSystem.toSlashes(decoy.path)),
      root,
    );
  });

  test('rend null quand aucun parent ne porte les deux marqueurs', () {
    final orphan = Directory.systemTemp.createTempSync('orphan_');
    addTearDown(() => orphan.deleteSync(recursive: true));

    expect(
      ProjectRoot.findFrom(fs, IoContentFileSystem.toSlashes(orphan.path)),
      isNull,
    );
  });

  test('les antislash de Windows sont normalises a l entree', () {
    final deep = '$root/build/windows';
    Directory(deep).createSync(recursive: true);

    expect(ProjectRoot.findFrom(fs, deep.replaceAll('/', '\\')), root);
  });
}
```

- [ ] **Step 5 : Lancer le test et vérifier qu'il échoue**

Commande : `flutter test test/unit/content_editor/project_root_test.dart`
Attendu : ÉCHEC — `project_root.dart` n'existe pas encore.

- [ ] **Step 6 : Écrire `ProjectRoot`**

Fichier `lib/services/content_editor/project_root.dart` :

```dart
import 'content_file_system.dart';

/// Trouve la racine de l'arborescence **source** du projet.
///
/// L'application tourne depuis `build/<plateforme>/.../runner/Debug/`, alors
/// que les donnees que l'editeur modifie vivent dans l'arborescence source. On
/// remonte donc depuis le repertoire de l'executable jusqu'au premier
/// repertoire portant a la fois `pubspec.yaml` et `assets/data/`.
///
/// **Deux marqueurs et non un** : `pubspec.yaml` seul se trouve aussi dans le
/// cache des paquets, ou l'on n'a rien a ecrire.
class ProjectRoot {
  const ProjectRoot._();

  /// Nombre maximal de niveaux remontes. Le chemin reel en compte cinq ou six ;
  /// la borne evite de balayer le volume entier quand la racine n'existe pas.
  static const int maxDepth = 12;

  /// La racine, ou `null` si l'application ne tourne pas depuis une
  /// arborescence source. L'editeur refuse alors de s'ouvrir : mieux vaut ne
  /// rien pouvoir faire que d'ecrire au hasard.
  static String? find(ContentFileSystem fs) =>
      findFrom(fs, fs.startDirectory);

  static String? findFrom(ContentFileSystem fs, String from) {
    var current = _trimTrailingSlash(from.replaceAll('\\', '/'));
    for (var level = 0; level < maxDepth; level++) {
      if (isProjectRoot(fs, current)) return current;
      final cut = current.lastIndexOf('/');
      if (cut <= 0) return null;
      current = current.substring(0, cut);
    }
    return null;
  }

  static bool isProjectRoot(ContentFileSystem fs, String directory) =>
      fs.fileExists('$directory/pubspec.yaml') &&
      fs.directoryExists('$directory/assets/data');

  static String _trimTrailingSlash(String path) =>
      path.length > 1 && path.endsWith('/')
          ? path.substring(0, path.length - 1)
          : path;
}
```

- [ ] **Step 7 : Lancer le test et vérifier qu'il passe**

Commande : `flutter test test/unit/content_editor/project_root_test.dart`
Attendu : SUCCÈS, 5 tests.

- [ ] **Step 8 : Vérifier que `dart:io` reste confiné**

Commande : `grep -rn "import 'dart:io'" lib/`
Attendu : **exactement une ligne**, dans `content_file_system_io.dart`.

Puis : `dart analyze`
Attendu : `No issues found!`

- [ ] **Step 9 : Commit**

```bash
git add lib/services/content_editor/ test/unit/content_editor/
git commit -m "feat(editeur): isoler dart:io derriere un seam et trouver la racine du projet"
```

---

### Task 2 : La table déclarative des sept catégories

**Files:**
- Create: `lib/services/content_editor/entity_descriptor.dart`
- Test: `test/unit/content_editor/entity_descriptor_test.dart`

**Interfaces:**
- Consumes: rien de la Task 1 — cette unité est pure.
- Produces: `enum EntityCategory { card, relic, event, passive, forgeUpgrade, heroClass, enemy }` ;
  `class EntityDescriptor` avec les champs `category`, `label`, `directory`, `folderFile`,
  `imageName`, `imagePathKey`, `supportsHeroClass`, `requiredKeys`, `forbiddenKeys`, `enumKeys`,
  `enumListKeys`, `referenceKeys`, `bilingualBases`, `construct`, `template` ; la méthode
  `String pathOf(String id, {String? heroClass})` ; et la constante
  `Map<EntityCategory, EntityDescriptor> kEntityDescriptors`.

- [ ] **Step 1 : Écrire le test (il doit échouer)**

Fichier `test/unit/content_editor/entity_descriptor_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';

void main() {
  test('les descripteurs couvrent les sept categories chargeables', () {
    // `loadGameDataRegistry` declare sept categories d'entites (l'audio n'en
    // est pas une). Une source ajoutee la-bas sans descripteur ici rendrait
    // une categorie du jeu ineditable sans que rien ne le signale.
    expect(kEntityDescriptors.keys.toSet(), EntityCategory.values.toSet());
    expect(EntityCategory.values, hasLength(7));
  });

  test('chaque descripteur est indexe sous sa propre categorie', () {
    kEntityDescriptors.forEach((key, descriptor) {
      expect(descriptor.category, key);
    });
  });

  group('pathOf', () {
    test('une carte neutre va dans cards/', () {
      expect(
        kEntityDescriptors[EntityCategory.card]!.pathOf('coup_bas'),
        'assets/data/cards/coup_bas.json',
      );
    });

    test('une carte de classe va dans le dossier de sa classe', () {
      expect(
        kEntityDescriptors[EntityCategory.card]!
            .pathOf('smite', heroClass: 'paladin'),
        'assets/data/classes/paladin/cards/smite.json',
      );
    });

    test('une relique va dans relics/', () {
      expect(
        kEntityDescriptors[EntityCategory.relic]!.pathOf('talisman'),
        'assets/data/relics/talisman.json',
      );
    });

    test('une classe est un dossier portant class.json', () {
      expect(
        kEntityDescriptors[EntityCategory.heroClass]!.pathOf('barde'),
        'assets/data/classes/barde/class.json',
      );
    });

    test('un ennemi est un dossier portant enemy.json', () {
      expect(
        kEntityDescriptors[EntityCategory.enemy]!.pathOf('troll'),
        'assets/data/enemies/troll/enemy.json',
      );
    });
  });

  test('les cles enumerees viennent des enumerations reelles', () {
    // Le point de la decision E3 : si `CardRarity` gagne une valeur, le
    // descripteur la connait sans qu'on l'ait recopiee.
    expect(
      kEntityDescriptors[EntityCategory.card]!.enumKeys['rarity'],
      CardRarity.values.map((e) => e.name).toList(),
    );
  });

  test('la carte interdit les champs que le repertoire impose', () {
    expect(
      kEntityDescriptors[EntityCategory.card]!.forbiddenKeys,
      {'heroClass', 'category'},
    );
  });

  test('les gabarits sont du JSON valide et ne portent aucun champ interdit',
      () {
    for (final descriptor in kEntityDescriptors.values) {
      final decoded = descriptor.decodeTemplate();
      for (final forbidden in descriptor.forbiddenKeys) {
        expect(
          decoded.containsKey(forbidden),
          isFalse,
          reason: '${descriptor.label} : gabarit portant "$forbidden"',
        );
      }
    }
  });

  test('seule la carte accepte une classe', () {
    final withClass = kEntityDescriptors.values
        .where((d) => d.supportsHeroClass)
        .map((d) => d.category)
        .toList();
    expect(withClass, [EntityCategory.card]);
  });

  test('seules la classe et l ennemi sont des dossiers a image', () {
    final withImage = kEntityDescriptors.values
        .where((d) => d.imageName != null)
        .map((d) => d.category)
        .toSet();
    expect(withImage, {EntityCategory.heroClass, EntityCategory.enemy});

    for (final category in withImage) {
      final descriptor = kEntityDescriptors[category]!;
      expect(descriptor.folderFile, isNotNull);
      expect(descriptor.imagePathKey, isNotNull);
    }
  });
}
```

- [ ] **Step 2 : Lancer le test et vérifier qu'il échoue**

Commande : `flutter test test/unit/content_editor/entity_descriptor_test.dart`
Attendu : ÉCHEC — `entity_descriptor.dart` n'existe pas.

- [ ] **Step 3 : Écrire le squelette du descripteur**

Fichier `lib/services/content_editor/entity_descriptor.dart`, première moitié :

```dart
import 'dart:convert';

import 'package:meta/meta.dart';

import '../../models/data/card_data.dart';
import '../../models/data/enemy_data.dart';
import '../../models/data/event_data.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/data/relic_data.dart';

/// Les sept categories d'entites editables. Elles sont en regard exact des
/// sept appels a `loadAll` de `loadGameDataRegistry` — l'audio n'en est pas
/// une, c'est un document de configuration.
enum EntityCategory { card, relic, event, passive, forgeUpgrade, heroClass, enemy }

/// Ce qu'est une categorie : un chemin, des cles, et un `fromJson`.
///
/// Tout ce qui distingue une categorie d'une autre tient dans cette table.
/// Aucune de ces informations n'a besoin d'etre du code, et aucune ne doit
/// etre recopiee ailleurs.
@immutable
class EntityDescriptor {
  const EntityDescriptor({
    required this.category,
    required this.label,
    required this.directory,
    required this.requiredKeys,
    required this.bilingualBases,
    required this.construct,
    required this.template,
    this.forbiddenKeys = const {},
    this.enumKeys = const {},
    this.enumListKeys = const {},
    this.referenceKeys = const {},
    this.supportsHeroClass = false,
    this.folderFile,
    this.imageName,
    this.imagePathKey,
  });

  final EntityCategory category;

  /// Le nom montre a l'ecran. Au singulier.
  final String label;

  /// Le repertoire sous `assets/data/`.
  final String directory;

  /// Les cles sans lesquelles l'entite n'a pas de sens. `id` n'y figure pas :
  /// il vient du triangle d'identite, pas du corps.
  final Set<String> requiredKeys;

  /// Les cles que le repertoire impose et qu'un fichier ne doit pas porter.
  /// Voir `EntitySource.redundantFields` : seul `id` est redeclarable.
  final Set<String> forbiddenKeys;

  /// Cle -> valeurs admises, lues sur l'enumeration Dart reelle.
  final Map<String, List<String>> enumKeys;

  /// Comme [enumKeys], pour une cle portant une **liste** de valeurs.
  final Map<String, List<String>> enumListKeys;

  /// Cle -> categorie que sa valeur doit designer. `passiveTrait` pointe un
  /// passif, et `referential_integrity_test` le verifie deja.
  final Map<String, EntityCategory> referenceKeys;

  /// Les bases dont les deux variantes `_fr` et `_en` sont exigees. Elles ne
  /// sont **pas** les memes partout : un evenement porte `title`, un ennemi
  /// n'a pas de description.
  final List<String> bilingualBases;

  /// Le `fromJson` reel du modele. Il ne rend rien : on ne l'appelle que pour
  /// savoir s'il leve.
  final void Function(Map<String, dynamic> json) construct;

  /// La mecanique pre-remplie, montree dans l'editeur au moment de creer.
  final String template;

  /// Vrai pour la seule carte, qui peut etre neutre ou appartenir a une classe.
  final bool supportsHeroClass;

  /// Pour les categories qui sont un **dossier** : le nom du fichier qu'il
  /// porte (`class.json`, `enemy.json`).
  final String? folderFile;

  /// Le nom de l'image que ce dossier doit porter.
  final String? imageName;

  /// La cle sous laquelle le chemin de cette image est ecrit dans le JSON.
  final String? imagePathKey;

  /// Le chemin du fichier, relatif a la racine du projet.
  String pathOf(String id, {String? heroClass}) {
    if (supportsHeroClass && heroClass != null) {
      return 'assets/data/classes/$heroClass/cards/$id.json';
    }
    if (folderFile != null) {
      return 'assets/data/$directory/$id/$folderFile';
    }
    return 'assets/data/$directory/$id.json';
  }

  /// Le chemin de l'image, pour les categories qui en portent une.
  String? imagePathOf(String id) =>
      imageName == null ? null : 'assets/data/$directory/$id/$imageName';

  Map<String, dynamic> decodeTemplate() =>
      jsonDecode(template) as Map<String, dynamic>;
}

List<String> _names(List<Enum> values) =>
    values.map((e) => e.name).toList(growable: false);
```

- [ ] **Step 4 : Écrire les sept descripteurs**

Suite du même fichier :

```dart
/// **La declaration des categories editables.** A tenir en regard des sept
/// sources de `loadGameDataRegistry` ; un test verifie qu'aucune ne manque.
final Map<EntityCategory, EntityDescriptor> kEntityDescriptors = {
  EntityCategory.card: EntityDescriptor(
    category: EntityCategory.card,
    label: 'Carte',
    directory: 'cards',
    supportsHeroClass: true,
    requiredKeys: const {'cost', 'type'},
    // Le repertoire impose l'appartenance : les declarer fait echouer le
    // chargement depuis l'expiration de la tolerance de migration (ADR-086).
    forbiddenKeys: const {'heroClass', 'category'},
    enumKeys: {
      'type': _names(CardType.values),
      'rarity': _names(CardRarity.values),
      'target': _names(CardTarget.values),
    },
    bilingualBases: const ['name', 'description'],
    construct: CardData.fromJson,
    template: '''
{
  "cost": 1,
  "type": "attack",
  "rarity": "common",
  "target": "singleEnemy",
  "animation": "melee",
  "effects": [
    { "type": "damage", "value": 6 }
  ],
  "baseMaxForgeUpgrades": 1
}''',
  ),
  EntityCategory.relic: EntityDescriptor(
    category: EntityCategory.relic,
    label: 'Relique',
    directory: 'relics',
    requiredKeys: const {'trigger', 'effectType', 'value', 'rarity'},
    enumKeys: {
      'trigger': _names(RelicTrigger.values),
      'rarity': _names(RelicRarity.values),
    },
    bilingualBases: const ['name', 'description'],
    construct: RelicData.fromJson,
    template: '''
{
  "trigger": "startOfCombat",
  "effectType": "gain_armor",
  "value": 5,
  "rarity": "common",
  "emoji": "🪙"
}''',
  ),
  EntityCategory.passive: EntityDescriptor(
    category: EntityCategory.passive,
    label: 'Passif',
    directory: 'passives',
    requiredKeys: const {'trigger', 'effectType', 'value'},
    enumKeys: {'trigger': _names(RelicTrigger.values)},
    bilingualBases: const ['name', 'description'],
    construct: PassiveData.fromJson,
    template: '''
{
  "trigger": "startOfTurn",
  "effectType": "gain_armor",
  "value": 2
}''',
  ),
  EntityCategory.event: EntityDescriptor(
    category: EntityCategory.event,
    label: 'Evenement',
    directory: 'events',
    requiredKeys: const {'choices'},
    // Un evenement porte `title`, pas `name`. Les textes de ses choix sont
    // imbriques deux niveaux plus bas et restent dans la partie JSON.
    bilingualBases: const ['title', 'description'],
    construct: EventData.fromJson,
    template: '''
{
  "choices": [
    {
      "text_fr": "Accepter",
      "text_en": "Accept",
      "result_text_fr": "Vous gagnez 20 pieces.",
      "result_text_en": "You gain 20 gold.",
      "actions": [
        { "type": "gold", "value": 20 }
      ]
    }
  ]
}''',
  ),
  EntityCategory.forgeUpgrade: EntityDescriptor(
    category: EntityCategory.forgeUpgrade,
    label: 'Amelioration de forge',
    directory: 'forge_upgrades',
    // `ForgeUpgradeData.fromJson` ne leve sur rien d'autre que `id` : toutes
    // les autres cles ont un defaut. C'est la categorie ou la validation
    // declarative fait tout le travail.
    requiredKeys: const {'pools'},
    enumListKeys: {'eligibleCardTypes': _names(CardType.values)},
    bilingualBases: const ['name', 'description'],
    construct: ForgeUpgradeData.fromJson,
    template: '''
{
  "icon": "bolt",
  "color": "#FFAA00",
  "pools": ["common"],
  "valueMultiplier": 1,
  "weight": 10,
  "emoji": "🔮"
}''',
  ),
  EntityCategory.heroClass: EntityDescriptor(
    category: EntityCategory.heroClass,
    label: 'Classe',
    directory: 'classes',
    folderFile: 'class.json',
    imageName: 'icon.png',
    imagePathKey: 'iconPath',
    requiredKeys: const {'maxHp', 'maxMana', 'baseDamage'},
    referenceKeys: const {'passiveTrait': EntityCategory.passive},
    bilingualBases: const ['name', 'description'],
    construct: HeroData.fromJson,
    // Ni `iconPath` ni `skills` ne figurent au gabarit : l'ecrivain calcule le
    // premier, et le second se remplit carte par carte (Task 6).
    template: '''
{
  "maxHp": 100,
  "maxMana": 3,
  "baseDamage": 5,
  "luck": 0,
  "displayOrder": 99
}''',
  ),
  EntityCategory.enemy: EntityDescriptor(
    category: EntityCategory.enemy,
    label: 'Ennemi',
    directory: 'enemies',
    folderFile: 'enemy.json',
    imageName: 'sprite.png',
    imagePathKey: 'spritePath',
    requiredKeys: const {'maxHp', 'baseDamage'},
    // Un ennemi n'a **pas** de description : seulement un nom.
    bilingualBases: const ['name'],
    construct: EnemyData.fromJson,
    template: '''
{
  "maxHp": 30,
  "baseDamage": 5,
  "tier": 1,
  "xp": 35,
  "critChance": 0,
  "gold": 10,
  "intents": [
    { "type": "attack", "value": 5 }
  ]
}''',
  ),
};
```

- [ ] **Step 5 : Lancer le test et vérifier qu'il passe**

Commande : `flutter test test/unit/content_editor/entity_descriptor_test.dart`
Attendu : SUCCÈS, 12 tests.

Si le test « les gabarits sont du JSON valide » échoue, c'est le gabarit qu'il faut corriger, jamais
le test : un gabarit invalide serait servi tel quel à l'utilisateur.

- [ ] **Step 6 : `dart analyze` puis commit**

Commande : `dart analyze`
Attendu : `No issues found!`

```bash
git add lib/services/content_editor/entity_descriptor.dart test/unit/content_editor/entity_descriptor_test.dart
git commit -m "feat(editeur): decrire les sept categories dans une table declarative"
```

---

### Task 3 : Le brouillon, et les trois premières familles de validation

**Files:**
- Create: `lib/services/content_editor/entity_draft.dart`
- Create: `lib/services/content_editor/entity_validator.dart`
- Create: `test/unit/content_editor/fixtures.dart`
- Test: `test/unit/content_editor/entity_validator_test.dart`

**Interfaces:**
- Consumes: `ContentFileSystem` (Task 1) ; `EntityDescriptor`, `EntityCategory`,
  `kEntityDescriptors` (Task 2).
- Produces: `class EntityDraft` avec `descriptor`, `id`, `heroClass`, `bilingual`, `mechanics`,
  `isModification`, le getter `String get path` et la méthode `Map<String, dynamic> compose()` ;
  `class ValidationFault(String message, {String? field})` ;
  `class EntityValidator({required ContentFileSystem fs, required String rootPath, GameDataRegistry? registry})`
  avec `List<ValidationFault> validate(EntityDraft draft)`.

- [ ] **Step 1 : Écrire le brouillon**

Fichier `lib/services/content_editor/entity_draft.dart` :

```dart
import 'dart:convert';

import 'package:meta/meta.dart';

import 'entity_descriptor.dart';

/// Ce que l'ecran compose et que le validateur juge.
///
/// Le triangle d'identite ([id], [heroClass]) et la prose ([bilingual]) sont
/// saisis dans des champs ; la mecanique reste du **texte** JSON, que le
/// validateur decode lui-meme afin de pouvoir dire pourquoi il ne decode pas.
@immutable
class EntityDraft {
  const EntityDraft({
    required this.descriptor,
    required this.id,
    required this.bilingual,
    required this.mechanics,
    this.heroClass,
    this.isModification = false,
  });

  final EntityDescriptor descriptor;
  final String id;

  /// La classe proprietaire, pour une carte de classe. `null` pour une carte
  /// neutre et pour toutes les autres categories.
  final String? heroClass;

  /// Les champs bilingues, sous leur cle complete : `name_fr`, `title_en`…
  final Map<String, String> bilingual;

  /// Le corps JSON tel que saisi.
  final String mechanics;

  /// En modification, le triangle d'identite est gele : il decide **ou** est
  /// le fichier, et le deplacer serait un renommage — hors perimetre (E1).
  final bool isModification;

  String get path => descriptor.pathOf(id, heroClass: heroClass);

  /// Le document final, dans l'ordre des fichiers existants : identifiant,
  /// prose, mecanique.
  ///
  /// **Leve si [mechanics] ne decode pas** : a n'appeler qu'apres la famille 2
  /// de la validation, ce que garantit `EntityValidator`.
  Map<String, dynamic> compose() {
    final decoded = jsonDecode(mechanics) as Map<String, dynamic>;
    final imagePath = descriptor.imagePathOf(id);
    return {
      'id': id,
      for (final base in descriptor.bilingualBases) ...{
        '${base}_en': bilingual['${base}_en'] ?? '',
        '${base}_fr': bilingual['${base}_fr'] ?? '',
      },
      ...decoded,
      // Le chemin de l'image est **derive de l'identifiant**, donc calcule et
      // jamais saisi — c'est exactement ce qu'une saisie manuelle rate. Il est
      // place apres la mecanique pour que l'outil ait le dernier mot.
      if (imagePath != null) descriptor.imagePathKey!: imagePath,
    };
  }
}
```

- [ ] **Step 2 : Écrire les fixtures de test**

Fichier `test/unit/content_editor/fixtures.dart` :

```dart
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';

/// Les entites sont construites par leur **vrai** `fromJson`, jamais par leur
/// constructeur : une fixture ecrite a la main derive du modele sans que rien
/// ne le signale.
CardData fixtureCard(String id) => CardData.fromJson({
      'id': id,
      'name_en': 'x',
      'name_fr': 'x',
      'description_en': 'x',
      'description_fr': 'x',
      'cost': 1,
      'type': 'attack',
      'category': 'global',
      'rarity': 'common',
      'target': 'singleEnemy',
    });

PassiveData fixturePassive(String id) => PassiveData.fromJson({
      'id': id,
      'name_en': 'x',
      'name_fr': 'x',
      'description_en': 'x',
      'description_fr': 'x',
      'trigger': 'startOfTurn',
      'effectType': 'gain_armor',
      'value': 1,
    });

GameDataRegistry fixtureRegistry({
  List<CardData> cards = const [],
  List<PassiveData> passives = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: cards,
      events: const [],
      passives: passives,
      relics: const [],
      forgeUpgrades: const [],
      audio: const AudioData.disabled(),
    );

/// Un brouillon de relique valide, dont chaque test ne change que ce qu'il
/// veut casser.
EntityDraft fixtureRelicDraft({
  String id = 'talisman_de_fer',
  String? mechanics,
  Map<String, String>? bilingual,
  bool isModification = false,
}) {
  final descriptor = kEntityDescriptors[EntityCategory.relic]!;
  return EntityDraft(
    descriptor: descriptor,
    id: id,
    isModification: isModification,
    bilingual: bilingual ??
        const {
          'name_fr': 'Talisman de fer',
          'name_en': 'Iron Talisman',
          'description_fr': 'Donne 5 armure au debut du combat.',
          'description_en': 'Gain 5 armor at the start of combat.',
        },
    mechanics: mechanics ?? descriptor.template,
  );
}
```

- [ ] **Step 3 : Écrire le test des familles 1 à 3 (il doit échouer)**

Fichier `test/unit/content_editor/entity_validator_test.dart` :

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
import 'package:roguelike_card_game/services/content_editor/entity_validator.dart';

import 'fixtures.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('validator_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
    Directory('$root/assets/data/relics').createSync(recursive: true);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  EntityValidator validatorWith({dynamic registry}) => EntityValidator(
        fs: fs,
        rootPath: root,
        registry: registry ?? fixtureRegistry(),
      );

  group('famille 1 — identite', () {
    test('un identifiant vide est refuse', () {
      final faults = validatorWith().validate(fixtureRelicDraft(id: ''));
      expect(faults, isNotEmpty);
      expect(faults.first.field, 'id');
    });

    test('les majuscules et les accents sont refuses', () {
      for (final bad in ['Talisman', 'talisman-de-fer', 'épée', 'talisman ']) {
        final faults = validatorWith().validate(fixtureRelicDraft(id: bad));
        expect(faults, isNotEmpty, reason: 'accepte a tort : "$bad"');
        expect(faults.first.field, 'id');
      }
    });

    test('un fichier deja present interdit la creation', () {
      File('$root/assets/data/relics/talisman_de_fer.json')
          .writeAsStringSync('{}');

      final faults = validatorWith().validate(fixtureRelicDraft());
      expect(faults, isNotEmpty);
      expect(faults.first.message, contains('existe deja'));
    });

    test('un fichier absent interdit la modification', () {
      final faults =
          validatorWith().validate(fixtureRelicDraft(isModification: true));
      expect(faults, isNotEmpty);
      expect(faults.first.message, contains('aucun fichier a modifier'));
    });

    test('un identifiant deja dans le registre est refuse, chemin libre', () {
      // Le cas que le controle disque **ne peut pas** voir : une carte neutre
      // homonyme d'une carte de classe. Le chargeur, lui, le rejette.
      final descriptor = kEntityDescriptors[EntityCategory.card]!;
      final draft = EntityDraft(
        descriptor: descriptor,
        id: 'smite',
        bilingual: const {
          'name_fr': 'x',
          'name_en': 'x',
          'description_fr': 'x',
          'description_en': 'x',
        },
        mechanics: descriptor.template,
      );

      // Le chemin `assets/data/cards/smite.json` est libre…
      expect(File('$root/${draft.path}').existsSync(), isFalse);
      // …mais le registre porte deja `smite`, sous le dossier du paladin.
      final faults = validatorWith(
        registry: fixtureRegistry(cards: [fixtureCard('smite')]),
      ).validate(draft);

      expect(faults, isNotEmpty);
      expect(faults.first.message, contains('smite'));
    });
  });

  group('famille 2 — syntaxe', () {
    test('un corps illisible est refuse en nommant la cause', () {
      final faults =
          validatorWith().validate(fixtureRelicDraft(mechanics: '{ "a": }'));
      expect(faults, hasLength(1));
      expect(faults.first.message, contains('JSON invalide'));
    });

    test('un tableau n est pas un document d entite', () {
      final faults =
          validatorWith().validate(fixtureRelicDraft(mechanics: '[1, 2]'));
      expect(faults, hasLength(1));
      expect(faults.first.message, contains('objet JSON'));
    });
  });

  group('famille 3 — cles', () {
    test('une cle obligatoire absente est nommee', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"trigger": "startOfCombat", "rarity": "common"}',
        ),
      );
      // `effectType` et `value` manquent.
      expect(faults.map((f) => f.field), containsAll(['effectType', 'value']));
    });

    test('un champ impose par le repertoire est refuse', () {
      final descriptor = kEntityDescriptors[EntityCategory.card]!;
      final faults = validatorWith().validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'coup_bas',
          bilingual: const {
            'name_fr': 'x',
            'name_en': 'x',
            'description_fr': 'x',
            'description_en': 'x',
          },
          mechanics: '{"cost": 1, "type": "attack", "heroClass": "paladin"}',
        ),
      );
      expect(faults.map((f) => f.field), contains('heroClass'));
    });

    test('id peut etre redeclare, mais seulement a l identique', () {
      final ok = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"id": "talisman_de_fer", "trigger": "startOfCombat", '
              '"effectType": "gain_armor", "value": 5, "rarity": "common"}',
        ),
      );
      expect(ok, isEmpty);

      final ko = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"id": "autre_chose", "trigger": "startOfCombat", '
              '"effectType": "gain_armor", "value": 5, "rarity": "common"}',
        ),
      );
      expect(ko.map((f) => f.field), contains('id'));
    });
  });

  test('le gabarit de chaque categorie franchit les trois premieres familles',
      () {
    // Un gabarit qui ne passerait pas sa propre validation serait un piege
    // servi a l'utilisateur des l'ouverture de l'ecran.
    final faults = validatorWith().validate(fixtureRelicDraft());
    expect(faults, isEmpty);
  });
}
```

- [ ] **Step 4 : Lancer le test et vérifier qu'il échoue**

Commande : `flutter test test/unit/content_editor/entity_validator_test.dart`
Attendu : ÉCHEC — `entity_validator.dart` n'existe pas.

- [ ] **Step 5 : Écrire le validateur, familles 1 à 3**

Fichier `lib/services/content_editor/entity_validator.dart` :

```dart
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
```

- [ ] **Step 6 : Lancer le test et vérifier qu'il passe**

Commande : `flutter test test/unit/content_editor/entity_validator_test.dart`
Attendu : SUCCÈS, 10 tests.

- [ ] **Step 7 : `dart analyze` puis commit**

```bash
git add lib/services/content_editor/ test/unit/content_editor/
git commit -m "feat(editeur): valider l identite, la syntaxe et les cles d un brouillon"
```

---

### Task 4 : Les quatre familles restantes — énumérations, bilingue, références, construction

**Files:**
- Modify: `lib/services/content_editor/entity_validator.dart`
- Modify: `test/unit/content_editor/entity_validator_test.dart`

**Interfaces:**
- Consumes: tout ce que la Task 3 produit.
- Produces: aucune signature nouvelle — `validate` couvre désormais les sept familles.

- [ ] **Step 1 : Écrire les tests des quatre familles (ils doivent échouer)**

Ajouter à `test/unit/content_editor/entity_validator_test.dart`, avant la dernière accolade de
`main()` :

```dart
  group('famille 4 — enumerations', () {
    test('une rarete inconnue est refusee, et les valeurs admises listees', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"trigger": "startOfCombat", "effectType": "gain_armor", '
              '"value": 5, "rarity": "commune"}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.field, 'rarity');
      expect(faults.first.message, contains('legendary'));
    });

    test('c est bien ce que fromJson laisse passer', () {
      // Le point de la famille 4. Le meme document construit sans lever :
      // `RelicRarity.values.firstWhere` n'a pas d'`orElse` pour `rarity`, mais
      // `CardRarity` en a un — la carte retombe en silence sur `common`.
      final descriptor = kEntityDescriptors[EntityCategory.card]!;
      final draft = EntityDraft(
        descriptor: descriptor,
        id: 'coup_bas',
        bilingual: const {
          'name_fr': 'x',
          'name_en': 'x',
          'description_fr': 'x',
          'description_en': 'x',
        },
        mechanics: '{"cost": 1, "type": "attack", "rarity": "commune"}',
      );

      // `fromJson` accepte, donc la famille 7 seule ne verrait rien…
      expect(() => descriptor.construct(draft.compose()), returnsNormally);
      // …et pourtant la famille 4 refuse.
      final faults = validatorWith().validate(draft);
      expect(faults, hasLength(1));
      expect(faults.first.field, 'rarity');
    });

    test('une liste enumeree est verifiee element par element', () {
      final descriptor = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
      final faults = validatorWith().validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'affutage',
          bilingual: const {
            'name_fr': 'x',
            'name_en': 'x',
            'description_fr': 'x',
            'description_en': 'x',
          },
          mechanics: '{"pools": ["common"], '
              '"eligibleCardTypes": ["attack", "sortilege"]}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.field, 'eligibleCardTypes');
      expect(faults.first.message, contains('sortilege'));
    });
  });

  group('famille 5 — bilingue', () {
    test('une variante absente est refusee', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          bilingual: const {
            'name_fr': 'Talisman',
            'name_en': 'Talisman',
            'description_fr': 'Donne 5 armure.',
          },
        ),
      );
      expect(faults.map((f) => f.field), contains('description_en'));
    });

    test('une variante vide ou blanche est refusee', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          bilingual: const {
            'name_fr': 'Talisman',
            'name_en': '   ',
            'description_fr': 'Donne 5 armure.',
            'description_en': 'Gain 5 armor.',
          },
        ),
      );
      expect(faults.map((f) => f.field), contains('name_en'));
    });

    test('c est bien ce que fromJson laisse passer', () {
      // `RelicData.fromJson` retombe sur la chaine vide : la relique existe,
      // et elle est sans nom en jeu.
      final draft = fixtureRelicDraft(
        bilingual: const {
          'name_fr': 'Talisman',
          'name_en': 'Talisman',
          'description_fr': 'Donne 5 armure.',
        },
      );
      expect(
        () => draft.descriptor.construct(draft.compose()),
        returnsNormally,
      );
      expect(validatorWith().validate(draft), isNotEmpty);
    });

    test('un ennemi n exige pas de description', () {
      // La preuve que les bases bilingues sont par categorie et non
      // universelles : `EnemyData` n'a que des noms.
      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      final faults = validatorWith().validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );
      expect(faults, isEmpty);
    });
  });

  group('famille 6 — references', () {
    test('un passiveTrait pendant est refuse', () {
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      final faults = validatorWith(
        registry: fixtureRegistry(passives: [fixturePassive('regen_armor')]),
      ).validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'barde',
          bilingual: const {
            'name_fr': 'Le Barde',
            'name_en': 'The Bard',
            'description_fr': 'Oriente soutien',
            'description_en': 'Support oriented',
          },
          mechanics: '{"maxHp": 90, "maxMana": 3, "baseDamage": 4, '
              '"passiveTrait": "chant_inexistant"}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.field, 'passiveTrait');
    });

    test('un passiveTrait resolu passe', () {
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      final faults = validatorWith(
        registry: fixtureRegistry(passives: [fixturePassive('regen_armor')]),
      ).validate(
        EntityDraft(
          descriptor: descriptor,
          id: 'barde',
          bilingual: const {
            'name_fr': 'Le Barde',
            'name_en': 'The Bard',
            'description_fr': 'Oriente soutien',
            'description_en': 'Support oriented',
          },
          mechanics: '{"maxHp": 90, "maxMana": 3, "baseDamage": 4, '
              '"passiveTrait": "regen_armor"}',
        ),
      );
      expect(faults, isEmpty);
    });
  });

  group('famille 7 — construction', () {
    test('un type de mauvaise nature est attrape par le modele', () {
      final faults = validatorWith().validate(
        fixtureRelicDraft(
          mechanics: '{"trigger": "startOfCombat", "effectType": "gain_armor", '
              '"value": "cinq", "rarity": "common"}',
        ),
      );
      expect(faults, hasLength(1));
      expect(faults.first.message, contains('refuse'));
    });
  });

  test('tous les gabarits franchissent les sept familles', () {
    // Chaque categorie est testee avec sa prose minimale : un gabarit qui ne
    // passerait pas sa propre validation serait un piege servi a l'ouverture.
    for (final descriptor in kEntityDescriptors.values) {
      final draft = EntityDraft(
        descriptor: descriptor,
        id: 'entite_de_test',
        bilingual: {
          for (final base in descriptor.bilingualBases) ...{
            '${base}_fr': 'texte',
            '${base}_en': 'text',
          },
        },
        mechanics: descriptor.template,
      );
      expect(
        validatorWith().validate(draft),
        isEmpty,
        reason: '${descriptor.label} : ${validatorWith().validate(draft)}',
      );
    }
  });
```

- [ ] **Step 2 : Lancer les tests et vérifier qu'ils échouent**

Commande : `flutter test test/unit/content_editor/entity_validator_test.dart`
Attendu : ÉCHEC — les familles 4 à 7 ne sont pas encore évaluées, donc aucune faute n'est rendue.

- [ ] **Step 3 : Enchaîner les quatre familles dans `validate`**

Dans `entity_validator.dart`, remplacer la dernière ligne de `validate` — `return _keys(draft, mechanics);` — par :

```dart
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
```

- [ ] **Step 4 : Écrire les quatre familles**

Ajouter à `EntityValidator`, après `_keys` :

```dart
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
        faults.add(ValidationFault('doit etre une liste', field: key));
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
              'les deux variantes linguistiques sont exigees, et non vides',
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
            'aucune entite de la categorie '
            '"${kEntityDescriptors[category]!.label}" ne porte l identifiant '
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
          'le modele refuse ce document : ${e.toString().replaceAll('\n', ' ')}',
        ),
      ];
    }
    return const [];
  }
```

- [ ] **Step 5 : Lancer les tests et vérifier qu'ils passent**

Commande : `flutter test test/unit/content_editor/entity_validator_test.dart`
Attendu : SUCCÈS, 20 tests.

Les deux tests nommés « c est bien ce que fromJson laisse passer » sont les plus importants du
fichier : ils prouvent que les familles 4 et 5 **ne sont pas redondantes** avec la famille 7. S'ils
passaient avec la famille 7 seule, ces deux familles seraient à supprimer.

- [ ] **Step 6 : `dart analyze` puis commit**

```bash
git add lib/services/content_editor/entity_validator.dart test/unit/content_editor/entity_validator_test.dart
git commit -m "feat(editeur): verifier les enumerations, le bilingue et les references"
```

---

### Task 5 : L'écrivain — une entité à plat, et `sync_assets`

**Files:**
- Create: `lib/services/content_editor/entity_writer.dart`
- Test: `test/unit/content_editor/entity_writer_test.dart`

**Interfaces:**
- Consumes: `ContentFileSystem`, `ProcessOutcome` (Task 1) ; `EntityDraft` (Task 3).
- Produces: `class WriteReport({required List<String> written, ProcessOutcome? sync, bool relaunchAdvised})`
  avec le getter `bool get syncFailed` ; `class WriteStep(String relative, String? previous)` ;
  `class EntityWriter({required ContentFileSystem fs, required String rootPath})` avec
  `Future<WriteReport> write(EntityDraft draft)` et, pour les tâches 6 et 7,
  les méthodes privées `_writeFiles(EntityDraft, List<WriteStep>)` et
  `_writeJson(String, Map<String, dynamic>, List<WriteStep>)`.

- [ ] **Step 1 : Écrire le test (il doit échouer)**

Fichier `test/unit/content_editor/entity_writer_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_writer.dart';

import 'fixtures.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('entity_writer_');
    root = IoContentFileSystem.toSlashes(sandbox.path);

    // Le script est invoque depuis le bac a sable : il lui faut une copie, et
    // un pubspec a reecrire. Meme montage que `test/unit/sync_assets_test.dart`.
    Directory('$root/tool').createSync(recursive: true);
    File('tool/sync_assets.dart').copySync('$root/tool/sync_assets.dart');
    Directory('$root/assets/data/relics').createSync(recursive: true);

    // `environment:` evite l avertissement « has no lower-bound SDK
    // constraint » que `dart run` ecrirait sur stdout a chaque invocation.
    File('$root/pubspec.yaml').writeAsStringSync(
      'name: sandbox\r\n'
      'environment:\r\n'
      '  sdk: ^3.11.4\r\n'
      'flutter:\r\n'
      '  uses-material-design: true\r\n'
      '  assets:\r\n'
      '  fonts: []\r\n',
    );
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  EntityWriter writerHere() => EntityWriter(fs: fs, rootPath: root);

  test('ecrit le fichier au chemin calcule', () async {
    await writerHere().write(fixtureRelicDraft());

    final file = File('$root/assets/data/relics/talisman_de_fer.json');
    expect(file.existsSync(), isTrue);
  });

  test('le document porte l identifiant, la prose puis la mecanique', () async {
    await writerHere().write(fixtureRelicDraft());

    final raw =
        File('$root/assets/data/relics/talisman_de_fer.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    expect(decoded['id'], 'talisman_de_fer');
    expect(decoded['name_fr'], 'Talisman de fer');
    expect(decoded['trigger'], 'startOfCombat');
    // L'ordre des cles est celui des fichiers existants.
    expect(
      decoded.keys.take(5).toList(),
      ['id', 'name_en', 'name_fr', 'description_en', 'description_fr'],
    );
  });

  test('le JSON est indente de deux espaces et finit par une ligne', () async {
    await writerHere().write(fixtureRelicDraft());

    final raw =
        File('$root/assets/data/relics/talisman_de_fer.json').readAsStringSync();
    expect(raw, contains('\n  "id": "talisman_de_fer"'));
    expect(raw.endsWith('\n'), isTrue);
  });

  test('sync_assets est relance et le pubspec declare le repertoire',
      () async {
    final report = await writerHere().write(fixtureRelicDraft());

    expect(report.sync, isNotNull);
    expect(
      report.sync!.exitCode,
      0,
      reason: report.sync!.output,
    );
    expect(
      File('$root/pubspec.yaml').readAsStringSync(),
      contains('assets/data/relics/'),
    );
  });

  test('une creation conseille de relancer flutter run', () async {
    final report = await writerHere().write(fixtureRelicDraft());
    expect(report.relaunchAdvised, isTrue);
    expect(report.written, ['assets/data/relics/talisman_de_fer.json']);
  });

  test('une modification ne le conseille pas', () async {
    await writerHere().write(fixtureRelicDraft());
    final report =
        await writerHere().write(fixtureRelicDraft(isModification: true));

    expect(report.relaunchAdvised, isFalse);
  });

}
```

- [ ] **Step 2 : Lancer le test et vérifier qu'il échoue**

Commande : `flutter test test/unit/content_editor/entity_writer_test.dart`
Attendu : ÉCHEC — `entity_writer.dart` n'existe pas.

- [ ] **Step 3 : Écrire l'écrivain**

Fichier `lib/services/content_editor/entity_writer.dart` :

```dart
import 'dart:convert';

import 'package:meta/meta.dart';

import 'content_file_system.dart';
import 'entity_draft.dart';

/// Ce qui a ete ecrit, et ce qu'il reste a faire cote humain.
@immutable
class WriteReport {
  const WriteReport({
    required this.written,
    this.sync,
    this.relaunchAdvised = false,
  });

  /// Les chemins ecrits, relatifs a la racine du projet.
  final List<String> written;

  /// Le resultat de `sync_assets`. `null` s'il n'a pas ete lance.
  final ProcessOutcome? sync;

  /// Vrai apres une creation : le manifeste d'assets est produit a la
  /// compilation, et un fichier nouveau ne s'y trouve pas.
  final bool relaunchAdvised;

  bool get syncFailed => sync != null && !sync!.succeeded;
}

/// Une ecriture, et de quoi la defaire.
@immutable
class WriteStep {
  const WriteStep(this.relative, this.previous);

  final String relative;

  /// Le contenu d'avant, ou `null` si le fichier n'existait pas.
  final String? previous;
}

/// Ecrit une entite, puis enchaine ses effets de bord.
///
/// **Ne valide rien** : l'appelant valide, l'ecrivain ecrit. La separation
/// tient la decision E6 — rien n'est ecrit avant que la validation entiere
/// passe, et c'est a l'appelant de ne pas appeler.
@immutable
class EntityWriter {
  const EntityWriter({required this.fs, required this.rootPath});

  final ContentFileSystem fs;
  final String rootPath;

  /// Deux espaces, comme les fichiers existants. `Map` et `jsonDecode`
  /// preservant l'ordre d'insertion, une modification produit un diff minimal.
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  Future<WriteReport> write(EntityDraft draft) async {
    final steps = <WriteStep>[];
    try {
      _writeFiles(draft, steps);
    } catch (_) {
      _rollback(steps);
      rethrow;
    }

    final sync = await _runSyncAssets();

    return WriteReport(
      written: [for (final step in steps) step.relative],
      sync: sync,
      relaunchAdvised: !draft.isModification,
    );
  }

  /// Empile les ecritures dans [steps]. Les tâches suivantes l'etendent : la
  /// carte de classe y ajoute `class.json`, la classe et l'ennemi leur dossier
  /// et leur image.
  void _writeFiles(EntityDraft draft, List<WriteStep> steps) {
    _writeJson(draft.path, draft.compose(), steps);
  }

  void _writeJson(
    String relative,
    Map<String, dynamic> document,
    List<WriteStep> steps,
  ) {
    final absolute = '$rootPath/$relative';
    // L'etape est empilee **avant** l'ecriture : une ecriture qui echoue a
    // mi-chemin doit elle aussi pouvoir etre defaite.
    steps.add(
      WriteStep(relative, fs.fileExists(absolute) ? fs.readFile(absolute) : null),
    );
    // Une ligne finale, comme tous les fichiers du depot.
    fs.writeFile(absolute, '${_encoder.convert(document)}\n');
  }

  /// Defait ce qui vient d'etre ecrit : un fichier **cree** est supprime, un
  /// fichier **modifie** retrouve son contenu d'avant.
  ///
  /// La distinction n'est pas cosmetique. Une modification ecrase un fichier
  /// existant, et l'ecriture couplee de la carte de classe touche un
  /// `class.json` deja la : le supprimer au motif qu'on « defait » serait bien
  /// pire que la panne qu'on rattrape.
  void _rollback(List<WriteStep> steps) {
    for (final step in steps.reversed) {
      final absolute = '$rootPath/${step.relative}';
      final previous = step.previous;
      if (previous == null) {
        if (fs.fileExists(absolute)) fs.deleteFile(absolute);
      } else {
        fs.writeFile(absolute, previous);
      }
    }
    steps.clear();
  }

  /// Les declarations d'assets de Flutter ne sont recursives a aucun niveau :
  /// un repertoire non declare se charge en developpement puis disparait
  /// silencieusement d'un build.
  ///
  /// Un echec n'annule pas l'ecriture — le fichier est bon — mais il est
  /// rapporte : `pubspec.yaml` est alors en retard.
  Future<ProcessOutcome> _runSyncAssets() => fs.run(
        'dart',
        const ['run', 'tool/sync_assets.dart'],
        workingDirectory: rootPath,
      );
}
```

- [ ] **Step 4 : Lancer le test et vérifier qu'il passe**

Commande : `flutter test test/unit/content_editor/entity_writer_test.dart`
Attendu : SUCCÈS, 7 tests.

- [ ] **Step 5 : `dart analyze` puis commit**

```bash
git add lib/services/content_editor/entity_writer.dart test/unit/content_editor/entity_writer_test.dart
git commit -m "feat(editeur): ecrire une entite a plat et resynchroniser les assets"
```

---

### Task 6 : Les dossiers, et l'écriture couplée de la carte de signature

**Files:**
- Modify: `lib/services/content_editor/entity_writer.dart`
- Modify: `test/unit/content_editor/entity_writer_test.dart`

**Interfaces:**
- Consumes: `EntityWriter`, `WriteStep` (Task 5) ; `EntityCategory`, `EntityDescriptor` (Task 2).
- Produces: aucune signature publique nouvelle. `write` crée désormais le dossier des catégories
  qui en sont un, et met `skills` à jour pour une carte de classe.

**C'est la tâche la plus importante du plan.** Elle traite les deux pièges de `referential_integrity_test`
que rien d'autre ne rattrape :

- `referential_integrity_test.dart:103` exige que le contenu de `classes/<id>/cards/` soit
  **exactement** le tableau `skills` de la classe. Une carte ajoutée seule y est orpheline.
- Ce même test appelle `listSync()` **sans garde** : un dossier `cards/` absent le fait *lever*, et
  c'est toute la suite qui tombe.

- [ ] **Step 1 : Écrire les tests (ils doivent échouer)**

Ajouter à `test/unit/content_editor/entity_writer_test.dart`, avant la dernière accolade de `main()` :

```dart
  /// Monte une classe minimale dans le bac a sable, comme le depot la porte.
  void seedClass(String id, {List<String> skills = const []}) {
    Directory('$root/assets/data/classes/$id/cards').createSync(recursive: true);
    File('$root/assets/data/classes/$id/class.json').writeAsStringSync(
      jsonEncode({
        'id': id,
        'name_en': 'X',
        'name_fr': 'X',
        'description_en': 'x',
        'description_fr': 'x',
        'iconPath': 'assets/data/classes/$id/icon.png',
        'maxHp': 100,
        'maxMana': 3,
        'baseDamage': 5,
        'skills': skills,
      }),
    );
  }

  EntityDraft classCardDraft(String id, String heroClass) {
    final descriptor = kEntityDescriptors[EntityCategory.card]!;
    return EntityDraft(
      descriptor: descriptor,
      id: id,
      heroClass: heroClass,
      bilingual: const {
        'name_fr': 'Frappe',
        'name_en': 'Strike',
        'description_fr': 'Inflige 6 degats.',
        'description_en': 'Deal 6 damage.',
      },
      mechanics: descriptor.template,
    );
  }

  group('carte de classe', () {
    test('ecrit la carte ET declare son identifiant dans skills', () async {
      seedClass('paladin', skills: ['smite']);

      final report =
          await writerHere().write(classCardDraft('coup_saint', 'paladin'));

      expect(
        File('$root/assets/data/classes/paladin/cards/coup_saint.json')
            .existsSync(),
        isTrue,
      );
      final classJson = jsonDecode(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(classJson['skills'], ['coup_saint', 'smite']);
      expect(report.written, hasLength(2));
    });

    test('le dossier cards et skills restent en bijection', () async {
      seedClass('paladin');
      await writerHere().write(classCardDraft('un', 'paladin'));
      await writerHere().write(classCardDraft('deux', 'paladin'));

      final onDisk = Directory('$root/assets/data/classes/paladin/cards')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();
      final classJson = jsonDecode(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      // La forme exacte de l'assertion de `referential_integrity_test`.
      expect(onDisk, (classJson['skills'] as List).toSet());
    });

    test('une classe sans class.json ne laisse pas la carte derriere elle',
        () async {
      Directory('$root/assets/data/classes/fantome/cards')
          .createSync(recursive: true);

      await expectLater(
        writerHere().write(classCardDraft('orpheline', 'fantome')),
        throwsA(isA<StateError>()),
      );

      // Les deux fichiers, ou aucun : la carte a ete defaite.
      expect(
        File('$root/assets/data/classes/fantome/cards/orpheline.json')
            .existsSync(),
        isFalse,
      );
    });

    test('modifier une carte ne retouche pas skills', () async {
      seedClass('paladin');
      await writerHere().write(classCardDraft('coup_saint', 'paladin'));

      final before =
          File('$root/assets/data/classes/paladin/class.json').readAsStringSync();
      final report = await writerHere().write(
        EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.card]!,
          id: 'coup_saint',
          heroClass: 'paladin',
          isModification: true,
          bilingual: const {
            'name_fr': 'Frappe renforcee',
            'name_en': 'Greater Strike',
            'description_fr': 'Inflige 9 degats.',
            'description_en': 'Deal 9 damage.',
          },
          mechanics: '{"cost": 2, "type": "attack", "rarity": "common", '
              '"target": "singleEnemy", "effects": '
              '[{"type": "damage", "value": 9}]}',
        ),
      );

      expect(report.written, hasLength(1));
      expect(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
        before,
      );
    });

    test('une carte deja declaree n est pas ajoutee deux fois', () async {
      seedClass('paladin', skills: ['coup_saint']);
      await writerHere().write(classCardDraft('coup_saint', 'paladin'));

      final classJson = jsonDecode(
        File('$root/assets/data/classes/paladin/class.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(classJson['skills'], ['coup_saint']);
    });
  });

  group('categories en dossier', () {
    test('une classe nait avec un sous-dossier cards vide', () async {
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'barde',
          bilingual: const {
            'name_fr': 'Le Barde',
            'name_en': 'The Bard',
            'description_fr': 'Oriente soutien',
            'description_en': 'Support oriented',
          },
          mechanics: descriptor.template,
        ),
      );

      final cards = Directory('$root/assets/data/classes/barde/cards');
      // Sans ce dossier, `referential_integrity_test` **leve** au lieu
      // d'echouer : `listSync()` y est appele sans garde.
      expect(cards.existsSync(), isTrue);
      expect(cards.listSync(), isEmpty);
    });

    test('un ennemi nait dans son propre dossier', () async {
      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );

      final written = File('$root/assets/data/enemies/troll/enemy.json');
      expect(written.existsSync(), isTrue);
      final decoded =
          jsonDecode(written.readAsStringSync()) as Map<String, dynamic>;
      // Le chemin du sprite est calcule, jamais saisi.
      expect(decoded['spritePath'], 'assets/data/enemies/troll/sprite.png');
    });
  });
```

Ajouter les imports nécessaires en tête du fichier de test :

```dart
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
```

- [ ] **Step 2 : Lancer les tests et vérifier qu'ils échouent**

Commande : `flutter test test/unit/content_editor/entity_writer_test.dart`
Attendu : ÉCHEC — l'écrivain n'écrit qu'un fichier et ne crée aucun dossier.

- [ ] **Step 3 : Étendre `_writeFiles`**

Dans `entity_writer.dart`, ajouter l'import :

```dart
import 'entity_descriptor.dart';
```

Puis remplacer `_writeFiles` par :

```dart
  void _writeFiles(EntityDraft draft, List<WriteStep> steps) {
    _prepareFolder(draft);
    _writeJson(draft.path, draft.compose(), steps);
    _registerSignatureCard(draft, steps);
  }

  /// Une classe et un ennemi sont des **dossiers**, qu'il faut creer avant
  /// d'y ecrire.
  ///
  /// Celui d'une classe porte en outre un sous-dossier `cards/`, **meme
  /// vide** : `referential_integrity_test` y appelle `listSync()` sans garde,
  /// et un dossier absent le fait *lever*. Ce n'est alors pas ce test qui
  /// echoue, c'est toute la suite qui tombe.
  void _prepareFolder(EntityDraft draft) {
    final descriptor = draft.descriptor;
    if (descriptor.folderFile == null || draft.isModification) return;

    final folder = '$rootPath/assets/data/${descriptor.directory}/${draft.id}';
    fs.createDirectory(folder);
    if (descriptor.category == EntityCategory.heroClass) {
      fs.createDirectory('$folder/cards');
    }
  }

  /// Une carte de classe **est** une carte de signature.
  ///
  /// `referential_integrity_test` exige que le contenu du dossier `cards/`
  /// soit exactement egal au tableau `skills` de la classe. Une carte ajoutee
  /// seule y serait orpheline et ferait rougir la suite — a tous les coups, et
  /// jamais au moment de l'ecriture. Les deux fichiers, ou aucun.
  void _registerSignatureCard(EntityDraft draft, List<WriteStep> steps) {
    final heroClass = draft.heroClass;
    if (heroClass == null || draft.isModification) return;

    final relative = 'assets/data/classes/$heroClass/class.json';
    final absolute = '$rootPath/$relative';
    if (!fs.fileExists(absolute)) {
      throw StateError(
        'la classe "$heroClass" n a pas de class.json : sa carte de signature '
        'ne peut pas y etre declaree',
      );
    }

    final document = jsonDecode(fs.readFile(absolute)) as Map<String, dynamic>;
    final skills = List<String>.from(document['skills'] as List? ?? const []);
    if (skills.contains(draft.id)) return;

    skills.add(draft.id);
    // Trie pour que l'ordre ne depende pas de celui des ajouts : le diff d'une
    // classe reste lisible d'une carte a l'autre.
    skills.sort();
    document['skills'] = skills;
    _writeJson(relative, document, steps);
  }
```

- [ ] **Step 4 : Lancer les tests et vérifier qu'ils passent**

Commande : `flutter test test/unit/content_editor/entity_writer_test.dart`
Attendu : SUCCÈS, 14 tests.

- [ ] **Step 5 : `dart analyze` puis commit**

```bash
git add lib/services/content_editor/entity_writer.dart test/unit/content_editor/entity_writer_test.dart
git commit -m "feat(editeur): creer les dossiers et declarer la carte de signature"
```

---

### Task 7 : L'image de remplacement

**Files:**
- Create: `assets/images/placeholder_entity.png`
- Modify: `lib/services/content_editor/entity_writer.dart`
- Modify: `test/unit/content_editor/entity_writer_test.dart`
- Modify: `pubspec.yaml` *(régénéré par `sync_assets`, jamais à la main)*

**Interfaces:**
- Consumes: `EntityWriter` (Tasks 5-6) ; `EntityDescriptor.imagePathOf` (Task 2).
- Produces: la constante `const String kPlaceholderImage = 'assets/images/placeholder_entity.png';`
  exportée depuis `entity_writer.dart`.

- [ ] **Step 1 : Créer l'image de remplacement**

Un carré magenta franchement laid, pour qu'oublier de le remplacer se voie immédiatement.
`assets/images/` ne contient aujourd'hui que `bg_dungeon.png`.

Cette base64 a été produite puis **relue comme image** pour vérifier qu'elle décode bien : 134
octets, 64 × 64, magenta plein.

```bash
python -c "import base64,pathlib; pathlib.Path('assets/images/placeholder_entity.png').write_bytes(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAATUlEQVR42u3PMQkAAAwDsPo33UnoPQjEQNL0tQgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIrMABQafh0jMgqsoAAAAASUVORK5CYII='))"
```

Vérifier ensuite la taille exacte :

```bash
ls -l assets/images/placeholder_entity.png
```

Attendu : **134 octets**. Toute autre taille signifie que la chaîne a été tronquée à la copie —
refaire l'étape. Un placeholder vide ou tronqué ferait échouer le chargement d'image de toute
classe créée, et l'échec surviendrait loin d'ici.

- [ ] **Step 2 : Déclarer l'asset**

Commande : `dart run tool/sync_assets.dart`
Puis : `dart run tool/sync_assets.dart --check`
Attendu : sortie 0. `assets/images/` était déjà déclaré ; la commande confirme qu'aucune ligne ne
manque.

- [ ] **Step 3 : Écrire les tests (ils doivent échouer)**

Ajouter à `test/unit/content_editor/entity_writer_test.dart`, dans le groupe
`categories en dossier` :

```dart
    test('l image de remplacement est deposee sous le nom attendu', () async {
      // Le bac a sable doit porter une copie du placeholder, comme le depot.
      Directory('$root/assets/images').createSync(recursive: true);
      File('assets/images/placeholder_entity.png')
          .copySync('$root/assets/images/placeholder_entity.png');

      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );

      final sprite = File('$root/assets/data/enemies/troll/sprite.png');
      expect(sprite.existsSync(), isTrue);
      expect(sprite.lengthSync(), greaterThan(0));
    });

    test('une image deja presente n est jamais ecrasee', () async {
      Directory('$root/assets/images').createSync(recursive: true);
      File('assets/images/placeholder_entity.png')
          .copySync('$root/assets/images/placeholder_entity.png');
      Directory('$root/assets/data/enemies/troll').createSync(recursive: true);
      File('$root/assets/data/enemies/troll/sprite.png')
          .writeAsStringSync('image peinte a la main');

      final descriptor = kEntityDescriptors[EntityCategory.enemy]!;
      await writerHere().write(
        EntityDraft(
          descriptor: descriptor,
          id: 'troll',
          bilingual: const {'name_fr': 'Troll', 'name_en': 'Troll'},
          mechanics: descriptor.template,
        ),
      );

      expect(
        File('$root/assets/data/enemies/troll/sprite.png').readAsStringSync(),
        'image peinte a la main',
      );
    });

    test('une categorie a plat ne recoit aucune image', () async {
      await writerHere().write(fixtureRelicDraft());
      expect(Directory('$root/assets/data/relics').listSync(), hasLength(1));
    });
```

- [ ] **Step 4 : Lancer les tests et vérifier qu'ils échouent**

Commande : `flutter test test/unit/content_editor/entity_writer_test.dart`
Attendu : ÉCHEC sur les deux premiers — aucune image n'est déposée.

- [ ] **Step 5 : Déposer l'image**

Dans `entity_writer.dart`, ajouter la constante en tête de fichier, après les imports :

```dart
/// L'image deposee dans un dossier de classe ou d'ennemi nouvellement cree.
/// Un carre magenta volontairement laid : oublier de le remplacer doit se voir.
const String kPlaceholderImage = 'assets/images/placeholder_entity.png';
```

Puis ajouter l'appel dans `_writeFiles`, après `_prepareFolder(draft);` :

```dart
    _placeImage(draft);
```

Et la méthode, après `_prepareFolder` :

```dart
  /// Depose l'image de remplacement, **si et seulement si aucune n'est deja
  /// la**. Une image peinte a la main ne doit jamais etre ecrasee par un carre
  /// magenta.
  ///
  /// Elle n'est deliberement pas defaite par [_rollback] : un placeholder
  /// laisse dans un dossier neuf est sans consequence, la ou une suppression
  /// pourrait emporter une image legitime.
  void _placeImage(EntityDraft draft) {
    final relative = draft.descriptor.imagePathOf(draft.id);
    if (relative == null) return;

    final absolute = '$rootPath/$relative';
    if (fs.fileExists(absolute)) return;

    final source = '$rootPath/$kPlaceholderImage';
    if (!fs.fileExists(source)) return; // rien a copier : on n'invente pas
    fs.copyFile(source, absolute);
  }
```

- [ ] **Step 6 : Lancer les tests et vérifier qu'ils passent**

Commande : `flutter test test/unit/content_editor/entity_writer_test.dart`
Attendu : SUCCÈS, 17 tests.

- [ ] **Step 7 : Suite complète, `dart analyze`, puis commit**

Commande : `flutter test`
Attendu : tout vert. `sync_assets_test` en particulier, que le nouvel asset touche.

Commande : `dart analyze`
Attendu : `No issues found!`

```bash
git add assets/images/placeholder_entity.png pubspec.yaml lib/services/content_editor/entity_writer.dart test/unit/content_editor/entity_writer_test.dart
git commit -m "feat(editeur): deposer une image de remplacement sans jamais ecraser"
```

---

### Task 8 : Les valeurs déjà employées

**Files:**
- Create: `lib/services/content_editor/known_values.dart`
- Test: `test/unit/content_editor/known_values_test.dart`

**Interfaces:**
- Consumes: `ContentFileSystem` (Task 1) ; `EntityDescriptor` (Task 2).
- Produces: `Map<String, List<String>> knownValues(ContentFileSystem fs, String rootPath, EntityDescriptor descriptor)`.

Le panneau « valeurs déjà utilisées » est **dérivé du disque**, jamais écrit à la main : il ne peut
donc pas se périmer. C'est lui qui rend `effectType` découvrable — chaîne libre côté modèle, mais
vocabulaire fermé côté moteur (`gain_armor`, `heal`, `gain_mana`, `gain_strength`…), qu'aucune
documentation ne liste.

- [ ] **Step 1 : Écrire le test (il doit échouer)**

Fichier `test/unit/content_editor/known_values_test.dart` :

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/known_values.dart';

void main() {
  late Directory sandbox;
  late String root;
  const fs = IoContentFileSystem();

  void write(String relative, String content) {
    final file = File('$root/$relative');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('known_values_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  test('rassemble les valeurs distinctes, triees', () {
    write('assets/data/relics/a.json',
        '{"trigger": "startOfRun", "effectType": "heal"}');
    write('assets/data/relics/b.json',
        '{"trigger": "startOfCombat", "effectType": "heal"}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.relic]!);

    expect(values['trigger'], ['startOfCombat', 'startOfRun']);
    expect(values['effectType'], ['heal']);
  });

  test('les cles de prose et l identifiant sont ecartes', () {
    write('assets/data/relics/a.json',
        '{"id": "a", "name_fr": "Amulette", "effectType": "heal"}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.relic]!);

    expect(values.containsKey('id'), isFalse);
    expect(values.containsKey('name_fr'), isFalse);
    expect(values['effectType'], ['heal']);
  });

  test('les listes de chaines sont aplaties', () {
    write('assets/data/forge_upgrades/a.json',
        '{"pools": ["common", "rare"]}');
    write('assets/data/forge_upgrades/b.json', '{"pools": ["rare"]}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.forgeUpgrade]!);

    expect(values['pools'], ['common', 'rare']);
  });

  test('une carte est cherchee a plat ET sous chaque classe', () {
    write('assets/data/cards/neutre.json', '{"animation": "melee"}');
    write('assets/data/classes/paladin/cards/smite.json',
        '{"animation": "buff"}');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.card]!);

    expect(values['animation'], ['buff', 'melee']);
  });

  test('une categorie en dossier lit le fichier que le dossier porte', () {
    write('assets/data/enemies/gobelin/enemy.json', '{"sfx": "hit_small"}');
    write('assets/data/enemies/orc/enemy.json', '{"sfx": "hit_big"}');
    // Un fichier egare a la racine de la categorie n'est pas une entite.
    write('assets/data/enemies/notes.txt', 'rien');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.enemy]!);

    expect(values['sfx'], ['hit_big', 'hit_small']);
  });

  test('un fichier illisible ne prive pas du panneau entier', () {
    write('assets/data/relics/bon.json', '{"effectType": "heal"}');
    write('assets/data/relics/casse.json', '{ pas du json');

    final values =
        knownValues(fs, root, kEntityDescriptors[EntityCategory.relic]!);

    expect(values['effectType'], ['heal']);
  });

  test('un repertoire absent rend une table vide, sans lever', () {
    expect(
      knownValues(fs, root, kEntityDescriptors[EntityCategory.event]!),
      isEmpty,
    );
  });
}
```

- [ ] **Step 2 : Lancer le test et vérifier qu'il échoue**

Commande : `flutter test test/unit/content_editor/known_values_test.dart`
Attendu : ÉCHEC — `known_values.dart` n'existe pas.

- [ ] **Step 3 : Écrire la dérivation**

Fichier `lib/services/content_editor/known_values.dart` :

```dart
import 'dart:convert';

import 'content_file_system.dart';
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

  for (final relative in _entityFiles(fs, rootPath, descriptor)) {
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

List<String> _entityFiles(
  ContentFileSystem fs,
  String rootPath,
  EntityDescriptor descriptor,
) {
  final base = 'assets/data/${descriptor.directory}';
  final files = <String>[];

  final folderFile = descriptor.folderFile;
  if (folderFile != null) {
    for (final entry in fs.listDirectory('$rootPath/$base')) {
      final candidate = '$base/$entry/$folderFile';
      if (fs.fileExists('$rootPath/$candidate')) files.add(candidate);
    }
    return files;
  }

  for (final name in fs.listDirectory('$rootPath/$base')) {
    if (name.endsWith('.json')) files.add('$base/$name');
  }

  // Une carte vit a plat **et** sous chaque classe. Les deux emplacements
  // portent le meme vocabulaire.
  if (descriptor.supportsHeroClass) {
    for (final heroClass in fs.listDirectory('$rootPath/assets/data/classes')) {
      final cards = 'assets/data/classes/$heroClass/cards';
      for (final name in fs.listDirectory('$rootPath/$cards')) {
        if (name.endsWith('.json')) files.add('$cards/$name');
      }
    }
  }

  return files;
}
```

- [ ] **Step 4 : Lancer le test et vérifier qu'il passe**

Commande : `flutter test test/unit/content_editor/known_values_test.dart`
Attendu : SUCCÈS, 7 tests.

- [ ] **Step 5 : `dart analyze` puis commit**

```bash
git add lib/services/content_editor/known_values.dart test/unit/content_editor/known_values_test.dart
git commit -m "feat(editeur): deriver du disque les valeurs deja employees"
```

---

### Task 9 : L'écran

**Files:**
- Create: `lib/services/content_editor/content_editor_providers.dart`
- Create: `lib/ui/screens/content_editor_screen.dart`
- Modify: `lib/ui/screens/home_screen.dart:212-231`
- Test: `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: tout ce que les tâches 1 à 8 produisent.
- Produces: `final contentFileSystemProvider = Provider<ContentFileSystem?>` ;
  `final projectRootProvider = Provider<String?>` ; `class ContentEditorScreen`.

L'écran arrive en dernier délibérément : les huit neuvièmes de la valeur sont dans des unités sans
interface, et c'est là que sont tous les tests qui comptent.

- [ ] **Step 1 : Écrire les providers**

Fichier `lib/services/content_editor/content_editor_providers.dart` :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_file_system.dart';
import 'platform_file_system.dart';
import 'project_root.dart';

/// Le systeme de fichiers de la plateforme, ou `null` sur le web.
final contentFileSystemProvider = Provider<ContentFileSystem?>(
  (ref) => platformFileSystem(),
);

/// La racine de l'arborescence source, ou `null` si l'application ne tourne
/// pas depuis une. L'ecran refuse alors de s'ouvrir : mieux vaut ne rien
/// pouvoir faire que d'ecrire au hasard.
final projectRootProvider = Provider<String?>((ref) {
  final fs = ref.watch(contentFileSystemProvider);
  return fs == null ? null : ProjectRoot.find(fs);
});
```

- [ ] **Step 2 : Écrire le test d'écran (il doit échouer)**

Fichier `test/widget/content_editor_screen_test.dart` :

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_editor_providers.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/ui/screens/content_editor_screen.dart';

void main() {
  late Directory sandbox;
  late String root;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('editor_screen_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
    Directory('$root/assets/data/relics').createSync(recursive: true);
    File('$root/pubspec.yaml').writeAsStringSync('name: sandbox\n');
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  Widget harness({required String? projectRoot}) {
    return ProviderScope(
      overrides: [
        contentFileSystemProvider.overrideWithValue(const IoContentFileSystem()),
        projectRootProvider.overrideWithValue(projectRoot),
      ],
      child: const MaterialApp(home: ContentEditorScreen()),
    );
  }

  testWidgets('sans racine, l ecran refuse et explique pourquoi',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: null));

    expect(find.textContaining('arborescence source'), findsOneWidget);
    expect(find.text('Ecrire'), findsNothing);
  });

  testWidgets('le chemin calcule est affiche et suit la categorie',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.pump();

    expect(
      find.textContaining('assets/data/cards/talisman.json'),
      findsOneWidget,
    );
  });

  testWidgets('un brouillon fautif est refuse sans rien ecrire',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    // Identifiant en majuscules : la famille 1 doit le refuser.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'Talisman');
    await tester.tap(find.text('Valider'));
    await tester.pump();

    expect(find.textContaining('minuscules'), findsOneWidget);
    expect(Directory('$root/assets/data').listSync(), hasLength(1));
  });
}
```

- [ ] **Step 3 : Lancer le test et vérifier qu'il échoue**

Commande : `flutter test test/widget/content_editor_screen_test.dart`
Attendu : ÉCHEC — `content_editor_screen.dart` n'existe pas.

- [ ] **Step 4 : Écrire l'écran**

Fichier `lib/ui/screens/content_editor_screen.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/data/game_data_registry.dart';
import '../../services/content_editor/content_editor_providers.dart';
import '../../services/content_editor/entity_descriptor.dart';
import '../../services/content_editor/entity_draft.dart';
import '../../services/content_editor/entity_validator.dart';
import '../../services/content_editor/entity_writer.dart';
import '../../services/content_editor/known_values.dart';

/// Editeur de contenu. **Hors run** : il ne touche a aucun etat de jeu, et le
/// verrou de persistance du lot 1 ne le concerne pas.
///
/// Les libelles sont en francais dans le code, exception delibaree et limitee
/// a cet ecran : ajouter des cles ARB pour un outil jamais publie serait un
/// cout pur.
class ContentEditorScreen extends ConsumerStatefulWidget {
  const ContentEditorScreen({super.key});

  @override
  ConsumerState<ContentEditorScreen> createState() =>
      _ContentEditorScreenState();
}

class _ContentEditorScreenState extends ConsumerState<ContentEditorScreen> {
  EntityCategory _category = EntityCategory.card;
  bool _isModification = false;
  String? _heroClass;

  final TextEditingController _id = TextEditingController();
  final TextEditingController _mechanics = TextEditingController();
  final Map<String, TextEditingController> _prose = {};

  List<ValidationFault> _faults = const [];
  WriteReport? _report;
  String? _failure;

  /// La table des valeurs connues, et la categorie pour laquelle elle a ete
  /// calculee. Voir [_knownValuesFor].
  EntityCategory? _valuesFor;
  Map<String, List<String>> _values = const {};

  EntityDescriptor get _descriptor => kEntityDescriptors[_category]!;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  @override
  void dispose() {
    _id.dispose();
    _mechanics.dispose();
    for (final controller in _prose.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadCategory() {
    _mechanics.text = _descriptor.template;
    for (final controller in _prose.values) {
      controller.dispose();
    }
    _prose.clear();
    for (final base in _descriptor.bilingualBases) {
      for (final suffix in const ['fr', 'en']) {
        _prose['${base}_$suffix'] = TextEditingController();
      }
    }
    _faults = const [];
    _report = null;
    _failure = null;
  }

  EntityDraft _draft() => EntityDraft(
        descriptor: _descriptor,
        id: _id.text.trim(),
        heroClass: _descriptor.supportsHeroClass ? _heroClass : null,
        isModification: _isModification,
        bilingual: {
          for (final entry in _prose.entries) entry.key: entry.value.text,
        },
        mechanics: _mechanics.text,
      );

  List<ValidationFault> _validate(String root) => EntityValidator(
        fs: ref.read(contentFileSystemProvider)!,
        rootPath: root,
        registry: GameDataRegistry.instance,
      ).validate(_draft());

  Future<void> _write(String root) async {
    final faults = _validate(root);
    setState(() {
      _faults = faults;
      _report = null;
      _failure = null;
    });
    // Decision E6 : rien n'est ecrit avant que la validation entiere passe.
    if (faults.isNotEmpty) return;

    try {
      final report = await EntityWriter(
        fs: ref.read(contentFileSystemProvider)!,
        rootPath: root,
      ).write(_draft());
      if (mounted) {
        setState(() {
          _report = report;
          // L'entite ecrite vient d'ajouter ses valeurs au vocabulaire.
          _valuesFor = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _failure = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = ref.watch(projectRootProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editeur de contenu')),
      body: root == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Cette application ne tourne pas depuis une arborescence "
                  "source : aucun repertoire parent ne porte a la fois "
                  "pubspec.yaml et assets/data/. L'editeur ne peut pas savoir "
                  "ou ecrire, et refuse donc de s'ouvrir.",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _form(root),
    );
  }

  Widget _form(String root) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              children: [
                _identityTriangle(root),
                const Divider(),
                for (final entry in _prose.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: entry.key),
                    ),
                  ),
                const Divider(),
                TextField(
                  controller: _mechanics,
                  maxLines: 14,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Mecanique (JSON)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _faults = _validate(root)),
                      child: const Text('Valider'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _write(root),
                      child: const Text('Ecrire'),
                    ),
                  ],
                ),
                _outcome(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _knownValuesPanel(root)),
        ],
      ),
    );
  }

  Widget _identityTriangle(String root) {
    final draft = _draft();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownButton<EntityCategory>(
              value: _category,
              items: [
                for (final entry in kEntityDescriptors.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value.label),
                  ),
              ],
              onChanged: _isModification
                  ? null
                  : (value) => setState(() {
                        if (value == null) return;
                        _category = value;
                        _heroClass = null;
                        _loadCategory();
                      }),
            ),
            const SizedBox(width: 16),
            // Le triangle d'identite est **gele** en modification : il decide
            // ou est le fichier, et le deplacer serait un renommage — hors
            // perimetre (E1).
            Switch(
              value: _isModification,
              onChanged: (value) => setState(() => _isModification = value),
            ),
            Text(_isModification ? 'Modifier' : 'Creer'),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('editeur-id'),
                controller: _id,
                enabled: !_isModification,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Identifiant'),
              ),
            ),
            if (_descriptor.supportsHeroClass) ...[
              const SizedBox(width: 16),
              DropdownButton<String?>(
                value: _heroClass,
                hint: const Text('neutre'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('neutre')),
                  for (final hero in GameDataRegistry.instance?.heroes ??
                      const <dynamic>[])
                    DropdownMenuItem(
                      value: hero.id as String,
                      child: Text(hero.id as String),
                    ),
                ],
                onChanged: _isModification
                    ? null
                    : (value) => setState(() => _heroClass = value),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Le retour le plus utile de l'ecran : la consequence du choix de
        // classe, montree avant l'ecriture.
        Text(
          draft.id.isEmpty ? '(identifiant requis)' : draft.path,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }

  Widget _outcome() {
    if (_failure != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text('Echec : $_failure'),
      );
    }
    if (_faults.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final fault in _faults) Text('• $fault')],
        ),
      );
    }
    final report = _report;
    if (report == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final path in report.written) Text('Ecrit : $path'),
          if (report.syncFailed)
            Text('sync_assets a echoue : ${report.sync!.output}'),
          // Voir §6.3 de la spec : la regle conservatrice, jusqu'a ce que la
          // verification manuelle permette de la resserrer.
          Text(
            report.relaunchAdvised
                ? 'Relancer `flutter run` pour que la nouvelle entite soit '
                    'chargee : le manifeste d assets est produit a la '
                    'compilation.'
                : 'Redemarrage a chaud pour voir la modification.',
          ),
        ],
      ),
    );
  }

  /// Le panneau relit tout le repertoire de la categorie : hors de question de
  /// le faire a chaque frappe. La table est donc retenue tant que la categorie
  /// ne change pas, et invalidee apres une ecriture — qui, elle, ajoute une
  /// valeur.
  Map<String, List<String>> _knownValuesFor(String root) {
    if (_valuesFor != _category) {
      _values = knownValues(
        ref.read(contentFileSystemProvider)!,
        root,
        _descriptor,
      );
      _valuesFor = _category;
    }
    return _values;
  }

  Widget _knownValuesPanel(String root) {
    final values = _knownValuesFor(root);

    return ListView(
      children: [
        const Text(
          'Valeurs deja utilisees',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final entry in values.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${entry.key} : ${entry.value.join(', ')}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5 : Lancer le test et vérifier qu'il passe**

Commande : `flutter test test/widget/content_editor_screen_test.dart`
Attendu : SUCCÈS, 3 tests.

- [ ] **Step 6 : Ajouter le bouton d'entrée sur l'accueil**

Dans `lib/ui/screens/home_screen.dart`, à l'intérieur du bloc `if (kDebugMode) ...[` existant
(ligne 212), **après** le bouton `RUN DEBUG` qui s'y trouve déjà, insérer :

```dart
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 14,
                                    ),
                                    backgroundColor: Colors.teal,
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ContentEditorScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'EDITEUR DE CONTENU',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
```

Et l'import en tête du fichier :

```dart
import 'content_editor_screen.dart';
```

- [ ] **Step 7 : Suite complète et analyse**

Commande : `flutter test`
Attendu : tout vert.

Commande : `dart analyze`
Attendu : `No issues found!`

Commande : `grep -rn "import 'dart:io'" lib/`
Attendu : **une seule ligne**, dans `content_file_system_io.dart`.

- [ ] **Step 8 : Vérifier que la cible web compile toujours**

C'est la garde qui justifie tout le seam de la Task 1, et c'est le seul moyen de savoir qu'il tient.

Commande : `flutter build web --release`
Attendu : succès. Un échec mentionnant `dart:io` signifie qu'un import a fui hors de
`content_file_system_io.dart`.

- [ ] **Step 9 : Commit**

```bash
git add lib/services/content_editor/content_editor_providers.dart lib/ui/screens/content_editor_screen.dart lib/ui/screens/home_screen.dart test/widget/content_editor_screen_test.dart
git commit -m "feat(editeur): ouvrir l ecran d edition depuis l accueil en debug"
```

---

## Après le plan

**Vérifications manuelles dues** — aucune ne se mécanise, et la première conditionne un message
affiché à l'utilisateur :

1. **Ce que voit réellement le jeu après une écriture** (§6.3 de la spec). Établir, pour chacun des
   trois gestes — modifier une entité, en créer une, créer une classe ou un ennemi — ce qui suffit :
   redémarrage à chaud, ou relance de `flutter run`. **Puis resserrer le message de `_outcome()` sur
   ce qui a été observé.** La spec retient la règle conservatrice tant que l'observation n'est pas
   faite ; on ne promet pas un comportement dont on n'a pas le témoin.
2. Créer une entité de chacune des sept catégories, relancer, et vérifier qu'elle apparaît en jeu.
3. Créer une classe, puis une carte pour elle, et confirmer que `flutter test` reste vert — c'est
   l'intégrité référentielle qui se prononce.

**Gestes de suivi, hors de ce plan :**

- Cocher le chantier dans `docs/ROADMAP.md` et faire une passe `memory-bank-sync`.
- **Ne pas rédiger de patch note.** Cet outil n'est visible d'aucun joueur : pas d'entrée dans
  `patch_notes.json`, pas de changement de version.
- Envisager un ADR sur le seam de plateforme : `lib/` n'importait `dart:io` nulle part, et ce lot
  établit la règle qui le maintient confiné.
