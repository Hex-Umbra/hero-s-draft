# Analyse Technique des Évolutions Futures (Flutter / Flame / Riverpod)

Ce document présente une analyse détaillée de l'implémentation technique des évolutions futures envisagées dans `proto_futures_evols.md`, adaptées à notre stack actuelle (Flutter + Flame + Riverpod).

## 1. Game Design & Mécaniques de Jeu (Core Loop)

### A. Vrai Système de Cartes (Deckbuilding)
*   **Le concept :** Passer de compétences fixes à un deck de cartes que l'on pioche, joue et défausse.
*   **Implémentation technique :** 
    *   **Riverpod :** Créer un `DeckState` contenant trois listes : `drawPile` (pioche), `hand` (main actuelle) et `discardPile` (défausse).
    *   **Modèles :** Créer une classe `Card` abstraite avec une méthode `play(Entity target)`.
    *   **Flutter/Flame :** Remplacer les boutons actuels par un composant visuel de "Main" où les cartes s'affichent en éventail au bas de l'écran (gérable via Flutter overlay ou directement dans Flame avec des événements de *Drag & Drop*).

### B. Système d'Intentions Ennemies (Télégraphie)
*   **Le concept :** Afficher ce que l'ennemi va faire au prochain tour pour que le joueur puisse réagir.
*   **Implémentation technique :**
    *   **Logique :** Au début du tour de l'ennemi (ou à la fin du tour précédent), l'IA décide de son prochain coup et le stocke dans son état.
    *   **Flame :** Ajouter un `PositionComponent` enfant au-dessus de l'ennemi. Ce composant lira l'intention (ex: `AttackIntent`, `DefendIntent`) et affichera le `Sprite` correspondant (une épée avec un chiffre "10", un bouclier, etc.).

### C. États Altérés (Status Effects)
*   **Le concept :** Poison, Vulnérabilité, Épines, etc.
*   **Implémentation technique :**
    *   **Modèles :** Créer une classe `StatusEffect` avec des méthodes comme `onTurnStart()`, `onDamageTaken()`, `onTurnEnd()`.
    *   **Entités :** Ajouter une liste `List<StatusEffect>` aux joueurs et ennemis.
    *   **Game Loop :** À chaque transition de phase (ex: début du tour du joueur), itérer sur ces statuts pour appliquer leurs effets (ex: retirer des PV pour le poison) et décrémenter leur durée.

### D. Carte de Progression (Pathing) & Reliques
*   **Implémentation technique :**
    *   **Carte :** Cela peut être une vue purement **Flutter** (pas besoin de Flame pour ça) affichée entre les combats. Un algorithme génère un graphe acyclique dirigé (DAG) pour créer des chemins avec différents nœuds (Combat, Feu de camp, Marchand).
    *   **Reliques :** Nécessite la mise en place d'un système d'événements (voir section Architecture Technique).

---

## 2. Interface et Expérience Utilisateur (UI/UX)

### A. Refonte Visuelle (Sprites & Backgrounds)
*   **Implémentation technique (Flame) :** 
    *   Remplacer nos actuels `RectangleComponent` par des `SpriteComponent` ou `SpriteAnimationComponent` (pour les personnages qui respirent/bougent).
    *   Charger les assets via `Flame.images.load()`.
    *   Ajouter un `SpriteComponent` en arrière-plan qui prend la taille de l'écran pour l'arène de combat.

### B. "Juice" (Animations, Particules, Screen Shake)
*   **Implémentation technique (Flame) :**
    *   **Animations :** Utiliser les `Effect` de Flame (ex: `MoveEffect.to` ou `SequenceEffect`) pour faire avancer le personnage quand il attaque, puis reculer.
    *   **Screen Shake :** Utiliser les capacités de la `CameraComponent` de Flame (ex: un script personnalisé qui modifie le `camera.viewfinder.position` de façon aléatoire pendant 0.2 secondes lors d'un gros coup).
    *   **Particules :** Utiliser le `ParticleSystemComponent` de Flame pour générer des explosions de pixels lors des impacts.

### C. Barres de vie visuelles & Tooltips
*   **Implémentation technique :**
    *   **Barre de vie :** Dessiner deux rectangles superposés dans Flame : un fond gris et une jauge rouge/verte par-dessus, dont la largeur est proportionnelle à `(currentHp / maxHp) * baseWidth`.
    *   **Tooltips :** Dans l'interface Flutter superposée (Overlay), écouter les appuis longs (`GestureDetector` ou `Tooltip` widget) pour afficher des fenêtres modales expliquant les effets d'une statistique ou d'un statut.

---

## 3. Architecture Technique et Scalabilité

### A. Séparation des Données et du Code (Data-Driven)
*   **Pourquoi c'est crucial :** Pour équilibrer un jeu de cartes, il faut modifier les valeurs constamment. Le faire dans le code Dart nécessite de recompiler à chaque fois, ce qui est très lent.
*   **Implémentation technique :** Créer des fichiers `.json` ou `.yaml` (ex: `cards.json`, `enemies.json`) dans un dossier `assets`. Utiliser la librairie `dart:convert` pour charger ces fichiers au démarrage de l'application et les transformer en objets Dart en mémoire.

### B. Système d'Événements Avancé (Event Bus)
*   **Le concept :** Pour implémenter des Reliques (ex: "Chaque fois que vous piochez une carte, gagnez 1 armure"), il ne faut pas lier la pioche directement à l'armure dans le code source de base pour éviter le code spaghetti.
*   **Implémentation technique :** Créer un `EventBus` global. 
    *   L'action de piocher émet un événement : `eventBus.fire(CardDrawnEvent(card))`.
    *   La relique écoute l'événement de manière asynchrone : `eventBus.on<CardDrawnEvent>().listen((event) { player.addArmor(1); })`.

### C. Arbres de comportement pour l'IA
*   **Implémentation technique :** Remplacer les comportements "hardcodés" par des listes de "Patterns" pour chaque ennemi. Par exemple, un archétype "Chevalier" aura un cycle : `[BuffArmure, AttaqueLegere, AttaqueLourde]`. Une variable d'index suit où il en est dans son cycle de décision.

### D. Sauvegarde et Reprise de Partie (Persistence)
*   **Implémentation technique :** Utiliser le package `shared_preferences` (pour des petites données) ou `hive` / `isar` (si l'état devient complexe). À la fin de chaque combat, on sérialise l'état actuel de la "Run" (le deck du joueur, ses PV actuels, le niveau atteint) en JSON et on le sauvegarde localement. Au lancement de l'appli, on vérifie si une sauvegarde existe pour proposer "Continuer la partie".

---

## Feuille de Route Suggérée (Priorisation)

Lorsque le développement de nouvelles fonctionnalités débutera, l'ordre d'implémentation le plus logique et structuré serait :

1.  **Architecture de base (Refactoring) :** Mettre en place le système "Data-Driven" (JSON) pour faciliter l'ajout futur d'ennemis et de compétences.
2.  **Core Loop :** Implémenter le vrai système de cartes (Deckbuilding) en remplaçant les compétences fixes.
3.  **Feedbacks :** Ajouter de l'intention ennemie (Telegraphing) et des barres de vie visuelles pour que le jeu commence à "parler" au joueur.
