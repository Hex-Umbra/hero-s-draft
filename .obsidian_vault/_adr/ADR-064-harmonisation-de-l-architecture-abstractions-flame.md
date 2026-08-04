## 🛠️ ADR-064 : Harmonisation de l'Architecture — Abstractions Flame, Riverpodisation du Registry et Simplification du Modèle de Carte (v0.2.4)

### Statut
✅ Accepté & Implémenté (v0.2.4)

### Contexte
Suite à l'audit du refactoring de la dette technique globale, quatre axes d'amélioration ont été identifiés pour parfaire l'extensibilité et la robustesse de la base de code :
1. `ClassSelectionScreen` n'utilisait pas encore l'infrastructure de Scaffold unifiée, provoquant des duplications visuelles d'AppBar et de décors.
2. Le code d'update et de détection graphique de changement de statistiques était en partie dupliqué entre `HeroCard` et `EnemyCard`, n'exploitant pas pleinement la classe parente `CombatEntity`.
3. Le registre d'effets `EffectRegistry` comportait un état statique global mutable non conforme aux concepts de Riverpod, et des callbacks orphelins inutilisés existaient encore dans `HerosDraftGame`.
4. L'extraction de l'étage actuel d'un nœud de carte (`MapNode`) reposait sur des opérations de split de chaînes sur son ID (`id.split('_')[1]`), ce qui était fragile et sujet aux régressions.

### Décision
1. **Harmonisation UI de la Sélection de Classe** : Migrer `ClassSelectionScreen` pour s'appuyer sur `ScreenScaffold` (fond dégradé sombre) et `PageHeader` (sans bouton retour car écran d'accueil de sélection), éliminant l'AppBar et le Scaffold dupliqués.
2. **Centralisation dans CombatEntity (Flame)** : Remonter la méthode de détection des changements de statistiques `triggerHitReactions` et d'instanciation des popups `spawnFloatingText` dans la classe commune `CombatEntity`. `HeroCard` et `EnemyCard` redéfinissent `updateStats` en appelant la méthode héritée, éliminant toute duplication de logique visuelle.
3. **Riverpodisation d'EffectRegistry & Nettoyage** : Rendre la classe `EffectRegistry` non-statique et l'exposer via `effectRegistryProvider` (créé sous `lib/game/services/effects/effect_strategy.dart`). Transmettre l'instance du registre en paramètre à `EffectResolver.resolveCard` et l'injecter via `ref.read` dans `CombatController`. Nettoyer les constructeurs et instanciations de `HerosDraftGame` et `GameScreen` de tous les callbacks obsolètes d'armure, dégâts et soins.
4. **Attribut floor Explicite sur MapNode** : Ajouter un champ `floor` de type `int` à `MapNode`. Configurer son constructeur `fromJson` pour qu'il extrait le floor avec `json['floor'] ?? int.parse(id.split('_')[1])` (rétrocompatibilité). Remplacer les expressions `id.split('_')[1]` par un appel direct à `node.floor` dans l'ensemble de la base de code.

### Preuves dans le code
- [class_selection_screen.dart](../../lib/ui/screens/class_selection_screen.dart) : Migration sous `ScreenScaffold` et `PageHeader`.
- [combat_entity.dart](../../lib/game/components/entities/combat_entity.dart) : Centralisation d' `updateStats` via `triggerHitReactions`.
- [hero_card.dart](../../lib/game/components/entities/hero_card.dart) & [enemy_card.dart](../../lib/game/components/entities/enemy_card.dart) : Appels d'update délégués à `triggerHitReactions`.
- [effect_strategy.dart](../../lib/game/services/effects/effect_strategy.dart) : Fournit `effectRegistryProvider`.
- [effect_resolver.dart](../../lib/game/services/effect_resolver.dart) & [combat_controller.dart](../../lib/game/controllers/combat_controller.dart) : Utilisation du provider et transmission du registre.
- [map_node.dart](../../lib/models/map_node.dart) : Ajout de l'attribut `floor` et logique de fallback `fromJson`.
- [map_node_generator.dart](../../lib/services/map/map_node_generator.dart), [map_content_placer.dart](../../lib/services/map/map_content_placer.dart), [map_validator.dart](../../lib/services/map/map_validator.dart), [map_screen.dart](../../lib/ui/screens/map_screen.dart) : Remplacement du split par l'appel direct à `node.floor`.

### Conséquences
- ✅ **Code Propre (DRY & SRP)** : Plus de 100 lignes dupliquées de logique d'impact et de transition visuelle ont été éliminées de `HeroCard` et `EnemyCard`.
- ✅ **Sécurité et Robustesse** : Le typage fort de `floor` remplace les splits de chaînes, réduisant les risques d'exceptions de parsing lors des manipulations géométriques de la carte.
- ✅ **Conformité Riverpod** : L'état statique global mutable de la classe stratégie est éliminé. Le cycle de vie des registries est géré de manière propre et déclarative par le conteneur Riverpod.
- ✅ **Qualité Garantie** : 0 erreur `dart analyze` et passage des 108 tests unitaires.
