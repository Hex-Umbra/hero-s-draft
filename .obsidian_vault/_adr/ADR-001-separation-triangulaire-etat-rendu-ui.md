## 🏛️ ADR-001 : Séparation Triangulaire État/Rendu/UI (Riverpod ⇄ Flame ⇄ Flutter)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans les jeux intégrant des moteurs de rendu interactifs comme Flame, il est courant que la logique métier (calcul de dégâts, cycle de vie du deck, debuffs, cooldowns) se retrouve couplée au code de dessin ou de gestion des animations (`PositionComponent`). Cela rend les tests impossibles sans instancier le moteur graphique et provoque des désynchronisations état/affichage.

### Décision
- **Exclure toute logique métier du moteur Flame** : les contrôleurs Riverpod (`RunController`, `DeckNotifier`, `CombatController`, `InventoryController`, `SkillController`, `EventController`, `ShopController`) sont la source unique de vérité.
- **Rendre Flame réactif et passif** : il observe l'état Riverpod via un pattern de **double-buffering** (`_nextState`, `_nextDeckState`, `_nextCombatState`) appliqué dans `HerosDraftGame.update(dt)` par diffing visuel.
- **Limiter les interactions Flame à des callbacks** : 18 callbacks fortement typés (ex: `onPlayCard`, `onSelectEnemy`, `onResolveEnemyIntent`) injectés via le constructeur de `HerosDraftGame`.
- **Synchronisation Synchrone Transitoire** : Pour les transitions d'état réactives très sensibles au timing utilisateur (comme l'état actif/inactif du bouton de fin de tour), forcer de manière synchrone et directe la valeur dans le moteur Flame (par exemple `_game.currentPhase = TurnPhase.player;` dans `_startPlayerNewTurn()`) plutôt que d'attendre la mise à jour asynchrone au tick suivant de Flame.

### Preuves dans le code
- `HerosDraftGame` (775 lignes) contient uniquement de la logique de rendu, layout, et animation — pas de calcul de dégâts ni de gestion d'état.
- Tous les `StateNotifier` dans `lib/game/controllers/` fonctionnent indépendamment de Flame.
- `EffectResolver` est une classe statique pure sans dépendance Flame.
- `game_screen.dart` (`_startPlayerNewTurn()`) synchronise de manière synchrone `_game.currentPhase = TurnPhase.player;` pour réactiver immédiatement le bouton Fin de Tour (v0.2.5).

### Conséquences
- ✅ **Tests unitaires purs** : 58 tests au vert sans instancier le moteur graphique.
- ✅ **Éradication des bugs de désynchronisation** entre affichage et valeurs logiques.
- ⚠️ **Rigueur nécessaire** : Le pattern de buffering peut manquer des changements d'état si plusieurs mutations surviennent dans une même frame (identifié dans `docs/lessons/flame_riverpod_sync.md`). Pour contourner cela sur les éléments d'interface UI critiques, une mise à jour synchrone directe sur l'instance de `_game` doit être appliquée lors du cycle de vie du Widget parent.
- ⚠️ **Violation partielle** : `HerosDraftGame.executeSkill()` contient encore de la logique de calcul de dégâts (damage_aoe, damage_targeted, armor_buff) — identifiée comme dette technique dans le rapport Opus 4.6.
