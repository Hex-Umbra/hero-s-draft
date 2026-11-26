### 5.5. Dimensions de Carte

- **Taille compacte (Réduction de 25%)** :
  - `cardWidth = 140.0`, `cardHeight = 196.0` → `cardSize = Vector2(140, 196)`.
  - Rapport hauteur/largeur plus dense, offrant une meilleure ergonomie et libérant de l'espace écran pour les scènes de combat et menus.
- **La carte d'un ennemi** est le **canevas de son tier**, en pixels de cadre — 88 × 120, 96 × 128, 104 × 136,
  112 × 144, 120 × 152 pour les tiers 1 à 5 —, autour d'une **fenêtre invariante de 64 × 96** ; la barre de PV et les
  languettes s'ancrent à un **gabarit de 88 × 120** (la fenêtre et 12 de marge) centré sur la fenêtre, le même sur
  les cinq cadres. Elle ne suit plus `scaleFactor` : son échelle de repos est la **taille** de `boardScaleFor`
  (`BoardScale.frame`, en pixels logiques par pixel de cadre) — 2,2 pixels d'écran par pixel de cadre pour 1080
  pixels physiques de hauteur (B90, B91), plafonnée par une rangée de six places de 117 pixels de cadre (le gabarit et une languette ; deux languettes voisines se superposent, la carte du dessus reçoit le survol), écart
  minimal 7, largeur utile 0,95 de l'écran, par la barre et par le héros, arrondie à l'entier ≥ 2 à 10 % près s'il
  tient (net), lissée sinon : ×2 net en 1080p, ×3 net en 1440p, 3,31 lissé sur 2880 × 1800 dans Chrome, 3,667 en plein écran, ×4 net en 4K ; la créature et le fond sont à la moitié du pas. Un boss a
  la taille des autres. `baseScale` = taille × `inspectionScale` (2,0) quand sa fiche est ouverte, à toute taille ;
  la carte ouverte descend de 77 pixels de cadre × la taille. Sa barre, en pixels de cadre : `enemyHealthBarTop` = −17,
  `enemyHealthBarHeight` = 13 au-dessus du gabarit, rayon 4, texte 9, bouclier 8 à 3 du texte, montant à 2 du bouclier.
  Les mesures sont dans `GameConstants` (`enemyWindowWidth`, `enemyTemplateWidth`, `enemyRowMinGap`,
  `enemyRowCenterY` = 0,21 …). Le héros et la main gardent `scaleFactor`. Les trois tailles de badge ont disparu
  avec `StatBadge` (vague 1, [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)) ; la carte composée
  est l'objet de [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md), fusionnée dans `main` par la PR #62 ; vérifié le 2026-11-25.
