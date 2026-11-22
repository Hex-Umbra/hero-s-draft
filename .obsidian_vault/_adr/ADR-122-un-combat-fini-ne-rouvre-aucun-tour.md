---
description: Fix S9 — a combat that ends during the enemy phase (the last enemy killed by statuses, or the hero killed by an attack) no longer reopens a player turn; the guard lives in the controller, TurnPhaseManager, whose startPlayerTurn and endEnemyTurn do nothing once either side has lost (CombatState.isCombatEnded or RunState.isDead), while Flame's enemy phase keeps playing its animations to the end; seven controller tests; closes the S9 reserve recorded by ADR-117 and ADR-118
---

# ADR-122 — Un Combat Fini ne Rouvre Aucun Tour (S9)

### Statut

✅ Accepté — 2026-11-20 (correctif S9, consigné ouvert depuis la vague 7). Commit `8d544a3d`,
d'abord sur la branche `fix/s9-phase-ennemie-apres-victoire`, jamais fusionnée seule : **livré sur
la branche `feat/v0.6.1-interface-des-ennemis`, qui en part — vague 1 du
[cadrage du bestiaire](../../docs/possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md) (§4,
trois écarts du propriétaire), test du propriétaire passé le 2026-11-22, en attente de la PR, de la fusion et du tag du
propriétaire.** Rien n'en est dans `main`.

**Clôt la réserve S9** qu'ont consignée [ADR-117](ADR-117-les-charges-elementaires.md) (vague 7) et
[ADR-118](ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md) (vague 8). Chacun ne
change que de Statut.

### Contexte

`HerosDraftGame._enemyRipostePhase` joue la phase ennemie jusqu'au bout, sans lire
`isCombatEnded`, et finit par `onEndEnemyTurn`. Quand les statuts tuaient le dernier ennemi, ou
qu'une attaque tuait le héros, l'écran enchaînait quand même la fin de phase : un tour du joueur
complet s'ouvrait sur un combat fini. Après une victoire, le héros subissait ses statuts — un soin
de trop de *Bénédiction* et de la *Source de Vie* de *Prière*, un Poison qui pouvait le tuer ; après
sa mort, un soin de début de tour pouvait le ranimer. Le défaut était dit **bloquant pour le premier
contenu qui pose du Feu ou du Poison sur le héros** — précisément ce que les vagues suivantes du
bestiaire apportent.

### Décision

1. **La garde vit dans le contrôleur, pas dans Flame.** `TurnPhaseManager` gagne `_isCombatOver`
   — vrai dès qu'un camp a perdu : `controller.currentState.isCombatEnded` ou
   `ref.read(runProvider).isDead`. **`startPlayerTurn` et `endEnemyTurn` ne font rien sur un combat
   fini** : ni fermeture de phase, ni nouvelles intentions, ni reliques de début de tour, ni statuts,
   ni pioche, ni `turnCount`.
2. **Flame ne change pas** : il continue d'appeler les façades et d'animer ; c'est le contrôleur
   qui refuse. Aucune règle ne se calcule dans Flame ([`_patterns/07-00`](../_patterns/07-00-flux-complet-d-un-tour-de-combat.md)).
3. **Un combat qui continue rouvre son tour comme avant** : la garde ne lit que la fin du combat.

### Preuves dans le code

- `lib/game/controllers/combat/turn_phase_manager.dart` (`_isCombatOver`, `startPlayerTurn`,
  `endEnemyTurn`).
- `test/unit/combat_controller_test.dart`, groupe « Un combat fini a la phase ennemie ne rouvre
  aucun tour » : sept tests — cinq sur la victoire par les statuts (le compte des tours, le Poison
  du héros, la Source de Vie, la pioche, un combat qui continue), deux sur la mort du héros.

### Conséquences

- La base de tests de la branche passe de 1859 (`main`) à **1866** (+7), base de la vague 1 du
  bestiaire — mesurée par la vague, re-mesurée par la suite complète de 1935 le 2026-11-22.
- La note de version de la vague porte les deux corrections que le joueur voit : la victoire et la
  défaite pendant le tour des ennemis.
