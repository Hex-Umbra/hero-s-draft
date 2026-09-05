# Menu de debug — lot 1 : manipulateur de run — Conception

Date : 2026-09-05
Statut : **Conçu, non implémenté**
Révision : v2 — après relecture : ciblage des ennemis un par un plutôt qu'une action de vague
(§4, onglet Combat), et vérification manuelle du build release (§7.1)
Périmètre : **lot 1 sur 2.** Le lot 2 — l'éditeur de contenu hors run — fait l'objet de sa propre
spec et n'est pas traité ici.
Sources amont :
- Brainstorming du 2026-09-05 (chemin architectural, approche A retenue)
- `docs/superpowers/specs/2026-09-04-reorganisation-donnees-un-fichier-par-entite-design.md` — la
  réorganisation qui rend le lot 2 envisageable, et dont ce lot-ci est indépendant
- `.obsidian_vault/_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md`

> **Ce lot n'écrit rien.**
>
> Il ne touche qu'à l'état vivant de l'application — les providers Riverpod, perdus au prochain
> lancement. C'est la ligne de partage avec le lot 2, qui produit des fichiers durables : deux
> outils, deux niveaux de conséquence. Un bug ici coûte une session ; un bug là-bas entre dans le
> dépôt et devient le jeu de tout le monde.
>
> La conséquence de conception tient en une phrase : **le lot 1 n'a besoin d'aucun code nouveau
> dans les contrôleurs.** Tout ce qu'il manipule est déjà public, parce que `SaveService.load()`
> en avait besoin avant lui.

---

## 1. Le problème

Tester une situation de jeu demande aujourd'hui de la jouer. Vérifier le comportement de l'acte 3
avec un deck de vingt cartes et quatre reliques, c'est une run de trente minutes — et si le bug
n'apparaît pas, c'est trente minutes à recommencer.

Trois conséquences mesurables :

1. **Les états tardifs sont sous-testés.** Le début de run est parcouru des dizaines de fois par
   jour, la fin presque jamais.
2. **Les bugs de fin de run se reproduisent mal.** Un défaut vu une fois à l'acte 3 demande de
   reconstituer la run entière pour être observé une seconde fois.
3. **L'équilibrage se règle à l'aveugle.** Les formules de budget de rencontre
   (`CombatDebugLogger` en imprime le détail) dépendent de `playerLevel`, `act`, du nombre de
   reliques et de cartes. Aucun de ces quatre paramètres n'est réglable autrement qu'en jouant.

## 2. Décisions retenues

| # | Décision | Motif |
|:--|:---|:---|
| **D1** | Deux lots séparés : manipulateur de run (mémoire vive) et éditeur de contenu (disque) | Réversibilité opposée, et les artefacts du lot 2 doivent passer les mêmes gardes que des fichiers écrits à la main |
| **D2** | Approche A — une classe statique `DebugActions` composant les contrôleurs existants | Aucune méthode nouvelle sur les contrôleurs ; §6 |
| **D3** | Point d'entrée unique dans `PauseDialog` | Ce dialogue est déjà appelé depuis le combat *et* la carte : une insertion couvre les deux |
| **D4** | Tout est gardé par `kDebugMode`, à deux niveaux | Jamais présent dans un build publié ; §3.4 |
| **D5** | Une run touchée par le debug ne se sauvegarde plus | Une sauvegarde trafiquée est indistinguable d'une sauvegarde légitime, et survivrait à la session |
| **D6** | Le drapeau de contamination se remet à zéro dans `startNewRun` | Sinon toute run ultérieure reste non sauvegardable jusqu'au redémarrage |
| **D7** | Pas de génération d'ennemis choisis | Demanderait d'exposer le calcul de scaling d'`EncounterSystem` ; §8 |

## 3. Architecture

### 3.1 `DebugActions`

`lib/game/services/debug_actions.dart` — classe statique, calquée sur `SaveService` : elle reçoit
un `Ref` et compose les contrôleurs. Elle ne détient aucun état.

Chaque méthode publique commence par `if (!kDebugMode) return;`. C'est la seconde garde, celle qui
tient même si un appel échappait un jour à la première. Le précédent du dépôt est
`CombatDebugLogger` (`lib/game/services/combat_debug_logger.dart:33`), gardé exactement ainsi.

### 3.2 Les points d'entrée utilisés

Aucun n'est à créer. Tous existent et sont publics :

| Cible | Appel |
|:---|:---|
| Stats du héros, acte, niveau, drafts, cartes par tour | `RunController.updateState` — `run_controller.dart:228` |
| Acte suivant avec régénération de carte | `RunController.advanceToNextWorld` — `:282` |
| Or | `InventoryController.gainGold` / `spendGold` |
| Reliques | `InventoryController.addRelic` / `removeRelics` |
| Deck | `DeckNotifier.addCardToMasterDeck` / `removeCardById` / `drawCards` / `discardHand` |
| PV d'un ennemi | `CombatController.updateEnemyStats` — `combat_controller.dart:197` |
| Résolution des morts | `CombatController.cleanDeadEnemies` — `:290` |
| Fin de combat forcée | `CombatController.updateState` — `:33` |

Les listes de choix ne demandent aucun chargement : `GameDataRegistry.instance` expose déjà
`cards`, `relics`, `enemies`, `heroes`, `passives` et `forgeUpgrades`.

### 3.3 Le drapeau de contamination

Un `debugTaintProvider` — `NotifierProvider<DebugTaintNotifier, bool>`, conforme à la règle du
dépôt qui proscrit les nouveaux `StateNotifier`. Il vit dans `debug_actions.dart`.

- `DebugActions` le passe à `true` à la **première** action, quelle qu'elle soit.
- `autosaveOrchestratorProvider` (`checkpoint_controller.dart:20`) le lit et, s'il est levé,
  n'appelle plus `SaveService.save`.
- `RunController.startNewRun` le remet à `false`, derrière `kDebugMode` (**D6**).

**La sauvegarde déjà présente sur le disque n'est ni écrasée ni effacée.** Une run debug la laisse
exactement où elle était : au prochain lancement, c'est elle qui se recharge.

> [!IMPORTANT]
> Le drapeau est volontairement irréversible pour la run en cours. Aucun bouton ne le rabaisse :
> une run dont on ne sait plus quelles valeurs ont été forcées ne doit pas pouvoir redevenir
> sauvegardable par inadvertance. On en sort en lançant une nouvelle run.

### 3.4 L'interface

`lib/ui/widgets/debug/` — un `DebugMenuDialog` construit sur le kit existant (`GameDialog`,
`GameButton`, `AppSpacing`), à onglets.

Le bouton d'ouverture est ajouté dans `PauseDialog`, enveloppé dans `if (kDebugMode)`.
`kDebugMode` est une constante de compilation : en release, la condition est repliée à `false` et
le sous-arbre — dialogue, actions, imports — devient inatteignable, donc éliminé au tree-shaking.

Une seule insertion couvre les deux contextes, `PauseDialog` étant déjà appelé depuis
`game_screen.dart:541` et `map_screen.dart:142`.

Chaque action confirme par le système de notifications existant
(`notificationProvider`, `NotificationType.success`). Pas de rappel de redémarrage : **le lot 1 est
immédiat.** L'avertissement de hot restart appartient au lot 2, dont les écritures ne sont visibles
qu'après rechargement du bundle d'assets.

## 4. Inventaire des actions

### Onglet Héros — via `RunState.heroStats`

PV et PV max, mana et mana max, armure, attaque, chance, niveau, XP, chance de critique et
multiplicateur de critique. Tous les champs numériques d'`EntityStats`, en écriture directe.

Deux raccourcis : **soin complet** (`currentPv = maxPv`) et **mana plein**.

### Onglet Run

Tous ces champs vivent sur `RunState`, à une exception près, signalée dans le tableau.

| Champ | Effet |
|:---|:---|
| `gold` | Or courant. **Seul champ de cet onglet à vivre sur `InventoryState`**, donc écrit via `InventoryController` et non `updateState` |
| `act` | Voir §5 — deux actions distinctes |
| `currentLevel` | Niveau de run ; alimente les formules de budget de rencontre |
| `pendingDrafts` | Drafts de montée de niveau en attente |
| `cardsPerTurn` | Cartes piochées par tour |
| `bonusForgeSlots` | Slots de forge achetés |

### Onglet Deck

Ajouter n'importe quelle carte du registre au deck maître, en retirer une, forcer une pioche de
*n* cartes, vider la main. La liste de choix est `GameDataRegistry.instance.cards`, triée par
`CardData.compareByDisplayOrder` (rareté, puis coût, puis id) — le comparateur que partagent déjà
le dictionnaire de cartes, le draft de deck de départ et le tutoriel.

### Onglet Reliques

Ajouter et retirer depuis `GameDataRegistry.instance.relics`. `addRelic` déclenche déjà l'effet
des reliques `startOfRun` : le comportement testé est donc le vrai.

### Onglet Combat — présent seulement pendant un combat

L'onglet liste **les ennemis actuellement en jeu**, un par ligne : nom, PV courants sur PV max, et
son rang dans la vague pour distinguer deux ennemis du même type. Chaque ligne porte ses propres
commandes.

| Action | Mécanisme | Ce que ça teste |
|:---|:---|:---|
| **Mettre un ennemi à 0 PV** — un bouton par ligne | `updateEnemyStats(currentPv: 0)` sur cet ennemi seul, puis `cleanDeadEnemies()` | Viser une cible précise au milieu des autres, par le **vrai** chemin de mort : gain d'XP et déclencheurs de reliques compris |
| **Fixer les PV d'un ennemi** — un champ par ligne | `updateEnemyStats(currentPv: n)` | Les seuils de PV bas : exécutions, intentions conditionnelles, affichage des barres de vie |
| **Mettre tous les ennemis à 0 PV** | La même chose appliquée à chaque ennemi de `state.enemies` | Vider la vague courante ; la vague suivante apparaît depuis `pendingEnemies` si elle n'est pas vide |
| **Gagner le combat** | `updateState` avec `enemies` et `pendingEnemies` vides, `isCombatEnded` et `isVictory` à `true` | Le court-circuit : passe directement à l'écran de récompense |
| **Perdre le combat** | `heroStats.currentPv = 0` | `RunState.isDead`, donc `DeathOverlay` |
| **Sauter la phase ennemie** | `updateState(turnPhase: TurnPhase.player)` | Enchaîner des tours joueur sans subir les intentions |

> [!NOTE]
> **Réduire des PV n'est pas gagner un combat, et l'outil ne doit pas les confondre.** Les trois
> premières lignes empruntent le chemin réel : `cleanDeadEnemies()` distribue l'XP, déclenche les
> reliques et **fait apparaître la vague suivante** si `pendingEnemies` n'est pas vide — c'est le
> comportement légitime, et c'est exactement ce qu'on veut pouvoir observer. « Gagner le combat »
> vide les files et court-circuite tout. Un outil qui mélangerait les deux mentirait sur ce qu'il
> vient de tester.

Les commandes par ennemi vivent **dans le dialogue de debug, pas sur les sprites.** Poser un
bouton sur un composant d'ennemi ferait entrer de la logique de debug dans la couche de rendu
Flame, que l'architecture du dépôt tient à l'écart de toute décision — les composants lisent
l'état et l'affichent, ils n'en déclenchent pas la modification. La liste du dialogue donne le
même pouvoir de ciblage sans toucher au rendu.

## 5. Le cas de l'acte

`advanceToNextWorld()` ne se contente pas d'incrémenter `act` : il **régénère la carte** et
**efface `currentNodeId`**. Déclenché en plein combat, il laisserait la run sans position.

Deux actions distinctes, donc :

- **Acte suivant** — appelle `advanceToNextWorld()`. Disponible **sur l'écran de carte
  uniquement**, masqué en combat.
- **Forcer `act = n`** — `updateState(copyWith(act: n))`, le champ seul, carte et position
  intactes. Disponible partout. C'est celle qui sert à régler les formules de scaling.

## 6. Ce qu'il n'y a pas à écrire

Le point le plus important de cette conception, et la raison pour laquelle l'approche A a été
retenue : **aucun contrôleur n'est modifié pour rendre l'état accessible.**

`RunController.updateState`, `CombatController.updateState`, `DeckNotifier.hydrate` et
`InventoryController.hydrate` sont publics depuis l'implémentation du système de sauvegarde, qui
avait exactement le même besoin — remplacer un état entier par un autre. Le menu de debug est un
second client de cette même surface.

Les seules lignes ajoutées à du code existant sont au nombre de trois :

1. le bouton dans `PauseDialog`, sous `if (kDebugMode)` ;
2. la lecture du drapeau dans `autosaveOrchestratorProvider` ;
3. la remise à zéro dans `startNewRun`, sous `if (kDebugMode)` (**D6**).

## 7. Tests

`DebugActions` est de la logique pure sur un `ProviderContainer` — testable exactement comme
`run_controller_test.dart` et `inventory_controller_test.dart`.

`test/unit/debug_actions_test.dart` :

- une assertion par action, vérifiant l'état résultant ;
- mettre **un** ennemi à 0 PV sur une vague de trois → il disparaît, les deux autres sont intacts,
  et le combat continue ;
- mettre **tous** les ennemis à 0 PV avec `pendingEnemies` non vide → la vague suivante apparaît
  et le combat **n'est pas** terminé ;
- fixer les PV d'un ennemi à une valeur non nulle → il survit, `cleanDeadEnemies` ne l'emporte
  pas ;
- « gagner le combat » → `isCombatEnded` et `isVictory` levés, les deux files vides ;
- « forcer l'acte » → `act` change, `mapNodes` et `currentNodeId` inchangés.

`test/unit/debug_taint_test.dart`, dans la lignée de `checkpoint_autosave_test.dart` :

- une action debug lève le drapeau ;
- drapeau levé + `checkpointProvider.bump()` → aucune écriture ;
- `startNewRun` rabaisse le drapeau et l'autosave reprend.

### 7.1 L'absence en build release se vérifie à la main

Les tests s'exécutent en mode debug : `kDebugMode` y vaut toujours `true`. Aucun test automatisé
de ce dépôt ne peut donc prouver l'absence du menu dans un build publié. **Cette vérification est
manuelle, et c'est le choix retenu** plutôt qu'un test automatisé qui ne prouverait rien.

Procédure, à exécuter une fois à la livraison du lot, puis à chaque déplacement du point d'entrée
de §3.4 :

1. `flutter build windows --release`
2. Lancer le binaire produit, démarrer une run, ouvrir le menu pause **depuis la carte** puis
   **depuis un combat**.
3. Aucun bouton de debug ne doit apparaître dans l'un ni dans l'autre.

La garantie de fond reste le repliage de constante du compilateur ; la double garde de §3.1 est là
pour que l'oubli d'un seul des deux niveaux ne suffise pas à faire fuiter le menu.
`CombatDebugLogger` vit sous la même limite depuis son introduction.

## 8. Hors périmètre

| Écarté | Motif |
|:---|:---|
| Toute écriture disque | C'est le lot 2, intégralement |
| Génération d'un ennemi choisi en combat | **D7** — demanderait d'exposer le calcul de niveau et de scaling d'`EncounterSystem`, un chantier à part |
| Changer de classe en cours de run | La classe détermine le pool de cartes et le passif ; la changer à mi-run produit un état qu'aucune partie réelle ne peut atteindre |
| Rejouer un nœud déjà résolu | Demanderait de défaire `completeCurrentNode`, qui a déjà déclenché un checkpoint |
| Éditer les effets d'une carte | Contenu, donc lot 2 |
| Un état debug qui survit au redémarrage | Contredirait **D5** : ce lot ne persiste rien |

## 9. Risques

| Risque | Portée | Traitement |
|:---|:---|:---|
| Le menu atteint un build publié | Élevée si elle survenait | Double garde `kDebugMode` (§3.1, §3.4), et vérification manuelle sur un build release à la livraison (§7.1) |
| Une sauvegarde trafiquée passe pour légitime | Élevée | **D5** — le drapeau ; la sauvegarde disque reste celle d'avant |
| Une valeur forcée produit un état impossible à atteindre en jeu, et un faux bug | Moyenne | Aucun garde-fou : c'est le but de l'outil. Les bornes des champs sont celles des modèles, pas celles du gameplay |
| Un `act` forcé sans carte correspondante | Faible | §5 sépare les deux actions précisément pour ça |
| `DebugActions` diverge des contrôleurs qu'il compose | Faible | Il n'appelle que des méthodes publiques déjà couvertes par les tests existants ; une signature changée casse la compilation |

## 10. Estimation

Six tâches, séquentielles :

1. `DebugActions` et le drapeau, avec leurs tests — le gros du travail
2. Les trois lignes dans le code existant (§6)
3. `DebugMenuDialog` et ses onglets, dont la liste d'ennemis ciblables
4. Le bouton dans `PauseDialog`
5. `dart analyze` propre, suite complète verte
6. La vérification manuelle du build release (§7.1)

Aucune dépendance nouvelle. Aucun asset. Aucune migration de sauvegarde — le format n'est pas
touché.
