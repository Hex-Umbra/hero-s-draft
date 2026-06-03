# 🧠 Contexte Actuel de Développement (Active Context)

Ce document décrit le focus actif du projet, les accomplissements récents, et la trajectoire de développement à court terme pour **Hero's Draft**.

---

## 1. Focus Actuel du Projet

Le projet vient de finaliser un sprint d'implémentation centré sur l'équilibrage du catalogue de cartes, la refonte de la constitution du deck de départ et des corrections de stabilité associées :
1. **Refactoring des Cartes de Classe "Unique"** : Isolation des cartes de classe spécifiques dans un fichier dédié `hero_cards.json` sous la rareté `unique` (multiplicateur 1.0, non-fusionnables, non-disponibles en récompense/boutique) et liaison via le champ `"skills"` dans `heroes.json`.
2. **Standardisation Globale & VPM (Valeur Par Mana)** : Conversion de toutes les cartes globales de `cards.json` en rareté `common` et rééquilibrage de leurs statistiques autour de ratios standardisés.
3. **Refonte & Stabilisation du Draft Initial** : Nouvelle interface de grille dans `StarterDeckDraftScreen` permettant la sélection libre de 5 cartes globales parmi le catalogue complet (sans restriction de tirage aléatoire de 10 cartes). Les descriptions de localisation ont été corrigées en français/anglais, et les 78 tests unitaires et widget-tests ont été validés avec succès.

Le focus actuel s'oriente vers la préparation des prochaines étapes de refactoring technique et l'implémentation des nouveaux chantiers de la roadmap.

---

## 2. Accomplissements Récents

1. **Refactoring des Cartes de Classe "Unique" & Schémas JSON** :
   - Déplacement de toutes les cartes spécifiques de classe (`holy_shield`, `smite`, `reckless_strike`, `rage_form`, `magic_missile`, `mana_surge`) de `cards.json` vers `assets/data/hero_cards.json`.
   - Ajout de la rareté `unique` (enum `CardRarity`) mappée à un multiplicateur de 1.0 dans `card_instance.dart` et d'une limite de forge `baseMaxForgeUpgrades` fixée à 5.
   - Verrouillage de la fusion : les cartes de rareté `unique` ne peuvent pas être fusionnées (désactivé dans l'UI et interdit dans `deck_controller.dart`), et elles sont exclues des tables de draft de récompense ou de boutique en cours de run.
   - Restructuration de `heroes.json` avec l'intégration du champ `"skills"` contenant les identifiants de cartes de départ.
   - Création de la méthode d'extension `getHeroCards(gameData)` sur `HeroSkillsLink` pour charger dynamiquement les cartes de classe uniques à partir des compétences du héros sélectionné.

2. **Standardisation Globale et Rééquilibrage VPM** :
   - Uniformisation de la rareté de toutes les cartes globales restantes dans `cards.json` à `common`.
   - Rééquilibrage complet de leurs statistiques (coût, dégâts, blocage, statuts) autour d'un ratio de Valeur Par Mana (VPM) standardisé :
     - `heal_potion` : Coût 1 mana, Soin 4, Épuisement (`isExhaust: true`).
     - `iron_wall` : Coût 2 mana, Blocage 10.
     - `heavy_strike` : Coût 2 mana, Dégâts 12.

3. **Overhaul de l'Écran de Draft Initial (`StarterDeckDraftScreen`) & Corrections** :
   - Chargement direct de l'intégralité du catalogue des 15 cartes globales pour le choix initial (suppression totale de la logique de pool intermédiaire de 10 cartes tirées au hasard).
   - Retrait des importations et méthodes inutilisées (`dart:math` et `_rollRarity`).
   - Mise à jour des chaînes de localisation `draftDeckSubtitle` dans `app_en.arb` et `app_fr.arb` pour refléter la sélection libre des 5 cartes de départ (suppression de la mention "parmi les 10 proposées").
   - Les cartes uniques de classe du héros choisi sont automatiquement résolues via l'extension `getHeroCards(gameData)` et ajoutées pour constituer le deck de départ final.

4. **Intégration et Résolution des Effets Élémentaires & Vulnérabilité (Axe 1 - Précédent)** :
   - **Brûlure (`burn`)** : Dégâts de feu infligés au début du tour de la cible. Le tick applique des dégâts égaux à la valeur accumulée puis décrémente la valeur et la durée de 1.
   - **Gel (`freeze`)** : Divise par deux (arrondi) les dégâts de la prochaine attaque ennemie et décrémente immédiatement la durée du gel de 1.
   - **Électrocution (`shock`)** : Ajoute la valeur cumulée du statut à chaque dégât d'attaque direct subi par la cible.
   - **Vulnérabilité (`vulnerable`)** : Amplifie de 50% tous les dégâts reçus de manière universelle (s'applique aussi bien au Héros qu'aux Ennemis).
   - Résolutions métier câblées proprement dans `CombatController` et `EffectResolver` sans couplage Flame.

5. **Rareté Dynamique & Fusion Interactive (Axe 2 & 4 - Précédent)** :
   - Remplacement des niveaux numériques de cartes par une progression de rareté dynamique (`common` → `uncommon` → `rare` → `epic` → `legendary`). Les multiplicateurs de rareté adaptent les statistiques de base de la carte.
   - **Fusion interactive (3→1)** : Le joueur sélectionne exactement 3 exemplaires identiques. Le système fusionne automatiquement les upgrades de même ID en additionnant leurs Tiers, tout en limitant la quantité finale selon la capacité de la rareté supérieure. Un choix d'héritage d'améliorations est proposé de manière interactive.

6. **Système de Forge Découplé (Axe 3 - Précédent)** :
   - **Capacité de Forge** : Limite d'améliorations fixée à `baseMaxForgeUpgrades + rarityIndex`.
   - **Slots Probabilistes** : De 1 à 5 slots générés indépendamment avec des probabilités de `100%`, `50%`, `25%`, `10%`, et `2%`.
   - **Pools d'Améliorations** : Tirages clamps par rareté (Common: stats/debuffs; Uncommon: pioche/mana; Rare: enduring).
   - **Relance individuelle (Reroll)** : Coût par slot indexé sur $20 \times 1.25^n$ (arrondi), consommant l'or de l'inventaire.
   - **Intégration premium** : Nouveau widget `ForgeUpgradeDialog` accessible depuis l'option Forge de l'écran `RestScreen` (anciennement Campfire).

7. **Système de Tutoriel Autonome & Refactoring Responsive (Ancien)** :
   - Module isolé sous `lib/tutorial/` avec son propre `TutorialEngine` et un état simulé `TutorialMockState`.
   - 13 étapes interactives adaptées aux smartphones portrait/paysage, web, et desktop via des structures responsives unifiées (`LayoutBuilder`, `FittedBox`, `SingleChildScrollView`, `Wrap`).
   - Ciblage double phase interactif et infobulles explicatives localisées.

8. **Assurance Qualité et Robustesse** :
   - **78 tests automatisés** unitaires, d'intégration, et widget-tests 100% verts (tous passés avec succès).
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
