# 🧠 Contexte Actuel de Développement (Active Context)

Ce document décrit le focus actif du projet, les accomplissements récents, et la trajectoire de développement à court terme pour **Hero's Draft**.

---

## 1. Focus Actuel du Projet

Nous réalisons une opération de **reverse engineering technique complet** de l'architecture logicielle, de la gestion d'état, de la responsivité dynamique, de l'internationalisation, et de la dette technique résiduelle de **Hero's Draft**. 
L'objectif est d'alimenter de façon exhaustive la "Memory Bank" du projet (située dans `.obsidian_vault/_memory_bank/`) pour documenter les mécaniques du jeu sans introduire de modifications de code.

---

## 2. Accomplissements Récents

1. **Rénovation Graphique Premium & Jus Visuel (Visual Juice)** :
   - **Poli Visuel des Cartes Héros & Ennemis** : Effets d'impact et de dégâts dynamiques et synchronisés. Animation d'impact élastique (`Curves.elasticOut`), secousses haute-fréquence de la carte ciblée, et flashs de couleur découplés appliqués directement au sprite interne via `ColorEffect` (rouge/orange pour les coups normaux, vert émeraude pour le poison).
   - **Feedback de Blocage d'Armure** : Gonflement de scale (`1.08x`) et surbrillance de bordure couleur cyan vif (`Colors.cyanAccent`) pour illustrer visuellement l'absorption des dégâts par l'armure.
   - **Particules de Dégâts Vectorielles** : Éjection radiale de particules circulaires physiques (`spawnDamageParticles`) depuis le centre de la carte (12 particules vertes pour le poison, 15 rouges pour un coup normal, et 25 rouges pour un coup critique de 15 dégâts ou plus).
   - **Ligne de Ciblage Courbe de Bézier** : Remplacement de la ligne droite rigide par une courbe de Bézier quadratique fluide (`targeting_line.dart`). Des points pointillés défilent le long de la courbe avec fondu d'entrée/sortie aux extrémités. La tête de flèche s'oriente dynamiquement via le calcul de la tangente de la courbe à `t=1.0`. La couleur s'ajuste selon l'élément de la carte (orange pour le feu, cyan pour le froid, émeraude pour le poison, jaune pour la foudre, rouge/blanc pour la mêlée).
   - **Traînées Élémentaires & Rubans (RibbonTrails)** : Particules de traînées d'étincelles assorties à l'élément de la carte dans `CardAnimator`, et effet de ruban coloré (`RibbonTrail`) persistant lors du glissement de la carte dans `CardComponent`.
   - **Auras de Soin et de Bouclier** : Pour les compétences de soin, émission de 20 particules en croix dorées et vertes (`CrossParticle`) s'élevant depuis la carte du héros (`HeroCard`). Pour les compétences de blocage, affichage d'un dôme de force cyan clignotant (`ShieldDome`) avec des lignes de scan horizontales autour du héros.
   - **Icônes de Statut Vectorielles sur Canvas** : Remplacement des émojis texte dans `effect_icon.dart` par des icônes vectorielles dessinées à la main (bouclier métallique avec contours écusson, épées croisées avec gardes dorées, goutte de poison vert menthe, étoile dorée) avec un effet de lueur floutée (`MaskFilter.blur`).

2. **Système de Mort Synchronisé Z-Sync (Z-Sync Death System)** :
   - Résolution d'une condition de concurrence (race condition) visuelle où un ennemi mourant s'effaçait instantanément via `_applyCombatState` alors que la carte jouée était encore au milieu de son animation de mêlée ou de projectile, faisant frapper la carte dans le vide.
   - Introduction des flags d'état `isCardAnimating` dans `HerosDraftGame` et `isPendingDeath` dans `EnemyCard`.
   - Si un ennemi meurt durant l'animation d'une carte, son animation de disparition est différée. Il est marqué `isPendingDeath = true` et reste affiché solidement pour subir l'impact visuel du coup.
   - Dès que l'animation de la carte se termine et applique l'impact, son callback `onComplete` appelle `game.resolvePendingDeaths()`, déclenchant l'animation de rétrécissement (shrink) et de fondu (fade-out) de tous les ennemis marqués.
   - Les morts hors combat (ex: poison en début de tour) contournent ce délai pour s'exécuter instantanément.

3. **Restructuration Globale de la Localisation** :
   - Migration absolue vers `AppLocalizations` fortement typé pour l'interface UI Flutter.
   - Élimination intégrale des variables `isFr` locales et des chaînes de caractères codées en dur.
   - Intégration du support multilingue double-champs dans les bases de données JSON (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`).
   - Traduction dynamique en temps réel des statuts de combat dans `StatusEffectsPanel`.

4. **Validation, Assurance Qualité et Robustesse** :
   - Suite de tests unitaire mise à jour et validée : **59 tests unitaires et widget-tests 100% VERT (59 passés avec succès)**.
   - Analyse de code statique parfaite : **0 erreur, 0 warning, 0 info** sous `flutter analyze`.

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
