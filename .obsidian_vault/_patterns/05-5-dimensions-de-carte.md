### 5.5. Dimensions de Carte

- **Taille compacte (Réduction de 25%)** :
  - `cardWidth = 140.0`, `cardHeight = 196.0` → `cardSize = Vector2(140, 196)`.
  - Rapport hauteur/largeur plus dense, offrant une meilleure ergonomie et libérant de l'espace écran pour les scènes de combat et menus.
- **La carte d'un ennemi** est le **canevas de son tier**, en pixels de cadre — 88 × 120, 96 × 128, 104 × 136,
  112 × 144, 120 × 152 pour les tiers 1 à 5 —, autour d'une **fenêtre invariante de 64 × 96** ; la barre de PV et les
  languettes s'ancrent à un **gabarit de 88 × 120** (la fenêtre et 12 de marge) centré sur la fenêtre, le même sur
  les cinq cadres. Elle ne suit plus `scaleFactor` : son échelle de repos est le **palier** de `boardScaleFor`
  (`BoardScale.frame`, en pixels logiques par pixel de cadre) — le plus grand pas pair, en pixels physiques, qui
  laisse tenir une rangée de six places de 146 pixels de cadre, écart minimal 7, largeur utile 0,95 de l'écran :
  ×2 en 1080p et en 1440p, ×4 en 4K, lissé sous ×2 ; la créature et le fond sont à la moitié du pas. Un boss a
  la taille des autres. `baseScale` = palier × `inspectionScale` (2,0) quand sa fiche est ouverte, à tout palier ;
  la carte ouverte descend de 77 pixels de cadre × le palier. Sa barre, en pixels de cadre : `enemyHealthBarTop` = −17,
  `enemyHealthBarHeight` = 13 au-dessus du gabarit, rayon 4, texte 9, bouclier 8 à 3 du texte, montant à 2 du bouclier.
  Les mesures sont dans `GameConstants` (`enemyWindowWidth`, `enemyTemplateWidth`, `enemyRowMinGap`,
  `enemyRowCenterY` = 0,21 …). Le héros et la main gardent `scaleFactor`. Les trois tailles de badge ont disparu
  avec `StatBadge` (vague 1, [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)) ; la carte composée
  est l'objet de [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md), sur la branche `feat/v0.6.2-cadres-et-decors` ; vérifié le 2026-11-25.
