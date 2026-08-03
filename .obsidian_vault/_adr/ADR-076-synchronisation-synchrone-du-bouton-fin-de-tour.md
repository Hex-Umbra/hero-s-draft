## 🧭 ADR-076 : Synchronisation Synchrone du Bouton Fin de Tour

> [!NOTE]
> Renumeroté de `ADR-028` en `ADR-076` le 2026-08-03 : le numero `ADR-028` etait porte par deux decisions distinctes. Voir `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md` §2.1.

### Statut
✅ Accepté & Implémenté (v0.2.5)

### Contexte
Lors du combat, le bouton de fin de tour utilise une triple validation : l'état Riverpod (`combatState.turnPhase == TurnPhase.player`), l'état de phase local de Flame (`_game.currentPhase == TurnPhase.player`) et l'absence d'animation de cartes (`!_game.isCardAnimating`).
Lorsqu'il clique sur "Fin de Tour", `HerosDraftGame` passe immédiatement `currentPhase` à `TurnPhase.enemy` pour empêcher le spam. À la fin du tour ennemi, l'état Riverpod repassait immédiatement à `TurnPhase.player`, mais le widget se reconstruisait avant que Flame ne fasse son tick de frame suivant. Cela causait une désynchronisation transitoire de phase désactivant le bouton ("null") à la reconstruction de la vue pour le nouveau tour.

### Décision
- Forcer de manière synchrone et explicite l'état `_game.currentPhase = TurnPhase.player;` dans la méthode `_startPlayerNewTurn()` de `game_screen.dart` lors du déclenchement du tour joueur.
- Conserver la logique de protection contre le double-clic lors de la transition vers le tour de l'ennemi.

### Preuves dans le code
- [game_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/game_screen.dart) (`_startPlayerNewTurn()`) :
  ```dart
  _game.currentPhase = TurnPhase.player;
  ```

### Conséquences
- ✅ **Expérience utilisateur fluide** : Le bouton de fin de tour redevient immédiatement actif et cliquable dès le début du tour du joueur.
- ✅ **Sécurité anti-spam préservée** : Le bouton se désactive instantanément dès le premier clic pour la transition vers le tour ennemi.
- ✅ **Zéro Régression** : Les tests unitaires (108/108) et l'analyse statique restent 100% verts.
