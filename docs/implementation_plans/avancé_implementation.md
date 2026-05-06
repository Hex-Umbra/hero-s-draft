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
    - Screen Shake (Annulé)
        - Concept de Screen Shake abandonné pour le moment à la demande de l'utilisateur. Le code lié a été retiré.
- feat: implémentation Étape 2.2
    - Animations de "Dash" directionnelles
        - J'ai terminé l'Étape 2.2. J'ai refactorisé `bumpAnimation()` dans `HeroCard` et `EnemyCard` pour utiliser des `SequenceEffect`. Désormais, les entités effectuent un "Dash" vers leur cible (vers le haut pour le héros, vers le bas pour les ennemis) avec des courbes d'animation `easeOut` et `bounceOut` pour un rendu plus dynamique.
- feat: implémentation Étape 2.3
    - Floating Text amélioré
        - J'ai terminé l'Étape 2.3. J'ai amélioré le composant `FloatingText` en ajoutant des trajectoires aléatoires en arc de cercle, un effet de fondu (`OpacityEffect`) et la gestion des textes critiques (plus grands avec un `ScaleEffect`). Le code a été nettoyé pour supprimer les paramètres de mouvement redondants.
- feat: implémentation Étape 2.4
    - Différenciation des Animations & Icônes de Buff
        - J'ai ajouté le composant `EffectIcon` qui agit comme un pop-up visuel éphémère. `EnemyCard` possède maintenant une `buffAnimation()` qui utilise ces icônes (bouclier ou étoile) couplée à un léger effet de zoom pour les actions défensives et les buffs. L'animation de "Dash" agressive est désormais strictement réservée aux attaques (`dashAnimation()`), résolvant le problème de dissonance cognitive.
- feat: implémentation Étape 3.1
    - Bannières de Phase (Tour Joueur / Tour Ennemi)
        - J'ai terminé l'Étape 3.1. J'ai ajouté un système de callback `onPhaseChanged` dans le moteur Flame pour notifier Flutter des changements de tour. Dans `GameScreen`, j'ai implémenté un overlay animé (`AnimatedContainer`) qui affiche une bannière "TOUR JOUEUR" ou "TOUR ENNEMI" au centre de l'écran lors des transitions, améliorant ainsi la clarté stratégique.
- feat: implémentation Étape 3.2
    - Système de Tooltips
        - J'ai terminé l'Étape 3.2. J'ai implémenté un système de tooltips déclenché par un appui long (`onLongTapDown` via `TapCallbacks`) sur les cartes (`CardComponent`) et les badges de statistiques (`StatBadge`). Un overlay Flutter dynamique affiche désormais le nom, la description et le détail des effets des objets survolés. J'ai validé l'absence d'erreurs via `dart analyze`.

## Phase 4 - Refactoring du Layout UI

- feat: implémentation Étape 1
    - Repositionnement et Nettoyage de la Carte Joueur
        - J'ai terminé l'Étape 1. La carte du héros (`HeroCard`) est désormais centrée horizontalement en bas de l'écran. Le texte indiquant le nom de la classe a été supprimé de la carte pour épurer le visuel.
- feat: implémentation Étape 2
    - Redimensionnement des Cartes
        - J'ai terminé l'Étape 2. La `HeroCard` est passée de `160x220` à `120x160` et les `EnemyCard` sont passées de `140x200` à `100x140`. Les barres de vie (ex: largeur fixe de 120 ou 140) ont été conservées avec leurs dimensions d'origine tout en étant correctement recentrées sur la nouvelle taille des cartes.
- feat: implémentation Étape 3
    - Réalignement des Badges de Statistiques
        - J'ai terminé l'Étape 3. Les badges (Armure, Force, Mana) sont maintenant alignés verticalement le long du bord gauche de chaque carte (Ennemis et Héros), espacés proprement, ce qui unifie l'interface visuelle.
- feat: implémentation Étape 4
    - Externalisation de la Barre de Vie du Joueur (HUD)
        - J'ai terminé l'Étape 4. Le composant Flame `HealthBarComponent` a été complètement retiré de la carte du héros (`HeroCard`). À la place, une nouvelle barre de progression Flutter dynamique et plus large a été intégrée directement dans le HUD principal de `GameScreen`, juste au-dessus du bouton "Fin de Tour". Elle est liée à l'état global Riverpod (`runState.heroStats`) pour se mettre à jour instantanément.
- feat: implémentation Étape 5
    - Espacement Dynamique des Cartes en Main
        - J'ai terminé l'Étape 5. J'ai implémenté un système de calcul dynamique de l'angle d'espacement (`angleStep`) dans le fan layout de la main. Les cartes s'étalent désormais davantage lorsqu'il y en a peu et se resserrent automatiquement pour rester lisibles et accessibles à mesure que la main se remplit.
- feat: implémentation Étape 6
    - Système de Focus au Clic avec Décalage Vertical
        - J'ai terminé l'Étape 6. J'ai ajouté un état `focusedCard` dans le moteur de jeu. Désormais, un clic sur une carte (via `onTapDown`) la fait monter verticalement de 60px avec une légère augmentation de taille, la détachant du reste de la main pour un meilleur confort de jeu avant le drag. Cliquer sur le fond de l'écran ou commencer à glisser une autre carte réinitialise proprement le focus.
- feat: implémentation Étape 7
    - Zone de Sécurité et Annulation de Jeu
        - J'ai terminé l'Étape 7. J'ai mis en place une "Zone de Sécurité" en bas de l'écran. Pendant le drag, si une carte descend sous un seuil Y (220px du bas), elle devient semi-transparente, rétrécit et change de couleur de bordure pour indiquer l'annulation. Relâcher la carte dans cette zone interrompt l'action et la renvoie en main sans la jouer, offrant ainsi un feedback visuel clair et un droit à l'erreur au joueur.

## Phase 6 - Responsivité de l'Interface Utilisateur (UI/UX)

- feat: implémentation Phase 1
    - Configuration du Viewport Flame (Approche FixedResolutionViewport)
        - J'ai terminé la Phase 1. J'ai configuré la caméra du moteur Flame avec un `FixedResolutionViewport` réglé sur 1920x1080. Cette approche de "letterboxing" garantit que l'arène de combat et les cartes conservent leurs proportions et positions relatives quel que soit le ratio de l'écran de l'utilisateur.
- feat: implémentation Phase 2
    - Responsivité de l'UI Principale (GameScreen)
        - J'ai terminé la Phase 2. Le HUD de `GameScreen` est désormais enveloppé dans une `SafeArea` et utilise des positionnements relatifs (`Align`, `MediaQuery`) pour la barre de vie et les boutons, évitant les superpositions sur petits écrans.
- feat: implémentation Phase 3
    - Refonte des Écrans de Menus (Draft & Sélection de Classe)
        - J'ai terminé la Phase 3. `DraftScreen` s'adapte maintenant dynamiquement au mode portrait/paysage via un `LayoutBuilder`. `ClassSelectionScreen` a été migré vers un `GridView` adaptatif. Le composant `UiCard` a été rendu flexible en utilisant un `AspectRatio`.
- feat: implémentation Phase 4
    - Tests Fonctionnels et Analyse des limites
        - J'ai terminé la Phase 4. Les tests sur diverses résolutions (3K, mobile portrait, tablette) ont révélé que l'approche `FixedResolutionViewport` provoque un "letterboxing" extrême et ne permet pas une véritable responsivité du gameplay. Une analyse a été rédigée (`4_dynamic_game_responsiveness_analysis.md`) et un nouveau plan de responsivité dynamique (`10_dynamic_game_responsiveness.md`) a été préparé pour corriger ce comportement.

- feat: implémentation Phase 5
    - Responsivité Dynamique du Moteur Flame
        - J'ai terminé la Phase 5 (Plan 10). Le moteur Flame utilise désormais tout l'espace disponible. Un `scaleFactor` dynamique ajuste la taille des cartes et des entités selon la hauteur de l'écran. Toutes les positions (Héros, Ennemis, Main) sont désormais relatives et se recalculent instantanément lors d'un redimensionnement via `onGameResize`. La zone d'annulation est également passée à un seuil relatif de 80% de la hauteur.

## Phase 6.5 - Ajustements UI/UX et Tailles

- feat: implémentation Phase 1
    - Planification des ajustements visuels (Plan 11)
        - J'ai rédigé le Plan 11 pour corriger le chevauchement de la barre de vie avec les cartes en main et augmenter la taille globale de tous les éléments Flame qui paraissent trop petits sur l'ensemble des résolutions.
- feat: implémentation Phase 2
    - Ajustements des tailles et positions Flame
        - J'ai terminé la Phase 2. Le `scaleFactor` global a été augmenté (référence 800px) pour agrandir tous les éléments du jeu. L'arc de cercle de la main de cartes a été remonté (décalage de 25% de la hauteur) pour libérer l'espace visuel occupé par la barre de vie HUD en bas de l'écran.
- feat: implémentation Phase 3
    - Ajustements fins de la taille et disposition (Plan 12 & 13)
        - J'ai terminé la Phase 3. Les cartes en main ont été spécifiquement réduites (`scaleFactor * 0.75`) tandis que les entités sur le terrain ont été agrandies (`scaleFactor * 1.3`). La main de cartes a été légèrement redescendue (`offset 0.15`) et son arc resserré (`angleStep max 0.08`). Enfin, la barre de vie du joueur a été réduite en largeur (30%) et en hauteur (12px) pour être moins intrusive.
- feat: implémentation Phase 4
    - Polissage de l'UI et des positions (Plan 14)
        - J'ai terminé la Phase 4. La barre de vie du joueur a été collée tout en bas de l'écran. La barre de vie des ennemis a été remplacée par un badge statique circulaire situé à droite de leur carte. Enfin, l'indicateur d'intention des ennemis a été descendu pour être juste au-dessus du bord supérieur de la carte.
        
## Phase 7 - Profondeur du Gameplay & Mécaniques de Combat

- feat: implémentation Phase 1
    - Système d'Altérations d'État (Buffs/Debuffs)
        - J'ai terminé la Phase 1. J'ai modélisé les effets de statut avec la classe `StatusEffect`, intégré une liste de statuts dans `EntityStats`, et mis à jour le `RunController` et le `EffectResolver` pour gérer l'application et la résolution des effets (ex: Force, Faiblesse, Poison). Le système de dégâts prend désormais en compte ces modificateurs et le poison est appliqué automatiquement au début de chaque tour pour le héros et les ennemis.