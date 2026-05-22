## Phase 36 - Résolution des failles de retour en arrière (PopScope et verrouillage de carte)

- fix: Interception du retour en arrière et verrouillage réactif de la carte
    - Ajout de PopScopes réactifs et sécurisation de _isNodeAvailable pour forcer la complétion des nœuds
        - J'ai terminé la sécurisation du retour arrière sur navigateur et mobile. D'une part, `_isNodeAvailable` dans `map_screen.dart` n'autorise plus l'accès aux nœuds suivants si le nœud actif n'est pas marqué complété (`isCompleted`), ne laissant cliquable que le nœud actuel pour y ré-entrer. D'autre part, des `PopScope` réactifs pilotés par l'état Riverpod ont été intégrés sur `GameScreen` et dans les overlays de carte (`_showNodeOverlay`), empêchant toute sortie intempestive via le bouton Retour ou le swipe tactile tant que la phase en cours n'est pas résolue.

- feat: Animation de tremblement (shake) sur les cartes injouables faute de mana
    - Intégration dans onTapDown et onDragStart pour donner un retour visuel clair
        - J'ai ajouté un retour visuel immédiat et ergonomique sous forme de micro-animation de tremblement latéral (shake) lorsque le joueur essaie de jouer une carte qu'il ne peut pas s'offrir en mana (soit en cliquant dessus via `onTapDown` soit en initiant un drag via `onDragStart`). De plus, le mécanisme `_shakeAnimation` a été optimisé pour être totalement robuste contre les clics rapides répétés (réinitialisation et annulation des anciens effets en cours), garantissant que la carte retourne toujours à sa position idéale de main sans décalage cumulatif.
