### 5.4. Constantes de Z-Indexing (`GameConstants`)

**Vérifié le 2026-11-22** sur la branche `feat/v0.6.1-interface-des-ennemis`
(`lib/game/game_constants.dart`). Il n'existe ni `priorityHero` ni `priorityEnemy` : `HeroCard` et
`EnemyCard` sont à la priorité 0 au repos (`CombatEntity.layerPriority`).

| Constante | Valeur | Usage |
|:---|:---|:---|
| `priorityBackground` | -100 | Fond d'arène |
| `priorityFrostVignette` | -50 | Givre aux coins de l'écran (héros gelé) : au-dessus du fond, sous les cartes |
| *(aucune constante)* | 0 | `HeroCard` et `EnemyCard` au repos |
| `priorityEntityHovered` | 5 | Carte de combat survolée : ses languettes déroulées passent sur la voisine, sous la main |
| `priorityCardBase` | 10 | Cartes en main (+ index) |
| `priorityCardHovered` | 100 | Carte de la main survolée |
| `priorityCardFocused` | 150 | Carte de la main sélectionnée/ciblée |
| `priorityInspectionVeil` | 180 | Voile d'estompage de la fiche d'un ennemi, au-dessus de la carte focalisée |
| `priorityInspectedEnemy` | 190 | Carte de l'ennemi dont la fiche est ouverte, au-dessus du voile — et pendant son retour |
| `priorityCardTrail` | 200 | Effets de traînée |
| `priorityTargetingLine` | 300 | Ligne de ciblage |
| `priorityCardDraggingMax` | 500 | Carte en cours de drag |

Les trois constantes 5, 180 et 190 viennent de la vague 1 du bestiaire
([ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md), sur la branche). Au-dessus du
voile passent les textes flottants et les icônes d'effet (ajoutés au jeu à 200) et la carte jouée
en vol (500) ; la ligne de ciblage, enfant de `CombatVisualSystem` ajouté à 0, reste dessous. Les
languettes sont enfants de leur carte à 6, au-dessus de la gangue (4) et du halo (5).
