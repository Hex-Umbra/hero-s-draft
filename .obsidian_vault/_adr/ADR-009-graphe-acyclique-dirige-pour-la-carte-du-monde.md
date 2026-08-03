## 🗺️ ADR-009 : Graphe Acyclique Dirigé pour la Carte du Monde

### Statut
✅ Accepté & Implémenté

### Contexte
Les roguelikes deckbuilders utilisent typiquement une carte procédurale permettant des choix de parcours. Le design doit offrir de la variété tout en garantissant l'accessibilité de tous les nœuds.

### Décision
- Générer un **DAG** de 10 étages via `MapGeneratorService.generateMap()`.
- Largeur variable de 2 à 5 nœuds par étage, avec des règles spéciales (chokepoint à l'étage 5, repos garanti avant boss, boss unique au dernier étage).
- Connexions par offset (-1, 0, +1) depuis un index proportionnel, avec passe de correction d'orphelins.
- Le modèle `MapNode` utilise `Vector2` de Flame pour le positionnement.

### Preuves dans le code
- `MapGeneratorService` : ~120 lignes de logique de génération.
- `MapNode` : utilise `Vector2` (import Flame).
- `RunController.startNewRun()` : appelle `MapGeneratorService.generateMap()`.

### Conséquences
- ✅ Rejouabilité élevée (variété de parcours).
- ✅ Garantie d'accessibilité (passe orphelins).
- ⚠️ **Couplage modèle/rendu** : `MapNode` importe `Vector2` de Flame — le modèle de données dépend du moteur de rendu.
