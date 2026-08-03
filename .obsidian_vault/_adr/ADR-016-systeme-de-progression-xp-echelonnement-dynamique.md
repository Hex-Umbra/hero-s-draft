## 📈 ADR-016 : Système de Progression XP & Échelonnement Dynamique des Ennemis (XP Progression & Enemy Scaling)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans la version initiale, le niveau du héros était figé et les ennemis possédaient des statistiques prédéfinies et fixes dans les fichiers JSON. Ce manque de progression à long terme aplatissait l'expérience au cours d'une run, ne proposant aucun sentiment d'évolution ou de montée en puissance. Pour introduire une dimension RPG gratifiante et conserver une tension compétitive croissante tout au long des actes, le jeu nécessitait l'intégration d'un système d'expérience avec des seuils exponentiels et une mise à l'échelle dynamique des caractéristiques des ennemis basée sur le niveau du joueur et la difficulté de la salle de combat.

### Décision
1. **Courbe d'Expérience Exponentielle** :
   - Implémenter une formule de progression basée sur des seuils d'expérience exponentiels :
     $$RequiredXP = 100 \times 1.5^{\text{level} - 1}$$
   - Concevoir la méthode de gain d'XP (`RunController.gainXp(int xp)`) de sorte qu'elle traite de manière récursive ou itérative les gains d'XP massifs. Si le montant d'XP dépasse plusieurs paliers consécutifs, le héros gagne plusieurs niveaux à la fois tout en conservant et reportant le reliquat d'expérience restant (`XP carry-over`) de façon mathématiquement intègre.

2. **Échelonnement Dynamique des Niveaux de Combat** :
   - Déterminer le niveau d'un ennemi de façon dynamique selon la formule :
     $$EnemyLevel = PlayerLevel + (Act - 1) \times 2 + NodeModifier$$
     - `NodeModifier` vaut `0` pour un combat standard, `+1` pour un combat élite, et `+2` pour un combat de boss de fin d'acte.

3. **Multiplicateurs de Caractéristiques de Combat** :
   - Mettre à l'échelle dynamiquement les points de vie maximaux et les dégâts de base des monstres lors de l'initialisation du combat dans `CombatController`.
   - Augmenter les PV max de **+12% par niveau** de monstre supplémentaire au-dessus du niveau 1.
   - Augmenter l'attaque de base de **+8% par niveau** de monstre supplémentaire au-dessus du niveau 1.
   - Les formules appliquées sont :
     - $$ScaledHP = BaseHP \times [1 + (Level - 1) \times 0.12]$$
     - $$ScaledDamage = BaseDamage \times [1 + (Level - 1) \times 0.08]$$

4. **Visuels et HUD de Progression** :
   - Intégrer une barre de progression XP dorée permanente sous les mini-statistiques du héros sur la carte du monde (`MapScreen`) pour une visualisation claire.
   - Suffixer dynamiquement le nom des ennemis par leur niveau calculé dans l'arène de combat Flame (ex : "Squelette (Niv. 3)") afin de signaler immédiatement la dangerosité relative aux joueurs.

### Preuves dans le code
- `RunController.gainXp(int xp)` : Boucle de consommation d'XP avec augmentation du niveau et report du reliquat.
- `CombatController.initializeCombat()` : Calcul dynamique du niveau et application des multiplicateurs `1 + (level - 1) * 0.12` pour les HP, et `1 + (level - 1) * 0.08` pour les dégâts.
- `test/unit/xp_scaling_test.dart` : Suite de tests unitaires validant l'XP cumulée, le carry-over en cascade (multi-levels), et le calcul correct des niveaux de monstres standards, élites et boss.

### Conséquences
- ✅ **Expérience RPG Profonde** : La boucle d'action devient gratifiante grâce à la montée de niveau et aux bonus de caractéristiques permanentes choisis par le joueur.
- ✅ **Courbe de Difficulté Équilibrée** : L'adaptation automatique élimine la trivialisation des combats en late-game tout en offrant un défi juste et progressif.
- ✅ **Absence de bugs de transition** : Les tests unitaires rigoureux sur l'XP prouvent qu'aucune expérience n'est perdue ou dupliquée lors des montées de niveau successives.
- ⚠️ **Danger de "Soft Lock"** : Si le joueur n'optimise pas son deck (fusions automatiques et forges), la mise à l'échelle des ennemis (+12% HP, +8% ATK) peut rapidement surpasser sa puissance offensive, créant des combats longs et punitifs.
