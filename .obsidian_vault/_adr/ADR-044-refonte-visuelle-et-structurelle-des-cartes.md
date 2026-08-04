## 🃏 ADR-044 : Refonte Visuelle et Structurelle des Cartes (Unified Glassmorphic Card UI)

### Statut
✅ Accepté & Implémenté (v0.1.5)

### Contexte
L'interface visuelle d'un jeu de cartes comme Hero's Draft est cruciale pour le game feel et la clarté tactique. La version précédente souffrait de plusieurs limitations :
1. Les cartes possédaient un motif en filigrane (watermark) en arrière-plan et des badges de ciblage textuels encombrants (Single target, All enemies, Self), ce qui surchargeait visuellement l'interface et limitait la lisibilité des descriptions.
2. Les améliorations de forge étaient représentées par des étoiles dorées basiques, ne donnant aucune indication sur la nature de l'upgrade appliqué.
3. Le coût en mana était affiché sous forme de cristaux ou de gemmes positionnés de manière incohérente entre le moteur Flame et les widgets de l'interface Flutter (UiCard).
4. La taille des cartes était trop grande, provoquant des encombrements d'écran sur les petites résolutions.
5. Les labels textuels indiquant explicitement la rareté de la carte (ex: "COMMUNE", "LÉGENDAIRE") encombraient la face avant de la carte, alors que la couleur de la carte devrait suffire à communiquer cette information de manière immédiate et intuitive.

### Décision
Mettre en œuvre une refonte visuelle majeure et unifiée pour le rendu des cartes dans les couches Flutter (`UiCard`) et Flame (`CardComponent` et `CardTextRenderer`) :
1. **Style Glassmorphic Unifié** :
   - Application d'un arrière-plan semi-transparent avec dégradé vertical (opacité `0.6` en haut à `0.2` en bas) et floutage d'arrière-plan de 10px (`BackdropFilter` et `ImageFilter.blur`).
   - Lissage des bordures avec une épaisseur fine (de `1.5` à `2.5` si sélectionné) et une opacité réduite (`0.5` de la couleur du type de carte) pour un style moderne.
   - Suppression totale du filigrane (watermark) arrière-plan.
2. **Médaillon de Coût Mana Standardisé** :
   - Affichage du coût dans un cercle de rayon 12px positionné dans le coin supérieur gauche, de couleur sombre (`0xFF0D1B2A`), orné d'un liseré et d'un halo de lueur cyan. Standardisé à l'identique entre le moteur Flame et les widgets Flutter.
3. **Fentes de Runes (Rune Sockets) avec Retour à la Ligne** :
   - Remplacement des étoiles dorées par des emplacements circulaires représentant la capacité de forge (`baseMaxForgeUpgrades + rarityIndex`).
   - Chaque emplacement vide est un cercle blanc translucide (`0.05` d'opacité).
   - Les upgrades appliqués affichent l'émoji/rune correspondant à l'amélioration (⚔️ pour `sharp`, 🛡️ pour `hardened`, 🔥 pour `burning`, etc.), rendant les cartes auto-documentées visuellement.
   - **Retour à la ligne automatique (Multi-row Wrapping)** : Pour éviter que les fentes ne dépassent de la largeur de la carte (notamment pour les cartes de haute rareté et les cartes uniques qui peuvent avoir jusqu'à 5+ upgrades), les sockets sont disposés sur plusieurs lignes avec un maximum de 5 fentes par rangée.
     - **Couche UI (Flutter `UiCard`)** : Utilisation d'un widget `Wrap` à espacement défini (`spacing: 2.0`, `runSpacing: 2.0`) contraint à l'intérieur d'une `SizedBox` de largeur fixe `45.0` pixels, forçant un wrap automatique au-delà de 5 fentes (`5 * 7px + 4 * 2px = 43px`).
     - **Couche Rendu (Flame `CardTextRenderer`)** : Calcul manuel de positionnement sur Canvas à l'aide d'une boucle imbriquée (`numRows = (totalSlots + 4) ~/ 5` et `maxSlotsPerRow = 5`) pour centrer chaque ligne horizontalement et les empiler verticalement en décalant l'ordonnée Y de `16` pixels (`socketDiameter 14.0 + spacing 2.0`) par rangée.
4. **Réduction d'Échelle de 25%** :
   - Dimensions réduites à `140 × 196` (ratio `70/110`) dans `GameConstants` pour offrir une disposition plus compacte.
5. **Suppression des Badges de Ciblage & Doublement d'Icônes** :
   - Retrait des badges textuels de ciblage (Single target, All enemies, Self) pour alléger l'UI.
   - **Remplacés par des indicateurs double-icône (double-icon indicators)** : Pour les cartes ciblant tous les ennemis, le doublement d'icône d'effet s'applique uniquement aux effets offensifs ou destinés à l'ennemi (ex: double icône d'épée ⚔️⚔️ pour les dégâts AoE, ou doublement d'icônes de débuffs). En revanche, les effets ciblant le joueur/héros (tels que le gain d'armure, de soin, de mana, la pioche, ou les buffs de statut comme `strength`, `strength_regen` et `armor_regen`) restent représentés par une icône simple, puisqu'ils ne ciblent pas individuellement chaque ennemi.
6. **Suppression du Label de Rareté & Identification par Code Couleur et Halo (Color-Coded Rarity & Glow)** :
   - Retrait complet de l'affichage textuel de la rareté (ex: "Commune", "Rare", "Légendaire") sur la face avant de la carte.
   - La rareté est communiquée de façon purement visuelle via la couleur de sa bordure fine (`rarityColor.withValues(alpha: 0.5)`) et par un halo de surbrillance/glow radial coloré (`rarityColor.withValues(alpha: 0.4)` avec un rayon de flou de 15px et de diffusion de 4px) lorsque la carte est activement sélectionnée (`isSelected == true`).
   - Encadrement de l'infobulle (tooltip) de combat par une bordure reprenant la couleur de la rareté de la carte avec une épaisseur de `1.5` pour lier sémantiquement l'infobulle à la carte.
7. **Couleurs d'Arrière-Plan Typées pour le Rendu Combat (Flame)** :
   - Les cartes de combat dans l'arène de jeu (Flame `CardComponent`) ont été mises à jour pour utiliser des couleurs d'arrière-plan thématiques spécifiques à leur type (type-specific background colors), calquant le style des cartes de menu (`UiCard`) : rouge sombre (`0xFF4A1D1D`) pour les attaques, bleu marine profond (`0xFF152A4A`) pour les compétences, bronze sombre (`0xFF453215`) pour les pouvoirs et gris sombre (`0xFF2D2D2D`) pour les statuts.
8. **Mise à Jour des Tests** :
   - Réécriture des tests d'interface dans `hud_and_targeting_badge_test.dart` pour s'assurer que les anciens badges textuels n'apparaissent plus, valider le doublement des icônes d'action pour la portée multicible sur les effets offensifs, et confirmer le maintien d'une icône simple pour les effets bénéfiques au joueur.

### Preuves dans le code
- `lib/ui/widgets/ui_card.dart` : Rendu du gradient glassmorphic, médaillon flottant en haut à gauche, `runeSocketsRow` remplaçant les étoiles, suppression de `_buildTargetIcon` et implémentation du doublement filtré de `visuals.icon` si `isAllEnemies == true` et que `!isPlayerEffect` est vrai. Utilisation de `rarityColor` pour les bordures, le glow de sélection, et la bordure du tooltip, sans rendu textuel du paramètre `rarity`.
- `lib/game/components/card_component.dart` : Rendu sur canvas Flame de la bordure fine (`rarityColor.withValues(alpha: 0.5)`) et du halo de sélection (`glowPaint..color = rarityColor.withValues(alpha: 0.4)..maskFilter = MaskFilter.blur(BlurStyle.outer, 8)`), sans appel de texte de rareté dans `CardTextRenderer`, et implémentation de `getBackgroundColor()` associant chaque type de carte à son code couleur sombre.
- `lib/game/components/widgets/card_text_renderer.dart` : Rendu vectoriel sur canvas Flame reproduisant fidèlement le médaillon mana (cercle 12px, cyan border), la ligne de rune sockets sur plusieurs rangées avec retour à la ligne (wrapping) par rangées de 5 (décalage vertical de 16 pixels), et le doublement sélectif des icônes de statut/dégâts (filtré par `!isPlayerEffect`).
- `test/widget/hud_and_targeting_badge_test.dart` : Assertions sur `findsNothing` pour les badges textuels, `findsNWidgets(2)` pour les effets offensifs AoE et `findsOneWidget` pour les effets appliqués au joueur sur la même carte.

### Conséquences
- ✅ **Expérience Esthétique Premium** : Le design glassmorphic et le médaillon cyan procurent un game feel plus propre et professionnel.
- ✅ **Lisibilité Accrue & Précision Tactique** : La suppression du filigrane, des badges textuels de ciblage et des labels de rareté textuels réduit considérablement le bruit visuel et simplifie l'assimilation des informations de la carte.
- ✅ **Identification Sémantique Instantanée** : L'utilisation de codes couleur de rareté pour la bordure, le halo de sélection et l'infobulle permet d'identifier immédiatement la valeur d'une carte sans avoir recours à du texte.
- ✅ **Auto-Documentation Graphique & Zéro Débordement (Wrapping)** : L'affichage des runes d'améliorations (émojis) avec wrapping automatique par rangées de 5 (rows of 5) permet d'identifier les upgrades appliqués de manière ordonnée sans déborder des contours de la carte, même pour les cartes uniques hautement améliorées.
- ✅ **Grid Layout Stable & Uniformité Totale** : La réduction d'échelle élimine le risque d'overflow ou d'encombrement graphique sur petit écran, tandis que l'application des couleurs de fond typées sur les cartes Flame en combat garantit l'alignement graphique avec les menus Flutter.
