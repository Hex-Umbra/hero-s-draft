# Rapport d'Analyse de la Dette Technique (Volume 4) — Hero's Draft

Ce rapport présente une analyse exhaustive et rigoureuse du projet **Hero's Draft** après l'accomplissement complet et réussi de **l'Étape 1 (Rénovation de la Localisation - i18n Absolue)**. Ce chantier d'envergure a permis d'éradiquer la totalité des chaînes en dur, des variables locales `isFr`, et des conditions de traduction manuelles au sein de la couche UI Flutter, élevant ainsi le jeu à un standard d'internationalisation de niveau professionnel.

Ce volume 4 dresse le bilan clinique des récents succès de refactoring, identifie la dette technique résiduelle et propose une nouvelle feuille de route pour finaliser les fondations techniques du jeu.

---

## 1. Tableau de Bord de l'Architecture Actuelle

Grâce à la rénovation complète de la localisation et au nettoyage des écrans, la base de code a atteint un niveau de propreté et de découplage impressionnant.

### Métriques Cliniques du Projet
* **Moteur Flutter & Internationalisation (i18n)** : **100% de conformité**. Plus aucune chaîne brute en français, plus de flag `isFr` local dans les widgets. Tout transite par `AppLocalizations` fortement typé avec compilation automatisée des fichiers ARB.
* **Découplage UI / Gameplay** : Tous les écrans (`RestScreen`, `StarterDeckDraftScreen`, `CardDictionaryScreen`, `ClassSelectionScreen`, `DeckScreen`, `DraftScreen`, `EventScreen`, `ShopScreen`) délèguent entièrement leur logique aux contrôleurs purs de Riverpod.
* **Fiabilité et Assurance Qualité** : 
  * **58 tests automatisés (100% au statut VERT / Réussite totale)**.
  * **0 avertissement ni erreur** retourné par le compilateur statique `flutter analyze`.

---

## 2. Bilan du Refactoring : Ce qui a été résolu

La dette majeure d'internationalisation du Volume 3 a été entièrement résorbée :

1. **Substitution intégrale de `isFr` par `AppLocalizations`** :
   * **RestScreen (`rest_screen.dart`)** : Options de feu de camp, titres et SnackBars localisés.
   * **StarterDeckDraftScreen (`starter_deck_draft_screen.dart`)** : Constitution du deck, vérification du nombre de cartes sélectionnées et messages d'alerte entièrement déportés dans les fichiers ARB.
   * **CardDictionaryScreen (`card_dictionary_screen.dart`)** : Rares labels de types, de cibles et titres passés sous `AppLocalizations`.
   * **ClassSelectionScreen (`class_selection_screen.dart`)** : Infobulles et boutons d'action de sélection épurés.
   * **DeckScreen (`deck_screen.dart`)** & **DraftScreen (`draft_screen.dart`)** : Fusion de cartes, boosts de statistiques, options de clonage et raretés intégralement internationalisés.
   * **EventScreen (`event_screen.dart`)** : Remplacement des badges de gains en dur par des traducteurs dynamiques dotés de placeholders (PV, PV Max, Or, Attaque, Relique).

2. **Découplage de la Localisation des Statuts** :
   * Le widget réactif **StatusEffectsPanel** traduit désormais à la volée les statuts de combat (Poison, Force, Faiblesse, Vulnérable, Régénération d'Armure, Éveil d'Attaque, Vol de vie) à partir de leur identifiant technique (`status.id`) en utilisant des expressions `AppLocalizations` dédiées. Le moteur Flame et les classes logiques ne manipulent plus que des identifiants techniques neutres.

3. **Ajustement de la Suite de Tests** :
   * Configuration de la locale de test (`Locale('fr', '')`) dans `starter_deck_draft_screen_test.dart` pour s'assurer de la parfaite cohésion avec les assertions de test originelles, rétablissant le statut 100% vert de la suite de tests.

---

## 3. Cartographie de la Dette Technique Résiduelle (Volume 4)

Bien que le projet soit dans un état extrêmement robuste, une nouvelle exploration approfondie de la base de code a mis en évidence des axes d'amélioration critiques pour assurer la stabilité à long terme et la commercialisation future du jeu.

```mermaid
graph TD
    subgraph Dette Résiduelle Actuelle (Volume 4)
        A[GameDataService] -->|Cold Start I/O| SequentialReads["7 requêtes asynchrones en série (await)"]
        B[Moteur Audio] -->|Absence de SFX/BGM| AudioUnimplemented["TODO Audio non branchés (Pas de dépendance)"]
        C[Persistance et Sauvegardes] -->|Absence d'Autosave| StateLost["Perte complète de progression si l'application est fermée"]
        D[Router et États transitoires] -->|Navigation Couplée| HardcodedNavigator["Couplage fort de l'UI avec Navigator.push/pop"]
    end
```

### A. Dette de Performance : Chargement Séquentiel des Fichiers de Données
* **Fichier** : [game_data_service.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/services/game_data_service.dart#L14)
* **Problème** : La méthode d'initialisation du provider `gameDataLoaderProvider` charge les 7 bases de données JSON (enemies, heroes, skills, cards, events, passives, relics) de façon séquentielle à l'aide de 7 expressions `await` distinctes :
  ```dart
  final enemiesJson = await rootBundle.loadString('assets/data/enemies.json');
  final heroesJson = await rootBundle.loadString('assets/data/heroes.json');
  // ...
  ```
* **Risque** : Sur les appareils mobiles bas de gamme ou lors d'un chargement en conditions réseau instables sur le Web, cette lecture en série bloque le fil principal d'exécution et augmente artificiellement le temps de démarrage initial (Cold Start) de l'application.
* **Solution** : Paralléliser les lectures à l'aide de `Future.wait([ ... ])`, puis décoder et mapper les données de façon asynchrone et groupée.

### B. Dette Sensorielle : Moteur Audio Non Implémenté
* **Problème** : De nombreux commentaires `// TODO: Audio Hook` subsistent dans les fichiers du jeu (par exemple dans le rendu visuel et les interactions de cartes). Le fichier `pubspec.yaml` ne comprend aucune dépendance pour la lecture audio (`flame_audio` ou `audioplayers`), et il n'existe pas de service central de contrôle audio (`AudioService`) pour piloter les musiques de fond (BGM) ou les effets sonores (SFX).
* **Risque** : Une expérience de jeu aride et un manque de rétroaction sensorielle, ce qui nuit à l'immersion nécessaire pour un roguelike de cartes premium.

### C. Dette de Robustesse : Absence de Système de Sauvegarde (Autosave & Persistance)
* **Problème** : Le combat (`CombatState`), l'inventaire (`InventoryState`), et la progression générale de la run (`RunState`) sont conservés uniquement dans la mémoire vive de l'application (providers d'état Riverpod). Si l'application subit un crash, si l'appareil manque de mémoire ou si le joueur ferme simplement la fenêtre de jeu, la progression de sa partie en cours est définitivement perdue.
* **Risque** : Frustration majeure pour les joueurs lors de parties prolongées, et impossibilité de suspendre puis de reprendre une partie à mi-chemin.
* **Solution** : Implémenter un service de sauvegarde locale (`SaveService` s'appuyant sur `shared_preferences` ou `sqlite`) qui sérialise automatiquement l'état logique de la partie (combat, deck, or, reliques, et carte) à chaque changement d'état ou à la fin de chaque tour, et permet sa restauration fluide au démarrage du jeu.

### D. Dette d'Architecture : Système de Navigation et Transitions Couplés
* **Problème** : Les transitions d'un écran à un autre (e.g. MapScreen -> ShopScreen -> GameScreen) sont codées en dur dans les callbacks de l'UI à l'aide de `Navigator.of(context).push(...)` ou `Navigator.of(context).pop()`.
* **Risque** : Ce couplage fort rend le flux de navigation dépendant de l'état graphique des widgets. Il est extrêmement difficile d'implémenter un écran de chargement de transition fluide, de contrôler les droits de navigation (ex: empêcher de quitter un combat en cours via un pop accidentel), ou de restaurer l'état de l'écran après un rechargement d'autosave.
* **Solution** : Découpler la navigation en créant un contrôleur de route logique (`NavigationController` ou `RunRouterProvider`) qui observe le type de nœud actif ou l'état de la run et pilote réactivement l'écran à afficher.

---

## 4. Feuille de Route de Refactoring Proposée (Phase 7)

Pour parfaire la base technique de **Hero's Draft** et en faire un projet irréprochable prêt pour la production, nous recommandons le plan d'actions suivant :

### Étape 1 : Optimisation des I/O de Démarrage (Cold Start)
1. **Parallélisation dans `GameDataService`** : Remplacer les 7 appels `await rootBundle.loadString(...)` successifs par un unique appel groupé `Future.wait`.
2. **Mesure de performance** : Assurer que le temps de décodage et d'instanciation reste sous la barre fatidique des 16ms pour éviter tout gel d'écran (jank) lors de l'affichage du splash screen.

### Étape 2 : Implémentation du Moteur de Sauvegarde et Persistance
1. **Service de Sauvegarde local (`SaveService`)** : Création d'une classe d'accès aux fichiers ou de stockage persistant local (`shared_preferences`).
2. **Intégration d'Autosave** : Brancher des écouteurs sur nos providers d'état Riverpod (`RunController`, `DeckController`, `InventoryController`, `CombatController`) pour persister les états au format JSON après chaque modification majeure (obtention de carte, perte de points de vie, fin de tour de combat).
3. **Bouton de Reprise de Partie** : Ajouter une option "REPRENDRE LA PARTIE" sur l'écran d'accueil (`HomeScreen`) si un fichier de sauvegarde valide est détecté sur l'appareil.

### Étape 3 : Intégration de l'Infrastructure Audio
1. **Ajout de dépendance** : Ajouter `flame_audio` ou une passerelle audio légère dans `pubspec.yaml`.
2. **AudioService** : Concevoir un contrôleur centralisé gérant les pistes musicales en boucle (BGM pour l'accueil, la carte, le combat, la boutique, et le repos) et les SFX (slash d'attaque, blocage de bouclier, pop de texte flottant).
3. **Raccordement des Hooks** : Résoudre l'ensemble des TODOs audio en branchant les effets sonores aux endroits stratégiques dans `CardAnimator` et `FloatingText`.

---

## 5. Conclusion

Le projet **Hero's Draft** se dresse aujourd'hui sur des fondations d'une propreté exceptionnelle. La résorption absolue de la dette d'internationalisation de l'UI a permis de nettoyer l'arborescence et d'assurer une évolutivité totale pour le multi-langue global. 

En s'attaquant à la dette de performance I/O et en instaurant un solide système de persistance (Autosave) et d'audio dans cette Phase 7, le jeu franchira le cap final le séparant d'un produit commercialisable d'excellence.
