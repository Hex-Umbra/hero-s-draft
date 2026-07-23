# World Map System - Documentation Technique

Cette documentation décrit le fonctionnement actuel du système de "World Map" (carte du monde) dans le jeu "Hero's Draft". Le système gère la progression du joueur à travers une série de rencontres générées procéduralement.

## 1. Modèles de Données (`lib/models/map_node.dart`)

Le système repose sur la classe `MapNode` qui représente un point d'arrêt sur la carte.

### Types de Nœuds (`MapNodeType`)
Chaque nœud a un type spécifique qui détermine l'action qui s'y déroulera :
- `combat` : Rencontre standard contre des ennemis.
- `elite` : Rencontre plus difficile offrant de meilleures récompenses.
- `shop` : Boutique pour dépenser de l'or (achat de cartes, services).
- `rest` : Zone de repos (généralement pour soigner ou améliorer des cartes).
- `event` : Événement narratif ou aléatoire.
- `boss` : Rencontre finale d'un acte.

### Propriétés de `MapNode`
- `id` : Identifiant unique du nœud (format typique : `node_{floor}_{index}`).
- `type` : Le type du nœud (énumération `MapNodeType`).
- `connections` : Liste d'identifiants (`String`) des nœuds accessibles depuis celui-ci.
- `position` : Les coordonnées (`Vector2` de Flame) pour le placement visuel sur l'écran.
- `isCompleted` : Un booléen indiquant si le joueur a déjà terminé ce nœud.

Le modèle inclut des méthodes `toJson` et `fromJson` pour une potentielle sérialisation/sauvegarde de la partie.

## 2. Génération Procédurale (`lib/services/map_generator_service.dart`)

La carte est générée par la classe `MapGeneratorService` qui crée un **Graphe Acyclique Dirigé (DAG)**.

### Algorithme de Génération (`generateMap`)
1. **Création des étages (Floors) :**
   - Par défaut, la carte fait 10 étages (`floors = 10`).
   - La largeur de chaque étage est aléatoire, entre 2 et 5 nœuds (`maxWidth = 5`), sauf pour le dernier étage (étage du Boss) qui n'a toujours qu'un seul nœud.
   - Les nœuds sont répartis horizontalement et verticalement (génération de bas en haut).

2. **Attribution des types :**
   - Le premier étage (floor 0) est toujours un nœud de type `combat`.
   - Le dernier étage est toujours un nœud de type `boss`.
   - Pour les autres étages, la distribution est aléatoire avec les probabilités suivantes :
     - 60% Combat
     - 15% Événement
     - 10% Boutique (Shop)
     - 10% Repos (Rest)
     - 5% Élite

3. **Création des connexions :**
   - L'algorithme connecte l'étage N à l'étage N+1.
   - Chaque nœud de l'étage actuel se connecte à 1 ou 2 nœuds de l'étage suivant.
   - Pour éviter les croisements extrêmes ou les longues lignes obliques, un nœud se connecte principalement aux nœuds situés directement au-dessus de lui ou adjacents (offset de -1, 0, ou 1).
   - Une passe de vérification finale s'assure qu'aucun nœud de l'étage suivant n'est "orphelin" (inaccessible). Si c'est le cas, il est connecté au nœud le plus proche de l'étage précédent.

## 3. Gestion de l'État (`lib/game/controllers/run_controller.dart`)

La progression sur la carte est gérée par le `RunController` (via Riverpod).

### État de la Carte (`RunState`)
- `mapNodes` : La liste complète de tous les `MapNode` générés pour l'acte en cours.
- `currentNodeId` : L'identifiant du nœud sur lequel le joueur se trouve actuellement (ou null s'il n'a pas encore commencé l'acte).
- `act` : Le numéro de l'acte en cours.

### Actions de Navigation
- `startNewRun()` : Déclenche la génération d'une nouvelle carte via `MapGeneratorService` et réinitialise l'état du joueur.
- `travelToNode(String nodeId)` : Met à jour `currentNodeId` pour déplacer le joueur sur le nœud sélectionné.
- `completeCurrentNode()` : Passe le booléen `isCompleted` du nœud actuel à `true`. Si le nœud complété est un `boss`, déclenche le passage à l'acte suivant.
- `advanceToNextWorld()` : Incrémente le compteur d'actes, génère une nouvelle carte, et réinitialise la position (`currentNodeId` à null).

## 4. Interface Utilisateur (`lib/ui/screens/map_screen.dart`)

La carte est affichée dans un écran Flutter dédié.

### Navigation et Rendu Visuel
- **InteractiveViewer :** Utilisé pour permettre le déplacement (pan) sur la carte. Le zoom est actuellement désactivé (`scaleEnabled: false`) avec un `scale` fixe à 0.8.
- **Centrage Automatique :** Le code (dans `WidgetsBinding.instance.addPostFrameCallback`) centre automatiquement la caméra sur le nœud actuel du joueur, ou sur le milieu du premier étage au début d'un acte.
- **CustomPainter (`MapConnectionPainter`) :** Dessine des lignes semi-transparentes pour relier les nœuds en fonction de leurs `connections`.
- **Positioned Widgets (`_MapNodeWidget`) :** Chaque nœud est affiché à ses coordonnées `(position.x, position.y)`.
  - Des icônes et des couleurs spécifiques représentent chaque type de nœud (ex: Jaune pour la boutique, Rouge pour l'élite).
  - Un nœud actuel ou complété a un aspect visuel distinct (opacité, surbrillance, icône de validation).

### Logique de Disponibilité (`_isNodeAvailable`)
Un nœud n'est cliquable ("disponible") que si :
- Le joueur n'a pas encore commencé (auquel cas seuls les nœuds du premier étage `node_0_x` sont cliquables).
- OU le nœud fait partie de la liste `connections` du nœud actuellement occupé par le joueur (`currentNodeId`).

### Routage
Lorsqu'un joueur clique sur un nœud disponible, `_onNodeTap` est appelé :
1. Le `RunController` met à jour la position (`travelToNode`).
2. Flutter navigue vers l'écran approprié en fonction du type de nœud :
   - `combat`, `elite`, `boss`, `rest`, `event` -> `GameScreen`
   - `shop` -> `ShopScreen`
