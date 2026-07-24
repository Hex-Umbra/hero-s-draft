# Spec de Design : Système de Sauvegarde de Run (Hero's Draft)

**Date** : 2026-07-23
**Statut** : Validé, en attente de plan d'implémentation

## 1. Contexte & Problème

Aujourd'hui, l'état d'une run (`RunState`, `DeckState`, `InventoryState`, `SkillState`) ne vit qu'en mémoire dans les `Notifier` Riverpod. Fermer l'application, la mettre en arrière-plan (mobile) ou un crash entraîne la perte totale de la progression — un run pouvant durer 30 à 60+ minutes sur ~10 étages.

Le point d'extension existe déjà mais est un stub vide : `lib/game/controllers/run/run_persistence_manager.dart` définit `saveRun()`, `loadRun()`, `clearSavedRun()` sans aucune logique. La dépendance `shared_preferences` est déjà présente dans le projet (utilisée par `lib/tutorial/tutorial_progress_service.dart`), donc aucune nouvelle librairie n'est nécessaire.

**Hors scope explicite** : ce design ne couvre que la persistance d'une run active. La monnaie méta persistante entre runs (backlog séparé) n'est pas traitée ici, même si l'infrastructure `SaveService` pourra potentiellement être réutilisée plus tard.

## 2. Décisions de Cadrage

Ces décisions structurent l'ensemble du design et ne sont pas renégociées dans les sections suivantes :

- **Granularité de sauvegarde = checkpoint carte, pas mid-combat.** On sauvegarde uniquement entre les nœuds (retour sur `MapScreen` après un combat/boutique/repos/event/forge résolu). `CombatState`, `EnemyInstance` et l'état de tour en cours ne sont **jamais** sérialisés. Si l'application est tuée en plein combat, ce combat est simplement rejoué au prochain lancement depuis le dernier checkpoint.
- **Un seul slot de sauvegarde.** Cohérent avec l'architecture actuelle (un seul `RunController` actif). Démarrer une nouvelle partie alors qu'une sauvegarde existe écrase l'ancienne, après confirmation utilisateur.
- **Autosave uniquement à la résolution d'un nœud**, jamais à chaque mutation d'état interne à un nœud (pas de save à chaque achat en boutique par exemple — seulement à la sortie de la boutique).

## 3. Architecture

Trois nouvelles pièces, plus la mise en œuvre de l'existant :

### `SaveService` (`lib/services/save_service.dart`)
Logique pure de sérialisation/écriture, sans dépendance Riverpod propre (elle reçoit un `Ref` en paramètre). Expose :
- `Future<void> save(Ref ref)` — lit `runProvider`, `deckProvider`, `inventoryProvider`, `skillProvider`, construit un JSON unique, l'écrit dans `shared_preferences` sous une clé unique et versionnée.
- `Future<SaveLoadResult> load(Ref ref)` — lit et parse le JSON, réhydrate chaque `Notifier`, retourne un résultat incluant la liste des éléments de contenu manquants détectés (voir §4).
- `Future<void> clear()` — supprime la clé de sauvegarde (appelé à la fin d'une run, victoire ou mort).
- `Future<bool> hasSave()` — vérifie l'existence d'une sauvegarde valide, utilisé par `HomeScreen`.

### `checkpointProvider`
Un `Notifier` minimaliste exposant `bump()`. Les écrans de nœud appellent `ref.read(checkpointProvider.notifier).bump()` à leur résolution, sans connaître les détails de la sauvegarde.

### `autosaveOrchestratorProvider`
Écoute `checkpointProvider` via `ref.listen` et appelle `SaveService.save(ref)` à chaque `bump()`. C'est la seule pièce qui relie "un checkpoint a eu lieu" à "il faut sauvegarder", ce qui découple les écrans de nœud du mécanisme de sauvegarde et permet d'ajouter un futur point de checkpoint en une ligne (`bump()`) sans toucher au `SaveService`.

### `RunPersistenceManager` (existant)
Le stub actuel est implémenté en délégant simplement à `SaveService` — aucune nouvelle logique métier n'y est ajoutée, c'est un point de câblage.

### Réhydratation
Chaque `Notifier` concerné (`RunController`, `DeckNotifier`, `InventoryController`, `SkillController`) reçoit une nouvelle méthode `hydrate(...)` qui remplace directement son état depuis les données chargées. La navigation post-chargement saute directement vers `MapScreen`, en contournant `ClassSelectionScreen` et `StarterDeckDraftScreen`.

## 4. Schéma de Données

Un unique JSON stocké sous une seule clé `shared_preferences` :

```json
{
  "schemaVersion": 1,
  "savedAt": "2026-07-23T14:32:00Z",
  "run": { },
  "deck": { },
  "inventory": { },
  "skills": { }
}
```

### `run` (miroir de `RunState`)
`currentLevel`, `act`, `heroStats` (déjà sérialisable via `EntityStats.toJson`), `heroClassId`, `mapNodes` (déjà sérialisable via `MapNode.toJson`), `currentNodeId`, `passiveTrait`, `forgeSlots`, `forgeTargetCardId`, `forgeTargetSessions`, `bonusForgeSlots`, `pendingDrafts`.

Point d'attention : `activePassive` référence un catalogue statique (`PassiveData`). On sauvegarde son **ID seul** (`activePassiveId`), re-résolu via `GameDataRegistry` au chargement — jamais l'objet complet.

### `deck` (miroir de `DeckState`)
Chaque pile (`masterDeck`, `drawPile`, `hand`, `discardPile`, `exhaustPile`) comme liste de `CardInstance` sérialisées.

**Décision clé** : au chargement, le champ `data` embarqué dans le JSON de chaque `CardInstance` n'est **jamais utilisé comme source de vérité**. `CardData` est systématiquement re-résolu par `id` via `GameDataRegistry`. Seuls `uniqueId`, `rarity`, `forgeUpgrades` (propres à l'instance) sont repris tels quels depuis la sauvegarde. Conséquences :
- un rééquilibrage de carte publié après la sauvegarde s'applique automatiquement à la prochaine reprise ;
- une carte supprimée du catalogue est détectable (échec de résolution par `id`) et déclenche le mécanisme de contenu manquant (§4.4).

### `inventory` (miroir de `InventoryState`)
`gold` (int), `relics` comme **liste d'IDs** (jamais l'objet `RelicData` complet, re-résolu au chargement), `bonusShopCards` (int).

### `skills` (miroir de `SkillState`)
`skill1Cooldown`, `skill2Cooldown` — triviaux, aucune référence à du contenu catalogué.

### Gestion du contenu manquant

Pour chaque carte, relique ou upgrade de forge référencée par ID dans la sauvegarde, un **instantané du nom bilingue** (`nameFr`/`nameEn`) est stocké à côté de l'ID au moment du `save()`. Si, au chargement, l'ID ne se résout plus dans les données actuelles (`GameDataRegistry`) :
1. l'entrée correspondante est retirée silencieusement de la liste concernée (deck, reliques, forge slots) — le reste de la run reste intact ;
2. l'entrée est ajoutée à la liste `missingItems` du `SaveLoadResult`, avec le nom instantané conservé (puisque l'ID seul ne permet plus de retrouver un nom affichable une fois le contenu supprimé) ;
3. l'UI de chargement affiche un message précis listant ces noms (voir §5).

## 5. Déclencheurs & Flux de Chargement/Reprise

### Points de `bump()` du checkpoint
Appelés au retour effectif sur `MapScreen`, nœud résolu :
1. `GameScreen` — après collecte des récompenses de victoire (or/XP/carte/relique).
2. `ShopScreen` — à la fermeture (achat, reroll, ou sortie sans achat).
3. `RestScreen` — dans la méthode `_leave()` existante.
4. `EventScreen` — après résolution du choix, à la fermeture.
5. `ForgeFusionScreen` / `ForgeUpgradeDialog` — après une fusion/achat d'upgrade confirmé.
6. `RelicExchangeScreen` — après une transaction d'échange conclue.
7. `DraftScreen` (post-combat ou Level Up) — après sélection de carte.

### Fin de run
À la victoire finale (retour au menu principal) ou à la mort du héros (`GameOverScreen`), `SaveService.clear()` est appelé — aucune sauvegarde n'est conservée pour une run terminée.

### `HomeScreen`
- Un `FutureProvider` appelle `SaveService.hasSave()` au build. Si vrai, un bouton **« Continuer »** apparaît au-dessus de **« Nouvelle Partie »**.
- **Continuer** → `SaveService.load(ref)`. Si `missingItems` est non vide, une boîte de dialogue liste les noms précis (ex. *« Certains éléments ne sont plus disponibles suite à une mise à jour : Croc Kunaï, Frappe Rapide. Votre progression a été conservée. »*), puis navigation directe vers `MapScreen`.
- **Nouvelle Partie** alors qu'une sauvegarde existe → dialogue de confirmation (*« Une partie est en cours, la démarrer en écrasera la sauvegarde. Continuer ? »*) avant `SaveService.clear()` et poursuite vers `ClassSelectionScreen` comme aujourd'hui.

## 6. Gestion d'Erreur & Versioning

Le champ `schemaVersion` distingue deux cas de défaillance traités différemment :

- **ID de contenu manquant** (carte/relique/upgrade supprimée) → dégradation *attendue*, gérée finement comme décrit en §4.4 : l'entrée est retirée, le reste de la run reste jouable, l'utilisateur est averti précisément.
- **JSON illisible ou `schemaVersion` inconnue/future** (sauvegarde corrompue ou format non migrable) → traité comme une *défaillance totale*, sans tentative de récupération partielle : `SaveService.load()` retourne un échec, la clé corrompue est supprimée via `clear()`, un log est émis en mode debug, et `HomeScreen` se comporte comme s'il n'existait aucune sauvegarde (le bouton "Continuer" n'apparaît pas). Le risque de désynchronisation silencieuse entre les sous-états (deck partiellement chargé, run incohérente) est jugé pire qu'une perte de run proprement signalée par son absence.

## 7. Plan de Tests

Conformément à la convention du projet (`flutter test` doit rester à 100% de réussite après implémentation) :

- Round-trip `toJson`/`fromJson` unitaire pour `RunState`, `DeckState`, `InventoryState`, `SkillState` (nouveaux, ces modèles n'en ont pas actuellement).
- `SaveService.save()` + `load()` en aller-retour, via `SharedPreferences.setMockInitialValues` pour simuler le stockage sans dépendance plateforme.
- Scénario « contenu manquant » : sauvegarde de test référençant un ID de carte/relique inexistant → vérifier le retrait silencieux de l'état réhydraté et la présence de l'entrée (avec son nom instantané) dans `missingItems`.
- Scénario « sauvegarde corrompue » : JSON invalide ou `schemaVersion` inconnue → `load()` échoue proprement, la clé est nettoyée, aucune exception ne remonte à l'UI.
- `checkpointProvider` / `autosaveOrchestratorProvider` : un seul `bump()` déclenche exactement un `save()` (pas de double-écriture).
- Widget test `HomeScreen` : bouton "Continuer" visible seulement si `hasSave()` est vrai ; dialogue de confirmation affiché sur "Nouvelle Partie" quand une sauvegarde existe.

## 8. Hors Scope (Rappel)

- Reprise exacte en plein combat (`CombatState` mid-fight).
- Slots de sauvegarde multiples.
- Monnaie méta / progression persistante inter-runs.
- Migration automatique entre versions de schéma (`schemaVersion` futur) — non nécessaire tant qu'il n'existe qu'une seule version du schéma.
