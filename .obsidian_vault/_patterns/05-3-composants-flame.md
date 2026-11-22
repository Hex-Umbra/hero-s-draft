### 5.3. Composants Flame (`lib/game/components/`)

| Composant | Héritage | Rôle | Priorité Z |
|:---|:---|:---|:---|
| `CardComponent` | `PositionComponent` + `DragCallbacks` — le survol est décidé par `HerosDraftGame.refreshHover` et `pickHoveredCard` (`hand_geometry.dart`), arbitre géométrique unique ([ADR-119](../_adr/ADR-119-les-corrections-de-fin-de-vague-8.md)) | Carte en main : façade déléguant son rendu à `CardRenderer` et ses gestes à `CardInteractionHandler` | base=10+index, hover=100, focused=150, dragging=500 |
| `TargetingLine` | `PositionComponent` | Arc de ciblage : gradient vert→rouge, pattern pointillé animé, cercles pulsants sur cibles valides | 300 |
| `EnemyCard` | `CombatEntity` + `TapCallbacks` | Entité ennemie : sprite, `EnemyHealthBar`, deux `StatusTabs`, bordure (fiche ouverte, puis sélection, puis surbrillance) ; tient le plein du voile d'armure et l'agrandissement de sa fiche (`baseScale`, `place`, `animateInspection`) ; hérite des animations de combat communes | 0 ; survolée 5, fiche ouverte 190 |
| `HeroCard` | `CombatEntity` + `TapCallbacks` | Entité héros : portrait et bordure, deux `StatusTabs` ; **ni barre, ni badge** — la jauge du héros est le widget Flutter `PlayerHealthBar`, son détail le `StatusEffectsPanel` (B38) | 0 ; survolée 5 |
| `EnemyHealthBar` | `PositionComponent` + `TapCallbacks` | Barre de PV d'un ennemi, à la largeur de sa carte (y −17 à −4 en unités de la carte) : « PV/PV max », l'armure en cyan à côté, le voile `LinearProgressBarComponent` que lit `ArmorVeil` ; renvoie ses appuis au `onTapDown` de sa carte | enfant |
| `StatusTabs` | `PositionComponent` + `TapCallbacks` | Languette des bonus (gauche) ou des altérations et charges (droite), ennemi comme héros, lue sur `StatusReadout` : au repos l'icône et sa valeur, au survol de la carte le nom, la valeur et la durée, vers l'intérieur au bord de l'écran (`unfoldsInward`, B39) ; renvoie ses appuis à sa carte | 6 (enfant) |
| `InspectionVeil` | `RectangleComponent` | Voile noir à 55 % sur toute la scène Flame quand une fiche est ouverte ; le HUD Flutter reste net (B36) | 180 |
| `FloatingText` | `PositionComponent` | Texte flottant de dégâts/soins : `MoveEffect` ascendant + `OpacityEffect` fade, auto-suppression ~1.5s | — |
| `SlashEffect` | `BaseVisualEffect` | Effet visuel d'entaille à l'impact physique, durée et suppression automatique | — |

> [!IMPORTANT]
> **Une zone par carte de combat** (P-05 vague 1, sur la branche
> `feat/v0.6.1-interface-des-ennemis` — [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)).
> `CombatEntity.zone` — le rectangle continu de la barre au bas de la carte, plus chaque languette
> par son rectangle dessiné **et** son rectangle au repos — est la seule règle que lisent le survol
> (`pickHoveredEntity`, `HerosDraftGame.refreshEntityHover`), l'appui (`_livingEnemyAt`) et le
> lâcher d'une carte (`findHoveredEnemy`). La barre et les languettes renvoient leur appui à leur
> carte : une languette déroulée sur la voisine ne joue jamais la carte sur la voisine. Les textes
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
