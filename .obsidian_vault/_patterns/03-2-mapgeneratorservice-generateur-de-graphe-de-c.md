### 3.2. `MapGeneratorService` — Générateur de Graphe de Carte du Monde (DAG World Map)

**Type** : Service statique utilitaire (`lib/services/map_generator_service.dart`).

**Responsabilités** :
1. **Génération de la topologie en DAG** (`generateMap`) :
   - Génère un graphe acyclique dirigé de 10 étages (`floors = 10`), avec une largeur fluctuant de 2 à 5 nœuds (`maxWidth = 5`).
   - Câble séquentiellement les connexions de l'étage `y` vers l'étage `y+1` avec des offsets indexés de $-1$, $0$, $+1$.
   - **Passe de correction d'orphelins** : Parcourt tous les nœuds de l'étage suivant et connecte de force une source s'ils ne sont pas ciblés.
2. **Contraintes structurelles forcées** :
   - Étage 0 : Forced to standard combat.
   - Étage du milieu (`middleFloor = floors ~/ 2`) : Forced to exactly 1 node (chokepoint) of type Élite, enabling dynamic map sizing support.
   - Étage `floors-2` (repos garanti) : All nodes are forced to type Repos (Rest).
   - Étage `floors-1` (Boss) : Generates exactly 3 boss nodes depending on the final act requirements.
   - **Forge de Fusion** : `MapContentPlacer` place un nœud `MapNodeType.forgeFusion` avec 25% de probabilité par carte/map, choisi de façon aléatoire sur un étage intermédiaire entre les étages 3 et 7.
3. **Solver de Quotas (`_balanceQuotas`)** :
   - Itère sur les nœuds de la carte pour réallouer les types de nœuds afin de respecter les limites globales configurées dans `GameConstants.nodeQuotas` (Combat: 12-22, Elite: 3-6, Rest: 3-6, Shop: 2-5, Event: 4-9).
4. **Algorithme Anti-Répétition de Chemin (`_hasThreeConsecutive` / `_getChainOfThree`)** :
   - Parcourt récursivement tous les chemins valides menant de l'étage d'entrée (0) aux boss (étage 9).
   - Détecte toute chaîne de 3 nœuds consécutifs du type Élite ou Repos.
   - Corrige les violations en convertissant le 3ème nœud de la suite en Combat, Shop ou Event, et répète la validation jusqu'à ce que plus aucun chemin ne contrevienne à la règle.
