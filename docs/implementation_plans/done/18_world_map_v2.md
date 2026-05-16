# Plan d'implémentation : Phase 11 - Refonte Avancée de la World Map

Ce plan détaille l'implémentation des améliorations UI/UX et de génération pour la carte du monde, basées sur l'analyse `5_analyse_world_map_improvements.md`.

## Étape 1 : Rendu Visuel et Lignes Animées
*   **Objectif :** Rendre la carte plus vivante et organique.
*   **Tâches :**
    *   Modifier `MapConnectionPainter` pour remplacer les lignes pleines par des chemins en pointillés (`dash path`).
    *   Intégrer un `AnimationController` dans `MapScreen` pour faire défiler (animer) la phase des pointillés, donnant l'illusion d'un flux d'énergie vers l'avant.
    *   Améliorer le fond de la carte (gradient plus complexe ou particules simples).

## Étape 2 : Animation du Pion Joueur
*   **Objectif :** Améliorer l'immersion lors du déplacement entre les nœuds.
*   **Tâches :**
    *   Au lieu que le nœud actuel ne s'allume instantanément, créer un "pion" visuel (ex: icône de bouclier ou casque) qui se déplace de manière fluide (avec un `Tween` ou `AnimatedPositioned`) de l'ancien nœud vers le nouveau.

## Étape 3 : Refonte des Transitions (Shop et Rest en Modales)
*   **Objectif :** Ne pas casser l'expérience de la carte en changeant complètement d'écran.
*   **Tâches :**
    *   Convertir `ShopScreen` et `RestScreen` pour qu'ils soient appelés via `showGeneralDialog` ou `showModalBottomSheet` en superposition directe par-dessus `MapScreen`, avec un fond flou (blur).
    *   Gérer la mise à jour de la carte en temps réel à la fermeture de ces modales.

## Étape 4 : Surbrillance des Chemins (Path Highlighting)
*   **Objectif :** Aider le joueur à planifier sa route.
*   **Tâches :**
    *   Lorsqu'un joueur survole un nœud accessible (même éloigné de 3 étages), calculer récursivement le chemin pour l'atteindre et mettre en surbrillance (glow) toutes les lignes de connexion concernées.

## Étape 5 : Génération Dirigée (Chokepoints)
*   **Objectif :** Rendre les choix de routes plus cruciaux.
*   **Tâches :**
    *   Modifier `MapGeneratorService` pour forcer un goulot d'étranglement (Chokepoint) à mi-chemin (ex: étage 5) où tous les chemins se rejoignent sur un seul nœud (souvent un Élite ou Repos).
    *   Ajouter une règle forçant l'étage 9 (juste avant le boss) à être un nœud de Repos.
