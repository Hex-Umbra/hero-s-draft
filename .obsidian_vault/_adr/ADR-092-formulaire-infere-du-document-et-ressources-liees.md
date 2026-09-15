### Statut

✅ **Livré le 2026-09-14**, suite du lot 2 de P-30 (éditeur de contenu), branche
`feat/menu-debug-lot-2` — commits `5c69f4e` à `25b2945`. **Amende
[ADR-089](ADR-089-editeur-de-contenu-seam-disque-et-validation-totale.md)** sur trois points : une
saisie non convertible devient une faute au lieu d'être remplacée, un import explicite peut écraser
une image, et un geste d'écriture peut toucher `audio.json` et un fichier binaire. Le reste
d'ADR-089 — rien n'est écrit avant que toute la validation passe — tient inchangé.

### Contexte

Tests manuels du propriétaire, 2026-09-14 : la création est vérifiée, la modification ne l'est pas.
Quatre défauts — chiffres remesurés le 2026-09-15 sur les fichiers livrés, que la livraison n'a pas
modifiés :

- **Les gabarits écrivaient des clés qu'aucune entité n'emploie** : `"sfx": ""` pour la carte, la
  relique et l'ennemi (0 fichier sur 52 porte `sfx`), `"spritePath": ""` pour la carte (0 sur 23).
  `audio_catalogue_test` refuse tout `sfx` non déclaré : **toute entité créée faisait rougir la suite**.
- **Le formulaire ne connaissait pas les types** — un champ texte par clé en création, une boîte JSON
  unique en modification — et une saisie non convertible était remplacée en silence par le gabarit.
- **Des chaînes libres dans le modèle sont fermées dans le moteur** : un type d'effet inconnu du
  résolveur passe `fromJson` et ne fait rien en jeu, sans un message.
- **Aucune ressource ne pouvait être liée** : ni son de carte, ni image de classe ou d'ennemi.

### Décision

**D1 — Un gabarit ne porte que les clés qu'une entité de sa catégorie emploie**, et une clé
optionnelle laissée vide n'est jamais écrite. `CardData.spritePath` reste pourtant dans le modèle,
réservé aux illustrations de carte à venir : c'est une **exclusion nommée** de la garde
« gabarit ⊇ modèle », devenue `clés du modèle = gabarit ∪ assetKeys ∪ exclusions`.

**D2 — L'état du formulaire est un document** (`EditorDocument`, un `Map` adressé par chemin),
dont le formulaire et la vue JSON brute sont deux vues. `EntityDraft.mechanics` reste du texte JSON
jugé par `EntityValidator` : le formulaire n'est qu'une autre façon de le produire.

**D3 — Les champs sont inférés du document**, non d'une liste : `inferFieldKind` choisit le widget
d'après les métadonnées du descripteur, puis le type JSON de la valeur ; la première règle qui
s'applique l'emporte. **Aucune clé du fichier n'est perdue**, même inconnue du gabarit. Création et
modification partagent le même formulaire.

**D4 — Une saisie non convertible est une faute signalée** (`conversionFaults`), jugée avant le
moteur ; la valeur du document ne change pas. En modification, le fichier fait foi : le gabarit ne
complète plus que la prose vide (commit `47f6731`).

**D5 — Les vocabulaires fermés côté moteur se lisent sur le disque** (`vocabularyKeys`,
`vocabularyOf`) : admis = l'usage de **toute** la catégorie, fichier édité compris, plus le gabarit.
Exclure le fichier édité refusait de modifier toute entité portant une valeur unique. Le premier
fichier d'un type réellement nouveau, qui demande du code de jeu, s'écrit à la main. `color` et
`icon` d'une amélioration de forge sont des vocabulaires, pas un hex : les 8 fichiers livrés portent
des noms du moteur (`orangeAccent`…).

**D6 — Les ressources sont déclarées au descripteur** (`assetKeys`, `AssetSlot` son ou image), comme
les couleurs et les références ; elles absorbent l'ancienne déclaration d'image. Un son se choisit
dans `audio.json` ou s'importe ; une image s'importe sous son nom imposé.

**D7 — Un import est différé jusqu'à « Écrire » et entre dans la pile de rollback**, binaire
compris : copie de sauvegarde `*.editor-backup` d'une destination existante, restaurée sur échec,
retirée au mieux sur succès. Le son est déclaré par **insertion textuelle** dans `audio.json` — le
réencoder réécrirait un fichier aligné à la main —, contrôlée par décodage avant et après.

**D8 — Le sélecteur de fichier est un seam injectable** (`AssetPicker`, `file_picker` derrière
`FilePickerAssetPicker`) : les tests n'ouvrent aucune fenêtre.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Document et chemins | `lib/services/content_editor/editor_document.dart`, `field_path.dart` |
| Inférence du widget | `lib/services/content_editor/field_kind.dart` — `inferFieldKind` |
| Vocabulaires | `lib/services/content_editor/known_values.dart` — `vocabularyOf` ; `entity_validator.dart` — `_vocabulary` |
| Ressources | `entity_descriptor.dart` — `AssetSlot`, `assetKeys` ; `pending_import.dart` ; `entity_validator.dart` — `_assets` |
| Rollback des imports | `lib/services/content_editor/entity_writer.dart` — `_copyAsset`, `_dropBackups` |
| Insertion dans `audio.json` | `lib/services/content_editor/audio_catalog.dart` — `insertSound` |
| Seam du sélecteur | `lib/services/content_editor/asset_picker.dart`, `content_editor_providers.dart` — `assetPickerProvider` |
| Rendu | `lib/ui/widgets/content_editor/document_form.dart`, `asset_field.dart` |
| Tests | `test/unit/content_editor/` — `editor_document_test.dart`, `field_kind_test.dart`, `field_path_test.dart`, `audio_catalog_test.dart`, `shipped_entities_round_trip_test.dart` |

`shipped_entities_round_trip_test.dart` est la garde qui manquait : chaque fichier livré, relu comme
l'écran le relit, passe la validation et recompose exactement le fichier d'origine.

### Conséquences

- `file_picker` entre en `dependencies` pour un outil de debug, comme `flutter_colorpicker`.
- L'outil ne supprime toujours rien : un son remplacé reste sur le disque, et `volume` ou
  `variants` d'un son importé se règlent à la main.
- Une valeur de vocabulaire fautive **déjà sur le disque** passe en modification : le contrôle garde
  la création, pas le stock.
- Un sélecteur non bloquant (Windows, Linux) peut revenir après un changement d'entité : son
  résultat est ignoré (commits `2b4446a`, `4f3551a`).
- Spec : `docs/superpowers/specs/2026-09-14-editeur-de-contenu-formulaire-infere-et-ressources-design.md` ;
  plan : `docs/superpowers/plans/2026-09-14-editeur-de-contenu-formulaire-infere-et-ressources.md`.
