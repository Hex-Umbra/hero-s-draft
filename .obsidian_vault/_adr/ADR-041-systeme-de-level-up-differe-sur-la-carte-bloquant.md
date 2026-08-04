## 🗺️ ADR-041 : Système de Level Up Différé sur la Carte & Bloquant (Deferred Level Up & Interaction Blocking on Map)

### Statut
✅ Accepté & Implémenté (v0.1.4)

### Contexte
Dans l'implémentation précédente, lorsqu'un joueur passait un niveau (gain d'XP post-combat), l'écran de draft (`DraftScreen`) s'affichait instantanément sous forme d'un overlay par-dessus le combat. Ce flux créait des conflits visuels avec les transitions de fin de combat, forçait le joueur à faire un choix de carte avant même de voir le récapitulatif global des gains (or, reliques, etc.), et encombrait le cycle de vie du `GameScreen`.

### Décision
Déporter le déclenchement du Draft de montée de niveau sur la carte du monde (`MapScreen`) de manière différée et bloquante :
1. **Suivi d'État Métier (`pendingDrafts`)** :
   - Ajouter un entier `pendingDrafts` dans `RunState`.
   - Lors d'une montée de niveau dans `RunController.gainXp(int xp)`, au lieu d'ouvrir directement un écran, incrémenter `pendingDrafts`.
   - Fournir les méthodes `decrementPendingDrafts()` et `resetPendingDrafts()` dans le contrôleur.
2. **Découplage de fin de combat** :
   - Modifier `GameScreen` pour que la fin de combat (`_presentNextReward` / `_completeAndExitCombat`) ignore l'affichage immédiat du draft et renvoie le joueur directement à la carte.
   - Retirer le composant `DraftScreen` des overlays du jeu de combat.
3. **Overlay d'Alerte Bloquant sur la Carte (`MapScreen`)** :
   - Si `runState.pendingDrafts > 0`, afficher un overlay d'animation "LEVEL UP !" recouvrant tout l'écran de la carte.
   - Bloquer la navigation et les clics sur tous les nœuds de la carte tant que `pendingDrafts` n'est pas résolu.
   - Un clic sur l'overlay "LEVEL UP !" pousse l'écran de draft standard (`DraftScreen`) via le routeur. Lorsque le draft se termine (choix d'une carte ou passe), `decrementPendingDrafts()` est appelée, et si le compteur descend à 0, l'overlay est masqué, rendant les nœuds de la carte à nouveau interactifs.

### Preuves dans le code
- `lib/game/controllers/run_controller.dart` : Ajout et gestion du champ `pendingDrafts` dans `RunState` et `RunController`.
- `lib/ui/screens/map_screen.dart` : Affichage conditionnel de l'overlay `LevelUpOverlay`, interdiction de clic sur les nœuds, et transition vers `DraftScreen`.
- `lib/ui/screens/game_screen.dart` : Retrait de l'overlay de draft et routage de sortie directe sur montée de niveau.
- `lib/ui/screens/draft_screen.dart` : Retrait de l'appel direct à `nextLevel` (désormais géré lors de la sortie du nœud de combat).

### Conséquences
- ✅ **Rythme de Jeu Naturel** : La transition de fin de combat est plus fluide. Le joueur retourne d'abord à la carte, visualise sa position, puis est célébré avec sa montée de niveau.
- ✅ **Gestion des Niveaux Multiples** : Si le joueur gagne plusieurs niveaux d'un coup (combat de boss), `pendingDrafts` s'incrémente plusieurs fois, et l'overlay réapparaîtra séquentiellement sur la carte pour proposer autant de tirages de draft que nécessaire.
- ✅ **Stabilité des États** : L'état du combat est entièrement purgé avant le draft, réduisant les risques d'incohérence mémoire.
