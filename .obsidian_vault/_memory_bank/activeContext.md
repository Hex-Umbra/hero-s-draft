# 🧠 Contexte Actuel de Développement (Active Context)

Ce document décrit le focus actif du projet, les accomplissements récents, et la trajectoire de développement à court terme pour **Hero's Draft**.

---

## 1. Focus Actuel du Projet

Le projet vient de finaliser un sprint d'implémentation majeur centré sur les trois axes suivants :
1. **Système de Statuts et Effets Élémentaires (Axe 1)** : Résolution complète de la brûlure (`burn`), du gel (`freeze`), de l'électrocution (`shock`), et de la vulnérabilité (`vulnerable`) affectant à la fois le Héros et les Ennemis.
2. **Rareté Dynamique et Fusion Interactive (Axe 2 & 4)** : Évolution dynamique des raretés à la place des niveaux de cartes basiques, fusion interactive de 3 cartes identiques avec transmission/consolidation de leurs améliorations et choix d'héritage, et équilibrage de cartes phares (`holy_shield`, `warcry`, `mana_surge`, `concentration`, `poison_stab`).
3. **Système de Forge Découplé (Axe 3)** : Génération probabiliste de slots d'améliorations, tirages pondérés par rareté et Tiers, relances individuelles avec coût exponentiel, et intégration de la boîte de dialogue `ForgeUpgradeDialog` sur l'écran de feu de camp `RestScreen`.

Le focus actuel s'oriente désormais vers la stabilisation de cette architecture, la validation des 78 tests unitaires/widgets (tous verts) et la préparation des prochaines étapes de refactoring et d'autosave.

---

## 2. Accomplissements Récents

1. **Intégration et Résolution des Effets Élémentaires & Vulnérabilité (Axe 1)** :
   - **Brûlure (`burn`)** : Dégâts de feu infligés au début du tour de la cible. Le tick applique des dégâts égaux à la valeur accumulée puis décrémente la valeur et la durée de 1.
   - **Gel (`freeze`)** : Divise par deux (arrondi) les dégâts de la prochaine attaque ennemie et décrémente immédiatement la durée du gel de 1.
   - **Électrocution (`shock`)** : Ajoute la valeur cumulée du statut à chaque dégât d'attaque direct subi par la cible.
   - **Vulnérabilité (`vulnerable`)** : Amplifie de 50% tous les dégâts reçus de manière universelle (s'applique aussi bien au Héros qu'aux Ennemis).
   - Résolutions métier câblées proprement dans `CombatController` et `EffectResolver` sans couplage Flame.

2. **Rareté Dynamique & Fusion Interactive (Axe 2 & 4)** :
   - Remplacement des niveaux numériques de cartes par une progression de rareté dynamique (`common` → `uncommon` → `rare` → `epic` → `legendary`). Les multiplicateurs de rareté adaptent les statistiques de base de la carte.
   - **Fusion interactive (3→1)** : Le joueur sélectionne exactement 3 exemplaires identiques. Le système fusionne automatiquement les upgrades de même ID en additionnant leurs Tiers, tout en limitant la quantité finale selon la capacité de la rareté supérieure. Un choix d'héritage d'améliorations est proposé de manière interactive.
   - **Équilibrage de cartes clés** :
     - `holy_shield` : Rebalancée avec le mot-clé `isExhaust` (Épuisement).
     - `warcry` : Dégâts à tous les ennemis (AoE) combinés avec un gain d'armure personnel.
     - `mana_surge` : Gain de mana, pioche, et mot-clé `isExhaust`.
     - `concentration` : Pioche de 2 cartes et mot-clé `isExhaust`.
     - `poison_stab` : Dégâts directs ciblés et application de poison.

3. **Système de Forge Découplé (Axe 3)** :
   - **Capacité de Forge** : Limite d'améliorations fixée à `baseMaxForgeUpgrades + rarityIndex`.
   - **Slots Probabilistes** : De 1 à 5 slots générés indépendamment avec des probabilités de `100%`, `50%`, `25%`, `10%`, et `2%`.
   - **Pools d'Améliorations** : Tirages clamps par rareté :
     - *Common* : Améliorations de statistiques de base, statuts limités aux cartes Attaque.
     - *Uncommon* : Cartes pioche/mana.
     - *Rare* : Effet persistant `enduring` (retrait Exhaust) réservé aux cartes non-pouvoir exhaustibles.
   - **Pondération et Tiers** : Probabilités de Tier calibrées à Tier I (80%), Tier II (15%), Tier III (5%). Tirages pondérés selon l'index de rareté de la carte.
   - **Relance individuelle (Reroll)** : Coût par slot indexé sur $20 \times 1.25^n$ (arrondi), consommant l'or de l'inventaire.
   - **Intégration premium** : Nouveau widget `ForgeUpgradeDialog` accessible depuis l'option Forge de l'écran `RestScreen` (anciennement Campfire).

4. **Système de Tutoriel Autonome & Refactoring Responsive (Sprint Précédent)** :
   - Module isolé sous `lib/tutorial/` avec son propre `TutorialEngine` et un état simulé `TutorialMockState`.
   - 13 étapes interactives adaptées aux smartphones portrait/paysage, web, et desktop via des structures responsives unifiées (`LayoutBuilder`, `FittedBox`, `SingleChildScrollView`, `Wrap`).
   - Ciblage double phase interactif et infobulles explicatives localisées.

5. **Assurance Qualité et Robustesse** :
   - **78 tests automatisés** unitaires, d'intégration, et widget-tests 100% verts (`test/unit/decoupled_forge_test.dart` et autres).
   - Analyse de code statique : **0 erreur** sous `flutter analyze`.

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
   - Résoudre l'ensemble des commentaires `// TODO: Audio Hook`.
4. **Découplage des Écrans UI Monolithiques** :
   - Découper la classe géante `map_screen.dart` (**2471 lignes**) en composants unitaires réutilisables.
   - Externaliser la logique métier et de traversée de graphe dans un contrôleur focalisé `map_controller.dart`.
   - Décomposer `game_screen.dart` (**1667 lignes**) en extrayant ses overlays privés.
5. **Découplage du Routage de Navigation** :
   - Éradiquer les transitions codées en dur via `Navigator.push`.
   - Implémenter un contrôleur logique de navigation (`GoRouter` ou contrôleur d'état Riverpod réactif).
