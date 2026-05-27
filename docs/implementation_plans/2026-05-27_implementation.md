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

## Phase 102 - Résolution du Plantage CanvasKit WebAssembly (tas de mémoire sature)

- fix: Optimisation du tracé des liaisons animées pour éliminer les fuites de mémoire WASM à 60 FPS
    - Résolution d'un plantage critique `RuntimeError: Aborted()` survenant après un certain temps de jeu sur la carte du monde en mode Flutter Web (CanvasKit).
        - **Analyse du Problème** :
            - Le tracé animé des liaisons entre nœuds (`MapConnectionPainter`) instanciait de nouveaux objets `Path` et calculait de façon continue des métriques complexes via `computeMetrics()` et `extractPath()` à chaque frame.
            - Sous WebAssembly CanvasKit (Skia), ces objets ne sont pas libérés immédiatement par le Garbage Collector de Dart car ce sont des allocations natives. L'accumulation ultra-rapide d'objets natives sature le tas WASM, provoquant un plantage irrécupérable de l'application.
            - De plus, l'absence de `RepaintBoundary` forçait Flutter à repeindre l'intégralité du Stack (les 15+ widgets de nœuds complexes, pion du joueur et HUD) à chaque frame, surchargeant le CPU/GPU.
        - **Refactoring Vectoriel Mathématique Pur (`lib/ui/widgets/map/map_connection_painter.dart`)** :
            - Élimination totale des allocations d'objets `Path`, `computeMetrics` et `extractPath`.
            - Écriture d'un algorithme de découpe vectoriel mathématique direct dans Dart : calcul de la distance euclidienne entre points (`sqrt`), vecteur unitaire directionnel et découpe manuelle des coordonnées des segments à dessiner.
            - Utilisation directe du tracé primitif optimisé de Skia `canvas.drawLine(...)` pour dessiner chaque pointillé.
            - Avantage : **0 allocation WASM** lors de l'exécution, évitant définitivement tout débordement de mémoire et allégeant considérablement l'usage CPU.
        - **Isolation du Calque Graphique (`lib/ui/screens/map_screen.dart`)** :
            - Enveloppement du widget `CustomPaint` (contenant le peintre de connexions) dans un `RepaintBoundary`.
            - Cela crée un calque de rendu indépendant. L'animation des pointillés se redessine à 60 FPS uniquement sur son propre plan isolé, libérant les nœuds de carte statiques et le HUD d'être repeints inutilement.

## Phase 103 - Rénovation Architecturale : Centralisation de la Boutique et des Événements dans Riverpod (Étape 1)

- refactor: Migration de la logique métier de la Boutique et des Événements vers la couche de gestion d'état Riverpod
    - **Analyse du Problème initial** :
        - Les fichiers `shop_screen.dart` et `event_screen.dart` centralisaient de manière inline des règles métiers et du hasard (shuffling des cartes, calcul de prix selon la rareté, duplication, purge, tirage d'événements et calcul des probabilités pondérées d'obtention de reliques par rapport à la chance (*Luck*)).
        - Cette imbrication de logique interdisait les tests unitaires et créait un couplage fort entre l'interface utilisateur et le gameplay.
    - **Mise en place de l'infrastructure Boutique (`lib/models/shop_state.dart`, `lib/game/controllers/shop_controller.dart`)** :
        - Définition d'un état immutable `ShopState` contenant la liste des cartes en vente (`cardsForSale`) et le marqueur de soin acheté (`purchasedHeal`).
        - Création du `ShopController` gérant de manière isolée l'initialisation, l'achat de cartes, le reroll, l'achat de soin, l'expansion, la purge et le clonage.
        - Refactoring de `shop_screen.dart` pour observer réactivement `shopProvider` et déléguer toutes les actions utilisateur. Intégration de `Future.microtask` pour initialiser le stock à l'entrée afin d'éviter toute violation de cycle de build Riverpod.
    - **Mise en place de l'infrastructure Événement (`lib/models/event_state.dart`, `lib/game/controllers/event_controller.dart`)** :
        - Définition d'un état immutable `EventState` contenant l'événement actif (`activeEvent`), le choix sélectionné (`selectedChoice`) et le marqueur de résolution (`isResolved`).
        - Création de `EventController` centralisant les tirages d'événements et le traitement de leurs conséquences (or, dégâts, soin, modificateurs de stats du héros et gains de reliques pondérés par la chance).
        - Refactoring de `event_screen.dart` pour décharger toute sa logique de gameplay.
    - **Écriture et passage des Tests Unitaires & Widgets** :
        - Création de `test/unit/shop_controller_test.dart` et `test/unit/event_controller_test.dart` validant de manière déterministe les transactions, le hasard boutique et les calculs de probabilités de reliques.
        - Validation : Passage de **14 nouveaux tests**, portant le total du projet à **47 tests unitaires et widget validés avec 100% de réussite** et 0 avertissement `flutter analyze`.

## Phase 104 - Rénovation Architecturale : Découpage du Mega-Contrôleur RunController & Harmonisation des Modèles (Étape 2)

- refactor: Découplage de l'inventaire et des compétences de RunController et réorganisation du modèle EntityStats
    - **Analyse du Problème initial** :
        - Le fichier `RunController` (510 lignes) agissait comme un "God Class", mélangeant à la fois les données de progression globale (niveau, carte, classe, PV max/actuel), l'inventaire d'or et de reliques, ainsi que le suivi des cooldowns des compétences actives.
        - Cette centralisation surchargeait le contrôleur principal, provoquait des notifications de reconstruction inutiles sur toute l'interface et compliquait le code et les tests.
        - De plus, le fichier `entity_stats.dart` était localisé dans `lib/data/models/`, rompant l'uniformité avec les autres modèles situés dans `lib/models/`.
    - **Harmonisation des Modèles** :
        - Déplacement physique de `entity_stats.dart` vers `lib/models/entity_stats.dart`.
        - Remplacement des imports de `entity_stats.dart` dans 7 fichiers source (`enemy_card.dart`, `hero_card.dart`, `combat_controller.dart`, `run_controller.dart`, `heros_draft_game.dart`, `effect_resolver.dart`, `enemy_instance.dart`) et 2 fichiers de tests (`combat_controller_test.dart`, `effect_resolver_test.dart`).
    - **Découplage de l'Inventaire (Or et Reliques)** :
        - Création d'un état immutable `InventoryState` (`lib/models/inventory_state.dart`) pour stocker `gold`, `relics`, et `bonusShopCards`.
        - Création du `InventoryController` (`lib/game/controllers/inventory_controller.dart`) étendant `StateNotifier<InventoryState>` pour centraliser les gains/pertes d'or, l'ajout de reliques, l'achat d'expansion et les réinitialisations.
    - **Découplage des Compétences (Sorts et Cooldowns)** :
        - Création d'un état immutable `SkillState` (`lib/models/skill_state.dart`) pour stocker les cooldowns `skill1Cooldown` et `skill2Cooldown`.
        - Création du `SkillController` (`lib/game/controllers/skill_controller.dart`) pour centraliser le déclenchement des compétences (avec validation et consommation de ressources) et l'écoulement des tours.
    - **Simplification de `RunController` & Raccordement UI/Tests** :
        - Retrait des variables et fonctions d'or, de reliques et de cooldowns de `RunState` et `RunController`. Passage de Riverpod `Ref` à son constructeur pour lui permettre de piloter réactivement `inventoryProvider` et `skillProvider`.
        - Adaptation de la couché UI (`shop_screen.dart`, `event_screen.dart`, `map_screen.dart`, `game_screen.dart`, `draft_screen.dart`, `relics_dialog.dart`) pour observer et manipuler réactivement ces nouveaux providers spécialisés.
    - **Validation & Rénovation des Tests** :
        - Rénovation complète de tous les tests unitaires et widget existants pour instancier les contrôleurs via un `ProviderContainer` Riverpod, reproduisant fidèlement le comportement découplé de production.
        - Création de `test/unit/inventory_controller_test.dart` et `test/unit/skill_controller_test.dart` (validation déterministe des transactions d'or, des reliques, des ticks de cooldowns et des ressources).
        - **Résultat** : **58 tests unitaires et widget validés avec 100% de réussite** et 0 avertissement `flutter analyze`.

