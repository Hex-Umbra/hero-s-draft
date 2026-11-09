### 3.8. `SignatureEvolutionRules` — les Règles Pures des Évolutions de Signature

`lib/game/systems/signature_evolution_rules.dart` — ce que le palier admet, le pool rangé pour
l'écran et le choix des évolutions de signature, sans Riverpod, sans état ni hasard : une
`SignatureInstance`, rien d'autre. Plus de tirage depuis D78
([ADR-115](../_adr/ADR-115-le-choix-libre-des-evolutions-et-les-rideaux-de-la-carte.md)). Vague 5
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
| `admissible(s)` | Ce que le joueur choisit : au palier mineur (`s.nextTier`), les mineures ; au palier majeur, les majeures éligibles, plus toutes les mineures quand il en reste moins de trois (`_enoughMajors`) — le repli de Q6 |
| `board(s)` | Le pool rangé pour l'écran, `SignatureEvolutionBoard`, chaque évolution une fois, dans l'ordre du pool : `choices` (`admissible`) ; `upcoming`, l'autre rang — une mineure prise y reste —, et `upcomingHeroLevel` ; `takenMajors` ; `excluded`, chaque majeure exclue avec la majeure prise qui l'exclut |
| `take(s, evolutionId)` | La signature après le choix, ou `null` si l'évolution n'est pas `admissible` |
| `withChoice(evolutions, chosen)` | Les références après le choix : une mineure déjà prise monte d'un niveau **à sa place**, toute autre entre à `<id>:1` **à la fin** — l'ordre de première prise que lisent la bande et les puces |

#### 3.8.2. Ce qui vit ailleurs, et pourquoi

| Lecture | Où | Pourquoi pas ici |
|:---|:---|:---|
| `level`, `nextTier`, `pendingFor(heroLevel)`, `nextEvolutionHeroLevel`, `cooldown`, `taken` | `SignatureInstance` (`lib/models/signature_instance.dart`) | Des lectures de l'instance, dérivées de ses références ; **l'attente n'est jamais stockée** (A27) |
| `asCard` — la vue évoluée, ses deltas, sa cible, son coût, sa description | `SignatureInstance` | La vue d'E4 que jouent le moteur et la barre ; la vue est une `CardInstance` dont les `extraDeltas` portent les deltas des évolutions à leur niveau — `flatBonus` compris —, appliqués par le même applicateur que les runes (`EffectiveCard`) |
| `effectLines` — les entrées de la bande et de la liste | `SignatureInstance` | Valeurs lues sur la vue évoluée : aucun widget ne recalcule ([`_patterns/05-12`](05-12-barre-de-signatures-bande-et-calque.md)) |
| `restore(data, raw)` — la relecture d'une sauvegarde | `SignatureInstance` | Un id absent du pool entre au rapport des éléments manquants ; une référence mal formée ou une majeure impossible est corrigée sans rapport |
| `pendingEvolutions`, `hasPendingChoice` | `RunState` (`run_controller.dart`) | Les signatures dont une évolution attend, dans l'ordre de `HeroData.skills`, choisies ensemble (D79) ; le rideau et les deux gardes de nœud de `MapScreen` lisent `hasPendingChoice` |
| `chooseSignatureEvolution` | `RunController` | Refuse sans rien écrire hors de la run, sans attente, hors du pool, hors d'`admissible` ; sinon écrit et `checkpointProvider.bump()` |
| La sélection en cours, le bouton unique | `SignatureEvolutionScreen` | Un état d'écran : rien n'est tiré, donc rien à retenir ; le bouton appelle `chooseSignatureEvolution` pour chaque signature, et le retour ramène au rideau sans rien perdre |
| Le rideau, une forme par ce qui attend | `LevelUpOverlay`, `lib/ui/widgets/map/curtains/` | De l'affichage seul : il lit `pendingDrafts` et le `nextTier` des `pendingEvolutions` (D80 à D82) |

#### 3.8.3. Les références

Les évolutions s'écrivent comme les runes, `id:niveau`, lues par l'analyseur unique
`ForgeUpgradeData.parseRef` / `levelsOf` : une seule grammaire pour les deux sortes d'améliorations
qui montent de niveau.

> [!NOTE]
> **Tests** : `signature_evolution_rules_test.dart` (`board` compris), les lectures de `SignatureInstance`, le choix
> du contrôleur, la sauvegarde (dix mutations, neuf attrapées, la dixième gardée par une assertion,
> S17) et les deux actions de debug (`debug_actions_test.dart`). L'écran, les rideaux et Mon Deck
> sont au test manuel ([ADR-113](../_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)).
