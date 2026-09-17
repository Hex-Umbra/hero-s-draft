## 19. Éditeur de Contenu — Seam Disque, Validation, Écriture (P-30, lot 2)

> [!IMPORTANT]
> **Rien n'est écrit avant que toute la validation passe, et « Valider » juge le document que
> « Écrire » écrira.** Un fichier invalide ne casse pas que lui : il fait échouer le chargement de
> toute sa catégorie. Voir [ADR-089](../_adr/ADR-089-editeur-de-contenu-seam-disque-et-validation-totale.md),
> amendé par [ADR-092](../_adr/ADR-092-formulaire-infere-du-document-et-ressources-liees.md).

L'outil crée ou modifie une entité de `assets/data/` depuis le jeu, en `kDebugMode` seulement,
atteint par le bouton « EDITEUR DE CONTENU » de l'accueil. Il **ne supprime ni ne renomme** rien.
Le format qu'il écrit est celui de [`_patterns/17-00`](17-00-chargeur-de-donnees-generique-et-motifs-de-che.md).
Cette fiche décrit le moteur, `lib/services/content_editor/` ; l'écran vit en
[`_patterns/19-5`](19-5-editeur-de-contenu-interface.md).

### 19.1. Les seams `dart:io`, la racine et le sélecteur

| Élément | Emplacement | Rôle |
|:---|:---|:---|
| `ContentFileSystem` | `lib/services/content_editor/content_file_system.dart` | Interface : opérations disque (dont `readBytes`, pour l'aperçu d'une image) + `run` d'un processus |
| `IoContentFileSystem` | `content_file_system_io.dart` | **Seul** fichier du moteur à importer `dart:io` |
| Stub web | `content_file_system_stub.dart`, choisi par `platform_file_system.dart` | `create()` rend `null` : l'écran refuse de s'ouvrir |
| `ProjectRoot.findFrom` | `project_root.dart` | Remonte depuis `Platform.resolvedExecutable` (12 niveaux max) jusqu'à `pubspec.yaml` **et** `assets/data` |
| `AssetPicker` | `asset_picker.dart` | Sélecteur de fichier ; `FilePickerAssetPicker` (`file_picker`) en vrai, surchargé en test |
| Providers | `content_editor_providers.dart` | `projectRootProvider` nul → écran refusé ; `assetPickerProvider` |

La racine est **passée en paramètre** à tout le moteur : les tests écrivent sur une arborescence
jetable, comme `bundle` pour `GameDataLoader`.

### 19.2. La table déclarative des 7 catégories

`kEntityDescriptors` (`entity_descriptor.dart`) décrit chaque catégorie en données : motif de
chemin, clés requises et interdites, bases bilingues, `construct` (le vrai `fromJson`), gabarit,
fichier de dossier, et six familles de métadonnées. Ajouter une catégorie = ajouter une entrée,
pas du code d'interface.

| Table | Désigne | Exemple |
|:---|:---|:---|
| `enumKeys` / `enumListKeys` | Une ou plusieurs valeurs d'un **enum Dart réel** | `rarity`, `intents[].type`, `eligibleCardTypes` |
| `vocabularyKeys` | Une chaîne libre dans le modèle, fermée dans le moteur | `effects[].type`, `color` et `icon` d'une forge |
| `referenceKeys` | Une entité d'une autre catégorie | *(aucun descripteur livré ne l'emploie depuis P-49 — `passiveTrait` en était le seul ; le mécanisme reste, vérifié sur un descripteur de test)* |
| `referenceListKeys` | Une **liste** d'entités d'une autre catégorie, non vide | `classes` d'un passif → catégorie `heroClass` ([ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md)) |
| `hexColorKeys` | Un `#RRGGBB` | `themeColor` |
| `assetKeys` | Un `AssetSlot` son, ou image à nom imposé (jeton `{id}`) | `sfx`, `classCard`, `iconPath`, `spritePath` d'un ennemi |

Un chemin s'écrit `effects[].type`, `[]` valant « tout élément » (`field_path.dart`). Un gabarit ne
porte **que** les clés qu'une entité de sa catégorie emploie ; `entity_descriptor_test.dart` garde
`clés lues par le modèle = gabarit ∪ assetKeys ∪ exclusions nommées` — `spritePath` d'une carte,
réservé aux illustrations à venir, est la seule exclusion.

### 19.3. Le pipeline de validation

L'écran juge d'abord les **fautes de conversion** du document (`EditorDocument.conversionFaults`,
« 1a » n'est pas un entier) et celles de la recette de classe. Puis `fillPlaceholders`
(`placeholder_filler.dart`) complète la prose vide en `[À REMPLIR] <id>` — et, **en création
seulement**, la mécanique vide par le gabarit : en modification, le fichier fait foi. Sans cette
complétion préalable, le contrôle bilingue refuserait exactement ce qu'elle fournit.

`EntityValidator.validate` (`entity_validator.dart`) s'arrête ensuite au **premier** contrôle en échec :

1. **Identité** — convention d'`id`, fichier déjà présent (création) ou absent (modification), doublon dans le registre
2. **Syntaxe** — le JSON décode en objet
3. **Clés** — interdites (celles que le répertoire impose), `id` redéclaré différent, requises
4. **Énumérations**, chemins imbriqués compris
5. **Vocabulaires** — usage de la catégorie sur le disque, fichier édité compris, plus le gabarit (`vocabularyOf`, `known_values.dart`)
6. **Couleurs** `#RRGGBB`
7. **Bilingue** — `_fr` et `_en`
8. **Références** — contre le registre, sautées si le registre est nul
9. **Ressources** — `sfx` déclaré dans `audio.json` ou importé ; import copiable (source, extension, identifiant neuf, destination libre) ; image obligatoire, ou optionnelle et déclarée, présente
10. **Cartes de signature** — bijection `skills` ↔ `cards/` **lue sur le disque**
11. **Construction** — le vrai `fromJson` ne lève pas

### 19.4. L'écriture transactionnelle

`EntityWriter.writeAll` (`entity_writer.dart`), dans cet ordre : dossiers, ressources importées,
`audio.json`, puis chaque entité.

- **Une pile de rollback partagée** par tous les brouillons et imports d'un geste : fichier créé →
  supprimé, fichier modifié → contenu d'origine rendu.
- **Import sur une destination existante** : copie de sauvegarde `<destination>.editor-backup`
  avant, restaurée sur échec, retirée **au mieux** après succès — une sauvegarde verrouillée ne
  transforme pas un geste abouti en échec, et `*.editor-backup` est ignoré par git.
- **Un son importé est déclaré dans `audio.json` par insertion textuelle** (`insertSound`,
  `audio_catalog.dart`) : le fichier est aligné à la main. Le résultat décodé doit valoir
  l'original plus l'entrée, sinon l'insertion lève et tout se défait.
- **Carte de classe = deux écritures** : son fichier, et son `id` ajouté (trié) au `skills` de
  `class.json`.
- **Classe = dossier + `cards/` vide** : `referential_integrity_test` lève sur un `cards/` absent.
- **Image placeholder copiée si absente et sans import** (`assets/placeholders/images/`) ; l'icône
  d'une classe ne l'est que si le corps porte `iconPath`.
- **`tool/sync_assets.dart` lancé une fois, en fin de geste** ; son échec est signalé, l'écriture
  est conservée.

`ClassRecipe` (`class_recipe.dart`) transforme « une classe et ses cartes de signature » en une
liste de brouillons pour un seul `writeAll` ; `faults()` refuse deux cartes de même `id`.

> [!NOTE]
> **Angles morts connus** : le rollback ne défait ni les dossiers ni les images placeholder ; le
> registre ne voit pas ce que la session vient d'écrire ; une valeur de vocabulaire fautive déjà
> sur le disque passe en modification ; un son remplacé reste sur le disque.

### 19.5. L'interface

Formulaire inféré du document, habillage « éditeur » et contrat de choix :
[`_patterns/19-5`](19-5-editeur-de-contenu-interface.md).

### 19.6. Après l'écriture

Création comme modification → **redémarrage à chaud** (`WriteReport.createdEntity` ne change que
le libellé). Pour une création, `pubspec.yaml` modifié compris, c'est vérifié à la main le
2026-09-14 (commit `35e4a9f`).

### 19.7. Tests du moteur

| Emplacement | Couvre |
|:---|:---|
| `test/unit/content_editor/` (14 fichiers + `fixtures.dart`, **vérifié le 2026-09-15**) | Racine, table, brouillon, complétion, validation, écriture et rollback des imports, catalogue, valeurs connues, recette, document, chemins, inférence, `audio.json` |
| `test/unit/content_editor/shipped_entities_round_trip_test.dart` | Chaque fichier livré, relu comme l'écran le relit, passe la validation et recompose exactement l'original |
