### 5.2. Widget `UiCard` (`lib/ui/widgets/ui_card.dart`)

**Composant UI maître unifié et décomposé (v0.2.01)** — remplace 6 implémentations dupliquées et applique le principe de responsabilité unique (SRP).

Pour éviter le pattern anti-pattern de la God Class et structurer proprement le code, le composant `UiCard` (initialement >1100 lignes) a été divisé en sous-widgets et utilitaires spécialisés sous le dossier `lib/ui/widgets/ui_card/` :
- **`UiCard`** : Classe façade principale, qui assemble le layout global et gère les interactions (`GestureDetector`, `Tooltip`).
- **`ui_card_helpers.dart`** : Module purement logique regroupant l'analyse des cibles (`resolveTarget`), l'analyse élémentaire (`determineDamageType`), la configuration visuelle des effets (`getEffectVisuals`), le code couleur du type de carte et du fond (`getCardTypeColor`, `getCardBackgroundColor`), les couleurs et indices de rareté, et la construction verbeuse des descriptions bilingues des infobulles (`buildDetailedDescription`).
- **`polychromatic_border.dart`** : Widget stateful (`PolychromaticBorder` et son painter) prenant en charge l'animation d'effet foil polychromatique au survol de la souris.
- **`card_mana_medallion.dart`** : Widget autonome layout-agnostique dessinant le médaillon circulaire flottant affichant le coût en mana.
- **`card_rune_sockets.dart`** : Widget de rendu et d'agencement multi-lignes (Wrapping) pour les fentes d'upgrades de la forge.
- **`card_compact_description.dart`** : Widget de mise en forme des badges d'effets visuels et des modificateurs de forge sur la face avant de la carte.

Le comportement et les caractéristiques visuelles restent inchangés :

- **Ratio d'aspect** : `70 / 110` constant.
- **Style Glassmorphic** : Utilise un `BackdropFilter` (flou gaussien de 10px) avec un arrière-plan semi-transparent (dégradé linéaire vertical d'opacité `0.6` à `0.2`) et une bordure fine de `1.5` (`2.5` si sélectionné, opacité `0.5` de typeColor) pour un rendu moderne et épuré. Le motif en filigrane (watermark) en arrière-plan a été retiré.
- **Médaillon de Coût Standard** : Un cercle flottant noir (`Color(0xFF0D1B2A)`) de rayon 12px (centré à offset `[-6, -6]` par rapport au coin supérieur gauche) affichant le coût en mana avec un liseré et un halo de lueur cyan. Câblé à l'identique entre Flutter et Flame.
- **Fentes de Runes (Rune Sockets) avec Multi-Row Wrapping** : Remplace les anciennes étoiles par des réceptacles circulaires représentant la capacité de forge (`baseMaxForgeUpgrades + rarityIndex`). Les upgrades actifs affichent leur emoji rune (⚔️, 🛡️, 🪶, 💎, 🔥, ❄️, ⚡, ⏳), tandis que les vides apparaissent sous forme de cercles blancs translucides (opacité `0.05`). Pour accommoder un grand nombre d'upgrades sans dépasser la largeur de la carte, les fentes sont agencées en multi-lignes de 5 éléments maximum.
  - **Dans Flutter (`UiCard`)** : Utilisation d'un widget `Wrap` (`spacing: 2.0`, `runSpacing: 2.0`) confiné dans un conteneur `SizedBox` de largeur `45.0` pixels, provoquant le retour automatique à la ligne au-delà de 5 fentes.
  - **Dans Flame (`CardTextRenderer`)** : Calcul manuel de grille sur Canvas via `numRows = (totalSlots + 4) ~/ 5` et `maxSlotsPerRow = 5`, recentrant chaque ligne horizontalement et les empilant verticalement en décalant l'ordonnée Y de `16.0` pixels (diamètre 14.0 + espacement 2.0) par ligne.
- **Suppression du Ciblage Textuel** : Les badges textuels de ciblage (Single target, All enemies, Self) ont été supprimés pour réduire le bruit visuel.
- **Doublement d'icônes Multicibles (Raffiné)** : Pour signifier graphiquement la portée multicible (`CardTarget.allEnemies`), l'icône des effets destinés aux ennemis (ex: dégâts ⚔️, débuffs) est affichée deux fois consécutivement (⚔️⚔️) dans la ligne d'effets compacte. Les effets bénéfiques ciblant le joueur (ex: armure, soin, gain de mana, pioche, force) ne sont pas doublés et restent représentés par une seule icône afin d'éviter une surcharge visuelle incorrecte.
- **Suppression du label de rareté & Identification visuelle par Couleur/Halo** : Retrait total de l'affichage textuel de la rareté sur la face avant de la carte. La couleur de la rareté (`rarityColor`) est récupérée de façon dynamique via l'extension `.color` sur l'enum de rareté (`CardRarity`) et sert à teinter la bordure fine de la carte (`rarityColor.withValues(alpha: 0.5)`), à appliquer un halo radial de surbrillance (`rarityColor.withValues(alpha: 0.4)` de rayon de flou 15px et de diffusion 4px) en cas de sélection (`isSelected == true`), et à colorer le contour de son infobulle (`Border.all(color: rarityColor, width: 1.5)`).
- **`buildDetailedDescription()`** : Concatène de manière verbeuse et formatée les détails de la carte en tête de l'infobulle (type de cible écrit explicitement pour éviter toute ambiguïté visuelle, rareté, type de carte et coût en mana), parse la liste d'effets, remplace les placeholders dynamiques selon le niveau et les améliorations de forge, et enrichit systématiquement les statuts d'explications mécaniques détaillées, claires et localisées entre parenthèses :
  - **poison** : `(Subit des dégâts égaux au Poison au début de son tour, puis la durée diminue)` en FR / `(Takes damage equal to Poison at turn start, then duration decreases)` en EN.
  - **burn** : `(Subit des dégâts de feu égaux à la Brûlure au début de son tour, puis la valeur diminue de 1)` en FR / `(Takes fire damage equal to Burn at turn start, then the value decreases by 1)` en EN.
  - **freeze** : `(Réduit les dégâts de la prochaine attaque de l'ennemi de 50%)` en FR / `(Reduces next enemy attack damage by 50%)` en EN.
  - **shock** : `(Subit des dégâts supplémentaires égaux à l'Électrocution à chaque coup reçu)` en FR / `(Takes extra damage equal to Shock on every hit)` en EN.
  - **weakness** : `(Réduit les dégâts infligés par l'ennemi de 25%)` en FR / `(Reduces damage dealt by the enemy by 25%)` en EN.
  - **vulnerable** : `(L'ennemi subit 50% de dégâts supplémentaires)` en FR / `(Enemy takes 50% more damage from attacks)` en EN.
- **Mappage HUD & Emojis** : Pour préserver la cohérence visuelle absolue :
  - Les statuts joueurs et ennemis utilisent des émojis unifiés dans `status_indicator.dart` (`burn` 🔥, `freeze` ❄️, `shock` ⚡, `strength_regen` ✊ pour éviter la collision visuelle avec burn).
  - Les labels linguistiques sont câblés dynamiquement à la volée dans `status_effects_panel.dart`.
