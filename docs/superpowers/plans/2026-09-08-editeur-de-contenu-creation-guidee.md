# Éditeur de contenu — création guidée et identité de classe en donnée — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** rendre une classe entièrement créable depuis l'éditeur de contenu, en un geste, et sortir son identité visuelle du code.

**Architecture:** deux étapes ordonnées. **A** (tâches 1-3) rend la donnée de classe honnête — `classCard` au lieu d'un `iconPath` qui désignait une carte de 1696 × 2528, `themeColor` sorti des `if` du dialogue de stats, `armorMastery` rendu écrivable. **B** (tâches 4-11) ajoute au moteur une transaction partagée, le remplissage des champs vides, un catalogue d'entités et la recette de classe, puis remplace la liste déroulante de l'écran par un arbre de boutons à trois niveaux. B consomme la donnée que A crée : l'ordre n'est pas négociable.

**Tech Stack:** Flutter 3.x / Dart, Riverpod 2.x (`Notifier` / `NotifierProvider`), `flutter_test`, `flutter_colorpicker` (ajouté en tâche 9).

**Spec:** `docs/superpowers/specs/2026-09-08-editeur-de-contenu-creation-guidee-design.md`

## Global Constraints

- **`dart analyze` doit être propre — zéro problème — après chaque tâche**, avant de la considérer terminée.
- **Ne jamais lancer `dart format`** : le dépôt n'y a jamais été passé, 120 des 185 fichiers de `lib/` changeraient. Le code nouveau suit son voisinage, pas l'outil.
- **Messages de commit en français, conventional commits, sans accent dans la ligne de sujet** (le corps peut en porter). Chaque commit se termine par `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- **`assets/data/patch_notes.json` ne se modifie jamais à la main** — il appartient au skill `patch-notes-writer`.
- **`.obsidian_vault/_memory_bank/`, `_adr/`, `_rules/`, `_patterns/`** appartiennent au skill `memory-bank-sync`. `.obsidian_vault/_archive/` est en lecture seule.
- **Un test doit pouvoir échouer.** Chaque tâche écrit le test d'abord, le voit rouge, puis le rend vert. Un test qu'on n'a pas vu rouge ne prouve rien — c'est le défaut qui est revenu cinq fois sur la branche du lot 2.
- **Toute entité JSON portant du texte visible doit avoir ses deux variantes `_fr` et `_en`.**
- **`heroClass` et `category` ne s'écrivent jamais dans un fichier de carte** : le répertoire les impose et le chargeur rejette le fichier qui les déclare.
- **`Color.value` est déprécié dans ce SDK** (Flutter 3.41.6) : employer `toARGB32()`. Un membre déprécié fait sortir `dart analyze` du zéro problème exigé plus haut.
- Suite complète : `flutter test`. Fichier seul : `flutter test test/unit/<fichier>.dart`. Un test seul : `flutter test --plain-name "<nom>"`.

---

## Structure des fichiers

**Créés**

| Fichier | Responsabilité |
|:---|:---|
| `lib/services/content_editor/entity_catalog.dart` | Lister ce qui existe sur le disque : les fichiers d'une catégorie, et les identifiants groupés par propriétaire |
| `lib/services/content_editor/placeholder_filler.dart` | Compléter un brouillon incomplet **avant** que le validateur ne le juge |
| `lib/services/content_editor/class_recipe.dart` | Une classe complète en un geste : `class.json` puis ses N cartes de signature |
| `lib/ui/widgets/content_editor/tree_level.dart` | Un niveau de l'arbre : une rangée de boutons, un sélectionné, une tabulation |
| `lib/ui/widgets/content_editor/entity_form.dart` | Le formulaire, création comme modification |
| `lib/ui/widgets/content_editor/color_field.dart` | Le champ couleur et sa roue |

**Modifiés**

| Fichier | Ce qui change |
|:---|:---|
| `lib/models/data/hero_data.dart` | `classCard`, `iconPath` optionnel, `themeColor` |
| `lib/models/data/game_data_registry.dart:44` | Précharge `classCard` |
| `lib/game/systems/state_sync_system.dart:52` | Passe `classCard` à `HeroCard` |
| `lib/ui/widgets/map/dialogs/stats_dialog.dart:47-76` | Lit la donnée au lieu des six `if` |
| `lib/services/content_editor/entity_descriptor.dart` | `imageName` accepte le jeton `{id}`, `imagePathKey` vise `classCard`, gabarit de classe complété |
| `lib/services/content_editor/entity_validator.dart` | Bijection `skills` ↔ `cards/` |
| `lib/services/content_editor/entity_writer.dart` | `writeAll` : une transaction pour plusieurs brouillons |
| `lib/services/content_editor/known_values.dart` | Délègue son énumération de fichiers à `entity_catalog.dart` |
| `lib/ui/screens/content_editor_screen.dart` | Réécrit : arbre à la place de la liste déroulante |
| `assets/data/classes/*/class.json` (×3) | `classCard`, `themeColor` |
| `pubspec.yaml` | `flutter_colorpicker` |

---

## Task 1 : `HeroData` nomme ses images pour ce qu'elles sont

**Files:**
- Modify: `lib/models/data/hero_data.dart`
- Modify: `lib/models/data/game_data_registry.dart:44`
- Modify: `lib/game/systems/state_sync_system.dart:52`
- Modify: `assets/data/classes/{paladin,berserker,mage}/class.json`
- Rename: `assets/data/classes/<id>/icon.png` → `assets/data/classes/<id>/<id>.png`
- Test: `test/unit/hero_data_identity_test.dart` (créé), `test/unit/game_data_registry_preload_test.dart`

**Interfaces:**
- Produces: `HeroData.classCard` (`String`, requis), `HeroData.iconPath` (`String?`), `HeroData.themeColor` (`int?`, ARGB). Les tâches 2, 3, 8 et 11 en dépendent.

- [ ] **Step 1 : écrire le test qui échoue**

Créer `test/unit/hero_data_identity_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  Map<String, dynamic> base() => {
        'id': 'gambler',
        'name_fr': 'Le Parieur',
        'name_en': 'Gambler',
        'description_fr': 'Manipule les probabilites.',
        'description_en': 'Plays the odds.',
        'classCard': 'assets/data/classes/gambler/gambler.png',
        'maxHp': 100,
        'maxMana': 3,
        'baseDamage': 5,
      };

  test('classCard est lu, et iconPath vaut null quand il est absent', () {
    final hero = HeroData.fromJson(base());
    expect(hero.classCard, 'assets/data/classes/gambler/gambler.png');
    expect(hero.iconPath, isNull);
  });

  test('iconPath est lu quand il est present', () {
    final hero = HeroData.fromJson(
      base()..['iconPath'] = 'assets/data/classes/gambler/icon.png',
    );
    expect(hero.iconPath, 'assets/data/classes/gambler/icon.png');
  });

  test('themeColor decode #RRGGBB en ARGB opaque', () {
    final hero = HeroData.fromJson(base()..['themeColor'] = '#B71C1C');
    expect(hero.themeColor, 0xFFB71C1C);
  });

  // Une couleur fausse ne doit pas faire echouer le chargement du jeu entier :
  // `fromJson` est une couche de compatibilite, pas un validateur. C'est
  // l'editeur qui refuse d'ecrire une couleur malformee, pas le chargeur qui
  // refuse de demarrer.
  test('une themeColor malformee vaut null plutot que de lever', () {
    for (final bad in const ['B71C1C', '#XYZ', '#B71C1', '', '#B71C1CFF']) {
      expect(
        HeroData.fromJson(base()..['themeColor'] = bad).themeColor,
        isNull,
        reason: 'valeur refusee : "$bad"',
      );
    }
  });
}
```

- [ ] **Step 2 : lancer le test, vérifier qu'il échoue**

Run: `flutter test test/unit/hero_data_identity_test.dart`
Expected: FAIL — la compilation échoue, `classCard` n'existe pas sur `HeroData`.

- [ ] **Step 3 : modifier le modèle**

Dans `lib/models/data/hero_data.dart`, remplacer le champ `iconPath` et son usage dans le constructeur et `fromJson` :

```dart
  /// L'image de la carte de classe — 1696 x 2528 pour les trois classes
  /// livrees. C'est elle que `HeroCard` affiche en combat.
  final String classCard;

  /// Une vraie icone, petite, optionnelle. Absente des trois classes livrees :
  /// le dialogue de stats replie alors sur [classCard].
  final String? iconPath;

  /// La couleur d'accent de la classe, en ARGB opaque. `null` quand elle n'est
  /// pas declaree — le lecteur choisit son repli.
  final int? themeColor;
```

Constructeur : remplacer `required this.iconPath,` par

```dart
    required this.classCard,
    this.iconPath,
    this.themeColor,
```

`fromJson` : remplacer `iconPath: json['iconPath'] as String,` par

```dart
      classCard: json['classCard'] as String,
      iconPath: json['iconPath'] as String?,
      themeColor: _parseHexColor(json['themeColor']),
```

et ajouter, à la fin de la classe :

```dart
  /// `#RRGGBB` -> `0xFFRRGGBB`. `null` pour tout le reste.
  static int? _parseHexColor(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value);
    if (match == null) return null;
    return 0xFF000000 | int.parse(match.group(1)!, radix: 16);
  }
```

- [ ] **Step 4 : lancer le test, vérifier qu'il passe**

Run: `flutter test test/unit/hero_data_identity_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5 : renommer les trois images et migrer les trois JSON**

```bash
for c in paladin berserker mage; do
  git mv "assets/data/classes/$c/icon.png" "assets/data/classes/$c/$c.png"
done
```

Dans chacun des trois `assets/data/classes/<id>/class.json`, remplacer la ligne

```json
  "iconPath": "assets/data/classes/<id>/icon.png",
```

par les deux lignes

```json
  "classCard": "assets/data/classes/<id>/<id>.png",
  "themeColor": "<couleur>",
```

avec `<couleur>` reprenant exactement ce que le code affiche aujourd'hui (`stats_dialog.dart:47-49`) : `#2196F3` pour `paladin` (`Colors.blue`), `#F44336` pour `berserker` (`Colors.red`), `#9C27B0` pour `mage` (`Colors.purple`).

- [ ] **Step 6 : faire suivre les deux lecteurs**

`lib/models/data/game_data_registry.dart:44` — `...heroes.map((h) => h.iconPath),` devient :

```dart
        ...heroes.map((h) => h.classCard),
```

`lib/game/systems/state_sync_system.dart:52` — `imagePath: heroData.iconPath,` devient :

```dart
        imagePath: heroData.classCard,
```

- [ ] **Step 7 : laisser le compilateur énumérer les sites d'appel restants**

Run: `dart analyze`

`classCard` étant requis, l'analyseur liste **exactement** chaque `HeroData(...)` qui ne le passe pas — une trentaine, tous dans `test/`. Dans chacun, renommer l'argument `iconPath:` en `classCard:`. Ne pas chercher à les deviner : la liste de l'analyseur est la liste complète.

- [ ] **Step 8 : mettre à jour le test de préchargement**

Dans `test/unit/game_data_registry_preload_test.dart`, les `HeroData(...)` construits passent désormais `classCard:`. Ajouter à ce fichier l'assertion qui manquait :

```dart
  // Sans cette assertion, un retour de `imagesToPreload` a l'ancien champ
  // passerait inapercu : Flame ne prechargerait plus la seule grande image
  // qu'il prechargeait, et rien n'echouerait avant l'affichage.
  test('imagesToPreload prend la carte de classe, pas l icone', () {
    final registry = GameDataRegistry(
      cards: const [],
      relics: const [],
      events: const [],
      passives: const [],
      forgeUpgrades: const [],
      heroes: const [
        HeroData(
          id: 'gambler',
          classCard: 'assets/data/classes/gambler/gambler.png',
          iconPath: 'assets/data/classes/gambler/icon.png',
          maxHp: 100,
          maxMana: 3,
          baseDamage: 5,
        ),
      ],
      enemies: const [],
      audio: AudioData.empty(),
    );

    expect(
      registry.imagesToPreload,
      contains('assets/data/classes/gambler/gambler.png'),
    );
    expect(
      registry.imagesToPreload,
      isNot(contains('assets/data/classes/gambler/icon.png')),
    );
  });
```

> Adapter les arguments du constructeur `GameDataRegistry` à ceux que le fichier de test emploie déjà — le reste du fichier montre la forme exacte, y compris pour `audio`.

- [ ] **Step 9 : lancer la suite complète et l'analyse**

Run: `flutter test` puis `dart analyze`
Expected: tout vert, zéro problème. `referential_integrity_test` et `real_bundle_load_test` chargent le vrai bundle : ils échoueraient si un `class.json` avait été mal migré.

- [ ] **Step 10 : vérifier que le manifeste d'assets n'a pas bougé**

Run: `dart run tool/sync_assets.dart --check`
Expected: exit 0. Les assets sont déclarés par dossier, donc renommer un fichier à l'intérieur ne touche pas `pubspec.yaml`. Un exit 1 signale une erreur de renommage, pas une dérive normale.

- [ ] **Step 11 : commit**

```bash
git add -A
git commit -m "feat(donnees): nommer la carte de classe pour ce qu elle est"
```

---

## Task 2 : le dialogue de stats lit la donnée

**Files:**
- Modify: `lib/ui/widgets/map/dialogs/stats_dialog.dart:47-76`
- Test: `test/widget/stats_dialog_identity_test.dart` (créé)

**Interfaces:**
- Consumes: `HeroData.themeColor`, `HeroData.iconPath`, `HeroData.classCard` (tâche 1).

- [ ] **Step 1 : écrire le test qui échoue**

Créer `test/widget/stats_dialog_identity_test.dart`. Le test emploie une classe fictive dont la couleur n'est **aucune** des trois codées en dur — sans quoi il passerait avec l'ancien code.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  const hero = HeroData(
    id: 'gambler',
    nameFr: 'Le Parieur',
    nameEn: 'Gambler',
    classCard: 'assets/data/classes/gambler/gambler.png',
    themeColor: 0xFF00A88F, // aucune des trois couleurs en dur
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );

  test('la couleur vient de la donnee', () {
    expect(StatsDialog.classColorOf(hero), const Color(0xFF00A88F));
  });

  test('une classe sans themeColor retombe sur le bleu d origine', () {
    const plain = HeroData(
      id: 'plain',
      classCard: 'assets/data/classes/plain/plain.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    );
    expect(StatsDialog.classColorOf(plain), Colors.blue);
  });

  test('l image affichee est l icone quand elle existe, la carte sinon', () {
    expect(StatsDialog.classImageOf(hero),
        'assets/data/classes/gambler/gambler.png');

    const withIcon = HeroData(
      id: 'gambler',
      classCard: 'assets/data/classes/gambler/gambler.png',
      iconPath: 'assets/data/classes/gambler/icon.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    );
    expect(StatsDialog.classImageOf(withIcon),
        'assets/data/classes/gambler/icon.png');
  });
}
```

Ajouter l'import du dialogue en tête :
`import 'package:roguelike_card_game/ui/widgets/map/dialogs/stats_dialog.dart';`

- [ ] **Step 2 : lancer le test, vérifier qu'il échoue**

Run: `flutter test test/widget/stats_dialog_identity_test.dart`
Expected: FAIL — `classColorOf` et `classImageOf` n'existent pas.

- [ ] **Step 3 : exposer les deux choix, et supprimer les six `if`**

Dans `lib/ui/widgets/map/dialogs/stats_dialog.dart`, ajouter à la classe `StatsDialog` :

```dart
  /// La couleur d'accent de la classe. Statique et publique pour etre
  /// testable sans monter tout le dialogue, qui exige un `runProvider` peuple
  /// et un registre charge.
  static Color classColorOf(HeroData hero) =>
      hero.themeColor == null ? Colors.blue : Color(hero.themeColor!);

  /// L'image montree dans la pastille : la vraie icone si elle existe, la
  /// carte de classe sinon. Le repli evite un carre magenta tant qu'aucune
  /// icone n'est dessinee.
  static String classImageOf(HeroData hero) => hero.iconPath ?? hero.classCard;
```

Ajouter l'import `import '../../../../models/data/hero_data.dart';`.

Puis remplacer les lignes 47-54 par :

```dart
    final classColor = classColorOf(heroData);
```

et, à la ligne qui portait `Icon(classIcon, color: classColor, size: 36)`, mettre :

```dart
          ClipOval(
            child: Image.asset(
              classImageOf(heroData),
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
```

Les deux autres usages de `classColor` (`glowColor:` et `color:`) ne changent pas.

- [ ] **Step 4 : lancer le test, vérifier qu'il passe**

Run: `flutter test test/widget/stats_dialog_identity_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5 : vérifier qu'aucun `classIcon` ne subsiste**

Run: `grep -n "classIcon" lib/ui/widgets/map/dialogs/stats_dialog.dart`
Expected: aucune ligne. Puis `dart analyze` — l'import de `sword_icon.dart` reste utilisé ailleurs dans le fichier ; ne le retirer que si l'analyseur le signale inutilisé.

- [ ] **Step 6 : commit**

```bash
git add -A
git commit -m "feat(ui): lire l identite de classe dans la donnee, pas dans six if"
```

---

## Task 3 : le descripteur suit le renommage, et le gabarit cesse de mentir

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart` (`imagePathOf`, descripteur `heroClass`)
- Test: `test/unit/content_editor/entity_descriptor_test.dart`

**Interfaces:**
- Produces: `EntityDescriptor.imageName` accepte le jeton `{id}` ; `imagePathOf('gambler')` rend `assets/data/classes/gambler/gambler.png` pour la classe et `assets/data/enemies/gobelin/sprite.png` pour l'ennemi. Les tâches 5 et 8 en dépendent.

- [ ] **Step 1 : écrire les tests qui échouent**

Ajouter à `test/unit/content_editor/entity_descriptor_test.dart` :

```dart
  test('le chemin d image d une classe porte son identifiant', () {
    expect(
      kEntityDescriptors[EntityCategory.heroClass]!.imagePathOf('gambler'),
      'assets/data/classes/gambler/gambler.png',
    );
  });

  test('le chemin d image d un ennemi reste constant', () {
    expect(
      kEntityDescriptors[EntityCategory.enemy]!.imagePathOf('gobelin'),
      'assets/data/enemies/gobelin/sprite.png',
    );
  });

  test('la classe ecrit son image sous classCard', () {
    expect(
      kEntityDescriptors[EntityCategory.heroClass]!.imagePathKey,
      'classCard',
    );
  });

  // `armorMastery` est lu par run_controller.dart:253 et applique a chaque
  // gain d armure. Absent du gabarit, il etait invisible dans l editeur et
  // valait 0 pour les trois classes sans que personne l ait decide.
  test('le gabarit de classe expose toutes les stats que le modele lit', () {
    final template =
        kEntityDescriptors[EntityCategory.heroClass]!.decodeTemplate();
    for (final key in const [
      'maxHp',
      'maxMana',
      'baseDamage',
      'luck',
      'armorMastery',
      'displayOrder',
      'themeColor',
    ]) {
      expect(template.containsKey(key), isTrue, reason: 'clé absente : $key');
    }
  });
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/entity_descriptor_test.dart`
Expected: FAIL sur les quatre — le chemin rend `.../gambler/icon.png`, la clé vaut `iconPath`, `armorMastery` et `themeColor` manquent au gabarit.

- [ ] **Step 3 : implémenter le jeton et compléter le gabarit**

Dans `lib/services/content_editor/entity_descriptor.dart`, remplacer `imagePathOf` :

```dart
  /// Le chemin de l'image, pour les categories qui en portent une.
  ///
  /// [imageName] peut porter le jeton `{id}` : la carte d'une classe est
  /// nommee d'apres elle (`gambler/gambler.png`), la ou le sprite d'un ennemi
  /// porte un nom constant.
  String? imagePathOf(String id) {
    final name = imageName;
    if (name == null) return null;
    return 'assets/data/$directory/$id/${name.replaceAll('{id}', id)}';
  }
```

Et dans le descripteur `EntityCategory.heroClass` :

```dart
    imageName: '{id}.png',
    imagePathKey: 'classCard',
```

en remplaçant le commentaire du gabarit et le gabarit lui-même par :

```dart
    // Ni `classCard` ni `skills` ne figurent au gabarit : l'ecrivain calcule
    // le premier, et `_registerSignatureCard` remplit le second a chaque carte
    // de classe ecrite. `themeColor` y figure au magenta : une classe dont la
    // couleur n'a pas ete choisie doit se voir.
    template: '''
{
  "maxHp": 100,
  "maxMana": 3,
  "baseDamage": 5,
  "luck": 0,
  "armorMastery": 0,
  "displayOrder": 99,
  "themeColor": "#FF00FF"
}''',
```

- [ ] **Step 4 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/entity_descriptor_test.dart`
Expected: PASS.

- [ ] **Step 5 : lancer la suite et l'analyse**

Run: `flutter test` puis `dart analyze`
Expected: tout vert. `entity_writer_test.dart` teste le dépôt d'image : si un cas y attendait `icon.png`, le corriger en `<id>.png` — c'est le renommage, pas une régression.

- [ ] **Step 6 : commit**

```bash
git add -A
git commit -m "feat(editeur): deriver le nom de l image de l identifiant, et completer le gabarit"
```

---

## Task 4 : la bijection `skills` ↔ `cards/`

**Files:**
- Modify: `lib/services/content_editor/entity_validator.dart`
- Test: `test/unit/content_editor/entity_validator_test.dart`

**Interfaces:**
- Produces: une famille de validation supplémentaire, évaluée après `_references` et avant `_construct`. Aucune signature publique ne change : `EntityValidator.validate(EntityDraft)` rend toujours `List<ValidationFault>`.

- [ ] **Step 1 : écrire les tests qui échouent**

Ajouter à `test/unit/content_editor/entity_validator_test.dart`. Le bac à sable de ce fichier suit le patron déjà présent (`Directory.systemTemp.createTempSync`) ; réutiliser ses helpers.

```dart
  group('bijection skills <-> cards/', () {
    /// Une classe sur le disque, avec deux cartes dans son dossier.
    void seedClassWithTwoCards() {
      Directory('$root/assets/data/classes/gambler/cards')
          .createSync(recursive: true);
      for (final id in const ['bluff', 'all_in']) {
        File('$root/assets/data/classes/gambler/cards/$id.json')
            .writeAsStringSync('{}');
      }
      File('$root/assets/data/classes/gambler/class.json')
          .writeAsStringSync('{}');
    }

    EntityDraft classDraft(String skillsJson) => EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.heroClass]!,
          id: 'gambler',
          bilingual: const {
            'name_fr': 'Le Parieur',
            'name_en': 'Gambler',
            'description_fr': 'Manipule les probabilites.',
            'description_en': 'Plays the odds.',
          },
          mechanics: '{"maxHp": 100, "maxMana": 3, "baseDamage": 5, '
              '"skills": $skillsJson}',
          isModification: true,
        );

    test('un skills exact est accepte', () {
      seedClassWithTwoCards();
      final faults = validator().validate(classDraft('["all_in", "bluff"]'));
      expect(faults, isEmpty);
    });

    test('une carte declaree mais absente du dossier est refusee', () {
      seedClassWithTwoCards();
      final faults =
          validator().validate(classDraft('["all_in", "bluff", "fantome"]'));
      expect(faults.map((f) => f.toString()).join(), contains('fantome'));
    });

    // L'autre sens compte autant : une carte presente et non declaree serait
    // chargee dans le pool de la classe sans que rien ne le dise, et
    // referential_integrity_test rougirait bien plus tard.
    test('une carte presente mais absente de skills est refusee', () {
      seedClassWithTwoCards();
      final faults = validator().validate(classDraft('["bluff"]'));
      expect(faults.map((f) => f.toString()).join(), contains('all_in'));
    });

    test('une classe creee, sans dossier cards/ ni skills, passe', () {
      final faults = validator().validate(
        EntityDraft(
          descriptor: kEntityDescriptors[EntityCategory.heroClass]!,
          id: 'nouveau',
          bilingual: const {
            'name_fr': 'Nouveau',
            'name_en': 'New',
            'description_fr': 'Rien.',
            'description_en': 'Nothing.',
          },
          mechanics: '{"maxHp": 100, "maxMana": 3, "baseDamage": 5}',
        ),
      );
      expect(faults, isEmpty);
    });
  });
```

> `validator()` et `root` suivent la forme déjà employée par le fichier. S'il n'y a pas de helper `validator()`, construire `EntityValidator(fs: const IoContentFileSystem(), rootPath: root)` comme le font les tests voisins.

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/entity_validator_test.dart`
Expected: les deux tests de refus échouent — rien ne contrôle encore `skills`.

- [ ] **Step 3 : implémenter la famille**

Dans `lib/services/content_editor/entity_validator.dart`, ajouter la fonction à la liste des familles, entre `_references` et `_construct` :

```dart
      () => _references(draft, mechanics),
      () => _signatureCards(draft, mechanics),
      () => _construct(draft),
```

Et la méthode :

```dart
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
```

- [ ] **Step 4 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/entity_validator_test.dart`
Expected: PASS.

- [ ] **Step 5 : prouver que le contrôle peut échouer**

Commenter temporairement la ligne `() => _signatureCards(draft, mechanics),` puis relancer le fichier : les deux tests de refus doivent virer au rouge. Rétablir la ligne. Un contrôle qu'on n'a pas vu manquer ne prouve rien.

- [ ] **Step 6 : lancer la suite et l'analyse, puis commit**

Run: `flutter test` puis `dart analyze`

```bash
git add -A
git commit -m "feat(editeur): exiger la bijection entre skills et le dossier cards"
```

---

## Task 5 : une transaction partagée dans l'écrivain

**Files:**
- Modify: `lib/services/content_editor/entity_writer.dart`
- Test: `test/unit/content_editor/entity_writer_test.dart`

**Interfaces:**
- Produces: `Future<WriteReport> EntityWriter.writeAll(List<EntityDraft> drafts)`. `write(draft)` subsiste et délègue à `writeAll([draft])`. La tâche 8 consomme `writeAll`.

- [ ] **Step 1 : écrire les tests qui échouent**

Ajouter à `test/unit/content_editor/entity_writer_test.dart` :

```dart
  test('writeAll ecrit tous les brouillons et ne synchronise qu une fois', () async {
    final fs = RecordingFileSystem(root); // le double deja present dans ce fichier
    final report = await EntityWriter(fs: fs, rootPath: root).writeAll([
      classDraft('gambler'),
      classCardDraft('gambler', 'bluff'),
      classCardDraft('gambler', 'all_in'),
    ]);

    expect(report.written, hasLength(greaterThanOrEqualTo(3)));
    expect(fs.syncRuns, 1, reason: 'un dart run par carte serait insupportable');
  });

  // Le point entier de la transaction : sans pile partagee, les deux premieres
  // ecritures resteraient sur le disque et laisseraient une classe a moitie
  // creee — precisement l'etat que referential_integrity_test refuse.
  test('un echec en cours de route defait ce qui precede', () async {
    final fs = FailingOnNthWrite(root, failAt: 3);
    final writer = EntityWriter(fs: fs, rootPath: root);

    await expectLater(
      writer.writeAll([
        classDraft('gambler'),
        classCardDraft('gambler', 'bluff'),
        classCardDraft('gambler', 'all_in'),
      ]),
      throwsA(anything),
    );

    expect(File('$root/assets/data/classes/gambler/class.json').existsSync(),
        isFalse);
    expect(
      File('$root/assets/data/classes/gambler/cards/bluff.json').existsSync(),
      isFalse,
    );
  });

  test('writeAll conseille la recompilation des qu une creation y figure',
      () async {
    final fs = RecordingFileSystem(root);
    final report = await EntityWriter(fs: fs, rootPath: root)
        .writeAll([classDraft('gambler')]);
    expect(report.relaunchAdvised, isTrue);
  });
```

> Les doubles `RecordingFileSystem` et les helpers `classDraft` / `classCardDraft` suivent ce que le fichier emploie déjà. `FailingOnNthWrite` est un double nouveau : il délègue tout à `IoContentFileSystem` mais lève sur le n-ième appel à `writeFile`. Compter `syncRuns` dans `run()` si le double ne le fait pas encore.

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/entity_writer_test.dart`
Expected: FAIL — `writeAll` n'existe pas.

- [ ] **Step 3 : implémenter**

Dans `lib/services/content_editor/entity_writer.dart`, remplacer `write` par :

```dart
  /// Ecrit un brouillon. Raccourci sur [writeAll].
  Future<WriteReport> write(EntityDraft draft) => writeAll([draft]);

  /// Ecrit plusieurs brouillons comme **un seul geste**.
  ///
  /// Les etapes partagent une pile de rollback : si le troisieme echoue, les
  /// deux premiers sont defaits. Une classe a moitie creee est precisement
  /// l'etat que `referential_integrity_test` refuse, et il ne doit pas pouvoir
  /// naitre d'une panne d'ecriture.
  ///
  /// `sync_assets` ne tourne qu'une fois, a la fin : c'est un `dart run`, et
  /// un par carte rendrait la recette inutilisable.
  Future<WriteReport> writeAll(List<EntityDraft> drafts) async {
    final steps = <WriteStep>[];
    try {
      for (final draft in drafts) {
        _writeFiles(draft, steps);
      }
    } catch (_) {
      _rollback(steps);
      rethrow;
    }

    final sync = await _runSyncAssets();

    return WriteReport(
      written: [for (final step in steps) step.relative],
      sync: sync,
      relaunchAdvised: drafts.any((draft) => !draft.isModification),
    );
  }
```

- [ ] **Step 4 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/entity_writer_test.dart`
Expected: PASS. Les tests existants de `write` passent inchangés — c'est la garantie que la délégation ne change rien.

- [ ] **Step 5 : lancer la suite et l'analyse, puis commit**

Run: `flutter test` puis `dart analyze`

```bash
git add -A
git commit -m "feat(editeur): ecrire plusieurs brouillons dans une seule transaction"
```

---

## Task 6 : compléter un brouillon plutôt que le refuser

**Files:**
- Create: `lib/services/content_editor/placeholder_filler.dart`
- Test: `test/unit/content_editor/placeholder_filler_test.dart` (créé)

**Interfaces:**
- Produces: `EntityDraft fillPlaceholders(EntityDraft draft)`. Les tâches 8 et 11 l'appellent **avant** `EntityValidator.validate`.

- [ ] **Step 1 : écrire les tests qui échouent**

Créer `test/unit/content_editor/placeholder_filler_test.dart` :

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';
import 'package:roguelike_card_game/services/content_editor/placeholder_filler.dart';

void main() {
  EntityDraft draft({
    Map<String, String> bilingual = const {},
    String mechanics = '{}',
  }) =>
      EntityDraft(
        descriptor: kEntityDescriptors[EntityCategory.relic]!,
        id: 'talisman',
        bilingual: bilingual,
        mechanics: mechanics,
      );

  test('la prose vide recoit un placeholder criard', () {
    final filled = fillPlaceholders(draft());
    expect(filled.bilingual['name_fr'], '[À REMPLIR] talisman');
    expect(filled.bilingual['description_en'], '[À REMPLIR] talisman');
  });

  test('la prose saisie n est jamais ecrasee', () {
    final filled = fillPlaceholders(
      draft(bilingual: const {'name_fr': 'Talisman de fer'}),
    );
    expect(filled.bilingual['name_fr'], 'Talisman de fer');
    expect(filled.bilingual['name_en'], '[À REMPLIR] talisman');
  });

  test('une cle absente du corps prend la valeur du gabarit', () {
    final filled = fillPlaceholders(draft(mechanics: '{"value": 7}'));
    final decoded = jsonDecode(filled.mechanics) as Map<String, dynamic>;
    final template =
        kEntityDescriptors[EntityCategory.relic]!.decodeTemplate();

    expect(decoded['value'], 7, reason: 'la saisie prime sur le gabarit');
    for (final key in template.keys) {
      expect(decoded.containsKey(key), isTrue, reason: 'clé absente : $key');
    }
  });

  // Un corps illisible n'est pas l'affaire du remplisseur : le validateur sait
  // dire *pourquoi* il ne decode pas, et ce message-la vaut mieux qu'un
  // ecrasement silencieux par le gabarit.
  test('un corps JSON invalide ressort inchange', () {
    final broken = draft(mechanics: '{ pas du json');
    expect(fillPlaceholders(broken).mechanics, '{ pas du json');
  });
}
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/placeholder_filler_test.dart`
Expected: FAIL — le fichier `placeholder_filler.dart` n'existe pas.

- [ ] **Step 3 : implémenter**

Créer `lib/services/content_editor/placeholder_filler.dart` :

```dart
import 'dart:convert';

import 'entity_draft.dart';

/// Ce qu'on ecrit dans un champ de prose laisse vide. Volontairement voyant :
/// un nom oublie doit se lire comme tel dans le jeu, pas passer pour un choix.
const String kProsePlaceholderPrefix = '[À REMPLIR]';

/// Complete un brouillon incomplet.
///
/// **A appeler avant la validation**, jamais apres : la famille bilingue
/// refuse la prose vide, c'est-a-dire exactement ce qu'on est charge de
/// completer. Place ensuite, ce remplissage ne servirait a rien.
///
/// Ce qui est saisi n'est jamais ecrase — le formulaire prime toujours sur le
/// gabarit.
EntityDraft fillPlaceholders(EntityDraft draft) {
  final bilingual = <String, String>{...draft.bilingual};
  for (final base in draft.descriptor.bilingualBases) {
    for (final suffix in const ['fr', 'en']) {
      final key = '${base}_$suffix';
      if ((bilingual[key] ?? '').trim().isEmpty) {
        bilingual[key] = '$kProsePlaceholderPrefix ${draft.id}';
      }
    }
  }

  var mechanics = draft.mechanics;
  try {
    final decoded = jsonDecode(mechanics) as Map<String, dynamic>;
    draft.descriptor.decodeTemplate().forEach((key, fallback) {
      final value = decoded[key];
      if (value == null || (value is String && value.trim().isEmpty)) {
        decoded[key] = fallback;
      }
    });
    mechanics = const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    // Corps illisible : on le laisse tel quel pour que le validateur dise
    // pourquoi. Ecraser par le gabarit effacerait la saisie et la raison.
  }

  return EntityDraft(
    descriptor: draft.descriptor,
    id: draft.id,
    bilingual: bilingual,
    mechanics: mechanics,
    heroClass: draft.heroClass,
    isModification: draft.isModification,
  );
}
```

- [ ] **Step 4 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/placeholder_filler_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5 : commit**

```bash
git add -A
git commit -m "feat(editeur): completer les champs vides avant de les juger"
```

---

## Task 7 : le catalogue de ce qui existe

**Files:**
- Create: `lib/services/content_editor/entity_catalog.dart`
- Modify: `lib/services/content_editor/known_values.dart` (délègue son énumération)
- Test: `test/unit/content_editor/entity_catalog_test.dart` (créé)

**Interfaces:**
- Produces:
  - `List<String> entityFiles(ContentFileSystem fs, String rootPath, EntityDescriptor descriptor)` — les chemins relatifs, déplacé depuis `known_values.dart`.
  - `Map<String?, List<String>> entityIdsByOwner(ContentFileSystem fs, String rootPath, EntityDescriptor descriptor)` — clé `null` pour les entités sans propriétaire et les cartes neutres, identifiant de classe sinon. Valeurs triées.
- Les tâches 10 et 11 construisent les boutons du niveau 2 avec `entityIdsByOwner`.

- [ ] **Step 1 : écrire les tests qui échouent**

Créer `test/unit/content_editor/entity_catalog_test.dart`, sur le patron de bac à sable de `known_values_test.dart` :

```dart
  test('une categorie simple rend ses identifiants sous la cle null', () {
    File('$root/assets/data/relics/talisman.json').writeAsStringSync('{}');
    File('$root/assets/data/relics/amulette.json').writeAsStringSync('{}');

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.relic]!,
    );

    expect(byOwner.keys, [null]);
    expect(byOwner[null], ['amulette', 'talisman'], reason: 'triés');
  });

  test('les cartes sont groupees par proprietaire', () {
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');
    Directory('$root/assets/data/classes/paladin/cards')
        .createSync(recursive: true);
    File('$root/assets/data/classes/paladin/cards/smite.json')
        .writeAsStringSync('{}');

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.card]!,
    );

    expect(byOwner[null], ['frappe']);
    expect(byOwner['paladin'], ['smite']);
  });

  test('une classe est listee par son dossier, pas par un fichier a plat', () {
    Directory('$root/assets/data/classes/mage').createSync(recursive: true);
    File('$root/assets/data/classes/mage/class.json').writeAsStringSync('{}');

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.heroClass]!,
    );

    expect(byOwner[null], ['mage']);
  });

  // Un dossier de classe sans `class.json` n'est pas une classe. Sans ce
  // filtre, un dossier laisse par une creation avortee apparaitrait comme une
  // entite modifiable, et « Charger » echouerait sur un fichier absent.
  test('un dossier sans son fichier n est pas une entite', () {
    Directory('$root/assets/data/classes/fantome').createSync(recursive: true);

    final byOwner = entityIdsByOwner(
      const IoContentFileSystem(),
      root,
      kEntityDescriptors[EntityCategory.heroClass]!,
    );

    expect(byOwner[null] ?? const [], isEmpty);
  });
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/entity_catalog_test.dart`
Expected: FAIL — le fichier n'existe pas.

- [ ] **Step 3 : créer le catalogue en déplaçant `_entityFiles`**

Créer `lib/services/content_editor/entity_catalog.dart`. Le corps de `entityFiles` est **exactement** celui de `_entityFiles` (`known_values.dart:62-95`), déplacé sans modification, avec son commentaire sur les deux emplacements d'une carte.

```dart
import 'content_file_system.dart';
import 'entity_descriptor.dart';

/// Les fichiers d'une categorie, relatifs a la racine du projet.
///
/// Deplace depuis `known_values.dart` : deux appelants en ont desormais besoin,
/// le panneau de valeurs connues et l'arbre de l'editeur.
List<String> entityFiles(
  ContentFileSystem fs,
  String rootPath,
  EntityDescriptor descriptor,
) {
  // ... corps de l'ancien `_entityFiles`, inchange ...
}

/// Les identifiants d'une categorie, groupes par proprietaire.
///
/// La cle `null` porte les entites sans proprietaire — toutes les categories
/// sauf la carte — et les cartes neutres. Les autres cles sont des
/// identifiants de classe. C'est cette carte qui dessine le niveau 2 de
/// l'arbre, et le groupement y **est** le repertoire : dans ce projet, le
/// repertoire porte la propriete.
Map<String?, List<String>> entityIdsByOwner(
  ContentFileSystem fs,
  String rootPath,
  EntityDescriptor descriptor,
) {
  final byOwner = <String?, List<String>>{};

  for (final relative in entityFiles(fs, rootPath, descriptor)) {
    final segments = relative.split('/');
    final String? owner;
    final String id;

    if (descriptor.folderFile != null) {
      // `assets/data/classes/<id>/class.json`
      owner = null;
      id = segments[segments.length - 2];
    } else if (segments.length > 4 && segments[2] == 'classes') {
      // `assets/data/classes/<classe>/cards/<id>.json`
      owner = segments[3];
      id = segments.last.replaceAll('.json', '');
    } else {
      // `assets/data/<repertoire>/<id>.json`
      owner = null;
      id = segments.last.replaceAll('.json', '');
    }

    (byOwner[owner] ??= <String>[]).add(id);
  }

  for (final ids in byOwner.values) {
    ids.sort();
  }
  return byOwner;
}
```

Puis, dans `known_values.dart` : supprimer `_entityFiles`, ajouter `import 'entity_catalog.dart';`, et remplacer l'appel `_entityFiles(fs, rootPath, descriptor)` par `entityFiles(fs, rootPath, descriptor)`.

- [ ] **Step 4 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/entity_catalog_test.dart test/unit/content_editor/known_values_test.dart`
Expected: PASS des deux fichiers — le second prouve que le déplacement n'a rien changé.

- [ ] **Step 5 : lancer la suite et l'analyse, puis commit**

Run: `flutter test` puis `dart analyze`

```bash
git add -A
git commit -m "feat(editeur): cataloguer les entites presentes sur le disque"
```

---

## Task 8 : la recette de classe

**Files:**
- Create: `lib/services/content_editor/class_recipe.dart`
- Test: `test/unit/content_editor/class_recipe_test.dart` (créé)

**Interfaces:**
- Consumes: `EntityWriter.writeAll` (tâche 5), `fillPlaceholders` (tâche 6), `EntityDescriptor.imagePathOf` (tâche 3).
- Produces:
  - `class SignatureCardInput { const SignatureCardInput({required String id, Map<String, String> bilingual}); }`
  - `class ClassRecipe { const ClassRecipe({required String id, required Map<String, String> bilingual, required String mechanics, required List<SignatureCardInput> signatureCards}); List<EntityDraft> toDrafts(); }`
- La tâche 11 construit un `ClassRecipe` depuis le formulaire et passe `toDrafts()` à `writeAll`.

- [ ] **Step 1 : écrire les tests qui échouent**

Créer `test/unit/content_editor/class_recipe_test.dart` :

```dart
  ClassRecipe recipe({int cards = 2}) => ClassRecipe(
        id: 'gambler',
        bilingual: const {
          'name_fr': 'Le Parieur',
          'name_en': 'Gambler',
          'description_fr': 'Manipule les probabilites.',
          'description_en': 'Plays the odds.',
        },
        mechanics: '{"maxHp": 90}',
        signatureCards: [
          for (var i = 1; i <= cards; i++)
            SignatureCardInput(id: 'pari_$i', bilingual: const {}),
        ],
      );

  test('la classe vient en premier, ses cartes ensuite', () {
    final drafts = recipe().toDrafts();

    expect(drafts, hasLength(3));
    expect(drafts.first.descriptor.category, EntityCategory.heroClass);
    expect(drafts.first.path, 'assets/data/classes/gambler/class.json');
    // L'inverse leverait StateError : `_registerSignatureCard` exige que le
    // class.json existe avant qu'une de ses cartes ne soit ecrite.
    expect(drafts[1].path, 'assets/data/classes/gambler/cards/pari_1.json');
    expect(drafts[2].path, 'assets/data/classes/gambler/cards/pari_2.json');
  });

  test('la classe ne declare aucun skills : l ecrivain le remplit', () {
    final mechanics =
        jsonDecode(recipe().toDrafts().first.mechanics) as Map<String, dynamic>;
    // Un `skills` complet ecrit d'avance violerait la bijection de la tache 4
    // a chaque etape sauf la derniere.
    expect(mechanics.containsKey('skills'), isFalse);
  });

  test('la saisie prime, le gabarit complete le reste', () {
    final mechanics =
        jsonDecode(recipe().toDrafts().first.mechanics) as Map<String, dynamic>;
    expect(mechanics['maxHp'], 90);
    expect(mechanics['maxMana'], 3);
    expect(mechanics['armorMastery'], 0);
    expect(mechanics['themeColor'], '#FF00FF');
  });

  test('chaque carte appartient a la classe et porte une prose non vide', () {
    final card = recipe().toDrafts()[1];
    expect(card.heroClass, 'gambler');
    expect(card.bilingual['name_fr'], isNotEmpty);
    expect(card.bilingual['name_en'], isNotEmpty);
  });

  test('une classe sans carte de signature ne produit qu un brouillon', () {
    expect(recipe(cards: 0).toDrafts(), hasLength(1));
  });
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/class_recipe_test.dart`
Expected: FAIL — `class_recipe.dart` n'existe pas.

- [ ] **Step 3 : implémenter**

Créer `lib/services/content_editor/class_recipe.dart` :

```dart
import 'package:meta/meta.dart';

import 'entity_descriptor.dart';
import 'entity_draft.dart';
import 'placeholder_filler.dart';

/// Une carte de signature telle qu'on la saisit : un identifiant, et la prose
/// qu'on veut bien donner tout de suite.
@immutable
class SignatureCardInput {
  const SignatureCardInput({required this.id, this.bilingual = const {}});

  final String id;
  final Map<String, String> bilingual;
}

/// Une classe complete, en un geste.
///
/// Ce que la recette apporte n'est pas le lien `skills` — `EntityWriter` le
/// tient deja — mais **l'atomicite et l'ordre** : les identifiants des cartes
/// sont decides d'avance, la classe est ecrite avant elles, et l'ensemble
/// partage une transaction.
@immutable
class ClassRecipe {
  const ClassRecipe({
    required this.id,
    required this.bilingual,
    required this.mechanics,
    required this.signatureCards,
  });

  final String id;
  final Map<String, String> bilingual;

  /// Le corps saisi pour la classe. Ce qu'il ne porte pas, le gabarit le
  /// complete.
  final String mechanics;

  final List<SignatureCardInput> signatureCards;

  /// Les brouillons, **dans l'ordre d'ecriture**.
  ///
  /// La classe d'abord : `_registerSignatureCard` leve `StateError` si une
  /// carte de classe est ecrite avant le `class.json` qui doit la declarer.
  /// Et son `skills` reste absent : l'ecrivain l'alimente carte par carte, si
  /// bien que chaque etat intermediaire respecte la bijection exigee par
  /// `EntityValidator._signatureCards`.
  List<EntityDraft> toDrafts() {
    final classDescriptor = kEntityDescriptors[EntityCategory.heroClass]!;
    final cardDescriptor = kEntityDescriptors[EntityCategory.card]!;

    return [
      fillPlaceholders(
        EntityDraft(
          descriptor: classDescriptor,
          id: id,
          bilingual: bilingual,
          mechanics: mechanics,
        ),
      ),
      for (final card in signatureCards)
        fillPlaceholders(
          EntityDraft(
            descriptor: cardDescriptor,
            id: card.id,
            bilingual: card.bilingual,
            mechanics: '{}',
            heroClass: id,
          ),
        ),
    ];
  }
}
```

- [ ] **Step 4 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/class_recipe_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5 : écrire le test de bout en bout, sur un vrai bac à sable**

Ajouter au même fichier, avec le patron `Directory.systemTemp.createTempSync` et le double sans processus des tests voisins :

```dart
  test('la recette produit une classe que la validation accepte', () async {
    final fs = NoProcessFileSystem(); // double des tests voisins
    final drafts = recipe().toDrafts();

    final report = await EntityWriter(fs: fs, rootPath: root).writeAll(drafts);
    expect(report.written, hasLength(3));

    // L'invariant final : skills == le contenu de cards/.
    final classJson = jsonDecode(
      File('$root/assets/data/classes/gambler/class.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(classJson['skills'], ['pari_1', 'pari_2']);

    final onDisk = Directory('$root/assets/data/classes/gambler/cards')
        .listSync()
        .map((e) => e.uri.pathSegments.last.replaceAll('.json', ''))
        .toSet();
    expect(onDisk, {'pari_1', 'pari_2'});

    // Et la carte de classe a bien ete deposee sous son nouveau nom.
    expect(
      File('$root/assets/data/classes/gambler/gambler.png').existsSync(),
      isTrue,
    );
  });
```

Run: `flutter test test/unit/content_editor/class_recipe_test.dart`
Expected: PASS.

- [ ] **Step 6 : lancer la suite et l'analyse, puis commit**

Run: `flutter test` puis `dart analyze`

```bash
git add -A
git commit -m "feat(editeur): creer une classe entiere en un seul geste"
```

---

## Task 9 : le champ couleur et sa roue

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/ui/widgets/content_editor/color_field.dart`
- Test: `test/widget/content_editor/color_field_test.dart` (créé)

**Interfaces:**
- Produces: `ColorField({required Color value, required ValueChanged<Color> onChanged})`, et `String colorToHex(Color)` / `Color? hexToColor(String)` — la conversion que le formulaire écrit dans le JSON.

- [ ] **Step 1 : ajouter la dépendance**

Run: `flutter pub add flutter_colorpicker`
Puis `flutter pub get`.

Elle atterrit dans `dependencies:` parce qu'elle est importée depuis `lib/`. L'écran étant derrière `kDebugMode` — constante de compilation, branche éliminée — son code ne part pas en release ; le paquet reste au lock et à la page de licences, et c'est un coût accepté.

- [ ] **Step 2 : écrire les tests qui échouent**

Créer `test/widget/content_editor/color_field_test.dart` :

```dart
  test('la conversion vers le JSON est en majuscules et sur six chiffres', () {
    expect(colorToHex(const Color(0xFFB71C1C)), '#B71C1C');
    expect(colorToHex(const Color(0xFF000000)), '#000000');
    // L'alpha est ignore : le JSON ne porte que RRGGBB, et `HeroData` rend
    // toujours une couleur opaque.
    expect(colorToHex(const Color(0x40B71C1C)), '#B71C1C');
  });

  test('la conversion depuis le JSON refuse ce qui n est pas #RRGGBB', () {
    expect(hexToColor('#B71C1C'), const Color(0xFFB71C1C));
    for (final bad in const ['B71C1C', '#XYZ', '#B71C1', '']) {
      expect(hexToColor(bad), isNull, reason: 'valeur refusée : "$bad"');
    }
  });

  testWidgets('le champ montre la couleur courante et signale le changement',
      (tester) async {
    Color? seen;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ColorField(
          value: const Color(0xFFB71C1C),
          onChanged: (c) => seen = c,
        ),
      ),
    ));

    expect(find.byKey(const Key('editeur-couleur-pastille')), findsOneWidget);

    await tester.tap(find.byKey(const Key('editeur-couleur-pastille')));
    await tester.pumpAndSettle();
    // La roue est ouverte : le bouton de confirmation en est la preuve.
    expect(find.text('Valider la couleur'), findsOneWidget);

    await tester.tap(find.text('Valider la couleur'));
    await tester.pumpAndSettle();
    expect(seen, isNotNull);
  });
```

- [ ] **Step 3 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor/color_field_test.dart`
Expected: FAIL — le fichier n'existe pas.

- [ ] **Step 4 : implémenter**

Créer `lib/ui/widgets/content_editor/color_field.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// `Color` -> `#RRGGBB`. L'alpha est ignore : le JSON n'en porte pas, et une
/// couleur de classe est toujours opaque.
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// `#RRGGBB` -> `Color` opaque. `null` pour tout le reste — c'est au champ de
/// choisir son repli, pas a la conversion de deviner.
Color? hexToColor(String hex) {
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex);
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

/// Une pastille de la couleur courante, qui ouvre la roue complete.
///
/// Une palette fermee aurait suffi a l'usage, mais le spectre entier est un
/// choix explicite : voir D11 de la spec.
class ColorField extends StatelessWidget {
  const ColorField({super.key, required this.value, required this.onChanged});

  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          key: const Key('editeur-couleur-pastille'),
          onTap: () => _open(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(colorToHex(value)),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    var picked = value;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: value,
            onColorChanged: (color) => picked = color,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged(picked);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Valider la couleur'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/widget/content_editor/color_field_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 6 : vérifier que le build web tient toujours**

Run: `flutter build web --release`
Expected: exit 0. La dépendance ne doit rien casser côté web — `dart:io` reste hors de `lib/` sauf derrière le seam de `content_file_system_io.dart`.

- [ ] **Step 7 : commit**

```bash
git add -A
git commit -m "feat(editeur): choisir une couleur dans le spectre complet"
```

---

## Task 10 : l'arbre de boutons

**Files:**
- Create: `lib/ui/widgets/content_editor/tree_level.dart`
- Modify: `lib/ui/screens/content_editor_screen.dart` (niveaux 0 à 2, la liste déroulante disparaît)
- Test: `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: `entityIdsByOwner` (tâche 7), `HeroData.themeColor` (tâche 1).
- Produces: `TreeLevel({required List<TreeChoice> choices, required Object? selected, required ValueChanged<Object> onSelected, int depth = 0})` et `TreeChoice({required Object value, required String label, Color? background, String? imagePath})`.

- [ ] **Step 1 : écrire les tests qui échouent**

Remplacer, dans `test/widget/content_editor_screen_test.dart`, les gestes qui passaient par `DropdownButton<EntityCategory>` par des taps sur des boutons, et ajouter :

```dart
  testWidgets('les sept types sont des boutons, visibles d emblee',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    for (final label in const [
      'Carte', 'Relique', 'Événement', 'Passif',
      'Amélioration de forge', 'Classe', 'Ennemi',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'type manquant : $label');
    }
    expect(find.byType(DropdownButton<EntityCategory>), findsNothing);
  });

  testWidgets('le niveau 1 n apparait qu apres avoir choisi un type',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    expect(find.text('Créer'), findsNothing);
    expect(find.text('Modifier'), findsNothing);

    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();

    expect(find.text('Créer'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    // Les sept types restent la : rien ne se replie vers le haut.
    expect(find.text('Ennemi'), findsOneWidget);
  });

  testWidgets('Modifier ouvre la liste des entites presentes', (tester) async {
    File('$root/assets/data/relics/talisman_de_fer.json')
        .writeAsStringSync('{}');
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(find.text('talisman_de_fer'), findsOneWidget);
  });

  testWidgets('choisir un autre type referme la branche ouverte',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ennemi'));
    await tester.pumpAndSettle();

    // Le niveau 1 est bien la, mais reinitialise : plus aucune branche ouverte
    // en dessous.
    expect(find.text('Créer'), findsOneWidget);
    expect(find.text('talisman_de_fer'), findsNothing);
  });

  testWidgets('les cartes portent la couleur de leur proprietaire',
      (tester) async {
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');
    Directory('$root/assets/data/classes/mage/cards')
        .createSync(recursive: true);
    File('$root/assets/data/classes/mage/cards/eclair.json')
        .writeAsStringSync('{}');
    File('$root/assets/data/classes/mage/class.json').writeAsStringSync(
      '{"id":"mage","name_fr":"Mage","name_en":"Mage",'
      '"description_fr":".","description_en":".",'
      '"classCard":"assets/data/classes/mage/mage.png",'
      '"themeColor":"#9C27B0","maxHp":100,"maxMana":3,"baseDamage":5}',
    );

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    Color? backgroundOf(String label) {
      final button = tester.widget<Container>(
        find.ancestor(
          of: find.text(label),
          matching: find.byKey(const Key('editeur-bouton-fond')),
        ),
      );
      return (button.decoration as BoxDecoration?)?.color;
    }

    // Sans cette assertion, la couleur pourrait etre uniforme et le test
    // passerait quand meme : c'est la *difference* qui porte l'information.
    expect(backgroundOf('eclair'), isNot(backgroundOf('frappe')));
    expect(backgroundOf('eclair'), const Color(0xFF9C27B0));
  });
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor_screen_test.dart`
Expected: FAIL — l'écran porte encore une liste déroulante.

- [ ] **Step 3 : créer le niveau d'arbre**

Créer `lib/ui/widgets/content_editor/tree_level.dart` :

```dart
import 'package:flutter/material.dart';

/// Un choix d'un niveau de l'arbre.
@immutable
class TreeChoice {
  const TreeChoice({
    required this.value,
    required this.label,
    this.background,
    this.imagePath,
  });

  final Object value;
  final String label;

  /// Le fond du bouton. Porte le proprietaire d'une carte : gris pour les
  /// neutres, `themeColor` de la classe sinon.
  final Color? background;

  /// L'icone ou la carte de la classe proprietaire. La distinction ne repose
  /// ainsi pas sur la seule couleur.
  final String? imagePath;
}

/// Une rangee de boutons, dont un peut etre selectionne.
///
/// [depth] est la tabulation : chaque descente decale d'un cran, et rien ne se
/// replie vers le haut.
class TreeLevel extends StatelessWidget {
  const TreeLevel({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.depth = 0,
  });

  static const double indent = 24;

  final List<TreeChoice> choices;
  final Object? selected;
  final ValueChanged<Object> onSelected;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * indent, top: 8, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in choices)
            _button(context, choice, choice.value == selected),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, TreeChoice choice, bool isSelected) {
    final background = choice.background ?? Colors.grey.shade300;
    return InkWell(
      onTap: () => onSelected(choice.value),
      child: Container(
        key: const Key('editeur-bouton-fond'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (choice.imagePath != null) ...[
              ClipOval(
                child: Image.asset(
                  choice.imagePath!,
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                  // Un placeholder absent ne doit pas faire tomber l'ecran.
                  errorBuilder: (_, __, ___) => const SizedBox(width: 16),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              choice.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4 : câbler les trois niveaux dans l'écran**

Dans `lib/ui/screens/content_editor_screen.dart` : supprimer les deux `DropdownButton`, et tenir trois champs d'état — `EntityCategory? _category`, `_EditorMode? _mode` (`create` / `modify`), `String? _target` plus `String? _targetOwner`.

Le corps de l'écran devient :

```dart
        TreeLevel(
          choices: [
            for (final descriptor in kEntityDescriptors.values)
              TreeChoice(value: descriptor.category, label: descriptor.label),
          ],
          selected: _category,
          onSelected: (value) => setState(() {
            // Changer de type referme tout ce qui pendait dessous : une cible
            // d'une autre categorie n'a plus de sens.
            _category = value as EntityCategory;
            _mode = null;
            _target = null;
            _targetOwner = null;
          }),
        ),
        if (_category != null)
          TreeLevel(
            depth: 1,
            choices: const [
              TreeChoice(value: _EditorMode.create, label: 'Créer'),
              TreeChoice(value: _EditorMode.modify, label: 'Modifier'),
            ],
            selected: _mode,
            onSelected: (value) => setState(() {
              _mode = value as _EditorMode;
              _target = null;
              _targetOwner = null;
            }),
          ),
        if (_mode == _EditorMode.modify) _targetLevel(root),
```

avec

```dart
  /// Le niveau 2 : ce qui existe, groupe par proprietaire et colore par lui.
  Widget _targetLevel(String root) {
    final byOwner = entityIdsByOwner(
      ref.read(contentFileSystemProvider)!,
      root,
      _descriptor,
    );

    final choices = <TreeChoice>[];
    // Les neutres d'abord, puis chaque classe en bloc : le groupement se voit
    // sans qu'il faille un niveau de plus.
    for (final owner in [null, ...byOwner.keys.whereType<String>()..sort()]) {
      for (final id in byOwner[owner] ?? const <String>[]) {
        choices.add(TreeChoice(
          value: '${owner ?? ''}/$id',
          label: id,
          background: owner == null ? null : _ownerColor(root, owner),
          imagePath: owner == null ? null : _ownerImage(root, owner),
        ));
      }
    }

    return TreeLevel(
      depth: 2,
      choices: choices,
      selected: _target == null ? null : '${_targetOwner ?? ''}/$_target',
      onSelected: (value) => setState(() {
        final parts = (value as String).split('/');
        _targetOwner = parts.first.isEmpty ? null : parts.first;
        _target = parts.last;
      }),
    );
  }
```

`_ownerColor` et `_ownerImage` lisent `assets/data/classes/<owner>/class.json` par `ContentFileSystem`, y prennent `themeColor` et `iconPath ?? classCard`, et rendent `null` si le fichier manque ou ne décode pas — un dossier incomplet ne doit pas faire tomber l'écran.

- [ ] **Step 5 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/widget/content_editor_screen_test.dart`
Expected: PASS.

- [ ] **Step 6 : lancer la suite et l'analyse, puis commit**

Run: `flutter test` puis `dart analyze`

```bash
git add -A
git commit -m "feat(editeur): remplacer la liste deroulante par un arbre de boutons"
```

---

## Task 11 : les formulaires dans l'arbre

**Files:**
- Create: `lib/ui/widgets/content_editor/entity_form.dart`
- Modify: `lib/ui/screens/content_editor_screen.dart` (niveau 3, écriture, retour à la branche 0)
- Test: `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: `fillPlaceholders` (6), `ClassRecipe` (8), `EntityWriter.writeAll` (5), `ColorField` (9), `entityIdsByOwner` (7).

- [ ] **Step 1 : écrire les tests qui échouent**

Ajouter à `test/widget/content_editor_screen_test.dart` :

```dart
  testWidgets('creer une relique avec le seul identifiant ecrit un fichier valide',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    // C'est ce test qui echouerait si la substitution passait *apres* la
    // validation : la famille bilingue refuserait la prose vide.
    expect(find.textContaining('Écrit :'), findsOneWidget);
    final written = jsonDecode(
      File('$root/assets/data/relics/talisman.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written['name_fr'], contains('À REMPLIR'));
    expect(written['name_en'], contains('À REMPLIR'));
  });

  testWidgets('apres une creation, l arbre revient a la branche 0',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    // Plus aucune branche ouverte, mais le compte rendu reste lisible : la
    // nouvelle entite n'existe pas encore pour l'application qui tourne, et
    // ouvrir son formulaire donnerait l'illusion inverse.
    expect(find.text('Créer'), findsNothing);
    expect(find.textContaining('Écrit :'), findsOneWidget);
    expect(find.textContaining('Relancer'), findsOneWidget);
  });

  testWidgets('creer une classe ecrit ses cartes et referme skills',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
    await tester.enterText(
        find.byKey(const Key('editeur-nombre-cartes')), '2');
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('editeur-carte-0-id')), 'bluff');
    await tester.enterText(
        find.byKey(const Key('editeur-carte-1-id')), 'all_in');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final classJson = jsonDecode(
      File('$root/assets/data/classes/gambler/class.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(classJson['skills'], ['all_in', 'bluff']);
    expect(
      File('$root/assets/data/classes/gambler/cards/bluff.json').existsSync(),
      isTrue,
    );
  });

  testWidgets('le proprietaire d une carte est un champ, pas un niveau',
      (tester) async {
    Directory('$root/assets/data/classes/mage/cards').createSync(recursive: true);
    File('$root/assets/data/classes/mage/class.json').writeAsStringSync(
      '{"id":"mage","name_fr":"Mage","name_en":"Mage",'
      '"description_fr":".","description_en":".",'
      '"classCard":"assets/data/classes/mage/mage.png",'
      '"maxHp":100,"maxMana":3,"baseDamage":5}',
    );

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editeur-proprietaire-mage')));
    await tester.enterText(find.byKey(const Key('editeur-id')), 'eclair');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    expect(
      File('$root/assets/data/classes/mage/cards/eclair.json').existsSync(),
      isTrue,
      reason: 'le propriétaire choisi décide du répertoire',
    );
  });

  testWidgets('le passif se choisit dans le catalogue, pas dans l usage',
      (tester) async {
    // Un passif present sur le disque qu'aucune classe n'emploie : le cas que
    // `knownValues`, qui liste les valeurs *employees*, manquerait.
    Directory('$root/assets/data/passives').createSync(recursive: true);
    File('$root/assets/data/passives/chance_du_joueur.json')
        .writeAsStringSync('{}');

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.text('chance_du_joueur'), findsWidgets);
  });
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3 : construire le formulaire**

Créer `lib/ui/widgets/content_editor/entity_form.dart`. Il porte, pour la catégorie courante :

- le triangle d'identité — `Key('editeur-id')`, et le chemin calculé affiché dessous, comportement déjà livré et conservé ;
- pour une **carte** en création : la rangée de pastilles de propriétaire, `Key('editeur-proprietaire-<classe>')` et `Key('editeur-proprietaire-neutre')`, colorées par le `themeColor` de chaque classe ;
- **un champ par clé du gabarit**, plus les champs bilingues du descripteur ;
- pour `themeColor` : un `ColorField` de la tâche 9, dont la valeur écrite est `colorToHex` ;
- pour chaque `referenceKeys` du descripteur — donc `passiveTrait` — une liste des identifiants tirés de `entityIdsByOwner(fs, root, kEntityDescriptors[EntityCategory.passive]!)`, **et non de `knownValues`** : ce panneau ne liste que les valeurs déjà employées, et un passif jamais utilisé y serait invisible ;
- pour une **classe** en création : `Key('editeur-nombre-cartes')`, et pour chaque carte `Key('editeur-carte-<i>-id')`, `Key('editeur-carte-<i>-nom-fr')`, `Key('editeur-carte-<i>-nom-en')`.

Le panneau de valeurs connues (`knownValues`) reste tel quel, à droite : il sert le vocabulaire libre — `effectType`, `trigger` — et c'est son bon usage.

- [ ] **Step 4 : brancher l'écriture**

Dans `content_editor_screen.dart`, la méthode d'écriture devient :

```dart
  Future<void> _write(String root) async {
    final writer = EntityWriter(
      fs: ref.read(contentFileSystemProvider)!,
      rootPath: root,
    );

    // Les brouillons sont completes **avant** d'etre juges : la famille
    // bilingue refuse la prose vide, c'est-a-dire ce que le remplissage est
    // charge de fournir. Inverser l'ordre rendrait la creation impossible.
    final drafts = _isClassRecipe ? _recipe().toDrafts() : [fillPlaceholders(_draft())];

    final faults = [
      for (final draft in drafts) ..._validator(root).validate(draft),
    ];
    setState(() {
      _faults = faults;
      _report = null;
      _failure = null;
    });
    if (faults.isNotEmpty) return;

    try {
      final report = await writer.writeAll(drafts);
      setState(() {
        _report = report;
        // Retour a la branche 0 : la nouvelle entite n'est pas dans le
        // registre avant recompilation, et ouvrir son formulaire ferait croire
        // le contraire. Le compte rendu, lui, reste affiche.
        if (drafts.any((d) => !d.isModification)) {
          _category = null;
          _mode = null;
          _target = null;
          _targetOwner = null;
        }
      });
    } catch (e) {
      setState(() => _failure = e.toString());
    }
  }
```

La porte E6 du lot 2 — refuser d'écrire une modification dont le fichier n'a pas été relu — est conservée telle quelle, en tête de la méthode.

- [ ] **Step 5 : lancer les tests, vérifier qu'ils passent**

Run: `flutter test test/widget/content_editor_screen_test.dart`
Expected: PASS.

- [ ] **Step 6 : prouver que l'ordre compte**

Déplacer temporairement `fillPlaceholders` **après** la validation, relancer le fichier : le test « creer une relique avec le seul identifiant » doit virer au rouge sur une faute bilingue. Rétablir l'ordre. C'est la seule preuve que D7 est tenue.

- [ ] **Step 7 : la suite complète, l'analyse et le build web**

Run: `flutter test`, puis `dart analyze`, puis `flutter build web --release`
Expected: tout vert, zéro problème, exit 0.

- [ ] **Step 8 : vérification manuelle**

Lancer `flutter run`, ouvrir `ÉDITEUR DE CONTENU` depuis l'accueil, créer la classe `gambler` avec deux cartes, puis **redémarrer à chaud** : la classe ne doit pas apparaître, et le message doit avoir conseillé une relance de `flutter run`. Relancer : elle apparaît à la sélection de classe, en magenta, avec sa carte de remplacement.

- [ ] **Step 9 : commit**

```bash
git add -A
git commit -m "feat(editeur): remplir un formulaire complet et creer en un geste"
```

---

## Auto-revue du plan

**Couverture de la spec** — §3.1 → T1 et T3 ; §3.2 → T1 ; §3.3 → T2 ; §3.4 → T1, T10 ; §3.5 → T3 (magenta au gabarit) ; §4.1-4.2 → T10 ; §4.3 → T10 (couleur) et T11 (pastilles de propriétaire) ; §4.4 → T11 ; §5.1 → T6 et T11 ; §5.2-5.3 → T11 ; §5.4 → T9 ; §5.5 → T7 et T11 ; §6.1 → T8 ; §6.2 → T11 (l'ennemi n'exige aucun code neuf : un fichier, une image, `sync_assets` — c'est le chemin existant, plus le remplissage de T6) ; §6.3 → T11 ; §7.1 → T4 ; §7.2 → T3 ; §8 → réparti ; §10 → T11 step 8.

**Écart assumé** : la spec §7.2 décrivait un test « gabarit ⊇ modèle » générique, lisant le source de chaque modèle au motif que Dart n'offre pas de réflexion en test. La tâche 3 le remplace par une assertion explicite sur le gabarit de la **classe**, la seule catégorie où un écart réel a été mesuré (`armorMastery`). Un test qui lit du source par expression régulière introduit un mécanisme fragile pour un défaut hypothétique dans les six autres catégories ; l'assertion nommée échoue aussi sûrement et se lit sans explication. Si un écart apparaît ailleurs, on ajoutera l'assertion correspondante.

**Cohérence des types** — `classCard` est un `String` requis partout ; `iconPath` et `themeColor` sont nullables de bout en bout ; `writeAll` prend une `List<EntityDraft>` et rend un `WriteReport` ; `entityIdsByOwner` rend `Map<String?, List<String>>` et ses trois appelants (T10, T11) l'emploient sous cette forme ; `fillPlaceholders` prend et rend un `EntityDraft`.
