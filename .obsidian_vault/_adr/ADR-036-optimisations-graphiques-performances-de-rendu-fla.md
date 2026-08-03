## 🔄 ADR-036 : Optimisations Graphiques, Performances de Rendu Flame & Synchronisation des Animations (Graphics, Performance & Animation Optimizations)

### Statut
✅ Accepté & Implémenté

### Contexte
La version 0.0.98 de Hero's Draft présentait plusieurs inefficacités visuelles et goulots d'étranglement de performance dans son moteur de rendu Flame :
1. **Redondance GPU via `saveLayer`** : L'affichage des textes flottants de dégâts/soins (`FloatingText`) et des petites icônes vectorielles (`EffectIcon`) déclenchait des appels répétitifs à `canvas.saveLayer()`. Ces appels forcent le GPU à allouer des tampons off-screen coûteux en mémoire et en temps de calcul, dégradant le framerate sur mobile.
2. **Re-layout CPU à chaque frame** : Pendant les transitions d'opacité (fondus), la disposition textuelle (`TextPainter`) de `CardComponent` était recalculée et re-layoutée à chaque frame, gaspillant du temps CPU.
3. **Condition de concurrence des effets de combat** : Les secousses d'écran, les flashs de sprite et les projectiles visuels étaient initiés dès le clic sur une carte, créant un décalage visuel où l'ennemi affichait ses dégâts (chiffres flottants, flash de douleur) avant même que le projectile ou la carte ne l'ait physiquement percuté. De plus, des double-réactions redondantes dans `CardAnimator` généraient parfois des duplications d'animations.
4. **Manque de poli visuel lors de la pioche** : Les cartes piochées apparaissaient instantanément dans la main, manquant de fluidité et de réalisme physique.

### Décision
1. **Éradication des saveLayer superflus** :
   - Éliminer complètement les appels à `canvas.saveLayer` dans `FloatingText` et `EffectIcon`. Peindre directement sur le canvas principal en adaptant les styles et pinceaux de dessin vectoriels.
2. **Optimisation du Layout CPU de Texte et Opacité Conditionnelle** :
   - Mettre en cache l'instance de `TextPainter` pour le titre et la description dans `CardComponent`.
   - Pendant les transitions d'opacité, éviter de ré-agencer le texte. Dessiner avec `canvas.saveLayer` uniquement et exclusivement si la carte a une opacité strictement inférieure à 1.0 (`opacity < 1.0`). Si la carte est opaque (cas standard), contourner l'allocation off-screen pour peindre le texte en direct.
3. **Synchronisation à l'Impact Synchrone & Anti-Double Trigger** :
   - Différer l'apparition des effets visuels d'impact (tremblement de carte, flash de sprite, FloatingText de dégâts, particules) sur `EnemyCard` lorsque `game.isCardAnimating == true`.
   - Stocker ces effets dans le tampon `_pendingVisualInstance`.
   - Déclencher l'impact physique, le flash, les chiffres de dégâts et l'actualisation des HP/armure uniquement lors de la collision de la carte avec l'ennemi en appelant explicitement `resolvePendingVisualStats()` au moment de l'impact réel.
   - Retirer les écouteurs et callbacks redondants dans `CardAnimator` pour éliminer définitivement les doubles déclenchements.
4. **Effet Physique Organique de Pioche** :
   - Instancier les cartes piochées aux coordonnées de la pile de pioche `Vector2(40, size.y - 40)`.
   - Utiliser des Flame Effects asynchrones (`MoveEffect`, `ScaleEffect`, `RotateEffect`) chaînés pour faire glisser, redimensionner et orienter la carte dynamiquement vers son slot final dans la main.

### Preuves dans le code
- `lib/game/components/floating_text.dart` & `lib/game/components/effect_icon.dart` : Nettoyage des appels à `saveLayer`, dessin direct.
- `lib/game/components/card_component.dart` : Implémentation du cache de layout textuel et de l'opacité conditionnelle.
- `lib/game/components/enemy_card.dart` : Modification de `updateStats` pour différer l'intégralité des effets d'impact physiques (flashes, shakes, particules) et du calcul visuel sous conditions de carte active, résolus dans `resolvePendingVisualStats`.
- `lib/game/animators/card_animator.dart` : Suppression des branchements redondants d'animation d'impact.
- `lib/game/heros_draft_game.dart` : Logique de spawn de cartes à `Vector2(40, size.y - 40)` avec application d'effets visuels combinés.

### Conséquences
- ✅ **Fluidité Graphique Optimisée (60 FPS)** : Le retrait de `saveLayer` élimine les goulots d'étranglement GPU et stabilise le framerate sur mobile. Le caching CPU évite le coût de `layout()` sur le fil de rendu.
- ✅ **Immersion et Confort Visuel** : Les retours d'impact se déclenchent à la frame exacte de collision physique de la carte. Plus de flash de dégâts ou de chiffres flottants prématurés.
- ✅ **Tactilité Améliorée ("Game Feel")** : L'animation de pioche avec trajectoire et orientation fluide renforce l'aspect physique du deckbuilder.
