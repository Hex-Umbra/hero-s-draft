## 🔒 ADR-055 : Immutabilité Stricte des Modèles d'État (v0.1.9)

### Statut
✅ Accepté & Implémenté (v0.1.9)

### Contexte
1. L'utilisation de Riverpod pour la gestion globale de l'état repose sur des données immuables. Si des listes ou des objets imbriqués dans l'état sont mutables, des modifications directes de données peuvent se produire de manière indésirable sans déclencher la mise à jour des widgets à l'écran, rompant le cycle de rendu Flutter/Riverpod.
2. Les modèles d'état `EntityStats`, `CombatState` et `EnemyInstance` contenaient des listes (comme `statuses` et `enemies`) qui pouvaient être altérées par référence directe.
3. Il était nécessaire de sécuriser ces modèles pour interdire les mutations directes et renforcer la conformité du code avec le paradigme immuable.

### Décision
1. **Annotation @immutable** : Ajouter l'import `package:meta/meta.dart` et annoter les classes `EntityStats`, `CombatState` et `EnemyInstance` avec `@immutable`.
2. **Encapsulation des listes** : Remplacer l'instanciation simple des listes internes par `List.unmodifiable(...)` dans le constructeur et lors de l'appel à la méthode `copyWith`. Toute altération directe lève désormais une exception.
3. **Mise à jour des constructeurs** : Convertir les constructeurs de `EntityStats` et `CombatState` pour qu'ils ne soient plus `const` puisque `List.unmodifiable` est exécuté à l'exécution.

### Preuves dans le code
- [entity_stats.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/entity_stats.dart) : Ajout de `@immutable` et `List.unmodifiable(statuses)`.
- [combat_state.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/combat_state.dart) : Ajout de `@immutable` et `List.unmodifiable` pour `enemies`, `pendingEnemies`, et `defeatedEnemies`.
- [enemy_instance.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/enemy_instance.dart) : Ajout de `@immutable`.

### Conséquences
- ✅ **Sécurisation du State Riverpod** : Plus aucune altération d'état non détectée ne peut se produire sur les entités de combat.
- ✅ **Respect Strict du Flux Unidirectionnel** : Les modifications se font uniquement via `copyWith` et les Notifiers associés.
- ✅ **Code Léger** : Aucune dépendance sur du code généré complexe (pas de `freezed` ni de build_runner requis pour le moment).
- ✅ **Zéro Régression** : Les 108 tests unitaires de non-régression s'exécutent avec succès.
