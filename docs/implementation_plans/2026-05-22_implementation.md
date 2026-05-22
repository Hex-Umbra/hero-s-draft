## Phase 36 - Résolution des failles de retour en arrière (PopScope et verrouillage de carte)

- fix: Interception du retour en arrière et verrouillage réactif de la carte
    - Ajout de PopScopes réactifs et sécurisation de _isNodeAvailable pour forcer la complétion des nœuds
        - J'ai terminé la sécurisation du retour arrière sur navigateur et mobile. D'une part, `_isNodeAvailable` dans `map_screen.dart` n'autorise plus l'accès aux nœuds suivants si le nœud actif n'est pas marqué complété (`isCompleted`), ne laissant cliquable que le nœud actuel pour y ré-entrer. D'autre part, des `PopScope` réactifs pilotés par l'état Riverpod ont été intégrés sur `GameScreen` et dans les overlays de carte (`_showNodeOverlay`), empêchant toute sortie intempestive via le bouton Retour ou le swipe tactile tant que la phase en cours n'est pas résolue.

- feat: Animation de tremblement (shake) sur les cartes injouables faute de mana
    - Intégration dans onTapDown et onDragStart pour donner un retour visuel clair
        - J'ai ajouté un retour visuel immédiat et ergonomique sous forme de micro-animation de tremblement latéral (shake) lorsque le joueur essaie de jouer une carte qu'il ne peut pas s'offrir en mana (soit en cliquant dessus via `onTapDown` soit en initiant un drag via `onDragStart`). De plus, le mécanisme `_shakeAnimation` a été optimisé pour être totalement robuste contre les clics rapides répétés (réinitialisation et annulation des anciens effets en cours), garantissant que la carte retourne toujours à sa position idéale de main sans décalage cumulatif.

## Phase 37 - Correction du calcul des intentions d'attaque des ennemis élites buffés

- fix: Correction du calcul des dégâts d'intentions des élites/boss buffés
    - Introduction d'une formule de mise à l'échelle proportionnelle de l'intention et de séparation du bonus dynamique en combat.
        - Résolution du problème où les intentions d'attaque successives des ennemis élites ou boss (qui ont un modificateur de spawn initial) calculaient de façon erronée les dégâts de leurs attaques secondaires. Désormais, le modificateur de spawn (`_spawnMultiplier`) et l'attaque de départ (`_startingAttaque`) sont stockés à l'instanciation de `EnemyCard`. Les bonus de combat (comme les buffs plats d'attaque ou les statuts de Force) sont calculés de manière isolée (`inBattleBonus = stats.effectiveAttaque - _startingAttaque`) et ajoutés à l'intention préalablement mise à l'échelle proportionnelle : `max(stats.effectiveAttaque, scaledValue + inBattleBonus)`. Les tests unitaires ont été étendus et valident la correction.

## Phase 38 - Suppression de la relique de test temporaire

- fix: Suppression du bonus automatique d'armure de début de combat
    - Retrait de la relique de test dans GameScreen et nettoyage de l'import inutile
        - J'ai supprimé l'ajout automatique de la relique temporaire "Calendrier de Pierre" (qui offrait systématiquement +6 armure au début de chaque combat lorsque le deck de départ était vide lors d'un test). Cela corrige le comportement inattendu où les classes, notamment le Berserker, commençaient systématiquement le combat avec 6 d'armure au lieu de leur valeur par défaut de 0. J'ai également nettoyé l'import inutile de `relic_data.dart` et validé le code avec `flutter analyze` et `flutter test`.

## Phase 39 - Refactoring des buffs ennemis via le système de Force (StatusEffect)

- fix: Conversion du buff plat d'attaque en statut de Force permanent
    - Remplacement de la mutation directe de stats.attaque par l'ajout du statut strength pour éviter les doubles calculs
        - Résolution définitive du problème de calcul d'attaque sur les élites buffés (où une attaque après buff comptabilisait doublement l'effet). Les intentions de type `buff` appliquent désormais un `StatusEffect` de Force ('strength') de 99 tours (permanent pour le combat) au lieu de muter directement la variable `attaque` du modèle `EntityStats`. Les getters réactifs et l'indicateur d'intention tirent parti de ce statut de manière saine, et la couverture de test a été mise à jour et validée.

- fix: Prévention de la double mise à l'échelle des intentions d'attaque générées aléatoirement (fallback)
    - Remplacement de stats.attaque par data?.baseDamage ?? _startingAttaque lors du roll d'intentions aléatoires
        - Correction d'un bug identifié où, si l'ennemi n'avait pas d'intentions définies dans son fichier JSON de données (fallback aléatoire), la génération de l'intention d'attaque utilisait stats.attaque (déjà mise à l'échelle) au lieu de sa valeur brute de base. Cela entraînait une double multiplication de l'échelle par _spawnMultiplier dans le getter réactif effectiveIntent. Le correctif garantit que la génération aléatoire s'appuie désormais sur la valeur non mise à l'échelle.

## Phase 40 - Affichage des PV dans la barre de vie

- feat: Affichage de la quantité de PV directement dans la barre de vie du joueur
    - Intégration d'un Stack contenant le LinearProgressIndicator et le Text pour un rendu plus compact et lisible
        - J'ai modifié l'implémentation du HUD de combat dans `game_screen.dart`. Auparavant, les PV textuels ('currentPv / maxPv PV') étaient affichés au-dessus de la barre de vie. Désormais, ils sont intégrés et centrés directement au sein de celle-ci grâce à un widget `Stack`. Cela offre un rendu visuel plus moderne et compact, tout en garantissant une lisibilité optimale grâce à des ombres textuelles.

## Phase 41 - Avertissement contextuel de fin de tour à 0 mana

- feat: Signaler au joueur qu'il n'a plus de mana via une notification contextuelle non interactive
    - Interception de la transition du mana vers 0 et affichage d'un encadré élégant et non intrusif juste au-dessus du bouton de fin de tour.
        - J'ai implémenté un système d'alerte dans `game_screen.dart`. Lorsqu'un lancer de carte fait passer le mana du joueur à exactement 0, et après un délai de 600ms pour laisser les animations visuelles s'achever, un élégant encadré d'avertissement ("Plus de mana. Terminer le tour ?") apparaît directement au-dessus du bouton "Fin de Tour". Cette notification est purement informative et non interactive (sans boutons "Oui" / "Non"), incitant directement le joueur à utiliser le bouton "Fin de Tour" situé juste en dessous si aucune autre action (comme des cartes à coût 0) n'est possible.
        - **Alignement et dimensions** : Le conteneur d'avertissement et le bouton « Fin de Tour » ont tous deux été configurés avec une largeur identique fixe de `170` pixels, garantissant un alignement horizontal parfait sur le côté droit de l'écran. L'espacement vertical a également été finement ajusté pour offrir un rendu visuel harmonieux et unifié. L'avertissement se désactive automatiquement dès que le joueur récupère du mana ou lorsque son tour prend fin.

## Phase 42 - Compteur de tour en combat

- feat: Affichage d'un compteur de tour élégant juste sous le bouton de fin de tour
    - Ajout d'une variable d'état `_turnCount` et affichage d'un widget conteneur centré et parfaitement aligné de 170px de large.
        - J'ai introduit un compteur réactif de tours (`_turnCount` initialisé à 1) au sein de `_GameScreenState`. Ce compteur s'incrémente automatiquement à chaque transition de phase ramenant le tour au joueur (via le callback `onTurnEnded`).
        - Un conteneur d'affichage reprenant le même thème sombre haut de gamme (`0xFF1E1E2C` à 200 d'opacité) et la même largeur de `170` pixels que les éléments supérieurs a été ajouté exactement 10 pixels en dessous du bouton « Fin de Tour » (`top: MediaQuery.of(context).size.height / 2 + 33`), offrant une excellente cohérence visuelle et un repère direct sur la progression temporelle du combat.

## Phase 43 - Réinitialisation du Deck lors du lancement d'une nouvelle partie

- fix: Réinitialisation du deck de cartes à la sélection d'une classe
    - Ajout d'une méthode `clearDeck()` dans `DeckNotifier` et appel de celle-ci lors du clic sur le bouton de sélection d'une classe.
        - J'ai identifié la cause racine d'un bug persistant de persistance de la pioche : lorsqu'une partie se terminait par la mort du joueur et qu'une nouvelle run était lancée, le deck de cartes conservait les ajouts et fusions de la partie précédente car le fournisseur global `deckProvider` n'était pas réinitialisé.
        - Pour y remédier, j'ai introduit la méthode `clearDeck()` dans `DeckNotifier` pour réinitialiser le `DeckState`. Cette méthode est désormais systématiquement appelée au clic sur le bouton de sélection dans `class_selection_screen.dart`, juste avant de lancer la nouvelle partie via `startNewRun`. Cela garantit que la nouvelle run commence toujours avec le paquet de cartes de départ approprié et réinitialisé.

## Phase 44 - Coloration dynamique des prix de la boutique (Bouton d'achat vert/rouge)

- feat: Affichage dynamique en vert ou rouge du coût en or dans le shop
    - Ajout du calcul de solvabilité (`canAfford`) et coloration translucide premium des boutons de prix.
        - J'ai modifié `shop_screen.dart` afin d'intégrer un retour visuel direct et élégant sur la solvabilité du joueur dans le shop. Désormais, le montant nécessaire pour acheter un article (cartes en vente comme services de la boutique) s'affiche avec un fond vert premium (si le joueur a suffisamment d'or, ex. `Colors.green.shade900`) ou rouge premium (s'il n'a pas assez d'or, ex. `Colors.red.shade900`).
        - Les effets de survol souris (`_isHovered`) ont également été adaptés pour illuminer harmonieusement la couleur correspondante (vert plus clair ou rouge plus clair), tout en préservant le style sombre translucide haut de gamme du HUD et le comportement de désactivation (bouton grisé pour les potions déjà achetées).

## Phase 45 - Affichage clair des gains et pertes lors des événements

- feat: Affichage explicite des gains et pertes de statistiques lors des choix d'événements
    - Intégration de badges de conséquences animés et colorés décrivant les effets appliqués après chaque résolution.
        - Afin de donner un retour visuel clair et satisfaisant lors des rencontres d'événements, j'ai enrichi l'interface de `event_screen.dart`. Une fois qu'un choix d'événement est résolu, un nouvel en-tête « EFFETS APPLIQUÉS » apparaît sous la description du résultat, accompagné d'une série de badges colorés.
        - Chaque type d'action est représenté de manière distincte : l'or gagné/perdu (icône or ambre, avec fond vert pour gain ou rouge pour perte), les points de vie perdus/gagnés (icône cœur, fond rouge ou vert), l'augmentation de PV Max (icône d'ajout rose), la Force obtenue (icône d'éclair orange), et les reliques gagnées (icône d'étoile violette). Si un choix n'entraîne aucun effet (comme la prière), un badge neutre « Aucun effet » est affiché.
        - L'ensemble de ces badges apparaît grâce à une micro-animation d'échelle et d'opacité fluide (`TweenAnimationBuilder` sur 500ms avec une courbe `Curves.easeOutBack`) pour un effet haut de gamme très réactif.
        - **Correction d'overshoot d'opacité** : Pour éviter toute exception Flutter liée à un dépassement d'opacité (`opacity >= 0.0 && opacity <= 1.0` non respecté dû à l'effet de rebond de `Curves.easeOutBack`), la valeur d'animation passée au widget `Opacity` a été sécurisée avec un `.clamp(0.0, 1.0)`.

## Phase 46 - Refonte de l'affichage des intentions d'attaques ennemies

- feat: Délocalisation des intentions ennemies vers un panneau HUD réactif et clair
    - Retrait de l'indicateur rectangulaire intrusif au-dessus des ennemis et intégration d'un panneau d'intentions modernisé au-dessus de la défausse.
        - Pour rendre le combat plus lisible et dégager l'arène, j'ai masqué l'ancien rendu de l'indicateur d'intention (`IntentionIndicator.renderTree` configuré pour ne plus rien tracer sur le canvas Flame).
        - À la place, un panneau d'intentions dynamique et élégant a été intégré dans `game_screen.dart`, positionné idéalement à droite au-dessus de la défausse (`bottom: 80, right: 20`).
        - Ce panneau récapitule tous les ennemis vivants avec leurs points de vie actuels, leur nom (coloré en doré s'il s'agit d'un Boss), ainsi que leur intention réactive et formatée avec des icônes et couleurs adaptées (Attaque en rouge vif, Défense en bleu, Buff Force en violet, Malédictions en vert printanier).
        - L'import de `enemy_intent.dart` a été ajouté au sommet de `game_screen.dart` pour permettre la manipulation saine de l'enum `IntentType`.

## Phase 47 - Résolution du chargement des images de nouveaux ennemis et automatisation 100% dynamique

- fix: Préchargement et chargement asynchrone robuste des nouveaux ennemis (Slime, Orc, Squelette)
    - Ajout des images manquantes dans images.loadAll de heros_draft_game.dart et sécurisation via game.images.load dans enemy_card.dart.
        - J'ai identifié et corrigé la cause racine pour laquelle les nouvelles images d'ennemis ne se chargeaient pas correctement. D'une part, Flame s'attend à ce que toutes les images soient préchargées en cache au démarrage, mais seules les images du héros et du gobelin étaient déclarées dans `images.loadAll` de `heros_draft_game.dart`. J'ai complété cette liste en y intégrant `enemy_slime.png`, `enemy_skeleton.png` et `enemy_orc.png`.
        - D'autre part, pour rendre le système totalement pérenne et immunisé contre d'autres oublis futurs (si d'autres ennemis ou mods sont ajoutés dans `enemies.json`), j'ai modifié l'initialisation du sprite dans `EnemyCard.onLoad`. Au lieu de récupérer directement l'image depuis le cache de manière synchrone via `images.fromCache` (ce qui provoque un crash si l'image n'y est pas présente), j'ai basculé sur un chargement asynchrone robuste : `await game.images.load(spriteName)`. Cette méthode vérifie intelligemment le cache avant de solliciter le disque, garantissant un chargement fluide et sans crash.

- feat: Automatisation et dynamique complète du préchargement des images des héros et ennemis
    - Intégration d'un parseur JSON au démarrage du jeu dans heros_draft_game.dart pour lire et charger à la volée toutes les images définies dans les fichiers de données.
        - Afin de supprimer toute nécessité d'ajouter manuellement chaque nouvelle image d'ennemi ou de héros dans le code Dart, j'ai transformé la routine d'initialisation de `onLoad` dans `heros_draft_game.dart`.
        - Le jeu va désormais lire de manière asynchrone `enemies.json` (pour récupérer chaque champ `spritePath`) et `heroes.json` (pour récupérer chaque champ `iconPath`). Toutes ces images sont collectées, dédoublonnées via un `Set` et préchargées automatiquement via `images.loadAll`.
        - Un garde-fou robuste avec try-catch garantit un fallback élégant sur une liste par défaut si un environnement de test ne dispose pas de ces fichiers JSON mockés, prévenant toute régression de la suite d'intégration.

## Phase 48 - Préservation automatique du ratio d'aspect des images d'ennemis (BoxFit.contain)

- feat: Rendu proportionnel des sprites d'ennemis pour éviter toute distorsion visuelle
    - Remplacement du dimensionnement forcé par un calcul dynamique respectant le ratio original des PNG (intégration d'une logique de type BoxFit.contain).
        - Lorsque des images d'aspect ratio différent (comme le nouveau Slime, qui est un carré parfait de 320x320) sont intégrées dans le cadre rectangulaire standard des cartes d'ennemis (100x140), le moteur Flame étirait auparavant le sprite par défaut pour occuper tout l'espace, provoquant un écrasement horizontal disgracieux.
        - Pour y remédier, j'ai implémenté un système de dimensionnement proportionnel automatique dans `EnemyCard.onLoad`. L'image est analysée pour en extraire son ratio intrinsèque (`width / height`).
        - Si l'image est plus large ou carrée que le ratio de la carte, le sprite s'ajuste sur la largeur et se centre verticalement. Si elle est plus haute, elle s'ajuste sur la hauteur et se centre horizontalement.
        - Cela permet de supporter nativement et sans aucune déformation les images carrées transparentes faites à la main ou tout autre format alternatif, garantissant un rendu impeccable pour chaque asset de remplacement.

## Phase 49 - Relocalisation de la réinitialisation de l'armure en fin de combat

- fix: Réinitialisation de l'armure en fin de combat pour préserver les passifs de début de combat
    - Déplacement de `armure: 0` de `startCombat()` vers `completeCurrentNode()` dans `run_controller.dart` et ajout du déclenchement du passif au premier tour.
        - Auparavant, le reset complet de l'armure à 0 se faisait lors de la fonction `startCombat()`, ce qui écrasait instantanément le passif de l'Armure du Berserker (qui octroie de l'armure en fonction des PV manquants dès le début du combat/tour).
        - Pour y remédier, j'ai déplacé ce nettoyage de l'armure (`armure: 0`) et des statuts à la fin du combat, précisément dans la fonction `completeCurrentNode()` de `run_controller.dart`. De plus, j'ai ajouté l'appel de `TraitSystem.onTurnStart(this)` à la fin de `startCombat()` pour garantir que le passif s'applique correctement dès le premier tour du combat. Un test unitaire dédié a été écrit pour valider l'intégrité de ce comportement.

## Phase 50 - Réduction du tilt effect et ajout d'un halo lumineux interactif réactif dans la sélection de classe

- feat: Réduction du tilt effect et ajout d'un halo lumineux réactif sur les cartes de sélection de classe
    - Diminution du facteur multiplicateur de tilt à 0.05 et intégration d'un RadialGradient interactif centré sur la position de la souris.
        - Pour améliorer la finesse visuelle du menu de sélection de classe, j'ai réduit l'angle du tilt effect lorsque la souris survole la carte de classe en diminuant le coefficient multiplicateur à `0.05` (au lieu de `0.15`), limitant ainsi l'inclinaison maximale à environ 0.025 radians pour un effet beaucoup plus subtil et haut de gamme.
        - De plus, j'ai ajouté un effet de halo lumineux interactif et très léger qui suit précisément la position du curseur sur la carte. Cela a été accompli en stockant la coordonnée locale du pointeur (`_mousePosition`) lors de l'événement de déplacement, puis en l'utilisant au sein d'un widget `Stack` interne pour projeter un conteneur d'effet (`IgnorePointer`) décoré d'un `RadialGradient` centré de façon dynamique sur le curseur. L'opacité douce et la couleur adaptée à chaque classe offrent un rendu visuel premium et extrêmement réactif.

## Phase 51 - Affichage immédiat des intentions ennemies et agrandissement du panneau HUD

- fix: Résolution de l'affichage différé des intentions ennemies au début des combats
    - Initialisation synchrone de l'intention dans le constructeur de `EnemyCard` au lieu de `onLoad` asynchrone, et ajout d'un callback `onEnemiesSpawned` pour notifier Flutter de forcer le rebuild de l'interface.
        - Pour éliminer le comportement inesthétique où les intentions ennemies étaient masquées en début de combat (et ne s'affichaient qu'après l'interaction avec une carte), j'ai déplacé le premier appel de `_determineNextIntent()` du chargement d'image asynchrone `onLoad` directement dans le constructeur synchrone de `EnemyCard`. Ainsi, l'intention est calculée dès la naissance du composant.
        - D'autre part, j'ai introduit le callback `onEnemiesSpawned` dans `HerosDraftGame`. Il est automatiquement déclenché à la fin de `_spawnEnemies` (durant la frame initiale d'update). Le widget `GameScreen` y souscrit et appelle instantanément un `setState` pour synchroniser le HUD Flutter avec les intentions prêtes de Flame.
- feat: Agrandissement du panneau d'intentions ennemies pour une meilleure lisibilité
    - Passage de la largeur du panneau à 250px (au lieu de 200px) et augmentation des espacements et tailles de polices des éléments internes.
        - Le panneau d'intentions a été agrandi visuellement pour offrir un meilleur repère ergonomique. Sa largeur est passée à `250px` avec des marges intérieures (`padding`) de `16px`. Les tailles des polices et icônes ont également été augmentées (titre à `12px` et icône à `16px`, labels d'intentions à `13px`, etc.) garantissant une lisibilité idéale pour les intentions et points de vie des monstres.

## Phase 52 - Repositionnement général du terrain de combat et agrandissement des cartes en main

- feat: Réajustement des positions des cartes d'ennemis et du héros vers le haut du terrain
    - Remontée des cartes d'ennemis à 15% de la hauteur de l'écran (au lieu de 25%) et de la carte du héros à 48% (au lieu de 60%).
        - Afin de libérer de l'espace vertical au bas du terrain de combat pour accueillir une main de cartes agrandie, les ennemis ont été remontés plus près du bord supérieur de l'écran en ramenant leur ordonnée `posY` de `0.25` à `0.15` dans `_repositionEnemies()`.
        - De même, la carte du joueur (`HeroCard`) a été remontée vers le milieu de l'écran en modifiant sa coordonnée Y de `0.6` à `0.48` dans les méthodes `onGameResize()` et `_applyState()` de `HerosDraftGame`.
- feat: Remontée et agrandissement significatif des cartes jouables en main
    - Augmentation du facteur d'échelle des cartes en main de 0.75 à 0.88 et remontée de l'arc de cercle de la main de 15% à 23%.
        - Pour améliorer le confort visuel lors de la sélection des cartes et rendre les illustrations et descriptions textuelles plus faciles à lire, la taille globale des cartes jouables a été agrandie en passant leur coefficient d'échelle de base de `0.75` à `0.88` dans `CardComponent` et `HerosDraftGame` (les effets de survol et de focus s'adaptent proportionnellement).
        - De plus, pour accompagner cet agrandissement sans qu'elles ne sortent de l'écran par le bas, le centre de l'arc de cercle du deck de combat dans `_layoutHand()` a été ajusté de `size.y * 0.15` à `size.y * 0.23`, ce qui remonte agréablement la main de cartes sur l'axe vertical.



