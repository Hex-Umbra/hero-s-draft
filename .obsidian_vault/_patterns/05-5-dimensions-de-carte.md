### 5.5. Dimensions de Carte

- **Taille compacte (Réduction de 25%)** :
  - `cardWidth = 140.0`, `cardHeight = 196.0` → `cardSize = Vector2(140, 196)`.
  - Rapport hauteur/largeur plus dense, offrant une meilleure ergonomie et libérant de l'espace écran pour les scènes de combat et menus.
- **La carte d'un ennemi** mesure 100 × 140 unités, mises à l'échelle par `restScale` =
  `scaleFactor` × 1,45 (× 1,25 pour un boss) × `scaleMultiplier`, et `baseScale` = `restScale` ×
  `inspectionScale` (1,25) quand sa fiche est ouverte. Sa barre de PV, en unités de la carte :
  `enemyHealthBarTop` = −17, `enemyHealthBarHeight` = 13 (donc y −17 à −4), rayon 4, texte 9,
  bouclier 8 à 3 du texte, montant à 2 du bouclier. Les trois tailles de badge (`badgeHpSize`,
  `badgeStandardSize`, `badgeCircleSize`) ont disparu avec `StatBadge` — vague 1 du bestiaire, sur
  la branche `feat/v0.6.1-interface-des-ennemis`
  ([ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)) ; vérifié le 2026-11-22.
