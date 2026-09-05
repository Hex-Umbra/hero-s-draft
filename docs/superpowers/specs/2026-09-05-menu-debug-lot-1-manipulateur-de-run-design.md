# Menu de debug — lot 1 : manipulateur de run — Conception

Date : 2026-09-05
Statut : **Livré** le 2026-09-05, branche `feat/menu-debug-lot-1`
Révision : v4 — v2 : ciblage des ennemis un par un plutôt qu'une action de vague (§4). v3 : la
vérification du build release s'est révélée **mécanisable** sur l'instantané AOT (§7.1). **v4 : le
drapeau de contamination est remplacé par un mode debug déclaré au lancement, et le verrou de
persistance descend dans `SaveService`** — la v3 n'empêchait que l'écriture, laissant `clear()`
détruire la vraie sauvegarde (§3.3)
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
| **D5** | Une run debug **ne persiste rien** : ni écriture, ni effacement | Une sauvegarde trafiquée est indistinguable d'une sauvegarde légitime ; et l'effacement est aussi destructeur que l'écriture — voir §3.3 |
| **D6** | Le mode est **déclaré au lancement**, pas déduit d'une modification | Un mode déclaré peut refuser toute persistance dès la première ligne, et s'afficher à l'écran ; un mode déduit ne réagit qu'après coup, et reste invisible |
| **D6b** | Le menu n'existe **que** dans une run debug, et `DebugActions` refuse d'agir ailleurs | Une run normale n'est alors pas seulement dépourvue de boutons : elle est intouchable, y compris par un appel égaré |
| **D7** | Pas de génération d'ennemis choisis | Demanderait d'exposer le calcul de scaling d'`EncounterSystem` ; §8 |

## 3. Architecture

### 3.1 `DebugActions`

`lib/game/services/debug_actions.dart` — classe statique, calquée sur `SaveService` : elle reçoit
un `Ref` et compose les contrôleurs. Elle ne détient aucun état.

Chaque méthode publique commence par la même garde : `kDebugMode` **et** une run debug en cours
(**D6b**). C'est la seconde barrière, celle qui tient même si un appel échappait un jour à
l'interface — une run normale n'est pas seulement dépourvue de boutons, elle est intouchable.
Le précédent du dépôt est `CombatDebugLogger`
(`lib/game/services/combat_debug_logger.dart:33`), gardé sur le seul `kDebugMode`.

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

### 3.3 Le mode debug, déclaré au lancement

`DebugRunState` — un `Notifier` dans `debug_run_controller.dart`, portant deux booléens :
`isDebugRun` (la run en cours) et `requested` (la prochaine). Le bouton **RUN DEBUG**, sous
« JOUER », pose `requested` ; `startNewRun` le consomme, deux écrans plus loin — la run ne naît
qu'après le choix de classe et le draft de départ.

> [!IMPORTANT]
> **Le verrou est dans `SaveService`, pas chez ses appelants**, et `clear()` y prend le même
> `RefReader` que `save()`.
>
> La conception précédente ne protégeait que l'écriture. Or `SaveService.clear` est appelé à trois
> endroits, dont `DeathOverlay` — et le menu offre « Perdre le combat ». Tester une mort effaçait
> donc la vraie sauvegarde. **L'effacement est aussi destructeur que l'écriture ; ne garder qu'une
> des deux portes ne garde rien.**
>
> Placé dans le service, le verrou couvre les quatre appelants externes, les deux appels internes
> du chemin « sauvegarde corrompue », et ceux que personne n'a encore écrits.

Deux pièges, tous deux silencieux, ont chacun leur test :

1. **L'intention qui traîne.** « RUN DEBUG », retour à l'accueil, puis « JOUER » : sans que le
   bouton normal efface la demande en attente, la run normale partirait en debug sans rien dire.
   Chaque bouton de départ déclare donc son mode.
2. **La sauvegarde chargée après une run debug.** `SaveService.load` rabaisse le mode dès sa
   première ligne — avant les `clear` du chemin corrompu, qu'il débloque au passage. Sans cela,
   enchaîner une run debug puis « Continuer » privait la vraie partie de toute sauvegarde pour le
   reste de la session.

Enfin, le bouton **RUN DEBUG** ne passe pas par la confirmation d'écrasement ni par le `clear()`
du chemin normal : une run qui ne persiste rien n'a rien à écraser, et emprunter ce chemin
détruirait la vraie partie avant même de commencer.

### 3.4 L'interface

`lib/ui/widgets/debug/` — un `DebugMenuDialog` construit sur le kit existant (`GameDialog`,
`GameButton`, `AppSpacing`), à onglets.

Le bouton d'ouverture est ajouté dans `PauseDialog`, sous `kDebugMode && isDebugRun`. `kDebugMode`
étant une constante de compilation, la condition entière est repliée à `false` en release : le
sous-arbre — dialogue, actions, imports — devient inatteignable, donc éliminé au tree-shaking.

`PauseDialog` porte aussi **le marqueur** — « RUN DEBUG — aucune sauvegarde ». Sans lui, rien à
l'écran ne distingue une run de test d'une vraie partie, et on peut jouer une heure avant de
comprendre pourquoi elle ne s'est jamais enregistrée. C'est ce que la conception précédente,
fondée sur un drapeau invisible, ne pouvait pas offrir.

Une seule insertion couvre les deux contextes, `PauseDialog` étant déjà appelé depuis
`game_screen.dart:541` et `map_screen.dart:142`.

Les champs numériques affichent la valeur courante et se rafraîchissent dès l'écriture : **ils sont
leur propre confirmation**, et une notification à chaque frappe validée ne serait que du bruit.
Seules les actions sans écho à l'écran — gagner un combat, vider une vague, changer d'acte, ajouter
une carte ou une relique — confirment par le système existant, via l'extension
`BuildContext.showNotification`.

Pas de rappel de redémarrage : **le lot 1 est immédiat.** L'avertissement de hot restart appartient
au lot 2, dont les écritures ne sont visibles qu'après rechargement du bundle d'assets.

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

Les ajouts à du code existant restent peu nombreux, et tous d'une ligne ou deux :

1. le bouton **RUN DEBUG** et la déclaration de mode dans `home_screen.dart`, sous `kDebugMode` ;
2. le bouton du menu dans `PauseDialog`, sous la même condition ;
3. la consommation de l'intention dans `startNewRun`, sous `kDebugMode` ;
4. le verrou dans `SaveService.save` et `clear`, plus la remise à zéro en tête de `load`.

Deux changements de signature en découlent, tous deux mécaniques : `SaveService.clear` prend un
`RefReader`, et `DeathOverlay` devient un `ConsumerWidget` pour le lui fournir.

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

`test/unit/debug_run_test.dart`, dans la lignée de `checkpoint_autosave_test.dart` :

- une run lancée normalement n'est pas une run debug ; le bouton **RUN DEBUG** marque bien celle
  qui naît deux écrans plus loin ;
- **le piège 1** — « RUN DEBUG » puis « JOUER » → la run est normale ;
- **le piège 2** — `SaveService.load` rabaisse le mode ;
- une run debug ne déclenche aucune écriture au checkpoint, quand une run normale, elle, en
  déclenche toujours (non-régression) ;
- **le test qui compte** — une run debug **n'efface pas** la sauvegarde existante, c'est-à-dire
  que le chemin `DeathOverlay` la laisse intacte ;
- `DebugActions` refuse d'agir hors d'une run debug.

### 7.1 L'absence en build release se vérifie sur l'instantané AOT

Les tests `flutter test` s'exécutent en mode debug, où `kDebugMode` vaut toujours `true` : aucun
d'eux ne peut rien dire du build publié. **Mais la vérification n'est pas condamnée à être
visuelle pour autant** — contrairement à ce que cette section affirmait avant d'être mise à
l'épreuve.

Les littéraux de chaînes du code Dart survivent dans l'instantané AOT
`build/windows/x64/runner/Release/data/app.so`. Y chercher un libellé du menu de debug répond donc
directement à la question, **à condition de vérifier d'abord que la recherche sait trouver quelque
chose** :

```bash
flutter build windows --release
SO=build/windows/x64/runner/Release/data/app.so
# Temoins : doivent etre PRESENTS, sinon la recherche ne prouve rien
for s in "Carte du Monde" "Menu Principal"; do grep -aq "$s" "$SO" && echo "temoin ok : $s"; done
# Libelles de debug : doivent etre ABSENTS
for s in "Menu de debug" "Soin complet" "Reliques possedees"; do
  grep -aq "$s" "$SO" && echo "FUITE : $s"
done
```

**Mesuré le 2026-09-05**, à la livraison du lot : les quatre témoins présents, les trois libellés
de debug absents. Le sous-arbre a bien été éliminé au tree-shaking.

Le témoin n'est pas une précaution de style. La première exécution de cette recherche n'a rien
trouvé **nulle part**, y compris pour des chaînes réellement présentes : le résultat négatif sur le
menu de debug ne valait alors rien. Une recherche incapable de trouver ne démontre aucune absence.

Cette vérification ne dispense pas d'un coup d'œil à l'écran à la livraison — ouvrir le menu pause
depuis la carte puis depuis un combat — mais elle le précède, parce qu'elle est reproductible et ne
dépend pas de l'attention de qui regarde.

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
| Le menu atteint un build publié | Élevée si elle survenait | Double garde `kDebugMode` (§3.1, §3.4), et recherche des libellés de debug dans l'instantané AOT du build release, témoins à l'appui (§7.1) |
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
