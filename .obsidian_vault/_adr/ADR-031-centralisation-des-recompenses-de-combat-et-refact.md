## 🪙 ADR-031 : Centralisation des Récompenses de Combat et Refactoring du Gain d'Or (Combat Reward Centralization & Gold Drops)

### Statut
✅ Accepté & Implémenté

### Contexte
Auparavant, le calcul et l'attribution des récompenses post-combat (XP, or, reliques et tirages de cartes) étaient intégrés directement au sein des classes de l'interface utilisateur (`GameScreen` et `DraftScreen`). Cette structure violait le principe de séparation des responsabilités, rendant l'interface lourde, difficile à tester et sujette aux régressions. De plus, les drops d'or des ennemis étaient calculés de manière aléatoire et codés en dur lors du draft de fin de combat, et le type de récompense de Boss à l'étage 9 était résolu par une analyse textuelle de l'identifiant du nœud (`id.endsWith('_0')`), ce qui était fragile et limitait l'évolutivité.

### Décision
1. **Ajout et Scaling du Butin d'Or des Ennemis** :
   - Ajouter la propriété `gold` au modèle `EnemyData` (avec une valeur par défaut de 10) et au modèle runtime `EnemyInstance`.
   - Définir l'or de base spécifique à chaque monstre dans `enemies.json` (slime: 10, gobelin: 12, squelette: 15, orc furieux: 25).
   - Mettre à l'échelle l'or gagné lors de la victoire en utilisant la même formule progressive que pour l'XP : `(baseGold * levelMultiplier).round()` où `levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1)`.
2. **Typage Fort des Récompenses de Boss** :
   - Introduire l'énumération `BossRewardType { cards, doubleXp, improvedRelic }` pour modéliser proprement les récompenses uniques de fin d'acte.
   - Ajouter le champ optionnel `bossRewardType` au modèle de données `MapNode` avec support complet de sa sérialisation/désérialisation JSON.
   - Lors de la génération procédurale dans `MapGeneratorService`, assigner explicitement `bossRewardType` aux nœuds de l'étage final (étage 9) en se basant sur leur position horizontale `x` (0: `cards`, 1: `doubleXp`, 2: `improvedRelic`).
3. **Création du Contrôleur de Récompenses (`RewardController`)** :
   - Introduire `RewardController` (`rewardProvider`), un `StateNotifier` centralisant l'état d'attribution post-combat (`RewardState`).
   - Gérer de manière isolée le calcul unifié des gains (XP doublée pour `doubleXp`, or scalé, et jets de relique de rareté supérieure pour `improvedRelic` excluant les reliques communes).
   - Encapsuler les méthodes de validation de collecte et d'omission : `collectGoldAndXp()`, `collectRelic()`, `skipRelic()`, `chooseCards()`, `skipCards()`.
   - Maintenir le drapeau d'état global `isResolved` pour coordonner la fin de la séquence de victoire.
4. **Découplage et Nettoyage de l'UI** :
   - Modifier `MapNodeWidget` pour lire directement le type fortement typé `node.bossRewardType` à la place du parsing de chaîne de coordonnées.
   - Refactoriser `GameScreen` pour déléguer les calculs et le séquençage visuel des récompenses (relique, draft de cartes, montées de niveau et transition de retour) au `rewardProvider`.
   - Supprimer le gain d'or aléatoire codé en dur qui persistait dans `DraftScreen._finishDraft`.

### Preuves dans le code
- `lib/models/data/enemy_data.dart` et `lib/models/map_node.dart` : ajout des attributs et mise à jour de `fromJson`/`toJson`.
- `assets/data/enemies.json` : définition de la propriété `"gold"` pour chaque ennemi.
- `lib/services/map_generator_service.dart` : attribution de `bossRewardType` lors de la construction de la carte.
- `lib/game/controllers/reward_controller.dart` : implémentation complète du contrôleur et de son état immuable.
- `lib/ui/widgets/map/map_node_widget.dart`, `lib/ui/screens/game_screen.dart` et `lib/ui/screens/draft_screen.dart` : intégration des flux de récompenses par delegation au provider.
- Validation statique vierge sous `dart analyze` et passage des 100 tests unitaires et widget-tests de la suite de tests.

### Conséquences
- ✅ **Séparation Métier / Rendu nette** : La logique de récompenses n'encombre plus les vues UI, ce qui facilite grandement la maintenance.
- ✅ **Robustesse et Évolutivité** : Remplacement des parsing fragiles par des types et propriétés forts. L'ajout de nouvelles récompenses de carte ou d'événements s'en trouve simplifié.
- ✅ **Testabilité Accrue** : Possibilité de tester la validité des calculs de butins, de drops d'or et de tirages de reliques par de simples tests unitaires Riverpod sans monter d'arbre de widgets.
- ✅ **Économie de Combat Cohérente** : Les gains d'or sont désormais directement proportionnels au niveau et à la difficulté des ennemis vaincus, évitant les anomalies de progression.
