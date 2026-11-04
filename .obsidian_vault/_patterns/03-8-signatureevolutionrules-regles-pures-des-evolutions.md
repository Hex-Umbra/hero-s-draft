### 3.8. `SignatureEvolutionRules` — les Règles Pures des Évolutions de Signature

`lib/game/systems/signature_evolution_rules.dart` — le tirage et le choix des évolutions de
signature, sans Riverpod ni état : une `SignatureInstance` et un `Random`, rien d'autre. Vague 5
(P-42 tranche 1, partie 3), en attente du propriétaire —
[ADR-114](../_adr/ADR-114-les-evolutions-de-signature.md). Règle de jeu :
[`_rules/02-8`](../_rules/02-8-evolutions-de-signature.md).

> [!IMPORTANT]
> **Une seule règle de pose, lue par le jeu et par le debug** (S23). `RunController.chooseSignatureEvolution`
> et `DebugActions.takeSignatureEvolution` passent tous deux par `take` : un état que la règle
> refuse n'est posable ni en jouant ni par le menu de debug. Le debug ne saute qu'une condition,
> l'attente (`pendingFor`), pour préparer un test manuel sans monter le héros.

#### 3.8.1. Les fonctions

| Fonction | Rend |
|:---|:---|
| `eligibleMajors(s)` | Les majeures du pool ni prises, ni exclues par une majeure prise, ni l'excluant (`excludesOrIsExcludedBy`, Q7) |
| `admissible(s)` | Au palier mineur (`s.nextTier`), les mineures ; au palier majeur, les majeures éligibles, plus toutes les mineures quand il en reste moins de `offerSize` (3) — le repli de Q6 |
| `offer(s, rng)` | Trois évolutions sans poids ni remise : au palier mineur, trois mineures ; au palier majeur, les majeures éligibles puis des mineures pour compléter ; moins si le pool n'en a pas assez |
| `take(s, evolutionId)` | La signature après le choix, ou `null` si l'évolution n'est pas `admissible` |
| `withChoice(evolutions, chosen)` | Les références après le choix : une mineure déjà prise monte d'un niveau **à sa place**, toute autre entre à `<id>:1` **à la fin** — l'ordre de première prise que lisent la bande et les puces |

#### 3.8.2. Ce qui vit ailleurs, et pourquoi

| Lecture | Où | Pourquoi pas ici |
|:---|:---|:---|
| `level`, `nextTier`, `pendingFor(heroLevel)`, `cooldown`, `taken` | `SignatureInstance` (`lib/models/signature_instance.dart`) | Des lectures de l'instance, dérivées de ses références ; **l'attente n'est jamais stockée** (A27) |
| `asCard` — la vue évoluée, ses deltas, sa cible, son coût, sa description | `SignatureInstance` | La vue d'E4 que jouent le moteur et la barre ; la vue est une `CardInstance` dont les `extraDeltas` portent les deltas des évolutions à leur niveau — `flatBonus` compris —, appliqués par le même applicateur que les runes (`EffectiveCard`) |
| `effectLines` — les entrées de la bande et de la liste | `SignatureInstance` | Valeurs lues sur la vue évoluée : aucun widget ne recalcule ([`_patterns/05-12`](05-12-barre-de-signatures-bande-et-calque.md)) |
| `restore(data, raw)` — la relecture d'une sauvegarde | `SignatureInstance` | Un id absent du pool entre au rapport des éléments manquants ; une référence mal formée ou une majeure impossible est corrigée sans rapport |
| `nextPendingEvolution`, `hasPendingChoice` | `RunState` (`run_controller.dart`) | L'ordre des attentes entre signatures : le plus bas niveau d'abord, à égalité l'ordre de `HeroData.skills` (S16) ; le rideau et les deux gardes de nœud de `MapScreen` lisent `hasPendingChoice` |
| `chooseSignatureEvolution` | `RunController` | Refuse sans rien écrire hors de la run, sans attente, hors du pool, hors d'`admissible` ; sinon écrit et `checkpointProvider.bump()` |
| Le tirage à l'ouverture de l'écran | `SignatureEvolutionScreen` | Rien n'est retenu entre deux ouvertures, comme le draft de niveau ; le retour système, sous `PopScope`, ne relance pas le tirage (S19) |

#### 3.8.3. Les références

Les évolutions s'écrivent comme les runes, `id:niveau`, lues par l'analyseur unique
`ForgeUpgradeData.parseRef` / `levelsOf` : une seule grammaire pour les deux sortes d'améliorations
qui montent de niveau.

> [!NOTE]
> **Tests** : `signature_evolution_rules_test.dart`, les lectures de `SignatureInstance`, le choix
> du contrôleur, la sauvegarde (dix mutations, neuf attrapées, la dixième gardée par une assertion,
> S17) et les deux actions de debug (`debug_actions_test.dart`). L'écran et le rideau sont au test
> manuel ([ADR-113](../_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)).
