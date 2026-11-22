## 7. Flux Complet d'un Tour de Combat

```
0. OUVERTURE DU COMBAT (une seule fois, depuis initState de GameScreen)
   └→ CombatController.startPlayerCombat()   [TurnPhaseManager]
       ├→ RunController.startCombat()
       │   ├→ Purge des statuts du combat précédent, mana = maxMana, manaReserve = 0
       │   ├→ applyRelics(startOfCombat)
       │   └→ TraitSystem.onTurnStart(runController)   (ex: Berserker)
       └→ DeckNotifier.startCombat(handSize: cardsPerTurn, maxHandSize: RunState.maxHandSize)

1. DÉBUT TOUR JOUEUR
   └→ CombatController.startPlayerTurn()   [TurnPhaseManager]
       ├→ RunController.startTurn()
       │   ├→ Armure remise à 0, mana = maxMana + manaReserve, puis manaReserve = 0
       │   ├→ applyRelics(startOfTurn)
       │   ├→ Process statuts: Feu d'abord (ChargeRules.resolveOwnFire — sa part seule, sans explosion),
       │   │   puis poison (dégâts), might_regen (→might), armor_regen (→armure), mana_regen (→mana)
       │   ├→ tickStatuses(charges.ids) (décrémente durées, supprime expirés — les charges exemptes)
       │   ├→ hp_regen (→PV, vague 8) : la Source de Vie, sommée avant le tic, rendue après lui,
       │   │   bornée aux PV max, rien si le Feu ou le poison viennent de tuer le porteur
       │   ├→ ChargeRules.decay, puis startBearerTurn : un gel du héros « en attente » passe « actif »
       │   └→ TraitSystem.onTurnStart(runController)
       └→ DeckNotifier.drawCards(cardsPerTurn, maxHandSize: RunState.maxHandSize)
           └→ remélange à sec si la pioche se vide en cours de route

2. JOUEUR JOUE UNE CARTE
   └→ CombatController.applyPlayerCardPlay(card, runCtrl, deckNotif)
       ├→ EffectResolver.resolveCard() → consomme mana, applique effets (dégâts par DamagePipeline : Foudre et
       │   vulnerable du défenseur, gel du héros, jet de coup critique) ; une charge posée passe par
       │   ChargeRules.pose — le Gel et la Foudre peuvent rompre aussitôt ; chaque coup note son bonus de Foudre
       ├→ DeckNotifier.playCard() → main → défausse (ou exhaust)
       └→ _afterCardPlayed(card, enemyId:) — la suite commune :
           ├→ TraitSystem : onCardPlayed, puis l'événement du type, puis onDamagingCardPlayed si
           │   card.effective.dealsDamage (vague 8 — Marque du Mage, son seul lecteur)
           ├→ applyRelics(onCardPlayed), puis l'événement du type (jamais onDamagingCardPlayed)
           └→ _cleanDeadEnemies() → onEnemyKilled() → si ennemis actifs < 5 et réserve non vide, transfère le premier ennemi de pendingEnemies vers enemies et roule son intention.

2 bis. JOUEUR JOUE UNE SIGNATURE (vague 4 — ADR-109)
   └→ SignatureBar → GameScreen._playSignature(signature, enemyId:) — une signature à cible
      unique s'arme d'abord, et l'ennemi arrive par onSelectEnemy (_patterns/04-00)
       └→ CombatController.playSignature(signature, enemyId:)
           ├→ refus sans effet : tour ennemi, combat fini, pas prête, pas de cible, mana
           ├→ EffectResolver.resolveCard(signature.asCard) → consomme mana, applique effets
           ├→ signaturesReadyOn[id] = turnCount + cooldown — aucune pile touchée
           └→ _afterCardPlayed(card, enemyId:) — la même suite que la carte

3. FIN DE TOUR JOUEUR
   └→ Clic sur le bouton de fin de tour (GameScreen)
       ├→ Validation de confirmation (s'il reste du mana et que `_showRemainingManaWarning` est à false, l'avertissement de mana restant est affiché et le clic est intercepté)
       └→ Validation finale (si le mana est égal à 0 ou qu'il s'agit du second clic consécutif confirmant la fin de tour) :
           ├→ TraitSystem.onTurnEnd(ref.read(runProvider.notifier))
           │   └→ sous Canalisation : ManaReservePassive → RunController.setManaReserve(banked)
           ├→ ref.read(runProvider.notifier).applyRelics(RelicTrigger.endOfTurn)
           ├→ ref.read(deckProvider.notifier).discardHand()
           └→ HerosDraftGame.executeTurn()
               └→ _enemyRipostePhase()

4. PHASE ENNEMIE
   ├→ CombatController.startEnemyTurn() → bool   [vague 7 : la phase ennemie s'ouvre en trois temps]
   │   ├→ fermeture du tour du joueur : toute Foudre chargée à 0, le gel actif du héros prend fin
   │   └→ vague 1 de la chaîne du Feu : tous les porteurs vivants se résolvent ensemble,
   │       compte rendu dans CombatState.fireWaveReport ; vrai si une vague s'est jouée
   ├→ tant que vrai : délai combatDelayFireWaveMs (800 ms), l'onde animée par StateSyncSystem →
   │   CombatVisualSystem.playFireWave, puis CombatController.resolveNextFireWave() — la vague
   │   suivante, formée du seul Feu que la précédente a posé ; faux et compte rendu effacé à la fin
   ├→ CombatController.resolveEnemyStatuses()
   │   ├→ Pour chaque ennemi : poison/regen, tick statuts (charges exemptes), Source de Vie
   │   │   (symétrique, vague 8 — aucun ennemi n'en pose), déclins des charges
   │   └→ _cleanDeadEnemies() — une seule fois, les morts de la chaîne compris
   ├→ Pour chaque ennemi actif vivant :
   │   ├→ gelé (EnemyInstance.skipsAction) → frozenTurnAnimation, puis resolveEnemyIntent() consomme
   │   │   le gel sans rien résoudre
   │   ├→ sinon Animation (dash/buff)
   │   └→ resolveEnemyIntent() → dégâts héros (DamagePipeline : Foudre du héros, vulnerable, jet de coup critique) / armure / strength
   └→ CombatController.endEnemyTurn()
       ├→ fermeture de la phase ennemie : toute Foudre chargée à 0 (un gel du héros « en attente » reste)
       ├→ Re-roll toutes les intentions pour les ennemis actifs (l'intention perdue d'un gelé est consommée)
       ├→ Phase → player
       └→ turnCount++

5. FIN DE COMBAT & TRANSITION DE VICTOIRE
   └→ _cleanDeadEnemies() détecte 0 ennemis
       ├→ isCombatEnded = true, isVictory = true
       └→ onEnemiesDead callback → UI (GameScreen) délègue la gestion des récompenses à RewardController :
           ├→ RewardController.handleVictory() : calcule l'XP et l'or de façon unifiée (scaling par niveau de monstre de +10% par niveau), et résout les tirages de reliques ou de cartes selon bossRewardType — et, vague 3, la trouvaille (foundCards) d'un combat normal ou d'une élite.
           ├→ Le joueur clique pour récupérer l'XP et l'or : RewardController.collectGoldAndXp()
           │   └→ vague 3 : cartes trouvées ajoutées au deck ; boss « XP » : runes montées (sharpenedRunes) ;
           │      une notification par carte et par rune, NotificationNotifier.maxVisible = 5 (4 avant)
           ├→ SI LEVEL UP : Déclenche l'affichage en plein écran de la bannière festive « LEVEL UP ! »
           │   └→ Redirection du joueur vers l'écran DraftScreen amélioré (sélection de récompense de niveau)
           ├→ SI BOSS/ELITE : Affichage séquentiel du carrousel de relique (collecte/skip gérés par RewardController)
           ├→ SI BOSS (type cards) : Affichage séquentiel du dialogue de draft de cartes (choix/skip gérés par RewardController)
           └→ Une fois isResolved = true : Déblocage du voyage et retour sur la carte du monde
```

> [!NOTE]
> **La réserve de mana traverse la phase ennemie sans bouger** (vague 6, fusionnée
> dans `main` le 2026-11-15 — [ADR-116](../_adr/ADR-116-canalisation-une-banque-de-mana.md)).
> Écrite à l'étape 3 par la seule stratégie de *Canalisation*, elle est lue une fois à l'étape 1
> suivante, avant les reliques et les statuts, sans passer par `StatGains`. Un mana gagné pendant la
> phase 4 (*Essence spirituelle* sur un ennemi tué par le poison) n'y entre pas ; l'écran, dès la
> bannière « Tour ennemi », lit la réserve écrite (`ManaReserve.shown`). Un combat qui finit en
> phase 4 la laisse à `startCombat`, qui la vide.

> [!NOTE]
> **La phase ennemie lit l'état avant d'animer** (vague 7, fusionnée dans `main` le 2026-11-18 par la PR #55 —
> [ADR-117](../_adr/ADR-117-les-charges-elementaires.md)). Le contrôleur joue la chaîne du Feu
> une vague à la fois et Flame l'appelle (`HerosDraftGame._enemyRipostePhase` : `onStartEnemyTurn`,
> `onResolveFireWave`, `onResolveEnemyStatuses`) ; l'ennemi gelé se lit sur `skipsAction` **avant**
> que Flame lance son action, si bien qu'il ne fonce jamais. Aucune règle ne se calcule dans Flame.
> **Un combat fini ne rouvre aucun tour** (S9, sur la branche `feat/v0.6.1-interface-des-ennemis`
> — [ADR-122](../_adr/ADR-122-un-combat-fini-ne-rouvre-aucun-tour.md)). Flame joue encore la phase
> ennemie jusqu'au bout, mais `endEnemyTurn` (étape 4) et `startPlayerTurn` (étape 1) ne font rien
> dès qu'un camp a perdu — `isCombatEnded`, ou le héros mort (`RunState.isDead`) : ni intentions,
> ni statuts, ni pioche, ni `turnCount`. Sur `main`, la phase se joue encore après une victoire
> constatée par les statuts (compte rendu de la vague 7, §4).

> [!IMPORTANT]
> **Les étapes 0 et 1 appartiennent à `TurnPhaseManager`, pas à `GameScreen`.** Le widget
> ne fait qu'appeler les deux façades et animer le résultat. À l'intérieur de chacune,
> l'ordre `RunController` **puis** `DeckNotifier` est un invariant : l'inverser décalerait
> toute relique `startOfTurn` d'un tour entier. Voir
> [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md). La borne de
> main passée aux deux pioches est `RunState.maxHandSize` depuis la vague 3, et non
> plus la constante 10 ([ADR-107](../_adr/ADR-107-trouvaille-et-progression.md)).
