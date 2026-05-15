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
- feat: implémentation Phase 2
    - Types de Cartes Spéciaux (Pouvoirs et Malédictions)
        - J'ai terminé la Phase 2. J'ai implémenté le support pour les cartes de type `Power` (qui sont épuisées après usage et appliquent des effets permanents via des statuts de régénération comme `strength_regen` ou `armor_regen`) et les cartes de type `Status/Curse` (comme `Injury` qui est injouable). Le `DeckNotifier` gère déjà l'épuisement des pouvoirs, et j'ai enrichi le `EffectResolver` et les contrôleurs pour traiter ces nouveaux comportements de début de tour.
- feat: implémentation Phase 3
    - Reliques et Objets Passifs
        - J'ai terminé la Phase 3. J'ai mis en place l'architecture des reliques avec `RelicData` et `RelicTrigger`. Le `RunController` gère désormais une liste de reliques et possède une méthode `applyRelics` pour déclencher des effets passifs (gain de mana, armure, force ou soin) à des moments clés (début de combat, début de tour). J'ai intégré ces appels dans le cycle de jeu principal et validé le tout par un `dart analyze`.
- feat: implémentation Phase 4
    - Visualisation des Statuts (UI)
        - J'ai terminé la Phase 4. J'ai créé le composant `StatusIndicator` qui affiche une rangée d'icônes dynamiques avec leurs valeurs respectives (Poison, Force, Faiblesse, etc.). Ce composant a été intégré à `HeroCard` (au-dessus) et `EnemyCard` (au-dessous), permettant au joueur de suivre en temps réel les altérations d'état actives sur toutes les entités du terrain.

## Phase 8 - World Map et Solidification Technique

- feat: implémentation Phase 1.1
    - Modélisation de la Carte (MapNode)
        - J'ai terminé l'Étape 1.1. J'ai créé le modèle `MapNode` avec les types de nœuds nécessaires (combat, elite, shop, rest, event) et la gestion des connexions pour structurer la progression sous forme de graphe.
- feat: implémentation Phase 1.2
    - Service de Génération de Carte (MapGeneratorService)
        - J'ai terminé l'Étape 1.2. J'ai implémenté le `MapGeneratorService` qui génère un graphe acyclique dirigé (DAG) avec plusieurs étages. Le service garantit la connectivité entre les étages et répartit aléatoirement les types de rencontres (Combat, Élite, Boutique, Repos, Événement).
- feat: implémentation Phase 1.3
    - Interface World Map (MapScreen) et Intégration du Flux
        - J'ai terminé l'Étape 1.3. J'ai créé le `MapScreen` avec un `InteractiveViewer` et un `CustomPainter` pour afficher la carte et ses connexions. Le `RunController` a été mis à jour pour gérer l'état de la carte, la position du joueur et l'économie (or). Le flux de jeu est désormais complet : Sélection de classe -> Map -> Combat -> Draft -> Retour à la Map avec le nœud complété.
- feat: implémentation Phase 1.4
    - Améliorations UI/UX de la World Map (Tooltips, Légende, Hover)
        - J'ai terminé l'Étape 1.4. J'ai ajouté un système de tooltips explicatifs sur chaque nœud (via appui long), une légende interactive dans le coin inférieur gauche pour identifier les types de rencontres, et un effet de survol dynamique (agrandissement et lueur) pour indiquer les nœuds sélectionnables.
- feat: implémentation Phase 1.5
    - Multiplicateurs de difficulté pour Élites et Boss
        - J'ai terminé l'Étape 1.5. Les nœuds Élite appliquent désormais un multiplicateur de 1.5x aux statistiques des ennemis (PV et Attaque). Les nœuds Boss appliquent un multiplicateur de 3.0x, génèrent un seul ennemi et l'agrandissent visuellement de 50% pour un effet colossal.
- feat: implémentation Phase 1.6
    - Nœud de Repos (RestScreen)
        - J'ai terminé l'Étape 1.6. J'ai créé le `RestScreen` qui propose trois actions au joueur : se reposer (+30% PV), forger (améliorer une carte au niveau supérieur) ou oublier (retirer définitivement une carte du deck). Le système de sélection de carte a été intégré directement dans cet écran via un modal.
- feat: implémentation Phase 1.7
    - Nœud d'Événement (EventScreen)
        - J'ai terminé l'Étape 1.7. J'ai mis en place un système d'événements textuels basé sur un fichier JSON (`events.json`). Le joueur doit faire face à des situations narratives avec des choix multiples ayant des conséquences immédiates sur ses statistiques, son or ou son deck.

- feat: implémentation Phase 2
    - Système d'Or et Boutique (ShopScreen)
        - J'ai terminé la Phase 2. L'économie est en place avec l'or gagné après les combats (dans `DraftScreen`). J'ai créé `ShopScreen` qui s'ouvre lorsqu'on clique sur un nœud "Shop". La boutique propose aléatoirement 3 cartes (excluant statuts) et un service de soin. L'or est correctement débité et les cartes sont ajoutées au Master Deck via le `DeckController`.

- feat: implémentation Phase 3
    - Solidification et Robustesse (Tests et i18n)
        - J'ai terminé la Phase 3. J'ai ajouté des tests unitaires (`map_generator_test.dart`, `effect_resolver_test.dart`) pour garantir la fiabilité de la génération de map et de la logique de combat. J'ai également écrit un test de widget (`map_screen_test.dart`) et mis en place le package `flutter_localizations` avec des fichiers `.arb` pour préparer l'interface multilingue (français/anglais).

## Phase 8.5 - Polissage du Contenu, de la Map et de la Progression

- feat: implémentation Phase 15 Étape 1
    - Amélioration des Cartes Statuts et de l'IA Ennemie
        - J'ai terminé l'Étape 1. Les cartes de statut sont explicitement bloquées lors du jeu, la carte "Blessure" a été retirée du deck de base, et l'IA ennemie possède désormais l'intention `debuffDeck` avec une probabilité de 10% pour ajouter des statuts dans la défausse du joueur.
- feat: implémentation Phase 15 Étape 2
    - Refonte des Récompenses de Draft (Combat)
        - J'ai terminé l'Étape 2. Une 4ème option de récompense (Clonage) avec une probabilité d'apparition de 30% a été ajoutée. Le joueur peut choisir cette option pour ouvrir un modal affichant 3 cartes aléatoires de son deck, en sélectionner une et l'ajouter à son deck (ce qui déclenche l'Auto-Merge si applicable).
- feat: implémentation Phase 15 Étape 3
    - Améliorations de la Boutique (ShopScreen)
        - J'ai terminé l'Étape 3. La boutique propose désormais deux nouveaux services : l'Oubli (retirer une carte du deck pour 75 or) et le Miroir Magique (cloner une carte pour 150 or). Les cartes achetées disparaissent dynamiquement de la liste et l'interface globale a été ajustée.
- feat: implémentation Phase 15 Étape 4
    - Corrections et Améliorations de la World Map
        - J'ai terminé l'Étape 4. La caméra de la MapScreen se centre désormais automatiquement sur le nœud actif ou le départ. Le nœud de Boss n'est plus coupé en haut de l'écran grâce à un ajustement du layout. Enfin, une boucle de gameplay a été implémentée : valider le nœud Boss génère une nouvelle carte tout en conservant les acquis du joueur.
- feat: implémentation Phase 15 Étape 5
    - Refonte du système de buffs (Finis les buffs infinis)
        J'ai terminé l'Étape 5. J'ai nettoyé les altérations d'état entre les combats (`statuses = []` au début d'un combat). J'ai modifié les cartes comme *Forme Démoniaque* pour qu'elles n'utilisent plus une mécanique de "régénération" buggée, mais qu'elles appliquent directement un buff de *Force* d'une durée stricte (ex: 3 tours). L'effet de *Métallisation* a aussi été borné dans le temps. (Nécessite un redémarrage complet de l'app pour charger le JSON mis à jour).

## Phase 11 - Refonte Avancée de la World Map

- feat: implémentation Étape 1
    - Lignes de connexion animées et rendu visuel (MapScreen)
        - J'ai terminé l'Étape 1. Le `MapConnectionPainter` a été entièrement refactorisé pour dessiner des chemins en pointillés (`dash path`). Un `AnimationController` a été ajouté au `MapScreen` pour animer la phase des pointillés en continu, donnant une illusion de défilement fluide et d'énergie circulant le long des chemins de la carte.
- feat: implémentation Étape 2
    - Animation du Pion Joueur (Avatar de Map)
        - J'ai terminé l'Étape 2. J'ai créé un composant `_PlayerPawn` qui représente physiquement le joueur sur la carte. Grâce à un `AnimatedPositioned` avec une courbe `easeInOutBack`, le pion se déplace désormais de manière fluide entre les nœuds lorsque le joueur sélectionne une destination, offrant un feedback visuel beaucoup plus satisfaisant et immersif que le simple changement de couleur précédent.


        ## Phase 9 - Visual Juice & Game Feel (Style Balatro)

        - feat: implémentation Phase 1
        - Dynamisme de la Carte en Main (Inertie & Tilt)
        - J'ai terminé la Phase 1. J'ai implémenté un système de "Tilt" dynamique dans `CardComponent` qui incline la carte en fonction de sa vitesse de déplacement latérale pendant le drag. J'ai également amélioré l'animation de retour en main en utilisant `Curves.elasticOut` pour simuler un effet de ressort satisfaisant, inspiré du feeling organique de Balatro.
        - feat: implémentation Phase 2
            - Séquence de Jeu et Impact (Attack Sequence)
                - J'ai terminé la Phase 2. L'action de jouer une carte est désormais spectaculaire : la carte recule en anticipation, fonce vers sa cible à haute vitesse, devient blanche à l'impact et explose en un bouquet de particules bleues. Le moteur `HerosDraftGame` a été mis à jour pour attendre la fin de cette animation avant de retirer officiellement la carte du monde.
        - feat: implémentation Phase 3
            - Réaction de l'Ennemi (Feedback de Dégâts)
                - J'ai terminé la Phase 3. J'ai ajouté une méthode `shakeAndFlashAnimation` dans `EnemyCard` qui se déclenche lors de la réception de dégâts, provoquant un tremblement aléatoire et un flash blanc. Le composant `FloatingText` a également été amélioré avec un effet de "Pop" initial (`ScaleEffect` avec `bounceOut`), rendant l'affichage des dégâts beaucoup plus percutant.

## Phase 10 - Corrections de Bugs et Stabilité

- fix: Correction du reroll des récompenses
    - Refonte du composant DraftScreen
        - J'ai corrigé le bug qui provoquait la régénération automatique des récompenses après un combat. Le composant `DraftScreen` a été converti en `ConsumerStatefulWidget` et la génération des choix a été déplacée dans `initState` afin de garantir qu'elle ne s'exécute qu'une seule fois par sélection.
- fix: Affichage dynamique des statistiques des cartes (Leveling)
    - Mise à jour de CardComponent et UiCard
        - J'ai corrigé le bug d'affichage des descriptions des cartes améliorées. Les composants `CardComponent` et `UiCard` calculent désormais dynamiquement les valeurs des effets (+50% par niveau au-dessus du niveau 1) pour afficher les dégâts, soins et armure réels correspondant au niveau de la carte.
- fix: Correction de l'overflow dans la boutique (ShopScreen)
    - Ajustement des contraintes de hauteur
        - J'ai corrigé une erreur `RenderFlex overflow` dans la boutique en augmentant la hauteur du conteneur des cartes à 220px. Cela laisse suffisamment d'espace pour afficher les cartes (`UiCard`) et leurs boutons d'achat sans dépassement vertical.
- feat: Amélioration de l'accès au Deck et Notifications de Fusion
    - Refonte du HUD et de la Map
        - J'ai déplacé le bouton "Mon Deck" à côté de la barre de vie du joueur pendant le combat pour un accès plus intuitif, tout en maintenant le bouton "Pause" en haut à droite. Sur la carte du monde (`MapScreen`), le bouton est désormais plus explicite avec du texte ("MON DECK") et inclut un indicateur visuel (point rouge et texte "DECK (!)") lorsqu'une fusion de 3 cartes identiques est possible.
- fix: Correction du cycle de pioche et disparition de cartes
    - Robustification du DeckNotifier
        - J'ai corrigé un bug où des cartes pouvaient sembler disparaître ou être dupliquées dans le deck. La méthode `playCard` a été sécurisée pour ne déplacer une carte vers la défausse que si elle est réellement présente en main, évitant les doublons d'ID qui causaient des erreurs d'affichage dans le moteur Flame. J'ai également clarifié le comportement des cartes de type "Pouvoir" qui sont intentionnellement épuisées (retirées du cycle) après usage.
- feat: Indicateurs visuels pour les cartes à usage unique (Pouvoirs)
    - Clarification de la mécanique d'épuisement
        - Afin de rendre explicite la mécanique d'épuisement des cartes de type "Pouvoir", j'ai ajouté un badge rouge "USAGE UNIQUE" sur les `UiCard` et une mention "USAGE UNIQUE (Épuisement)" dans les tooltips détaillés. De plus, pendant le combat, ces cartes affichent désormais un indicateur "1/1" en rouge en bas à droite pour signaler leur usage unique immédiat.
- feat: Affichage dynamique des dégâts finaux sur les cartes
    - Calcul en temps réel avec bonus d'attaque
        - Les cartes d'attaque affichent désormais la somme exacte des dégâts qui seront infligés (Dégâts de base de la carte + Statistique d'Attaque du héros). Cet affichage est mis à jour dynamiquement pendant le combat, permettant au joueur de voir l'impact de ses buffs de force ou débuffs de faiblesse directement sur ses cartes avant de les jouer.
- fix: Optimisation de l'affichage du texte sur les cartes en combat
    - Utilisation de TextBoxComponent et gestion de l'overflow
        - J'ai corrigé les problèmes de dépassement de texte sur les cartes jouées pendant le combat. L'utilisation de `TextBoxComponent` permet désormais un retour à la ligne automatique pour les descriptions. Les tailles de police et les marges internes ont été ajustées pour garantir que le nom de la carte et ses effets restent parfaitement lisibles et confinés dans les limites de la carte.
- fix: Restauration de la visibilité des entités et de l'interactivité
    - Correction des crashs Flame et du blocage des hit-tests
        - J'ai résolu un bug majeur qui rendait les entités de jeu invisibles et l'interface non interactive. La cause était double : un crash silencieux du moteur Flame dû à des méthodes de couleur incompatibles, et un blocage des événements tactiles par une `SafeArea` mal positionnée. J'ai sécurisé le `CardComponent` avec des méthodes robustes (`withAlpha`) et refactorisé le HUD de `GameScreen` pour utiliser exclusivement des widgets `Positioned`, garantissant ainsi que l'interface Flutter ne bloque plus le moteur Flame.
- feat: Refonte fondamentale du rendu textuel des cartes (Combat)
    - Passage au TextPainter natif de Flutter
        - J'ai entièrement réécrit le système d'affichage des textes sur les cartes de combat. En abandonnant les `TextComponent` de Flame au profit de `TextPainter` (Flutter natif), j'ai supprimé tout risque de crash lié aux widgets de texte complexes tout en obtenant un contrôle total sur le retour à la ligne (`word wrap`), l'alignement et la richesse stylistique. Les textes sont désormais dessinés manuellement sur le `Canvas` de Flame, garantissant une fluidité parfaite et une stabilité maximale.