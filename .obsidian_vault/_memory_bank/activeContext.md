# 🧠 Contexte Actuel de Développement (Active Context)

Ce document décrit le focus actif du projet, les accomplissements récents, et la trajectoire de développement à court terme pour **Hero's Draft**.

## 1. Focus Actuel du Projet

Le projet vient de finaliser la mise en œuvre de la génération procédurale robuste de la carte du monde (Section 5) et le polissage de l'UI responsive et adaptative en combat (Section 6). L'ensemble des 100 tests unitaires et d'intégration passe au vert avec 0 avertissement.

Le focus actuel s'oriente vers la préparation des prochaines étapes de refactoring technique de la Phase 4 (Sauvegarde, parallélisation I/O, audio).

---

## 2. Accomplissements Récents

1. **Génération et Progression de la Carte (Section 5)** :
   - **Algorithme anti-répétition de chemin** : Garantit de manière stricte qu'aucun chemin dans le graphe ne contient 3 nœuds consécutifs du même type (Élite ou Repos).
   - **Quotas de types de nœuds (Solver)** : Maintient un équilibre statistique optimal sur l'ensemble de la carte : Combat (12-22), Élite (3-6), Repos (3-6), Shop (2-5), Event (4-9).
   - **Chokepoints structurels forcés** : Étage 5 (chokepoint à 1 nœud de type Élite) et Étage 8 (tous les nœuds sont obligatoirement de type Repos, garantissant une pause avant les boss).
   - **Branchements de Boss multiples** : L'étage 9 présente 3 nœuds de boss distincts différenciés par leur position horizontale pour offrir des récompenses de combat uniques.
   - **Récompenses de Boss thématiques basées sur la position** :
     - **Position gauche (x = 0)** : Offre un dialogue interactif permettant d'ajouter entre 1 et 3 cartes gratuites dans le deck (icône Cartes).
     - **Position centrale (x = 1)** : Multiplie par 2 l'expérience globale accumulée lors de la victoire (icône Magie/XP).
     - **Position droite (x = 2)** : Garantie de butin de relique premium améliorée (minimum Uncommon, avec des chances de tirage Legendary et Epic accrues, icône Diamant).

2. **Polissage et Responsivité en Combat (Section 6)** :
   - **HUD Responsive** : Adaptabilité complète de la hauteur et de la largeur du panneau de combat avec clamps de sécurité pour toutes les tailles d'écran (mobiles, desktop, web).
   - **Badges de Ciblage Bilingues** : Affichage d'indicateurs de ciblage clairs sur les cartes (Single Target, All Enemies, Self) traduits à la volée en français ('Cible unique', 'Tous les ennemis', 'Soi-même') et sécurisés par un widget `FittedBox`.
   - **Indicateurs de Carte du Monde** : Badge numérique dynamique pour les reliques possédées et badge numérique sur le bouton du deck affichant la taille actuelle du master deck.
   - **Scaling Échelle des Ennemis** : Ajustement proportionnel de la taille des cartes d'ennemis sur le plateau Flame pour refléter visuellement leur importance et leur niveau.

3. **Refactoring des Cartes de Classe "Unique" & Schémas JSON** :
   - Déplacement de toutes les cartes spécifiques de classe (`holy_shield`, `smite`, `reckless_strike`, `rage_form`, `magic_missile`, `mana_surge`) de `cards.json` vers `assets/data/hero_cards.json`.
   - Ajout de la rareté `unique` (enum `CardRarity`) mappée à un multiplicateur de 1.0 dans `card_instance.dart` et d'une limite de forge `baseMaxForgeUpgrades` fixée à 5.
   - Verrouillage de la fusion : les cartes de rareté `unique` ne peuvent pas être fusionnées (désactivé dans l'UI et interdit dans `deck_controller.dart`), et elles sont exclues des tables de draft de récompense ou de boutique en cours de run.
   - Restructuration de `heroes.json` avec l'intégration du champ `"skills"` contenant les identifiants de cartes de départ.
   - Création de la méthode d'extension `getHeroCards(gameData)` sur `HeroSkillsLink` pour charger dynamiquement les cartes de classe uniques à partir des compétences du héros sélectionné.

4. **Standardisation Globale et Rééquilibrage VPM** :
   - Uniformisation de la rareté de toutes les cartes globales restantes dans `cards.json` à `common`.
   - Rééquilibrage complet de leurs statistiques (coût, dégâts, blocage, statuts) autour d'un ratio de Valeur Par Mana (VPM) standardisé :
     - `heal_potion` : Coût 1 mana, Soin 4, Épuisement (`isExhaust: true`).
     - `iron_wall` : Coût 2 mana, Blocage 10.
     - `heavy_strike` : Coût 2 mana, Dégâts 12.

5. **Overhaul de l'Écran de Draft Initial (`StarterDeckDraftScreen`) & Corrections** :
   - Chargement direct de l'intégralité du catalogue des 15 cartes globales pour le choix initial (suppression totale de la logique de pool intermédiaire de 10 cartes tirées au hasard).
   - Retrait des importations et méthodes inutilisées (`dart:math` et `_rollRarity`).
   - Mise à jour des chaînes de localisation `draftDeckSubtitle` dans `app_en.arb` et `app_fr.arb` pour refléter la sélection libre des 5 cartes de départ (suppression de la mention "parmi les 10 proposées").
   - Les cartes uniques de classe du héros choisi sont automatiquement résolues via l'extension `getHeroCards(gameData)` et ajoutées pour constituer le deck de départ final.

6. **Intégration et Résolution des Effets Élémentaires & Vulnérabilité (Axe 1 - Précédent)** :
   - **Brûlure (`burn`)** : Dégâts de feu infligés au début du tour de la cible. Le tick applique des dégâts égaux à la valeur accumulée puis décrémente la valeur et la durée de 1.
   - **Gel (`freeze`)** : Divise par deux (arrondi) les dégâts de la prochaine attaque ennemie et décrémente immédiatement la durée du gel de 1.
   - **Électrocution (`shock`)** : Ajoute la valeur cumulée du statut à chaque dégât d'attaque direct subi par la cible.
   - **Vulnérabilité (`vulnerable`)** : Amplifie de 50% tous les dégâts reçus de manière universelle (s'applique aussi bien au Héros qu'aux Ennemis).
   - Résolutions métier câblées proprement dans `CombatController` et `EffectResolver` sans couplage Flame.

7. **Rareté Dynamique & Fusion Interactive (Axe 2 & 4 - Précédent)** :
   - Remplacement des niveaux numériques de cartes par une progression de rareté dynamique (`common` → `uncommon` → `rare` → `epic` → `legendary`). Les multiplicateurs de rareté adaptent les statistiques de base de la carte.
   - **Fusion interactive (3→1)** : Le joueur sélectionne exactement 3 exemplaires identiques. Le système fusionne automatiquement les upgrades de même ID en additionnant leurs Tiers, tout en limitant la quantité finale selon la capacité de la rareté supérieure. Un choix d'héritage d'améliorations est proposé de manière interactive.

8. **Système de Forge Découplé (Axe 3 - Précédent)** :
   - **Capacité de Forge** : Limite d'améliorations fixée à `baseMaxForgeUpgrades + rarityIndex`.
   - **Slots Probabilistes** : De 1 à 5 slots générés indépendamment avec des probabilités de `100%`, `50%`, `25%`, `10%`, et `2%`.
   - **Pools d'Améliorations** : Tirages clamps par rareté (Common: stats/debuffs; Uncommon: pioche/mana; Rare: enduring).
   - **Relance individuelle (Reroll)** : Coût par slot indexé sur $20 \times 1.25^n$ (arrondi), consommant l'or de l'inventaire.
   - **Intégration premium** : Nouveau widget `ForgeUpgradeDialog` accessible depuis l'option Forge de l'écran `RestScreen` (anciennement Campfire).

9. **Système de Tutoriel Autonome & Refactoring Responsive (Ancien)** :
   - Module isolé sous `lib/tutorial/` avec son propre `TutorialEngine` et un état simulé `TutorialMockState`.
   - 13 étapes interactives adaptées aux smartphones portrait/paysage, web, et desktop via des structures responsives unifiées (`LayoutBuilder`, `FittedBox`, `SingleChildScrollView`, `Wrap`).
   - Ciblage double phase interactif et infobulles explicatives localisées.

10. **Équilibrage de la Courbe de Difficulté et Vagues de Combat** :
    - Mise en œuvre d'un algorithme d'équilibrage hybride (DDA amorti à 0.5) comparant `PlayerPower` et `ExpectedPower` pour ajuster le `FinalBudget` de menace.
    - Intégration du système de `CombatRating` dynamique des ennemis (prenant en compte le scaling HP, dégâts, tier et chance critique).
    - Développement du système de réserve `pendingEnemies` (limité à 5 slots actifs) avec réapprovisionnement automatique lors des éliminations et condition de victoire étendue.
    - Correction de la logique de détermination de Boss (`isBoss`) : Restriction de la vérification par floor (divisible par 10) aux cas où le type de nœud n'est pas spécifié, évitant ainsi le scaling erroné de boss lors des combats classiques du floor 10.
    - Validation complète du comportement des vagues et de la répartition budgétaire via des tests unitaires automatisés.

11. **Assurance Qualité et Robustesse** :
    - **Tests automatisés** unitaires et d'intégration validés avec succès (dont tests du générateur, du système de vagues, de la correction `isBoss` et du nouveau logger), portant le total à **100 tests** (100% verts).
    - Analyse de code statique : **0 erreur** sous `flutter analyze`.

12. **Isolation de la Journalisation du Combat (`CombatDebugLogger`)** :
    - Découplage complet de la journalisation mathématique d'initialisation de combat en extrayant ces fonctions de `CombatController` vers `CombatDebugLogger`.
    - Stylisation de la console de débogage à l'aide de bordures en boîte ANSI et de codes de couleurs ANSI pour mettre en valeur les statistiques du joueur, les formules calculées de la DDA, les détails du scaling et les attributs finaux des ennemis.
    - Encapsulation des instructions de log dans des vérifications de mode débogage (`kDebugMode`) pour éviter toute surcharge d'allocation de mémoire en production.

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
