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
