# Rapport Technique : Architecture et Systèmes de Hero's Draft (MVP)

Ce document détaille l'architecture technique, les systèmes sous-jacents et l'implémentation des fonctionnalités du prototype *Hero's Draft*.

## 1. Architecture Globale
Le projet utilise une architecture hybride exploitant la puissance de deux frameworks majeurs du monde Flutter :
*   **Flutter & Riverpod (Interface & État Global)** : La gestion des menus, des surcouches UI (HUD, Compétences, Pause, Draft) et de l'état global de la partie (la "Run") est assurée par Flutter couplé à Riverpod. L'état est persistant en dehors du moteur de jeu.
*   **Flame (Moteur de Jeu & Combat)** : La scène de combat, le rendu des entités (cartes), les animations et la boucle séquentielle du tour par tour sont gérés par Flame.
*   **Synchronisation** : L'état global (Riverpod) est injecté dans le moteur Flame à chaque frame via une méthode `syncState()`. Les actions dans Flame (tuer un ennemi, subir des dégâts) déclenchent des callbacks qui mettent à jour l'état Riverpod, garantissant une séparation claire entre la logique métier/persistance et le rendu visuel.

## 2. Modèles de Données et Entités
*   **EntityStats (`entity_stats.dart`)** : Classe immuable représentant les statistiques de toute entité (Héros ou Ennemi). Elle contient : PV (max/actuel), Mana (max/actuel), Attaque, Armure, et Défense (en pourcentage).
    *   *Mécanique de Dégâts* : La méthode `takeDamage(amount)` implémente un calcul strict : 
        1. Les dégâts sont d'abord réduits par le pourcentage de Défense.
        2. Le reste est absorbé par l'Armure.
        3. Si l'Armure tombe à 0, le surplus est soustrait aux PV actuels.
*   **PlayerClass (`player_class.dart`)** : Définit les archétypes jouables (Paladin, Berserker, Mage) sous forme de constantes, embarquant leurs statistiques de départ (EntityStats) et leur description.

## 3. Gestion de l'État (Riverpod)
*   **RunState & RunController (`run_controller.dart`)** : Représente la source de vérité d'une partie en cours.
    *   Gère le niveau actuel, les statistiques du héros, sa classe.
    *   Suit l'état des temps de recharge (Cooldowns) des 2 compétences.
    *   Suit la durée des buffs temporaires (Buff d'attaque pour le Paladin, durée de Vol de vie pour le Berserker).
    *   Contient les méthodes métier pour : démarrer une run, passer au niveau suivant (et restaurer 50% du mana), appliquer les bonus de draft, consommer des ressources (Mana ou PV) pour lancer des sorts.

## 4. Le Moteur de Combat (Flame)
*   **HerosDraftGame (`heros_draft_game.dart`)** : La boucle de jeu principale gérant l'arène de combat.
    *   **Phases de Tour** : Utilise un enum `TurnPhase` (`player`, `enemy`) pour bloquer les interactions UI pendant l'exécution des attaques.
    *   **Système de Ciblage** : Permet de sélectionner une cible `EnemyCard` unique qui sera la cible des attaques basiques ou des compétences ciblées.
    *   **Exécution des Compétences** : Implémente la logique spécifique aux actions (Ex: `executeMageAoe` inflige 20% d'attaque à tous les ennemis, `executeBerserkerTargeted` vole 15% de l'armure de la cible).
    *   **Riposte (Intelligence Artificielle basique)** : Une fois le tour du joueur terminé (`executeTurn`), le jeu itère séquentiellement sur les ennemis restants (avec des délais asynchrones pour l'animation) pour infliger des dégâts au joueur via un callback vers Riverpod.
*   **Composants Visuels (Flame Components)** :
    *   **HeroCard & EnemyCard** : Étendent `PositionComponent` avec `TapCallbacks`. Ils gèrent leur propre rendu graphique, la mise à jour de leurs badges de statistiques (UI), et leurs animations de coup (`bumpAnimation`).
    *   **FloatingText** : Affiche des textes éphémères animés (dégâts subis en rouge, armure perdue/gagnée en bleu) lors des mises à jour des statistiques.

## 5. Système de Génération Procédurale (Encounter System)
*   **EncounterSystem (`encounter_system.dart`)** : Moteur mathématique de création d'ennemis pour offrir une difficulté infinie (Roguelike).
    *   **Génération de groupes** : Crée 1 à 3 ennemis par niveau (1 boss unique tous les 10 niveaux). Les statistiques globales requises pour le niveau sont divisées par le nombre d'ennemis générés pour maintenir l'équilibre.
    *   **Formules Mathématiques (PRD - Pseudo-Random Distribution)** : Les statistiques ennemies croissent de façon exponentielle via la formule : `S(N) = S0 * (1 + 0.05*N) * 1.15^P * 1.40^E`
        *   `N` : Niveau actuel.
        *   `P` (Paliers) : Augmente tous les 10 niveaux (Boss).
        *   `E` (Ères) : Augmente tous les 3 paliers de boss (niveau 30, 60...).
    *   **Défense Asymptotique** : La réduction des dégâts (Défense) des ennemis augmente selon une courbe asymptotique `Dmax * (1 - e^(-k*N))` plafonnant à 75%, évitant que les ennemis ne deviennent purement invulnérables aux hauts niveaux.

## 6. Interface Utilisateur (UI Flutter)
*   **GameScreen (`game_screen.dart`)** : Superpose des couches (Stack) sur le `GameWidget` de Flame :
    *   HUD (Niveau, Buffs) en haut à gauche.
    *   Bouton Pause en haut à droite.
    *   Bouton central "Fin de Tour".
    *   Zone d'actions en bas à droite : Génère dynamiquement les boutons de compétences selon la classe choisie. Gère la désactivation des boutons en fonction des Cooldowns et des ressources disponibles (Mana/PV).
*   **DraftScreen (`draft_screen.dart`)** : À la fin d'un combat, affiche une surcouche de sélection. Génère dynamiquement 3 choix aléatoires (avec répétition possible) parmi 4 buffs fixes (PV, Attaque, Armure, Mana). Déclenche l'application des statistiques via Riverpod et relance la boucle de jeu.
*   **Écrans de Navigation** : Les écrans de Menu Principal et de Sélection de Classe assurent une navigation classique via le `Navigator` de Flutter.