# Assainissement du Système de Cartes et de Pioche

**Date** : 31/07/2026
**Contexte** : Analyse du système de deck/pioche existant (`DeckNotifier`, `EffectResolver`, `TurnPhaseManager`, `LayoutSystem`) à la recherche d'améliorations. L'analyse a fait remonter douze constats, répartis en trois familles : bugs de règles, profondeur de gameplay manquante, et fuite de logique métier vers l'UI. Ce document couvre **uniquement la première et la troisième famille** — le socle de règles correctes et testables.
**Statut** : Brainstorm — conception fonctionnelle validée par échange, **rien encore implémenté**.
**Objectif retenu** : assainir les règles avant d'ajouter du contenu. Les mécaniques de profondeur (mots-clés de deck, effets interactifs, malédictions ennemies) dépendent toutes d'un moteur de piles fiable ; les construire sur les règles actuelles reviendrait à empiler sur un socle bancal.

---

## 1. État des lieux du système actuel

Cinq piles logiques dans `DeckState` (`lib/game/controllers/deck_controller.dart`) : `masterDeck`, `drawPile`, `hand`, `discardPile`, `exhaustPile`. État immuable, `copyWith`, sérialisation complète avec rapport de contenu manquant (`MissingSaveItem`).

Cycle de combat actuel :

| Moment | Appel | Emplacement |
|:---|:---|:---|
| Début de combat | `initializeCombat()` puis `drawCards(5)` | `game_screen.dart:275-276` |
| Début de tour | si `drawPile.length < 5` → `shuffleDiscardIntoDraw()`, puis `drawCards(5)` | `game_screen.dart:214-217` |
| Fin de tour | `discardHand()` | `game_screen.dart:504` |
| Carte jouée | `playCard()` → défausse, sauf `power` ou `isExhaust` → exhaust | `deck_controller.dart:177` |

La rune de forge `enduring:1` annule l'épuisement (`deck_controller.dart:188`).

## 2. Constats de la famille « règles »

### 2.1 `drawCards()` ne remélange jamais — échec silencieux

`deck_controller.dart:145` fait `min(amount, currentDrawPile.length)`. Une carte « Piocher 2 » jouée avec une pioche vide et quinze cartes en défausse **ne fait strictement rien**, sans erreur ni retour. Idem pour la rune de forge `quick` (`effect_resolver.dart:164-166`) et pour `DrawEffectStrategy` (`strategies.dart:120`).

C'est le défaut le plus grave : il rend trois cartes du pool et une rune non fiables de façon invisible pour le joueur comme pour le développeur.

### 2.2 Le seuil `< 5` détruit la lisibilité du cycle

Le remélange anticipé de `game_screen.dart:214` déclenche dès qu'il reste quatre cartes en pioche. Conséquence : les cartes défaussées au tour précédent peuvent revenir immédiatement, et le joueur ne peut jamais savoir ce qu'il lui reste à voir avant de recycler son deck.

Or « compter son deck » est la compétence centrale d'un deckbuilder : c'est ce qui transforme la pioche d'un jet de dés en une information exploitable. La convention du genre (Slay the Spire, Monster Train) est de remélanger **uniquement quand la pioche est vide**, y compris au milieu d'une pioche.

### 2.3 Aucune limite de taille de main

Rien ne borne `hand`. Le rendu en éventail (`layout_system.dart:8-17`) compresse l'angle via `angleStep` clampé à `0.04`, mais finira par superposer les cartes. Aucune règle de jeu ne traite le débordement.

### 2.4 Mélange non déterministe

`shuffle(Random())` (`deck_controller.dart:130` et `159`) instancie un `Random` neuf à chaque appel. Aucun test de séquence de pioche n'est écrivable de façon fiable, ce qui explique que `test/unit/deck_controller_test.dart` ne couvre pas les règles de tour.

### 2.5 Code mort lié au deck

| Élément | Sites | État |
|:---|:---|:---|
| `CardInstance.temporaryCost` | `card_instance.dart:9,16,23,47,55,65,74` | Champ déclaré, sérialisé et lu par `currentCost`, mais **jamais écrit** nulle part |
| `IntentType.debuffDeck` | `enemy_intent.dart:1`, `turn_phase_manager.dart:110`, `model_extensions.dart:108`, `enemy_intents_panel.dart:129` | `case debuffDeck: break;` — aucun effet. Aucun ennemi de `enemies.json` ne l'utilise |
| `onEnemyDebuffDeck` | `heros_draft_game.dart:57,76`, `game_screen.dart:281` | Callback `required`, **jamais invoqué**. Corps vide avec commentaire « Logique retirée » |

Le `CLAUDE.md` interdit explicitement le code mort. Ces éléments sont les vestiges d'une fonctionnalité « l'ennemi pollue ton deck » abandonnée en cours de route — elle reviendra comme chantier à part entière (voir §8).

## 3. Constats de la famille « architecture »

### 3.1 La règle de pioche vit dans un widget

`_startPlayerNewTurn` (`game_screen.dart:204-218`) contient le nombre de cartes piochées, le seuil de remélange et l'appel de remélange. C'est de la logique métier dans une couche UI, ce que le `CLAUDE.md` proscrit — et c'est la cause directe de l'absence de couverture de tests sur la règle de tour.

`TurnPhaseManager` ne modélise aujourd'hui que la phase **ennemie** (`startEnemyTurn`, `endEnemyTurn`, `resolveEnemyIntent`). La moitié joueur du cycle manque.

### 3.2 `_turnCount` double `combatState.turnCount`

`game_screen.dart:63` déclare un `int _turnCount = 1`, incrémenté en `setState` (`:208`) et affiché par `TurnControlPanel` (`:509`). En parallèle, `CombatState.turnCount` existe, est incrémenté par `turn_phase_manager.dart:47`, et est **sérialisé** (`combat_state.dart:88,100`).

Bug qui en découle : une partie sauvegardée en plein combat puis rechargée restaure `combatState.turnCount` correctement, mais `_turnCount` — simple champ de `State` — repart à `1`. Le HUD affiche alors « Tour 1 » sur un combat au tour 7.

### 3.3 Deck de secours codé en dur dans l'UI

`game_screen.dart:227-248` construit un deck de cinq cartes fixes (`strike_basic`, `defend_basic`, `demon_form`, `metallicize`, `poison_stab`) si `masterDeck` est vide — **indépendamment de la classe du héros**. `StarterDeckDraftScreen` (`starter_deck_draft_screen.dart:108`) est le seul chemin légitime d'initialisation.

---

## 4. Conception retenue

### 4.1 Répartition des responsabilités

Une seule règle structurante : **`DeckNotifier` garantit les invariants de piles, `TurnPhaseManager` décide quand.** Le widget n'appelle et n'anime plus que.

```
game_screen._startPlayerNewTurn()
   └─> combatController.startPlayerTurn()          ← nouveau point d'entrée
         ├─ runController.startTurn()               (mana, statuts, reliques — inchangé)
         └─ deckController.drawCards(5, maxHandSize: …)
                └─ remélange à sec + débordement, en interne
```

`endEnemyTurn()` conserve la transition de phase et l'incrément de `turnCount` — aucun changement de comptage des tours.

### 4.2 Le cœur : `drawCards`

```dart
void drawCards(int amount, {required int maxHandSize}) {
  final draw = [...state.drawPile];
  final hand = [...state.hand];
  final discard = [...state.discardPile];

  for (var i = 0; i < amount; i++) {
    if (draw.isEmpty) {
      if (discard.isEmpty) break;        // deck épuisé : on s'arrête proprement
      draw..addAll(discard)..shuffle(_random);
      discard.clear();                    // remélange À SEC, au milieu de la pioche
    }
    final card = draw.removeLast();
    if (hand.length >= maxHandSize) {
      discard.add(card);                  // débordement : la carte est consommée
    } else {
      hand.add(card);
    }
  }

  state = state.copyWith(drawPile: draw, hand: hand, discardPile: discard);
}
```

Trois propriétés à souligner :

- **Une seule affectation de `state`** en fin de méthode. Aujourd'hui, un remélange suivi d'une pioche produit deux notifications Riverpod, donc deux passes de `_applyDeckState` (`state_sync_system.dart:66`) et deux appels à `layoutHand()` — l'éventail se réanime deux fois. Le nouveau code n'en déclenche qu'une.
- `shuffleDiscardIntoDraw()` devient **privé**. Plus aucun appelant externe : la règle cesse d'être optionnelle et ne peut plus être oubliée par un futur appelant.
- `initializeCombat({required int maxHandSize})` absorbe la main d'ouverture. Le `drawCards(5)` séparé de `game_screen.dart:276` disparaît, et la main de départ respecte exactement les mêmes invariants que toutes les pioches suivantes.

**Propagation du changement de signature** — trois appelants existants de `drawCards` doivent transmettre `maxHandSize` :

| Appelant | Accès à la statistique |
|:---|:---|
| `DrawEffectStrategy` (`strategies.dart:120`) | Via le paramètre `runController` déjà présent dans `resolve` |
| Rune de forge `quick` (`effect_resolver.dart:165`) | Via le `runController` déjà présent dans `resolveCard` |
| `game_screen.dart:217,276` | Disparaît — remplacé par `startPlayerTurn()` et `initializeCombat()` |

Aucun de ces appelants n'a besoin d'un nouvel argument injecté depuis l'extérieur : `RunController` est déjà dans leur portée.

**Règle de débordement retenue** : la carte en excès **part à la défausse**, elle n'est pas laissée dans la pioche. Elle est donc bien consommée, ce qui préserve l'exactitude du cycle de deck et rend un effet « Piocher 3 » prévisible. C'est aussi ce qui donne sa valeur à la relique de §4.3 : sans consommation, augmenter la limite de main n'apporterait rien.

### 4.3 `maxHandSize` comme statistique de run

Valeur de base **10**, augmentable par relique.

- Nouveau champ `EntityStats.maxHandSize` (`entity_stats.dart`), désérialisé en `json['maxHandSize'] as int? ?? 10` — les sauvegardes existantes se rechargent sans migration.
- `applyHeroStatModifier(maxHandSizeAcc:)` et un `case 'increase_hand_size'` dans `applyRelicEffect` (`player_stats_manager.dart:179`), sur le trigger `startOfRun`. C'est exactement le motif déjà employé par `gain_mana` (`:181-183`) et `gain_luck` (`:218-220`) — aucun mécanisme nouveau à inventer.
- Une entrée dans `assets/data/relics.json`, bilingue `_fr`/`_en` comme l'impose le `CLAUDE.md`.

**Rareté proposée : `rare`, valeur `2`.** Le raisonnement : c'est une relique à effet conditionnel, nulle dans un deck agressif compact et forte dans un deck à forte pioche. Ce profil « inutile ou décisif selon le build » correspond à ce que sont les `rare` du pool actuel, alors que les `common` sont des filets de statistiques constants. En `common` elle serait un blanc fréquent ; en `legendary` elle serait décevante. **À confirmer au moment de l'implémentation.**

Effet de bord notable : ce serait la **première relique du jeu à interagir avec le deck**. Sur les 24 reliques actuelles, les effets se limitent à `gain_armor`, `gain_mana`, `gain_crit`, `gain_luck`, `gain_strength`, `heal` et quatre variantes à charges — aucune ne touche à la pioche, à la main ou à la défausse.

### 4.4 Aléatoire injectable

```dart
final deckRandomProvider = Provider<Random>((ref) => Random());
```

Lu par `DeckNotifier` dans `build()`. En jeu, comportement identique à aujourd'hui. En test, `overrideWithValue(Random(42))` rend chaque séquence de pioche reproductible — c'est la condition d'existence de la couverture décrite en §5.

Cette injection reste volontairement minimale : pas de seed persisté ni de seed partageable. Ces deux évolutions restent possibles plus tard sans changer le point d'injection.

### 4.5 Suppression du code mort

| Élément | Traitement |
|:---|:---|
| `CardInstance.temporaryCost` et `clearTemporaryCost` | Supprimés. Le getter `currentCost` **reste** (6 sites d'appel : `ui_card.dart:65`, `card_component.dart:54,320`, `card_text_renderer.dart:671`, `effect_resolver.dart:98,123`) et devient `=> data.cost` |
| `IntentType.debuffDeck` | Supprimé de l'enum et de ses 3 sites de `switch` |
| `onEnemyDebuffDeck` | Supprimé de `HerosDraftGame` et de son site d'instanciation |
| Deck de secours codé en dur | Supprimé de `game_screen.dart:227-248` |

### 4.6 Déduplication de `_turnCount`

Suppression du champ `_turnCount` (`game_screen.dart:63`) et de son incrément (`:208`). `TurnControlPanel` est alimenté par `combatState.turnCount` (`:509`), qui est déjà lu dans le `build` de l'écran. Corrige au passage l'affichage « Tour 1 » sur une partie rechargée en plein combat (§3.2).

## 5. Couverture de tests visée

C'est l'aboutissement du chantier : ces tests sont précisément ceux que le système actuel ne permet pas d'écrire.

1. **Remélange à sec au milieu d'une pioche** — pioche 3, défausse 7, on pioche 5 → main 5, pioche 5, défausse 0.
2. **Deck totalement épuisé** — pioche et défausse vides, `drawCards(3)` → main inchangée, aucune exception.
3. **Débordement** — main à `maxHandSize`, on pioche → la carte atterrit en défausse, jamais perdue.
4. **Invariant de conservation** — `masterDeck.length == drawPile + hand + discardPile + exhaustPile` après chaque opération. C'est le test qui attrapera toute régression future, y compris celles des chantiers de §8.
5. **Déterminisme** — seed fixe → ordre de pioche reproductible entre deux exécutions.
6. **Relique de taille de main** — `maxHandSize` augmenté, seuil de débordement décalé d'autant.

**Test existant à réécrire** : `test/unit/deck_controller_test.dart:77-119` appelle `shuffleDiscardIntoDraw()` directement. La méthode devenant privée, ce test doit passer par `drawCards`.

## 6. Effort & risque

- **Code : moyen.** Une méthode réécrite (`drawCards`), une méthode ajoutée (`TurnPhaseManager.startPlayerTurn`), un champ de statistique, un `case` de relique, un provider, et quatre suppressions. Aucun nouveau fichier.
- **Risque principal : régression de flux de combat.** Déplacer la pioche hors du widget touche le chemin le plus emprunté du jeu. L'ordre relatif de `runController.startTurn()` (qui déclenche les reliques `startOfTurn` et le traitement des statuts) et de la pioche doit être préservé à l'identique, sous peine de décaler des effets de reliques d'un tour.
- **Risque secondaire : rééquilibrage implicite.** Le passage du seuil `< 5` au remélange à sec **change la difficulté ressentie** — le joueur voit ses bonnes cartes moins souvent en début de combat, et son deck devient plus prévisible en fin de combat. À évaluer en jeu, potentiellement conjointement avec les documents d'échelonnement de difficulté existants.
- **Risque faible : compatibilité des sauvegardes.** Le `?? 10` sur `maxHandSize` et la suppression de `temporaryCost` (champ optionnel à la lecture) sont tous deux rétrocompatibles. Une sauvegarde contenant `temporaryCost` verra simplement la clé ignorée.

## 7. Points ouverts

- Confirmer la rareté et la valeur de la relique de taille de main (`rare` / `2` proposés) au moment de la rédiger dans `relics.json`.
- Faut-il un retour visuel du remélange (animation de la défausse repartant vers la pioche) ? Le moment devient significatif pour le joueur alors qu'il était noyé auparavant. Relève du chantier « ressenti », mais la donnée est produite ici.
- Le débordement de main mérite-t-il une notification (`NotificationOverlay`) ? Une carte qui part directement à la défausse sans passer par la main est actuellement invisible.

## 8. Ce que ce chantier rend possible (hors scope)

L'analyse initiale avait remonté cinq axes de profondeur, tous écartés de ce document mais tous dépendants de son socle :

1. **Mots-clés de deck** — Rétention, Innée, Éphémère, coût variable. Aucun n'existe aujourd'hui ; le seul modificateur est `isExhaust`. Le champ `temporaryCost` supprimé ici serait à réintroduire *avec* son mécanisme le jour où le coût variable sera implémenté.
2. **Effets interactifs** — « défausser une carte pour… », « épuiser une carte de la main », « remonter une carte de la défausse ». Bloqués par le contrat de `EffectStrategy` (`effect_strategy.dart:9-19`), dont la signature ne prend aucune entrée utilisateur. C'est le vrai verrou architectural de la profondeur.
3. **Reliques liées au deck** — la relique de taille de main de §4.3 ouvre la voie ; « +1 pioche par tour », « commence le combat avec X en main » suivent le même motif.
4. **Élargissement du pool** — 17 cartes globales + 6 cartes de héros = **23 cartes**, pour 6 types d'effets seulement (`damage`, `heal`, `armor`, `gain_mana`, `draw`, `apply_status`). Le registre de stratégies est propre et extensible, mais très sous-exploité.
5. **Malédictions ennemies** — reconstruire proprement ce que `IntentType.debuffDeck` promettait. `CardType.status` existe déjà et est correctement bloqué au jeu par `canPlayCard` (`effect_resolver.dart:101-103`), et `addCardToDiscardPile` (`deck_controller.dart:319`) est le point d'injection tout prêt. Figure déjà au backlog archivé (`docs/archives/backlog_and_roadmap_report_22072026.md`, section « Diversification des Intentions »).

Un sixième axe, purement UI, reste également ouvert : les panneaux latéraux (`combat_side_panels.dart`) n'affichent que des compteurs de pioche et de défausse. Aucune consultation du contenu des piles n'est possible, ce qui prive le joueur d'information au moment de décider.

## 9. Prochaines étapes possibles

1. Rédiger le plan d'implémentation détaillé de ce document.
2. Implémenter en menant les tests de §5 en amont — c'est la seule façon de valider que le remélange à sec se comporte comme attendu avant de brancher le flux de combat dessus.
3. Jouer plusieurs combats complets pour évaluer l'impact réel du changement de règle de remélange sur la difficulté ressentie (§6), avant de considérer le chantier clos.
4. Trancher ensuite l'ordre des axes de §8 — le verrou de `EffectStrategy` (axe 2) conditionne les axes 1 et 5, et mérite probablement d'être traité en premier.
