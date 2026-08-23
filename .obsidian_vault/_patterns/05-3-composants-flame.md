### 5.3. Composants Flame (`lib/game/components/`)

| Composant | Héritage | Rôle | Priorité Z |
|:---|:---|:---|:---|
| `CardComponent` | `PositionComponent` + `DragCallbacks` + `HoverCallbacks` | Carte en main : façade déléguant son rendu à `CardRenderer` et ses gestes à `CardInteractionHandler` | base=10+index, hover=100, focused=150, dragging=500 |
| `TargetingLine` | `PositionComponent` | Arc de ciblage : gradient vert→rouge, pattern pointillé animé, cercles pulsants sur cibles valides | 300 |
| `EnemyCard` | `CombatEntity` + `TapCallbacks` | Entité ennemie : barre de vie, badges stats, indicateur d'intention, bordure pulsante si ciblé, hérite des animations de combat communes | 20 |
| `HeroCard` | `CombatEntity` | Entité héros : portrait, `HealthBar`, `StatBadge` (armure/mana), icônes de statuts, hérite des animations de combat communes | 10 |
| `FloatingText` | `PositionComponent` | Texte flottant de dégâts/soins : `MoveEffect` ascendant + `OpacityEffect` fade, auto-suppression ~1.5s | — |
| `HealthBar` | `PositionComponent` | Barre HP horizontale : interpolation green→yellow→red, transition animée | — |
| `StatBadge` | `PositionComponent` | Badge vectoriel custom : icône bouclier/cristal, valeur numérique, pulse de scale au changement | — |
| `SlashEffect` | `BaseVisualEffect` | Effet visuel d'entaille à l'impact physique, durée et suppression automatique | — |

**Décomposition de `CardComponent`** :
Afin de nettoyer la classe `CardComponent` de ses centaines de lignes de dessin 2D et de gestion bas niveau des gestes, elle a été divisée en trois responsabilités :
- **`CardComponent`** (`lib/game/components/card_component.dart`) :
  - Classe façade principale qui coordonne les initialisations et les interactions de haut niveau (callbacks de jeu, effets de shake).
- **`CardRenderer`** (`lib/game/components/widgets/card_renderer.dart`) :
  - Encapsule tout le dessin 2D de la face avant de la carte (fond avec coins arrondis, dégradés selon le type de carte, liseré et halo de rareté de carte, effet foil polychromatique rotatif pour la rareté `unique`, et dessin des fentes de runes de forge avec wrapping Canvas).
  - Délègue le dessin des textes à `CardTextRenderer`.
- **`CardInteractionHandler`** (`lib/game/components/widgets/card_interaction_handler.dart`) :
  - Centralise la gestion des gestes du pointeur : détection du survol (`hover`), calcul du glissement (`drag`), détection d'entrée dans la zone d'annulation (`cancel zone`) et détection de survol d'un ennemi pour ciblage.
