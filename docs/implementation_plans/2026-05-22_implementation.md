## Phase 36 - Résolution des failles de retour en arrière (PopScope et verrouillage de carte)

- fix: Interception du retour en arrière et verrouillage réactif de la carte
    - Ajout de PopScopes réactifs et sécurisation de _isNodeAvailable pour forcer la complétion des nœuds
        - J'ai terminé la sécurisation du retour arrière sur navigateur et mobile. D'une part, `_isNodeAvailable` dans `map_screen.dart` n'autorise plus l'accès aux nœuds suivants si le nœud actif n'est pas marqué complété (`isCompleted`), ne laissant cliquable que le nœud actuel pour y ré-entrer. D'autre part, des `PopScope` réactifs pilotés par l'état Riverpod ont été intégrés sur `GameScreen` et dans les overlays de carte (`_showNodeOverlay`), empêchant toute sortie intempestive via le bouton Retour ou le swipe tactile tant que la phase en cours n'est pas résolue.
