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
   - **Carrousel de Récompense de Reliques Premium** : Remplacement de l'attribution instantanée brute des reliques de boss/élites par un système interactif de carrousel de type machine à sous en plein écran. Présentation de 3 reliques simultanément dans un `PageView` à fraction de viewport (la carte centrale focalisée à échelle `1.0x` et opaque, les latérales rétrécies à `0.85x` et floutées/translucides à `0.4` d'opacité). Une phase de spin à haute vitesse décélère dynamiquement selon une courbe cubique d'ease-out (`Curves.easeOutCubic`) sur 4,0 secondes pour s'arrêter précisément sur la relique gagnée pré-sélectionnée logiquement, déclenchant des particules de célébration dessinées sur Canvas et des callbacks audio (`onTick`, `onLand`) pour les sons de défilement et d'atterrissage. Un bouton « Récupérer » sécurisé n'autorise la collecte dans l'inventaire et la transition d'écran que lorsque le carrousel s'est parfaitement verrouillé sur sa cible.

2. **Système de Mort et de Stats Synchronisé Z-Sync (Z-Sync Death & Stats System)** :
   - **Résolution des Concurrences Visuelles** : Résout la condition de concurrence (race condition) visuelle où un ennemi mourrait ou voyait sa barre de vie se vider instantanément via `_applyCombatState` alors que la carte jouée était encore en train de voyager (animation de mêlée ou projectile), faisant frapper la carte dans le vide ou drainer la vie avant l'impact physique.
   - **Introduction des Flags d'État** : Utilise `isCardAnimating` dans `HerosDraftGame`, `isPendingDeath` et `_pendingVisualInstance` dans `EnemyCard`.
   - **Diffèrement de la Mort et des Stats** : Si l'ennemi subit des dégâts ou meurt durant l'animation d'une carte :
     - Les feedbacks visuels d'impact immédiats (secousses, flashes de couleur, nombres flottants, éclatement de particules physiques) sont déclenchés instantanément pour un ressenti ultra-satisfaisant ("snappiness").
     - Mais la diminution réelle de la barre de vie (`HealthBar`), du bouclier (`StatBadge` d'armure) et des indicateurs de buff/debuff est temporisée. L'instance mise à jour est stockée dans `_pendingVisualInstance` dans `EnemyCard`.
     - Si l'ennemi meurt, il est marqué `isPendingDeath = true` et reste pleinement visible.
   - **Résolution Synchrone à l'Impact** : Dès que l'animation de la carte touche sa cible à 100% de son trajet, son callback `onComplete` appelle `game.resolvePendingDeaths()`. Cette méthode parcourt toutes les `EnemyCard` actives pour appeler `card.resolvePendingVisualStats()` (qui applique l'instance différée, rafraîchit la barre de HP et les badges d'armure) puis déclenche les animations de rétrécissement (shrink) et fondu (fade-out) des ennemis morts.
   - **Bypass Hors-Combat** : Les modifications de stats hors combat (ex: ticks de poison ou de brûlure au début de tour) contournent ce délai pour s'appliquer instantanément.

3. **Intégration des Statuts Élémentaires (Burn, Freeze, Shock)** :
   - **Brûlure (Burn)** : Résolution au début du tour ennemi via `startEnemyTurn()`, infligeant des dégâts directs à hauteur de la valeur cumulée du statut, similaire au poison.
   - **Gel (Freeze)** : Division par deux des dégâts d'attaque prévus dans l'intention de l'ennemi lors de `resolveEnemyIntent()` : `(intent.value * 0.5).round()`.
   - **Électrocution (Shock)** : Amplification directe des dégâts reçus par l'ennemi lors de la résolution des cartes d'attaque dans `EffectResolver.resolveCard()` : `dmg += shockStatus.value`.
   - **Support Technique Complet** : Création centralisée dans `EffectResolver._createStatus()`, prise en charge bilingue intégrale et intégration robuste dans le moteur de résolution.

4. **Consistance Visuelle des Statuts et Transparence des Infobulles (Tooltip Clarity & Mapping)** :
   - **Tracés Vectoriels Haute Fidélité** : Implémentation dans `effect_icon.dart` de tracés de canvas vectoriels complexes pour `burn` (flamme rouge/orange avec masque de lueur), `freeze` (flocon de neige bleu symétrique à 6 branches avec lueurs cyan) et `shock` (éclair jaune électrique).
   - **Mappage de Statuts Emojis et HUD** : Correction du bug d'affichage générique de `burn` en le mappant sur 🔥 dans `status_indicator.dart`, `freeze` sur ❄️, `shock` sur ⚡, et ré-attribution de `strength_regen` vers ✊ (poing) pour lever toute collision visuelle. Câblage dynamique des labels linguistiques à la volée dans `status_effects_panel.dart`.
   - **Infobulles Explicatives Parentthésées** : Ajout d'explications mécaniques explicites, condensées et localisées dans `_buildDetailedDescription()` (pour `UiCard` et `CardComponent`) détaillant précisément l'impact de chaque statut (poison, burn, freeze, shock, weakness, vulnerable) pour éliminer toute confusion de gameplay.

5. **Restructuration Globale de la Localisation** :
   - Migration absolue vers `AppLocalizations` fortement typé pour l'interface UI Flutter.
   - Élimination intégrale des variables `isFr` locales et des chaînes de caractères codées en dur.
   - Intégration du support multilingue double-champs dans les bases de données JSON (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`).
   - Traduction dynamique en temps réel des statuts de combat dans `StatusEffectsPanel`.

6. **Système de Progression XP & Niveaux (XP & Levels Progression System)** :
   - **Formule de Seuils Exponentiels** : Implémentation de la courbe `100 * 1.5^(level - 1)` dans le `RunController`.
   - **Gains de Niveaux Multiples & Carry-Over** : La méthode `gainXp` gère le passage fluide de plusieurs niveaux en cascade en conservant parfaitement le reste d'expérience.
   - **Interface HUD de Progression** : Affichage d'une barre de progression XP dorée et de badges de niveau sous le panel des mini-stats de la carte du monde (`MapScreen`).

7. **Échelonnement Dynamique des Ennemis (Enemy Scaling)** :
   - **Calcul de Niveau de Combat** : Niveau d'ennemi déterminé par `playerLevel + (act - 1) * 2 + nodeModifier` (Elite : `+1`, Boss : `+2`).
   - **Scaling Mathématique des Stats** : Multiplicateurs d'HP (`+12% par niveau`) et de dégâts (`+8% par niveau`) appliqués dynamiquement dans `CombatController`.
   - **Consistance Visuelle** : Intégration du niveau des monstres à côté de leurs noms dans le panel d'intentions Flame (ex : « Slime (Niv. 3) »).

8. **Flux de Victoire & Révélation de Cartes Interactive (Draft Card Reel)** :
   - **Pattern DraftCardReel Séquentiel** : Remplacement de l'apparition statique du Draft post-combat par un spinner vertical de type machine à sous.
   - **Révélation Séquentielle 3D** : Révélation des 3 cartes par rotation 3D sur l'axe X avec des retards de stabilisation asynchrones échelonnés (0.8s, 1.4s, 2.0s).
   - **Célébration Légendaire Épique** : Pour les récompenses légendaires, rallongement du spin, secousses d'écran (screen-shake), auréole dorée de feu de particules et flashes d'impact.
   - **Pipeline de Transition & Level Up** : À la victoire, cumul de l'XP de tous les ennemis (+10% par niveau de monstre). En cas de montée de niveau, lecture de la bannière festive « LEVEL UP ! » et redirection vers l'écran de draft amélioré, sinon attribution de l'or et progression sur la carte. Câblage de sound hooks (`onTick` / `onLand`).

9. **Intégration de la Rareté Mythique & Transition d'Alerte Séquentielle (Draft)** :
   - **Rareté Mythique (Mythic)** : Création d'une rareté ultime de couleur rouge sang (`0xFFE53E3E`) avec une bordure de carte de `4.0` (comparée à `3.0` pour la Légendaire) et des effets d'ombre avec halo rouge vif. Les rouleaux Mythiques en cours de rotation ont des délais asynchrones prolongés (`+800ms`), une amplitude de secousse doublée (`12.0` vs `6.0` pixels), et des contours d'étincelles rouge-néon via un `_SparkPainter` adapté.
   - **Transition d'Alerte Horizontale (Warning Alert)** : Lors du tirage du Draft, si des cartes Mythiques sont obtenues (Trèfle à quatre feuilles ou Miroir), une transition d'alerte spectaculaire de 1400ms se déclenche après l'arrêt des rouleaux standard : une ligne laser écarlate balaye horizontalement l'écran de gauche à droite en coupant les cartes, tandis que trois points d'exclamation géants `!!!` surgissent au centre en animation élastique avec des ombres doubles (rouge et blanc) et flashent deux fois.
   - **Floutage d'Arrière-Plan & Révélation (Foreground Overlay)** : Un `BackdropFilter` applique un flou gaussien de `8.0px` sur l'arrière-plan, tandis qu'une bannière rouge clignotante annonce l'apparition Mythique en premier plan. Après stabilisation et révélation des cartes Mythiques, l'overlay s'estompe en fondu (fade-out) après 1.5s pour réintégrer les cartes au Draft standard prêtes pour sélection.
   - **Rééquilibrage des Probabilités de Draft** :
     - Tirages standards : Légendaire `2%`, Épique `6%`, Rare `16%`, Atypique `24%`, Commune `52%` (100% exact).
     - Tirages améliorés / Level Up : Mythique `0.5%`, Légendaire `2.0%`, Épique `6%`, Rare `16%`, Atypique `24%`, Commune `51.5%` (100% exact).

10. **Validation, Assurance Qualité et Robustesse** :
    - Suite de tests unitaires et widgets validée : **66 tests unitaires et widget-tests 100% VERT (66 passés avec succès)**.
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
