## 19.5. Éditeur de Contenu — Interface : Formulaire Inféré et Habillage « Éditeur »

> [!IMPORTANT]
> **L'écran est une vue du moteur, jamais une seconde règle.** Le formulaire ne fait que produire le
> texte JSON que `EntityValidator` juge ([`_patterns/19-00`](19-00-editeur-de-contenu-seam-disque-validation-ecriture.md)) :
> [ADR-092](../_adr/ADR-092-formulaire-infere-du-document-et-ressources-liees.md). Toute couleur y
> est un jeton nommé, et tout sélectionnable suit le **contrat de choix** :
> [ADR-093](../_adr/ADR-093-habillage-editeur-jetons-nommes-et-contrat-de-choix.md).

`ContentEditorScreen` (`lib/ui/screens/content_editor_screen.dart`, 1165 lignes, **vérifié le
2026-09-15** par `wc -l`) tient tout l'état ; les widgets de `lib/ui/widgets/content_editor/` sont
présentationnels. Libellés en français écrits en dur, sans ARB, comme le tiroir de debug.

### 19.5.1. La composition

```
ScreenScaffold
├── EditorAppBar            titre, badge DEBUG, dépôt réduit à ses deux derniers dossiers
├── EditorToolbar           7 onglets de type │ EditorSegmented Créer / Modifier, dès qu'un type est choisi
└── _editing                LayoutBuilder
    ├── EntityExplorer      240 px, mode Modifier seulement
    ├── EntityForm          en-tête de fichier, puis sections — défile
    │   EditorActionBar     bandeau d'issue + Charger / Valider / Écrire — fixe
    └── ReferencePanel      300 px, quand la zone de travail atteint 1100 px
```

Les niveaux Type et Action tiennent sur une ligne, qui passe à la ligne quand la largeur manque.
Retaper le type ou le mode courant ne change rien : ni l'identifiant ni la saisie ne se vident.

### 19.5.2. Le formulaire inféré du document

| Élément | Emplacement | Règle |
|:---|:---|:---|
| État | `EditorDocument` (moteur) | Un `Map` adressé par chemin ; le formulaire et la vue « JSON brut » en sont deux vues. Un brut qui ne décode pas en objet reste brut, la raison au canal des fautes |
| Choix du widget | `inferFieldKind` (moteur) | 14 `FieldKind`, première règle qui s'applique : métadonnées du descripteur d'abord, type JSON ensuite, un petit champ JSON pour la seule clé en dernier recours |
| Rendu | `document_form.dart`, `form_blocks.dart` | Récursif, dans l'ordre du document ; **aucune clé du fichier n'est perdue**. Au moins deux nombres consécutifs → `NumberGrid` (trois colonnes au plus) ; liste d'objets → sous-panneaux numérotés `ElementCard`, résumé et corbeille, `AddElementButton` en pointillés ; options de `rarity` aux couleurs de rareté du jeu |
| Ressource | `asset_field.dart` | Son : « aucun », les sons d'`audio.json`, « Importer… ». Image : aperçu `Image.memory` sur `readBytes` — `Image.file` ferait entrer `dart:io` dans `lib/ui/`, que le build web refuse —, « Importer… », « aucune » pour une image optionnelle |
| Couleur | `color_field.dart` | Roue `flutter_colorpicker`, sans alpha ; le hex est en lecture seule |

Création et modification partagent ce formulaire. Les pastilles de propriétaire et les cartes de
signature restent propres à la création.

### 19.5.3. Le formulaire habillé

- **En-tête de fichier** : tuile à l'icône du type (`kCategoryIcons`), teintée par la couleur du
  propriétaire ou `themeColor` ; titre `Créer · Classe` ; chemin visé ; état `EntityFileStatus` —
  `Nouveau fichier`, `Relu du disque`, `Non chargé` (qu'« Écrire » refusera).
- **Sections** `EditorPanel` : Identité, Textes, Mécanique (bascule Formulaire / JSON brut dans
  son en-tête), Ressources, Cartes de signature.
- **Rangée de propriété** `PropertyRow` : clé JSON réelle en chasse fixe (`editorMono`), point bleu
  si obligatoire ; la clé passe au-dessus du contrôle sous 240 px de contrôle. Textes FR et EN côte
  à côte.

### 19.5.4. Les fautes et la barre d'actions

`EditorActionBar` reste visible quel que soit le défilement ; `OutcomeBanner` y dit l'issue du
dernier geste — rouge pour une faute ou un échec, vert pour une écriture, ambre pour le redémarrage
à chaud. Une faute qui nomme son champ (`ValidationFault.field`) borde ce champ de rouge avec son
message, et sa ligne du bandeau y ramène : `FieldAnchors` tient une `GlobalKey` par champ, posée par
le widget qui le rend, et `reveal` fait défiler jusqu'à lui.

**Une carte de signature n'a pas de rangée à elle** : l'écran (`_judge`) re-étiquette ses fautes
`carte N : …` et les fait viser `skills`, l'ancre du panneau des cartes de signature. Une faute
d'import de la classe n'y est pas répétée par carte — le brouillon de la classe la rapporte déjà.

### 19.5.5. Les jetons et le contrat de choix

| Élément | Emplacement | Règle |
|:---|:---|:---|
| Jetons | `editor_style.dart` — `EditorColors` | D'`AppColors` quand le jeu porte la couleur ; pas de littéral `Color(0x…)` dans un widget — convention de revue, sans test, `kNeutralOwnerColor` restant l'exception antérieure |
| Coque du contrat | `choice_surface.dart` — `ChoiceSurface` | `Semantics(selected:)`, fond **opaque** de clé `editeur-bouton-fond`, `Material` transparent, `InkWell` |
| Usagers | `ChoiceButton`, `EditorSegmented`, onglet de `EditorToolbar`, entité d'`EntityExplorer` | Chacun garde son indice hors couleur : coche, anneau, soulignement |
| Lisibilité | `readableOn(fill)` dans `color_field.dart` | Texte noir ou blanc selon la luminance WCAG, pour une teinte d'identité |
| Bouton d'action | `editor_button.dart` — `EditorButton` | Hors contrat : le geste principal est le seul bouton plein |

> [!NOTE]
> **Sans le `Material` transparent de la coque**, l'encre du survol et du focus peint sur celui du
> `Scaffold`, sous le fond opaque : elle n'est jamais visible (commit `2c9ba6d`). Un élément
> cliquable posé sur un fond opaque hors de la coque doit poser le sien.

L'explorateur groupe les entités par propriétaire — neutres d'abord, puis chaque classe par ordre
alphabétique, pastille de couleur et compteur — et un filtre les réduit (sous-chaîne, sans casse).

### 19.5.6. Tests de l'interface

| Emplacement | Couvre |
|:---|:---|
| `test/widget/content_editor_screen_test.dart` | Parcours complet, Valider = Écrire, imports, faute de conversion, faute qui ramène à son champ ou vise le panneau des cartes de signature, lisibilité |
| `test/widget/content_editor/` (11 fichiers + `contrast.dart`, **vérifié le 2026-09-15**) | Chaque widget ; `choice_surface_test.dart` pose un test d'encre par usager |
| `test/widget/content_editor/contrast.dart` | `expectReadableChoice` : fond opaque et 4,5:1, par la luminance du framework, jamais par `readableOn` |
