# 🧠 Contexte Actuel de Développement (Active Context)

Ce document décrit le focus actif du projet, les accomplissements récents, et la trajectoire de développement à court terme pour **Hero's Draft**.

---

## 1. Focus Actuel du Projet

Nous réalisons une opération de **reverse engineering technique complet** de l'architecture logicielle, de la gestion d'état, de la responsivité dynamique, de l'internationalisation, et de la dette technique résiduelle de **Hero's Draft**. 
L'objectif est d'alimenter de façon exhaustive la "Memory Bank" du projet (située dans `.second_brain/_memory_bank/`) pour documenter les mécaniques du jeu sans introduire de modifications de code.

---

## 2. Accomplissements Récents

1. **Restructuration Globale de la Localisation (Achevée)** :
   - Migration absolue vers `AppLocalizations` fortement typé pour l'interface UI Flutter.
   - Élimination intégrale des variables `isFr` locales et des chaînes de caractères codées en dur.
   - Intégration du support multilingue double-champs dans les bases de données JSON (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`).
   - Traduction dynamique en temps réel des statuts de combat dans `StatusEffectsPanel`.
   - Rétablissement de la suite de tests unitaires et widget-tests au statut **100% VERT (58 tests passés avec succès)**.
   - Nettoyage du compilateur statique (`flutter analyze` vierge de toute erreur/avertissement).

2. **Génération Exhaustive de la Memory Bank** :
   - `systemPatterns.md` : Clarification de l'architecture découplée Flame ⇄ Riverpod, du z-indexing, et de la structure unifiée autour de `UiCard`.
   - `productContext.md` : Formalisation de la boucle de gameplay (Core Loop), de la génération de carte (DAG de 10 étages), du draft de stats indexé sur la chance (`luck`), et des règles de mana, d'armure et de debuffs.
   - `decisionLog.md` : Rédaction d'Architecture Decision Records (ADRs) documentant l'immuabilité de l'état, la responsivité dynamique (`scaleFactor`), la localisation data-driven, et la centralisation visuelle des cartes.
   - `progress.md` : Inventaire rigoureux du statut des fonctionnalités (100% opérationnelles, partielles comme `vulnerable` ou l'audio, et refactorings prioritaires).

---

## 3. Prochaines Étapes de Développement (Roadmap Technique)

Pour élever le projet à un niveau commercialisable de qualité premium, les chantiers suivants doivent être priorisés (Phase 7) :

1. **Parallélisation des I/O dans `GameDataService`** :
   - Remplacer les 7 appels consécutifs `await rootBundle.loadString(...)` par un unique chargement parallèle via `Future.wait([...])` pour éliminer le décalage de démarrage à froid.
2. **Système de Sauvegarde et Persistance (Autosave)** :
   - Concevoir un `SaveService` s'appuyant sur `shared_preferences`.
   - Sauvegarder automatiquement l'état logique (`RunState`, `DeckState`, `CombatState`, `InventoryState`) après chaque modification significative (fin de tour, gain d'or, obtention de carte).
   - Intégrer un bouton "Reprendre la partie" sur l'écran d'accueil.
3. **Infrastructure Audio Sensorielle** :
   - Ajouter la dépendance `flame_audio` dans `pubspec.yaml`.
   - Mettre en place un service central `AudioService` pilotant les musiques de fond dynamiques et les effets sonores contextuels (impacts, pop de texte flottant).
   - Résoudre l'ensemble des commentaires de commentaires `// TODO: Audio Hook`.
4. **Découplage des Écrans UI Monolithiques** :
   - Découper la classe géante `map_screen.dart` (**2471 lignes**) en composants unitaires réutilisables (Legend, NodeWidget, Tooltips, CustomPainter).
   - Externaliser la logique métier et de traversée de graphe dans un contrôleur focalisé `map_controller.dart`.
   - Décomposer `game_screen.dart` (**1667 lignes**) en extrayant ses overlays privés.
5. **Découplage du Routage de Navigation** :
   - Éradiquer les transitions codées en dur via `Navigator.push`.
   - Implémenter un contrôleur logique de navigation (`GoRouter` ou contrôleur d'état Riverpod réactif).
