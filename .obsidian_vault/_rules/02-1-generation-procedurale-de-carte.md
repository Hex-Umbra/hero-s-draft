### 2.1. Génération Procédurale de Carte (`MapGeneratorService`)

Le service statique `MapGeneratorService.generateMap({floors = 10, maxWidth = 5})` orchestre la génération d'un **Graphe Acyclique Dirigé (DAG)** en déléguant ses étapes à 4 sous-services spécifiques situés sous `lib/services/map/` :
- **`MapNodeGenerator`** (Phase 1) : Instancie les nœuds et définit leurs types par défaut selon l'étage.
- **`MapConnectionBuilder`** (Phase 2) : Établit les liaisons (Directed Acyclic Graph) entre les étages successifs.
- **`MapValidator`** (Phase 3) : Valide et ajuste les quotas minimum/maximum de nœuds par type, et applique la règle anti-répétition de chemin (maximum 2 nœuds Repos ou Élite consécutifs).
- **`MapContentPlacer`** (Phase 4) : Gère le placement conditionnel d'événements ou de nœuds spéciaux (comme l'échange de reliques ou la **Forge de Fusion**).

**Phase 1 — Création des nœuds** :
- Itère de l'étage 0 à `floors-1` (0 à 9).
- Chaque étage a 2 à `maxWidth` nœuds (aléatoire), sauf cas spéciaux.
- Positionnement : X réparti sur 1000px de largeur, Y = `(floors - 1 - y) * 200` (bottom-to-top).

**Règles spéciales par étage** :
| Étage | Contrainte |
|:---|:---|
| 0 | 100% Combat (entrée obligatoire) |
| `floors ~/ 2` (ex: 5) | **Chokepoint** : exactement 1 nœud de type `elite` (étage central dynamique) |
| 8 (`floors-2`) | 100% `rest` (tous les nœuds de l'étage 8 sont de type repos) |
| 9 (`floors-1`) | 3 nœuds de type `boss` distincts (permettant un choix de Boss par récompense selon la position x) |

**Distribution probabiliste initiale** (pour les étages 1-4, 6-7) :
| Type de Nœud | Probabilité |
|:---|:---|
| Combat standard | 60% |
| Événement narratif | 15% |
| Boutique (Shop) | 10% |
| Repos (Campfire/Rest) | 10% |
| Combat Élite | 5% |

**Phase 2 — Câblage des connexions (DAG)** :
- Pour chaque nœud de l'étage `y`, calcule un index de base proportionnel dans l'étage `y+1`.
- Connecte à 1 ou 2 nœuds (offset -1, 0, ou +1 par rapport à la base).
- **Garantie d'accessibilité** : Vérifie que chaque nœud de `nextFloor` est ciblé par au moins un nœud de `currentFloor`. Sinon, connecte la source proportionnellement la plus proche.

**Phase 3 — Optimisations et Contraintes Algorithmiques** :
- **Solver de Quotas de Nœuds** (`_balanceQuotas`) : Ajuste itérativement les types de nœuds générés pour respecter les quotas globaux de la carte :
  - Combat : 12 à 22 nœuds
  - Élite : 3 à 6 nœuds
  - Repos : 3 à 6 nœuds
  - Boutique (Shop) : 2 à 5 nœuds
  - Événement (Event) : 4 à 9 nœuds
- **Algorithme Anti-Répétition de Chemin** (`_hasThreeConsecutive`) : Parcourt tous les chemins du graphe de l'entrée aux boss. Garantit qu'aucun chemin ne comporte 3 nœuds consécutifs du type Élite ou du type Repos. Si une violation est détectée, le troisième nœud est converti en un type alternatif (Combat, Boutique ou Événement).

**Mécanique de Récompenses Spécifiques des Boss (Étage 9) selon la position** :
- **Position gauche (x = 0)** : Permet au joueur de sélectionner 5 cartes aléatoires de son propre deck actuel et d'en choisir 2 pour les cloner (icône Cartes).
- **Position centrale (x = 1)** : Triple (x3) l'or et l'expérience globale (XP) accumulés lors de la victoire, et octroie en plus au joueur une carte aléatoire tirée du jeu entier (excluant les cartes uniques de classe et les cartes de statut) (icône Magie/XP).
- **Position droite (x = 2)** : Garantit l'obtention d'une relique de rareté supérieure (minimum Uncommon, excluant totalement les communes, icône Diamant). Les chances de rareté sont : Legendary 15%, Epic 30%, Rare 35%, Uncommon 20%.

**Génération du nœud de la Forge de Fusion (`MapNodeType.forgeFusion`)** :
- Le nœud spécial `forgeFusion` (icône de fente de fusion `Icons.layers_rounded` violette/fuchsia) a une **probabilité d'apparition de 25% par carte/map**.
- S'il est généré, il est placé de manière aléatoire sur un étage intermédiaire entre les **étages 3 et 7**, en écrasant un nœud éligible. Cela évite qu'il n'interfère avec les premiers étages d'apprentissage (0 à 2), le nœud de repos obligatoire (étage 8) et les boss (étage 9).
- Il est explicitement répertorié dans la légende de la carte (`MapLegend`) sous l'icône `Icons.layers_rounded` fuchsia.

**Modèle `MapNode`** : `id` (ex: "node_0_0"), `type` (MapNodeType), `connections` (List\<String\>), `position` (Vector2 Flame), `isCompleted` (bool mutable).
