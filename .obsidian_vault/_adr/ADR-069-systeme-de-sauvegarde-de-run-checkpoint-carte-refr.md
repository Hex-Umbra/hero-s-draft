## 💾 ADR-069 : Système de Sauvegarde de Run — Checkpoint Carte, `RefReader`, et Dégradation Gracieuse du Contenu Manquant (v3.2.0)

### Statut
✅ Accepté, Implémenté & **Mergé vers `main`** (v3.2.0, branche `feat/save_run`, PR #19, 13+ commits) — **résout ADR-011**.

### Contexte
`RunState`, `DeckState`, `InventoryState` et `SkillState` ne vivaient qu'en mémoire dans les `Notifier` Riverpod (cf. ADR-011). Fermer l'application, la mettre en arrière-plan ou un crash entraînait la perte totale d'une run pouvant durer 30 à 60+ minutes sur ~10 étages. Le point d'extension existait déjà mais était un stub vide (`RunPersistenceManager`), et `shared_preferences` était déjà une dépendance du projet (utilisée par `TutorialProgressService`).

Spec approuvée : `docs/superpowers/specs/2026-07-23-save-system-design.md`. Plan d'implémentation (10 tâches TDD) : `docs/superpowers/plans/2026-07-24-save-system.md`. Ledger d'exécution : `.superpowers/sdd/progress.md`.

### Décision
1. **Granularité Checkpoint Carte, jamais mid-combat** : L'autosave ne se déclenche qu'au retour sur `MapScreen` après résolution d'un nœud (combat, boutique, repos, event, forge fusion, échange de reliques, draft de Level Up différé). `CombatState` et l'état de tour en cours ne sont **jamais** sérialisés — un combat interrompu est simplement rejoué depuis le dernier checkpoint. Un seul slot de sauvegarde existe (cohérent avec l'architecture mono-`RunController`).
2. **Point de câblage unique via 2 méthodes de manager plutôt que 7 écrans** (déviation documentée par rapport au libellé littéral de la spec, intention préservée) : au lieu d'insérer `checkpointProvider.notifier.bump()` dans les 7 écrans de résolution de nœud listés par la spec, l'implémentation a découvert que les 6 écrans de nœud classiques (Shop/Rest/Event/ForgeFusion/RelicExchange/victoire combat) convergent déjà tous vers `MapProgressionManager.completeCurrentNode()`, et le 7ᵉ cas (Level Up) vers `PlayerStatsManager.decrementPendingDrafts()`. Le `bump()` est câblé dans ces 2 méthodes de manager uniquement — plus DRY et impossible à oublier pour un futur écran réutilisant ces méthodes.
3. **Clear de sauvegarde limité à la mort** (2ᵉ déviation documentée) : la spec mentionnait « victoire finale (retour au menu) ou mort du héros », mais le code ne possède aucun état de « victoire finale » — les actes s'enchaînent indéfiniment (`MapProgressionManager.advanceToNextWorld()`). Seule la mort (`RunState.isDead` → `GameOverScreen`) déclenche `SaveService.clear()`.
4. **Dégradation gracieuse du contenu manquant** : Pour chaque carte/relique/upgrade de forge/passif référencé par ID, un instantané bilingue du nom (`nameFr`/`nameEn`) est stocké à côté de l'ID au moment du `save()`. Si l'ID ne se résout plus au chargement (contenu retiré par une mise à jour), l'entrée est retirée silencieusement de l'état réhydraté et ajoutée à `SaveLoadResult.missingItems` (type `MissingSaveItem`), affiché au joueur dans une boîte de dialogue nommant précisément ce qui a été perdu — le reste de la run reste jouable.
5. **Sauvegarde structurellement corrompue = échec total, sans récupération partielle** : un JSON illisible ou un `schemaVersion` inconnu/futur fait échouer `SaveService.load()`, efface la clé via `clear()`, et `HomeScreen` se comporte comme si aucune sauvegarde n'existait. Un état partiellement désynchronisé entre sous-états a été jugé pire qu'une perte de run proprement signalée par son absence.
6. **Re-résolution systématique du contenu par ID depuis `GameDataRegistry`** : le contenu catalogué (`CardData`, `RelicData`, `PassiveData`, `ForgeUpgradeData`) n'est jamais désérialisé directement depuis le blob de sauvegarde — seul l'ID est repris, et la donnée fraîche du registre est re-résolue à chaque chargement. Conséquence voulue : un rééquilibrage de carte publié après la sauvegarde s'applique automatiquement à la reprise.

### Corrections Techniques Survenues en Cours d'Implémentation
- **Incompatibilité de typage `Ref`/`WidgetRef` (Riverpod 2.6.1)** : le plan initial typait `SaveService.save`/`load` comme acceptant un `Ref`, qui ne compile pas partout — `Ref` et `WidgetRef` ne partagent aucun supertype commun, et `ProviderContainer` n'implémente ni l'un ni l'autre. Après vérification du source de `riverpod`/`flutter_riverpod` 2.6.1, les trois exposent la même signature générique `T Function<T>(ProviderListenable<T>)`. Un typedef `RefReader` a été introduit ; tous les appelants passent désormais un tear-off `.read` (`ref.read`, `container.read`), jamais l'objet `ref` lui-même. Cela permet à `SaveService` de fonctionner identiquement depuis un `Notifier` (`Ref`), un widget (`WidgetRef`), et un test (`ProviderContainer`).
- **Bug de garde `SaveLoadResult.success` intercepté avant écriture de code** : lors de l'auto-revue du plan (Tâche 7), une incohérence dans la logique de garde du résultat de chargement a été détectée et corrigée directement dans le plan, avant qu'aucun code ne soit écrit — évitant un bug qui aurait autrement nécessité un cycle de correction post-implémentation.
- **Suppression de code mort (`RunPersistenceManager`)** : la revue finale de branche a détecté que `RunPersistenceManager` (le stub existant, cf. ADR-011) avait été re-câblé en Tâche 8 mais n'était en réalité jamais appelé nulle part — `SaveService` étant invoqué directement partout. Le fichier et son instanciation dans `run_controller.dart` ont été supprimés (commit `142b5ef`).

### Preuves dans le code
- `lib/services/save_service.dart` (`SaveService`, `SaveLoadResult`, typedef `RefReader`).
- `lib/game/controllers/checkpoint_controller.dart` (`checkpointProvider`, `autosaveOrchestratorProvider`).
- `lib/models/missing_save_item.dart` (`MissingSaveItem`).
- `hydrate()` sur `RunController`, `DeckNotifier`, `InventoryController`, `SkillController`.
- `toJson`/`fromJsonWithReport` sur `RunState`, `DeckState`, `InventoryState` ; `toJson`/`fromJson` sur `SkillState`.
- `getById()` sur `CardData`, `RelicData`, `PassiveData` ; `ForgeUpgradeData.filterValidRefs()`.
- `lib/ui/screens/home_screen.dart` (bouton « Continuer », dialogue de confirmation, dialogue de contenu manquant).
- Suite de tests dédiée : `save_catalog_lookups_test.dart`, `skill_state_persistence_test.dart`, `inventory_state_persistence_test.dart`, `deck_state_persistence_test.dart`, `run_state_persistence_test.dart`, `notifier_hydrate_test.dart`, `save_service_test.dart`, `checkpoint_autosave_test.dart`, `home_screen_save_test.dart`.

### Conséquences
- ✅ **Déblocage de commercialisation** : résout le point bloquant identifié dans ADR-011 — une run n'est plus jamais perdue au-delà du dernier nœud résolu.
- ✅ **Découplage total** : aucun écran de nœud n'a besoin de connaître l'existence du système de sauvegarde, seulement d'appeler `bump()` (indirectement, via les méthodes de manager déjà existantes).
- ✅ **Robustesse au content drift** : les futurs rééquilibrages ou suppressions de contenu ne peuvent ni corrompre une sauvegarde existante ni surprendre silencieusement le joueur.
- ⚠️ **Hors scope assumé** : pas de reprise mid-combat, pas de slots multiples, pas de monnaie méta persistante inter-runs — ces trois points restent au backlog.
- ⚠️ **Vérification manuelle toujours recommandée** : les flux UI de mort → clear → pas de bouton Continuer, Continuer → MapScreen, dialogue de contenu manquant, et confirmation d'écrasement n'ont été vérifiés que par tests automatisés, pas par un passage manuel `flutter run` (aucun sous-agent n'a de session interactive) — le merge a eu lieu (PR #19) sans que cette vérification manuelle ait été faite entre-temps.
