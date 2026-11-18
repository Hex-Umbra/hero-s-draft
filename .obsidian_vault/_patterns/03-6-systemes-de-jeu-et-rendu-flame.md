### 3.6. Systèmes de Jeu et Rendu Flame (`lib/game/systems/`)

Afin de décomposer la classe monolithique de rendu `HerosDraftGame`, ses tâches de synchronisation et de gestion d'animations/visuels de combat ont été isolées dans des composants de systèmes autonomes enregistrés auprès de Flame :

- **`StateSyncSystem`** (`state_sync_system.dart`) :
  - Composant gérant la réception et l'application synchrone séquentielle des états Riverpod (`RunState`, `DeckState`, `CombatState`) sur le thread Flame.
  - Évite les collisions d'états graphiques en sérialisant l'application des données Riverpod pendant les phases critiques d'animations ou de transitions.
- **`CardAnimationSystem`** (`card_animation_system.dart`) :
  - Gère les animations physiques et graphiques des cartes en main (effets visuels de zoom, d'inclinaison dynamique/tilt au drag, de translation de pioche, de tremblements de mana insuffisant).
  - Centralise l'état visuel du survol (`hover`) et de focalisation.
- **`CombatVisualSystem`** (`combat_visual_system.dart`) :
  - Gère le tracé des effets graphiques de combat, notamment la ligne de ciblage Bézier quadratique réactive et texturée (`TargetingLine`).
  - Gère l'apparition d'effets visuels lors des résolutions de dégâts ou d'utilisation de compétences (flashes sprite, explosions de particules Canvas, dômes de bouclier).
  - **`playFireWave(FireWaveReport)`** (vague 7, fusionnée dans `main` le 2026-11-18 — [ADR-117](../_adr/ADR-117-les-charges-elementaires.md)) : anime une vague de la chaîne du Feu à partir du seul compte rendu de l'état — éclair sur chaque porteur résolu, boule de feu vers chaque voisin, retenu jusqu'à l'impact ; appelé par `StateSyncSystem` quand `CombatState.fireWaveReport` change, avant que `HerosDraftGame` demande la vague suivante ([`_patterns/05-8`](05-8-rendu-vectoriel-direct-sur-canvas-auras-senso.md) §4).
- **`LayoutSystem`** (`layout_system.dart`) :
  - Calcule dynamiquement l'agencement géométrique des cartes dans la main du joueur en arc de cercle (`layoutHand`).
  - Gère le repositionnement automatique et adaptatif des ennemis actifs sur le board (`repositionEnemies`) selon leur nombre (de 1 à 5).
