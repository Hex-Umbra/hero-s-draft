# Éditeur de contenu — formulaire inféré du document et ressources liées — Conception

Date : 2026-09-14
Statut : **Conception** — non implémenté
Révision : v4 — **v4 : `color` et `icon` d'une amélioration de forge sont des vocabulaires, pas
un hex** : les huit fichiers livrés portent des noms du moteur, et la déclaration hex refusait de
les modifier (§4.4). v3 — **v3 : le vocabulaire d'une clé est l'usage de toute la catégorie, fichier édité
compris, plus le gabarit** : l'exclure refusait de modifier toute entité portant une valeur unique
(§4.5). Et les `referenceKeys` absentes du document restent des champs, faute de quoi le passif
d'une classe disparaissait de la création (§4.2). v2 — **v2 : `CardData.spritePath` reste dans le modèle**, réservé aux illustrations de
carte à venir ; seul le gabarit de l'éditeur cesse de l'écrire (D2, §3.2). Et la distinction entre
gabarit, données et modèle est posée d'emblée, faute de quoi « retirer une clé » était ambigu.
Périmètre : **trois étapes, dans cet ordre.** L'étape A rend les gabarits honnêtes — ils ne portent
plus que ce qu'une entité emploie. L'étape B remplace la boîte JSON et les champs texte par un
formulaire **inféré du document lui-même**. L'étape C y ajoute les champs de ressource : un son
choisi ou importé, une image importée. B consomme les gabarits de A ; C est un type de champ de B.
Sources amont :
- Tests manuels du propriétaire, 2026-09-14 : création vérifiée, modification en cours, trois
  observations (§1)
- `docs/superpowers/specs/2026-09-06-menu-debug-lot-2-editeur-de-contenu-design.md` — le moteur,
  le seam disque et la validation, dont cette spec hérite sans les redéfinir
- `docs/superpowers/specs/2026-09-08-editeur-de-contenu-creation-guidee-design.md` — l'arbre, les
  recettes, la garde « gabarit ⊇ modèle » (§7.2) que l'étape A amende

> **Ce que cette spec change, et ce qu'elle ne change pas.**
>
> `EntityDraft.mechanics` reste du **texte JSON**, et `EntityValidator` le juge comme aujourd'hui :
> le formulaire n'est qu'une autre façon de produire ce texte. L'ordre
> `composer → substituer → valider → écrire` et la décision « rien n'est écrit avant que toute la
> validation passe » sont intacts. Ce qui change : ce que les gabarits contiennent, la façon dont
> l'interface compose le document, deux familles de validation, et ce qu'un geste d'écriture peut
> toucher (un fichier binaire, `audio.json`).

> **Trois niveaux, à ne pas confondre.** Dans cette spec, « retirer une clé » vise toujours le
> premier.
>
> | Niveau | Emplacement | Touché par cette spec ? |
> |:---|:---|:---|
> | **Gabarit de l'éditeur** — le JSON pré-rempli à la création | `lib/services/content_editor/entity_descriptor.dart` | **Oui** (étape A) |
> | **Données du jeu** — les fichiers d'entité livrés | `assets/data/` | **Non.** Seuls les imports explicites (§5) ajoutent un fichier son ou image, et une ligne à `audio.json` |
> | **Modèle Dart** — ce que le jeu sait lire | `lib/models/data/` | **Non.** Le jeu lit et joue `sfx` comme aujourd'hui, et `CardData.spritePath` reste |

---

## 1. Le problème

**Les gabarits écrivent des clés qu'aucune entité n'emploie.** Mesuré le 2026-09-14 sur les
fichiers livrés (hors entités de test `gambler`, `gremlin`) :

| Clé du gabarit | Catégorie | Fichiers livrés qui la portent | Conséquence |
|:---|:---|---:|:---|
| `"spritePath": ""` | carte | 0 / 23 | Ne casse rien, mais chaque carte créée porte une valeur vide qu'aucun système ne remplit : il n'existe ni illustration de carte, ni placeholder, ni lecteur |
| `"sfx": ""` | carte, relique, ennemi | 0 / 52 | `audio_catalogue_test` refuse tout `sfx` non nul non déclaré : **toute entité créée par l'éditeur fait rougir la suite** |

**Le formulaire ne connaît pas les types.** En création, un champ texte par clé du gabarit, les
listes y figurant en JSON compact sur une ligne ; en modification, une boîte JSON unique. Une saisie
non convertible est remplacée **en silence** par la valeur du gabarit (angle mort connu,
`_patterns/19-00` §19.4).

**Les vocabulaires fermés côté moteur ne sont pas contrôlés.** `CardEffect.type` est une chaîne
libre dans le modèle, mais `card_component.dart` et le résolveur n'en connaissent qu'une poignée.
`dice_throw` porte `"type": "skill"` — un type de **carte**, pas d'effet : la validation passe, et
la carte ne fait rien en jeu, sans un message.

**Aucune ressource ne peut être liée à une entité.** Le son d'une carte ou d'une relique, l'image
d'une classe ou d'un ennemi : l'éditeur dépose un placeholder et s'arrête là.

> Le quatrième défaut observé — la modification affichait le gabarit au lieu du fichier choisi —
> est **corrigé hors de cette spec** (choisir une entité la relit), et n'y est pas rediscuté.

---

## 2. Décisions retenues

| # | Décision |
|:---|:---|
| D1 | Un gabarit ne porte **que les clés qu'une entité de sa catégorie emploie**. `spritePath` quitte la carte ; `sfx` quitte la carte, la relique et l'ennemi — il devient un champ de ressource (étape C). |
| D2 | `CardData.spritePath` **reste dans le modèle** : les cartes recevront des illustrations dessinées à la main lors de refontes à venir. Le gabarit cesse seulement de l'écrire ; la clé reviendra au gabarit, avec son champ de ressource, le jour où une illustration sera affichée. |
| D3 | Une clé optionnelle laissée vide **n'est pas écrite** — jamais `""`. |
| D4 | L'état du formulaire est **un document** (`Map`), non une table de contrôleurs texte. Le formulaire et la vue JSON brute en sont deux vues. |
| D5 | Les champs viennent **du document** (le fichier en modification, le gabarit en création) : le type de chaque valeur choisit le widget, les métadonnées du descripteur l'affinent. **Aucune clé du fichier n'est perdue**, même inconnue du gabarit. |
| D6 | Création et modification partagent **le même formulaire**. Les pastilles de propriétaire et les cartes de signature restent propres à la création. |
| D7 | Une saisie non convertible est une **faute signalée**, plus un remplacement silencieux. |
| D8 | Les chaînes à vocabulaire fermé côté moteur sont **déclarées** au descripteur (`vocabularyKeys`) et **refusées** si ni un fichier de la catégorie ni le gabarit ne les emploient. |
| D9 | Les ressources sont **déclarées** au descripteur (`assetKeys`), comme les couleurs et les références. Elles absorbent `imageName` / `imagePathKey` : une seule déclaration des images. |
| D10 | Un son se **choisit** parmi ceux d'`audio.json` ou s'**importe** ; l'import copie le fichier et déclare le son dans `audio.json`, dans le même geste. |
| D11 | Une image s'**importe** et remplace celle du nom imposé. Il n'y a pas de liste : le nom est dicté par l'identifiant. |
| D12 | Un import est **différé jusqu'à « Écrire »** et entre dans la pile de rollback, binaire compris. |
| D13 | Le choix de fichier passe par `file_picker`, derrière un seam injectable (`AssetPicker`) pour que les tests n'ouvrent aucune fenêtre. |

---

## 3. Étape A — des gabarits qui disent le schéma

### 3.1 Ce qui sort des gabarits

| Catégorie | Retiré | Pourquoi |
|:---|:---|:---|
| Carte | `spritePath` | Aucune carte ne le porte, aucun écran ne l'affiche ; le modèle le garde (D2) |
| Carte | `sfx` | Devient un champ de ressource ; absent tant qu'aucun son n'est choisi |
| Relique | `sfx` | Idem |
| Ennemi | `sfx` | Idem |

`animation` reste au gabarit de la carte : 23 cartes sur 23 la portent, et `AudioDirector` s'en sert
comme repli. `isExhaust` et `baseMaxForgeUpgrades` restent : lus par le modèle, portés par une
partie des cartes, et leur valeur par défaut doit rester modifiable.

### 3.2 Deux `spritePath` qui n'ont rien en commun

| | Ennemi | Carte |
|:---|:---|:---|
| Valeur écrite à la création | chemin **calculé** par l'écrivain (`EntityDraft.compose`) | `""` pré-écrit par le gabarit |
| Image de remplacement | copiée si absente (`EntityWriter._placeImage`) | aucune |
| Lecteur en jeu | `enemy_card.dart`, `enemy_instance.dart`, `game_data_registry.dart` | aucun (`grep` du 2026-09-14) |
| Dans cette spec | inchangé, plus « Importer… » (§5.3) | quitte le gabarit ; **reste dans `CardData`** (D2) |

Le système du sprite par défaut — chemin calculé, placeholder magenta copié — ne concerne que les
dossiers d'ennemi et de classe. Il fonctionne, et cette spec le conserve.

### 3.3 La règle d'omission

À la composition du document, une clé **absente de `requiredKeys`** dont la valeur est une chaîne
vide est **retirée**. Elle vaut pour les clés de premier niveau ; les clés imbriquées (`statusId`
d'un effet) suivent la même règle dans leur élément.

La validation la double côté ressources : en vue JSON brute, où rien ne compose, un `"sfx": ""`
est refusé par la famille « ressources » (§5.6) — un son vide n'est déclaré nulle part.

### 3.4 La garde « gabarit ⊇ modèle » amendée

`entity_descriptor_test.dart` — *chaque gabarit porte exactement les clés attendues* — compare
aujourd'hui gabarit et clés lues par le modèle, moins les exclusions de la §5.3 de la spec du
2026-09-08. Elle devient :

```
clés lues par le modèle  =  gabarit  ∪  assetKeys  ∪  exclusions nommées
```

Une clé que le modèle lit sans figurer ni au gabarit, ni aux ressources, ni aux exclusions reste
une faute ; une clé du gabarit que le modèle ne lit pas aussi. Le retrait de `sfx` du gabarit ne
l'affaiblit donc pas : `sfx` doit figurer aux `assetKeys` des trois catégories qui le lisent.

`spritePath` de la carte entre aux **exclusions nommées**, avec sa raison : lu par le modèle,
réservé aux illustrations à venir, hors formulaire tant qu'aucun écran ne l'affiche. Une carte
existante qui le porterait garde sa clé en modification (D5).

---

## 4. Étape B — le formulaire inféré

### 4.1 Un document, deux vues

L'écran tient un `EditorDocument` (`lib/services/content_editor/editor_document.dart`, Dart pur) :

| Opération | Rôle |
|:---|:---|
| `EditorDocument.fromJson(map)` | Graine : le fichier relu, ou le gabarit décodé |
| `valueAt(path)` / `setAt(path, value)` | Lecture et écriture par chemin (`effects[1].value`) |
| `addElement(path)` / `removeElement(path, index)` | Liste d'objets : ajoute un élément modèle (§4.3), retire un élément |
| `toMechanics()` | Le texte JSON de `EntityDraft.mechanics`, règle d'omission (§3.3) appliquée |
| `conversionFaults` | Les saisies non convertibles, en `ValidationFault` (D7) |

Le formulaire et la vue « JSON brut » sont deux vues de ce document :

- **Formulaire → brut** : le document encodé à deux espaces, comme l'écrivain.
- **Brut → formulaire** : le texte décodé. S'il ne décode pas, ou ne décode pas en objet, la vue
  reste brute et la raison s'affiche au canal des fautes ; rien n'est perdu.
- **Écrire depuis la vue brute** juge et écrit le texte brut tel quel.

`_mechanics`, `_mechanicsFields`, `_coerce` et `_composeCreateMechanics` de
`content_editor_screen.dart` disparaissent : ils sont précisément ce que `EditorDocument` remplace.

### 4.2 D'où viennent les champs

```
champs  =  clés du document  ∪  assetKeys  ∪  referenceKeys du descripteur
```

Dans l'ordre du document, puis les ressources et références absentes. Une référence absente est
celle d'une création : `passiveTrait` ne figure pas au gabarit d'une classe (spec du 2026-09-08,
§5.5), et reste pourtant à choisir. **Ne deviennent jamais des champs** :
`id` (triangle d'identité), la prose bilingue de premier niveau (ses propres champs), `skills`
(dérivé par l'écrivain), les `forbiddenKeys`. Les clés d'image (`classCard`, `iconPath`,
`spritePath` d'un ennemi) ne sont pas des champs texte : ce sont les champs de ressource du §5.3.

Une clé inconnue du gabarit — ajoutée à la main, ou par la vue brute — reçoit le widget de son type.
C'était la seule raison de garder une boîte JSON unique en modification : elle disparaît.

### 4.3 Le choix du widget

L'inférence (`lib/services/content_editor/field_kind.dart`, Dart pur) rend un `FieldKind` à partir
du chemin, de la valeur et du descripteur. **La première ligne qui s'applique l'emporte.**

| # | Condition | Widget |
|---:|:---|:---|
| 1 | Chemin dans `assetKeys` | Champ de ressource (§5) |
| 2 | Chemin dans `referenceKeys` | Boutons du catalogue de la catégorie visée (livré) |
| 3 | Chemin dans `hexColorKeys` | `ColorField` (livré) |
| 4 | Chemin dans `enumKeys` | Boutons de choix, un seul sélectionné |
| 5 | Chemin dans `enumListKeys` | Boutons de choix, plusieurs sélectionnés |
| 6 | Chemin dans `vocabularyKeys` | Boutons de choix issus des valeurs connues (§4.5) |
| 7 | `bool` | Interrupteur |
| 8 | `int` | Champ numérique entier |
| 9 | `double` | Champ numérique décimal |
| 10 | `String` | Champ texte |
| 11 | Liste d'objets | Une carte par élément, formulaire récursif ; « Ajouter », « Retirer » |
| 12 | Liste de chaînes | Pastilles retirables et un champ d'ajout |
| 13 | Objet | Groupe, formulaire récursif |
| 14 | Autre (`null`, liste vide sans modèle) | Petit champ JSON pour **cette clé seule** |

**Les chemins** s'écrivent `effects[].type`, `choices[].actions[].type` : un `[]` vaut « tout
élément ». Les tables `enumKeys`, `vocabularyKeys`, `assetKeys` du descripteur les acceptent ; les
clés de premier niveau restent écrites comme aujourd'hui (`rarity`).

**L'élément modèle** d'une liste d'objets (ligne 11) est le premier élément de la même liste au
gabarit, à défaut le premier du document. Faute des deux, la ligne 14 s'applique.

**Une paire bilingue imbriquée** (`text_fr` / `text_en`, `result_text_fr` / `result_text_en` d'un
choix d'événement) s'affiche sur une rangée, français à gauche.

**La fidélité du type** : un champ entier rend un `int`, un champ décimal un `double`. Une saisie
non convertible **ne change pas la valeur du document** et produit une faute de conversion
(`cost : « 1a » n'est pas un entier`), jugée avant la validation du moteur — « Valider » et
« Écrire » la montrent tous deux, et « Écrire » s'arrête.

### 4.4 Ce que le descripteur gagne

| Catégorie | `enumKeys` ajoutées | `vocabularyKeys` | `hexColorKeys` ajoutées |
|:---|:---|:---|:---|
| Carte | — | `animation`, `effects[].type`, `effects[].statusId` | — |
| Relique | — | `effectType` | — |
| Passif | — | `effectType` | — |
| Événement | — | `choices[].actions[].type` | — |
| Amélioration de forge | — | `color`, `icon` | — |
| Ennemi | `intents[].type` → `IntentType` | — | — |

`intents[].type` est une vraie énumération Dart (`IntentType`) dont `fromJson` retombe **en
silence** sur `attack` : la déclarer la fait valider. `color` et `icon` d'une amélioration de forge
sont, dans les huit fichiers livrés, des **noms du moteur** (`amberAccent`, `flash_on_rounded`…) que
`forge_slot_row.dart` traduit un à un, un nom inconnu retombant en silence sur du gris et
`Icons.help_outline` : deux vocabulaires, pas un hex.

### 4.5 Les vocabulaires fermés côté moteur

Un `vocabularyKey` désigne une chaîne libre dans le modèle mais fermée dans le moteur : un type
d'effet inconnu du résolveur ne fait rien. Aucune énumération Dart ne la décrit ; **le disque, si**.

- **Les valeurs admises** (`vocabularyOf`) : `knownValues`, étendu aux chemins imbriqués, sur
  **tous** les fichiers de la catégorie, **plus les valeurs du gabarit**. Le gabarit est écrit à la
  main et fait foi ; sans lui, une création dans une arborescence vide refuserait son propre
  `gain_armor`.
- **Pourquoi le fichier édité n'est pas exclu.** Mesuré le 2026-09-14 : l'animation `fire`, `ice`,
  `poison` ou `lightning`, les statuts `burn`, `freeze`, `shock`… ne sont portés que par **une**
  carte chacun. Exclure le fichier édité refuserait de modifier ces cartes. La contrepartie : une
  valeur fautive **déjà sur le disque** passe en modification — elle aurait été refusée à sa
  création, qui est le moment que ce contrôle garde.
- **La validation** (famille nouvelle, juste après les énumérations) : une valeur absente des
  valeurs admises est refusée — `effects[0].type : « skill » n'est employé ni par un fichier ni
  par le gabarit ; le moteur ne le connaît pas`.
- **Le cas légitime** — un type d'effet nouveau, livré avec son code — s'écrit à la main dans son
  premier fichier. Il demande du code de jeu, donc un développeur : c'est le prix accepté d'un
  refus qui attrape toutes les fautes de frappe.

Le panneau des valeurs connues affiche les chemins imbriqués avec les clés de premier niveau.

### 4.6 Décomposition

| Unité | Emplacement | Dépend de |
|:---|:---|:---|
| `EditorDocument` | `lib/services/content_editor/editor_document.dart` | rien |
| `inferFieldKind` | `lib/services/content_editor/field_kind.dart` | `EntityDescriptor` |
| `knownValues` par chemin | `known_values.dart` (étendu) | `entity_catalog.dart` |
| `DocumentForm` (rendu récursif) | `lib/ui/widgets/content_editor/document_form.dart` | `EditorDocument`, `inferFieldKind`, `ChoiceButton`, `ColorField` |
| `AssetField` (son, image) | `lib/ui/widgets/content_editor/asset_field.dart` | `AssetSlot`, `ChoiceButton` |

`EntityForm` garde l'identité, la prose, les pastilles, la recette et les boutons, et délègue la
mécanique à `DocumentForm`. `content_editor_screen.dart` (790 lignes) perd ses contrôleurs par clé.

---

## 5. Étape C — les ressources

### 5.1 La déclaration

`EntityDescriptor.assetKeys : Map<String, AssetSlot>`.

| Catégorie | Clé | Emplacement | Nom imposé | Obligatoire |
|:---|:---|:---|:---|:---:|
| Carte, relique, ennemi | `sfx` | son (§5.2) | — | non |
| Classe | `classCard` | image | `{id}.png` | oui |
| Classe | `iconPath` | image | `icon.png` | non |
| Ennemi | `spritePath` | image | `sprite.png` | oui |

`imageName` et `imagePathKey` disparaissent du descripteur : `imagePathOf`, `_placeImage` et
`_placeClassIcon` de l'écrivain lisent les emplacements image. Le comportement livré ne change pas —
placeholder déposé à la création s'il n'y a ni import ni fichier, jamais d'icône déposée en
modification (spec du 2026-09-08, §3.1).

### 5.2 Le son

Le champ montre :

- **« aucun »** — la clé n'est pas écrite (D3) ;
- **les sons déclarés** — les clés de `sounds` d'`audio.json`, lues sur le disque, triées ;
- **« Importer… »** — ouvre le sélecteur (`wav`, `mp3`, `ogg`), puis demande l'identifiant du son,
  proposé égal à l'identifiant de l'entité. Le son apparaît sélectionné, marqué « à importer ».

À l'écriture, dans cet ordre :

1. copie du fichier vers `assets/audio/sfx/<son>.<extension>` ;
2. déclaration dans `audio.json` : **insertion textuelle** d'une ligne
   `"<son>": { "file": "sfx/<son>.<extension>" }` en fin du bloc `sounds`, virgule ajoutée à la
   ligne précédente. Le fichier est aligné à la main ; le réencoder réécrirait ses 100 lignes ;
3. **contrôle** : le nouveau texte décodé doit être égal à l'ancien décodé plus l'entrée, sinon
   l'écriture lève et tout est défait.

`volume` et `variants` gardent leur défaut (1,0 et 1) ; les régler reste un geste manuel.

### 5.3 L'image

Le champ montre l'image actuelle **lue sur le disque** (`Image.memory` sur les octets de
`ContentFileSystem.readBytes`) — un fichier écrit pendant la session n'est pas dans le bundle avant
le redémarrage, et `Image.file` ferait entrer `dart:io` dans `lib/ui/`, ce que le build web refuse — son chemin, et « Importer… » (`png`
seulement : les trois noms imposés sont en `.png`). Pour `iconPath`, « aucune » retire la clé ;
`ClassIdentity.imageOf` retombe alors sur `classCard`. À la création d'une classe, l'emplacement de
l'icône est présent d'emblée (le placeholder est déposé à l'écriture), et « aucune » retire à la fois
la clé et le placeholder.

À l'écriture, le fichier choisi est copié sous le nom imposé, **par-dessus** l'image existante :
c'est le sens même d'un import. La valeur de la clé reste calculée par l'écrivain, jamais saisie.

### 5.4 La transaction

La pile de rollback de `EntityWriter.writeAll` gagne une étape de ressource :

| Cas | Avant | Rollback | Succès |
|:---|:---|:---|:---|
| Destination absente | — | supprimer la copie | — |
| Destination présente | copie de sauvegarde `<destination>.editor-backup` | restaurer la sauvegarde | supprimer la sauvegarde |

`audio.json` passe par l'étape texte existante (`WriteStep`), qui restitue son contenu d'origine.
Ordre du geste : dossier de l'entité, ressources, `audio.json`, JSON de l'entité, enregistrement de la carte de
signature, `sync_assets` une fois. L'écriture n'emploie que ce que `ContentFileSystem` offre déjà : `copyFile`,
`deleteFile`, `readFile`, `writeFile`. Seul l'aperçu du §5.3 lui ajoute `readBytes`.

### 5.5 Le seam du sélecteur

```dart
abstract class AssetPicker {
  /// Chemin absolu choisi, ou `null` si l'usager annule.
  Future<String?> pickFile({required List<String> extensions});
}
```

`FilePickerAssetPicker` (`file_picker`) est l'implémentation réelle, `assetPickerProvider` l'expose,
et les tests le surchargent. `file_picker` entre dans `dependencies:` ; l'écran étant derrière
`kDebugMode`, son code disparaît des builds de release — même coût accepté que
`flutter_colorpicker` (spec du 2026-09-08, §5.4).

### 5.6 La validation « ressources »

Famille nouvelle, après les références :

| Contrôle | Faute |
|:---|:---|
| `sfx` présent | déclaré dans `audio.json`, ou import en attente du même nom |
| Import de son | identifiant `snake_case`, absent de `sounds`, fichier de destination absent |
| Import (tout) | fichier source existant, extension admise |
| Image obligatoire, en modification | fichier présent sur le disque, ou import en attente |

---

## 6. Tests

Tout test cité doit pouvoir échouer : écrit d'abord, vu rouge, rendu vert.

**Étape A**
1. Aucun gabarit ne porte `spritePath` (carte) ni `sfx` ; la garde amendée (§3.4) rougit si `sfx`
   quitte les `assetKeys` d'une des trois catégories qui le lisent, ou si l'exclusion de
   `spritePath` (carte) disparaît alors que `CardData.fromJson` le lit toujours.
2. Un formulaire de création laissé vide écrit une carte, une relique et un ennemi **sans clé
   `sfx`** — le test qui aurait attrapé l'échec d'`audio_catalogue_test`.

**Étape B**
3. `EditorDocument` : `setAt` / `valueAt` sur un chemin imbriqué ; `addElement` clone l'élément
   modèle ; `toMechanics` retire une chaîne optionnelle vide et garde une clé requise.
4. `inferFieldKind` : une ligne de la table du §4.3 par cas, dont la priorité 4 sur 10 (`rarity`
   est une chaîne, mais une énumération d'abord).
5. Une saisie `1a` dans un champ entier produit une faute, **ne modifie pas le document**, et
   « Écrire » n'écrit rien.
6. Modifier une relique portant une clé inconnue du gabarit : la clé a son champ, et survit à
   « Écrire ».
7. Brut → formulaire avec un texte invalide : la vue reste brute, la faute s'affiche, le texte est
   intact.
8. `effects[].type : "skill"` est refusé ; `"damage"`, employé par un fichier, passe ; la valeur
   du gabarit passe dans une arborescence vide.
9. `intents[].type : "fly"` est refusé (énumération imbriquée).

**Étape C**
10. Choisir « aucun » pour `sfx` écrit l'entité sans la clé.
11. Importer un son (sélecteur factice) copie le fichier, déclare le son dans `audio.json` sans
    toucher aux autres lignes du fichier, et écrit `sfx`.
12. Un import de son dont l'identifiant existe déjà est refusé, rien n'est écrit.
13. Une écriture qui échoue après l'import défait tout : copie supprimée, `audio.json` d'origine,
    image écrasée restaurée depuis sa sauvegarde, aucune sauvegarde laissée.
14. Importer une image d'ennemi remplace `sprite.png` ; `spritePath` reste celui que l'écrivain
    calcule.

---

## 7. Hors périmètre

- **La musique et les moments d'`audio.json`** — seul `sounds` est touché.
- **Régler `volume` et `variants`** d'un son importé.
- **Supprimer ou renommer une ressource**, et nettoyer les sons orphelins — un son remplacé reste
  sur le disque. Décision tenue depuis le lot 2 : l'outil ne supprime rien.
- **Redimensionner ou recadrer** une image importée.
- **Écouter un son** depuis l'éditeur.
- **Une illustration de carte** — `CardData.spritePath` est gardé pour elle (D2) ; son champ
  d'import viendra avec l'écran qui l'affichera.
- **La validation bilingue des textes imbriqués** (`choices[].text_fr`) — inchangée.
- **Les fichiers de test `gambler` et `gremlin`** portent les défauts du §1 (`"sfx": ""`,
  `"type": "skill"`) : ils restent à corriger ou supprimer par leur auteur.

---

## 8. Risques

| Risque | Parade |
|:---|:---|
| Le formulaire récursif réécrit la moitié de l'écran et de ses tests widget | `EditorDocument` et `inferFieldKind` sont du Dart pur, testés unitairement avant le moindre widget |
| L'insertion textuelle dans `audio.json` casse sur une mise en forme imprévue | Contrôle décodé avant / après (§5.2) : un résultat inattendu lève et se défait, il ne s'écrit jamais |
| Un vocabulaire refuse un type légitime que seul le code connaît encore | Assumé (§4.5) : le premier fichier d'un type nouveau s'écrit à la main, avec le code qui l'exécute |
| Une liste vide sans élément modèle n'offre pas de formulaire | Ligne 14 : un champ JSON pour la clé seule, jamais un blocage |
| `file_picker` est une dépendance de plus pour du debug | Code élagué en release ; coût résiduel : le lock et la page de licences |
| Écraser une image livrée par erreur | Import explicite, image actuelle affichée à côté ; rollback en cas d'échec. Un import réussi se défait par git |
