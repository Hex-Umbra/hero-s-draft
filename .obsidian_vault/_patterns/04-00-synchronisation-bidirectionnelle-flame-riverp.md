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

**17 callbacks fortement typés** injectés via le constructeur de `HerosDraftGame` — **re-compté le 2026-11-22** sur la branche `feat/v0.6.1-interface-des-ennemis` (16 sur `main`, 14 le 2026-10-16, 13 le 2026-09-05) : `grep -cE "^\s+final (void Function|bool Function|VoidCallback)" lib/game/heros_draft_game.dart` :

| Callback | Déclencheur |
|:---|:---|
| `onPlayCard` | Carte jouée (drop sur ennemi valide) |
| `onSelectEnemy` / `onUpdateEnemyStats` | Clic/tap sur ennemi — `onSelectEnemy` n'était appelé par aucun code Flame avant le lot E4 de P-43 ; il rapporte désormais l'ennemi vivant touché pendant qu'une signature attend sa cible (ci-dessous) |
| `onEnemyTargetCancelled` | *Branche de la vague 4.* Le jeu abandonne l'attente d'une cible — carte focalisée ou saisie, toucher du décor —, jamais quand l'écran la lève |
| `onPhaseChanged` | Changement de phase |
| `onStartEnemyTurn` / `onEndEnemyTurn` | Début/fin de phase ennemie |
| `onResolveFireWave` / `onResolveEnemyStatuses` | Vague 7 : la vague suivante de la chaîne du Feu, puis les autres statuts des ennemis |
| `onResolveEnemyIntent` | Résolution séquentielle d'intention |
| `onEnemiesDead` / `onEnemyKilled` | Nettoyage d'ennemis |
| `onEnemiesSpawned` | Spawn initial |
| `onAnimationStateChanged` | Changement d'état d'animation Flame (force un rebuild HUD) |
| `onShowTooltip` / `onHideTooltip` | Infobulle d'une carte de la main — `CardType` non nul depuis que la jauge d'un ennemi n'en ouvre plus |
| `onInspectionChanged` | *Branche `feat/v0.6.1-interface-des-ennemis`.* Ouverture, remplacement, fermeture de la fiche d'un ennemi, et tout rectangle neuf d'une fiche ouverte dont la carte se replace (`EnemyInspection?` : id et rectangle de la carte agrandie) |

> [!IMPORTANT]
> **La fiche d'un ennemi — un état d'affichage que Flame possède et que l'écran reflète** (P-05
> vague 1, sur la branche — [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)).
> `_handlePlayerTargeting(target, pointerId)` suit un ordre fixe : run vivante et tour du joueur,
> sinon rien ; **une carte focalisée garde le toucher** ; un ennemi mort ou mourant n'ouvre rien ;
> **une signature armée reçoit l'ennemi** ; sinon l'ennemi ouvre sa fiche (`inspectEnemy`), la garde
> ou remplace celle d'un autre, et **le pointeur de l'appui est retenu**. Le `Listener` translucide
> de `GameScreen`, servi après Flame dans le même appui, appelle `closeInspectionUnlessOn(pointer)`
> à chaque appui du bouton principal : la fiche reste si et seulement si ce pointeur est celui que
> Flame vient de retenir, qui est aussitôt oublié. Flame ferme aussi par garde — `setFocusedCard`,
> le mutateur de `awaitingEnemyTarget`, le décor, `executeTurn` — et par l'état :
> `StateSyncSystem._applyCombatState` appelle `closeInspectionIfStale` (ennemi parti, phase
> quittée, combat fini). `repositionEnemies` (qui passe par `placeRow`) réémet le rectangle **s'il a changé** (chaque
> reconstruction de `GameScreen` rappelle `onGameResize`). **`GameScreen` diffère tout reflet** par
> `addPostFrameCallback`, comme `onEnemiesSpawned`. Fiche ouverte, ni la main ni les languettes ne
> réagissent au survol.

> [!IMPORTANT]
> **Le ciblage d'une signature — le contrat entre la barre et Flame** (lot E4 de P-43, branche de
> la vague 4, [ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md)). `GameScreen` arme une
> signature à cible unique en posant `awaitingEnemyTarget = true` (accesseur et mutateur de
> `HerosDraftGame` ; `false` éteint l'illumination sans rappel). Dans `_handlePlayerTargeting`,
> **une carte focalisée garde la priorité** ; sinon, un ennemi **vivant** touché est rapporté par
> `onSelectEnemy` et l'attente cesse — un ennemi mort ou mourant est ignoré, l'attente demeure.
> Pendant l'attente, l'ennemi survolé s'illumine (`onPointerMove`). **Flame ne connaît ni
> `SignatureInstance` ni la barre ; la barre ne lit aucun composant Flame.** Le glisser depuis la
> barre, écarté, aurait demandé à Flutter de lire les positions des composants Flame.

> [!NOTE]
> **Six callbacks ont été supprimés depuis la rédaction initiale**, en trois vagues.
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

La boucle ne lit pas `isCombatEnded` et se joue jusqu'au bout ; c'est le contrôleur qui refuse :
sur un combat fini, `endEnemyTurn` et `startPlayerTurn` ne font rien (S9, sur la branche
`feat/v0.6.1-interface-des-ennemis` — [ADR-122](../_adr/ADR-122-un-combat-fini-ne-rouvre-aucun-tour.md)).

### 4.4. Système de Mort et de Stats Différé Z-Sync (Delayed Entity Destruction & Visual Stats Synchronization)

Pour éliminer la condition de concurrence visuelle (race condition) où l'état logique de Riverpod met à jour les statistiques (points de vie, armure, statuts) ou supprime instantanément un ennemi alors que l'animation de la carte Flame est encore en route, le jeu implémente le patron Z-Sync étendu aux attributs visuels :

1. **Drapeaux et Buffers de Verrouillage** :
   - `game.isCardAnimating` (booléen global) : Flag de verrouillage positionné à `true` dès qu'une carte jouée initie sa phase d'attaque ou de lancer d'effet.
   - `enemyCard.isPendingDeath` (booléen local) : Flag indiquant que l'ennemi a été tué logiquement mais que sa suppression visuelle est mise en attente.
   - `enemyCard._pendingVisualInstance` (modèle `EnemyInstance?` local) : Buffer stockant l'état des statistiques logiques reçues durant le trajet de la carte afin d'en différer l'affichage HUD.

2. **Diffèrement des Statistiques HUD & Effets d'Impact (`updateStats`)** :
   - Lors de la réception de nouvelles statistiques dans `EnemyCard.updateStats(newInstance)` :
     - Si `game.isCardAnimating == true`, la mise à jour de la barre de vie et de son voile d'armure (`EnemyHealthBar`, et le plein du voile, `ArmorVeil.nextPeak`), des languettes de statuts (`StatusTabs`) — `StatBadge` et `StatusIndicator` avant la vague 1 du bestiaire ([ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md)) — ainsi que **l'intégralité des effets visuels d'impact** (secousses `Curves.elasticOut`, flashes sprite `ColorEffect`, `FloatingText` de dégâts, et éjection de particules `spawnDamageParticles`) sont **différés** et stockés dans `_pendingVisualInstance`.
     - Si `game.isCardAnimating == false` (dégâts passifs comme le poison ou le Feu), les indicateurs et effets d'impact physiques sont appliqués et déclenchés immédiatement.

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

> [!NOTE]
> **Ce que `GameScreen` passe au jeu depuis la vague 2** (fusionnée dans `main` par la PR #62 — [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md)) : la table des cadres (`registry.tierFrames`) et le lieu courant (`currentLocationProvider`), lus une fois dans le registre chargé et reçus par le constructeur de `HerosDraftGame` ; Flame n'en lit aucun provider. Une carte d'ennemi naît avec le cadre de son tier et un fond de fenêtre tiré parmi ceux du lieu ; un tier sans cadre lève une `StateError`.
