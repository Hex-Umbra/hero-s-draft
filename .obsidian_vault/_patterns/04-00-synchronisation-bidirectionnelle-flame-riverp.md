## 4. Synchronisation Bidirectionnelle Flame ⇄ Riverpod

Le mécanisme de synchronisation repose sur un **pattern de double-buffering** :

### 4.1. Descente d'État (Riverpod → Flame)

Les widgets Flutter (via `WidgetRef`) appellent trois setters :
- `game.syncState(RunState)` → écrit dans `_nextState`
- `game.syncDeck(DeckState)` → écrit dans `_nextDeckState`
- `game.syncCombat(CombatState)` → écrit dans `_nextCombatState`

Dans `HerosDraftGame.update(dt)`, si `hasLayout == true` et qu'un buffer est non-null :
1. `_applyState(_nextState!)` → crée/met à jour `HeroCard`, rafraîchit les visuels de cartes en main.
2. `_applyDeckState(_nextDeckState!)` → diff les cartes en main (ajout/suppression), recalcule le layout en arc.
3. `_applyCombatState(_nextCombatState!)` → diff les ennemis (ajout avec fade/scale, suppression), repositionne, synchronise la sélection visuelle, met à jour la phase.

### 4.2. Remontée d'Événements (Flame → Riverpod)

**14 callbacks fortement typés** injectés via le constructeur de `HerosDraftGame` — **compté le 2026-08-25** sur les déclarations de champs de `lib/game/heros_draft_game.dart` :

| Callback | Déclencheur |
|:---|:---|
| `onPlayCard` | Carte jouée (drop sur ennemi valide) |
| `onSelectEnemy` / `onUpdateEnemyStats` | Clic/tap sur ennemi |
| `onPhaseChanged` | Changement de phase |
| `onStartEnemyTurn` / `onEndEnemyTurn` | Début/fin de phase ennemie |
| `onResolveEnemyIntent` | Résolution séquentielle d'intention |
| `onExecuteSkill` | Exécution d'une compétence héroïque (skill1/skill2) |
| `onEnemiesDead` / `onEnemyKilled` | Nettoyage d'ennemis |
| `onEnemiesSpawned` | Spawn initial |
| `onAnimationStateChanged` | Changement d'état d'animation Flame (force un rebuild HUD) |
| `onShowTooltip` / `onHideTooltip` | Tooltips contextuels |

> [!NOTE]
> **Cinq callbacks ont été supprimés depuis la rédaction initiale**, en deux vagues.
> `onPlayerTakeDamage` / `onPlayerHeal` / `onPlayerGainArmor` d'abord — voir §6.2
> point 7. Puis `onTurnEnded` et `onEnemyDebuffDeck`, tous deux dans le commit
> `295ec93` du 2026-08-06, la passe de suppression de code mort de **P-02**
> ([ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md)).
> Ces deux-là sont restés listés ici pendant dix-neuf jours, et le total annoncé
> était donc resté à 16 — un décompte qui décrivait le tableau, non le code.

### 4.3. Phase de Riposte Ennemie (`_enemyRipostePhase`)

Flux asynchrone séquentiel avec animations :
1. `onPhaseChanged(TurnPhase.enemy)` + délai 600ms
2. `onStartEnemyTurn()` → `CombatController.startEnemyTurn()` (ticks poison, traitement statuts)
3. Délai 400ms pour animations de tick
4. **Boucle** sur chaque ennemi : animation d'attaque/buff → `onResolveEnemyIntent(enemyId)` → délai 400ms
5. `onEndEnemyTurn()` → re-roll intentions, retour phase joueur

### 4.4. Système de Mort et de Stats Différé Z-Sync (Delayed Entity Destruction & Visual Stats Synchronization)

Pour éliminer la condition de concurrence visuelle (race condition) où l'état logique de Riverpod met à jour les statistiques (points de vie, armure, statuts) ou supprime instantanément un ennemi alors que l'animation de la carte Flame est encore en route, le jeu implémente le patron Z-Sync étendu aux attributs visuels :

1. **Drapeaux et Buffers de Verrouillage** :
   - `game.isCardAnimating` (booléen global) : Flag de verrouillage positionné à `true` dès qu'une carte jouée initie sa phase d'attaque ou de lancer d'effet.
   - `enemyCard.isPendingDeath` (booléen local) : Flag indiquant que l'ennemi a été tué logiquement mais que sa suppression visuelle est mise en attente.
   - `enemyCard._pendingVisualInstance` (modèle `EnemyInstance?` local) : Buffer stockant l'état des statistiques logiques reçues durant le trajet de la carte afin d'en différer l'affichage HUD.

2. **Diffèrement des Statistiques HUD & Effets d'Impact (`updateStats`)** :
   - Lors de la réception de nouvelles statistiques dans `EnemyCard.updateStats(newInstance)` :
     - Si `game.isCardAnimating == true`, la mise à jour de la barre de vie (`HealthBar`), du badge d'armure (`StatBadge`), de la liste des icônes de buffs/debuffs ainsi que **l'intégralité des effets visuels d'impact** (secousses `Curves.elasticOut`, flashes sprite `ColorEffect`, `FloatingText` de dégâts, et éjection de particules `spawnDamageParticles`) sont **différés** et stockés dans `_pendingVisualInstance`.
     - Si `game.isCardAnimating == false` (dégâts passifs comme le poison ou la brûlure), les indicateurs et effets d'impact physiques sont appliqués et déclenchés immédiatement.

3. **Interception du Nettoyage Visuel (`_applyCombatState`)** :
   Dans `_applyCombatState`, lors de l'application du delta des ennemis :
   - Si un ennemi visuel Flame n'est plus présent dans la liste des ennemis logiques (Riverpod) :
     - Si `game.isCardAnimating == true`, le composant n'est **PAS** supprimé immédiatement. Il est marqué `isPendingDeath = true` et reste pleinement dessiné sur le board.
     - Si faux, il est supprimé ou anime sa disparition immédiatement (mort passive de début de tour, ex: poison).

4. **Libération et Résolution Synchrone à l'Impact (`resolvePendingDeaths`)** :
   - Lorsque l'effet visuel de la carte se termine et impacte sa cible (physiquement ou magiquement) :
     - Le callback d'impact est déclenché sur la cible.
     - Il appelle `card.resolvePendingVisualStats()` : cela applique le `_pendingVisualInstance` mis en réserve, actualise de façon synchrone les barres de vie, l'armure, les icônes de statuts, **ET** déclenche à cet instant précis les effets visuels physiques d'impact (secousses, flashes, particules, et damage numbers).
     - Le callback de fin de mouvement de la carte appelle `game.resolvePendingDeaths()`.
     - Cette méthode bascule `game.isCardAnimating = false`.
     - Elle lance simultanément l'animation de mort (réduction de taille via `ScaleEffect` et fondu d'opacité via `OpacityEffect` de Flame) pour toutes les `EnemyCard` ayant `isPendingDeath == true`.
     - Les réactions dupliquées ont été nettoyées de `CardAnimator` pour prévenir tout double déclenchement visuel.
