# Plan d'Implémentation : Feedbacks et UI/UX (Phase 3)

Ce document décrit le plan d'action exhaustif pour améliorer l'aspect visuel et l'expérience utilisateur (le "Juice"). L'objectif est de remplacer les éléments visuels de prototypage (formes géométriques simples) par de véritables assets, et d'ajouter des feedbacks clairs (animations, secousses, barres de vie, intentions) pour que le jeu "réponde" aux actions du joueur.

Ce plan se base sur la section 2 du rapport d'analyse technique (`analyse_techniques_evols.md`).

---

## Phase 1 : Remplacement des Assets Visuels (Sprites & Décors)

**Objectifs :** Intégrer les véritables graphismes du jeu via le moteur Flame.

1.  **Gestionnaire d'Assets :**
    *   S'assurer que toutes les images sont stockées dans `assets/images/` et déclarées dans le `pubspec.yaml`.
    *   Pré-charger les images principales au démarrage du jeu via `Flame.images.loadAll([...])` pour éviter les saccades en plein combat.
2.  **Arrière-plan (Background) :**
    *   Créer un `BackgroundComponent` (héritant de `SpriteComponent`).
    *   Lui assigner la taille de la fenêtre (`size = gameRef.size`) pour qu'il remplisse l'écran.
    *   Ce background pourra changer en fonction du biome ou du niveau sélectionné.
3.  **Sprites des Entités :**
    *   Remplacer les `RectangleComponent` représentant le Joueur et les Ennemis par des `SpriteComponent`.
    *   *Évolution possible :* Utiliser des `SpriteAnimationComponent` si l'on dispose de *spritesheets* pour donner une animation d'attente (Idle) aux personnages pour qu'ils aient l'air vivants.
    *   Lier le chemin de l'image (`spritePath`) chargé depuis le JSON (Système Data-Driven) à ce composant.

## Phase 2 : Feedbacks d'Information (Lisibilité du Combat)

**Objectifs :** Donner au joueur toutes les informations nécessaires pour prendre ses décisions tactiques en un coup d'œil.

1.  **Barres de Vie Visuelles (Health Bars) :**
    *   Créer un composant `HealthBarComponent` rattaché à chaque entité (Joueur et Ennemis).
    *   Utiliser deux rectangles superposés : un fond gris foncé et une barre rouge ou verte par-dessus.
    *   La largeur de la barre de couleur se calcule dynamiquement : `(currentHp / maxHp) * baseWidth`.
    *   Ajouter un `TextComponent` au centre ou au-dessus de la barre affichant les valeurs textuelles ("15 / 50") pour plus de précision.
2.  **Système d'Intentions Ennemies (Telegraphing) :**
    *   C'est le cœur stratégique : le joueur doit savoir ce que l'ennemi compte faire.
    *   Au début du tour (ou à la fin du tour précédent), l'IA décide de sa prochaine action.
    *   Afficher un composant (`PositionComponent` avec icône + texte) juste au-dessus de la tête de l'ennemi.
    *   *Exemples :* Une icône d'épée avec le chiffre "12" s'il va attaquer, une icône de bouclier s'il va se défendre.
3.  **Floating Text (Nombres de Dégâts) :**
    *   Lorsqu'une entité subit des dégâts ou des soins, instancier un `TextComponent` à sa position.
    *   Appliquer un `MoveEffect` pour que le texte monte doucement, combiné à un `OpacityEffect` pour qu'il s'estompe et disparaisse au bout de 1 ou 2 secondes.
    *   Couleur selon le type : Rouge (Dégâts reçus), Vert (Soin), Jaune (Coup Critique).

## Phase 3 : Le "Juice" (Animations et Feedbacks Viscéraux)

**Objectifs :** Rendre les combats dynamiques, percutants et satisfaisants.

1.  **Animations d'Attaque (Dash) :**
    *   Lorsqu'une entité attaque, elle ne doit pas rester statique.
    *   Créer une `SequenceEffect` avec Flame :
        *   1. L'entité avance rapidement vers sa cible (`MoveEffect.to` avec une courbe d'accélération).
        *   2. L'impact est calculé.
        *   3. L'entité recule à sa position de base (`MoveEffect.to` vers la position de départ).
2.  **Screen Shake (Tremblement de Caméra) :**
    *   Pour les impacts très puissants (gros dégâts, coup final d'un boss).
    *   Créer un script qui manipule temporairement le `camera.viewfinder.position` de la `CameraComponent` de Flame.
    *   Le script décale la caméra de quelques pixels dans des directions aléatoires pendant 0.2 à 0.5 secondes avant de la recentrer.
3.  **Système de Particules :**
    *   Créer des effets de particules simples au moment de l'impact (ex: de petites particules rouges s'éparpillant pour le sang, ou des particules bleues pour la magie).
    *   Utiliser le `ParticleSystemComponent` de Flame couplé à un `Timer` pour les nettoyer automatiquement après leur exécution.

## Phase 4 : Accessibilité et UI Avancée (Flutter Overlay)

**Objectifs :** Rendre l'interface utilisateur pratique et expliquer les mécaniques complexes sans surcharger l'écran.

1.  **Affichage des Statuts (Buffs/Debuffs) :**
    *   Ajouter une ligne de petites icônes sous la barre de vie des entités.
    *   Chaque icône représente un état actif (Poison, Force, Vulnérabilité) avec un petit chiffre indiquant le nombre de tours restants ou la valeur du buff.
2.  **Tooltips (Infobulles Explicatives) :**
    *   Utiliser la couche UI de Flutter (Overlay) qui gère parfaitement les interactions complexes.
    *   Lier des `GestureDetector` (pour les appuis longs ou survols de souris) sur les éléments de l'Overlay (ou écouter les `TapCallbacks` dans Flame pour déclencher l'ouverture d'un Widget Flutter).
    *   Afficher une fenêtre modale flottante expliquant l'effet : "Vulnérabilité : La cible subit 50% de dégâts supplémentaires."
