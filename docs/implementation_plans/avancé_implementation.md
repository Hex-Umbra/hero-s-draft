## Phase 1 - Implémentation du système de données

- feat: implémentation Phase 1 
    - configuration des assets json et création des modèles de données (EnemyData, HeroData, SkillData)
        - J'ai terminé la Phase 1. Les fichiers JSON ont été créés, le pubspec.yaml a été mis à jour et les classes Dart (DTOs) ont été implémentées.
- feat: implémentation Phase 2 
    - création du service de chargement Riverpod (gameDataLoaderProvider) et synchronisation au démarrage via un SplashScreen
        - J'ai terminé la Phase 2. Le système de chargement via Riverpod est en place et attend que les fichiers JSON soient chargés avant d'afficher le menu principal.
- feat: implémentation Phase 3 
    - refactoring des ennemis pour utiliser EnemyData depuis le JSON
        - J'ai terminé la Phase 3. Les ennemis générés lors des combats utilisent maintenant strictement les données issues de enemies.json via le GameDataRegistry ! Le EncounterSystem et le EnemyCard ont été mis à jour en conséquence, et j'ai ajouté quelques ennemis d'exemple dans le JSON pour que ça fonctionne directement.
- feat: implémentation Phase 4 
    - refactoring des classes de Héros (utilisation de HeroData et du JSON)
        - J'ai terminé la Phase 4. Les classes jouables (Paladin, Berserker, Mage) sont désormais chargées directement depuis le fichier heroes.json. Le ClassSelectionScreen lit dynamiquement ces données pour créer les boutons, et le RunState initialise les statistiques du joueur en fonction de la classe choisie.
- feat: implémentation Phase 5 
    - refactoring des compétences vers le JSON (Préparation au deckbuilding)
        - J'ai terminé la Phase 5. Les compétences ont été extraites dans le fichier skills.json et toutes les fonctions spécifiques (executeMageAoe, executeBerserkerTargeted, etc.) ont été remplacées par un seul moteur générique executeSkill() dans le jeu. L'interface (GameScreen) génère maintenant ses boutons dynamiquement depuis ces données JSON !
    
## Phase 2 - Implémentation du système de Deckbuilding

- feat: implémentation Phase 1 
    - modèles et architecture des cartes (Data)
        - J'ai terminé la Phase 1. J'ai créé le fichier `card_data.dart` contenant toutes les énumérations (`CardType`, `CardRarity`, etc.) ainsi que le modèle JSON. J'ai également créé `card_instance.dart` pour représenter les cartes en jeu avec un UUID, un niveau et la gestion des coûts temporaires.

- feat: implémentation Phase 2 
    - gestionnaire d'état du deck (Riverpod)
        - J'ai terminé la Phase 2. J'ai créé le `deck_controller.dart` qui contient le `DeckState` (pour gérer les différentes piles de cartes : masterDeck, drawPile, hand, discardPile, exhaustPile) et le `DeckNotifier`. Toutes les fonctions de gestion du deck (`initializeCombat`, `drawCards` avec remélange automatique, `discardHand` et `playCard` avec gestion de l'épuisement des pouvoirs) ont été implémentées.

- feat: implémentation Phase 3 
    - moteur d'exécution et vérifications
        - J'ai terminé la Phase 3. J'ai créé le service `effect_resolver.dart` qui s'occupe de vérifier la jouabilité d'une carte (coût en mana, présence d'une cible valide). J'ai également implémenté la résolution des effets (`damage`, `heal`, `armor`) avec déduction du mana via le `RunController` et application des dégâts sur les `EnemyCard`.

- feat: implémentation Phase 4 
    - interface utilisateur en combat (Flame)
        - J'ai terminé la Phase 4. J'ai créé le `card_component.dart` (visuel Flame) qui gère l'affichage des cartes et les interactions tactiles (`DragCallbacks`). Le composant gère le ciblage d'un ennemi pendant le "drag", se replace automatiquement dans la main en cas d'annulation (`MoveEffect`, `RotateEffect`), et transmet la carte à jouer au moteur principal.

- feat: implémentation Phase 5 
    - intégration à la game loop (Tour par tour)
        - J'ai terminé la Phase 5. J'ai connecté le `DeckNotifier` aux événements de la boucle de jeu dans `GameScreen`. Le mana est maintenant réinitialisé au début du tour du joueur et 5 cartes sont piochées automatiquement. Lorsqu'on clique sur "Fin de Tour", la main est correctement défaussée avant de passer à la phase de riposte des ennemis.

- feat: implémentation Phase 6 
    - système de draft (Loot) et amélioration (Fusion)
        - J'ai terminé la Phase 6. J'ai ajouté la fonction `addCardToMasterDeck` dans le `DeckNotifier` qui gère l'ajout d'une carte post-combat et inclut l'algorithme d'Auto-Merge récursif. Dès que 3 cartes identiques au même niveau sont détectées, elles sont retirées et remplacées par une seule carte de niveau supérieur. L'écran de Draft est maintenant prêt à utiliser des cartes en récompense !

## Phase 3 - Implémentation des Feedbacks, UI & UX

- feat: implémentation Étape 1.1
    - barres de vie dynamiques (HealthBarComponent)
        - J'ai terminé l'Étape 1.1. J'ai créé le `HealthBarComponent` et je l'ai intégré dans `HeroCard` (vert, en bas) et `EnemyCard` (rouge, en haut), remplaçant les badges HP circulaires pour une meilleure lisibilité des points de vie.
- feat: implémentation Étape 1.2
    - système d'intentions ennemies (Telegraphing)
        - J'ai terminé l'Étape 1.2. J'ai implémenté le système d'intentions (`EnemyIntent`) qui permet de prédire l'action de l'ennemi (Attaque, Défense, Buff). Les intentions sont affichées via un `IntentionIndicator` au-dessus de chaque ennemi et sont synchronisées avec la phase de riposte.
- feat: implémentation Étape 2.1
    - Screen Shake (Tremblement de caméra)
        - J'ai terminé l'Étape 2.1. J'ai ajouté une méthode `shake()` dans `HerosDraftGame` utilisant les `MoveEffect` de Flame sur le viewfinder de la caméra. L'effet est déclenché avec une intensité variable : légère lors des attaques réussies du joueur et forte lors des dégâts subis par le héros.
- feat: implémentation Étape 2.2
    - Animations de "Dash" directionnelles
        - J'ai terminé l'Étape 2.2. J'ai refactorisé `bumpAnimation()` dans `HeroCard` et `EnemyCard` pour utiliser des `SequenceEffect`. Désormais, les entités effectuent un "Dash" vers leur cible (vers le haut pour le héros, vers le bas pour les ennemis) avec des courbes d'animation `easeOut` et `bounceOut` pour un rendu plus dynamique.
