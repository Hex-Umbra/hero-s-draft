### 5.3. Composants Flame (`lib/game/components/`)

| Composant | Héritage | Rôle | Priorité Z |
|:---|:---|:---|:---|
| `CardComponent` | `PositionComponent` + `DragCallbacks` — le survol est décidé par `HerosDraftGame.refreshHover` et `pickHoveredCard` (`hand_geometry.dart`), arbitre géométrique unique ([ADR-119](../_adr/ADR-119-les-corrections-de-fin-de-vague-8.md)) | Carte en main : façade déléguant son rendu à `CardRenderer` et ses gestes à `CardInteractionHandler` | base=10+index, hover=100, focused=150, dragging=500 |
| `TargetingLine` | `PositionComponent` | Arc de ciblage : gradient vert→rouge, pattern pointillé animé, cercles pulsants sur cibles valides | 300 |
| `EnemyCard` | `CombatEntity` + `TapCallbacks` | Entité ennemie **composée en calques** (vague 2, [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md)) : fond de fenêtre (0), créature (1), cadre du tier (2), `TargetOutline` (3), puis gangue, halo, deux `StatusTabs` et `EnemyHealthBar` ; sa taille est le canevas de son tier, son échelle de repos le palier du plateau (`game.boardScale.frame`), doublé quand sa fiche est ouverte (`baseScale`, `place`, `animateInspection`) ; contour (fiche ouverte, puis sélection, puis surbrillance) ; tient le plein du voile d'armure ; hérite des animations de combat communes | 0 ; survolée 5, fiche ouverte 190 |
| `HeroCard` | `CombatEntity` + `TapCallbacks` | Entité héros : portrait et bordure, deux `StatusTabs` ; **ni barre, ni badge** — la jauge du héros est le widget Flutter `PlayerHealthBar`, son détail le `StatusEffectsPanel` (B38) | 0 ; survolée 5 |
| `EnemyHealthBar` | `PositionComponent` | Barre de PV d'un ennemi, à la largeur du **gabarit** de 88 × 120 (`anchorRect`), au-dessus de lui : « PV/PV max », l'armure en cyan à côté, le voile `LinearProgressBarComponent` que lit `ArmorVeil` ; ne reçoit aucun appui, la zone de la carte les prend | enfant |
| `StatusTabs` | `PositionComponent` | Languette des bonus (gauche) ou des altérations et charges (droite), ennemi comme héros, posée contre `anchorLocalRect` de sa carte (le gabarit pour un ennemi) et lue sur `StatusReadout` : au repos l'icône et sa valeur, au survol de la carte le nom, la valeur et la durée, vers l'intérieur au bord de l'écran (`unfoldsInward`, B39) ; ne reçoit aucun appui | 6 (enfant) |
| `TargetOutline` | `PositionComponent` | Contour de ciblage d'un ennemi, à l'extérieur de sa **fenêtre**, avec la lueur cyan pulsante de la surbrillance ; au repos, rien ; sa carte lui dit couleur et trait (cyan cible possible, ambre carte choisie ou fiche ouverte). Remplace la bordure `RectangleComponent` de l'ennemi, que le héros garde ([ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md)) | 3 (enfant) |
| `InspectionVeil` | `RectangleComponent` | Voile noir à 55 % sur toute la scène Flame quand une fiche est ouverte ; le HUD Flutter reste net (B36) | 180 |
| `FloatingText` | `PositionComponent` | Texte flottant de dégâts/soins : `MoveEffect` ascendant + `OpacityEffect` fade, auto-suppression ~1.5s | — |
| `SlashEffect` | `BaseVisualEffect` | Effet visuel d'entaille à l'impact physique, durée et suppression automatique | — |

> [!IMPORTANT]
> **Une zone par carte de combat** (P-05 vague 1, [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md), amendée par la vague 2,
> [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md), fusionnée dans `main` par la PR #62).
> `CombatEntity.zone` — pour un ennemi `enemyZoneRect`, du haut de la barre au bas du canevas sur toute sa largeur, coins compris, plus chaque languette
> par son rectangle dessiné **et** son rectangle au repos — est la seule règle que lisent le survol
> (`pickHoveredEntity`, `HerosDraftGame.refreshEntityHover`), l'appui (`_livingEnemyAt`) et le
> lâcher d'une carte (`findHoveredEnemy`). **Depuis la vague 2, cette zone est aussi le test d'appui de la carte** (`containsLocalPoint`) : la barre et les languettes ne renvoient plus rien à leur carte, et une languette déroulée sur la voisine ne joue jamais la carte sur la voisine. Les textes
> des languettes se lisent par `CombatEntity.l10n` (`lookupAppLocalizations` sur `activeLocale`).
> `StatBadge`, `StatusIndicator`, `CircleProgressComponent` et l'appui long sur la jauge ont
> disparu ; `lib/game/components/entities/health_bar.dart` (`HealthBarComponent`) n'a aucun lecteur.

**Décomposition de `CardComponent`** :
Afin de nettoyer la classe `CardComponent` de ses centaines de lignes de dessin 2D et de gestion bas niveau des gestes, elle a été divisée en trois responsabilités :
- **`CardComponent`** (`lib/game/components/card_component.dart`) :
  - Classe façade principale qui coordonne les initialisations et les interactions de haut niveau (callbacks de jeu, effets de shake).
- **`CardRenderer`** (`lib/game/components/widgets/card_renderer.dart`) :
  - Encapsule tout le dessin 2D de la face avant de la carte (fond avec coins arrondis, dégradés selon le type de carte, liseré et halo de rareté de carte, et dessin des fentes de runes de forge avec wrapping Canvas).
  - Délègue le dessin des textes à `CardTextRenderer`.
- **`CardInteractionHandler`** (`lib/game/components/widgets/card_interaction_handler.dart`) :
  - Centralise la gestion des gestes du pointeur : calcul du glissement (`drag`) — dont le début fait oublier le pointeur au survol (`forgetPointer`) —, détection d'entrée dans la zone d'annulation (`cancel zone`) et détection de survol d'un ennemi pour ciblage.
