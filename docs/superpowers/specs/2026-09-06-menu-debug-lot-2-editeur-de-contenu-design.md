# Menu de debug — lot 2 : éditeur de contenu — Conception

Date : 2026-09-06
Statut : **Conception** — non implémenté ; plan d'implémentation écrit
Révision : v2 — **v2 : les opérations disque passent par une interface, `dart:io` ne pouvant être
importé directement sans casser le build web du jeu publié ; et une septième famille de validation
s'ajoute, les références** (§3.3, §3.4). Les deux écarts sont apparus à l'écriture du plan, en
vérifiant le dépôt plutôt qu'en supposant
Périmètre : **lot 2 sur 2.** Le lot 1 — le manipulateur de run — est livré et fait l'objet de sa
propre spec ; les deux lots ne partagent aucun code.
Sources amont :
- Brainstorming du 2026-09-06 (chemin architectural, approche **B** retenue)
- `docs/superpowers/specs/2026-09-05-menu-debug-lot-1-manipulateur-de-run-design.md`
- `docs/superpowers/specs/2026-09-04-reorganisation-donnees-un-fichier-par-entite-design.md` — la
  réorganisation « un fichier par entité » sans laquelle ce lot n'aurait pas de cible
- `.obsidian_vault/_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md`

> **Ce lot écrit sur le disque.**
>
> Le lot 1 ne touchait qu'à l'état vivant de l'application, perdu au prochain lancement : un défaut
> y coûtait une session. Celui-ci produit des **fichiers versionnés qui deviennent le jeu**. Toute sa
> conception découle de cette différence : ce qu'il écrit doit franchir les mêmes gardes que ce que
> l'on écrit à la main, et il vaut mieux qu'il refuse d'écrire que d'écrire mal.

---

## 1. Le problème

Ajouter une entité au jeu demande aujourd'hui six gestes exacts, dans l'ordre, dont aucun n'est
guidé : trouver le bon répertoire, nommer le fichier comme l'identifiant, ne pas y écrire les champs
que le répertoire impose, remplir les deux variantes linguistiques de chaque texte, créer le dossier
et son image pour une classe ou un ennemi, relancer `tool/sync_assets.dart`. Une faute sur l'un des
six ne se voit pas à l'écriture : elle se voit au chargement suivant, ou — pire — ne se voit pas du
tout.

Trois pièges méritent d'être nommés, parce qu'ils sont invisibles et que ce sont eux qui justifient
un outil plutôt qu'une page de documentation :

1. **`CardData.fromJson` est une couche de compatibilité, pas un validateur.** Une rareté mal
   orthographiée retombe en silence sur `common`, une cible inconnue sur `singleEnemy`, un
   `name_fr` absent sur la chaîne vide. Le jeu démarre, la carte existe, et elle est fausse.
2. **Créer une carte de classe sans toucher à `class.json` casse l'intégrité référentielle.**
   `referential_integrity_test.dart:103` exige que le contenu du dossier `cards/` soit **exactement**
   égal au tableau `skills` de la classe. Une carte ajoutée seule est une carte orpheline, et le test
   rougit — à tous les coups, jamais au moment de l'écriture.
3. **Un dossier `cards/` absent fait *lever* ce même test**, `listSync()` n'ayant rien à lister.
   Créer une classe sans son sous-dossier vide casse la suite entière.

Le dépôt anticipait déjà cet outil. `EntitySource.redundantFields` porte, depuis la réorganisation,
le commentaire *« Le parametre reste un seam documente pour le devtool d'edition a venir »*, et le
drapeau `cache: false` de `GameDataLoader._read` liste comme **première** de ses trois raisons
*« le devtool d'edition relit le disque a chaud au lieu de servir un Future deja regle »*. Les
joints existent ; il reste à les utiliser.

---

## 2. Décisions retenues

| # | Décision | Motif |
|:--|:---|:---|
| **E1** | **Créer et modifier ; ni supprimer ni renommer.** | Supprimer une carte de signature ou un passif référencé casse l'intégrité ; renommer orphelinerait l'ancien fichier. Les deux se font à la main, rarement, en connaissance de cause. |
| **E2** | **Identité et prose bilingue en formulaire ; mécanique en JSON pré-rempli.** | Le formulaire couvre ce qui est universel et se rate silencieusement ; le JSON couvre ce qui varie d'une catégorie à l'autre et dupliquerait le schéma. |
| **E3** | **Les valeurs énumérées sont vérifiées contre les énumérations Dart réelles.** | `CardType.values`, `CardRarity.values`, `RelicTrigger.values`… Une liste recopiée à la main serait une seconde vérité, et se périmerait au premier ajout. |
| **E4** | **La racine du projet est déduite de `Platform.resolvedExecutable`, pas de `Directory.current`.** | Le répertoire courant dépend de la façon dont l'application a été lancée ; l'emplacement du binaire, non. |
| **E5** | **La couche d'écriture reçoit la racine en paramètre.** | Le même joint que `bundle` pour `GameDataLoader` et `workingDirectory` pour `sync_assets` : c'est ce qui la rend testable sur une arborescence jetable. |
| **E6** | **Rien n'est écrit avant que toute la validation passe.** | Un fichier à demi écrit fait échouer le chargement de *toute* sa catégorie, pas seulement de lui-même. |
| **E7** | **Une carte de classe écrit deux fichiers, ou aucun.** | Le fichier de carte et le `skills` de `class.json` sont une seule vérité en deux endroits (§1, piège 2). |
| **E8** | **L'unicité se vérifie sur le disque *et* dans le registre en mémoire.** | Le disque ne voit qu'un chemin — il rate une carte neutre et une carte de classe qui partagent un identifiant, doublon que le chargeur rejette pourtant. Le registre voit tous les chemins d'une catégorie, mais pas ce que la session vient d'écrire. Chacun rattrape l'angle mort de l'autre, pour deux lectures. |
| **E9** | **L'image est un placeholder copié, remplacé à la main, jamais écrasé.** | Choix explicite de l'utilisateur : aucune dépendance nouvelle pour un sélecteur de fichiers, et une image existante n'est jamais en danger. |
| **E10** | **Le menu n'existe qu'en `kDebugMode`, comme le lot 1.** | Constante de compilation : le sous-arbre est replié puis élagué du build release. |

---

## 3. Architecture

Cinq unités, sans état partagé, chacune testable seule.

```
ContentFileSystem  →  les huit opérations disque, et le seul endroit où vit dart:io
ProjectRoot        →  où écrire, ou pourquoi on ne peut pas
EntityDescriptor   →  ce qu'est une catégorie (table déclarative, 7 entrées)
EntityValidator    →  ce qui interdit d'écrire (7 familles, dans l'ordre)
EntityWriter       →  l'écriture et ses effets de bord (reçoit la racine)
```

### 3.1 `ProjectRoot` — trouver l'arborescence source

L'application tourne depuis `build/<plateforme>/…/runner/Debug/` ; les données qu'elle doit modifier
sont dans l'arborescence source. La sonde remonte depuis `Platform.resolvedExecutable` jusqu'au
premier répertoire contenant **à la fois** `pubspec.yaml` et `assets/data/`, avec un plafond de
remontée pour ne pas balayer tout le disque.

```dart
/// Rend la racine du projet, ou `null` si l'application ne tourne pas depuis
/// une arborescence source (build distribue, plateforme sans systeme de
/// fichiers). L'editeur refuse alors de s'ouvrir : il vaut mieux ne rien
/// pouvoir faire que d'ecrire au hasard.
static Directory? find();
```

Deux conditions plutôt qu'une : `pubspec.yaml` seul se trouve aussi dans le cache des paquets.

**En cas d'échec, l'éditeur ne s'ouvre pas** et affiche pourquoi. C'est le seul comportement sûr :
un outil d'écriture qui ne sait pas où il écrit ne doit pas écrire.

### 3.2 `EntityDescriptor` — une catégorie décrite en dix lignes

Une catégorie, c'est un chemin, une liste de clés et un `fromJson`. Rien de plus n'a besoin d'être
du code.

```dart
class EntityDescriptor {
  final String label;                       // 'Relique'
  final String Function(String id, String? heroClass) pathOf;
  final Set<String> requiredKeys;           // absentes = refus
  final Set<String> forbiddenKeys;          // imposees par le repertoire
  final Map<String, List<String>> enumKeys; // 'rarity' -> RelicRarity.values.map(name)
  final List<String> bilingualBases;        // 'name', 'description'
  final void Function(Map<String, dynamic>) construct; // le fromJson reel
  final String template;                    // JSON pre-rempli, mecanique seule
}
```

Les sept descripteurs vivent dans un seul fichier et sont **la** déclaration des catégories
éditables — comme `loadGameDataRegistry` est la déclaration des catégories chargeables. Les deux
listes doivent rester en regard ; un test le vérifie (§9).

`enumKeys` est peuplé depuis les énumérations réelles (`CardRarity.values.map((e) => e.name)`), jamais
depuis des littéraux : **E3**.

### 3.3 `EntityValidator` — sept familles, dans l'ordre

Du moins cher au plus structurel. **On s'arrête à la première famille en échec** : un rapport qui
mélange une faute de syntaxe JSON et douze clés manquantes est illisible, et les douze sont souvent
la conséquence de la première.

| # | Famille | Ce qu'elle attrape |
|:-:|:---|:---|
| 1 | **Identité** | `^[a-z0-9_]+$` ; le fichier calculé n'existe pas déjà ; aucune entité de la même catégorie ne porte cet identifiant dans le registre (**E8**) |
| 2 | **Syntaxe** | le corps décode, et décode vers un **objet** JSON |
| 3 | **Clés** | les obligatoires sont présentes ; les interdites sont absentes |
| 4 | **Énumérations** | chaque valeur appartient à son énumération Dart — *c'est le contrôle que `fromJson` avale* (§8) |
| 5 | **Bilingue** | les deux variantes de chaque base sont présentes **et non vides** |
| 6 | **Références** | `passiveTrait` désigne un passif existant — `referential_integrity_test:35` l'exige, et une référence pendante ferait rougir la suite longtemps après l'écriture |
| 7 | **Construction** | `fromJson` s'exécute sans lever — le filet structurel, en dernier |

La famille 7 ne remplace pas les six autres : elle attrape ce qu'on n'a pas prévu. Les six
premières existent précisément parce que la septième est trop permissive (§8).

### 3.4 `EntityWriter` — la racine en paramètre

```dart
class EntityWriter {
  const EntityWriter({required this.fs, required this.rootPath});
  final ContentFileSystem fs;
  final String rootPath;

  /// Ecrit l'entite et ses effets de bord. Ne valide rien : l'appelant valide,
  /// l'ecrivain ecrit.
  Future<WriteReport> write(EntityDraft draft);
}
```

La racine est un paramètre et non une constante : c'est le seul point qui rend l'écrivain testable
sur une arborescence jetable (**E5**), exactement comme `GameDataLoader(bundle)` et comme
`sync_assets` piloté par son `workingDirectory`.

> [!IMPORTANT]
> **`dart:io` ne peut pas être importé directement, et la raison est le produit lui-même.**
>
> Le jeu est publié en **build web** — `web/` existe, et le site distribue des URL jouables — et
> `lib/` n'importe `dart:io` nulle part aujourd'hui. Un import direct casserait cette cible.
>
> Les opérations disque passent donc par une interface `ContentFileSystem`, dont l'implémentation
> est choisie par **import conditionnel** : `dart:io` là où il existe, `null` sur le web — où
> l'éditeur refuse de s'ouvrir, du même refus que lorsqu'il ne trouve pas la racine (§3.1). Un seul
> fichier du dépôt importe `dart:io`, et une commande le vérifie.
>
> Conséquence heureuse : aucune des unités qui écrivent ne mentionne un type de `dart:io`, et la
> racine circule comme une simple `String`.

Le JSON est encodé avec `JsonEncoder.withIndent('  ')`, deux espaces, comme les fichiers existants.
L'ordre des clés est celui de la composition — `Map` et `jsonDecode` préservent tous deux l'ordre
d'insertion — de sorte qu'une modification produise un diff minimal.

### 3.5 L'interface

Un écran plein, atteint depuis l'écran d'accueil par un bouton visible sous `kDebugMode` seulement,
à côté du bouton « RUN DEBUG » du lot 1. Hors run : aucune interaction avec l'état de jeu, donc
aucun risque pour une sauvegarde.

```
┌─ Éditeur de contenu ────────────────────────────────┐
│ Catégorie  [Carte ▾]     ○ Créer   ○ Modifier      │
│ Identifiant [_______]  Classe [neutre ▾]           │
│ → assets/data/classes/paladin/cards/smite.json     │
├─────────────────────────────────────────────────────┤
│ Nom FR [____]  Nom EN [____]                       │
│ Description FR [____]  Description EN [____]       │
├─────────────────────────────────────────────────────┤
│ Mécanique (JSON)          │ Valeurs déjà utilisées │
│ { "cost": 1,              │ type: attack, skill,   │
│   "type": "attack",       │       power, status    │
│   ... }                   │ rarity: common, …      │
├─────────────────────────────────────────────────────┤
│ [ Valider ]   [ Écrire ]                            │
└─────────────────────────────────────────────────────┘
```

Le chemin calculé s'affiche en permanence sous le triangle d'identité : c'est le retour le plus
utile de tout l'écran, puisqu'il montre la conséquence du choix de classe avant l'écriture.

Le panneau **« valeurs déjà utilisées »** est **dérivé du registre chargé**, pas d'une liste écrite :
pour chaque clé du gabarit, les valeurs distinctes trouvées dans les entités existantes. Il est donc
incapable de se périmer, et il rend `effectType` — une chaîne libre côté modèle, mais un vocabulaire
fermé côté moteur — découvrable sans documentation.

---

## 4. Le triangle d'identité, et ce qu'il gèle

La ligne de partage n'est pas « certains champs » : elle passe entre **ce qui est dans le fichier**
et **ce qui décide où est le fichier**.

| Catégorie | Gelé en modification | Parce que c'est… |
|:---|:---|:---|
| Carte neutre | `id` | le nom du fichier |
| Carte de classe | `id` **et** la classe | le nom du fichier **et** le dossier parent |
| Relique, événement, passif, amélioration de forge | `id` | le nom du fichier |
| Classe, ennemi | `id` | le nom du **dossier** |

**Tout le reste est librement modifiable** : les champs bilingues, le coût, la rareté, le type, la
cible, les effets, les intentions, les choix d'événement — tout ce qui vit à l'intérieur du fichier.
Une carte peut changer de coût, de rareté et de texte autant qu'on veut ; elle ne peut changer ni de
nom ni de classe.

En mode « Modifier », le triangle est donc verrouillé et le corps JSON ne l'est jamais. La plupart de
ces champs gelés ne figurent d'ailleurs même pas dans le fichier : le répertoire les injecte au
chargement (**ADR-086**), et les déclarer est une erreur.

---

## 5. Les deux écritures couplées

`referential_integrity_test.dart:103` exige que le contenu de `classes/<id>/cards/` soit **exactement**
le tableau `skills` de `class.json`. Il en découle deux comportements que rien d'autre ne garantit :

**Créer une carte de classe écrit deux fichiers.** Le fichier de la carte, et `class.json` dont le
tableau `skills` gagne l'identifiant. Les deux, ou aucun (**E7**) : le brouillon est validé, les deux
contenus sont préparés en mémoire, puis écrits. Si la seconde écriture échoue, la première est
défaite.

**Créer une classe crée son dossier `cards/`, même vide.** Le test appelle `listSync()` sans garde :
un dossier absent le fait *lever*, et c'est toute la suite qui tombe. Une classe naît donc avec
`skills: []` et un dossier vide, cohérente ; ses cartes de signature s'ajoutent ensuite, une par une,
chacune mettant `skills` à jour.

Une carte neutre, elle, n'écrit qu'un fichier : aucune classe ne la revendique.

---

## 6. Les effets de bord de l'écriture

### 6.1 Le dossier et l'image

Une classe et un ennemi sont des **dossiers**. L'écrivain crée le dossier, y écrit le JSON, et y
copie une image de remplacement sous le nom attendu — `icon.png` pour une classe, `sprite.png` pour
un ennemi — **si et seulement si aucune image n'y est déjà** (**E9**).

La source est `assets/images/placeholder_entity.png`, à créer une fois et à versionner : un carré
magenta franchement laid, pour qu'oublier de le remplacer se voie immédiatement. Il est copié par
`dart:io` depuis l'arborescence source, jamais lu par le bundle.

L'écrivain calcule aussi `iconPath` / `spritePath`, qui sont des **chemins d'asset complets écrits
dans le fichier** (`"assets/data/classes/paladin/icon.png"`) et que `fromJson` exige. C'est
typiquement ce qu'une saisie manuelle rate, et ce qu'un chemin dérivé de l'identifiant ne peut pas
rater.

### 6.2 `sync_assets`

Un nouveau dossier de classe ou d'ennemi a besoin de sa propre ligne dans `pubspec.yaml` : les
déclarations d'assets de Flutter ne sont récursives à aucun niveau, et un dossier non déclaré se
charge en développement puis disparaît silencieusement d'un build.

```dart
await Process.run(
  'dart', ['run', 'tool/sync_assets.dart'],
  workingDirectory: root.path,
  runInShell: true, // INDISPENSABLE sous Windows — voir sync_assets_test.dart
);
```

`runInShell: true` n'est pas décoratif : l'hôte de `flutter test` n'est pas un shell, et
`sync_assets_test.dart` documente déjà le `ProcessException` que son absence provoque. Le script
n'utilise que des chemins relatifs (`Directory('assets')`, `File('pubspec.yaml')`) : c'est le
`workingDirectory` qui le pilote entièrement.

Le rapport d'écriture porte le code de sortie et la sortie du script. Un échec n'annule pas
l'écriture — le fichier est bon — mais il est signalé, puisque `pubspec.yaml` est alors en retard.

### 6.3 La visibilité du changement — **le point à vérifier**

L'outil écrit dans l'arborescence **source** ; `rootBundle` lit le bundle **construit**. Entre les
deux, il y a la synchronisation d'assets de `flutter run`, et son comportement exact sur un fichier
*nouveau* et sur un `pubspec.yaml` *modifié* n'est pas établi ici.

La spec retient donc la règle conservatrice, et l'outil affiche le geste correspondant :

| Geste | Ce que l'outil annonce |
|:---|:---|
| Modification d'une entité existante | Redémarrage à chaud, puis rechargement des données |
| Création d'une entité | Redémarrage à chaud, puis rechargement — **et relance de `flutter run` si elle n'apparaît pas** |
| Création d'une classe ou d'un ennemi | **Relancer `flutter run`** — `pubspec.yaml` a changé |

Un bouton « Recharger les données » invalide `gameDataLoaderProvider`, ce que le `cache: false` de
`GameDataLoader._read` rend utile : le chargeur relit au lieu de rendre un `Future` déjà réglé.

> **Vérification manuelle exigée à l'implémentation.** Établir empiriquement, pour chacun des trois
> gestes, ce qui suffit réellement — et resserrer le message si le redémarrage à chaud suffit. On ne
> promet pas un comportement qu'on n'a pas observé ; c'est la leçon du lot 1, où une recherche dans
> l'instantané AOT ne prouvait rien tant qu'elle n'avait pas de témoin positif.

---

## 7. Les sept catégories

Sept descripteurs, huit lignes : la carte en occupe deux parce que son chemin dépend de la classe,
mais c'est un seul descripteur, dont `pathOf(id, heroClass)` branche sur la présence d'une classe.

| Catégorie | Chemin | Champs bilingues | Clés dont l'absence fait lever `fromJson` |
|:---|:---|:---|:---|
| Carte neutre | `cards/<id>.json` | `name`, `description` | `cost`, `type` |
| Carte de classe | `classes/<cl>/cards/<id>.json` | `name`, `description` | `cost`, `type` |
| Relique | `relics/<id>.json` | `name`, `description` | `trigger`, `effectType`, `value`, `rarity` |
| Passif | `passives/<id>.json` | `name`, `description` | `trigger`, `effectType`, `value` |
| Amélioration de forge | `forge_upgrades/<id>.json` | `name`, `description` | *(aucune — tout a un défaut)* |
| Événement | `events/<id>.json` | **`title`**, `description` | `choices`, et `actions` par choix |
| Classe | `classes/<id>/class.json` | `name`, `description` | `iconPath`, `maxHp`, `maxMana`, `baseDamage` |
| Ennemi | `enemies/<id>/enemy.json` | **`name` seul** | `maxHp`, `baseDamage`, `spritePath` |

Deux irrégularités que la table rend visibles, et qui interdisent de traiter les champs bilingues
comme un bloc universel : **un événement porte `title_*` et non `name_*`**, et **un ennemi n'a aucune
description**. Un événement en porte en outre à deux niveaux imbriqués — `text_*` et `result_text_*`
par choix — qui restent dans la partie JSON.

Une amélioration de forge ne fait lever `fromJson` sur rien d'autre que `id` : c'est la catégorie où
les familles 3 à 5 de la validation font tout le travail.

---

## 8. Ce que `fromJson` laisse passer

Le tableau qui justifie les familles 4 et 5. Aucune de ces fautes ne fait échouer le chargement ;
toutes produisent une entité fausse et silencieuse.

| Faute | Ce que `fromJson` en fait |
|:---|:---|
| `"rarity": "commun"` sur une carte | retombe sur `CardRarity.common` |
| `"target": "tous"` | retombe sur `CardTarget.singleEnemy` |
| `"category"` absent | retombe sur `CardCategory.global` |
| `name_fr` absent | cherche `name`, puis rend `''` — carte sans nom en jeu |
| `description_en` absent | idem, description vide |

Les familles 4 et 5 ne dupliquent donc pas `fromJson` : elles couvrent exactement ce qu'il ne couvre
pas. La famille 7 reste utile pour tout le reste — un `cost` textuel, un `choices` absent, un effet
malformé — qu'elle attrape en levant.

Les énumérations sans `orElse` (`CardType`, `RelicTrigger`, `RelicRarity`) lèvent bien un
`StateError`, mais avec un message qui ne nomme ni le champ ni les valeurs acceptables. La famille 4
les rattrape avant, avec un message qui les nomme.

---

## 9. Tests

Le joint est l'arborescence jetable, sur le modèle exact de `sync_assets_test.dart` :
`Directory.systemTemp.createTempSync('entity_writer_')`, peuplée de quelques entités, et
`tearDown(() => sandbox.deleteSync(recursive: true))`.

| Test | Ce qu'il prouve |
|:---|:---|
| **Aller-retour** | Une entité écrite dans l'arborescence jetable, puis chargée par `GameDataLoader` sur cette même arborescence, apparaît dans le registre. *Le seul test qui compte vraiment : ce que l'outil écrit est chargeable.* |
| Validation, une par famille | Chacune des sept familles refuse ce qu'elle doit refuser — et, pour les familles 4 et 5, **le même brouillon passe `fromJson` sans lever**, ce qui prouve qu'elles ne sont pas redondantes |
| Champ interdit | `heroClass` dans un fichier de carte est refusé à l'écriture, comme il l'est au chargement |
| Unicité | Un identifiant dont le fichier existe déjà est refusé — **et** une carte neutre nommée comme une carte de classe existante l'est aussi, alors que son chemin, lui, est libre (**E8**) |
| Carte de classe | L'écriture met `skills` à jour dans `class.json` ; un échec sur le second fichier laisse le premier absent (**E7**) |
| Création de classe | Le dossier `cards/` existe et est vide ; `iconPath` pointe l'image déposée |
| Image | Le placeholder est copié si absent ; **une image existante n'est pas écrasée** |
| Descripteurs | Les sept descripteurs couvrent exactement les catégories de `loadGameDataRegistry` — un ajout de source sans descripteur échoue |
| Racine absente | `ProjectRoot.find()` rend `null` sur une arborescence sans `pubspec.yaml`, et l'écran affiche le refus |

Les suites existantes servent de garde de bout en bout : une entité écrite par l'outil doit laisser
`entity_id_convention_test` et `referential_integrity_test` verts. C'est le seul contrôle qui vérifie
l'outil contre les règles réelles du dépôt plutôt que contre sa propre idée d'elles.

---

## 10. Hors périmètre

- **`patch_notes.json` et `audio.json`** — documents de configuration, pas des catalogues d'entités ;
  `entity_id_convention_test` les exclut déjà nommément. `patch_notes.json` appartient au skill
  `patch-notes-writer` et ne se modifie jamais à la main.
- **La suppression et le renommage** (**E1**), faits à la main.
- **L'édition des effets par formulaire** — c'était l'approche A, écartée : elle recopierait le
  schéma de chaque catégorie dans une seconde source de vérité.
- **Un sélecteur d'images**, qui demanderait une dépendance nouvelle (**E9**).
- **Les builds release et les plateformes sans système de fichiers accessible**, où l'éditeur ne
  s'ouvre simplement pas.
- **La localisation de l'éditeur lui-même** : il est en français, comme le lot 1.

---

## 11. Risques

| Risque | Portée | Traitement |
|:---|:---|:---|
| L'outil écrit dans la mauvaise arborescence | **Élevée** — des fichiers versionnés | `ProjectRoot` exige deux marqueurs et refuse d'ouvrir sinon (§3.1) |
| Une entité écrite casse le chargement pour toute sa catégorie | Élevée | Rien n'est écrit avant validation complète (**E6**) ; l'aller-retour le prouve (§9) |
| `skills` diverge du contenu du dossier | Moyenne — casse la suite de tests | Écriture couplée (**E7**), testée dans les deux sens (§5) |
| `pubspec.yaml` en retard après une création | Moyenne — disparition silencieuse au build | `sync_assets` relancé, code de sortie rapporté (§6.2) |
| Le changement n'apparaît pas dans le jeu, et l'on croit l'écriture ratée | Faible — confusion, pas perte | Message adapté au geste, et vérification manuelle exigée (§6.3) |
| Les descripteurs se périment par rapport aux sources de chargement | Faible | Test de correspondance (§9) |
| **Un import de `dart:io` casse le build web, donc le jeu publié** | **Élevée si elle survenait** | Un seul fichier l'importe, derrière un import conditionnel (§3.4) ; `grep` le vérifie, et `flutter build web --release` est exécuté avant la livraison |

Ce lot n'a **aucune interaction avec l'état de jeu ni avec la sauvegarde** : il s'utilise hors run,
depuis l'écran d'accueil. Le verrou de persistance du lot 1 ne le concerne pas.

---

## 12. Estimation

Neuf tâches, dont la première — le seam de plateforme et `ProjectRoot` — lève la seule inconnue
portante restante avec §6.3. L'ordre fait de chaque tâche un livrable testable : seam et racine,
descripteurs, validation (deux tâches), écrivain simple, écriture couplée, image, valeurs connues,
écran.

L'écran arrive en dernier délibérément : les huit neuvièmes de la valeur sont dans des unités sans
interface, et c'est là que sont tous les tests qui comptent.

Le plan est écrit : [`docs/superpowers/plans/2026-09-06-menu-debug-lot-2.md`](../plans/2026-09-06-menu-debug-lot-2.md).
