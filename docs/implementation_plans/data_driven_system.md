# Plan d'Implémentation : Système Data-Driven

Ce document décrit le plan d'action étape par étape pour migrer les données "hardcodées" du jeu (ennemis, héros, compétences) vers un système Data-Driven basé sur des fichiers JSON. Cela rendra le jeu beaucoup plus facile à équilibrer et à étendre, et posera les bases pour le système de Deckbuilding.

## Objectif global
Extraire les statistiques et les comportements de base des classes Dart vers des fichiers de configuration `JSON` situés dans les `assets`. Ces données seront chargées au démarrage de l'application via `Riverpod` et utilisées pour instancier les entités en jeu.

---

## Phase 1 : Configuration des Assets et Modèles de Données (DTOs)

**Objectifs :** Préparer la structure des fichiers de données et les classes Dart qui permettront de les lire.

1.  **Création du dossier de données :**
    *   Créer un répertoire `assets/data/` à la racine du projet.
    *   Créer trois fichiers JSON (vides pour l'instant) : `enemies.json`, `heroes.json`, et `skills.json`.
2.  **Mise à jour du `pubspec.yaml` :**
    *   Déclarer le dossier `assets/data/` dans la section `assets:` pour que Flutter puisse les inclure dans le build final.
3.  **Création des Data Models (Modèles Dart) :**
    *   Créer un dossier `lib/models/data/` (ou adapter selon l'arborescence actuelle).
    *   Créer les classes Dart : `EnemyData`, `HeroData`, `SkillData`.
    *   Implémenter les méthodes `fromJson` pour désérialiser le JSON.
        *   *Exemple de champs pour `EnemyData` :* `id`, `name`, `maxHp`, `baseDamage`, `spritePath`.

## Phase 2 : Système de Chargement (Riverpod)

**Objectifs :** Lire les fichiers JSON au démarrage et les rendre disponibles globalement et de manière synchrone pendant toute la session de jeu.

1.  **Création du Service de Chargement :**
    *   Créer une classe de service qui utilise `rootBundle.loadString('assets/data/...json')` pour lire le texte, puis `jsonDecode` pour transformer la chaîne en structure de données Dart (List/Map).
2.  **Création du Provider Riverpod :**
    *   Créer un `FutureProvider` nommé `gameDataLoaderProvider` qui appelle le service de chargement et retourne un objet "Registre" (ex: `GameDataRegistry`) contenant toutes les données chargées en mémoire.
3.  **Synchronisation au démarrage de l'application :**
    *   Dans le `main.dart` ou l'écran de chargement (Splash Screen), utiliser `ref.watch(gameDataLoaderProvider).when(...)` pour forcer l'application à attendre la fin du chargement des JSON avant d'afficher le menu principal.

## Phase 3 : Refactoring des Ennemis

**Objectifs :** Générer les ennemis à partir des données JSON plutôt que de classes Dart statiques.

1.  **Mise à jour du générateur d'ennemis :**
    *   Modifier le code responsable de faire apparaître un nouvel ennemi au début d'un combat.
    *   Le faire piocher aléatoirement (ou selon la difficulté/niveau) un objet `EnemyData` depuis le `GameDataRegistry`.
2.  **Injection des données dans l'entité de Combat :**
    *   Modifier la logique d'état (`EnemyState`) et potentiellement l'entité Flame (`EnemyComponent`) pour accepter un `EnemyData` lors de leur création.
    *   Initialiser les statistiques réelles (PV max, dégâts) en se basant strictement sur cet objet de données.

## Phase 4 : Refactoring des Héros (Classes du Joueur)

**Objectifs :** Extraire les statistiques de départ du joueur (Paladin, Mage, etc.) dans les données.

1.  **Mise à jour de l'écran de sélection de classe :**
    *   L'écran de choix de héros au début d'une "Run" doit générer ses boutons dynamiquement en lisant la liste des `HeroData` depuis le registre (nom de la classe, description, icône).
2.  **Initialisation de l'état du Joueur :**
    *   Lors du lancement du premier combat, initialiser le `PlayerState` avec les statistiques issues du `HeroData` sélectionné (PV de départ, mana maximum, force de base).

## Phase 5 : Refactoring des Compétences (Préparation au Deckbuilding)

**Objectifs :** Séparer la définition des compétences (effets, coûts) de l'interface utilisateur et de la logique "en dur".

1.  **Définition des actions dans le JSON (`skills.json`) :**
    *   Définir chaque compétence avec son `id`, `nom`, `coût en mana`, et un système de types d'effets (ex: `effectType: "damage"`, `effectValue: 10` ou `effectType: "heal"`, `effectValue: 5`).
2.  **Création d'un exécuteur de compétences :**
    *   Remplacer les fonctions hardcodées (ex: `executeHeal()`) par un moteur générique capable de lire un `SkillData` et d'appliquer l'effet dynamique à la cible appropriée (joueur ou ennemi).
    *   *Note importante :* C'est la base indispensable pour introduire les "Cartes" dans le futur, car chaque carte ne sera au final qu'une représentation visuelle d'un objet `SkillData`.
