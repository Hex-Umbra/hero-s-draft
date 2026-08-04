## 📐 ADR-002 : Responsivité Dynamique par ScaleFactor

### Statut
✅ Accepté & Implémenté

### Contexte
Le jeu cible des supports variés : smartphones étroits, tablettes et moniteurs PC 4K. Flame utilise un canvas absolu par défaut, ce qui peut tronquer ou déformer l'affichage sur des résolutions non-standard.

### Décision
Implémenter une formule de mise à l'échelle dynamique basée sur la **hauteur réelle du viewport** :
```dart
double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);
```
- **Hauteur de référence** : 800px (résolution mobile standard portrait).
- **Clamp** : 0.85 (plancher pour très petits écrans) à 2.5 (plafond pour écrans 4K).
- Tous les composants graphiques (cartes 140×196, espacements, arcs de main, positions ennemis) sont multipliés par ce coefficient.

### Preuves dans le code
- `HerosDraftGame.scaleFactor` utilisé dans `_applyState()`, `_applyDeckState()`, `_applyCombatState()`, `onGameResize()`.
- `_layoutHand()` : `radius = size.y * 1.5`, angles et positions calculés proportionnellement.
- `GameConstants` : `cardWidth = 140.0`, `cardHeight = 196.0` — valeurs de base avant application du scale.

### Conséquences
- ✅ Adaptabilité visuelle du mobile au PC 4K sans rupture de layout.
- ✅ Préservation du "Game Feel" organique et de l'alignement des éléments.
- ⚠️ Contrainte d'incorporer `scaleFactor` sur toutes les dimensions, augmentant le risque d'oublis pour les nouveaux composants.
