### 5.10. Optimisations de Rendu GPU/CPU & Effet Physique de Pioche

Afin de garantir un framerate stable de 60 FPS sur mobile et d'assurer un "game feel" fluide, les optimisations suivantes ont été intégrées :

1. **Élimination de saveLayer GPU** :
   - Les appels à `canvas.saveLayer()` sont extrêmement coûteux en GPU car ils allouent des tampons off-screen.
   - Les composants `FloatingText` et `EffectIcon` ont été restructurés pour dessiner directement sur le canvas principal sans faire d'appels à `saveLayer` redondants.

2. **Mise en cache CPU (Text Painters) dans CardComponent** :
   - Les calculs de disposition (`TextPainter.layout`) consomment du CPU de façon significative.
   - Le texte des cartes est mis en cache sous forme de layout stable dans `CardComponent`. Pendant les animations de transition d'opacité, le texte n'est pas ré-aligné ni ré-agencé.
   - L'opacité est gérée via `canvas.saveLayer()` uniquement de manière conditionnelle si l'opacité est strictement inférieure à 1.0 (`opacity < 1.0`). Si la carte est pleinement opaque, le texte est dessiné sans aucun buffer off-screen.

3. **Transition Physique Organique de la Pioche** :
   - Lors du tirage d'une carte, celle-ci apparaît physiquement au niveau des coordonnées de la pile de pioche (`Vector2(40, size.y - 40)`).
   - Une série de Flame Effects asynchrones (déplacement `MoveEffect`, redimensionnement `ScaleEffect`, rotation `RotateEffect`) déplace et oriente dynamiquement la carte vers son slot assigné dans la main en arc de cercle, évitant l'apparition instantanée et statique.
