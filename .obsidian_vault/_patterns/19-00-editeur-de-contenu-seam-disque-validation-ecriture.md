## 19. Éditeur de Contenu — Seam Disque, Validation, Écriture (P-30, lot 2)

> [!IMPORTANT]
> **Rien n'est écrit avant que toute la validation passe, et « Valider » juge le document que
> « Écrire » écrira.** Un fichier invalide ne casse pas que lui : il fait échouer le chargement de
> toute sa catégorie. Voir [ADR-089](../_adr/ADR-089-editeur-de-contenu-seam-disque-et-validation-totale.md).

L'outil crée ou modifie une entité de `assets/data/` depuis le jeu, en `kDebugMode` seulement,
atteint par le bouton « EDITEUR DE CONTENU » de l'accueil. Il **ne supprime ni ne renomme** rien.
Le format qu'il écrit est celui de [`_patterns/17-00`](17-00-chargeur-de-donnees-generique-et-motifs-de-che.md).

### 19.1. Le seam `dart:io` et la racine

| Élément | Emplacement | Rôle |
|:---|:---|:---|
| `ContentFileSystem` | `lib/services/content_editor/content_file_system.dart` | Interface : opérations disque + `run` d'un processus |
| `IoContentFileSystem` | `content_file_system_io.dart` | **Seul** fichier du moteur à importer `dart:io` |
| Stub web | `content_file_system_stub.dart`, choisi par `platform_file_system.dart` | `create()` rend `null` : l'écran refuse de s'ouvrir |
| `ProjectRoot.findFrom` | `project_root.dart` | Remonte depuis `Platform.resolvedExecutable` (12 niveaux max) jusqu'à `pubspec.yaml` **et** `assets/data` |
| Providers | `content_editor_providers.dart` | `projectRootProvider` nul → écran refusé |

La racine est **passée en paramètre** à tout le moteur : les tests écrivent sur une arborescence
jetable, comme `bundle` pour `GameDataLoader`.

### 19.2. La table déclarative des 7 catégories

`kEntityDescriptors` (`entity_descriptor.dart`) décrit chaque catégorie en données : motif de
chemin, clés requises et interdites, `enumKeys` construites depuis les **enums Dart réels**,
`referenceKeys`, `hexColorKeys`, bases bilingues, `construct` (le vrai `fromJson`), gabarit,
fichier de dossier, nom d'image à jeton `{id}`, clé du chemin d'image. Ajouter une catégorie =
ajouter une entrée, pas du code d'interface.

### 19.3. Le pipeline de validation

`EntityValidator.validate` (`entity_validator.dart`) s'arrête au **premier** contrôle en échec :

1. **Identité** — convention d'`id`, fichier déjà présent (création) ou absent (modification), doublon dans le registre
2. **Syntaxe** — le JSON décode en objet
3. **Clés** — interdites (celles que le répertoire impose), `id` redéclaré différent, requises
4. **Énumérations**
5. **Couleurs** `#RRGGBB`
6. **Bilingue** — `_fr` et `_en`
7. **Références** — contre le registre, sautées si le registre est nul
8. **Cartes de signature** — bijection `skills` ↔ `cards/` **lue sur le disque**
9. **Construction** — le vrai `fromJson` ne lève pas

Avant tout jugement, `fillPlaceholders` (`placeholder_filler.dart`) complète la prose vide en
`[À REMPLIR] <id>` et la mécanique vide par la valeur du gabarit — sinon le contrôle 6 refuserait
exactement ce que la complétion fournit.

### 19.4. L'écriture transactionnelle

`EntityWriter.writeAll` (`entity_writer.dart`) :

- **Une pile de rollback partagée** par tous les brouillons d'un geste : fichier créé → supprimé,
  fichier modifié → contenu d'origine rendu.
- **Carte de classe = deux écritures** : son fichier, et son `id` ajouté (trié) au `skills` de
  `class.json`.
- **Classe = dossier + `cards/` vide** : `referential_integrity_test` lève sur un `cards/` absent.
- **Image placeholder copiée si absente, jamais écrasée** (`assets/placeholders/images/`).
- **`tool/sync_assets.dart` lancé une fois, en fin de geste** ; son échec est signalé, l'écriture
  est conservée.

`ClassRecipe` (`class_recipe.dart`) transforme « une classe et ses cartes de signature » en une
liste de brouillons pour un seul `writeAll` ; `faults()` refuse deux cartes de même `id`.

> [!NOTE]
> **Angles morts connus** : le rollback ne défait ni les dossiers ni les images placeholder ; le
> registre ne voit pas ce que la session vient d'écrire ; une saisie non convertible est remplacée
> par la valeur du gabarit avant validation.

### 19.5. L'interface

| Élément | Emplacement | Règle |
|:---|:---|:---|
| Arbre de boutons Type → Action → Entité | `content_editor_screen.dart`, `lib/ui/widgets/content_editor/tree_level.dart` | Changer de type referme les niveaux inférieurs et vide l'`id` ; après une création, retour au premier niveau (l'entité n'est pas au registre avant redémarrage) |
| Propriétaire d'une carte | couleur de fond du bouton, `themeColor` de sa classe | Gris neutre pour une carte sans classe ; magenta pour une classe inachevée |
| Formulaire de création | `entity_form.dart` | Toutes les clés du gabarit ; `passiveTrait` choisi dans le **catalogue** des passifs |
| Mode Modifier | même écran | Corps JSON unique, « Charger » exigé d'abord ; pas de roue de couleur |
| Couleur | `color_field.dart` | Roue `flutter_colorpicker`, sans alpha |
| Bouton de choix | `choice_button.dart` | Un seul bouton pour niveaux, pastilles et passifs ; sélectionné = coche, plus un anneau `primary` sur une couleur d'identité ou un fond `primary` sans elle |
| Lisibilité | `readableOn(fill)` dans `color_field.dart` | Texte noir ou blanc selon la luminance WCAG, pas `estimateBrightnessForColor` (3,1:1 sur le bleu du paladin) |

Le catalogue du disque est **retenu par catégorie** et vidé après écriture, au lieu d'être relu à
chaque frappe (commit `bcfd190`).

> [!NOTE]
> Le bouton de choix, `readableOn` et le balayage de contraste de
> `test/widget/content_editor/contrast.dart` (4,5:1) arrivent avec le commit `9b3ce82`.

### 19.6. Après l'écriture

Le message reste conservateur, le geste suffisant n'ayant pas été établi empiriquement : création
→ recompilation (`flutter run`), modification → redémarrage à chaud (`relaunchAdvised`).

### 19.7. Tests

| Emplacement | Couvre |
|:---|:---|
| `test/unit/content_editor/` (9 fichiers + `fixtures.dart`) | Racine, table, brouillon, complétion, validation, écriture et rollback, catalogue, valeurs connues, recette |
| `test/widget/content_editor_screen_test.dart` | Arbre, formulaire, Valider = Écrire, lisibilité |
| `test/widget/content_editor/color_field_test.dart` | Roue et transmission de la couleur, contraste |
