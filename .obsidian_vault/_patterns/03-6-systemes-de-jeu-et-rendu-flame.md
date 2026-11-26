### 3.6. Systèmes de Jeu et Rendu Flame (`lib/game/systems/`)

Afin de décomposer la classe monolithique de rendu `HerosDraftGame`, ses tâches de synchronisation et de gestion d'animations/visuels de combat ont été isolées dans des composants de systèmes autonomes enregistrés auprès de Flame :

- **`StateSyncSystem`** (`state_sync_system.dart`) :
  - Composant gérant la réception et l'application synchrone séquentielle des états Riverpod (`RunState`, `DeckState`, `CombatState`) sur le thread Flame.
  - Évite les collisions d'états graphiques en sérialisant l'application des données Riverpod pendant les phases critiques d'animations ou de transitions.
- **`CardAnimationSystem`** (`card_animation_system.dart`) :
  - Gère les animations physiques et graphiques des cartes en main (effets visuels de zoom, d'inclinaison dynamique/tilt au drag, de translation de pioche, de tremblements de mana insuffisant).
  - Centralise l'état visuel du survol (`hover`) et de focalisation : au survol, seule la `ScaleEffect` est retirée puis remise (`_scaleForHover`, `cardHoverScale` = 1,2). Quelle carte est survolée, c'est l'arbitre `HerosDraftGame.refreshHover` qui le décide ([ADR-119](../_adr/ADR-119-les-corrections-de-fin-de-vague-8.md)).
- **`CombatVisualSystem`** (`combat_visual_system.dart`) :
  - Gère le tracé des effets graphiques de combat, notamment la ligne de ciblage Bézier quadratique réactive et texturée (`TargetingLine`).
  - Gère l'apparition d'effets visuels lors des résolutions de dégâts ou d'utilisation de compétences (flashes sprite, explosions de particules Canvas, dômes de bouclier).
  - **`playFireWave(FireWaveReport)`** (vague 7, fusionnée dans `main` le 2026-11-18 — [ADR-117](../_adr/ADR-117-les-charges-elementaires.md)) : anime une vague de la chaîne du Feu à partir du seul compte rendu de l'état — éclair sur chaque porteur résolu, boule de feu vers chaque voisin, retenu jusqu'à l'impact ; appelé par `StateSyncSystem` quand `CombatState.fireWaveReport` change, avant que `HerosDraftGame` demande la vague suivante ([`_patterns/05-8`](05-8-rendu-vectoriel-direct-sur-canvas-auras-senso.md) §4).
- **`LayoutSystem`** (`layout_system.dart`) :
  - Calcule dynamiquement l'agencement géométrique des cartes dans la main du joueur en arc de cercle (`layoutHand`).
  - Gère le repositionnement automatique et adaptatif des ennemis actifs sur le board (`repositionEnemies`) selon leur nombre (de 1 à 5). Vague 1 du bestiaire : il est le **seul écrivain de la position d'un ennemi**, par `EnemyCard.place` (un écart relatif, descente de la fiche comprise), et relit le survol des cartes de combat après chaque replacement, le pointeur pouvant rester immobile. **Vague 2** (fusionnée dans `main` par la PR #62 — [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md)) : il ne calcule plus rien, il appelle `placeRow` (`enemy_row.dart`) avec les places des cadres, le palier `boardScale.frame` et le rapport de pixels, et `rowCenterYFor` ; plus de `scaleMultiplier` ni de largeur par ennemi.

**Les règles pures d'affichage du combat** (vague 1 du bestiaire, sur la branche —
[ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)) vivent à côté de ces systèmes,
sans composant ni écran, testées seules : `ArmorVeil` (`armor_veil.dart`, le plein et la part du
voile d'armure), `StatusReadout` et `statusEmoji` (`status_readout.dart`, ce qu'une entrée de statut
ou de charge écrit et de quel côté, lu par Flame et par la fiche Flutter), `pickHoveredEntity`,
`enemyBodyRect` et `unfoldsInward` (`entity_hover.dart`, l'arbitre du survol des cartes de combat,
sur le modèle de `pickHoveredCard` dans `hand_geometry.dart`).

**Les règles pures de la vague 2** (fusionnée dans `main` par la PR #62 — [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md)), sans composant ni écran, testées seules : `boardScaleFor` et `BoardScale` (`board_scale.dart`, la taille du pixel de cadre qui suit celle du héros, B90 et B91, et si elle tombe juste), `placeRow`, `slotOf`, `rowCenterYFor` et `inspectionShift` (`enemy_row.dart`, la rangée, ses centres sur des pixels physiques, le décalage vers l'intérieur d'une carte ouverte au bord), `creatureFitOf` (`creature_fit.dart`, le recadrage d'un ancien sprite par la taille de son image), `decorFitFor` (`decor_fit.dart`, le décor de 640 × 360 qui couvre l'écran), `pickWindowBackground` (`window_background.dart`) et `enemyZoneRect` (`entity_hover.dart`, qui remplace `enemyBodyRect`), avec `inDrawOrder` et `topmostWhere` (la carte dessinée par-dessus reçoit survol, appui et lâcher quand deux languettes se superposent, B91). `HerosDraftGame` pose le décor de combat (`_placeDecor`) et recalcule `boardScale` à chaque `onGameResize`.
