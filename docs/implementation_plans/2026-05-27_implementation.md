## Phase 100 - Résolution du Problème de Ciblage d'Ennemis Identiques

- fix: Correction du ciblage lors du drag/play d'une carte sur un ennemi spécifique
    - Résolution d'un bug majeur où le fait de jouer une carte sur un ennemi spécifique (ex: le deuxième squelette) infligeait à tort des dégâts à l'autre ennemi identique (le premier squelette).
        - **Analyse du Problème** :
            - Lors du drag/release d'une carte vers un ennemi dans le moteur Flame, `_handlePlayerTargeting(...)` appelle directement `onPlayCard(card, target)`.
            - Dans `game_screen.dart`, `onPlayCard` appelait `combatController.applyPlayerCardPlay(...)` qui résolvait les effets de la carte via `EffectResolver` en se basant uniquement sur la variable globale `state.selectedEnemyId` de Riverpod.
            - Comme l'action standard de sélection `onSelectEnemy(target.id)` était court-circuitée en présence d'une carte focalisée, l'ID dans Riverpod n'était jamais mis à jour vers le squelette effectivement visé, faisant ainsi diverger le rendu visuel de la résolution logique.
        - **Correction de la Sélection Réactive (`lib/ui/screens/game_screen.dart`)** :
            - Injection d'un garde propre au début du callback `onPlayCard(card, target)`.
            - Dès qu'un ennemi est explicitement ciblé (`target != null`), nous invoquons immédiatement `combatController.selectEnemy(target.id)`.
            - Cela garantit que l'état de combat Riverpod synchronise son ciblage actif en temps réel juste avant la résolution des effets.
            - Avantage collatéral : La bordure de sélection jaune s'aligne désormais de manière fluide et dynamique sur l'ennemi effectivement frappé, améliorant le confort et le feedback visuel du joueur.

## Phase 101 - Rétablissement du Cycle de Tour et de Pioche du Joueur

- fix: Restauration de l'initialisation du tour du joueur en fin de phase ennemie
    - Résolution d'une régression critique introduite lors de la phase 4 du refactoring, où les cartes à jouer et la mana ne se régénéraient plus après la fin des attaques des ennemis.
        - **Analyse du Problème** :
            - Lors du découplage de combat, la transition de fin de riposte des monstres a été migrée vers le callback Riverpod `onEndEnemyTurn` (déclenché par le moteur Flame à l'issue de ses animations d'attaques séquentielles).
            - Cependant, `onEndEnemyTurn` se contentait d'appeler `combatController.endEnemyTurn()`, ce qui changeait la phase de combat dans `CombatState` mais oubliait de notifier et de déclencher les contrôleurs `RunController` (réinitialisation de mana) et `DeckController` (repioche de main).
            - Toute la logique d'initialisation de tour résidait dans l'ancien callback `onTurnEnded`, qui n'était plus jamais appelé à la suite des animations d'attaques ennemies.
        - **Implémentation du Démarrage Réactif du Tour Joueur (`lib/ui/screens/game_screen.dart`)** :
            - Définition d'une méthode d'aide mutualisée et robuste au sein de la classe `_GameScreenState` : `void _startPlayerNewTurn()`.
            - **Actions de début de tour centralisées** :
                - Réduction ou élimination des indicateurs d'avertissement de mana.
                - Incrémentation du compteur logique de tours du combat (`_turnCount`).
                - Appel nominal à `ref.read(runProvider.notifier).startTurn()` : réinitialisation de la mana à son maximum, décrémentation des cooldowns de compétences et réduction des buffs/debuffs actifs sur le héros.
                - Vérification de la pioche (`drawPile.length`) : mélange automatique de la défausse dans la pioche si celle-ci contient moins de 5 cartes.
                - Distribution instantanée d'une nouvelle main de 5 cartes via `ref.read(deckProvider.notifier).drawCards(5)`.
            - **Connexion des points de terminaison** :
                - Liaison nominale de `onTurnEnded` à la nouvelle méthode `_startPlayerNewTurn`.
                - Rénovation d' `onEndEnemyTurn` pour appeler séquentiellement `combatController.endEnemyTurn()` puis `_startPlayerNewTurn()`.
            - Avantage immédiat : Le cycle de combat (pioche, défausse, régénération de mana) est désormais parfaitement fluide, réactif, et s'exécute de façon cadencée et sécurisée.
