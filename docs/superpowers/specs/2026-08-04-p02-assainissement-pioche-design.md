# P-02 — Assainissement du système de pioche — Conception

Date : 2026-08-04
Statut : **Design validé, non implémenté**
Chantier ROADMAP : **P-02**, Tier S (`docs/ROADMAP.md` §2)
Source amont : `docs/possible_upgrades/31-07-2026_systeme_pioche_assainissement_Opus5.md` (brainstorm du 31/07)

> Ce document **remplace** le brainstorm du 31/07 comme référence de conception. Il en reprend
> le diagnostic — re-vérifié contre le code le 2026-08-04, constat par constat — mais s'en écarte
> sur **quatre décisions** : la règle de débordement de main, la nature de la relique livrée,
> l'emplacement de la statistique associée, et l'étendue de la reprise du flux de tour 1.
> Les écarts sont justifiés en §9.

---

## 1. Vérification préalable

La ROADMAP impose qu'une fiche non re-mesurée depuis plus d'une semaine soit re-vérifiée contre
le code avant d'être ouverte (`docs/ROADMAP.md` §10.4). Contrôle effectué le 2026-08-04 :
**les douze constats du brainstorm tiennent intégralement, numéros de ligne inclus.**

| Constat | Vérification |
|:---|:---|
| `drawCards` ne remélange jamais | `lib/game/controllers/deck_controller.dart:145` — `min(amount, currentDrawPile.length)` |
| Seuil de remélange `< 5` dans l'UI | `lib/ui/screens/game_screen.dart:214` |
| Aucune limite de taille de main | Aucune occurrence dans `lib/` |
| Mélange non déterministe | `deck_controller.dart:130` et `:159` — `shuffle(Random())` |
| `CardInstance.temporaryCost` jamais écrit | Grep `lib/` + `test/` : uniquement les 7 sites de `card_instance.dart` |
| `IntentType.debuffDeck` sans effet | `enemy_intent.dart:1`, `turn_phase_manager.dart:110`, `model_extensions.dart:108`, `enemy_intents_panel.dart:129` |
| `onEnemyDebuffDeck` jamais invoqué | `heros_draft_game.dart:57,76` + `game_screen.dart:281` |
| `_turnCount` double `combatState.turnCount` | `game_screen.dart:63,208,509` vs `combat_state.dart:88,100` |
| Deck de secours codé en dur | `game_screen.dart:227-248` |

**Un constat supplémentaire, absent du brainstorm** : `onTurnEnded` (`heros_draft_game.dart:58,77`
+ `game_screen.dart:284`) est un **second callback `required` jamais invoqué**. Le flux réel passe
par `onEndEnemyTurn` (`game_screen.dart:370`), qui appelle `_startPlayerNewTurn` lui-même.

**Une asymétrie non relevée par le brainstorm, structurante pour la solution** : le tour 1 et les
tours suivants n'empruntent pas le même chemin, et c'est légitime — `RunController.startCombat()`
(`run_controller.dart:378`) déclenche les reliques `startOfCombat`, `RunController.startTurn()`
(`:393`) déclenche les `startOfTurn`.

```
Tour 1   : microtask initState → runController.startCombat()
                               → combatController.initializeCombat()   (génération d'ennemis)
                               → deck.initializeCombat() → deck.drawCards(5)
Tour N+1 : onEndEnemyTurn      → combatController.endEnemyTurn()
                               → _startPlayerNewTurn() → runController.startTurn()
                               → remélange si < 5 → drawCards(5)
```

---

## 2. Ce que le chantier corrige

1. **Trois cartes du pool et une rune sont silencieusement non fiables.** Une carte « Piocher 2 »
   jouée avec une pioche vide et quinze cartes en défausse ne fait *rien*, sans erreur ni retour.
   Idem pour la rune de forge `quick` (`effect_resolver.dart:165`) et `DrawEffectStrategy`
   (`strategies.dart:120`).
2. **Le seuil `< 5` détruit la capacité à compter son deck**, compétence centrale du genre : les
   cartes défaussées au tour précédent peuvent revenir immédiatement.
3. **La règle de tour vit dans un widget** (`game_screen.dart:204-218`), ce que le `CLAUDE.md`
   proscrit — et c'est la cause directe de l'absence de couverture de tests sur le cycle de tour.
4. **Le HUD affiche « Tour 1 » sur une partie rechargée en plein combat** (§1, `_turnCount`).
5. **Six éléments de code mort**, interdits par le `CLAUDE.md`.

**Pourquoi en Tier S** : c'est le socle des trois axes de profondeur suivants (mots-clés de deck,
effets interactifs, malédictions ennemies — brainstorm §8). Les construire sur les règles actuelles
reviendrait à empiler sur du bancal.

---

## 3. Répartition des responsabilités

**Règle unique** : `DeckNotifier` garantit les **invariants de piles**, `TurnPhaseManager` décide
**quand**, le widget n'**anime** plus que.

`TurnPhaseManager` ne modélise aujourd'hui que la moitié ennemie du cycle (`startEnemyTurn`,
`endEnemyTurn`, `resolveEnemyIntent`). Il gagne les deux points d'entrée joueur manquants, exposés
par `CombatController` exactement comme les deux existants :

```
CombatController (façade)
  ├─ startPlayerCombat()  → TurnPhaseManager.startPlayerCombat()   [NOUVEAU]
  ├─ startPlayerTurn()    → TurnPhaseManager.startPlayerTurn()     [NOUVEAU]
  ├─ startEnemyTurn()     → TurnPhaseManager.startEnemyTurn()      (inchangé)
  └─ endEnemyTurn()       → TurnPhaseManager.endEnemyTurn()        (inchangé)
```

Le nom `startPlayerCombat` est délibérément distinct d'`initializeCombat`, qui reste la génération
d'ennemis, côté adverse.

| Méthode | Contenu | Ordre |
|:---|:---|:---|
| `startPlayerCombat()` | `runController.startCombat()` → `deckController.startCombat(handSize:, maxHandSize:)` | mana/statuts/reliques `startOfCombat` **puis** main d'ouverture |
| `startPlayerTurn()` | `runController.startTurn()` → `deckController.drawCards(n, maxHandSize:)` | reliques `startOfTurn`/statuts **puis** pioche |

Les deux méthodes lisent `runState.cardsPerTurn` (§5.2) et `GameConstants.maxHandSize` (§5.1) :
**la main d'ouverture fait exactement le même nombre de cartes qu'une pioche de début de tour**, et
respecte les mêmes invariants. Le `handSize` de `startCombat` et le `n` de `drawCards` sont donc la
même valeur — l'ouverture de combat cesse d'être un cas particulier.

> **Point de vigilance n°1 du chantier.** Cet ordre est celui d'aujourd'hui
> (`game_screen.dart:212-217`). L'inverser décalerait toute relique `startOfTurn` d'un tour.

`endEnemyTurn()` conserve la transition de phase et l'incrément de `turnCount` — **aucun changement
de comptage des tours**.

### 3.1 Ce qui reste dans le widget

```dart
void _startPlayerNewTurn() {
  setState(() {
    _showManaWarning = false;
    _showRemainingManaWarning = false;
  });                                    // _turnCount++ disparaît
  _game.currentPhase = TurnPhase.player;
  _game.heroCard?.suppressArmorChangeAnimation = true;
  ref.read(combatProvider.notifier).startPlayerTurn();
}
```

La microtask d'`initState` passe de quatre appels métier à deux : `startPlayerCombat()` puis
`initializeCombat(...)`. **Aucune dépendance d'ordre entre eux** — le budget d'ennemis lit
`masterDeck.length` (`game_screen.dart:271`), que la constitution de la pioche ne modifie pas.

### 3.2 `DeckNotifier` ne lit pas `runProvider`

`cardsPerTurn` et `maxHandSize` lui sont passés **en paramètres**. Il reste sans dépendance sur un
autre contrôleur, donc testable avec un simple `ProviderContainer()` — c'est ce que font déjà les
4 tests de `test/unit/deck_controller_test.dart`.

---

## 4. Le moteur de piles

### 4.1 Les trois règles

1. **On pioche carte par carte, depuis le sommet de la pioche.** Inchangé.
2. **Si la pioche est vide alors qu'il reste des cartes à piocher : on verse toute la défausse dans
   la pioche, on mélange, et on continue immédiatement.** C'est le « remélange à sec » — il se
   déclenche **au milieu d'une pioche**, pas seulement en début de tour.
3. **Si la pioche ET la défausse sont vides : on s'arrête proprement.** Pas d'exception. On a
   simplement pioché moins que demandé.

**La pile d'épuisement n'est jamais remélangée** — c'est ce qui rend l'épuisement définitif.

### 4.2 La règle de débordement : arrêt net

**Quand la main atteint `maxHandSize`, la pioche s'interrompt.** Aucune carte n'est retirée de la
pioche, aucun remélange n'est déclenché. Les cartes en excès sont perdues, mais le deck reste
intact et ordonné.

Justification — le contre-exemple qui écarte l'alternative « la carte part en défausse » :

```
Main 10 (pleine) · pioche 0 · défausse 15 · « Piocher 2 »

Règle « part en défausse » :
  → pioche vide, donc remélange des 15 cartes
  → on tire 2 cartes … qui repartent aussitôt en défausse
  Final : main 10 · pioche 13 · défausse 2

Le deck vient d'être remélangé pour rien. Le joueur qui comptait son deck — la compétence
que §2.2 cherche précisément à restaurer — perd son information en échange de zéro carte.
```

L'arrêt net est la seule règle où **aucune carte n'est détruite sans que le joueur l'ait vue**, et
où **le deck n'est jamais mélangé pour rien**. La cause est de surcroît visible à l'écran : la main
est pleine.

### 4.3 L'algorithme

Cœur pur, partagé par les deux points d'entrée. Le record est le style déjà en place dans le
codebase (`deck_controller.dart:47` `_decodePile`, `DamagePipeline.calculate`).

```dart
static ({List<CardInstance> draw, List<CardInstance> hand,
         List<CardInstance> discard, int reshuffles}) _drawInto({
  required List<CardInstance> draw,
  required List<CardInstance> hand,
  required List<CardInstance> discard,
  required int amount,
  required int maxHandSize,
  required Random random,
}) {
  var reshuffles = 0;

  for (var i = 0; i < amount; i++) {
    if (hand.length >= maxHandSize) break;   // règle « arrêt net »
    if (draw.isEmpty) {
      if (discard.isEmpty) break;            // deck épuisé, sortie propre
      draw..addAll(discard)..shuffle(random);
      discard.clear();
      reshuffles++;
    }
    hand.add(draw.removeLast());
  }

  return (draw: draw, hand: hand, discard: discard, reshuffles: reshuffles);
}
```

**L'ordre des deux tests compte** : main pleine d'abord, remélange ensuite. C'est ce qui garantit
qu'une pioche impossible ne mélange jamais le deck.

### 4.4 Les deux points d'entrée publics

```dart
void drawCards(int amount, {required int maxHandSize})
void startCombat({required int handSize, required int maxHandSize})
```

`startCombat` remplace `initializeCombat()` **et** le `drawCards(5)` séparé de
`game_screen.dart:276` : il constitue la pioche depuis `masterDeck`, vide main/défausse/épuisement,
remet `reshuffleCount` à 0, et tire la main d'ouverture — le tout en **une seule affectation de
`state`**.

Ce détail n'est pas cosmétique. Aujourd'hui un remélange suivi d'une pioche produit deux
notifications Riverpod, donc deux passes de `_applyDeckState` (`state_sync_system.dart:66`) et
**deux `layoutHand()`** (`:92`) : l'éventail se réanime deux fois. Le nouveau code n'en déclenche
qu'une.

### 4.5 Trois conséquences structurelles

| Changement | Effet |
|:---|:---|
| `shuffleDiscardIntoDraw()` quitte l'API publique | La règle cesse d'être optionnelle. Aucun futur appelant ne peut plus « oublier » de remélanger — c'est la cause racine du bug d'origine. |
| `DeckState.reshuffleCount` (nouveau champ `int`) | Incrémenté par le moteur, remis à 0 par `startCombat`. Sérialisé avec `?? 0` en lecture : **rétrocompatible** avec les sauvegardes existantes. |
| `deckRandomProvider` | `Provider<Random>((ref) => Random())`, lu dans `DeckNotifier.build()`. Comportement identique en jeu ; en test, `overrideWithValue(Random(42))` rend chaque séquence reproductible. |

Injection volontairement minimale : **pas de seed persisté ni de seed partageable**. Ces deux
évolutions restent possibles plus tard sans changer le point d'injection.

### 4.6 L'invariant qui protège tout le reste

```
masterDeck.length == drawPile + hand + discardPile + exhaustPile
```

Vrai après **chaque** opération de pile. C'est l'assertion qui attrapera les régressions futures,
y compris celles des chantiers du brainstorm §8 qui viendront brancher de nouvelles manipulations
sur ce moteur.

### 4.7 Propagation du changement de signature

| Appelant de `drawCards` | Accès à `maxHandSize` |
|:---|:---|
| `DrawEffectStrategy` (`strategies.dart:120`) | Via le `runController` déjà présent dans `resolve` |
| Rune de forge `quick` (`effect_resolver.dart:165`) | Via le `runController` déjà présent dans `resolveCard` |
| `game_screen.dart:217,276` | Disparaissent — remplacés par `startPlayerTurn()` et `startPlayerCombat()` |

Aucun appelant n'a besoin d'un argument injecté depuis l'extérieur.

---

## 5. Les deux valeurs de règle

Elles n'ont pas le même statut, et c'est ce qui décide de leur implémentation.

### 5.1 `maxHandSize` → une constante, pas une statistique

Base **10**. Aucune relique ne la modifie (§5.3), donc en faire un champ sérialisé serait de la
plomberie sans consommateur. Elle devient **`GameConstants.maxHandSize = 10`**, lue par
`TurnPhaseManager` aux deux points d'appel.

Elle reste malgré tout un **paramètre** de `drawCards` / `startCombat` plutôt qu'une constante lue
dans `DeckNotifier` : c'est ce qui rend le test de débordement écrivable (`maxHandSize: 3` sur un
deck de test) sans avoir à atteindre 10 cartes en main. Zéro champ, zéro sérialisation, zéro
migration — et la règle reste testable.

**Constat de calibrage à consigner** : le plafond à 10 **ne se déclenchera pas en jeu aujourd'hui**.
La main est intégralement défaussée en fin de tour (`game_screen.dart:504`), donc chaque tour
repart de 5 cartes ; jouer une carte la retire de la main, si bien qu'une carte « inflige 3, pioche
1 » est un net **0**. Sur les 6 cartes du pool à effet `draw` (`cards.json` ×3, `hero_cards.json`
×3), une seule fait croître la main — `Concentration`, 0 mana, pioche 2, net **+1** — et elle
s'épuise. La rune `quick:1` est également net 0. Il faudrait **+5 net dans un seul tour** pour
toucher le plafond. La règle est donc posée pour les mots-clés de Rétention et Innée du §8, où les
mains persisteront d'un tour à l'autre.

### 5.2 `cardsPerTurn` → une statistique de run, sur `RunState`

Base **5** — la valeur aujourd'hui codée en dur à `game_screen.dart:217` et `:276`.

**Stockée sur `RunState`, pas sur `EntityStats`.** `EntityStats` est partagé par le héros *et* les
ennemis (`combat_controller.dart:152`) : y poser une notion de pioche donnerait à chaque gobelin un
`cardsPerTurn`. C'est la même erreur de catégorie que le `MapNode.position` typé `Vector2` que P-26
existe pour corriger. `RunState` héberge déjà exactement ce type de valeur de règle propre au joueur
(`bonusForgeSlots`, `pendingDrafts` — `run_controller.dart:32-33`).

Coût assumé : un mutateur dédié à côté d'`applyHeroStatModifier`, symétrique add/remove, plutôt que
la réutilisation directe des 4 `case` existants.

Sérialisation : `json['cardsPerTurn'] as int? ?? 5` — rétrocompatible.

### 5.3 La relique

Première relique du jeu à toucher au deck : les 24 actuelles se limitent à `gain_armor`,
`gain_mana`, `gain_crit`, `gain_luck`, `gain_strength`, `heal` et quatre variantes à charges.

```
trigger    : startOfRun
effectType : increase_cards_per_turn
value      : 1
rarity     : legendary
```

**Rareté calibrée sur le pool existant**, pas sur une intuition. Les 8 reliques `startOfRun`
permanentes de `assets/data/relics.json` :

| Relique | Effet permanent | Rareté |
|:---|:---|:---|
| Pierre à aiguiser · Pièce de chance | +1 Force · +5 crit | `common` |
| Porte-bonheur · Lame Maudite | +10 crit · +2 Force | `uncommon` |
| Lentille de Focalisation | +15 crit | `rare` |
| Trèfle Enchanté | +1 Chance | `epic` |
| Dé de Fortune | +2 Chance | `legendary` |
| **Couronne des Rois** (`relics.json:279`) | **+1 Mana Max** | **`legendary`** |

La lecture est nette : **+1 permanent sur une ressource centrale = `legendary`**. Or +1 carte
piochée par tour est au moins aussi fort que +1 mana max — le mana se réinitialise chaque tour, les
cartes s'accumulent dans le cycle du deck.

Entrée bilingue `_fr`/`_en` comme l'impose le `CLAUDE.md`.

### 5.4 La symétrie de retrait — point manqué par le brainstorm

Toute relique `startOfRun` doit être **retirable**. `removeRelicEffect`
(`player_stats_manager.dart:380`) porte 4 `case` symétriques, utilisés par l'écran d'Échange de
Reliques. Ajouter la relique sans son `case` de retrait ferait **fuiter le bonus** : le joueur
sacrifie la relique et garde la carte en plus. Les deux `case` sont livrés ensemble, avec un test
dédié (§7, test 11).

---

## 6. Feedback joueur : le remélange

Le remélange devient un **moment significatif** : aujourd'hui il est noyé par le seuil `< 5` qui le
déclenche presque chaque tour, demain il marquera la fin d'un cycle de deck complet.

Contrainte d'architecture : `NotificationOverlay` est une file de toasts **UI**
(`context.showNotification`), donc `DeckNotifier` ne peut pas la déclencher.

**Solution retenue** : `DeckState.reshuffleCount` (§4.5) est observable ; `game_screen` l'écoute via
`ref.listen` et affiche un toast bilingue « Défausse remélangée » quand il augmente. La remise à 0
par `startCombat` ne déclenche rien (le compteur diminue).

~6 lignes, **aucune dépendance sur `vfx_tokens.dart`** — qui n'existera qu'après P-06. Une mise en
scène animée des cartes repartant vers la pioche reste possible plus tard, sur le même point
d'accroche.

**Le débordement de main ne reçoit aucune notification** : avec un plafond à 10 inatteignable
(§5.1), il n'y a rien à signaler.

---

## 7. Suppression du code mort et de la duplication

Six suppressions, toutes vérifiées par grep sur `lib/` **et** `test/`.

| Élément | Sites | Traitement |
|:---|:---|:---|
| `CardInstance.temporaryCost` + `clearTemporaryCost` | `card_instance.dart:9,16,23,47,55,65,74` | Supprimés. **`currentCost` reste** et devient `=> data.cost` — ses 6 appelants externes (`ui_card.dart:65`, `card_component.dart:54,320`, `card_text_renderer.dart:671`, `effect_resolver.dart:98,123`) compilent sans être touchés. |
| `IntentType.debuffDeck` | `enemy_intent.dart:1` + 3 `switch` | Supprimé de l'enum et des 3 `case`. Aucun ennemi d'`enemies.json` ne l'utilise. |
| `onEnemyDebuffDeck` | `heros_draft_game.dart:57,76` + `game_screen.dart:281` | Callback `required` au corps vide, jamais invoqué. Supprimé. |
| `onTurnEnded` | `heros_draft_game.dart:58,77` + `game_screen.dart:284` | Second callback `required` jamais invoqué (§1). Supprimé. |
| Deck de secours codé en dur | `game_screen.dart:227-248` | Supprimé. `StarterDeckDraftScreen` (`:108`) est le seul chemin d'initialisation légitime. |
| `_turnCount` | `game_screen.dart:63,208` | Supprimé. `TurnControlPanel` (`:509`) est alimenté par `combatState.turnCount`, déjà lu dans le `build`. |

`HerosDraftGame` passe de **13 à 11 callbacks de constructeur** — ce qui allège d'autant le futur
P-27 (Event Bus), dont le périmètre est précisément ces callbacks.

### 7.1 Le bug d'affichage que corrige la déduplication

`_turnCount` est un simple champ de `State`, initialisé à `1`. `CombatState.turnCount` est
incrémenté par `turn_phase_manager.dart:47` **et sérialisé** (`combat_state.dart:88,100`). Une
partie sauvegardée en plein combat puis rechargée restaure correctement `combatState.turnCount`,
mais `_turnCount` repart de `1` : le HUD affiche « Tour 1 » sur un combat au tour 7.

### 7.2 Garde-fou sur la suppression du deck de secours

Retirer le fallback rend la faute **bruyante** au lieu de silencieuse. C'est l'effet voulu, mais
sans échouer en silence pour autant — motif `kDebugMode` déjà employé partout dans le projet :

```dart
// dans TurnPhaseManager.startPlayerCombat(), avant l'appel à deckController.startCombat()
if (kDebugMode && ref.read(deckProvider).masterDeck.isEmpty) {
  debugPrint('startPlayerCombat: masterDeck vide — '
             'StarterDeckDraftScreen a-t-il été court-circuité ?');
}
```

Zéro coût en release, cause immédiate le jour où un chemin de navigation contourne le draft de
départ.

---

## 8. Tests et validation

`ProviderContainer()` sans override suffit pour `runProvider` et `combatProvider` — c'est déjà le
motif de `test/unit/combat_controller_test.dart` (7 occurrences). Aucun échafaudage nouveau.

### 8.1 Le moteur de piles → `test/unit/deck_controller_test.dart`

| # | Test | Assertion clé |
|:--|:---|:---|
| 1 | Remélange à sec au milieu d'une pioche | pioche 3, défausse 7, `drawCards(5)` → main 5 · pioche 5 · défausse 0 |
| 2 | Deck totalement épuisé | pioche 0, défausse 0, `drawCards(3)` → main inchangée, **aucune exception** |
| 3 | **Arrêt net sur main pleine** | main à `maxHandSize`, `drawCards(2)` → les 4 piles **et `reshuffleCount`** strictement inchangés |
| 4 | Invariant de conservation | `masterDeck.length == draw + hand + discard + exhaust` après chaque opération |
| 5 | Déterminisme | `deckRandomProvider.overrideWithValue(Random(42))` → ordre de pioche reproductible |
| 6 | `startCombat` | pioche constituée + main d'ouverture en une passe, `reshuffleCount` remis à 0 |
| 7 | `reshuffleCount` | exactement +1 par remélange, jamais plus |

Le test 3 est celui qui **distingue la règle retenue de celle du brainstorm** : avec « consommée
vers la défausse », ce même scénario aurait mélangé le deck. Le compteur ajouté pour le toast (§6)
sert donc aussi d'assertion — un champ, deux usages.

**Tests existants à reprendre** :

| Fichier:ligne | Reprise |
|:---|:---|
| `deck_controller_test.dart:21` | « does not shuffle discard » affirme aujourd'hui le bug — assertion **inversée** |
| `deck_controller_test.dart:77` | appelle `shuffleDiscardIntoDraw()`, qui quitte l'API publique — passe par `drawCards` |
| `deck_controller_test.dart:56,110` | `initializeCombat()` → `startCombat(handSize:, maxHandSize:)` |
| `combat_controller_test.dart:334,481` | idem — **deux sites hors du fichier de test du deck**, à ne pas oublier |

Les 2 tests de `mergeCards` (`deck_controller_test.dart:133,184`) ne bougent pas.

### 8.2 La règle de tour → `test/unit/combat_controller_test.dart`

| # | Test | Assertion clé |
|:--|:---|:---|
| 8 | `startPlayerTurn` fait les deux moitiés | mana au max, armure des reliques `startOfTurn` appliquée, statuts tickés, **et** main à `cardsPerTurn` |
| 9 | `startPlayerTurn` pioche `cardsPerTurn`, pas 5 en dur | `cardsPerTurn = 6` → main de 6 |
| 10 | `startPlayerCombat` | `startCombat()` (statuts vidés, mana au max, reliques `startOfCombat`) **puis** main d'ouverture |

> **Réserve explicite sur le test 8.** L'*ordre* `startTurn()` → pioche n'est **pas** directement
> observable avec les effets existants : aucun effet actuel ne rend une pioche dépendante d'une
> relique de début de tour. Le test prouve que **les deux moitiés s'exécutent**. L'ordre lui-même
> est protégé *structurellement* — il est écrit une seule fois dans une méthode nommée au lieu
> d'être ré-établi à chaque site d'appel. C'est un gain de conception, pas de couverture.

### 8.3 La symétrie de la relique → `test/unit/relic_exchange_test.dart`

| # | Test | Assertion clé |
|:--|:---|:---|
| 11 | Relique acquise puis sacrifiée | `cardsPerTurn` : 5 → 6 → **5**. Sans le `case` de `removeRelicEffect` (§5.4), ce test échoue et le bonus fuite. |

**Total : 11 tests neufs + 2 réécrits.** La ROADMAP en promettait 6 « aujourd'hui inécrivables ».

### 8.4 Validation hors tests

1. **`dart analyze` propre, zéro issue** — exigence du `CLAUDE.md`, non négociable. Les six
   suppressions de code mort la rendent d'autant plus significative.
2. **`flutter test` intégral** — 42 fichiers. La suppression de `temporaryCost` et
   d'`IntentType.debuffDeck` touche des modèles largement partagés ; c'est là que se verront les
   régressions.
3. **Playtest de plusieurs combats complets** — ce que ni les tests ni l'analyse ne couvriront.

---

## 9. Écarts assumés par rapport au brainstorm du 31/07

| # | Brainstorm | Ce document | Raison |
|:--|:---|:---|:---|
| 1 | Débordement : la carte part en défausse (§4.2) | **Arrêt net** (§4.2) | La règle du brainstorm peut déclencher un remélange complet du deck pour ne rien donner au joueur — elle se retourne contre l'objectif « compter son deck » du §2.2. |
| 2 | Relique `maxHandSize`, `rare`, valeur 2 (§4.3) | **Relique `cardsPerTurn`, `legendary`, valeur 1** (§5.3) | Le plafond à 10 est inatteignable avec le pool actuel (§5.1) : la relique proposée serait statistiquement invisible. `cardsPerTurn` transforme en prime le `5` codé en dur en statistique, ce qui sert le déplacement de la règle hors de l'UI au lieu de le contredire. |
| 3 | `EntityStats.maxHandSize` (§4.3) | **`RunState.cardsPerTurn`, `GameConstants.maxHandSize`** (§5.1-5.2) | `EntityStats` est partagé avec les ennemis. `maxHandSize` n'ayant plus de relique, un champ sérialisé serait sans consommateur. |
| 4 | Seul `startPlayerTurn` est extrait (§4.1) | **`startPlayerCombat` aussi** (§3) | Le brainstorm laissait l'ouverture de combat dans la microtask d'`initState`, donc non testable, et laissait l'asymétrie tour 1 / tours N+1 invisible. |
| 5 | Silencieux sur le feedback (§7, point ouvert) | **`reshuffleCount` + toast** (§6) | Le compteur sert doublement : feedback joueur et assertion du test 3. |
| 6 | 5 éléments de code mort | **6** (§7) | `onTurnEnded` découvert lors de la vérification (§1). |
| 7 | Silencieux sur `removeRelicEffect` | **`case` de retrait livré avec** (§5.4) | Sans lui, l'Échange de Reliques fait fuiter le bonus. |

---

## 10. Risques

| Risque | Niveau | Mitigation |
|:---|:---:|:---|
| **Régression du flux de combat** — la pioche quitte `game_screen.dart`, le chemin le plus emprunté du jeu | ★★★★☆ | L'ordre `runController.startTurn()` → pioche est préservé à l'identique et figé dans une méthode nommée (§3). Tests 8-10. |
| **Rééquilibrage implicite** — le remélange à sec change la difficulté ressentie | ★★★☆☆ | Effet **assumé et voulu**. Playtest requis avant clôture. La ROADMAP en fait une dépendance explicite : **P-16 doit se calibrer après P-02**, sinon on calibre deux fois. |
| **Compatibilité des sauvegardes** | ★☆☆☆☆ | `reshuffleCount ?? 0` et `cardsPerTurn ?? 5` en lecture. La suppression de `temporaryCost` fait ignorer une clé optionnelle des anciennes sauvegardes. |
| **Deck vide en combat** après suppression du fallback | ★☆☆☆☆ | Garde-fou `kDebugMode` (§7.2). |

---

## 11. Ce que ce chantier débloque (hors périmètre)

Les quatre axes du brainstorm §8, tous dépendants de ce socle :

1. **Mots-clés de deck** — Rétention, Innée, Éphémère, coût variable. Le champ `temporaryCost`
   supprimé ici serait à réintroduire *avec* son mécanisme le jour où le coût variable existera.
   C'est aussi le jour où `maxHandSize` cessera d'être théorique.
2. **Effets interactifs** — « défausser une carte pour… », « épuiser une carte de la main ».
   Bloqués par le contrat d'`EffectStrategy` (`effect_strategy.dart:9-19`), dont la signature ne
   prend aucune entrée utilisateur. **C'est le vrai verrou architectural de la profondeur.**
3. **Reliques liées au deck** — la relique de §5.3 ouvre la voie ; « commence le combat avec X en
   main » suit le même motif.
4. **Malédictions ennemies** — reconstruire proprement ce que `IntentType.debuffDeck` promettait.
   `CardType.status` existe déjà et est correctement bloqué au jeu par `canPlayCard`
   (`effect_resolver.dart:101-103`) ; `addCardToDiscardPile` (`deck_controller.dart:319`) est le
   point d'injection tout prêt.

Un axe purement UI reste ouvert : `combat_side_panels.dart` n'affiche que des compteurs de pioche
et de défausse — aucune consultation du contenu des piles n'est possible.
