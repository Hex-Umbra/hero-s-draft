# P-41 lot C, partie 1 — Les récompenses de niveau deviennent de la donnée — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sortir les huit récompenses de niveau du code : un fichier par récompense sous `assets/data/level_up_rewards/`, portant sa table de valeurs par rareté et ses libellés bilingues, lu par le tirage, par l'écran de draft, par le rouleau du carrousel et par la prose du tutoriel — à valeurs et à comportement identiques.

**Architecture:** Une neuvième source d'entités (`EntitySource`), un modèle `LevelUpRewardData` et un champ `GameDataRegistry.levelUpRewards`, sur le modèle exact des huit catégories existantes. `LevelUpRewardType`, ses huit valeurs d'enum et le `rng.nextInt(6)` disparaissent : `DraftChoice` ne porte plus sept champs de gain mais la récompense tirée, sa rareté et sa valeur. Les libellés quittent les ARB pour des gabarits à substitution (`{amount}`, `{passive}`, `{effect}`), ce qui rend la composition de l'*Affinité* avec le passif actif une règle unique au lieu d'une branche par récompense. L'application du gain quitte l'écran de draft pour `PlayerStatsManager`, où un `switch` exhaustif sur la stat visée fait rougir l'analyseur si une stat est ajoutée sans être appliquée.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` — lire le **§8.1** en entier, puis le §8.4 (ce qui reste à P-16) et la décision **D3** du §0.1. Le §8.1 se termine par : « **Cette partie est indépendante de tout le reste de P-41** ». Elle l'est en effet de son lot A comme de son lot B, tous deux fusionnés ; la partie 2 du lot C, elle, en **dépend** (§8.2 : le filtre d'*Affinité* conditionne une récompense qui est de la donnée depuis cette partie).

## Pourquoi deux plans pour le lot C

Le lot C se livre en **deux parties**, comme le lot B, et pour la même raison : la première ne change pas le jeu et se vérifie par une table de valeurs figée ; la seconde change ce que le joueur voit et tire, sur une base déjà passée en donnée.

| | Partie 1 *(ce plan)* | Partie 2 — [plan](2026-09-18-p41-lot-c-partie-2-filtre-et-ecran-de-selection.md) |
|:---|:---|:---|
| Spec | §8.1 | §8.2, §8.3 |
| Contenu | Les huit récompenses passent en donnée | Le filtre d'*Affinité*, et l'écran de sélection de classe |
| Le jeu change ? | **Non** — mêmes valeurs, mêmes textes, mêmes probabilités | **Oui** : `baseDamage` disparaît, l'écran montre l'orientation et laisse choisir le passif, *Affinité* n'est plus tirée sans Maîtrise |
| Critère d'acceptation | `level_up_reward_values_test.dart`, devenu un test sur la donnée, verrouille les 30 combinaisons **à valeurs identiques** (spec §8.1) | La suite existante, plus les tests d'écran de la partie 2 |
| Branche | `feat/p41-lot-c-recompenses` | `feat/p41-lot-c-selection` |

**La partie 2 dépend de la partie 1** : son filtre d'*Affinité* ajoute un champ à `LevelUpRewardData` et un paramètre à `generateChoices`, tous deux créés ici. Elle se lance donc après la fusion de cette partie.

## Global Constraints

- **Le jeu ne change pas.** Aucune valeur, aucun texte joueur, aucune probabilité de tirage ne bouge. Ce qui change est la **provenance** de ces valeurs et de ces textes : du code vers `assets/data/level_up_rewards/`. Toute divergence observée est un défaut de cette partie, jamais un ajustement.
- **Le rééquilibrage reste à P-16** (spec §8.4). *Sagesse* garde son plateau assumé (1, 2, 2, 3, 4 — `round(1 × 1,5)` et `round(1 × 2,0)` donnent tous deux 2), et il est **recopié tel quel** dans sa donnée. P-41 doit seulement ne pas aggraver.
- `dart analyze` doit afficher `No issues found!` à la fin de **chaque** tâche.
- `flutter test` doit être **entièrement** vert à la fin de chaque tâche. Point de départ **mesuré le 2026-09-18 sur `main`** (commit `6605b25`) : **1021 tests**, `dart analyze` propre. Les totaux annoncés tâche par tâche sont une **prévision arithmétique** (1021 + les tests ajoutés − ceux supprimés), **non un rejeu** : un écart signale un test oublié ou dupliqué, à comprendre avant de continuer — jamais un nombre à réajuster à l'aveugle.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas.
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** pour du contenu : les heredocs de cet environnement mangent les antislashs, et le code Dart et les JSON de ce plan en contiennent (`'Trèfle à 4 feuilles'`, `\n`, `l\'Affinité`).
- Tout texte joueur d'un JSON porte ses variantes `_fr` **et** `_en` (`CLAUDE.md`). Les huit récompenses portent au minimum `name_fr`, `name_en`, `description_fr`, `description_en`.
- **Un fichier ajouté à `assets/` doit être déclaré au `pubspec.yaml`** : les déclarations de Flutter ne sont pas récursives, et un répertoire non déclaré se charge en développement puis disparaît du build sans un mot. C'est `dart run tool/sync_assets.dart` qui régénère la section, jamais la main.
- Les fichiers `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` sont générés **et commités** : après toute modification d'un ARB, lancer `flutter gen-l10n` et commiter les trois. Le fichier **gabarit** est `app_en.arb` (`l10n.yaml`) : c'est lui qui porte les blocs `@clé` de métadonnées.
- Le tutoriel ne référence aucun provider d'état (ADR-081), vérifié par `test/tutorial/tutorial_isolation_test.dart` — qui interdit nommément `GameDataRegistry.instance` dans `lib/tutorial/`. Le registre arrive au tutoriel par `TutorialScreen.data` et `TutorialEngine.data`, déjà en place : **aucune nouvelle voie d'accès**.
- **L'éditeur de contenu n'apprend pas cette catégorie** : la spec place « Récompenses de niveau : nouvelle catégorie éditable » au **lot D** (§9.2). Ne pas toucher `EntityCategory` ni `kEntityDescriptors` — le compte de catégories de `test/unit/content_editor/entity_descriptor_test.dart` doit rester à sept.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Le code va sur la branche `feat/p41-lot-c-recompenses`, jamais sur `main`. La documentation de cette partie est déjà commitée sur `main`, avant l'exécution. **Pas de worktree** (décision du propriétaire) : la branche est créée dans le checkout principal, même si le skill d'exécution en propose un.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes**, terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire des fichiers générés sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, ceux de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.

## Décisions prises à la rédaction du plan

La spec tranche la conception — « un fichier par récompense, répertoire et forme exacte fixés au plan » (§8.1). Voici cette forme. L'exécutant n'a pas à la rouvrir.

| # | Question | Décision | Pourquoi |
|:---|:---|:---|:---|
| **1** | Où vivent les fichiers ? | `assets/data/level_up_rewards/<id>.json`, à plat | C'est la forme des `relics/`, `events/`, `forge_upgrades/` et `passives/` : une récompense n'appartient à aucune classe. Le répertoire n'impose donc que l'`id` (ADR-086) |
| **2** | **Huit** fichiers ou six ? | **Huit** : les six types tirables **et** les deux mythiques, Trèfle et Miroir | Les mythiques sont des récompenses au même titre : construites en dur, elles resteraient la moitié du problème que D3 corrige. Un champ `pool` les distingue — `draft` pour les six tirés uniformément, `mythic` pour celles qui ont leur propre jet |
| **3** | Le tirage lit-il l'ordre des fichiers ? | Non : `displayOrder` puis `id`, comme `availablePassivesFor` et `HeroData.displayOrder` | `rng.nextInt(6)` tirait un **index**, et l'ordre des valeurs de l'enum en était la sémantique. Un tirage indexé sur l'ordre de lecture du disque serait un piège silencieux ; `id` tranche à rang égal |
| **4** | Comment la valeur par rareté est-elle écrite ? | Une **table explicite** `values`, cinq entrées pour une récompense `draft`, une pour une mythique. **Aucun multiplicateur ne survit en code** | Le multiplicateur générique (×1 / ×1,5 / ×2 / ×3 / ×4) ne couvrait déjà que trois des six types ; les trois autres portaient leur propre table. Une table pour tous supprime la coexistence des deux régimes — celle-là même qui avait laissé un légendaire retomber sur la valeur d'un commun (`level_up_reward_values_test.dart`) |
| **5** | Comment *Férocité* écrit-elle `0.10` ? | En **points de pourcentage entiers** : `10`, et l'application divise par 100 | Le joueur lit déjà « +10 % de dégâts de Critique » : la donnée écrit ce que le joueur lit. `values` reste `Map<RewardRarity, int>` pour les huit récompenses, sans un seul décimal dans le catalogue |
| **6** | Comment *Affinité* compose-t-elle avec le passif actif ? | Par **substitution de gabarit**, pas par une branche : `description` peut nommer `{amount}`, `{passive}` et `{effect}` ; `fallbackDescription` est le gabarit de repli quand `{passive}`/`{effect}` ne peuvent pas être résolus | C'est le mécanisme, pas le menu : une récompense future qui se décrit par le passif actif n'ajoute aucun `case`. La règle de repli reproduit exactement `draftChoiceAffinityNoEffect` d'aujourd'hui |

> **« Gabarit » = phrase à trous.** Le fichier d'une récompense ne porte pas un texte fini mais une phrase avec des trous nommés, entre accolades, que le jeu remplit au moment de l'afficher. `"+{amount} PV Max"` est un gabarit ; à l'affichage d'une Vitalité épique, `{amount}` devient `15` et le joueur lit « +15 PV Max ». Trois trous existent : `{amount}` (la valeur tirée), `{passive}` (le nom du passif actif) et `{effect}` (ce qu'un point de Maîtrise apporte à ce passif). Le code connaît **ces trois noms** et rien d'autre : il ne sait pas qu'une récompense s'appelle *Affinité*, ni combien il y en a. C'est ce qui permet d'en ajouter une par simple fichier.

### La forme exacte d'un fichier de récompense

Les huit fichiers sont écrits en entier à la tâche 3. Voici la même chose vue comme un formulaire, une clé par ligne, pour relire une forme plutôt qu'une liste.

| Clé | Obligatoire | Ce qu'elle dit |
|:---|:---:|:---|
| `id` | ✅ | L'identifiant, **égal au nom du fichier** (`vitality.json` → `"vitality"`), en `snake_case` ASCII |
| `name_fr`, `name_en` | ✅ | Le titre affiché sur la carte de draft — « Vitalité » / « Vitality » |
| `description_fr`, `description_en` | ✅ | La phrase à trous affichée sous le titre |
| `fallbackDescription_fr`, `_en` | — | La phrase de repli, quand `{passive}`/`{effect}` ne peuvent pas être remplis. *Affinité* seule en porte une |
| `shortDescription_fr`, `_en` | — | La ligne courte du rouleau qui défile, qui n'a ni passif ni place. *Affinité* et *Miroir* en portent une |
| `effect` | ✅ | `"stat"` (elle monte une stat) ou `"cloneCard"` (le Miroir) |
| `stat` | ✅ si `effect: "stat"` | Laquelle : `maxHp`, `might`, `mastery`, `maxMana`, `luck`, `critChance`, `critDamage` |
| `pool` | ✅ | `"draft"` — tirée uniformément dans les trois emplacements — ou `"mythic"` — son propre jet, à 0,5 %, ajoutée aux trois |
| `values` | ✅ | La valeur du gain, palier par palier. Cinq entrées pour `draft`, `mythic` seul pour une mythique de stat, vide pour le Miroir |
| `displayOrder` | — | Le rang dans son groupe de tirage ; départage par `id` à rang égal |
| `requires` | — | *(ajouté par la partie 2)* Ce que la run doit présenter — `"passiveMastery"` pour *Affinité* |

**Chaque texte porte ses deux langues, sans exception** (`CLAUDE.md`). `fromJson` refuse un `_fr` sans son `_en`, et réciproquement : une traduction perdue au passage en donnée doit faire échouer le chargement, pas s'afficher en anglais dans un jeu en français.
| **7** | Que montre le rouleau qui défile, qui n'a ni passif ni place ? | Un troisième gabarit **optionnel**, `shortDescription`, rempli à la valeur `rare`. Absent : le rouleau se rabat sur `fallbackDescription` puis sur `description` | Le rouleau affichait déjà des libellés **raccourcis à la main** (« Cloner une carte » pour le Miroir, dont la vraie description tient sur trois lignes). Sans ce champ, passer le rouleau à la donnée allongerait ses cartes — un changement visuel que cette partie s'interdit. La valeur `rare` est arbitraire et assumée : les libellés d'aujourd'hui ne correspondaient à aucun palier cohérent |
| **8** | Qui applique le gain à la run ? | `PlayerStatsManager.applyLevelUpReward(DraftChoice)`, façade sur `RunController` ; `DraftScreen` ne compose plus les sept accumulateurs | `CLAUDE.md` interdit la logique de jeu dans un écran, et la règle « quelle stat monte » devient un `switch` **exhaustif** sur `RewardStat` : ajouter une stat sans l'appliquer ne compile plus. C'est aussi ce qui rend l'application testable sans monter un widget |
| **9** | `RewardRarity` reste-t-il dans le service ? | Non : il part dans `lib/models/reward_rarity.dart` | `lib/models/data/` ne peut pas importer `lib/game/services/` sans inverser les couches. Précédent exact : `lib/models/might_target.dart`, enum sans dépendance importé par `EntityStats` et `HeroData` |
| **10** | La prose du tutoriel, comment lit-elle le registre alors que `kTutorialSteps` est `const` ? | La prose garde ses placeholders (`{rollableCount}`, `{rollableNames}`, `{mythicCount}`, `{mythicNames}`) et `TutorialScreen` les remplit par une fonction pure, `fillRewardPlaceholders` | `TutorialScreen` porte déjà `final GameDataRegistry data`. Rendre `kTutorialSteps` non-`const` propagerait le registre dans tout `tutorial_data.dart` pour une seule étape ; une fonction pure se teste sans widget et respecte ADR-081 |

## Conséquences assumées, à annoncer plutôt qu'à découvrir

1. **Une formulation du tutoriel change, d'un mot.** La liste des deux mythiques était écrite « le Trèfle à 4 feuilles et le Miroir » ; générée depuis les noms du registre, elle devient « Trèfle à 4 feuilles et Miroir ». Les articles français sont genrés et le registre ne porte pas le genre d'un nom : inventer un champ `article` pour deux noms serait plus coûteux que la perte. C'est le seul texte joueur que cette partie modifie.
2. **Le rouleau de draft montre désormais les valeurs `rare` de chaque récompense** au lieu de quatre chiffres écrits à la main (décision 7). Les cartes défilent en 140 ms et sont floutées : c'est une donnée de décor, pas une information.
3. **17 clés ARB disparaissent** (`draftChoiceVitality` … `draftChoiceFerocityDesc`). Les clés de rareté (`rarityLegendary` …) **restent** : la rareté n'est pas une récompense, et `RewardRarity` n'est pas de la donnée de contenu.
4. **Le nombre de fichiers d'entité passe de 77 à 85.** Deux tests le comptent nommément (`entity_id_convention_test.dart`, `real_bundle_load_test.dart`), et c'est leur raison d'être : les mettre à jour est la bonne réaction, les affaiblir ne l'est pas.
5. **L'éditeur de contenu ne sait pas éditer une récompense** jusqu'au lot D (§9.2). Seule la création à la main d'un fichier dans le répertoire fonctionne — exactement comme pour les huit autres catégories avant que l'éditeur ne les apprenne.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/reward_rarity.dart` *(nouveau)* | `enum RewardRarity`, sans dépendance | 1 |
| `lib/models/data/level_up_reward_data.dart` *(nouveau)* | `LevelUpRewardData`, `RewardEffect`, `RewardStat`, `RewardPool` ; la lecture JSON et la substitution de gabarit | 2 |
| `assets/data/level_up_rewards/*.json` *(8 nouveaux)* | Les huit récompenses : valeurs par rareté et libellés bilingues | 3 |
| `lib/services/game_data_service.dart` | La neuvième source d'entités | 3 |
| `lib/models/data/game_data_registry.dart` | `levelUpRewards` | 3 |
| `pubspec.yaml` | Le répertoire déclaré, par `tool/sync_assets.dart` | 3 |
| `lib/game/services/level_up_reward_service.dart` | `DraftChoice` réduit à (récompense, rareté, valeur) ; `generateChoices(rewards:)` ; `LevelUpRewardType` et le `nextInt(6)` supprimés | 4 |
| `lib/ui/widgets/draft/draft_choice_labels.dart` | Titres et descriptions lus sur la donnée | 4 |
| `lib/l10n/app_en.arb`, `app_fr.arb` | 17 clés retirées | 4 |
| `lib/ui/screens/draft_screen.dart` | Passe le registre au tirage ; délègue l'application ; passe le décor du rouleau | 4, 5, 6 |
| `lib/game/controllers/run/player_stats_manager.dart`, `run_controller.dart` | `applyLevelUpReward` | 5 |
| `lib/ui/widgets/relic_carousel/draft_card_reel.dart` | Le décor du rouleau devient un paramètre | 6 |
| `lib/tutorial/widgets/tutorial_draft_widget.dart` | Passe le registre au tirage | 4 |
| `lib/tutorial/tutorial_prose.dart` *(nouveau)* | `fillRewardPlaceholders`, fonction pure | 7 |
| `lib/tutorial/tutorial_data.dart`, `tutorial_screen.dart` | Les placeholders, et leur remplissage au rendu | 7 |

---

### Task 0: La branche, depuis la documentation déjà commitée

**À faire dans le checkout principal, avant toute tâche de code.**

**Files:**
- Aucun. La documentation de cette partie est **déjà commitée sur `main`** : ce plan, celui de la partie 2, et les liens qui les portent dans `docs/INDEX.md` et `docs/ROADMAP.md`.

**Interfaces:**
- Consumes: ce plan, commité sur `main`.
- Produces: la branche `feat/p41-lot-c-recompenses`, créée depuis le commit du plan.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement), puis `git status --short`
Expected: **aucune sortie** — l'arbre de travail est propre.

Run: `git log --oneline -5`
Expected: on y trouve le commit qui ajoute `docs/superpowers/plans/2026-09-18-p41-lot-c-partie-1-recompenses-data-driven.md`, et, avant lui, `6605b25 docs(exploration): brainstorm identite visuelle pixel art` — une passe de correction de ce plan a pu en ajouter un par-dessus. Si l'arbre n'est pas propre, ou si le commit du plan manque, **s'arrêter et le signaler** : ce plan part de cet état.

- [ ] **Step 2: Créer la branche**

Run: `git switch -c feat/p41-lot-c-recompenses` — depuis `main`, dans le checkout principal. **Pas de worktree**, même si le skill d'exécution en propose un.

- [ ] **Step 3: Mesurer la base**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1021: All tests passed!`

---

### Task 1: `RewardRarity` quitte le service

Un déplacement d'énumération, sans lecteur nouveau ni comportement changé. Il précède tout le reste : le modèle de la tâche 2 vit dans `lib/models/data/` et ne peut pas importer `lib/game/services/`.

**Files:**
- Create: `lib/models/reward_rarity.dart`
- Modify: `lib/game/services/level_up_reward_service.dart`, `lib/ui/screens/draft_screen.dart`, `lib/ui/widgets/draft/draft_choice_labels.dart`
- Modify (tests) : `test/unit/level_up_reward_values_test.dart`, `test/unit/probabilities_test.dart`, `test/unit/draft_choice_labels_test.dart`, `test/widget/draft_screen_test.dart`

**Interfaces:**
- Consumes: rien.
- Produces: `enum RewardRarity { common, uncommon, rare, epic, legendary, mythic }` dans `lib/models/reward_rarity.dart`. L'ordre des valeurs est inchangé et il compte : `test/unit/level_up_reward_values_test.dart` parcourt `RewardRarity.values` pour vérifier la progression.

- [ ] **Step 1: Créer le fichier de l'énumération**

Create `lib/models/reward_rarity.dart`:

```dart
/// Le palier de rareté d'une récompense de niveau.
///
/// Rangé ici, et non dans le service qui le tire, parce que la donnée le lit :
/// `LevelUpRewardData` porte une table de valeurs indexée par ce palier, et
/// `lib/models/data/` ne peut pas importer `lib/game/services/` sans inverser
/// les couches. Précédent : `lib/models/might_target.dart`.
///
/// **L'ordre des valeurs est croissant et il est lu comme tel** : les tests de
/// valeurs vérifient qu'une récompense progresse de [common] à [legendary].
/// [mythic] n'est rendu que par un tirage de niveau (`isLevelReward: true`).
enum RewardRarity { common, uncommon, rare, epic, legendary, mythic }
```

- [ ] **Step 2: Retirer l'énumération du service et l'y importer**

Edit `lib/game/services/level_up_reward_service.dart` : supprimer la ligne `enum RewardRarity { common, uncommon, rare, epic, legendary, mythic }` et ajouter, sous `import 'dart:math';` :

```dart
import '../../models/reward_rarity.dart';
```

- [ ] **Step 3: Faire tomber les erreurs de compilation**

Run: `dart analyze`
Expected: des erreurs `Undefined name 'RewardRarity'` dans les fichiers listés ci-dessus.

Ajouter, dans chacun, l'import du nouveau fichier :
- `lib/ui/screens/draft_screen.dart` et `lib/ui/widgets/draft/draft_choice_labels.dart` : `import '../../models/reward_rarity.dart';` et `import '../../../models/reward_rarity.dart';` respectivement — vérifier la profondeur du chemin relatif dans chaque fichier.
- les quatre fichiers de test : `import 'package:roguelike_card_game/models/reward_rarity.dart';`

**Ne pas retirer** l'import existant de `level_up_reward_service.dart` dans ces fichiers : ils y lisent encore `DraftChoice`, `LevelUpRewardType` ou `LevelUpRewardService`.

- [ ] **Step 4: Vérifier**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1021: All tests passed!` (aucun test ajouté ni supprimé : un déplacement de symbole n'en mérite pas).

- [ ] **Step 5: Commit**

```bash
git add lib/models/reward_rarity.dart lib/game/services/level_up_reward_service.dart lib/ui/screens/draft_screen.dart lib/ui/widgets/draft/draft_choice_labels.dart test/unit/level_up_reward_values_test.dart test/unit/probabilities_test.dart test/unit/draft_choice_labels_test.dart test/widget/draft_screen_test.dart
git commit -m "refactor(recompenses): RewardRarity devient un modele partage

La donnee des recompenses de niveau doit lire ce palier, et lib/models/data
ne peut pas importer lib/game/services sans inverser les couches. Precedent :
lib/models/might_target.dart.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `LevelUpRewardData`, le modèle et sa lecture

Modèle et lecture seuls, sans lecteur encore : rien du jeu ne change.

**Files:**
- Create: `lib/models/data/level_up_reward_data.dart`
- Test: `test/unit/level_up_reward_data_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `RewardRarity` (tâche 1) ; `PassiveData` et `PassiveMastery` (`lib/models/data/passive_data.dart`, existants).
- Produces:
  - `enum RewardEffect { stat, cloneCard }`
  - `enum RewardStat { maxHp, might, mastery, maxMana, luck, critChance, critDamage }`
  - `enum RewardPool { draft, mythic }`
  - `class LevelUpRewardData` — champs `String id`, `String nameFr/nameEn`, `String descriptionFr/descriptionEn`, `String? fallbackDescriptionFr/fallbackDescriptionEn`, `String? shortDescriptionFr/shortDescriptionEn`, `RewardEffect effect`, `RewardStat? stat`, `RewardPool pool`, `Map<RewardRarity, int> values`, `int displayOrder`.
  - `factory LevelUpRewardData.fromJson(Map<String, dynamic>)` — lève `FormatException` sur une valeur d'énumération inconnue, sur `effect: "stat"` sans `stat`, sur `effect: "cloneCard"` **avec** `stat`, sur un palier manquant dans `values`.
  - `String getName(String locale)`
  - `String describe(String locale, {required int amount, PassiveData? passive})`
  - `String shortLabel(String locale, {required int amount})`
  - `int amountFor(RewardRarity rarity)`

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/level_up_reward_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';

/// Une récompense de niveau est de la donnée (spec P-41, §8.1, décision D3).
void main() {
  Map<String, dynamic> vitalityJson() => {
        'id': 'vitality',
        'name_fr': 'Vitalité',
        'name_en': 'Vitality',
        'description_fr': '+{amount} PV Max',
        'description_en': '+{amount} Max HP',
        'effect': 'stat',
        'stat': 'maxHp',
        'pool': 'draft',
        'displayOrder': 1,
        'values': {
          'common': 5,
          'uncommon': 8,
          'rare': 10,
          'epic': 15,
          'legendary': 20,
        },
      };

  Map<String, dynamic> affinityJson() => {
        'id': 'affinity',
        'name_fr': 'Affinité',
        'name_en': 'Affinity',
        'description_fr': '{passive} : {effect}',
        'description_en': '{passive}: {effect}',
        'fallbackDescription_fr': '+{amount} Maîtrise, sans effet sur votre passif',
        'fallbackDescription_en': '+{amount} Mastery, no effect on your passive',
        'shortDescription_fr': '+{amount} Maîtrise',
        'shortDescription_en': '+{amount} Mastery',
        'effect': 'stat',
        'stat': 'mastery',
        'pool': 'draft',
        'displayOrder': 3,
        'values': {
          'common': 1,
          'uncommon': 2,
          'rare': 3,
          'epic': 5,
          'legendary': 7,
        },
      };

  Map<String, dynamic> mirrorJson() => {
        'id': 'mirror',
        'name_fr': 'Miroir',
        'name_en': 'Mirror',
        'description_fr': 'Cloner une carte au choix parmi 3 cartes aléatoires de votre deck',
        'description_en': 'Clone one card among 3 random cards from your deck',
        'shortDescription_fr': 'Cloner une carte',
        'shortDescription_en': 'Clone a card',
        'effect': 'cloneCard',
        'pool': 'mythic',
        'displayOrder': 8,
        'values': <String, dynamic>{},
      };

  PassiveData regen({PassiveMastery? mastery}) => PassiveData(
        id: 'regen_armor',
        nameEn: 'Armor Regeneration',
        nameFr: "Régénération d'Armure",
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: mastery,
      );

  const masteryBlock = PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} Block at end of turn',
    descriptionFr: '+{amount} Armure en fin de tour',
  );

  group('lecture', () {
    test('une récompense de stat porte sa table par rareté', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());

      expect(vitality.id, 'vitality');
      expect(vitality.effect, RewardEffect.stat);
      expect(vitality.stat, RewardStat.maxHp);
      expect(vitality.pool, RewardPool.draft);
      expect(vitality.amountFor(RewardRarity.epic), 15);
      // Un palier qu'une récompense `draft` ne peut pas atteindre rend 0
      // plutôt que de lever en plein tirage.
      expect(vitality.amountFor(RewardRarity.mythic), 0);
    });

    test('une récompense sans stat déclare son effet propre', () {
      final mirror = LevelUpRewardData.fromJson(mirrorJson());

      expect(mirror.effect, RewardEffect.cloneCard);
      expect(mirror.stat, isNull);
      expect(mirror.pool, RewardPool.mythic);
    });
  });

  group('lectures refusées', () {
    void refuse(Map<String, dynamic> json, String fragment) {
      expect(
        () => LevelUpRewardData.fromJson(json),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', contains(fragment)),
        ),
      );
    }

    test('un effet inconnu', () {
      refuse(vitalityJson()..['effect'] = 'gain_gold', 'effect');
    });

    test('une stat inconnue', () {
      refuse(vitalityJson()..['stat'] = 'charisma', 'stat');
    });

    test('un groupe de tirage inconnu', () {
      refuse(vitalityJson()..['pool'] = 'shop', 'pool');
    });

    test('une récompense de stat sans stat', () {
      refuse(vitalityJson()..remove('stat'), 'stat');
    });

    test('une récompense sans stat qui en déclare une', () {
      refuse(mirrorJson()..['stat'] = 'luck', 'stat');
    });

    test('un palier manquant dans une récompense tirable', () {
      final json = vitalityJson();
      (json['values'] as Map<String, dynamic>).remove('epic');
      refuse(json, 'epic');
    });

    test('un palier inconnu dans la table', () {
      final json = vitalityJson();
      (json['values'] as Map<String, dynamic>)['fabuleux'] = 99;
      refuse(json, 'fabuleux');
    });

    // Les trois suivants rendent vérifiable la règle de `CLAUDE.md` : tout
    // texte joueur porte ses deux langues. Une traduction perdue au passage en
    // donnée doit faire échouer le chargement, pas s'afficher en anglais dans
    // un jeu en français.

    test('un nom sans sa variante anglaise', () {
      refuse(vitalityJson()..remove('name_en'), 'name_en');
    });

    test('une description sans sa variante française', () {
      refuse(vitalityJson()..remove('description_fr'), 'description_fr');
    });

    test('un texte optionnel traduit à moitié', () {
      refuse(affinityJson()..remove('shortDescription_en'), 'shortDescription');
    });
  });

  group('description', () {
    test('{amount} devient la valeur tirée', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());

      expect(vitality.describe('fr', amount: 15), '+15 PV Max');
      expect(vitality.describe('en', amount: 15), '+15 Max HP');
    });

    test('{passive} et {effect} composent avec le passif actif', () {
      final affinity = LevelUpRewardData.fromJson(affinityJson());

      expect(
        affinity.describe('fr', amount: 2, passive: regen(mastery: masteryBlock)),
        "Régénération d'Armure : +2 Armure en fin de tour",
      );
      expect(
        affinity.describe('en', amount: 2, passive: regen(mastery: masteryBlock)),
        'Armor Regeneration: +2 Block at end of turn',
      );
    });

    test('sans passif, ou sans Maîtrise déclarée, le gabarit de repli sert', () {
      final affinity = LevelUpRewardData.fromJson(affinityJson());

      expect(
        affinity.describe('fr', amount: 3),
        '+3 Maîtrise, sans effet sur votre passif',
      );
      expect(
        affinity.describe('fr', amount: 3, passive: regen()),
        '+3 Maîtrise, sans effet sur votre passif',
      );
    });

    test('une description sans placeholder de passif ignore le passif', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());

      expect(
        vitality.describe('fr', amount: 5, passive: regen(mastery: masteryBlock)),
        '+5 PV Max',
      );
    });
  });

  group('libellé court', () {
    test('il sert quand il est déclaré', () {
      final affinity = LevelUpRewardData.fromJson(affinityJson());
      expect(affinity.shortLabel('fr', amount: 3), '+3 Maîtrise');
      expect(affinity.shortLabel('en', amount: 3), '+3 Mastery');
    });

    test('absent, il se rabat sur la description, jamais sur un placeholder', () {
      final vitality = LevelUpRewardData.fromJson(vitalityJson());
      expect(vitality.shortLabel('fr', amount: 10), '+10 PV Max');
      // Le rouleau n'a pas de passif : un `{passive}` qui fuirait à l'écran
      // serait le défaut que ce repli existe pour empêcher.
      expect(vitality.shortLabel('fr', amount: 10), isNot(contains('{')));
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/level_up_reward_data_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'roguelike_card_game/models/data/level_up_reward_data.dart'` (le fichier n'existe pas).

- [ ] **Step 3: Écrire le modèle**

Create `lib/models/data/level_up_reward_data.dart`:

```dart
import 'package:meta/meta.dart';

import '../reward_rarity.dart';
import 'passive_data.dart';

/// Ce que la récompense fait quand le joueur la prend.
enum RewardEffect {
  /// Elle monte une stat du héros, celle que [LevelUpRewardData.stat] désigne.
  stat,

  /// Elle ouvre le clonage d'une carte — le Miroir. Aucune stat.
  cloneCard,
}

/// La stat qu'une récompense [RewardEffect.stat] fait monter.
///
/// [critDamage] s'écrit **en points de pourcentage entiers** : la donnée dit
/// `10`, l'application divise par 100. Le joueur lit déjà « +10 % », et le
/// catalogue reste sans un seul décimal (décision 5 du plan).
enum RewardStat { maxHp, might, mastery, maxMana, luck, critChance, critDamage }

/// D'où la récompense est tirée.
enum RewardPool {
  /// Les trois emplacements du draft, tirés uniformément dans ce groupe.
  draft,

  /// Une option mythique, offerte par son propre jet et ajoutée aux trois.
  mythic,
}

/// Une récompense de niveau, telle que son fichier la déclare
/// (spec P-41, §8.1, décision D3).
///
/// Avant ce chantier, les huit récompenses étaient huit valeurs d'énumération,
/// un `rng.nextInt(6)`, deux `switch` de valeurs et des libellés en ARB,
/// recopiés à la main dans la prose du tutoriel et dans le rouleau du
/// carrousel. Elles sont désormais huit fichiers sous
/// `assets/data/level_up_rewards/`.
@immutable
class LevelUpRewardData {
  final String id;
  final String nameFr;
  final String nameEn;

  /// Le gabarit de description. Trois substitutions possibles : `{amount}`, la
  /// valeur tirée ; `{passive}`, le nom du passif actif ; `{effect}`, ce que la
  /// Maîtrise tirée apporte à ce passif.
  final String descriptionFr;
  final String descriptionEn;

  /// Le gabarit de repli, quand `{passive}` et `{effect}` ne peuvent pas être
  /// résolus — aucun passif actif, ou un passif sans bloc `mastery`. `null` :
  /// il n'y a rien à replier, la description n'en nomme aucun.
  final String? fallbackDescriptionFr;
  final String? fallbackDescriptionEn;

  /// La ligne du rouleau de draft, qui n'a ni passif ni place. `null` : le
  /// rouleau se rabat sur [fallbackDescriptionFr] puis sur [descriptionFr].
  final String? shortDescriptionFr;
  final String? shortDescriptionEn;

  final RewardEffect effect;

  /// La stat montée ; `null` — et seulement — pour un [RewardEffect] qui n'en
  /// monte aucune.
  final RewardStat? stat;

  final RewardPool pool;

  /// La valeur du gain, palier par palier. Une récompense [RewardPool.draft]
  /// porte les cinq paliers tirables ; une mythique de stat porte
  /// [RewardRarity.mythic] seul.
  final Map<RewardRarity, int> values;

  /// Rang de la récompense dans son groupe de tirage. Donnée de présentation,
  /// comme `HeroData.displayOrder` : l'ordre ne doit dépendre ni de l'ordre de
  /// lecture des fichiers ni de l'alphabet.
  final int displayOrder;

  const LevelUpRewardData({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.descriptionFr,
    required this.descriptionEn,
    this.fallbackDescriptionFr,
    this.fallbackDescriptionEn,
    this.shortDescriptionFr,
    this.shortDescriptionEn,
    required this.effect,
    this.stat,
    required this.pool,
    this.values = const {},
    this.displayOrder = 0,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;

  /// La valeur de cette récompense au palier [rarity] ; 0 pour un palier que
  /// sa table ne déclare pas — le Miroir, qui ne monte aucune stat, comme un
  /// palier qu'un groupe de tirage n'atteint jamais.
  int amountFor(RewardRarity rarity) => values[rarity] ?? 0;

  /// La description affichée sur la carte de draft.
  ///
  /// Un gabarit qui nomme `{passive}` ou `{effect}` a besoin d'un passif actif
  /// **qui déclare une Maîtrise** : sans lui, c'est [fallbackDescriptionFr] qui
  /// sert. C'est la règle, unique, qui remplace la branche `case affinity` de
  /// l'ancien `DraftChoiceLabels`.
  String describe(String locale, {required int amount, PassiveData? passive}) {
    final isFr = locale == 'fr';
    final main = isFr ? descriptionFr : descriptionEn;
    final fallback = isFr ? fallbackDescriptionFr : fallbackDescriptionEn;
    final mastery = passive?.mastery;
    final needsPassive = main.contains('{passive}') || main.contains('{effect}');
    final template = needsPassive && mastery == null ? fallback ?? main : main;

    return template
        .replaceAll('{amount}', '$amount')
        .replaceAll('{passive}', passive?.getName(locale) ?? '')
        .replaceAll('{effect}', mastery?.describe(locale, amount) ?? '');
  }

  /// La ligne courte du rouleau. Aucun `{passive}` ni `{effect}` n'y survit :
  /// le rouleau défile sans contexte de run.
  String shortLabel(String locale, {required int amount}) {
    final isFr = locale == 'fr';
    final template = (isFr ? shortDescriptionFr : shortDescriptionEn) ??
        (isFr ? fallbackDescriptionFr : fallbackDescriptionEn) ??
        (isFr ? descriptionFr : descriptionEn);
    return template.replaceAll('{amount}', '$amount');
  }

  static const List<RewardRarity> _draftRarities = [
    RewardRarity.common,
    RewardRarity.uncommon,
    RewardRarity.rare,
    RewardRarity.epic,
    RewardRarity.legendary,
  ];

  static T _readEnum<T extends Enum>(Object? value, List<T> values, String key) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    throw FormatException(
      '$key : valeur "$value" inconnue — attendu : '
      '${values.map((v) => v.name).join(', ')}',
    );
  }

  /// Un texte joueur obligatoire, dans une langue. Absent ou vide : faute de
  /// donnée. La règle de `CLAUDE.md` — deux langues pour tout texte joueur —
  /// n'a de valeur que si le chargement la refuse.
  static String _readText(Map<String, dynamic> json, String key, String id) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$id : "$key" est obligatoire (texte non vide)');
    }
    return value;
  }

  /// Un couple de textes optionnel : les deux langues, ou aucune. Une seule
  /// des deux afficherait du français dans un jeu en anglais, sans que rien ne
  /// le signale.
  static (String?, String?) _readOptionalPair(
    Map<String, dynamic> json,
    String base,
    String id,
  ) {
    final fr = json['${base}_fr'] as String?;
    final en = json['${base}_en'] as String?;
    if ((fr == null) != (en == null)) {
      throw FormatException(
        '$id : "$base" doit porter ses deux langues — ${base}_fr et ${base}_en',
      );
    }
    return (fr, en);
  }

  static Map<RewardRarity, int> _readValues(Object? json, String id) {
    if (json is! Map) {
      throw FormatException('$id : values doit être un objet — reçu : $json');
    }
    return {
      for (final entry in json.entries)
        _readEnum(entry.key, RewardRarity.values, '$id : values')
            : entry.value as int,
    };
  }

  factory LevelUpRewardData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final effect = _readEnum(json['effect'], RewardEffect.values, '$id : effect');
    final pool = _readEnum(json['pool'], RewardPool.values, '$id : pool');
    final statJson = json['stat'];

    final RewardStat? stat;
    if (effect == RewardEffect.stat) {
      if (statJson == null) {
        throw FormatException('$id : stat est obligatoire pour effect "stat"');
      }
      stat = _readEnum(statJson, RewardStat.values, '$id : stat');
    } else {
      if (statJson != null) {
        throw FormatException(
          '$id : stat n\'a pas de sens pour effect "${effect.name}"',
        );
      }
      stat = null;
    }

    final values = _readValues(json['values'] ?? const <String, dynamic>{}, id);

    // Un palier manquant est le defaut exact que ce chantier corrige : une
    // cascade sans palier legendaire faisait retomber un legendaire sur la
    // valeur d'un commun (`level_up_reward_values_test.dart`). En donnee, il
    // doit rougir au chargement, pas au tirage.
    if (pool == RewardPool.draft) {
      for (final rarity in _draftRarities) {
        if (!values.containsKey(rarity)) {
          throw FormatException('$id : values ne déclare pas "${rarity.name}"');
        }
      }
    } else if (effect == RewardEffect.stat &&
        !values.containsKey(RewardRarity.mythic)) {
      throw FormatException('$id : values ne déclare pas "mythic"');
    }

    final (fallbackFr, fallbackEn) =
        _readOptionalPair(json, 'fallbackDescription', id);
    final (shortFr, shortEn) = _readOptionalPair(json, 'shortDescription', id);

    return LevelUpRewardData(
      id: id,
      nameFr: _readText(json, 'name_fr', id),
      nameEn: _readText(json, 'name_en', id),
      descriptionFr: _readText(json, 'description_fr', id),
      descriptionEn: _readText(json, 'description_en', id),
      fallbackDescriptionFr: fallbackFr,
      fallbackDescriptionEn: fallbackEn,
      shortDescriptionFr: shortFr,
      shortDescriptionEn: shortEn,
      effect: effect,
      stat: stat,
      pool: pool,
      values: values,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
```

- [ ] **Step 4: Lancer le test pour le voir passer**

Run: `flutter test test/unit/level_up_reward_data_test.dart`
Expected: `+18: All tests passed!`

- [ ] **Step 5: Vérifier l'ensemble**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1039: All tests passed!` (1021 + 18).

- [ ] **Step 6: Commit**

```bash
git add lib/models/data/level_up_reward_data.dart test/unit/level_up_reward_data_test.dart
git commit -m "feat(recompenses): le modele d une recompense de niveau

Table de valeurs par rarete, libelles bilingues et gabarits a substitution
(amount, passive, effect). Sans lecteur encore : rien du jeu ne change.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Les huit fichiers, la neuvième source, le registre

Le catalogue existe et se charge ; rien ne le lit encore. Le test de cette tâche verrouille la **table de valeurs**, celle-là même que `level_up_reward_values_test.dart` vérifie aujourd'hui sur le code.

**Files:**
- Create: `assets/data/level_up_rewards/vitality.json`, `sharpening.json`, `affinity.json`, `wisdom.json`, `precision.json`, `ferocity.json`, `lucky_clover.json`, `mirror.json`
- Modify: `lib/models/data/game_data_registry.dart`, `lib/services/game_data_service.dart`, `pubspec.yaml`
- Modify (tests) : `test/unit/entity_id_convention_test.dart`, `test/unit/real_bundle_load_test.dart`
- Test: `test/unit/level_up_rewards_catalog_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `LevelUpRewardData.fromJson` (tâche 2).
- Produces: `GameDataRegistry.levelUpRewards` (`List<LevelUpRewardData>`, `const []` par défaut — un défaut, et non un paramètre requis, pour ne pas casser les 36 fichiers qui construisent un registre de test).

- [ ] **Step 1: Écrire les huit fichiers**

Create `assets/data/level_up_rewards/vitality.json`:

```json
{
  "id": "vitality",
  "name_fr": "Vitalité",
  "name_en": "Vitality",
  "description_fr": "+{amount} PV Max",
  "description_en": "+{amount} Max HP",
  "effect": "stat",
  "stat": "maxHp",
  "pool": "draft",
  "displayOrder": 1,
  "values": {
    "common": 5,
    "uncommon": 8,
    "rare": 10,
    "epic": 15,
    "legendary": 20
  }
}
```

Create `assets/data/level_up_rewards/sharpening.json`:

```json
{
  "id": "sharpening",
  "name_fr": "Aiguisage",
  "name_en": "Sharpening",
  "description_fr": "+{amount} Puissance",
  "description_en": "+{amount} Might",
  "effect": "stat",
  "stat": "might",
  "pool": "draft",
  "displayOrder": 2,
  "values": {
    "common": 2,
    "uncommon": 3,
    "rare": 4,
    "epic": 6,
    "legendary": 8
  }
}
```

Create `assets/data/level_up_rewards/affinity.json`:

```json
{
  "id": "affinity",
  "name_fr": "Affinité",
  "name_en": "Affinity",
  "description_fr": "{passive} : {effect}",
  "description_en": "{passive}: {effect}",
  "fallbackDescription_fr": "+{amount} Maîtrise, sans effet sur votre passif",
  "fallbackDescription_en": "+{amount} Mastery, no effect on your passive",
  "shortDescription_fr": "+{amount} Maîtrise",
  "shortDescription_en": "+{amount} Mastery",
  "effect": "stat",
  "stat": "mastery",
  "pool": "draft",
  "displayOrder": 3,
  "values": {
    "common": 1,
    "uncommon": 2,
    "rare": 3,
    "epic": 5,
    "legendary": 7
  }
}
```

Create `assets/data/level_up_rewards/wisdom.json`:

```json
{
  "id": "wisdom",
  "name_fr": "Sagesse",
  "name_en": "Wisdom",
  "description_fr": "+{amount} Mana Max",
  "description_en": "+{amount} Max Mana",
  "effect": "stat",
  "stat": "maxMana",
  "pool": "draft",
  "displayOrder": 4,
  "values": {
    "common": 1,
    "uncommon": 2,
    "rare": 2,
    "epic": 3,
    "legendary": 4
  }
}
```

> Le plateau de *Sagesse* entre `uncommon` et `rare` est **recopié tel quel** : il vient de `round(1 × 1,5)` et `round(1 × 2,0)`, et son rééquilibrage appartient à P-16 (spec §8.4).

Create `assets/data/level_up_rewards/precision.json`:

```json
{
  "id": "precision",
  "name_fr": "Précision",
  "name_en": "Precision",
  "description_fr": "+{amount}% de chance de Critique",
  "description_en": "+{amount}% Critical chance",
  "effect": "stat",
  "stat": "critChance",
  "pool": "draft",
  "displayOrder": 5,
  "values": {
    "common": 1,
    "uncommon": 2,
    "rare": 3,
    "epic": 4,
    "legendary": 5
  }
}
```

Create `assets/data/level_up_rewards/ferocity.json`:

```json
{
  "id": "ferocity",
  "name_fr": "Férocité",
  "name_en": "Ferocity",
  "description_fr": "+{amount}% de dégâts de Critique",
  "description_en": "+{amount}% Critical damage",
  "effect": "stat",
  "stat": "critDamage",
  "pool": "draft",
  "displayOrder": 6,
  "values": {
    "common": 10,
    "uncommon": 20,
    "rare": 30,
    "epic": 40,
    "legendary": 50
  }
}
```

> `critDamage` s'écrit en **points de pourcentage** (décision 5) : `10` ici vaut `+0.10` sur `critMultiplier`, et c'est l'application qui divise.

Create `assets/data/level_up_rewards/lucky_clover.json`:

```json
{
  "id": "lucky_clover",
  "name_fr": "Trèfle à 4 feuilles",
  "name_en": "Four-Leaf Clover",
  "description_fr": "+{amount} Chance",
  "description_en": "+{amount} Luck",
  "effect": "stat",
  "stat": "luck",
  "pool": "mythic",
  "displayOrder": 7,
  "values": {
    "mythic": 1
  }
}
```

Create `assets/data/level_up_rewards/mirror.json`:

```json
{
  "id": "mirror",
  "name_fr": "Miroir",
  "name_en": "Mirror",
  "description_fr": "Cloner une carte au choix parmi 3 cartes aléatoires de votre deck",
  "description_en": "Clone one card of your choice among 3 random cards from your deck",
  "shortDescription_fr": "Cloner une carte",
  "shortDescription_en": "Clone a card",
  "effect": "cloneCard",
  "pool": "mythic",
  "displayOrder": 8,
  "values": {}
}
```

- [ ] **Step 2: Déclarer le répertoire au pubspec**

Run: `dart run tool/sync_assets.dart`
Expected: la section `assets:` gagne la ligne `- assets/data/level_up_rewards/`, rangée alphabétiquement entre `- assets/data/forge_upgrades/` et `- assets/data/passives/`.

Run: `dart run tool/sync_assets.dart --check`
Expected: sortie de succès, code de retour 0.

- [ ] **Step 3: Écrire le test qui échoue**

Create `test/unit/level_up_rewards_catalog_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le catalogue des récompenses de niveau, lu depuis le vrai bundle
/// (spec P-41, §8.1).
///
/// Ce test regarde la **donnée** ; `level_up_reward_values_test.dart` regarde
/// ce que le tirage en fait. Les deux verrouillent la même table : l'un au
/// chargement, l'autre à l'usage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// La table d'aujourd'hui, à valeurs identiques (spec §8.1 : « à valeurs
  /// identiques »). Le plateau de Sagesse entre `uncommon` et `rare` est
  /// assumé et appartient à P-16 (§8.4).
  const attendu = <String, Map<RewardRarity, int>>{
    'vitality': {
      RewardRarity.common: 5,
      RewardRarity.uncommon: 8,
      RewardRarity.rare: 10,
      RewardRarity.epic: 15,
      RewardRarity.legendary: 20,
    },
    'sharpening': {
      RewardRarity.common: 2,
      RewardRarity.uncommon: 3,
      RewardRarity.rare: 4,
      RewardRarity.epic: 6,
      RewardRarity.legendary: 8,
    },
    'affinity': {
      RewardRarity.common: 1,
      RewardRarity.uncommon: 2,
      RewardRarity.rare: 3,
      RewardRarity.epic: 5,
      RewardRarity.legendary: 7,
    },
    'wisdom': {
      RewardRarity.common: 1,
      RewardRarity.uncommon: 2,
      RewardRarity.rare: 2,
      RewardRarity.epic: 3,
      RewardRarity.legendary: 4,
    },
    'precision': {
      RewardRarity.common: 1,
      RewardRarity.uncommon: 2,
      RewardRarity.rare: 3,
      RewardRarity.epic: 4,
      RewardRarity.legendary: 5,
    },
    'ferocity': {
      RewardRarity.common: 10,
      RewardRarity.uncommon: 20,
      RewardRarity.rare: 30,
      RewardRarity.epic: 40,
      RewardRarity.legendary: 50,
    },
  };

  test('les huit récompenses se chargent depuis le vrai bundle', () async {
    final registry = await loadGameDataRegistry(rootBundle);

    expect(registry.levelUpRewards, hasLength(8));
    expect(
      registry.levelUpRewards.map((r) => r.id).toSet(),
      {...attendu.keys, 'lucky_clover', 'mirror'},
    );
  });

  test('les six récompenses tirables portent la table d aujourd hui', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final byId = {for (final r in registry.levelUpRewards) r.id: r};

    for (final entree in attendu.entries) {
      final reward = byId[entree.key];
      expect(reward, isNotNull, reason: entree.key);
      expect(reward!.pool, RewardPool.draft, reason: entree.key);
      for (final palier in entree.value.entries) {
        expect(
          reward.amountFor(palier.key),
          palier.value,
          reason: '${entree.key} en ${palier.key.name}',
        );
      }
    }
  });

  test('les deux mythiques sont hors du tirage des trois emplacements', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final mythiques = registry.levelUpRewards
        .where((r) => r.pool == RewardPool.mythic)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    expect(mythiques.map((r) => r.id), ['lucky_clover', 'mirror']);
    expect(mythiques.first.amountFor(RewardRarity.mythic), 1);
    expect(mythiques.last.effect, RewardEffect.cloneCard);
  });

  test('les huit récompenses portent leurs deux langues', () async {
    // La règle de `CLAUDE.md`, vérifiée sur les vrais fichiers : les libellés
    // quittent les ARB, les traductions les suivent. `fromJson` refuse déjà un
    // `_fr` sans son `_en` ; ce test-ci vérifie que le catalogue livré n'a pas
    // de texte français recopié tel quel côté anglais.
    final registry = await loadGameDataRegistry(rootBundle);

    for (final reward in registry.levelUpRewards) {
      expect(reward.nameFr, isNotEmpty, reason: reward.id);
      expect(reward.nameEn, isNotEmpty, reason: reward.id);
      expect(
        reward.describe('fr', amount: 1),
        isNot(reward.describe('en', amount: 1)),
        reason: '${reward.id} : la description anglaise n\'est pas traduite',
      );
    }
  });

  test('le rang de tirage est déclaré, unique et sans trou', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final rangs = registry.levelUpRewards.map((r) => r.displayOrder).toList()
      ..sort();

    // L'ancien `rng.nextInt(6)` tirait un index : l'ordre des valeurs de
    // l'enum EN ETAIT la sémantique. En donnée, ce rang doit être déclaré,
    // pas hérité de l'ordre de lecture du disque.
    expect(rangs, [1, 2, 3, 4, 5, 6, 7, 8]);
  });
}
```

- [ ] **Step 4: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/level_up_rewards_catalog_test.dart`
Expected: FAIL — `The getter 'levelUpRewards' isn't defined for the class 'GameDataRegistry'`.

- [ ] **Step 5: Ajouter le champ au registre**

Edit `lib/models/data/game_data_registry.dart` : ajouter l'import `import 'level_up_reward_data.dart';`, le champ, et le paramètre du constructeur.

```dart
  final List<ForgeUpgradeData> forgeUpgrades;

  /// Les récompenses de niveau (spec P-41, §8.1). Défaut vide, et non
  /// paramètre requis : trente-six fichiers construisent un registre de test
  /// qui ne draftera jamais.
  final List<LevelUpRewardData> levelUpRewards;

  final AudioData audio;
```

```dart
    required this.forgeUpgrades,
    this.levelUpRewards = const [],
    this.audio = const AudioData.disabled(),
```

- [ ] **Step 6: Déclarer la neuvième source**

Edit `lib/services/game_data_service.dart` : ajouter l'import `import '../models/data/level_up_reward_data.dart';`, puis, entre le bloc `forgeUpgrades` et le bloc `passives` :

```dart
  // Les recompenses de niveau (spec P-41, §8.1, decision D3). A plat, comme
  // les reliques : une recompense n appartient a aucune classe. Le repertoire
  // n injecte donc que l id.
  final levelUpRewards = await loader.loadAll<LevelUpRewardData>([
    EntitySource('assets/data/level_up_rewards/*.json', LevelUpRewardData.fromJson,
        inject: (c) => {'id': c[0]}),
  ]);
```

et, dans le `return GameDataRegistry(...)`, après `forgeUpgrades: forgeUpgrades,` :

```dart
    levelUpRewards: levelUpRewards,
```

Mettre aussi à jour la phrase du doc-comment de `loadGameDataRegistry` : « **Unique declaration des huit sources du jeu** » devient « **des neuf sources du jeu** ».

- [ ] **Step 7: Lancer le test pour le voir passer**

Run: `flutter test test/unit/level_up_rewards_catalog_test.dart`
Expected: `+5: All tests passed!`

- [ ] **Step 8: Mettre à jour les deux comptes de fichiers d'entité**

Run: `flutter test test/unit/entity_id_convention_test.dart test/unit/real_bundle_load_test.dart`
Expected: FAIL — `Expected: <77> Actual: <85>`.

Edit `test/unit/entity_id_convention_test.dart`, troisième test : remplacer le nom du test et son contenu.

```dart
  test('il y a bien 85 fichiers d entite', () {
    // 17 cartes neutres + 25 reliques + 5 evenements + 8 ameliorations de
    // forge + 9 passifs + 8 recompenses de niveau + 3 class.json + 6 cartes
    // de classe + 4 enemy.json.
    expect(_entityFiles().length, 85,
        reason: '17 cartes neutres + 25 reliques + 5 evenements + 8 '
            'ameliorations de forge + 9 passifs + 8 recompenses de niveau + '
            '3 class.json + 6 cartes de classe + 4 enemy.json');
  });
```

Edit `test/unit/real_bundle_load_test.dart` : renommer le premier test en `'le manifeste declare les 85 fichiers d entite, par categorie'` et ajouter, après la ligne des passifs :

```dart
    expect(countUnder('assets/data/level_up_rewards/', 4), 8,
        reason: 'recompenses de niveau');
```

**Important** : si ces comptes restent faux après la correction, c'est que `build/unit_test_assets/` porte des fichiers fantômes. `flutter test` ne purge jamais ce répertoire — supprimer `build/unit_test_assets/assets/data/` et relancer.

- [ ] **Step 9: Vérifier l'ensemble**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1044: All tests passed!` (1039 + 5).

- [ ] **Step 10: Commit**

```bash
git add assets/data/level_up_rewards pubspec.yaml lib/models/data/game_data_registry.dart lib/services/game_data_service.dart test/unit/level_up_rewards_catalog_test.dart test/unit/entity_id_convention_test.dart test/unit/real_bundle_load_test.dart
git commit -m "feat(recompenses): huit fichiers, une neuvieme source d entites

Les huit recompenses de niveau sont desormais du contenu. Rien ne les lit
encore : le tirage suit. 77 fichiers d entite deviennent 85.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Le tirage et les libellés lisent la donnée

**C'est la tâche qui porte le critère d'acceptation de cette partie** (spec §8.1) : `level_up_reward_values_test.dart` devient un test sur la donnée et continue de verrouiller les 30 combinaisons, à valeurs identiques.

Le tirage et les libellés changent **ensemble** et non l'un après l'autre : supprimer `LevelUpRewardType` casse `DraftChoiceLabels` dans le même mouvement, et l'invariant « chaque tâche laisse la suite verte » interdit de les séparer.

**Files:**
- Modify: `lib/game/services/level_up_reward_service.dart`, `lib/ui/widgets/draft/draft_choice_labels.dart`, `lib/ui/screens/draft_screen.dart`, `lib/tutorial/widgets/tutorial_draft_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`
- Regenerate: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`
- Test: `test/unit/level_up_reward_values_test.dart` *(réécrit)*, `test/unit/draft_choice_labels_test.dart` *(réécrit)*

**Interfaces:**
- Consumes: `LevelUpRewardData`, `RewardEffect`, `RewardPool`, `RewardStat` (tâche 2) ; `GameDataRegistry.levelUpRewards` (tâche 3).
- Produces:
  - `class DraftChoice` — champs `LevelUpRewardData data`, `RewardRarity rarity`, `int amount` ; constructeur `const DraftChoice({required this.data, required this.rarity, required this.amount})` ; getter `bool get isCloneOption`.
  - `static List<DraftChoice> LevelUpRewardService.generateChoices({required List<LevelUpRewardData> rewards, required int luck, bool forceLegendary = false})`.
  - `LevelUpRewardService.rollRarity` **inchangé**, signature comprise.
  - `LevelUpRewardType` **supprimé**.
  - `DraftChoiceLabels.getChoiceTitle(AppLocalizations, DraftChoice)` et `getChoiceDescription(AppLocalizations, DraftChoice, {PassiveData? passive})` — signatures inchangées, corps réduit à une délégation.

- [ ] **Step 1: Réécrire le test de valeurs — le critère d'acceptation**

Replace `test/unit/level_up_reward_values_test.dart` entirely:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Verrouille la valeur de chaque récompense de draft, palier de rareté par
/// palier de rareté — **sur la donnée** désormais (spec P-41, §8.1).
///
/// Rien ne couvrait ces valeurs avant que ce fichier n'existe :
/// `probabilities_test.dart` ne teste que les probabilités de tirage, jamais
/// l'ampleur du gain. C'est ce trou qui a laissé la Forge d'Acier — aujourd'hui
/// l'Affinité — légendaire retomber sur la valeur d'un commun (+1 Maîtrise au
/// lieu de +7), sans que rien ne le signale.
///
/// Ce que ce fichier prouve maintenant, en plus : ce que le **tirage** rend est
/// bien ce que la **donnée** déclare. `level_up_rewards_catalog_test.dart`
/// verrouille la donnée elle-même.

/// La table attendue, une entrée par récompense tirable et par rareté.
/// Recopiée à l'identique de la version qui lisait le code : c'est la clause
/// « à valeurs identiques » de la spec.
const Map<String, Map<RewardRarity, int>> _attendu = {
  'vitality': {
    RewardRarity.common: 5,
    RewardRarity.uncommon: 8,
    RewardRarity.rare: 10,
    RewardRarity.epic: 15,
    RewardRarity.legendary: 20,
  },
  'sharpening': {
    RewardRarity.common: 2,
    RewardRarity.uncommon: 3,
    RewardRarity.rare: 4,
    RewardRarity.epic: 6,
    RewardRarity.legendary: 8,
  },
  'affinity': {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 3,
    RewardRarity.epic: 5,
    RewardRarity.legendary: 7,
  },
  // Sagesse plafonne à 2 sur deux paliers consécutifs : `round(1 × 1,5)` et
  // `round(1 × 2,0)` donnaient tous deux 2. Comportement existant, recopié
  // dans `wisdom.json` tel quel plutôt que corrigé au passage (spec §8.4).
  'wisdom': {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 2,
    RewardRarity.epic: 3,
    RewardRarity.legendary: 4,
  },
  'precision': {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 3,
    RewardRarity.epic: 4,
    RewardRarity.legendary: 5,
  },
  // En points de pourcentage : la donnée écrit ce que le joueur lit, et
  // l'application divise par 100 (décision 5 du plan).
  'ferocity': {
    RewardRarity.common: 10,
    RewardRarity.uncommon: 20,
    RewardRarity.rare: 30,
    RewardRarity.epic: 40,
    RewardRarity.legendary: 50,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<LevelUpRewardData> rewards;

  setUpAll(() async {
    rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
  });

  group('Valeurs de récompense par palier de rareté', () {
    test('la table est respectée sur les 30 combinaisons', () {
      // `generateChoices` tire sa récompense et sa rareté au hasard. On balaie
      // assez large pour voir les 30 combinaisons : la plus rare est un
      // légendaire d'une récompense donnée, à environ 0,33 % par choix à
      // chance 0, soit ~100 occurrences attendues sur 30 000 tirages.
      final observe = <String, Map<RewardRarity, Set<int>>>{};

      for (var i = 0; i < 10000; i++) {
        for (final choix
            in LevelUpRewardService.generateChoices(rewards: rewards, luck: 0)) {
          if (choix.data.pool != RewardPool.draft) continue;
          observe
              .putIfAbsent(choix.data.id, () => {})
              .putIfAbsent(choix.rarity, () => {})
              .add(choix.amount);
        }
      }

      for (final entree in _attendu.entries) {
        final id = entree.key;
        expect(
          observe[id],
          isNotNull,
          reason: '$id n\'a jamais été tirée sur 30 000 choix',
        );

        for (final palier in entree.value.entries) {
          final valeurs = observe[id]![palier.key];
          expect(
            valeurs,
            isNotNull,
            reason: '$id en ${palier.key.name} n\'a jamais été tirée',
          );
          expect(
            valeurs,
            hasLength(1),
            reason: '$id en ${palier.key.name} rend plusieurs valeurs : $valeurs',
          );
          expect(valeurs!.single, palier.value, reason: '$id en ${palier.key.name}');
        }
      }
    });

    test('les six récompenses tirables sont toutes atteignables', () {
      // L'ancien `rng.nextInt(6)` garantissait ce compte par construction.
      // En donnée, une récompense mal rangée le briserait en silence.
      final tirees = <String>{};
      for (var i = 0; i < 2000; i++) {
        for (final choix
            in LevelUpRewardService.generateChoices(rewards: rewards, luck: 0)) {
          if (choix.data.pool == RewardPool.draft) tirees.add(choix.data.id);
        }
      }
      expect(tirees, _attendu.keys.toSet());
    });

    test('chaque récompense progresse strictement avec la rareté', () {
      // L'invariant que le bug violait : un légendaire donnait moins qu'un
      // épique, et exactement autant qu'un commun.
      const ordre = [
        RewardRarity.common,
        RewardRarity.uncommon,
        RewardRarity.rare,
        RewardRarity.epic,
        RewardRarity.legendary,
      ];

      for (final entree in _attendu.entries) {
        // Sagesse a un plateau assumé entre peu commun et rare.
        final strict = entree.key != 'wisdom';

        for (var i = 1; i < ordre.length; i++) {
          final precedent = entree.value[ordre[i - 1]]!;
          final courant = entree.value[ordre[i]]!;
          expect(
            courant,
            strict ? greaterThan(precedent) : greaterThanOrEqualTo(precedent),
            reason:
                '${entree.key} : ${ordre[i].name} ($courant) ne devrait pas '
                'être sous ${ordre[i - 1].name} ($precedent)',
          );
        }
      }
    });

    test('une chance très élevée force le légendaire sur les trois choix', () {
      // `legendaryChance = 2 + luck × 0,5` dépasse 100 dès `luck: 200` : le
      // tirage est alors déterministe, ce qui donne un test non statistique
      // du palier qui était cassé.
      for (var i = 0; i < 50; i++) {
        final choix =
            LevelUpRewardService.generateChoices(rewards: rewards, luck: 200);
        for (final c in choix.take(3)) {
          expect(c.rarity, RewardRarity.legendary);
          final attendu = _attendu[c.data.id]?[RewardRarity.legendary];
          if (attendu == null) continue;
          expect(c.amount, attendu, reason: c.data.id);
        }
      }
    });

    test('l\'Affinité légendaire vaut plus que l\'épique', () {
      // Non-régression directe du défaut trouvé : la cascade de `if` sans
      // palier légendaire renvoyait 1, soit la valeur d'un commun.
      final affinity = _attendu['affinity']!;
      expect(
        affinity[RewardRarity.legendary],
        greaterThan(affinity[RewardRarity.epic]!),
      );
      expect(
        affinity[RewardRarity.legendary],
        isNot(affinity[RewardRarity.common]),
      );
    });
  });

  group('Les mythiques restent une surprise', () {
    // Ce que le passage en donnée ne doit surtout pas changer : le Trèfle et
    // le Miroir n'entrent jamais dans la table des trois emplacements, et
    // chacun a son propre jet, à 0,5 % à chance nulle. Avant ce chantier, les
    // deux étaient construits hors du tirage, ce qui le garantissait par
    // construction ; en donnée, c'est `pool` qui le garantit — donc un test.

    test('les trois emplacements ne contiennent jamais un mythique', () {
      for (var i = 0; i < 5000; i++) {
        final choix =
            LevelUpRewardService.generateChoices(rewards: rewards, luck: 0);
        expect(choix.length, greaterThanOrEqualTo(3));
        for (final c in choix.take(3)) {
          expect(c.data.pool, RewardPool.draft, reason: c.data.id);
          expect(c.rarity, isNot(RewardRarity.mythic), reason: c.data.id);
        }
      }
    });

    test('chaque mythique a son propre jet, à environ 0,5 % à chance nulle', () {
      // `mythicChance = 0,5 + chance × 0,15`, et `rollRarity` est appelée une
      // fois par récompense mythique : ~100 occurrences attendues sur 20 000
      // tirages, écart-type ~10. Les bornes sont larges — elles ne visent pas
      // la précision statistique mais une dérive d'un ordre de grandeur : un
      // mythique versé dans la table des trois, ou un jet perdu.
      const tirages = 20000;
      final comptes = <String, int>{'lucky_clover': 0, 'mirror': 0};

      for (var i = 0; i < tirages; i++) {
        for (final c in LevelUpRewardService.generateChoices(
          rewards: rewards,
          luck: 0,
        ).skip(3)) {
          comptes[c.data.id] = (comptes[c.data.id] ?? 0) + 1;
        }
      }

      for (final entree in comptes.entries) {
        expect(
          entree.value,
          inInclusiveRange(30, 220),
          reason: '${entree.key} : ${entree.value} sur $tirages tirages, '
              'attendu ~100 (0,5 %)',
        );
      }
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/level_up_reward_values_test.dart`
Expected: FAIL — `The named parameter 'rewards' isn't defined` sur `generateChoices`.

- [ ] **Step 3: Réécrire le service**

Replace the body of `lib/game/services/level_up_reward_service.dart` (garder `rollRarity` **mot pour mot** — elle ne change pas) :

```dart
import 'dart:math';

import '../../models/data/level_up_reward_data.dart';
import '../../models/reward_rarity.dart';

/// Une récompense tirée : ce qu'elle est, à quel palier, et pour combien.
///
/// Avant P-41 lot C, cette classe portait sept accumulateurs (`pvBoost`,
/// `mightBoost`, …) dont un seul était non nul à la fois, plus un `type`
/// d'énumération. La récompense étant devenue de la donnée, elle porte la
/// donnée.
class DraftChoice {
  final LevelUpRewardData data;
  final RewardRarity rarity;

  /// La valeur du gain à ce palier. Pour `RewardStat.critDamage`, en points de
  /// pourcentage : c'est l'application qui divise par 100.
  final int amount;

  const DraftChoice({
    required this.data,
    required this.rarity,
    required this.amount,
  });

  /// Le Miroir : la seule récompense qui ouvre une modale au lieu de monter
  /// une stat.
  bool get isCloneOption => data.effect == RewardEffect.cloneCard;
}

/// Tire les choix de récompense offerts à la montée de niveau, depuis le
/// catalogue de `assets/data/level_up_rewards/` (spec P-41, §8.1). Pur et sans
/// état, pour se tester directement.
class LevelUpRewardService {
  const LevelUpRewardService._();

  // >>> `rollRarity` NE CHANGE PAS. Laisser la methode exactement telle
  // >>> qu'elle est aujourd'hui dans le fichier, corps compris : signature,
  // >>> seuils, multiplicateurs de chance, ordre des tests. Ne pas la
  // >>> retaper, ne pas la deplacer. `probabilities_test.dart` l'echantillonne
  // >>> et rougirait au moindre ecart.
  static RewardRarity rollRarity(
    int luck, {
    bool canBeLegendary = true,
    bool isLevelReward = false,
    bool forceLegendary = false,
  }) { /* corps existant, intact */ }

  /// Les récompenses d'un groupe, dans l'ordre que la donnée déclare.
  ///
  /// `displayOrder` puis `id` : l'ancien `rng.nextInt(6)` tirait un **index**
  /// dans l'ordre des valeurs de l'énumération. Un tirage qui dépendrait de
  /// l'ordre de lecture des fichiers serait un piège silencieux ; l'`id`
  /// tranche à rang égal.
  static List<LevelUpRewardData> _inPool(
    List<LevelUpRewardData> rewards,
    RewardPool pool,
  ) =>
      rewards.where((reward) => reward.pool == pool).toList()
        ..sort((a, b) {
          final byOrder = a.displayOrder.compareTo(b.displayOrder);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });

  static List<DraftChoice> generateChoices({
    required List<LevelUpRewardData> rewards,
    required int luck,
    bool forceLegendary = false,
  }) {
    final rng = Random();
    final draftable = _inPool(rewards, RewardPool.draft);
    // Un registre de test sans récompenses : trois emplacements vides valent
    // mieux qu'une exception au milieu d'une montée de niveau.
    if (draftable.isEmpty) return const [];

    final choices = List.generate(3, (index) {
      final RewardRarity rarity;
      if (forceLegendary) {
        rarity = switch (index) {
          0 => RewardRarity.uncommon,
          1 => RewardRarity.epic,
          _ => RewardRarity.legendary,
        };
      } else {
        rarity = rollRarity(luck, canBeLegendary: true, isLevelReward: false);
      }

      final reward = draftable[rng.nextInt(draftable.length)];
      return DraftChoice(
        data: reward,
        rarity: rarity,
        amount: reward.amountFor(rarity),
      );
    });

    // Un jet indépendant par récompense mythique, dans l'ordre déclaré — c'est
    // exactement ce que faisaient les deux blocs écrits en dur, Trèfle puis
    // Miroir. Une troisième mythique n'est plus qu'un fichier.
    for (final mythic in _inPool(rewards, RewardPool.mythic)) {
      final rolled = rollRarity(
        luck,
        isLevelReward: true,
        forceLegendary: forceLegendary,
      );
      if (rolled == RewardRarity.mythic) {
        choices.add(
          DraftChoice(
            data: mythic,
            rarity: RewardRarity.mythic,
            amount: mythic.amountFor(RewardRarity.mythic),
          ),
        );
      }
    }

    return choices;
  }
}
```

`LevelUpRewardType` disparaît entièrement, ainsi que le `switch` de multiplicateurs, le `rng.nextInt(6)` et les deux `switch` de valeurs d'*Affinité*, de *Précision* et de *Férocité*.

- [ ] **Step 4: Réduire `DraftChoiceLabels` à une délégation**

Replace the two methods in `lib/ui/widgets/draft/draft_choice_labels.dart` (garder `rarityToString` inchangée) :

```dart
  /// Titre affiché pour ce choix de draft.
  static String getChoiceTitle(AppLocalizations l10n, DraftChoice choice) =>
      choice.data.getName(l10n.localeName);

  /// Description (avec la valeur du gain) affichée pour ce choix de draft.
  ///
  /// [passive] est le passif actif : une récompense dont le gabarit nomme
  /// `{passive}` ou `{effect}` se décrit par ce que la Maîtrise tirée lui
  /// apporte — c'est le cas d'*Affinité* (spec P-49, §6.5). Les autres
  /// l'ignorent, sans qu'aucune branche ne les distingue.
  static String getChoiceDescription(
    AppLocalizations l10n,
    DraftChoice choice, {
    PassiveData? passive,
  }) =>
      choice.data.describe(
        l10n.localeName,
        amount: choice.amount,
        passive: passive,
      );
```

Retirer alors l'import devenu inutile de `level_up_reward_service.dart` **seulement si** `DraftChoice` n'y est plus référencé — il l'est, dans les deux signatures : le garder. `dart analyze` tranchera.

- [ ] **Step 5: Passer le registre aux deux appelants du tirage**

Edit `lib/ui/screens/draft_screen.dart`, dans `initState` :

```dart
    _choices = LevelUpRewardService.generateChoices(
      rewards: ref.read(gameDataLoaderProvider).requireValue.levelUpRewards,
      luck: ref.read(runProvider).heroStats.luck,
      forceLegendary: widget.forceLegendary,
    );
```

Ajouter l'import de `game_data_service.dart` si absent (`import '../../services/game_data_service.dart';`).

Edit `lib/tutorial/widgets/tutorial_draft_widget.dart`, ligne 41 :

```dart
    _choices = LevelUpRewardService.generateChoices(
      rewards: widget.engine.data.levelUpRewards,
      luck: 0,
    );
```

`TutorialEngine.data` est le registre déjà porté par le moteur (`tutorial_engine.dart:89`) : **aucune** nouvelle voie d'accès, donc aucun risque vis-à-vis d'ADR-081 et de `tutorial_isolation_test.dart`.

- [ ] **Step 6: Réécrire le test des libellés**

Replace `test/unit/draft_choice_labels_test.dart` entirely:

```dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/draft/draft_choice_labels.dart';

/// Les libellés d'un choix de draft viennent de la donnée (spec P-41, §8.1) ;
/// Affinité se décrit par le passif actif (spec P-49, §6.5).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  late Map<String, LevelUpRewardData> byId;

  setUpAll(() async {
    final registry = await loadGameDataRegistry(rootBundle);
    byId = {for (final r in registry.levelUpRewards) r.id: r};
  });

  DraftChoice choice(String id, RewardRarity rarity) {
    final data = byId[id]!;
    return DraftChoice(data: data, rarity: rarity, amount: data.amountFor(rarity));
  }

  PassiveData regen({int perPoint = 1}) => PassiveData(
        id: 'regen_armor',
        nameEn: 'Armor Regeneration',
        nameFr: "Régénération d'Armure",
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: PassiveMastery(
          field: 'value',
          perPoint: perPoint,
          descriptionEn: '+{amount} Block at end of turn',
          descriptionFr: '+{amount} Armure en fin de tour',
        ),
      );

  test('le titre vient du nom déclaré, dans les deux langues', () {
    final affinity = choice('affinity', RewardRarity.uncommon);
    expect(DraftChoiceLabels.getChoiceTitle(fr, affinity), 'Affinité');
    expect(DraftChoiceLabels.getChoiceTitle(en, affinity), 'Affinity');
  });

  test('la description : le passif actif et l effet de la Maitrise tiree', () {
    final affinity = choice('affinity', RewardRarity.uncommon); // +2
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity, passive: regen()),
      "Régénération d'Armure : +2 Armure en fin de tour",
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(en, affinity, passive: regen()),
      'Armor Regeneration: +2 Block at end of turn',
    );
  });

  test('perPoint multiplie la valeur tiree', () {
    final affinity = choice('affinity', RewardRarity.uncommon); // +2
    expect(
      DraftChoiceLabels.getChoiceDescription(
        fr,
        affinity,
        passive: regen(perPoint: 2),
      ),
      "Régénération d'Armure : +4 Armure en fin de tour",
    );
  });

  test('sans passif actif, le gabarit de repli est rendu', () {
    final affinity = choice('affinity', RewardRarity.rare); // +3
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity),
      '+3 Maîtrise, sans effet sur votre passif',
    );
  });

  test('une récompense de stat rend sa valeur tirée', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, choice('vitality', RewardRarity.epic)),
      '+15 PV Max',
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(en, choice('ferocity', RewardRarity.legendary)),
      '+50% Critical damage',
    );
  });

  test('aucun libellé rendu ne laisse fuir un placeholder', () {
    for (final reward in byId.values) {
      for (final rarity in RewardRarity.values) {
        final rendu = DraftChoiceLabels.getChoiceDescription(
          fr,
          DraftChoice(
            data: reward,
            rarity: rarity,
            amount: reward.amountFor(rarity),
          ),
          passive: regen(),
        );
        expect(rendu, isNot(contains('{')), reason: '${reward.id} / ${rarity.name}');
      }
    }
  });
}
```

- [ ] **Step 7: Retirer les 17 clés ARB et régénérer**

Edit `lib/l10n/app_fr.arb` : supprimer les lignes `draftChoiceVitality`, `draftChoiceVitalityDesc`, `draftChoiceSharpening`, `draftChoiceSharpeningDesc`, `draftChoiceAffinity`, `draftChoiceAffinityDesc`, `draftChoiceAffinityNoEffect`, `draftChoiceWisdom`, `draftChoiceWisdomDesc`, `draftChoiceClover`, `draftChoiceCloverDesc`, `draftChoiceMirror`, `draftChoiceMirrorDesc`, `draftChoicePrecision`, `draftChoicePrecisionDesc`, `draftChoiceFerocity`, `draftChoiceFerocityDesc`.

Edit `lib/l10n/app_en.arb` : supprimer les **mêmes 17 clés** et, pour chacune, le bloc `"@<clé>": { ... }` qui la suit. `app_en.arb` est le gabarit : une clé laissée là sans traduction française ferait rougir `gen-l10n`.

**Ne pas toucher** aux clés `rarityCommon`, `rarityUncommon`, `rarityRare`, `rarityEpic`, `rarityLegendary` : la rareté n'est pas une récompense.

Run: `flutter gen-l10n`
Expected: aucune erreur ; les trois fichiers générés perdent les 17 getters.

- [ ] **Step 8: Lancer les tests**

Run: `flutter test test/unit/level_up_reward_values_test.dart test/unit/draft_choice_labels_test.dart`
Expected: `+13: All tests passed!` (7 + 6).

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1048: All tests passed!` (1044 − 4 − 5 + 7 + 6).

Si `test/widget/draft_screen_test.dart` rougit : il construit ses propres `DraftChoice` ou surveille `LevelUpRewardType`. L'adapter à la nouvelle forme — en lui donnant le registre réel par `loadGameDataRegistry(rootBundle)`, comme les deux fichiers ci-dessus — **sans changer ce qu'il vérifie**, et réajuster la prévision en conséquence.

- [ ] **Step 9: Commit**

```bash
git add lib/game/services/level_up_reward_service.dart lib/ui/widgets/draft/draft_choice_labels.dart lib/ui/screens/draft_screen.dart lib/tutorial/widgets/tutorial_draft_widget.dart lib/l10n test/unit/level_up_reward_values_test.dart test/unit/draft_choice_labels_test.dart test/widget/draft_screen_test.dart
git commit -m "feat(recompenses): le tirage et les libelles lisent la donnee

LevelUpRewardType, le rng.nextInt(6), les trois switch de valeurs et 17 cles
ARB disparaissent. Les 30 combinaisons restent verrouillees, a valeurs
identiques : c est le critere d acceptation du 8.1.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: L'application du gain quitte l'écran de draft

**Files:**
- Modify: `lib/game/controllers/run/player_stats_manager.dart`, `lib/game/controllers/run_controller.dart`, `lib/ui/screens/draft_screen.dart`
- Test: `test/unit/level_up_reward_apply_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `DraftChoice` (tâche 4), `RewardStat` (tâche 2).
- Produces: `void PlayerStatsManager.applyLevelUpReward(DraftChoice choice)` et sa façade `void RunController.applyLevelUpReward(DraftChoice choice)`. `applyHeroStatModifier` reste inchangée et publique : le manipulateur de run de la console de debug s'en sert.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/level_up_reward_apply_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Chaque récompense de niveau monte la stat que sa donnée désigne
/// (spec P-41, §8.1).
///
/// L'ancienne version composait sept accumulateurs dans `DraftScreen` : une
/// stat ajoutée sans être appliquée n'aurait fait rougir personne. Le `switch`
/// exhaustif sur `RewardStat` ne compile plus dans ce cas, et ce fichier
/// vérifie la correspondance stat par stat.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, LevelUpRewardData> byId;

  setUpAll(() async {
    byId = {
      for (final r in (await loadGameDataRegistry(rootBundle)).levelUpRewards)
        r.id: r,
    };
  });

  DraftChoice choice(String id, RewardRarity rarity) {
    final data = byId[id]!;
    return DraftChoice(data: data, rarity: rarity, amount: data.amountFor(rarity));
  }

  const paladin = HeroData(
    id: 'paladin',
    nameFr: 'Le Paladin',
    nameEn: 'Paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );

  ProviderContainer freshRun() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(runProvider.notifier).startNewRun(paladin);
    return container;
  }

  test('Vitalité monte les PV max et les PV courants', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('vitality', RewardRarity.epic)); // +15

    final apres = container.read(runProvider).heroStats;
    expect(apres.maxPv, avant.maxPv + 15);
    expect(apres.currentPv, avant.currentPv + 15);
  });

  test('Aiguisage monte la Puissance', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.might;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('sharpening', RewardRarity.rare)); // +4

    expect(container.read(runProvider).heroStats.might, avant + 4);
  });

  test('Affinité monte la Maîtrise', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.mastery;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('affinity', RewardRarity.legendary)); // +7

    expect(container.read(runProvider).heroStats.mastery, avant + 7);
  });

  test('Sagesse monte le mana max', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.maxMana;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('wisdom', RewardRarity.legendary)); // +4

    expect(container.read(runProvider).heroStats.maxMana, avant + 4);
  });

  test('Précision monte la chance de critique', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.critChance;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('precision', RewardRarity.epic)); // +4

    expect(container.read(runProvider).heroStats.critChance, avant + 4);
  });

  test('Férocité est en points de pourcentage, divisés par 100', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.critMultiplier;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('ferocity', RewardRarity.rare)); // 30 -> +0,30

    expect(
      container.read(runProvider).heroStats.critMultiplier,
      closeTo(avant + 0.30, 0.0001),
    );
  });

  test('le Trèfle monte la Chance', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.luck;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('lucky_clover', RewardRarity.mythic)); // +1

    expect(container.read(runProvider).heroStats.luck, avant + 1);
  });

  test('le Miroir ne touche aucune stat', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('mirror', RewardRarity.mythic));

    final apres = container.read(runProvider).heroStats;
    expect(apres.maxPv, avant.maxPv);
    expect(apres.might, avant.might);
    expect(apres.mastery, avant.mastery);
    expect(apres.maxMana, avant.maxMana);
    expect(apres.luck, avant.luck);
    expect(apres.critChance, avant.critChance);
    expect(apres.critMultiplier, avant.critMultiplier);
  });
}
```

> **Si `startNewRun` exige un argument de plus** que la classe (le passif est optionnel : `startNewRun(HeroData chosenClass, [PassiveData? activePassive])`), ne rien changer. Si `runProvider` ou `heroStats.critMultiplier` ne portent pas ces noms exacts, les relire dans `lib/game/controllers/run_controller.dart` et `lib/models/entity_stats.dart` avant d'adapter le test — **jamais** l'inverse.

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/level_up_reward_apply_test.dart`
Expected: FAIL — `The method 'applyLevelUpReward' isn't defined for the class 'RunController'`.

- [ ] **Step 3: Écrire la méthode**

Edit `lib/game/controllers/run/player_stats_manager.dart` : ajouter les imports (`import '../../services/level_up_reward_service.dart';`, `import '../../../models/data/level_up_reward_data.dart';` — vérifier la profondeur depuis `lib/game/controllers/run/`) et la méthode, juste après `applyHeroStatModifier` :

```dart
  /// Applique une récompense de niveau tirée (spec P-41, §8.1).
  ///
  /// Le `switch` est **exhaustif** sur [RewardStat] : ajouter une stat à
  /// l'énumération sans l'appliquer ici ne compile plus. C'était précisément
  /// le trou de la version où `DraftScreen` composait sept accumulateurs à la
  /// main.
  void applyLevelUpReward(DraftChoice choice) {
    final stat = choice.data.stat;
    // Le Miroir : il ouvre une modale de clonage, il ne monte rien.
    if (stat == null) return;

    final amount = choice.amount;
    switch (stat) {
      case RewardStat.maxHp:
        applyHeroStatModifier(maxPvAcc: amount);
      case RewardStat.might:
        applyHeroStatModifier(mightAcc: amount);
      case RewardStat.mastery:
        applyHeroStatModifier(masteryAcc: amount);
      case RewardStat.maxMana:
        applyHeroStatModifier(maxManaAcc: amount);
      case RewardStat.luck:
        applyHeroStatModifier(luckAcc: amount);
      case RewardStat.critChance:
        applyHeroStatModifier(critChanceAcc: amount);
      case RewardStat.critDamage:
        // La donnée est en points de pourcentage (décision 5 du plan) : le
        // joueur lit « +30 % », `critMultiplier` reçoit 0,30.
        applyHeroStatModifier(critDamageAcc: amount / 100);
    }
  }
```

Edit `lib/game/controllers/run_controller.dart` : ajouter la façade, juste après `applyHeroStatModifier` :

```dart
  /// Applique une récompense de niveau tirée (spec P-41, §8.1).
  void applyLevelUpReward(DraftChoice choice) {
    _playerStatsManager.applyLevelUpReward(choice);
  }
```

avec l'import de `level_up_reward_service.dart` si absent.

- [ ] **Step 4: Faire appeler l'écran**

Edit `lib/ui/screens/draft_screen.dart`, dans `_onChoiceSelected` : remplacer le bloc de sept accumulateurs par

```dart
      ref.read(runProvider.notifier).applyLevelUpReward(choice);
```

- [ ] **Step 5: Vérifier**

Run: `flutter test test/unit/level_up_reward_apply_test.dart` — Expected: `+8: All tests passed!`
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1056: All tests passed!` (1048 + 8).

- [ ] **Step 6: Commit**

```bash
git add lib/game/controllers/run/player_stats_manager.dart lib/game/controllers/run_controller.dart lib/ui/screens/draft_screen.dart test/unit/level_up_reward_apply_test.dart
git commit -m "refactor(recompenses): l application du gain quitte l ecran de draft

Un switch exhaustif sur RewardStat dans PlayerStatsManager, la ou l ecran
composait sept accumulateurs a la main. Une stat ajoutee sans etre appliquee
ne compile plus.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Le rouleau du carrousel lit le registre

**Files:**
- Modify: `lib/ui/widgets/relic_carousel/draft_card_reel.dart`, `lib/ui/screens/draft_screen.dart`
- Test: `test/widget/draft_card_reel_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `LevelUpRewardData.shortLabel` (tâche 2), `GameDataRegistry.levelUpRewards` (tâche 3).
- Produces: `DraftCardReel` gagne le paramètre requis `final List<ReelEntry> spinPool;`, et `typedef ReelEntry = ({String title, String description});` est déclaré dans le même fichier.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/widget/draft_card_reel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/relic_carousel/draft_card_reel.dart';

/// Le décor du rouleau vient du registre, plus d'une liste écrite à la main
/// (spec P-41, §8.1 : « le carrousel lit le registre »).
void main() {
  testWidgets('le rouleau affiche le décor qu on lui donne, pas une liste interne', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraftCardReel(
            title: 'Vitalité',
            description: '+15 PV Max',
            rarity: 'ÉPIQUE',
            index: 0,
            onTap: () {},
            spinPool: const [
              (title: 'Récompense factice', description: '+7 Factices'),
            ],
          ),
        ),
      ),
    );

    // Le rouleau démarre sur une entrée de son décor, jamais sur la
    // récompense réelle : celle-ci n'apparaît qu'à l'atterrissage.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Récompense factice'), findsWidgets);
    // La liste écrite en dur d'avant ce chantier ne doit plus exister.
    expect(find.text('+4 Puissance'), findsNothing);
    expect(find.text('+2 Maîtrise'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un rouleau déjà posé montre la récompense réelle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraftCardReel(
            title: 'Vitalité',
            description: '+15 PV Max',
            rarity: 'ÉPIQUE',
            index: 0,
            onTap: () {},
            initialLanded: true,
            spinPool: const [
              (title: 'Récompense factice', description: '+7 Factices'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vitalité'), findsOneWidget);
    expect(find.text('+15 PV Max'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/widget/draft_card_reel_test.dart`
Expected: FAIL — `No named parameter with the name 'spinPool'`.

- [ ] **Step 3: Paramétrer le rouleau**

Edit `lib/ui/widgets/relic_carousel/draft_card_reel.dart` :

Ajouter, au-dessus de `class DraftCardReel` :

```dart
/// Une entrée du décor qui défile pendant que le rouleau tourne : un titre et
/// une ligne, rien de plus. Le rouleau ne connaît pas les récompenses ; c'est
/// l'écran de draft qui les lui donne, lues du registre (spec P-41, §8.1).
typedef ReelEntry = ({String title, String description});
```

Ajouter le champ et le paramètre :

```dart
  /// Ce qui défile avant l'atterrissage. Jamais vide : le rouleau y pioche à
  /// chaque cycle.
  final List<ReelEntry> spinPool;
```

```dart
    required this.spinPool,
```

Remplacer le champ `_mockUpgrades` et ses trois usages. Dans `_DraftCardReelState` :

```dart
  late ReelEntry _currentCardData;
  late ReelEntry _nextCardData;
```

Dans `initState`, remplacer les deux tirages initiaux :

```dart
    final random = Random();
    // Un décor vide voudrait dire un catalogue vide : on fait tourner la
    // récompense réelle plutôt que de planter en plein draft.
    final pool = widget.spinPool.isEmpty
        ? <ReelEntry>[(title: widget.title, description: widget.description)]
        : widget.spinPool;
    _currentCardData = pool[random.nextInt(pool.length)];
    _nextCardData = pool[random.nextInt(pool.length)];
```

puis, dans le `addStatusListener`, la branche de boucle :

```dart
          setState(() {
            _currentCardData = _nextCardData;
            _nextCardData = pool[random.nextInt(pool.length)];
          });
```

et, aux deux atterrissages et dans `_landReel`, remplacer les littéraux de table par la forme d'enregistrement :

```dart
            _currentCardData = (
              title: widget.title,
              description: widget.description,
            );
```

Enfin, dans `build`, `_currentCardData['title']!` devient `_currentCardData.title`, et `['description']!` devient `.description` (quatre sites).

- [ ] **Step 4: Alimenter le décor depuis le registre**

Edit `lib/ui/screens/draft_screen.dart` : calculer le décor une fois, dans `build`, à côté d'`activePassive` :

```dart
    // Le décor du rouleau : chaque récompense du catalogue, à sa valeur `rare`.
    // Une valeur arbitraire et assumée — les libellés écrits à la main qu'elle
    // remplace ne correspondaient à aucun palier cohérent (spec P-41, §8.1).
    final spinPool = [
      for (final reward
          in ref.read(gameDataLoaderProvider).requireValue.levelUpRewards)
        (
          title: reward.getName(l10n.localeName),
          description: reward.shortLabel(
            l10n.localeName,
            amount: reward.amountFor(RewardRarity.rare),
          ),
        ),
    ];
```

puis passer `spinPool: spinPool,` aux **trois** constructions de `DraftCardReel` (autour des lignes 318, 443, et la troisième si elle existe — `dart analyze` les nommera toutes).

Ajouter l'import de `reward_rarity.dart` si absent.

- [ ] **Step 5: Vérifier**

Run: `flutter test test/widget/draft_card_reel_test.dart` — Expected: `+2: All tests passed!`
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1058: All tests passed!` (1056 + 2).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/relic_carousel/draft_card_reel.dart lib/ui/screens/draft_screen.dart test/widget/draft_card_reel_test.dart
git commit -m "feat(recompenses): le rouleau de draft lit le registre

La liste de six libelles ecrite en dur dans draft_card_reel disparait : le
decor est passe par l ecran, depuis le catalogue.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: La prose du tutoriel lit le registre

**Files:**
- Create: `lib/tutorial/tutorial_prose.dart`
- Modify: `lib/tutorial/tutorial_data.dart`, `lib/tutorial/tutorial_screen.dart`
- Test: `test/tutorial/tutorial_prose_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `LevelUpRewardData`, `RewardPool` (tâche 2) ; `GameDataRegistry.levelUpRewards` (tâche 3).
- Produces: `String fillRewardPlaceholders(String body, List<LevelUpRewardData> rewards, {required bool isFrench})` dans `lib/tutorial/tutorial_prose.dart` — fonction pure, sans provider, sans `GameDataRegistry.instance`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/tutorial/tutorial_prose_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/tutorial/tutorial_data.dart';
import 'package:roguelike_card_game/tutorial/tutorial_prose.dart';
import 'package:roguelike_card_game/tutorial/tutorial_step.dart';

/// La prose du tutoriel ne recopie plus la liste des récompenses à la main
/// (spec P-41, §8.1 : « la prose du tutoriel [...] lit le registre »).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les placeholders sont remplis depuis le catalogue', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;

    const gabarit =
        'Trois options sont tirées parmi {rollableCount} types — '
        '{rollableNames} — et jusqu\'à {mythicCount} options Mythiques '
        'peuvent s\'y ajouter : {mythicNames}.';

    expect(
      fillRewardPlaceholders(gabarit, rewards, isFrench: true),
      'Trois options sont tirées parmi six types — Vitalité, Aiguisage, '
      'Affinité, Sagesse, Précision, Férocité — et jusqu\'à deux options '
      'Mythiques peuvent s\'y ajouter : Trèfle à 4 feuilles et Miroir.',
    );
  });

  test('les noms sont donnés dans l ordre déclaré, pas alphabétique', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    final rendu = fillRewardPlaceholders('{rollableNames}', rewards, isFrench: true);

    expect(rendu.indexOf('Vitalité'), lessThan(rendu.indexOf('Aiguisage')));
    expect(rendu.indexOf('Précision'), lessThan(rendu.indexOf('Férocité')));
  });

  test('l anglais est rendu en anglais', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;

    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: false),
      'Four-Leaf Clover and Mirror',
    );
    expect(
      fillRewardPlaceholders('{rollableCount}', rewards, isFrench: false),
      'six',
    );
  });

  test('aucun placeholder ne survit dans l étape de draft', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    final etape = kTutorialSteps
        .firstWhere((s) => s.type == TutorialStepType.draft);

    for (final corps in [etape.bodyFr, etape.bodyEn]) {
      final rendu = fillRewardPlaceholders(
        corps,
        rewards,
        isFrench: corps == etape.bodyFr,
      );
      expect(rendu, isNot(contains('{')));
    }
  });

  test('un texte sans placeholder traverse inchangé', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    const corps = 'Les reliques donnent des bonus passifs.';

    expect(fillRewardPlaceholders(corps, rewards, isFrench: true), corps);
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/tutorial/tutorial_prose_test.dart`
Expected: FAIL — le fichier `tutorial_prose.dart` n'existe pas.

- [ ] **Step 3: Écrire la fonction pure**

Create `lib/tutorial/tutorial_prose.dart`:

```dart
import '../models/data/level_up_reward_data.dart';

/// Les nombres que la prose du tutoriel écrit en toutes lettres. Au-delà,
/// c'est le chiffre — le catalogue n'ira pas jusque-là de sitôt, et écrire
/// « quatorze » en deux langues n'a pas de lecteur.
const Map<int, ({String fr, String en})> _spelled = {
  1: (fr: 'un', en: 'one'),
  2: (fr: 'deux', en: 'two'),
  3: (fr: 'trois', en: 'three'),
  4: (fr: 'quatre', en: 'four'),
  5: (fr: 'cinq', en: 'five'),
  6: (fr: 'six', en: 'six'),
  7: (fr: 'sept', en: 'seven'),
  8: (fr: 'huit', en: 'eight'),
};

String _count(int n, {required bool isFrench}) {
  final spelled = _spelled[n];
  if (spelled == null) return '$n';
  return isFrench ? spelled.fr : spelled.en;
}

/// « A, B et C » — une virgule entre les premiers, « et » avant le dernier.
String _join(List<String> names, {required bool isFrench}) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.single;
  final et = isFrench ? ' et ' : ' and ';
  return '${names.sublist(0, names.length - 1).join(', ')}$et${names.last}';
}

List<String> _namesOf(
  List<LevelUpRewardData> rewards,
  RewardPool pool, {
  required bool isFrench,
}) {
  final inPool = rewards.where((r) => r.pool == pool).toList()
    ..sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  return [for (final r in inPool) r.getName(isFrench ? 'fr' : 'en')];
}

/// Remplit, dans [body], les quatre placeholders que la prose du tutoriel
/// laisse au catalogue (spec P-41, §8.1) : `{rollableCount}`,
/// `{rollableNames}`, `{mythicCount}` et `{mythicNames}`.
///
/// Fonction **pure**, sans provider et sans `GameDataRegistry.instance` : le
/// tutoriel reçoit son registre par `TutorialScreen.data` (ADR-081, vérifié par
/// `test/tutorial/tutorial_isolation_test.dart`). Un texte qui ne nomme aucun
/// placeholder traverse inchangé.
String fillRewardPlaceholders(
  String body,
  List<LevelUpRewardData> rewards, {
  required bool isFrench,
}) {
  final rollable = _namesOf(rewards, RewardPool.draft, isFrench: isFrench);
  final mythic = _namesOf(rewards, RewardPool.mythic, isFrench: isFrench);

  return body
      .replaceAll('{rollableCount}', _count(rollable.length, isFrench: isFrench))
      .replaceAll('{rollableNames}', _join(rollable, isFrench: isFrench))
      .replaceAll('{mythicCount}', _count(mythic.length, isFrench: isFrench))
      .replaceAll('{mythicNames}', _join(mythic, isFrench: isFrench));
}
```

- [ ] **Step 4: Mettre les placeholders dans la prose**

Edit `lib/tutorial/tutorial_data.dart`, l'étape `TutorialStepType.draft` : remplacer les deux premiers paragraphes de `bodyEn` et de `bodyFr`.

```dart
    bodyEn:
        'Each level grants a draft. Three options are rolled from '
        '{rollableCount} kinds — {rollableNames} — and up to {mythicCount} '
        '**Mythic** options can appear on top: {mythicNames}.\n\n'
        'Rarity decides how much you get. Luck raises your odds on every roll, '
        'which makes the Clover the option that improves all the others.\n\n'
        'Careful with Affinity: it grants **Mastery**, which strengthens what '
        'your passive produces — each passive states what one point adds.',
    bodyFr:
        'Chaque niveau donne droit à un draft. Trois options sont tirées parmi '
        '{rollableCount} types — {rollableNames} — et jusqu\'à {mythicCount} '
        'options **Mythiques** peuvent s\'y ajouter : {mythicNames}.\n\n'
        'La rareté décide de l\'ampleur du gain. La Chance améliore vos '
        'probabilités à chaque tirage, ce qui fait du Trèfle l\'option qui '
        'améliore toutes les autres.\n\n'
        'Attention à l\'Affinité : elle donne de la **Maîtrise**, qui renforce '
        'ce que produit votre passif — chaque passif indique ce qu\'un point '
        'lui apporte.',
```

> Les articles disparaissent de la liste des mythiques (« le Trèfle à 4 feuilles et le Miroir » → « Trèfle à 4 feuilles et Miroir ») : le registre ne porte pas le genre d'un nom, et un champ `article` pour deux noms coûterait plus que la perte. C'est la conséquence n° 1 annoncée en tête de plan.

- [ ] **Step 5: Remplir au rendu**

Edit `lib/tutorial/tutorial_screen.dart`, ligne 146 :

```dart
            final stepBody = fillRewardPlaceholders(
              isFrench ? currentStep.bodyFr : currentStep.bodyEn,
              widget.data.levelUpRewards,
              isFrench: isFrench,
            );
```

avec `import 'tutorial_prose.dart';`. Si le registre est porté par un autre nom que `widget.data` dans ce `build`, le relire dans le fichier — il y est déclaré `final GameDataRegistry data;` (`tutorial_screen.dart:24`).

- [ ] **Step 6: Vérifier**

Run: `flutter test test/tutorial/tutorial_prose_test.dart` — Expected: `+5: All tests passed!`
Run: `flutter test test/tutorial/tutorial_isolation_test.dart` — Expected: `+2: All tests passed!` (la nouvelle fonction n'importe ni Riverpod ni `GameDataRegistry.instance`).
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1063: All tests passed!` (1058 + 5).

- [ ] **Step 7: Commit**

```bash
git add lib/tutorial/tutorial_prose.dart lib/tutorial/tutorial_data.dart lib/tutorial/tutorial_screen.dart test/tutorial/tutorial_prose_test.dart
git commit -m "feat(recompenses): la prose du tutoriel lit le registre

La liste des six types et des deux mythiques n est plus recopiee a la main
dans tutorial_data : quatre placeholders, remplis au rendu par une fonction
pure. ADR-081 tenu : aucun provider, aucun GameDataRegistry.instance.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Vérification finale et pull request

**Files:**
- Aucun changement de code attendu. Si une vérification rougit, la corriger dans une tâche à part — pas ici.

**Interfaces:**
- Consumes: les tâches 1 à 7.
- Produces: la PR de la partie 1 du lot C.

- [ ] **Step 1: La suite complète, deux fois**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1063: All tests passed!`
Run: `flutter test` une seconde fois — Expected: **le même compte**. `level_up_reward_values_test.dart` échantillonne 30 000 tirages : deux passages verts d'affilée écartent un test rendu instable par le passage en donnée.

- [ ] **Step 2: Le pubspec ne dérive pas**

Run: `dart run tool/sync_assets.dart --check`
Expected: code de retour 0.

- [ ] **Step 3: Aucune trace de l'ancien régime**

Run: `git grep -n "LevelUpRewardType\|nextInt(6)\|draftChoiceVitality\|_mockUpgrades" -- lib test`
Expected: **aucune sortie**.

Run: `git grep -n "pvBoost\|mightBoost\|masteryBoost\|manaBoost\|luckBoost\|critChanceBoost\|critDamageBoost" -- lib test`
Expected: **aucune sortie** — les sept accumulateurs de `DraftChoice` ont disparu ; `applyHeroStatModifier` garde ses paramètres `…Acc`, qui ne sont pas visés par ce grep.

- [ ] **Step 4: Rien de généré n'est en attente**

Run: `git status --short`
Expected: aucune sortie. Si `macos/Flutter/GeneratedPluginRegistrant.swift`, `linux/flutter/` ou `windows/flutter/` apparaissent : `git checkout --` dessus, ne jamais les commiter.

- [ ] **Step 5: Ouvrir la pull request**

```bash
git push -u origin feat/p41-lot-c-recompenses
```

Titre : `P-41 lot C, partie 1 — Les recompenses de niveau deviennent de la donnee`

Corps :

```
Implemente le §8.1 de la spec S2 (decision D3) : les huit recompenses de
niveau quittent le code pour `assets/data/level_up_rewards/`.

Ce qui change de provenance, pas de valeur :
- huit fichiers, table de valeurs par rarete et libelles bilingues en ligne ;
- le tirage lit le registre ; `LevelUpRewardType` et `rng.nextInt(6)`
  disparaissent, ainsi que les trois `switch` de valeurs ;
- 17 cles ARB retirees : les libelles sont du contenu ;
- la prose du tutoriel et le rouleau du carrousel lisent le registre : les
  deux copies manuelles disparaissent ;
- l application du gain quitte `DraftScreen` pour `PlayerStatsManager`, sur un
  `switch` exhaustif.

Le jeu ne change pas. `level_up_reward_values_test.dart`, devenu un test sur
la donnee, verrouille les 30 combinaisons a valeurs identiques — c est le
critere d acceptation du §8.1.

Un seul texte joueur bouge : la liste des deux mythiques du tutoriel perd ses
articles (« Trefle a 4 feuilles et Miroir »), le registre ne portant pas le
genre d un nom.

`dart analyze` propre, `flutter test` vert (1063 tests, contre 1021 au depart).

Suite : partie 2 du lot C — filtre d'Affinite et ecran de selection.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 6: Après la fusion**

Une fois la PR fusionnée, lancer le skill `patch-notes-writer` (la note `0.5.2` est rouverte en place, cf. `docs/ROADMAP.md`) puis le skill `memory-bank-sync`. Les deux sont agent-gérés : ne pas éditer `assets/data/patch_notes.json`, `pubspec.yaml` (`version:`) ni `.obsidian_vault/_memory_bank/` à la main.

---

## Suites connues, laissées ouvertes

| Sujet | Où il vit |
|:---|:---|
| Le filtre d'*Affinité* quand le passif actif ne déclare pas de Maîtrise | Partie 2 du lot C — [plan](2026-09-18-p41-lot-c-partie-2-filtre-et-ecran-de-selection.md), spec §8.2 |
| L'éditeur de contenu apprend la catégorie « récompense de niveau » | Lot D, spec §9.2 |
| Le rééquilibrage des valeurs et des paliers, *Sagesse* en tête | P-16, spec §8.4 |
| Les neuf récompenses dédiées, une par passif | Remplacées par *Affinité* le 2026-09-16 (spec §8.2). **Reprises le 2026-09-18 comme idée d'évolution**, sous une forme qui lève l'objection de N1 : tirables **tous les 5 niveaux** dans leur propre pool, et non diluées dans celui des six autres — [`docs/possible_upgrades/upgrade_ideas.md`](../../possible_upgrades/upgrade_ideas.md) |
| **Les courbes de rareté** — `rollRarity` ici, et les deux cascades de `reward_controller.dart:105-140` pour les reliques | **Hors périmètre, délibérément — et c'est un chantier à part entière.** Ce lot déplace le **catalogue** (quelles récompenses existent, combien elles donnent), pas la **courbe** (à quelle fréquence chaque palier sort). Une courbe n'est pas une donnée d'entité : il y en a une par système, pas une par récompense, et elle n'aurait sa place ni dans `vitality.json` ni dans `whetstone.json`. Le relevé complet — **trois cascades en dur qui ne partagent aucune ligne**, dont celle de la relique d'élite qui a dérivé de la courbe commune ; un test qui recopie la formule au lieu de l'échantillonner et diverge de la production ; la forme JSON proposée — est consigné dans [`docs/possible_upgrades/upgrade_ideas.md`](../../possible_upgrades/upgrade_ideas.md), dernière entrée. **Ne rien en faire dans P-41** |
