### Statut

✅ **Livré le 2026-09-15**, habillage « éditeur » de l'éditeur de contenu (P-30), branche
`feat/menu-debug-lot-2` — commits `80233ba` à `2c9ba6d`. **Présentation seule** : aucune règle
d'[ADR-089](ADR-089-editeur-de-contenu-seam-disque-et-validation-totale.md) ni
d'[ADR-092](ADR-092-formulaire-infere-du-document-et-ressources-liees.md) ne change,
`lib/services/` n'est pas touché. Maquette HTML validée par le propriétaire « à 100 % », explorateur
vertical compris, le 2026-09-15.

### Contexte

Le formulaire était une pile de `TextField` Material à soulignement et de rangées de boutons : il
se lisait comme un brouillon. Les niveaux Type et Action occupaient deux rangées, la liste des
entités grandissait avec le contenu, « Valider » et « Écrire » sortaient de l'écran dès que le
formulaire défilait, et une faute ne disait pas quel champ elle visait.

Recomposer l'écran multipliait les éléments sélectionnables (onglet de type, segment
Créer / Modifier, puce, entité de l'explorateur) et les teintes. Le correctif de lisibilité
antérieur (commit `9b3ce82`) avait montré le risque : un libellé posé sur une teinte d'identité
passait sous le seuil WCAG sans que rien ne le signale.

### Décision

**D1 — Toute couleur de l'éditeur est une constante nommée**, d'`AppColors` quand le jeu la porte,
d'`EditorColors` sinon (`lib/ui/widgets/content_editor/editor_style.dart`). Un widget ne peint pas
de littéral `Color(0x…)` : une teinte nouvelle entre d'abord dans la table, avec son rôle en
commentaire (commit `81ddbe2`). Les transparences restent dérivées d'un jeton (`withValues`).

**D2 — Tout sélectionnable suit un seul contrat de choix**, porté par une coque commune,
`ChoiceSurface` :

| Clause | Exigence |
|:---|:---|
| (a) Fond | un `Container` **opaque** de clé `editeur-bouton-fond` porte le libellé |
| (b) Contraste | texte et icônes à **4,5:1** au moins sur ce fond |
| (c) Sémantique | `Semantics(selected: …)` |
| (d) Indice hors couleur | coche (puce, entité), soulignement (onglet), anneau (segment) |

La coque pose aussi un `Material` transparent entre le fond et l'`InkWell` : sans lui, l'encre du
survol et du focus peignait sur le `Scaffold`, **sous** le fond opaque, donc jamais visible
(commit `2c9ba6d`).

**D3 — Les tests suivent la structure, pas l'inverse.** Libellés visibles et clés `editeur-*` sont
conservés ; un test ne change que là où la structure qu'il observait disparaît, et garde alors
l'intention qu'il protégeait.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Jetons | `lib/ui/widgets/content_editor/editor_style.dart` — `EditorColors`, `editorMono`, `editorInputDecoration` |
| Coque du contrat | `lib/ui/widgets/content_editor/choice_surface.dart` |
| Ses quatre usagers | `choice_button.dart`, `editor_segmented.dart`, `editor_toolbar.dart` (`_TypeTab`), `entity_explorer.dart` (`_ExplorerItem`) |
| Contraste mesuré | `test/widget/content_editor/contrast.dart` — `expectReadableChoice` (fond opaque, 4,5:1), luminance du framework, jamais `readableOn` |
| Encre visible | `test/widget/content_editor/choice_surface_test.dart` — un test par usager |

### Conséquences

- **D1 n'est gardé par aucun test** : c'est une convention de revue. Relevé le 2026-09-15 : un seul
  littéral subsiste hors de la table, `kNeutralOwnerColor` (`choice_button.dart`), antérieur à
  l'habillage.
- **La table compte 33 jetons, dont 18 à un seul emploi** (mesuré le 2026-09-15), certains presque
  identiques à un jeton voisin : consolidation différée, voir `docs/ROADMAP.md` §P-30.
- Le contrat couvre les sélectionnables, pas les champs de saisie : leurs libellés, frères du champ
  plutôt que parents, ne donnent plus de nom accessible au champ — différé, même renvoi.
- L'arbre à boutons de la création guidée (`tree_level.dart`) est supprimé ; la mention « arbre de
  l'éditeur » d'[ADR-090](ADR-090-identite-visuelle-de-classe-portee-par-la-donnee.md) est historique.
- Spec : `docs/superpowers/specs/2026-09-15-editeur-de-contenu-habillage-editeur-design.md` (D1-D11,
  écarts assumés) ; plan : `docs/superpowers/plans/2026-09-15-editeur-de-contenu-habillage-editeur.md`.
