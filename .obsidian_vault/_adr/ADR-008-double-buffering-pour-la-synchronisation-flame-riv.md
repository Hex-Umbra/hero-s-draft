## 🔄 ADR-008 : Double-Buffering pour la Synchronisation Flame ⇄ Riverpod

### Statut
✅ Accepté & Implémenté

### Contexte
La boucle de jeu Flame (`update`) tourne à 60fps, tandis que les mutations Riverpod surviennent de manière asynchrone depuis l'UI Flutter. Un mécanisme de synchronisation sûr est nécessaire pour éviter les accès concurrents.

### Décision
- Trois **tampons nullable** dans `HerosDraftGame` : `_nextState`, `_nextDeckState`, `_nextCombatState`.
- Des **setters publics** (`syncState`, `syncDeck`, `syncCombat`) écrivent dans ces tampons depuis le thread UI.
- Dans `update(dt)`, si un tampon est non-null et `hasLayout == true`, la méthode de diffing correspondante est appelée (`_applyState`, `_applyDeckState`, `_applyCombatState`), puis le tampon est remis à null.

### Preuves dans le code
- `HerosDraftGame` : 3 champs `_nextState`/`_nextDeckState`/`_nextCombatState`.
- `GameScreen` : appelle `game.syncState()` dans des `addPostFrameCallback`.
- Leçon documentée dans `docs/lessons/flame_riverpod_sync.md`.

### Conséquences
- ✅ Pas de race condition entre Flame et Riverpod.
- ✅ Rendu toujours cohérent à la frame suivante.
- ⚠️ **Risque** : Si deux mutations d'état surviennent dans la même frame, seule la dernière est appliquée (la première est écrasée dans le tampon).
- ⚠️ Le rapport Gemini 3.5 recommande un pattern event-driven plutôt que polling de tampons.
