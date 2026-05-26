## Phase 95 - Modèles de Données purs pour le Combat (Refactoring - Étape 1)

- feat: Création des modèles de données purs EnemyInstance et CombatState pour détacher l'état logique de Flame
    - Conception et implémentation de structures de données pures et sérialisables pour représenter le combat, découplant définitivement la logique métier des composants graphiques Flame.
        - **Création du Modèle `EnemyInstance` (`lib/models/enemy_instance.dart`)** :
            - Représentation immuable d'un ennemi au sein d'une arène de combat.
            - Attributs intégrés : `id` (généré via un UUID v4 unique grâce au package `uuid`), `data` (référence immuable vers `EnemyData`), `stats` (instance de `EntityStats`), `currentIntent` (intention active du tour de type `EnemyIntent?`), `intentStep` (index cyclique des intentions), et `isBoss`.
            - Ajout d'une méthode `copyWith(...)` robuste incluant un drapeau utilitaire `clearIntent` pour réinitialiser l'intention active lors des fins de tour.
            - Implémentation des méthodes `toJson()` et `fromJson(...)` pour supporter la persistance future du combat à mi-parcours.
        - **Création du Modèle `CombatState` (`lib/models/combat_state.dart`)** :
            - Représentation complète de l'état logique d'un affrontement en cours.
            - Attributs intégrés : `enemies` (liste ordonnée des ennemis actifs `List<EnemyInstance>`), `turnPhase` (phase active de type `TurnPhase` : `player` ou `enemy`), `turnCount` (numéro du tour de combat), `selectedEnemyId` (ID de la cible actuelle choisie par le joueur), `isCombatEnded`, et `isVictory`.
            - Fourniture d'une énumération `TurnPhase` claire pour piloter la chronologie des phases de jeu.
            - Méthode `copyWith(...)` standard dotée d'une option `clearSelectedEnemy` pour nettoyer le ciblage du joueur lorsqu'un ennemi succombe.
            - Intégration de `toJson()` et `fromJson(...)` pour assurer une sérialisation en cascade et propre de la liste des ennemis.
        - **Enrichissement de `StatusEffect` et `EntityStats` pour la Sérialisation** :
            - Ajout des méthodes `toJson()` et `fromJson(...)` à la classe `StatusEffect` (`lib/models/status_effect.dart`) pour supporter l'encodage et décodage dynamique de la liste des statuts actifs.
            - Ajout des méthodes `toJson()` et `fromJson(...)` à la classe `EntityStats` (`lib/data/models/entity_stats.dart`), sérialisant les statistiques clés et mappant récursivement la collection des `StatusEffect` actifs.
        - **Robustesse et Compilation** :
            - Le typage est rigoureusement respecté et aucune modification n'impacte le bon fonctionnement du jeu à ce stade.

## Phase 96 - Contrôleur de Combat Riverpod (Refactoring - Étape 2)

- feat: Implémentation du CombatController Riverpod pour centraliser la logique métier du combat
    - Développement d'un contrôleur d'état pur étendant `StateNotifier<CombatState>` pour piloter les tours, le ciblage, les statuts et la résolution d'intentions ennemies hors de Flame.
        - **Création du `CombatController` (`lib/game/controllers/combat_controller.dart`)** :
            - Intégration de la méthode `initializeCombat` : prend en charge le spawn des ennemis via `EncounterSystem.generateEnemiesForLevel`, applique le coefficient multiplicateur de PV/dégâts selon la difficulté et le type de nœud (Boss = x3.0, Élite = x1.5), et détermine la première intention de chaque ennemi.
            - Intégration de la méthode `selectEnemy` : permet de cibler dynamiquement un ennemi via son ID.
            - Intégration de la méthode `applyPlayerCardPlay` : pré-structure l'application d'une carte par le joueur en coordonnant la résolution d'effets, le signalement de mort des ennemis, les passifs et les reliques. (Temporairement stubbé à cette étape pour préserver la compilabilité du projet avant le refactoring de `EffectResolver` à l'Étape 3).
            - Intégration de la méthode `resolveEnemyIntent` : applique synchroniquement l'intention d'un ennemi (Attaque, Défense, Buff de Force via statut).
            - Intégration de la méthode `startEnemyTurn` : boucle de début de tour ennemi qui résout les statuts récurrents (Poison, Métallisation/Régénération d'Armure), décrémente la durée des statuts et nettoie les morts éventuels.
            - Intégration de la méthode `endEnemyTurn` : calcule les intentions du tour suivant pour tous les monstres restants, incrémente le nombre de tours de combat et redonne la main au joueur.
            - Expositions de méthodes utilitaires d'écriture : `updateEnemyStats` (pour ajuster les PV/Armure des ennemis depuis les services) et `rollIntentForEnemy` / `tickEnemyStatuses`.
        - **Ajout du getter `effectiveIntent` sur `EnemyInstance` (`lib/models/enemy_instance.dart`)** :
            - Déplacement de la logique géométrique d'ajustement dynamique de l'attaque ennemie (en fonction du multiplicateur de spawn et des buffs de force accumulés en combat) vers le modèle purement logique `EnemyInstance`.
        - **Fourniture globale** :
            - Enregistrement du fournisseur Riverpod global `combatProvider`.

