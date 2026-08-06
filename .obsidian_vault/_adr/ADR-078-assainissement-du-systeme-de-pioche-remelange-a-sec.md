### Statut

✅ **Livré le 2026-08-06** — branche `feat/p02-assainissement-pioche`, 8 commits TDD.
Chantier **P-02** de `docs/ROADMAP.md` (Tier S). Conception :
`docs/superpowers/specs/2026-08-04-p02-assainissement-pioche-design.md`.

### Contexte

Sept défauts distincts partageaient la même racine : le moteur de pioche n'avait pas de
propriétaire clair, et la règle de tour vivait dans un widget.

| Défaut | Manifestation |
|:---|:---|
| Pioche silencieusement tronquée | `drawCards` faisait `min(amount, drawPile.length)` : une carte « Piocher 2 » sur une pioche vide ne faisait **rien**, sans erreur ni signal |
| Remélange optionnel et prématuré | `shuffleDiscardIntoDraw()` était appelée par `game_screen.dart` sur un seuil `if (drawPile.length < 5)`, donc presque chaque tour — la défausse revenait avant d'être méritée |
| Aucune limite de main | Rien n'empêchait une main de croître indéfiniment |
| Mélange non injectable | `shuffle(Random())` en dur × 2 : toute assertion sur une séquence de pioche était inécrivable |
| Règle de tour dans l'UI | `_GameScreenState._startPlayerNewTurn()` portait l'ordre `startTurn()` → pioche, et le tour 1 suivait un chemin **différent** du tour N+1 |
| Compteur de tour dupliqué | `_turnCount` (champ de widget) doublait `CombatState.turnCount` |
| Code mort | `temporaryCost`, `IntentType.debuffDeck`, `intentCurse`, `onEnemyDebuffDeck`, `onTurnEnded`, deck de secours codé en dur |

Le seuil `< 5` était le plus coûteux en jeu : il détruit la capacité à compter son deck,
compétence centrale du genre.

### Décision

**1. Remélange à sec.** La défausse rejoint la pioche **uniquement** quand celle-ci est
vide, y compris au milieu d'une pioche. `shuffleDiscardIntoDraw()` est supprimée : la
règle cesse d'être optionnelle.

**2. Arrêt net sur main pleine.** Quand la main atteint `maxHandSize`, la pioche
s'interrompt **sans consommer de carte ni déclencher de remélange**.

> [!IMPORTANT]
> L'alternative envisagée — consommer la carte et l'envoyer en défausse — a été écartée.
> Elle aurait permis à une main pleine sur pioche vide de déclencher un remélange complet
> du deck pour ne rien donner au joueur, ruinant précisément la capacité à compter son
> deck que ce chantier restaure. L'ordre des deux tests d'arrêt dans `_drawInto` porte
> cette décision : main pleine **avant** pioche vide.

**3. `maxHandSize` est une constante, pas une statistique.** `GameConstants.maxHandSize = 10`.
La conception initiale en faisait une statistique modifiable par relique ; l'arithmétique
du deck actuel montre que 10 est inatteignable en jeu, une telle relique aurait donc été
statistiquement invisible.

**4. `cardsPerTurn` devient une règle de run.** `RunState.cardsPerTurn` (défaut 5),
mutée par `applyRunRuleModifier`. Elle n'est **pas** posée sur `EntityStats`, partagé
avec les ennemis, qui n'ont pas de deck. C'est cette statistique, et non `maxHandSize`,
que cible la relique livrée avec le chantier.

**5. Aléatoire injectable.** `deckRandomProvider` (`Provider<Random>`), surchargeable en
test par `overrideWithValue(Random(42))`. `DeckState.reshuffleCount` rend l'événement
observable — il sert à la fois d'assertion de test et de déclencheur de notification.

**6. La règle de tour rejoint `TurnPhaseManager`.** `startPlayerCombat()` et
`startPlayerTurn()` complètent la moitié joueur du cycle, symétriques de
`startEnemyTurn()` / `endEnemyTurn()` déjà présentes. `game_screen.dart` n'anime plus que.
Le tour 1 et le tour N+1 empruntent désormais le même code.

> [!IMPORTANT]
> L'ordre `runController.startTurn()` **puis** pioche est un invariant. L'inverser
> décalerait toute relique `startOfTurn` d'un tour entier.

**7. Suppression du code mort.** Les six éléments listés ci-dessus, vérifiés sans
consommateur par `grep` sur `lib/` et `test/` avant et après.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Cœur pur de la pioche | `DeckNotifier._drawInto` (`lib/game/controllers/deck_controller.dart`) — retourne un record `({draw, hand, discard, reshuffles})` |
| Pioche publique | `DeckNotifier.drawCards(int amount, {required int maxHandSize})` — une seule affectation de `state`, donc une seule notification Riverpod |
| Main d'ouverture | `DeckNotifier.startCombat({required int handSize, required int maxHandSize})` — remplace `initializeCombat()` + `drawCards(5)` |
| Plafond de main | `GameConstants.maxHandSize` (`lib/game/game_constants.dart`) |
| Règle de run | `RunState.cardsPerTurn`, `RunController.applyRunRuleModifier` (`lib/game/controllers/run_controller.dart`), `PlayerStatsManager.applyRunRuleModifier` |
| Moitié joueur du cycle | `TurnPhaseManager.startPlayerCombat` / `.startPlayerTurn` (`lib/game/controllers/combat/turn_phase_manager.dart`) |
| Aléatoire injectable | `deckRandomProvider` (bas de `deck_controller.dart`) |
| Relique | `scholars_satchel` dans `assets/data/relics.json`, `case 'increase_cards_per_turn'` **symétrique** dans `applyRelicEffect` et `removeRelicEffect` |
| Tests | `test/unit/deck_controller_test.dart` (12), `test/unit/combat_controller_test.dart`, `test/unit/relic_exchange_test.dart`, `test/unit/run_controller_test.dart`, `test/unit/run_state_persistence_test.dart` |

### Conséquences

**Acquis**

- Les cartes de pioche et la rune `quick` fonctionnent enfin sur pioche vide.
- L'invariant de conservation `masterDeck == draw + hand + discard + exhaust` est
  désormais asserté à chaque test du moteur.
- La règle de tour est testable sans widget : **+18 tests neufs, 2 réécrits**
  (212 → 230 au vert). La ROADMAP en annonçait 6.
- `removeRelicEffect` est symétrique dès le premier `effectType` touchant au deck :
  l'Autel d'Échange ne peut pas laisser fuiter le bonus.

**Coûts assumés**

- **La difficulté ressentie change.** Le passage du seuil `< 5` au remélange à sec fait
  revoir les bonnes cartes moins souvent en début de combat et rend l'ordre du deck plus
  prévisible en fin de combat. C'est un effet voulu, non mesuré automatiquement, et la
  raison pour laquelle **P-16 doit venir après P-02** (`docs/ROADMAP.md` §Jalon 3).
- **Le plafond de 10 cartes ne se déclenche pas en jeu aujourd'hui.** C'est un garde-fou
  pour les mots-clés de deck à venir (B18/B19/B20), pas une contrainte perceptible.
- L'ordre `startTurn()` → pioche n'est pas directement observable avec les effets
  existants ; il est protégé structurellement (un seul site d'appel) et par commentaire,
  pas par une assertion.

### Voir aussi

- Règle de jeu : [../\_rules/03-4-systeme-de-piles-de-cartes.md](../_rules/03-4-systeme-de-piles-de-cartes.md)
- Pattern : [../\_patterns/02-3-decknotifier-maitre-du-deck.md](../_patterns/02-3-decknotifier-maitre-du-deck.md)
- Flux de tour : [../\_patterns/07-00-flux-complet-d-un-tour-de-combat.md](../_patterns/07-00-flux-complet-d-un-tour-de-combat.md)
