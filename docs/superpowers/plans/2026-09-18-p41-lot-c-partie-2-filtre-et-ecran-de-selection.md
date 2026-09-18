# P-41 lot C, partie 2 — Le filtre d'*Affinité* et l'écran de sélection — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** *Affinité* cesse d'être tirée quand le passif actif ne déclare aucune Maîtrise, et l'écran de sélection de classe cesse de mentir : `baseDamage` — 5 / 15 / 10 alors que toute run démarre à 0 — disparaît, remplacé par les stats de départ réellement non nulles, par ce que renforce la Puissance de la classe, par sa règle de stat en clair, et par le choix du passif parmi ceux que la classe peut prendre.

**Architecture:** Trois textes générés, jamais écrits classe par classe : la forme longue de `mightTargets` et la phrase d'une `StatRule` rejoignent `MightTargetsLabels` dans `lib/models/data/model_extensions.dart`, sur des `switch` exhaustifs qui font rougir l'analyseur si une valeur d'énumération est ajoutée sans son libellé — c'est la règle d'ADR-090, aucun écran ne compare `hero.id`. Le filtre d'*Affinité* est un champ `requires` sur `LevelUpRewardData`, lu par `generateChoices` : le mécanisme, pas la récompense. Le choix du passif ne fait qu'ouvrir ce que l'écran calculait déjà — `availablePassivesFor` rendait trois passifs dont il n'affichait que le premier.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` — lire les **§8.2** et **§8.3** en entier, puis le §7.4 pour la forme longue de l'orientation (« **La forme longue n'a pas de lecteur à la partie 1** : elle est écrite au lot C ») et le §5.1 (P4, P5) pour le point d'accès unique aux passifs. Le §11 écarte explicitement le rétablissement de `baseDamage`.

**Dépend de :** la **partie 1 du lot C** — [plan](2026-09-18-p41-lot-c-partie-1-recompenses-data-driven.md), spec §8.1 —, **fusionnée dans `main`**. Le filtre de la tâche 1 ajoute un champ à `LevelUpRewardData` et un paramètre à `generateChoices`, tous deux créés là-bas. Les lots A et B de P-41 et le chantier frère P-49 sont fusionnés (PR #38, #40, #41, #39).

## Global Constraints

- **Le jeu change, et c'est le but.** Ce qui change est borné à ceci : *Affinité* n'est plus tirée sans Maîtrise ; l'écran de sélection perd `baseDamage` et gagne les stats de départ non nulles, l'orientation de la Puissance, la règle de stat et le choix du passif. Rien d'autre — aucun chiffre de carte, de relique, d'ennemi, de passif ou de récompense.
- **Le champ `baseDamage` disparaît de `HeroData` et des trois `class.json`.** Il reste sur `EnemyData`, où il a des lecteurs réels (`combat_controller.dart:155`, `encounter_system.dart:205`, `enemy_instance.dart:20-21`). Ne pas confondre les deux au moment de nettoyer les fixtures.
- **Les deux chiffres que la spec §8.3 oppose sont toujours vrais, mais ses deux pointeurs ont vieilli.** L'écran affiche bien `playerClass.baseDamage` — 5 / 15 / 10 pour le Paladin, le Berserker et le Mage —, à `class_selection_screen.dart:350` (la spec cite `:345`, le `_buildStatBadge` qui l'enveloppe). Et la run démarre bien à 0 : c'est `run_controller.dart:266`, `might: 0, // Puissance de base à 0` — la spec cite `run_controller.dart:254` et `attaque: 0 // Force de base à 0`, nom et commentaire d'avant que le lot B ne renomme la stat. Le constat tient, la citation est à lire sous son nouveau nom.
- **Aucun écran ne compare l'identifiant d'une classe** (ADR-090). Les trois textes de l'écran — orientation, règle de stat, stats de départ — sont **générés depuis la donnée**. Un `if (hero.id == 'berserker')` dans ce lot est un défaut, pas un raccourci.
- `dart analyze` doit afficher `No issues found!` à la fin de **chaque** tâche.
- `flutter test` doit être **entièrement** vert à la fin de chaque tâche. Point de départ : **à re-mesurer sur `main` après la fusion de la partie 1** (`dart analyze` puis `flutter test`, tâche 0) ; prévision **1063 tests**, contre 1021 avant la partie 1 (mesuré le 2026-09-18 sur `6605b25`). Les totaux annoncés tâche par tâche sont une **prévision arithmétique** à partir du compte réellement mesuré à la tâche 0, **non un rejeu** : un écart signale un test oublié ou dupliqué, à comprendre avant de continuer — jamais un nombre à réajuster à l'aveugle.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas.
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** pour du contenu : les heredocs de cet environnement mangent les antislashs, et le code Dart, les JSON et les ARB de ce plan en contiennent (`l\'Affinité`, `\n`, `{duration, plural, ...}`).
- Tout texte joueur d'un JSON porte ses variantes `_fr` **et** `_en` (`CLAUDE.md`).
- Les fichiers `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` sont générés **et commités** : après toute modification d'un ARB, lancer `flutter gen-l10n` et commiter les trois. Le fichier **gabarit** est `app_en.arb` (`l10n.yaml`) : c'est lui qui porte les blocs `@clé` de métadonnées.
- Le tutoriel ne référence aucun provider d'état (ADR-081), vérifié par `test/tutorial/tutorial_isolation_test.dart`. Ce lot ne touche pas à `lib/tutorial/` sauf pour passer le passif actif au tirage, par un chemin qui existe déjà (`TutorialEngine.mockState.activePassive`). **L'étape de choix de classe du tutoriel reste au lot D** (spec §9.1).
- **L'éditeur de contenu n'apprend pas `statRules`** : la spec place sa validation au lot D (§9.2). Ce lot n'y retire que `baseDamage`, devenu une clé obligatoire vers un champ qui n'existe plus.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Le code va sur la branche `feat/p41-lot-c-selection`, jamais sur `main`. La documentation de cette partie est déjà commitée sur `main`, avant l'exécution. **Pas de worktree** (décision du propriétaire) : la branche est créée dans le checkout principal, même si le skill d'exécution en propose un.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes**, terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire des fichiers générés sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, ceux de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.

## Décisions prises à la rédaction du plan

La spec tranche la conception ; sept points d'implémentation restaient ouverts. Ils sont tranchés ici, et l'exécutant n'a pas à les rouvrir.

| # | Question | Décision | Pourquoi |
|:---|:---|:---|:---|
| **1** | Comment le filtre d'*Affinité* s'écrit-il ? | Un champ **`requires`** sur `LevelUpRewardData`, `enum RewardRequirement { passiveMastery }`, lu par `generateChoices` | Le conditionnement est un mécanisme, pas une propriété d'*Affinité* : le §8.2 prévoyait neuf récompenses conditionnées, et P-13 en branchera d'autres derrière le même point d'accès (§10). Un `if (reward.id == 'affinity')` referait le code que la partie 1 vient de supprimer |
| **2** | Un passif **absent** compte-t-il comme « ne déclare pas de Maîtrise » ? | Oui : `passive?.mastery != null`. Sans passif actif, *Affinité* n'est pas tirée | « Le passif actif ne déclare pas `mastery` » (§8.2) couvre le cas où il n'y a pas de passif du tout : la récompense serait tout aussi inerte. Conséquence assumée n° 1 |
| **2 bis** | Le filtre passe-t-il par `availablePassivesFor` ? | **Non** : il lit `RunState.activePassive`, et le tutoriel `TutorialEngine.mockState.activePassive` | Le §8.2 renvoie au point d'accès de P-49 (§5.1, P5) parce que sa conception d'origine tirait **neuf récompenses dédiées**, une par passif : il fallait alors savoir quels passifs la classe pouvait prendre. Avec la récompense unique *Affinité*, la question n'est plus « lesquels sont disponibles » mais « celui qui est actif déclare-t-il une Maîtrise » — et la réponse n'est que dans l'état de la run. Passer par le point d'accès lirait une liste dont aucun élément n'est celui qui compte |
| **3** | Où vivent la forme longue de l'orientation et la phrase d'une règle de stat ? | Dans `lib/models/data/model_extensions.dart`, à côté de `MightTargetsLabels.shortLabel` | C'est déjà là que vit la forme courte, écrite à la partie 1 du lot B, et le seul fichier de `lib/models/` qui importe `AppLocalizations`. Deux fichiers pour deux formes du même libellé seraient deux endroits à tenir |
| **4** | Comment la durée d'une règle s'écrit-elle en français ? | Par un **pluriel ICU** dans l'ARB : `{duration, plural, =1{... un tour.} other{... {duration} tours.}}` | C'est le premier pluriel des ARB du projet, et c'est la seule forme qui reste juste si une règle future dure trois tours. La générer en Dart demanderait d'écrire « un » et « one » en dur dans un fichier qui n'est pas un ARB |
| **5** | Quelles stats de départ l'écran montre-t-il ? | PV max et mana max **toujours** ; `mastery`, `critChance` et `luck` **seulement si > 0**. Un `Wrap`, plus un `Row` | « PV max et stats de départ non nulles » (§8.3). Les PV et le mana sont les deux repères que le joueur compare d'une classe à l'autre ; les trois autres valent 0 pour au moins une classe et n'ont rien à dire quand elles valent 0. Le `Wrap` évite qu'une quatrième stat non nulle déborde la carte sur mobile |
| **6** | Le choix est-il borné à trois passifs ? | Non : l'écran affiche **tous** ceux que `availablePassivesFor` rend, dans leur ordre | La spec dit « le choix du passif parmi les passifs disponibles pour la classe, lus par le point d'accès de P-49 » (§8.3). Trois est le compte d'aujourd'hui, pas une règle ; P-13 fera varier ce nombre par les déblocages, et un `take(3)` le trahirait silencieusement |
| **7** | `lib/ui/widgets/sword_icon.dart` survit-il ? | Non : supprimé avec `baseDamage`, et `might_icon_test.dart` passe de « plus qu'à l'écran de sélection » à « plus nulle part » | La spec le dit : « `SwordIcon` reste à l'écran de sélection **jusqu'au retrait de `baseDamage`** » (§7.4). Il n'a aucun autre usage (`git grep 'SwordIcon('`) : le laisser serait du code mort |

## Conséquences assumées, à annoncer plutôt qu'à découvrir

1. **Sans passif actif, *Affinité* n'est plus proposée du tout** (décision 2). Le gabarit `fallbackDescription` d'`affinity.json` devient donc inatteignable par le tirage normal ; il reste comme filet de rendu — un `DraftChoice` construit hors du tirage ne doit jamais laisser fuir un `{passive}` à l'écran, et un test de la partie 1 le vérifie sur les huit récompenses.
2. **La table de tirage effective passe de 6 à 5 types** pour un passif sans Maîtrise. Les neuf passifs livrés au lot B en déclarent tous un : **aucune run réelle n'est concernée aujourd'hui**. Le filtre est livré, testé sur un passif construit sans bloc `mastery`, et attend le premier passif qui n'en déclarera pas. C'est ce que la spec demande (§8.2), pas un mécanisme spéculatif : sans lui, un tel passif rendrait une récompense sur six inerte.
3. **Le Berserker n'affiche plus « 15 »**, et aucune classe n'affiche de dégâts de base. C'est le but : « L'écran ment au joueur au moment le plus structurant de la run » (§8.3). Rétablir `baseDamage` est explicitement écarté (§11).
4. **La carte de classe s'allonge.** Elle porte désormais, en plus, une phrase d'orientation, une éventuelle phrase de règle de stat, et un sélecteur de passif. Le `SingleChildScrollView` de la description absorbe le reste ; sur mobile, la carte reste dans son `childAspectRatio` de 0,68. À revoir à l'œil après la tâche 6 — un débordement est un défaut de cette partie.
5. **Le tutoriel garde son étape de choix de classe telle quelle.** Elle ne propose pas encore les passifs disponibles : la spec assigne ce point au **lot D** (§9.1), avec `tutorial_fixtures.dart:57` qui cesse de supposer un passif unique. Ce lot passe seulement le passif actif au tirage du tutoriel, pour que le filtre y vaille aussi.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/data/level_up_reward_data.dart` | `RewardRequirement`, le champ `requires`, `isAvailableWith` | 1 |
| `assets/data/level_up_rewards/affinity.json` | `"requires": "passiveMastery"` | 1 |
| `lib/game/services/level_up_reward_service.dart` | `generateChoices(activePassive:)` | 1 |
| `lib/ui/screens/draft_screen.dart`, `lib/tutorial/widgets/tutorial_draft_widget.dart` | Passent le passif actif au tirage | 1 |
| `lib/l10n/app_en.arb`, `app_fr.arb` | La forme longue, le joint de liste, les deux phrases de règle | 2, 3 |
| `lib/models/data/model_extensions.dart` | `MightTargetsLabels.longLabel`, `StatRuleLabel.describe` | 2, 3 |
| `lib/models/data/hero_data.dart` | `baseDamage` retiré | 4 |
| `assets/data/classes/*/class.json` | `baseDamage` retiré | 4 |
| `lib/services/content_editor/entity_descriptor.dart` | `baseDamage` retiré des `requiredKeys` et du gabarit de classe | 4 |
| `lib/ui/widgets/sword_icon.dart` *(supprimé)* | Sans usage une fois `baseDamage` parti | 4 |
| `lib/ui/screens/class_selection_screen.dart` | Les stats de départ non nulles, l'orientation, la règle, le choix du passif | 4, 5, 6 |
| `test/unit/might_icon_test.dart` | L'épée n'a plus aucun usage | 4 |
| `test/widget/class_selection_screen_test.dart` | Ce que la carte de classe montre et ce qu'elle pousse | 4, 5, 6 |

---

### Task 0: La branche, depuis la documentation déjà commitée

**À faire dans le checkout principal, avant toute tâche de code.**

**Files:**
- Aucun. La documentation de cette partie est **déjà commitée sur `main`** : ce plan, celui de la partie 1, et les liens qui les portent dans `docs/INDEX.md` et `docs/ROADMAP.md`.

**Interfaces:**
- Consumes: ce plan, commité sur `main` ; la partie 1 du lot C, **fusionnée**.
- Produces: la branche `feat/p41-lot-c-selection`, et le **compte de tests de départ réellement mesuré**, dont dépendent toutes les prévisions de ce plan.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git switch main && git pull`, puis `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement), puis `git status --short`
Expected: **aucune sortie** — l'arbre de travail est propre.

Run: `git log --oneline -8`
Expected: on y trouve la fusion de la partie 1 du lot C. Si elle manque, **s'arrêter et le signaler** : la tâche 1 ajoute un champ à un modèle que la partie 1 crée, et les tâches 5 et 6 supposent un `main` où les récompenses sont déjà de la donnée.

Run: `ls assets/data/level_up_rewards/`
Expected: huit fichiers. Même conclusion si le répertoire n'existe pas.

- [ ] **Step 2: Créer la branche**

Run: `git switch -c feat/p41-lot-c-selection` — depuis `main`, dans le checkout principal. **Pas de worktree**, même si le skill d'exécution en propose un.

- [ ] **Step 3: Mesurer la base — et noter le chiffre**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+N: All tests passed!`, **prévision N = 1063**.

**Noter N.** Toutes les prévisions de ce plan sont écrites à partir de 1063 ; si N diffère, décaler chaque prévision du même écart plutôt que de la recalculer.

---

### Task 1: *Affinité* n'est plus tirée sans Maîtrise

**Files:**
- Modify: `lib/models/data/level_up_reward_data.dart`, `assets/data/level_up_rewards/affinity.json`, `lib/game/services/level_up_reward_service.dart`, `lib/ui/screens/draft_screen.dart`, `lib/tutorial/widgets/tutorial_draft_widget.dart`
- Test: `test/unit/level_up_reward_requirement_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `LevelUpRewardData`, `DraftChoice`, `LevelUpRewardService.generateChoices` (partie 1) ; `PassiveData.mastery` (P-49).
- Produces:
  - `enum RewardRequirement { passiveMastery }` dans `lib/models/data/level_up_reward_data.dart`.
  - `LevelUpRewardData.requires` (`RewardRequirement?`, `null` par défaut), lu par `fromJson`.
  - `bool LevelUpRewardData.isAvailableWith(PassiveData? passive)`.
  - `generateChoices` gagne le paramètre nommé optionnel `PassiveData? activePassive`. Sa signature complète devient `({required List<LevelUpRewardData> rewards, required int luck, bool forceLegendary = false, PassiveData? activePassive})`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/level_up_reward_requirement_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// *Affinité* n'est pas tirée quand le passif actif ne déclare pas de Maîtrise
/// (spec P-41, §8.2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<LevelUpRewardData> rewards;

  setUpAll(() async {
    rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
  });

  PassiveData passif({PassiveMastery? mastery}) => PassiveData(
        id: 'ward',
        nameEn: 'Ward',
        nameFr: 'Garde',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: mastery,
      );

  const bloc = PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} Block at end of turn',
    descriptionFr: '+{amount} Armure en fin de tour',
  );

  Set<String> tirees({PassiveData? activePassive}) {
    final vues = <String>{};
    for (var i = 0; i < 2000; i++) {
      for (final choix in LevelUpRewardService.generateChoices(
        rewards: rewards,
        luck: 0,
        activePassive: activePassive,
      )) {
        if (choix.data.pool == RewardPool.draft) vues.add(choix.data.id);
      }
    }
    return vues;
  }

  test('affinity.json déclare son exigence', () {
    final affinity = rewards.firstWhere((r) => r.id == 'affinity');
    expect(affinity.requires, RewardRequirement.passiveMastery);
  });

  test('aucune autre récompense n exige quoi que ce soit', () {
    for (final reward in rewards.where((r) => r.id != 'affinity')) {
      expect(reward.requires, isNull, reason: reward.id);
    }
  });

  test('un passif avec Maitrise laisse les six types tirables', () {
    expect(
      tirees(activePassive: passif(mastery: bloc)),
      {'vitality', 'sharpening', 'affinity', 'wisdom', 'precision', 'ferocity'},
    );
  });

  test('un passif sans Maitrise retire l Affinite de la table', () {
    final vues = tirees(activePassive: passif());
    expect(vues, isNot(contains('affinity')));
    // Les cinq autres restent : la table rétrécit, elle ne se vide pas.
    expect(
      vues,
      {'vitality', 'sharpening', 'wisdom', 'precision', 'ferocity'},
    );
  });

  test('sans passif actif du tout, l Affinite n est pas tiree non plus', () {
    // Une récompense de Maîtrise sans passif est tout aussi inerte : c'est le
    // même cas (décision 2 du plan).
    expect(tirees(), isNot(contains('affinity')));
  });

  test('l exigence se lit sans passer par le tirage', () {
    final affinity = rewards.firstWhere((r) => r.id == 'affinity');
    final vitality = rewards.firstWhere((r) => r.id == 'vitality');

    expect(affinity.isAvailableWith(passif(mastery: bloc)), isTrue);
    expect(affinity.isAvailableWith(passif()), isFalse);
    expect(affinity.isAvailableWith(null), isFalse);
    // Une récompense sans exigence est toujours disponible.
    expect(vitality.isAvailableWith(null), isTrue);
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/level_up_reward_requirement_test.dart`
Expected: FAIL — `The getter 'requires' isn't defined for the class 'LevelUpRewardData'`.

- [ ] **Step 3: Ajouter l'exigence au modèle**

Edit `lib/models/data/level_up_reward_data.dart` : ajouter l'import `import 'passive_data.dart';` s'il n'y est pas (il y est — `describe` lit déjà `PassiveData`), puis l'énumération, sous `RewardPool` :

```dart
/// Ce qu'une récompense exige de la run pour être tirée (spec P-41, §8.2).
///
/// Un mécanisme, et non une propriété d'*Affinité* : le §8.2 prévoyait neuf
/// récompenses conditionnées par le passif actif, et la méta-progression (P-13)
/// en branchera d'autres derrière le même point (spec §10).
enum RewardRequirement {
  /// Le passif actif doit déclarer un bloc `mastery` : sans lui, un point de
  /// Maîtrise n'augmente rien (spec P-49, §3.3).
  passiveMastery,
}
```

Ajouter le champ, le paramètre du constructeur, sa lecture et le prédicat :

```dart
  /// Ce que la run doit présenter pour que cette récompense soit tirable ;
  /// `null` : rien.
  final RewardRequirement? requires;
```

```dart
    this.requires,
```

```dart
      requires: json['requires'] == null
          ? null
          : _readEnum(json['requires'], RewardRequirement.values, '$id : requires'),
```

```dart
  /// Cette récompense peut-elle être tirée dans une run dont le passif actif
  /// est [passive] ? Un passif absent ne déclare aucune Maîtrise : la
  /// récompense serait tout aussi inerte (décision 2 du plan).
  bool isAvailableWith(PassiveData? passive) => switch (requires) {
        null => true,
        RewardRequirement.passiveMastery => passive?.mastery != null,
      };
```

- [ ] **Step 4: Déclarer l'exigence dans la donnée**

Edit `assets/data/level_up_rewards/affinity.json` : ajouter la clé, après `"stat": "mastery",` :

```json
  "requires": "passiveMastery",
```

- [ ] **Step 5: Faire lire le filtre au tirage**

Edit `lib/game/services/level_up_reward_service.dart` : ajouter l'import `import '../../models/data/passive_data.dart';`, le paramètre, et le filtre.

```dart
  static List<DraftChoice> generateChoices({
    required List<LevelUpRewardData> rewards,
    required int luck,
    bool forceLegendary = false,
    PassiveData? activePassive,
  }) {
    final rng = Random();
    // Le filtre s'applique à la table des trois emplacements comme aux
    // mythiques : une exigence est une propriété de la récompense, pas du
    // groupe de tirage (spec P-41, §8.2).
    final eligible =
        rewards.where((reward) => reward.isAvailableWith(activePassive)).toList();
    final draftable = _inPool(eligible, RewardPool.draft);
    if (draftable.isEmpty) return const [];
```

et remplacer, plus bas, `_inPool(rewards, RewardPool.mythic)` par `_inPool(eligible, RewardPool.mythic)`.

- [ ] **Step 6: Passer le passif actif aux deux appelants**

Edit `lib/ui/screens/draft_screen.dart`, dans `initState` :

```dart
    _choices = LevelUpRewardService.generateChoices(
      rewards: ref.read(gameDataLoaderProvider).requireValue.levelUpRewards,
      luck: ref.read(runProvider).heroStats.luck,
      forceLegendary: widget.forceLegendary,
      activePassive: ref.read(runProvider).activePassive,
    );
```

Edit `lib/tutorial/widgets/tutorial_draft_widget.dart` :

```dart
    _choices = LevelUpRewardService.generateChoices(
      rewards: widget.engine.data.levelUpRewards,
      luck: 0,
      activePassive: widget.engine.mockState.activePassive,
    );
```

`mockState.activePassive` est déjà lu, deux lignes plus bas, pour décrire *Affinité* : **aucune** nouvelle voie d'accès, donc rien à craindre du côté d'ADR-081 et de `tutorial_isolation_test.dart`.

- [ ] **Step 7: Vérifier**

Run: `flutter test test/unit/level_up_reward_requirement_test.dart` — Expected: `+6: All tests passed!`
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1069: All tests passed!` (1063 + 6).

- [ ] **Step 8: Commit**

```bash
git add lib/models/data/level_up_reward_data.dart assets/data/level_up_rewards/affinity.json lib/game/services/level_up_reward_service.dart lib/ui/screens/draft_screen.dart lib/tutorial/widgets/tutorial_draft_widget.dart test/unit/level_up_reward_requirement_test.dart
git commit -m "feat(recompenses): l Affinite n est plus tiree sans Maitrise

Un champ requires sur la recompense, lu par le tirage : le mecanisme, pas la
recompense. Les neuf passifs livres declarent tous une Maitrise, donc aucune
run reelle ne change encore.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: La forme longue de l'orientation de la Puissance

Textes seuls, sans lecteur encore : c'est la tâche 5 qui les affiche. La spec l'annonçait à la partie 1 du lot B — « **La forme longue n'a pas de lecteur à la partie 1** : elle est écrite au lot C » (§7.4).

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/models/data/model_extensions.dart`
- Regenerate: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`
- Test: `test/unit/might_targets_long_label_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `MightTarget` (`lib/models/might_target.dart`), `MightTargetsLabels.shortLabel` (partie 1 du lot B).
- Produces:
  - Clés ARB : `mightTargetAttackLong`, `mightTargetSkillLong`, `mightTargetAlterationLong`, `listJoinAnd`, `mightTargetsSentence(targets)`.
  - `String MightTargetsLabels.longLabel(AppLocalizations l10n)` — les cibles longues, jointes.
  - `String MightTargetsLabels.sentence(AppLocalizations l10n)` — la phrase complète.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/might_targets_long_label_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/models/might_target.dart';

/// La forme longue de ce que renforce la Puissance, pour l'écran de sélection
/// (spec P-41, §7.4 et §8.3). Générée, jamais écrite classe par classe :
/// aucun écran ne compare `hero.id` (ADR-090).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('une seule cible : pas de joint', () {
    // Le Berserker.
    expect(
      {MightTarget.attack}.sentence(fr),
      'Votre Puissance renforce les dégâts de vos Attaques.',
    );
    expect(
      {MightTarget.attack}.sentence(en),
      'Your Might strengthens your Attack damage.',
    );
  });

  test('deux cibles : jointes par « et »', () {
    // Le Mage.
    expect(
      {MightTarget.skill, MightTarget.alteration}.sentence(fr),
      'Votre Puissance renforce les dégâts de vos Compétences et vos altérations.',
    );
    expect(
      {MightTarget.skill, MightTarget.alteration}.sentence(en),
      'Your Might strengthens your Skill damage and your alterations.',
    );
  });

  test('trois cibles : une virgule, puis « et »', () {
    // Le Paladin.
    expect(
      {MightTarget.attack, MightTarget.skill, MightTarget.alteration}.sentence(fr),
      'Votre Puissance renforce les dégâts de vos Attaques, les dégâts de vos '
      'Compétences et vos altérations.',
    );
    expect(
      {MightTarget.attack, MightTarget.skill, MightTarget.alteration}.sentence(en),
      'Your Might strengthens your Attack damage, your Skill damage and your '
      'alterations.',
    );
  });

  test('l ordre est celui de MightTarget, pas celui du Set', () {
    // Un `Set` littéral conserve l'ordre d'insertion : sans tri explicite, ce
    // test verrait « vos altérations et les dégâts de vos Attaques ».
    expect(
      {MightTarget.alteration, MightTarget.attack}.longLabel(fr),
      'les dégâts de vos Attaques et vos altérations',
    );
  });

  test('la forme courte n a pas bougé', () {
    // Elle sert au dialogue de stats (spec §7.4) et ne doit pas dériver.
    expect(
      {MightTarget.skill, MightTarget.alteration}.shortLabel(fr),
      'Compétences · Altérations',
    );
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/might_targets_long_label_test.dart`
Expected: FAIL — `The method 'sentence' isn't defined for the type 'Set<MightTarget>'`.

- [ ] **Step 3: Ajouter les clés ARB**

Edit `lib/l10n/app_en.arb`, à la suite de `mightTargetAlterationShort` :

```json
  "mightTargetAttackLong": "your Attack damage",
  "mightTargetSkillLong": "your Skill damage",
  "mightTargetAlterationLong": "your alterations",
  "listJoinAnd": "and",
  "@listJoinAnd": {
    "description": "Joins the last two items of an enumeration: A, B and C."
  },
  "mightTargetsSentence": "Your Might strengthens {targets}.",
  "@mightTargetsSentence": {
    "placeholders": {
      "targets": { "type": "String" }
    }
  },
```

Edit `lib/l10n/app_fr.arb`, à la suite de `mightTargetAlterationShort` :

```json
  "mightTargetAttackLong": "les dégâts de vos Attaques",
  "mightTargetSkillLong": "les dégâts de vos Compétences",
  "mightTargetAlterationLong": "vos altérations",
  "listJoinAnd": "et",
  "mightTargetsSentence": "Votre Puissance renforce {targets}.",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; les trois fichiers générés gagnent cinq getters.

- [ ] **Step 4: Écrire l'extension**

Edit `lib/models/data/model_extensions.dart` : ajouter les deux méthodes dans l'extension `MightTargetsLabels` existante, après `shortLabel`.

```dart
  /// Ce que renforce la Puissance, en toutes lettres et dans l'ordre de
  /// [MightTarget] : « les dégâts de vos Compétences et vos altérations »
  /// (spec P-41, §7.4). Deux cibles jointes par « et », trois par une virgule
  /// puis « et ».
  String longLabel(AppLocalizations l10n) {
    final parts = [
      for (final target in MightTarget.values)
        if (contains(target))
          switch (target) {
            MightTarget.attack => l10n.mightTargetAttackLong,
            MightTarget.skill => l10n.mightTargetSkillLong,
            MightTarget.alteration => l10n.mightTargetAlterationLong,
          },
    ];
    if (parts.length < 2) return parts.join();
    final debut = parts.sublist(0, parts.length - 1).join(', ');
    return '$debut ${l10n.listJoinAnd} ${parts.last}';
  }

  /// La phrase que lit le joueur à la sélection de classe (spec P-41, §8.3).
  /// Générée depuis l'orientation, jamais écrite classe par classe : c'est la
  /// règle d'ADR-090.
  String sentence(AppLocalizations l10n) =>
      l10n.mightTargetsSentence(longLabel(l10n));
```

- [ ] **Step 5: Vérifier**

Run: `flutter test test/unit/might_targets_long_label_test.dart` — Expected: `+5: All tests passed!`
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1074: All tests passed!` (1069 + 5).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/models/data/model_extensions.dart test/unit/might_targets_long_label_test.dart
git commit -m "feat(puissance): la forme longue de l orientation

Ecrite au lot C comme la spec l annoncait au 7.4 : generee depuis
mightTargets, dans l ordre de l enum, jointe par une virgule puis et. Sans
lecteur encore : l ecran de selection suit.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: La règle de stat, en clair

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/models/data/model_extensions.dart`
- Regenerate: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`
- Test: `test/unit/stat_rule_label_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `StatRule`, `RuleStat`, `RuleMode`, `RuleTarget` (`lib/models/data/stat_rule.dart`, partie 2 du lot B).
- Produces:
  - Clés ARB `statRuleConvertArmorToMight(duration)` et `statRuleConvertManaToMight(duration)`, à pluriel ICU.
  - `String StatRuleLabel.describe(AppLocalizations l10n)` — extension sur `StatRule` dans `model_extensions.dart`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/stat_rule_label_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';

/// La règle de stat d'une classe, écrite en clair pour l'écran de sélection
/// (spec P-41, §8.3) — « **générée à partir de la règle**, jamais écrite
/// classe par classe ».
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('la conversion d armure du Berserker, un tour', () {
    const regle = StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
    );

    expect(regle.describe(fr), 'Son Armure devient de la Puissance pour un tour.');
    expect(regle.describe(en), 'Their Armor becomes Might for one turn.');
  });

  test('une durée de plusieurs tours se met au pluriel', () {
    // Aucune classe livrée ne le fait ; c'est justement pourquoi le texte est
    // généré et non écrit à la main.
    const regle = StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 3,
    );

    expect(regle.describe(fr), 'Son Armure devient de la Puissance pour 3 tours.');
    expect(regle.describe(en), 'Their Armor becomes Might for 3 turns.');
  });

  test('une conversion de mana a son propre texte', () {
    // `RuleStat.mana` est légal depuis le lot B ; sans libellé, l'écran
    // afficherait un vide ou lèverait.
    const regle = StatRule(
      stat: RuleStat.mana,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
    );

    expect(regle.describe(fr), 'Son Mana devient de la Puissance pour un tour.');
    expect(regle.describe(en), 'Their Mana becomes Might for one turn.');
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/stat_rule_label_test.dart`
Expected: FAIL — `The method 'describe' isn't defined for the type 'StatRule'`.

- [ ] **Step 3: Ajouter les clés ARB, à pluriel ICU**

Edit `lib/l10n/app_en.arb`, à la suite de `mightTargetsSentence` :

```json
  "statRuleConvertArmorToMight": "{duration, plural, =1{Their Armor becomes Might for one turn.} other{Their Armor becomes Might for {duration} turns.}}",
  "@statRuleConvertArmorToMight": {
    "placeholders": {
      "duration": { "type": "int" }
    }
  },
  "statRuleConvertManaToMight": "{duration, plural, =1{Their Mana becomes Might for one turn.} other{Their Mana becomes Might for {duration} turns.}}",
  "@statRuleConvertManaToMight": {
    "placeholders": {
      "duration": { "type": "int" }
    }
  },
```

Edit `lib/l10n/app_fr.arb`, à la suite de `mightTargetsSentence` :

```json
  "statRuleConvertArmorToMight": "{duration, plural, =1{Son Armure devient de la Puissance pour un tour.} other{Son Armure devient de la Puissance pour {duration} tours.}}",
  "statRuleConvertManaToMight": "{duration, plural, =1{Son Mana devient de la Puissance pour un tour.} other{Son Mana devient de la Puissance pour {duration} tours.}}",
```

> **Premier pluriel ICU des ARB du projet** (décision 4). Si `flutter gen-l10n` se plaint, la cause est presque toujours une accolade non fermée ou un `duration` absent du bloc `@clé` du **gabarit** `app_en.arb` — le fichier français n'en porte pas.

Run: `flutter gen-l10n`
Expected: aucune erreur ; les trois fichiers générés gagnent deux méthodes prenant un `int`.

- [ ] **Step 4: Écrire l'extension**

Edit `lib/models/data/model_extensions.dart` : ajouter l'import `import 'stat_rule.dart';` et l'extension, à la suite de `MightTargetsLabels`.

```dart
extension StatRuleLabel on StatRule {
  /// La règle en clair : « Son Armure devient de la Puissance pour un tour. »
  ///
  /// Générée à partir de la règle, jamais écrite classe par classe
  /// (spec P-41, §8.3). Le `switch` est **exhaustif** sur le triplet
  /// (ressource, mode, cible) : ajouter une valeur à l'une des trois
  /// énumérations sans son libellé ne compile plus.
  String describe(AppLocalizations l10n) => switch ((stat, mode, to)) {
        (RuleStat.armor, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleConvertArmorToMight(duration),
        (RuleStat.mana, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleConvertManaToMight(duration),
      };
}
```

- [ ] **Step 5: Vérifier**

Run: `flutter test test/unit/stat_rule_label_test.dart` — Expected: `+3: All tests passed!`
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1077: All tests passed!` (1074 + 3).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/models/data/model_extensions.dart test/unit/stat_rule_label_test.dart
git commit -m "feat(classes): la regle de stat s ecrit en clair

Generee depuis la regle, sur un switch exhaustif du triplet ressource, mode,
cible. Premier pluriel ICU des ARB du projet, pour que la duree reste juste
au-dela d un tour.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `baseDamage` quitte `HeroData`, et l'épée quitte l'écran

**Une tâche de soustraction.** Elle enlève le champ, le badge qui l'affichait et l'icône qui l'accompagnait ; la tâche 5 remet quelque chose à la place. Les deux sont séparées parce qu'un relecteur peut accepter le retrait et discuter du remplacement.

**Files:**
- Modify: `lib/models/data/hero_data.dart`, `assets/data/classes/berserker/class.json`, `assets/data/classes/mage/class.json`, `assets/data/classes/paladin/class.json`, `lib/services/content_editor/entity_descriptor.dart`, `lib/ui/screens/class_selection_screen.dart`
- Delete: `lib/ui/widgets/sword_icon.dart`
- Modify (tests) : `test/unit/might_icon_test.dart`, `test/unit/content_editor/entity_descriptor_test.dart`, et **tous** les fichiers qui construisent un `HeroData` ou un JSON de classe avec `baseDamage`

**Interfaces:**
- Consumes: rien.
- Produces: `HeroData` sans `baseDamage`. **`EnemyData.baseDamage` ne bouge pas** : c'est une autre classe, avec de vrais lecteurs.

- [ ] **Step 1: Retirer le champ du modèle**

Edit `lib/models/data/hero_data.dart` : supprimer les trois lignes `final int baseDamage;`, `required this.baseDamage,` et `baseDamage: json['baseDamage'] as int,`.

- [ ] **Step 2: Laisser l'analyseur nommer tous les sites**

Run: `dart analyze`
Expected: une erreur `No named parameter with the name 'baseDamage'` par construction de `HeroData`, plus `The getter 'baseDamage' isn't defined for the class 'HeroData'` à `class_selection_screen.dart:350`.

**C'est la liste de travail.** Elle porte sur **37 fichiers de test** et un fichier de `lib/`. Pour chacun : supprimer la ligne `baseDamage: N,` du `HeroData(...)`, sans rien changer d'autre. **Ne pas toucher** aux `baseDamage:` des `EnemyData(...)` — les deux se côtoient dans plusieurs fichiers (`test/unit/combat_controller_test.dart`, `test/unit/run_controller_test.dart`, `test/widget/map_screen_test.dart`, `test/unit/game_data_registry_preload_test.dart`, `test/encounter_system_test.dart`). L'analyseur ne signale que les premières : s'il se tait sur une ligne, c'est un ennemi, et elle reste.

> **37 et non 36** : il y en a exactement 36 sur le `main` d'avant le lot C, et la partie 1 en ajoute un — `test/unit/level_up_reward_apply_test.dart`, dont le Paladin de fixture porte `baseDamage: 5`. Ne pas se fier au chiffre : se fier à l'analyseur, qui les nomme tous.

- [ ] **Step 3: Retirer la clé des trois classes**

Edit `assets/data/classes/berserker/class.json`, `mage/class.json`, `paladin/class.json` : supprimer la ligne `"baseDamage": N,`.

- [ ] **Step 4: Nettoyer les fixtures JSON**

Ces fichiers portent `baseDamage` dans une **table JSON de classe**, que l'analyseur ne signale pas : `HeroData.fromJson` se contenterait de l'ignorer. Les nettoyer quand même — une clé que plus rien ne lit est exactement ce que la spec supprime.

- `test/unit/hero_data_identity_test.dart:14`
- `test/unit/might_target_test.dart:45`
- `test/unit/stat_rule_test.dart:82`
- `test/unit/content_editor/fixtures.dart:43`
- `test/unit/content_editor/entity_writer_test.dart:168`
- `test/unit/content_editor/entity_validator_test.dart` — **trois** sites de classe : `:377`, `:437`, `:476`
- `test/widget/content_editor_screen_test.dart` — **six** sites de classe : `:85`, `:432`, `:827`, `:1032`, `:1386`, `:1705`

**Trois sites d'ennemi se cachent dans cette même liste de fichiers, et ils restent** — `baseDamage` est une `requiredKeys` du descripteur d'ennemi, les retirer ferait rougir le validateur :

- `test/unit/content_editor/entity_validator_test.dart:584` — `kEntityDescriptors[EntityCategory.enemy]`, `mechanics: '{"maxHp": 30, "baseDamage": 5, "intents": [...]}'`
- `test/widget/content_editor_screen_test.dart:1468` — `assets/data/enemies/gobelin/enemy.json`
- `test/unit/audio/audio_source_models_test.dart:53` — `EnemyData.fromJson`

Le signe qui départage sans se tromper : un JSON de **classe** porte `maxMana` et/ou `mightTargets`, jamais un ennemi.

- [ ] **Step 5: Retirer la clé de l'éditeur de contenu**

Edit `lib/services/content_editor/entity_descriptor.dart`, descripteur `EntityCategory.heroClass` — `requiredKeys` à la ligne **357** :

```dart
    requiredKeys: const {'maxHp', 'maxMana', 'mightTargets'},
```

et, dans son gabarit, supprimer la ligne `"baseDamage": 5,` (ligne **375**). **Ne pas toucher** au descripteur `EntityCategory.enemy`, qui suit immédiatement et porte les deux mêmes formes aux lignes **389** et **401** : `baseDamage` y reste obligatoire.

> La spec §8.3 cite `entity_descriptor.dart:328` et `:341` : ces numéros datent d'avant les lots A et B, qui ont allongé le fichier. Les deux sites sont bien ceux décrits, aux lignes ci-dessus.

Edit `test/unit/content_editor/entity_descriptor_test.dart` : retirer `'baseDamage'` des deux listes de clés attendues pour `EntityCategory.heroClass` (autour de `:154` et `:244`). Celle de `EntityCategory.enemy` (`:254`) reste.

- [ ] **Step 6: Retirer le badge et l'icône**

Edit `lib/ui/screens/class_selection_screen.dart` : supprimer, dans la rangée de badges, le séparateur et le badge de l'épée — du `Container(width: 1, ...)` qui précède `SwordIcon` jusqu'à la fin de ce `_buildStatBadge`. Il reste PV et mana ; la tâche 5 remplira la place.

Supprimer aussi l'import `import '../widgets/sword_icon.dart';`.

Run: `git rm lib/ui/widgets/sword_icon.dart`

- [ ] **Step 7: Mettre à jour le garde-fou de l'icône**

Edit `test/unit/might_icon_test.dart`, premier test :

```dart
  test('l epee n a plus aucun usage', () {
    // `baseDamage` est parti au lot C (spec §8.3), et avec lui le dernier
    // badge qui montrait une epee pour une stat de puissance.
    expect(File('lib/ui/widgets/sword_icon.dart').existsSync(), isFalse);

    for (final file in dartFilesOf('lib')) {
      expect(
        file.readAsStringSync().contains('SwordIcon'),
        isFalse,
        reason: normalized(file),
      );
    }
  });
```

- [ ] **Step 8: Mettre à jour le test d'écran**

Edit `test/widget/class_selection_screen_test.dart` : retirer les cinq `baseDamage: N,` des `HeroData(...)`, puis ajouter, dans le premier groupe :

```dart
  testWidgets('aucune classe n affiche de degats de base', (
    WidgetTester tester,
  ) async {
    // L'ecran affichait `playerClass.baseDamage` — 5 / 15 / 10 — alors que
    // toute run demarre a 0 (spec P-41, §8.3). Le champ n'existe plus ; ce
    // test empeche qu'un chiffre equivalent revienne.
    await _buildAndReady(tester);

    for (final chiffre in ['5', '15', '10']) {
      expect(find.text(chiffre), findsNothing);
    }
  });
```

> Si l'un de ces chiffres apparaît légitimement ailleurs sur la carte (un `maxMana` à 3, un `maxHp` à 100 : aucun des trois), adapter le mock de `_heroes` plutôt que d'affaiblir l'assertion.

- [ ] **Step 9: Vérifier**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1078: All tests passed!` (1077 + 1).

Si `test/unit/real_bundle_load_test.dart` ou `test/unit/referential_integrity_test.dart` rougissent : le bundle de test porte encore les anciens `class.json`. Supprimer `build/unit_test_assets/assets/data/classes/` et relancer.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat(classes): baseDamage quitte HeroData, et l epee l ecran

L ecran de selection affichait 5, 15 et 10 alors que toute run demarre a 0 :
le champ n a aucun consommateur de jeu cote heros, et le retablir est
explicitement ecarte (spec 11). EnemyData le garde. sword_icon.dart, sans
autre usage, disparait.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: L'écran montre ce qui diffère réellement

**Files:**
- Modify: `lib/ui/screens/class_selection_screen.dart`
- Test: `test/widget/class_selection_screen_test.dart`

**Interfaces:**
- Consumes: `MightTargetsLabels.sentence` (tâche 2), `StatRuleLabel.describe` (tâche 3), `HeroData.mastery`, `HeroData.critChance`, `HeroData.luck`, `HeroData.statRules`, `HeroData.mightTargets`.
- Produces: rien qu'une autre tâche consomme.

- [ ] **Step 1: Écrire les tests qui échouent**

Edit `test/widget/class_selection_screen_test.dart` : ajouter le groupe suivant, à la fin de `main()`.

```dart
  group('l identite de la classe est generee depuis sa donnee', () {
    const berserker = HeroData(
      id: 'berserker',
      nameEn: 'Berserker',
      nameFr: 'Le Berserker',
      classCard: 'hero_berserker.png',
      maxHp: 80,
      maxMana: 3,
      critChance: 10,
      mightTargets: {MightTarget.attack},
      statRules: [
        StatRule(
          stat: RuleStat.armor,
          mode: RuleMode.convert,
          to: RuleTarget.statusMight,
          duration: 1,
        ),
      ],
    );

    const mage = HeroData(
      id: 'mage',
      nameEn: 'Mage',
      nameFr: 'Le Mage',
      classCard: 'hero_mage.png',
      maxHp: 60,
      maxMana: 3,
      mightTargets: {MightTarget.skill, MightTarget.alteration},
    );

    const paladin = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Le Paladin',
      classCard: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      mastery: 1,
      mightTargets: {MightTarget.attack, MightTarget.skill, MightTarget.alteration},
    );

    testWidgets('ce que renforce la Puissance est ecrit en toutes lettres', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [mage],
        locale: const Locale('fr', ''),
      );

      expect(
        find.text(
          'Votre Puissance renforce les dégâts de vos Compétences et vos '
          'altérations.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('la regle de stat est ecrite en clair, et seulement si elle existe', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [berserker],
        locale: const Locale('fr', ''),
      );
      expect(
        find.text('Son Armure devient de la Puissance pour un tour.'),
        findsOneWidget,
      );

      await _buildAndReady(
        tester,
        heroes: const [mage],
        locale: const Locale('fr', ''),
      );
      expect(find.textContaining('devient de la Puissance'), findsNothing);
    });

    testWidgets('seules les stats de depart non nulles sont montrees', (
      WidgetTester tester,
    ) async {
      // Le Paladin : Maitrise 1, pas de critique, pas de chance.
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        locale: const Locale('fr', ''),
      );
      expect(find.text('1'), findsOneWidget, reason: 'la Maîtrise');
      expect(find.textContaining('%'), findsNothing, reason: 'aucun critique');

      // Le Mage : ni Maitrise, ni critique, ni chance — PV et mana seuls.
      await _buildAndReady(
        tester,
        heroes: const [mage],
        locale: const Locale('fr', ''),
      );
      expect(find.text('60'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsNothing, reason: 'une stat nulle ne se montre pas');
    });

    testWidgets('le critique de depart du Berserker est montre', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [berserker],
        locale: const Locale('fr', ''),
      );

      expect(find.text('10%'), findsOneWidget);
    });
  });
```

Ajouter les imports nécessaires en tête du fichier :

```dart
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/might_target.dart';
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/widget/class_selection_screen_test.dart`
Expected: FAIL — les quatre nouveaux tests ne trouvent ni la phrase d'orientation, ni la règle, ni les badges de stat.

- [ ] **Step 3: Générer les badges de stats de départ**

Edit `lib/ui/screens/class_selection_screen.dart` : remplacer le `Row` de la rangée de badges par un `Wrap` alimenté par une liste construite depuis la donnée. Dans `build`, à côté de `classColor` :

```dart
    // PV et mana toujours : ce sont les deux reperes que le joueur compare
    // d'une classe a l'autre. Les trois autres seulement si elles disent
    // quelque chose — « PV max et stats de depart non nulles » (spec §8.3).
    // Genere depuis la donnee : aucun `hero.id` n'est compare (ADR-090).
    final statBadges = <({Widget icon, String value})>[
      (
        icon: Icon(
          Icons.favorite,
          size: widget.isMobile ? 14 : 16,
          color: Colors.redAccent,
        ),
        value: '${playerClass.maxHp}',
      ),
      (
        icon: Icon(
          Icons.diamond_rounded,
          size: widget.isMobile ? 14 : 16,
          color: Colors.cyanAccent,
        ),
        value: '${playerClass.maxMana}',
      ),
      if (playerClass.mastery > 0)
        (
          icon: Icon(
            Icons.shield_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.lightBlueAccent,
          ),
          value: '${playerClass.mastery}',
        ),
      if (playerClass.critChance > 0)
        (
          icon: Icon(
            Icons.bolt_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.redAccent,
          ),
          value: '${playerClass.critChance}%',
        ),
      if (playerClass.luck > 0)
        (
          icon: Icon(
            Icons.casino_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.amberAccent,
          ),
          value: '${playerClass.luck}',
        ),
    ];
```

> Les icônes et leurs couleurs sont celles du dialogue de stats de la run (`lib/ui/widgets/map/dialogs/stats_dialog.dart`) : la même stat porte le même signe des deux côtés.

Remplacer le contenu du `Container` de la rangée :

```dart
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: widget.isMobile ? 8 : 14,
                                    runSpacing: widget.isMobile ? 2 : 4,
                                    children: [
                                      for (final badge in statBadges)
                                        _buildStatBadge(badge.icon, badge.value),
                                    ],
                                  ),
```

Le `Wrap` remplace le `Row` avec séparateurs : une quatrième stat non nulle passerait à la ligne au lieu de déborder la carte (décision 5).

- [ ] **Step 4: Ajouter le bloc d'identité de la Puissance**

Edit `lib/ui/screens/class_selection_screen.dart` : insérer, juste après le `Container` de la rangée de badges et son `SizedBox`, un bloc de deux phrases.

```dart
                                // Ce que renforce la Puissance de la classe,
                                // et ce qu'elle convertit — genere depuis
                                // `mightTargets` et `statRules`, jamais ecrit
                                // classe par classe (spec §8.3, ADR-090).
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 4 : 12,
                                    vertical: widget.isMobile ? 4 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(
                                      widget.isMobile ? 6 : 10,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        playerClass.mightTargets.sentence(l10n),
                                        style: TextStyle(
                                          fontSize: widget.isMobile ? 9.5 : 10.5,
                                          color: Colors.orangeAccent.withValues(
                                            alpha: 0.9,
                                          ),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      for (final rule in playerClass.statRules) ...[
                                        SizedBox(height: widget.isMobile ? 2 : 4),
                                        Text(
                                          rule.describe(l10n),
                                          style: TextStyle(
                                            fontSize: widget.isMobile ? 9.5 : 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.orangeAccent.withValues(
                                              alpha: 0.75,
                                            ),
                                            height: 1.25,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 4 : 12),
```

Ajouter les imports `import '../../models/data/model_extensions.dart';` (il porte les deux extensions). `l10n` est déjà en portée dans ce `build`.

- [ ] **Step 5: Vérifier**

Run: `flutter test test/widget/class_selection_screen_test.dart` — Expected: tous verts (9 + 1 de la tâche 4 + 4 = 14).
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1082: All tests passed!` (1078 + 4).

- [ ] **Step 6: Regarder la carte**

Run: `flutter run -d windows` — choisir « Nouvelle partie » pour atteindre l'écran de sélection.
Expected: les trois cartes tiennent sans débordement (`RenderFlex overflowed` dans la console est un défaut), en fenêtre large **et** rétrécie sous 600 px de large, où le mode mobile s'active. Si une carte déborde, réduire les `fontSize` du bloc d'identité ou son `padding` — **pas** en tronquant une phrase générée.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/screens/class_selection_screen.dart test/widget/class_selection_screen_test.dart
git commit -m "feat(classes): l ecran de selection montre ce qui differe vraiment

Stats de depart non nulles, ce que renforce la Puissance en toutes lettres, et
la regle de stat en clair. Les trois sont generes depuis la donnee : aucun
ecran ne compare un identifiant de classe.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Le choix du passif

La dernière pièce du §8.3, et celle qui referme la conséquence n° 1 du plan de la partie 2 du lot B : « **Un seul des trois passifs d'une classe est atteignable** avant le lot C ».

**Files:**
- Modify: `lib/ui/screens/class_selection_screen.dart`
- Test: `test/widget/class_selection_screen_test.dart`

**Interfaces:**
- Consumes: `availablePassivesFor` (`lib/game/systems/passive_availability.dart`, P-49) ; `StarterDeckDraftScreen({required HeroData playerClass, required PassiveData? passive})`, déjà en place.
- Produces: rien qu'une autre tâche consomme.

- [ ] **Step 1: Écrire les tests qui échouent**

Edit `test/widget/class_selection_screen_test.dart` : ajouter le groupe suivant, à la fin de `main()`.

```dart
  group('le joueur choisit son passif', () {
    const ward = PassiveData(
      id: 'ward',
      nameEn: 'Ward',
      nameFr: 'Garde',
      descriptionFr: 'Gagne 2 Armure en fin de tour.',
      descriptionEn: 'Gain 2 Block at end of turn.',
      classes: ['paladin'],
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
      displayOrder: 1,
    );
    const zeal = PassiveData(
      id: 'zeal',
      nameEn: 'Zeal',
      nameFr: 'Zele',
      descriptionFr: 'Gagne 1 Puissance au debut du tour.',
      descriptionEn: 'Gain 1 Might at the start of the turn.',
      classes: ['paladin'],
      trigger: RelicTrigger.startOfTurn,
      effectType: 'rage',
      value: 1,
      displayOrder: 2,
    );

    const paladin = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Le Paladin',
      classCard: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
    );

    testWidgets('tous les passifs disponibles sont proposes', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward, zeal],
      );

      expect(find.text('WARD'), findsOneWidget);
      expect(find.text('ZEAL'), findsOneWidget);
    });

    testWidgets('le premier du point d acces est selectionne par defaut', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward, zeal],
      );

      // La description du passif selectionne est celle qui s'affiche.
      expect(find.text('Gain 2 Block at end of turn.'), findsOneWidget);
      expect(find.text('Gain 1 Might at the start of the turn.'), findsNothing);
    });

    testWidgets('choisir un autre passif change ce que l ecran pousse', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward, zeal],
      );

      await tester.tap(find.text('ZEAL'));
      await tester.pump();

      expect(find.text('Gain 1 Might at the start of the turn.'), findsOneWidget);

      await tester.tap(find.text('Select'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pushed = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushed.passive?.id, 'zeal');
    });

    testWidgets('un seul passif disponible : aucun selecteur, et il est pousse', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        heroes: const [paladin],
        passives: const [ward],
      );

      expect(find.text('WARD'), findsOneWidget);

      await tester.tap(find.text('Select'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pushed = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushed.passive?.id, 'ward');
    });

    testWidgets('aucun passif disponible : l ecran reste utilisable', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(tester, heroes: const [paladin]);

      await tester.tap(find.text('Select'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final pushed = tester.widget<StarterDeckDraftScreen>(
        find.byType(StarterDeckDraftScreen),
      );
      expect(pushed.passive, isNull);
    });
  });
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/widget/class_selection_screen_test.dart`
Expected: FAIL — `ZEAL` n'est pas affiché : l'écran ne montre que `passives.first`.

- [ ] **Step 3: Porter le choix dans l'état de la carte**

Edit `lib/ui/screens/class_selection_screen.dart`, dans `_InteractiveClassCardState` : ajouter le champ

```dart
  /// Le passif retenu, par son rang dans `availablePassivesFor` — le point
  /// d'accès unique de P-49 (spec §5.1, P5). Le premier par défaut, et le
  /// choix du joueur ensuite (spec §8.3).
  int _passiveIndex = 0;
```

puis, dans `build`, remplacer les deux lignes qui prennent le premier passif :

```dart
    final passives = availablePassivesFor(playerClass, gameData);
    // Le rang peut sortir de la liste si la donnée change sous l'écran : on
    // retombe sur le premier plutôt que de lever.
    final index = _passiveIndex < passives.length ? _passiveIndex : 0;
    final passive = passives.isEmpty ? null : passives[index];
```

- [ ] **Step 4: Afficher le sélecteur**

Edit `lib/ui/screens/class_selection_screen.dart` : dans le bloc du passif, remplacer la `Row` qui affiche l'icône et `traitName` par une rangée de noms sélectionnables. Le nom seul, quand il n'y a qu'un passif, garde exactement l'apparence d'aujourd'hui.

```dart
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: widget.isMobile ? 6 : 10,
                                        runSpacing: 2,
                                        children: [
                                          for (var i = 0; i < passives.length; i++)
                                            GestureDetector(
                                              onTap: passives.length == 1
                                                  ? null
                                                  : () => setState(
                                                        () => _passiveIndex = i,
                                                      ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.shield,
                                                    size: widget.isMobile ? 12 : 16,
                                                    color: Colors.cyanAccent
                                                        .withValues(
                                                      alpha: i == index ? 1.0 : 0.35,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: widget.isMobile ? 3 : 6,
                                                  ),
                                                  Text(
                                                    passives[i]
                                                        .getName(locale)
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize:
                                                          widget.isMobile ? 10 : 11,
                                                      fontWeight: i == index
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: Colors.cyanAccent
                                                          .withValues(
                                                        alpha:
                                                            i == index ? 1.0 : 0.45,
                                                      ),
                                                      letterSpacing: 0.8,
                                                      decoration: i == index
                                                          ? TextDecoration.underline
                                                          : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (passives.isEmpty)
                                            Text(
                                              '—',
                                              style: TextStyle(
                                                fontSize: widget.isMobile ? 10 : 11,
                                                color: Colors.cyanAccent,
                                              ),
                                            ),
                                        ],
                                      ),
```

`traitName` n'a plus de lecteur : le supprimer. `traitDesc` et `masteryPerPoint` restent, et suivent le passif sélectionné puisqu'ils sont calculés depuis `passive`.

- [ ] **Step 5: Vérifier**

Run: `flutter test test/widget/class_selection_screen_test.dart` — Expected: tous verts (14 + 5 = 19).
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1087: All tests passed!` (1082 + 5).

- [ ] **Step 6: Regarder l'écran**

Run: `flutter run -d windows` — atteindre l'écran de sélection, cliquer les trois passifs d'une classe, vérifier que la description et la ligne de Maîtrise suivent, puis lancer une run et confirmer en combat que c'est bien le passif choisi qui agit.
Expected: aucun débordement, le passif choisi est celui qui se déclenche.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/screens/class_selection_screen.dart test/widget/class_selection_screen_test.dart
git commit -m "feat(classes): le joueur choisit son passif a la selection

Les passifs disponibles sont lus par le point d acces unique de P-49 et tous
proposes, pas seulement le premier. Referme la consequence annoncee au lot B
partie 2 : six passifs sur neuf etaient livres sans etre atteignables.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Vérification finale et pull request

**Files:**
- Aucun changement de code attendu. Si une vérification rougit, la corriger dans une tâche à part — pas ici.

**Interfaces:**
- Consumes: les tâches 1 à 6.
- Produces: la PR de la partie 2 du lot C.

- [ ] **Step 1: La suite complète, deux fois**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1087: All tests passed!`
Run: `flutter test` une seconde fois — Expected: **le même compte**. Les tests de filtre échantillonnent 2 000 tirages : deux passages verts d'affilée écartent un test rendu instable par le rétrécissement de la table.

- [ ] **Step 2: `baseDamage` a bien quitté le héros**

Run: `git grep -n "baseDamage" -- lib assets`
Expected: uniquement des sites d'**ennemi** — `enemy_data.dart`, `combat_controller.dart`, `combat_debug_logger.dart`, `encounter_system.dart`, `enemy_instance.dart`, `tutorial_engine.dart`, `tutorial_enemy_intents_widget.dart`, le descripteur `EntityCategory.enemy` et les quatre `assets/data/enemies/*/enemy.json`. **Aucune occurrence** dans `hero_data.dart`, dans les trois `class.json`, ni dans `class_selection_screen.dart`.

Run: `git grep -n "SwordIcon" -- lib`
Expected: **aucune sortie**.

- [ ] **Step 3: Aucune comparaison d'identifiant de classe n'est apparue**

Run: `git grep -n "id == 'berserker'\|id == 'mage'\|id == 'paladin'\|id == \"berserker\"" -- lib`
Expected: **aucune sortie** — c'est la règle d'ADR-090, et ce lot est celui où la tentation était la plus forte.

- [ ] **Step 4: Le pubspec ne dérive pas**

Run: `dart run tool/sync_assets.dart --check`
Expected: code de retour 0.

- [ ] **Step 5: Rien de généré n'est en attente**

Run: `git status --short`
Expected: aucune sortie. Si `macos/Flutter/GeneratedPluginRegistrant.swift`, `linux/flutter/` ou `windows/flutter/` apparaissent : `git checkout --` dessus, ne jamais les commiter.

- [ ] **Step 6: Ouvrir la pull request**

```bash
git push -u origin feat/p41-lot-c-selection
```

Titre : `P-41 lot C, partie 2 — Filtre d Affinite et ecran de selection`

Corps :

```
Implemente les §8.2 et §8.3 de la spec S2, et cloture le lot C.

- *Affinite* n est plus tiree quand le passif actif ne declare aucune
  Maitrise — un champ `requires` sur la recompense, lu par le tirage : le
  mecanisme, pas la recompense. Les neuf passifs livres en declarent tous un,
  donc aucune run reelle ne change encore.
- `baseDamage` quitte `HeroData`, les trois `class.json` et l editeur.
  L ecran affichait 5 / 15 / 10 alors que toute run demarre a 0.
  `EnemyData` le garde. `sword_icon.dart`, sans autre usage, disparait.
- L ecran de selection montre a la place : les stats de depart non nulles,
  ce que renforce la Puissance de la classe en toutes lettres, sa regle de
  stat en clair, et le choix du passif parmi ceux que le point d acces de
  P-49 lui ouvre. Les trois textes sont generes depuis la donnee ; aucun
  ecran ne compare un identifiant de classe (ADR-090).

Cela referme la consequence annoncee au lot B partie 2 : six des neuf passifs
etaient livres, testes et jouables, mais inatteignables sans cet ecran.

`dart analyze` propre, `flutter test` vert (1087 tests, contre 1063 au depart).

Restent au lot D : le tutoriel et la console de debug (spec §9).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 7: Après la fusion**

Une fois la PR fusionnée, lancer le skill `patch-notes-writer` (la note `0.5.2` est rouverte en place, cf. `docs/ROADMAP.md`) puis le skill `memory-bank-sync`. Les deux sont agent-gérés : ne pas éditer `assets/data/patch_notes.json`, `pubspec.yaml` (`version:`) ni `.obsidian_vault/_memory_bank/` à la main.

---

## Suites connues, laissées ouvertes

| Sujet | Où il vit |
|:---|:---|
| L'étape de choix de classe du tutoriel propose les passifs disponibles ; `tutorial_fixtures.dart:57` cesse de supposer un passif unique | Lot D, spec §9.1 |
| L'étape « Armure » du tutoriel, fausse pour le Berserker depuis la conversion | Lot D, spec §9.1 |
| Le réglage de Puissance de la console gagne le choix des cibles ; la run affichée expose son orientation, ses règles de stat et son passif actif | Lot D, spec §9.2 |
| L'éditeur valide `statRules` et `classes` ; la catégorie « récompense de niveau » devient éditable ; la création guidée de classe garantit un passif | Lot D, spec §9.2 |
| Le rééquilibrage des valeurs et des paliers de récompense, *Sagesse* en tête | P-16, spec §8.4 |
| Le déblocage des passifs par personnage, derrière le point d'accès de P-49 | P-13, spec §10 |
| **Les récompenses dédiées par passif, tirables tous les 5 niveaux** — le joueur choisit entre trois améliorations de passif pour adapter sa run, au lieu d'une chance diluée à chaque niveau. La stat *Maîtrise* et *Affinité* y seraient **remplacées**. C'est une reprise de la conception d'origine du §8.2, écartée par N1 de P-49 parce qu'elle mettait neuf récompenses dans le même pool que les six autres ; la cadence de cinq niveaux lève cette objection. Ce que la partie 1 pose pour ça : un pool est une valeur de `RewardPool`, une exigence un champ `requires`. Il manquerait une exigence **paramétrée** (`"requiresPassive": "rage"`) et une cadence de tirage, aujourd'hui absente du modèle | Idée du propriétaire, 2026-09-18 — [`docs/possible_upgrades/upgrade_ideas.md`](../../possible_upgrades/upgrade_ideas.md) (ligne « récompenses dédiés par passifs ») ; trace de la conception d'origine : spec §8.2 |
| **Plusieurs passifs actifs, et ce que devient *Affinité***. Impossible aujourd'hui et volontairement : `RunState.activePassive` est singulier (spec §5.1, P6) et `TraitSystem.dispatch` ne lit que lui (`trait_system.dart:14`). Le jour où P-13 l'ouvre, la Maîtrise étant **une stat de run unique** (`entity_stats.dart:168`) appliquée à chaque dispatch par `withMastery`, **tous** les passifs actifs en profiteraient à la fois : la valeur d'*Affinité* croîtrait avec le nombre d'emplacements. Trois réponses possibles — diviser sa courbe par le nombre d'emplacements, laisser le joueur désigner le passif qu'un point renforce, ou revenir aux neuf récompenses dédiées du §8.2 (qui, elles, empirent avec plusieurs emplacements : leur argument « une seule éligible par run » tombe). Côté code, le filtre de la tâche 1 devient `passives.any((p) => p.mastery != null)` — une signature, deux appelants —, et une récompense conditionnée à **un passif nommé** demanderait une exigence *paramétrée* (`"requiresPassive": "rage"`), soit un champ de plus et une branche dans `isAvailableWith`, sans restructuration | P-13, spec §10 et §11 (« Plusieurs passifs actifs d'emblée ») ; forme de la Maîtrise : spec de P-49, N1 |
