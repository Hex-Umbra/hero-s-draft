## 7. Flux Complet d'un Tour de Combat

```
0. OUVERTURE DU COMBAT (une seule fois, depuis initState de GameScreen)
   └→ CombatController.startPlayerCombat()   [TurnPhaseManager]
       ├→ RunController.startCombat()
       │   ├→ Purge des statuts du combat précédent, mana = maxMana
       │   ├→ applyRelics(startOfCombat)
       │   └→ TraitSystem.onTurnStart(runController)   (ex: Berserker)
       └→ DeckNotifier.startCombat(handSize: cardsPerTurn, maxHandSize: 10)

1. DÉBUT TOUR JOUEUR
   └→ CombatController.startPlayerTurn()   [TurnPhaseManager]
       ├→ RunController.startTurn()
       │   ├→ Armure remise à 0, restore mana = maxMana
       │   ├→ applyRelics(startOfTurn)
       │   ├→ Process statuts: poison (dégâts), strength_regen (→strength), armor_regen (→armure)
       │   ├→ tickStatuses() (décrémente durées, supprime expirés)
       │   └→ TraitSystem.onTurnStart(runController)
       └→ DeckNotifier.drawCards(cardsPerTurn, maxHandSize: 10)
           └→ remélange à sec si la pioche se vide en cours de route

2. JOUEUR JOUE UNE CARTE
   └→ CombatController.applyPlayerCardPlay(card, runCtrl, deckNotif)
       ├→ EffectResolver.resolveCard() → consomme mana, applique effets (dégâts augmentés par shock/vulnerable, jet de coup critique pour dégâts/soins)
       ├→ DeckNotifier.playCard() → main → défausse (ou exhaust)
       ├→ TraitSystem.onCardPlayed(runCtrl, card)
       ├→ applyRelics(onCardPlayed)
       └→ _cleanDeadEnemies() → onEnemyKilled() → si ennemis actifs < 5 et réserve non vide, transfère le premier ennemi de pendingEnemies vers enemies et roule son intention.

3. FIN DE TOUR JOUEUR
   └→ Clic sur le bouton de fin de tour (GameScreen)
       ├→ Validation de confirmation (s'il reste du mana et que `_showRemainingManaWarning` est à false, l'avertissement de mana restant est affiché et le clic est intercepté)
       └→ Validation finale (si le mana est égal à 0 ou qu'il s'agit du second clic consécutif confirmant la fin de tour) :
           ├→ TraitSystem.onTurnEnd(ref.read(runProvider.notifier))
           ├→ ref.read(runProvider.notifier).applyRelics(RelicTrigger.endOfTurn)
           ├→ ref.read(deckProvider.notifier).discardHand()
           └→ HerosDraftGame.executeTurn()
               └→ _enemyRipostePhase()

4. PHASE ENNEMIE
   ├→ CombatController.startEnemyTurn()
   │   ├→ Pour chaque ennemi: process poison/regen/burn (Brûlure), tick statuts
   │   └→ _cleanDeadEnemies() (morts par poison ou brûlure, avec transfert de réserve si nécessaire)
   ├→ Pour chaque ennemi actif vivant:
   │   ├→ Animation (dash/buff)
   │   └→ resolveEnemyIntent() → dégâts héros (divisés par 2 si gelé, augmentés par vulnerable, jet de coup critique) / armure / strength
   └→ CombatController.endEnemyTurn()
       ├→ Re-roll toutes les intentions pour les ennemis actifs
       ├→ Phase → player
       └→ turnCount++

5. FIN DE COMBAT & TRANSITION DE VICTOIRE
   └→ _cleanDeadEnemies() détecte 0 ennemis
       ├→ isCombatEnded = true, isVictory = true
       └→ onEnemiesDead callback → UI (GameScreen) délègue la gestion des récompenses à RewardController :
           ├→ RewardController.handleVictory() : calcule l'XP et l'or de façon unifiée (scaling par niveau de monstre de +10% par niveau), et résout les tirages de reliques ou de cartes selon bossRewardType.
           ├→ Le joueur clique pour récupérer l'XP et l'or : RewardController.collectGoldAndXp()
           ├→ SI LEVEL UP : Déclenche l'affichage en plein écran de la bannière festive « LEVEL UP ! »
           │   └→ Redirection du joueur vers l'écran DraftScreen amélioré (sélection de récompense de niveau)
           ├→ SI BOSS/ELITE : Affichage séquentiel du carrousel de relique (collecte/skip gérés par RewardController)
           ├→ SI BOSS (type cards) : Affichage séquentiel du dialogue de draft de cartes (choix/skip gérés par RewardController)
           └→ Une fois isResolved = true : Déblocage du voyage et retour sur la carte du monde
```

> [!IMPORTANT]
> **Les étapes 0 et 1 appartiennent à `TurnPhaseManager`, pas à `GameScreen`.** Le widget
> ne fait qu'appeler les deux façades et animer le résultat. À l'intérieur de chacune,
> l'ordre `RunController` **puis** `DeckNotifier` est un invariant : l'inverser décalerait
> toute relique `startOfTurn` d'un tour entier. Voir
> [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).
