## 🔄 ADR-035 : Modernisation Architecturale Riverpod & Découplage (Riverpod Notifier & Architectural Cleanups)

### Statut
✅ Accepté & Implémenté

### Contexte
L'architecture originale du projet reposait sur l'ancienne version de Riverpod (v1.x) utilisant `StateNotifier` et `StateNotifierProvider`. Cette approche imposait des contraintes rigides : pour que les contrôleurs communiquent entre eux, ils devaient s'injecter mutuellement dans leurs constructeurs respectifs ou stocker des instances de `Ref` globales. Cela menait à des signatures de constructeurs complexes et volumineuses, et augmentait considérablement le risque de dépendances circulaires au démarrage de l'application.
De plus, certains modèles comme `CardInstance` contenaient des listes modifiables (comme `forgeUpgrades`), ce qui pouvait corrompre l'état de manière silencieuse lors de manipulations directes. Enfin, une partie de la logique métier de combat (le calcul et l'application des compétences héroïques, `executeSkill`) était historiquement couplée et codée en dur dans le moteur de rendu graphique Flame (`HerosDraftGame`), violant le principe de séparation des responsabilités.

### Décision
1. **Migration vers Notifier et NotifierProvider** :
   - Abandonner complètement le pattern obsolète `StateNotifier` au profit de la classe moderne `Notifier` de Riverpod 2.x pour tous les contrôleurs métier (`RunController`, `CombatController`, `DeckNotifier`, `InventoryController`, `SkillController`, `EventController`, `ShopController`, `RewardController`).
   - Mettre à jour tous les providers associés vers `NotifierProvider`.
2. **Découplage Interne via `ref` et `ref.read`** :
   - Supprimer tous les paramètres de constructeur ou les injections directes de dépendances dans les constructeurs des contrôleurs.
   - Les contrôleurs héritent de `Notifier`, ce qui leur donne accès de manière native et sécurisée à la propriété `ref`.
   - Utiliser exclusivement `ref.read` en interne pour récupérer les instances des autres contrôleurs au moment de l'exécution (par exemple, `ref.read(runProvider.notifier)`).
3. **Immuabilité Stricte de `CardInstance`** :
   - Rendre tous les attributs de `CardInstance` finaux.
   - Forcer le gel de la liste des améliorations de la forge `forgeUpgrades` en la convertissant systématiquement en une liste non modifiable (`List<String>.unmodifiable`) lors de l'instanciation.
   - Remplacer toute altération par des appels à `copyWith` retournant de nouvelles instances.
4. **Découplage de la Logique de Compétence Flame** :
   - Extraire la logique métier de calcul des compétences (`executeSkill` qui calcule les dégâts, le vol d'armure, etc.) de la classe Flame `HerosDraftGame`.
   - L'intégrer proprement dans `CombatController` sous forme de méthode `executeSkill(SkillData skill, double healthPercent, RunController runCtrl)`.
   - Maintenir Flame comme un simple moteur de rendu réactif observant les changements d'état sans héberger de calculs de règles de combat.

### Preuves dans le code
- `lib/game/controllers/combat_controller.dart` : Héritage de `Notifier<CombatState>`, accès direct à `runProvider` et `deckProvider` via `ref.read`, et implémentation de la méthode métier `executeSkill`.
- `lib/game/controllers/run_controller.dart` : Héritage de `Notifier<RunState>` sans constructeur surchargé.
- `lib/game/controllers/deck_controller.dart` : Héritage de `Notifier<DeckState>` et manipulation de `CardInstance` en mode immuable.
- `lib/models/card_instance.dart` : Initialisation de `forgeUpgrades` avec `List<String>.unmodifiable`.
- `lib/game/heros_draft_game.dart` : Nettoyage des calculs métiers de compétences, Flame délègue l'exécution à `ref.read(combatProvider.notifier).executeSkill(...)`.

### Conséquences
- ✅ **Éradication des Dépendances Circulaires** : Les contrôleurs ne s'injectent plus dans les constructeurs, résolvant définitivement les bugs de cycles de dépendances.
- ✅ **Clean Code & SRP** : Flame ne contient plus de logique métier de combat, respectant une séparation stricte entre rendu visuel et logique applicative.
- ✅ **Prévisibilité de l'État** : L'immuabilité stricte de `CardInstance` élimine les risques d'effets de bord où une carte partagée est modifiée par mégarde en cours de combat.
- ✅ **Robustesse et Fiabilité** : Les 104 tests automatisés passent toujours avec succès, prouvant qu'aucune régression fonctionnelle n'a été introduite par ce refactoring majeur.
