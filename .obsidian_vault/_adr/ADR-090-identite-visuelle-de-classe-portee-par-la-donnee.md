### Statut

✅ **Livré le 2026-09-09**, suite « création guidée » de l'éditeur de contenu, branche
`feat/menu-debug-lot-2` ; **achevé le 2026-09-14** (commit `ce60b39`), quand les deux derniers écrans
codés en dur ont été rebranchés sur la donnée (D14 ci-dessous). Prolonge
[ADR-003](ADR-003-architecture-100-data-driven.md).

### Contexte

L'éditeur sait créer une classe entière. Mais la couleur et l'icône d'une classe ne vivaient pas
dans sa donnée : `stats_dialog.dart` les choisissait en six lignes de `if` sur l'identifiant. Une
classe créée par l'outil aurait donc été affichée en bleu par défaut, et son identité aurait exigé
du code — le contraire du contrat data-driven.

Par ailleurs, le champ `iconPath` de `class.json` désignait une image de 1696 × 2528 employée comme
**carte de classe** en combat : le nom mentait.

### Décision

**D13 — `iconPath` devient `classCard`**, et le fichier image prend le nom de la classe
(`classes/<id>/<id>.png`). `iconPath` renaît **optionnel**, réservé à une vraie icône.

**D1 — `themeColor` entre dans `class.json`**, chaîne `#RRGGBB` lue en `int?` (`null` si absente ou
malformée). Aucun fichier n'est obligé de la porter ; les trois classes la reçoivent avec les
couleurs affichées jusque-là, pour que la migration ne change rien à l'écran. Le champ a deux
lecteurs : le dialogue de stats et l'arbre de l'éditeur.

**D2 — L'icône vient d'une image, jamais d'un `iconName` mappé vers un `IconData`.** Un `IconData`
construit dynamiquement casse `--tree-shake-icons` en release : la table de correspondance serait
le codage en dur déplacé d'un cran.

**Replis** — couleur absente → bleu ; `iconPath` absent ou illisible → `classCard` recadrée ; image
illisible → disque à la couleur de classe. Le décodage est borné (`cacheWidth`) : la carte pleine
taille coûtait environ 17 Mo par ouverture.

**D9 — Le magenta signale l'inachevé** : le gabarit d'une classe neuve porte `themeColor: "#FF00FF"`,
et l'éditeur n'écrit `iconPath` et l'icône placeholder qu'**à la création**, jamais en modification
— sinon les classes livrées afficheraient un carré magenta.

**D14 — Aucun écran ne compare `hero.id` à un nom de classe** (2026-09-14). La couleur, l'image et
le dégradé passent par un seul point, `ClassIdentity` (`lib/ui/widgets/class_identity.dart`),
avec `ClassAvatar` déplacé du dialogue de stats vers ce fichier partagé. Le bouton « Sélectionner »
reconnaissait le paladin en comparant sa couleur à `Colors.blue` pour lui réserver un dégradé : le
dégradé se **dérive** désormais de la couleur (même teinte, du sombre vers le clair), pour toutes
les classes — ce qui change l'apparence des trois boutons existants.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Modèle | `lib/models/data/hero_data.dart` — `classCard`, `iconPath?`, `themeColor?` |
| Données | `assets/data/classes/<id>/class.json` (`classCard`, `themeColor`), image `<id>.png` |
| Point unique | `lib/ui/widgets/class_identity.dart` — `ClassIdentity.colorOf`/`imageOf`/`gradientOf`, `ClassAvatar` |
| Lecteurs | `stats_dialog.dart`, `class_selection_screen.dart`, `starter_deck_draft_screen.dart`, arbre de `content_editor_screen.dart` |
| Carte de classe en combat | `lib/game/systems/state_sync_system.dart`, `lib/models/data/game_data_registry.dart` |
| Tests | `test/unit/hero_data_identity_test.dart`, `test/widget/class_identity_test.dart`, `test/widget/class_selection_screen_test.dart` (classe inconnue du code, `id` connu sans couleur), `test/widget/starter_deck_draft_screen_test.dart`, `test/unit/asset_path_convention_test.dart` |

### Conséquences

- **Invariant vérifié le 2026-09-14** : `grep -rn "== 'paladin'\|== 'berserker'\|== 'mage'" lib` ne
  rend rien. Une classe créée par l'éditeur s'affiche partout dans sa couleur et avec son image.
- La sélection de classe montre la **carte de classe recadrée** là où elle montrait une icône
  Material, et le dégradé des boutons change pour les trois classes livrées.
- Trois vraies icônes de classe restent à dessiner (spec §10) ; d'ici là, le repli montre la carte.
- Spec : `docs/superpowers/specs/2026-09-08-editeur-de-contenu-creation-guidee-design.md` §3.
