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
