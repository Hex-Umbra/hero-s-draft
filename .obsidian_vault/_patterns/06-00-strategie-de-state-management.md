## 6. Stratégie de State Management (Riverpod v2.5.1)

### 6.1. Inventaire Complet des Providers

| Provider | Type | État | Auto-Dispose | Rôle |
|:---|:---|:---|:---|:---|
| `runProvider` | `NotifierProvider<RunController, RunState>` | `RunState` | Non | Progression globale, stats héros, carte, reliques |
| `deckProvider` | `NotifierProvider<DeckNotifier, DeckState>` | `DeckState` | Non | 5 piles de cartes, merge, upgrade |
| `combatProvider` | `NotifierProvider<CombatController, CombatState>` | `CombatState` | Non | Combat actif, ennemis, phases, intentions |
| `inventoryProvider` | `NotifierProvider<InventoryController, InventoryState>` | `InventoryState` | Non | Or, reliques, bonus boutique |
| `skillProvider` | `NotifierProvider<SkillController, SkillState>` | `SkillState` | Non | Cooldowns des 2 compétences héroïques |
| `eventProvider` | `NotifierProvider<EventController, EventState>` | `EventState` | Non | Événement narratif actif, choix sélectionné |
| `shopProvider` | `NotifierProvider<ShopController, ShopState>` | `ShopState` | Non | Cartes en vente, état d'achat heal |
| `rewardProvider` | `NotifierProvider<RewardController, RewardState>` | `RewardState` | Non | Butins post-combat (or, XP, reliques, cartes) |
| `effectRegistryProvider` | `Provider<EffectRegistry>` | `EffectRegistry` | Non | Registre d'effets Riverpodisé instanciant les 6 stratégies concrètes d'effets |
| `gameDataLoaderProvider` | `FutureProvider<GameDataRegistry>` | `GameDataRegistry` | Non | Chargement asynchrone de 9 JSON d'assets (`patch_notes.json`, 10ᵉ fichier de `assets/data/`, est chargé séparément) |

### 6.2. Principes Appliqués

1. **Immuabilité d'état** : Tous les contrôleurs `Notifier` émettent de nouveaux objets d'état via `state = state.copyWith(...)`. Les listes et collections internes sont recréées à chaque modification (pas de mutation directe in-place) afin de garantir la réactivité de Riverpod et d'éviter les bugs de cache d'état.
2. **Découplage Interne et ref.read** : Au lieu d'injecter des dépendances via des paramètres de constructeur, les contrôleurs accèdent les uns aux autres à l'aide de `ref.read` en interne (par exemple, `ref.read(runProvider.notifier)` au sein de `CombatController`). Cela résout les problèmes de dépendances circulaires lors de l'initialisation des providers et allège considérablement la signature des contrôleurs.
3. **Immuabilité Stricte de `CardInstance`** : Les instances de cartes sont garanties 100% immuables. Tous les attributs sont marqués `final`. Les listes d'améliorations de la forge (`forgeUpgrades`) sont converties en listes non modifiables (`List<String>.unmodifiable`) lors de l'instanciation de `CardInstance`. Toute mutation donne obligatoirement lieu à une nouvelle carte via l'appel à `copyWith`.
4. **Pas de logique dans les vues** : Les widgets et écrans UI observent l'état via `ref.watch(provider)` pour reconstruire l'interface de manière réactive, et délèguent toutes les actions logiques en invoquant les méthodes des contrôleurs via `ref.read(provider.notifier).method()`.
5. **Providers persistants** : Tous les providers de run et de combat sont configurés sans `autoDispose` pour maintenir l'état du jeu à travers les transitions d'écrans du cycle de vie de l'application.
6. **Riverpodisation de l'EffectRegistry** : Pour supprimer l'état statique global mutable d'`EffectRegistry`, celui-ci est désormais instancié de manière immutable et exposé par le provider `effectRegistryProvider`. Ce registre de stratégies concrètes d'effets est dynamiquement passé à `EffectResolver.resolveCard` à chaque exécution de carte.
7. **Suppression des Callbacks Obsolètes** : Les callbacks orphelins de `HerosDraftGame` (`onPlayerTakeDamage`, `onPlayerHeal`, `onPlayerGainArmor`) ont été entièrement nettoyés de l'instanciation de `HerosDraftGame` dans `GameScreen` pour respecter les principes de découplage de Riverpod.


### 6.3. Sérialisation

| Modèle | `fromJson`/`toJson` | Statut |
|:---|:---|:---|
| `CombatState`, `EnemyInstance`, `EnemyIntent`, `EntityStats`, `StatusEffect`, `MapNode` | ✅ Oui | Round-trip complet |
| `CardInstance`, `EventState`, `InventoryState`, `ShopState`, `SkillState` | ❌ Non | Runtime uniquement |
