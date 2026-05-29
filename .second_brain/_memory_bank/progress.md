# 📊 État du Projet & Progrès (Progress)

Ce document dresse l'inventaire technique exhaustif et rigoureux des fonctionnalités opérationnelles de **Hero's Draft**, des éléments partiellement implémentés, et de la feuille de route des refactorings prioritaires.

---

## 1. Fonctionnalités 100% Opérationnelles

Le socle technique du moteur de deckbuilder roguelike est entièrement consolidé et fonctionnel :

### 🗺️ Génération et Progression Procédurale (World Map)
- **Graphe Acyclique Dirigé (DAG)** : Génération robuste d'actes à 10 étages avec variation de largeur (2 à 5 nœuds).
- **Navigation Réactive** : Validation stricte de l'accessibilité des nœuds (seuls les nœuds reliés au nœud complété actuel ou les nœuds du premier étage au départ sont activables).
- **Caméra Centrée** : Repositionnement et centrage automatique fluide du plateau à chaque transition d'acte ou déplacement.
- **Widgets Dédiés** : Affichage d'icônes spécifiques à chaque nœud (Combat, Élite, Boutique, Événement, Repos, Boss) avec tooltips explicatifs.

### 🧠 Gestion d'État Métier (Riverpod Controllers)
- **Logique de Run (`RunController`)** : Suivi permanent des PV, du mana, de la maîtrise d'armure, de la chance, et de l'acte en cours.
- **Logique de Combat (`CombatController`)** : Gestion séquentielle des phases (Joueur ⇄ Ennemi), sélection dynamique des cibles, génération d'intentions ennemies aléatoires ou par cycles (`intentStep`), application de dégâts aux ennemis, et résolution automatique des décès.
- **Piles de Cartes (`DeckNotifier`)** : Modélisation des 5 piles logiques (Master Deck, Pioche, Main, Défausse, Épuisement) avec mélange de défausse et pioche sécurisée.
- **Économie et Reliques (`InventoryController`)** : Gestion de l'or, de l'extension de boutique, et des déclencheurs de reliques passives (`RelicTrigger`).

### 🃏 Mécanique d'Auto-Merge et Cartes Scalées
- **Fusion Automatique** : Balayage et détection instantanée de 3 cartes identiques (ID + Level). Fusion définitive dans le deck en 1 exemplaire de niveau supérieur.
- **Échelonnement Statistique** : Mise à l'échelle automatique des valeurs d'effets (dégâts, armure, etc.) selon la formule `baseValue * (1 + (level - 1) * 0.5)`.

### 🈳 Internationalisation Absolue (i18n)
- **UI 100% Propre** : Éradication totale des variables locales `isFr`, labels bruts en français et commutateurs manuels. Traduction intégrale gérée par `AppLocalizations` fortement typé avec fichiers ARB.
- **Modèles de Données Multilingues** : Les JSON de données (`cards.json`, `heroes.json`, `enemies.json`, `relics.json`, `passives.json`) supportent des structures de double-champs (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`) résolues par `getName()` et `getDescription()` selon la locale active.
- **Statuts Localisés** : Le panel interactif des statuts traduit dynamiquement à la volée les altérations de combat à partir d'identifiants techniques neutres (`poison`, `weakness`, `strength_regen`).

### 🎨 Rendu Unifié (Flutter Widgets & Flame Engine)
- **Widget `UiCard`** : Remplacement de 6 rendus de cartes dupliqués par une structure unique, responsive, typée, calculant automatiquement sa description selon son niveau et sa locale.
- **Game Feel & Visual Juice (Flame)** : Tilt dynamique des cartes lors du drag, vibrations d'erreur (shake), explosions de particules de traînée, ligne de ciblage colorée réactive (`TargetingLine`), et texte flottant de dégâts (`FloatingText`).

### 🧪 Fiabilité et Assurance Qualité (Quality Assurance)
- **58 Tests Automatisés** : 100% de la suite de tests unitaires et widget-tests s'exécutent avec succès (statut **VERT**).
- **Zéro Avertissement** : `flutter analyze` retourne **0 erreur, 0 avertissement, 0 info**.

---

## 2. Fonctionnalités Partiellement Implémentées (Dette Métier)

Certaines mécaniques sont actuellement au stade de squelette technique ou de placeholders :

1. **Statut de Combat Vulnérable (`vulnerable`)** :
   - Déclaré dans les types d'effets, l'UI et traduisible dans le panel.
   - **Absence Logique** : Non pris en compte dans le calcul de dégâts physiques de `EffectResolver._calculateDamage()`.
2. **Statuts d'Altérations Secondaires (`burn`, `freeze`, `shock`)** :
   - Gabarits d'affichage présents dans `UiCard` pour la description.
   - **Absence Logique** : Non configurés dans `EffectResolver._createStatus` et absents des algorithmes de combat.
3. **Moteur Audio (TODOs Hooks)** :
   - Commentaires `// TODO: Audio Hook` disséminés dans les fichiers d'effets et d'interactions de cartes.
   - **Absence Technique** : Aucune dépendance audio (`flame_audio` ou `audioplayers`) dans le `pubspec.yaml`, et aucun service de contrôle audio implanté.

---

## 3. Chantiers de Refactoring Prioritaires (Roadmap Dette Technique)

Conformément aux rapports cliniques de dette technique, les refactorings suivants sont identifiés comme prioritaires :

### 1️⃣ Optimisation des I/O de Démarrage (Cold Start - Performance Niveaux Critique)
- **Problème** : `GameDataService.loadAll()` charge séquentiellement les 7 bases de données JSON à coup de 7 expressions `await` consécutives, ce qui bloque artificiellement le temps de démarrage de l'app.
- **Refactoring** : Remplacer par un chargement parallèle via un unique appel groupé `Future.wait([...])`.

### 2️⃣ Décomposition des God Classes (Architecture - Niveau Important)
- **Problème** : Deux fichiers UI concentrent trop de responsabilités :
  - `map_screen.dart` (**2471 lignes**) : Dessin des connexions, gestion du pan interactif, tooltips overlays, légende, modal de prévisualisation, validations logiques de traversée.
  - `game_screen.dart` (**1667 lignes**) : Contient 5 overlays privés imbriqués (`_PauseOverlay`, `_RewardOverlay`, `_DeathOverlay`...).
- **Refactoring** : Diviser ces monolithes en composants unitaires isolés dans des dossiers `widgets/` dédiés et externaliser la logique de traversée dans un `map_controller.dart`.

### 3️⃣ Implémentation de la Persistance et des Sauvegardes (Robustesse - Niveau Important)
- **Problème** : L'état logique de la run (`RunState`, `DeckState`, `CombatState`, `InventoryState`) réside uniquement en mémoire vive. Fermer le jeu ou subir un crash provoque la perte irrémédiable de la progression.
- **Refactoring** : Créer un service de persistance locale (`SaveService` via `shared_preferences` ou `sqlite`) sauvegardant l'état après chaque action majeure (obtention de carte, fin de combat, fin de tour) et ajouter un bouton "Reprendre la partie" sur l'écran d'accueil.

### 4️⃣ Découplage de la Navigation UI (Architecture - Niveau Moyen)
- **Problème** : Les transitions d'un écran à l'autre (ex : de la carte stratégique vers les combats ou la boutique) sont codées en dur dans les callbacks graphiques via des appels `Navigator.of(context).push()`.
- **Refactoring** : Implémenter un contrôleur de routage centralisé (ex : s'appuyant sur `GoRouter` ou un `NavigationController` réactif observant l'état de la run) pour fluidifier les transitions et faciliter la restauration de l'état lors du chargement.
