## 🗺️ ADR-029 : Génération Procédurale Avancée avec Quotas et Anti-Répétition (Advanced Map Generation Constraints)

### Statut
✅ Accepté & Implémenté

### Contexte
La génération de la carte du monde procédurale sous forme de DAG pouvait dans certains cas générer des parcours trop faciles, répétitifs ou déséquilibrés. Par exemple, un joueur pouvait traverser un chemin contenant 4 combats d'élites d'affilée ou aucun feu de camp (Rest) pour se soigner avant un combat majeur. Il était indispensable de rajouter des contraintes algorithmiques strictes pour équilibrer la répartition des types de salles et de forcer des chokepoints structurels, tout en gérant 3 boss uniques à la fin de l'Acte avec des récompenses spécifiques.

### Décision
1. **Solver par Quotas de Nœuds** :
   - Définir des quotas stricts pour chaque type de nœud dans `GameConstants.nodeQuotas` :
     - Combat : 12-22
     - Élite : 3-6
     - Repos : 3-6
     - Boutique (Shop) : 2-5
     - Événement (Event) : 4-9
   - Exécuter une passe d'optimisation `_balanceQuotas` après la génération du graphe pour réallouer les types de nœuds excédentaires vers les types déficitaires.
2. **Contrainte Anti-Répétition de Chemin** :
   - Parcourir récursivement les chemins possibles du graphe (`_hasThreeConsecutive` et `_getChainOfThree`) pour détecter si un type de nœud Élite ou Repos apparaît 3 fois consécutivement.
   - Si une violation est détectée, remplacer l'un des nœuds de la chaîne par un type alternatif (Combat, Shop ou Event) afin de garantir qu'aucun chemin ne contienne 3 Élites ou 3 Repos consécutifs.
3. **Chokepoints Structurels Forcés** :
   - **Étage 5** : Forcer la largeur de l'étage à 1 seul nœud et forcer son type à Élite pour créer un combat de mi-parcours obligatoire pour tous les chemins.
   - **Étage 8** : Forcer tous les nœuds générés pour cet étage à être de type Repos (Rest), assurant ainsi une halte obligatoire et salutaire juste avant le combat de Boss.
4. **Trilogie de Boss Distincts (Étage 9)** :
   - Configurer 3 nœuds de Boss distincts à l'étage 9, différenciés uniquement par leur position horizontale (`x` index) pour offrir des récompenses de combat uniques. Les boss sont générés de manière procédurale et mis à l'échelle via l'algorithme d'équilibrage du CombatRating de façon standardisée sans utiliser d'identifiants ou d'entités boss hardcodés.
5. **Mécanique de Récompenses de Boss Thématiques basées sur la Position** :
   - À la défaite d'un Boss, déclencher des récompenses spécifiques selon la position horizontale (`x` index) du nœud du boss :
     - **Position gauche (x = 0)** : Dialogue interactif affichant 3 cartes globales aléatoires, permettant au joueur d'en sélectionner entre 1 et 3 pour les ajouter gratuitement à son deck (icône Cartes).
     - **Position centrale (x = 1)** : Multiplie par 2 toute l'expérience (XP) cumulée par le joueur lors du combat (icône Magie/XP).
     - **Position droite (x = 2)** : Garantit l'obtention d'une relique de rareté supérieure (minimum Uncommon, excluant totalement les communes, icône Diamant). Les chances de rareté sont : Legendary 15%, Epic 30%, Rare 35%, Uncommon 20%.

### Preuves dans le code
- `MapGeneratorService.generateMap` : Implémentation des règles d'étages (y == 5, y == floors-2, y == floors-1).
- `MapGeneratorService._optimizeMapTypes` et `_balanceQuotas` : Application itérative du solver de quotas et de l'anti-répétition.
- `MapNodeWidget` : Attribution dynamique de l'icône, de la couleur et de l'info-bulle en fonction de la position horizontale `xIndex` de l'ID du nœud de boss.
- `GameScreen._handleCombatVictory` et `_resolveCombatProgression` : Analyse de l'identifiant du nœud pour en extraire l'index de position horizontale `nodeX` afin de déterminer la récompense (choix de cartes pour x = 0, double XP pour x = 1, relique améliorée pour x = 2).
- Tests unitaires et widget-tests validés à 100%.

### Conséquences
- ✅ **Rythme de jeu équilibré et tactique** : L'interdiction des suites infinies d'Élites ou l'absence de Repos évite les situations de défaite inévitable ("soft lock").
- ✅ **Variété tactique de fin de partie** : La présence de 3 boss distincts à l'étage 9 et leurs récompenses variées encouragent les joueurs à adapter leur itinéraire en fonction de leurs besoins (XP vs Cartes vs Reliques).
- ✅ **Robustesse algorithmique** : L'optimisation par solver garantit le respect des quotas sur toutes les cartes générées.
