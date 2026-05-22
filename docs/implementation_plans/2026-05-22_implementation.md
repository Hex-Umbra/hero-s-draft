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



