# Menu de debug — lot 1 : manipulateur de run — Plan d'implémentation

> **Pour les agents exécutants :** SOUS-COMPÉTENCE REQUISE — utiliser
> `superpowers:subagent-driven-development` (recommandé) ou `superpowers:executing-plans`
> pour dérouler ce plan tâche par tâche. Les étapes sont cochables (`- [ ]`).

**But :** donner un menu de debug capable de modifier l'état d'une run en cours — stats du héros,
or, acte, deck, reliques, PV des ennemis — sans jouer la run, et sans jamais atteindre un build
publié.

**Architecture :** une classe statique `DebugActions` reçoit un `RefReader` et compose les
contrôleurs Riverpod existants, exactement comme `SaveService`. Aucune méthode nouvelle n'est
ajoutée aux contrôleurs : `updateState`, `hydrate`, `updateEnemyStats` et `cleanDeadEnemies` sont
déjà publics. Un drapeau de contamination coupe l'autosave dès la première action.

**Pile technique :** Flutter, Riverpod 2.x (`Notifier` / `NotifierProvider`), `flutter_test`.

**Spec :** [`docs/superpowers/specs/2026-09-05-menu-debug-lot-1-manipulateur-de-run-design.md`](../specs/2026-09-05-menu-debug-lot-1-manipulateur-de-run-design.md)

## Contraintes globales

- **`dart analyze` doit rendre zéro problème** après chaque tâche, avant tout commit.
- **Aucune écriture disque.** Ce lot ne touche qu'aux providers. Pas de `dart:io`, pas de
  `SharedPreferences`, pas d'écriture d'asset. C'est le lot 2 qui écrira des fichiers.
- **Aucune méthode nouvelle sur les contrôleurs existants.** Si une action semble en réclamer une,
  c'est le signe qu'elle sort du périmètre — la signaler plutôt que d'élargir la surface publique.
- **Double garde `kDebugMode`** : chaque méthode publique de `DebugActions` commence par
  `if (!kDebugMode) return;`, et le point d'entrée UI est enveloppé dans `if (kDebugMode)`.
- **Pas de localisation ARB pour ce menu.** Les libellés sont écrits en français directement dans
  le code. C'est une **exception délibérée** à la règle du dépôt qui fait passer les chaînes d'UI
  par `lib/l10n/` : ajouter une quarantaine de clés bilingues pour un outil qui n'est jamais publié
  serait un coût pur. Cette exception ne vaut que pour `lib/ui/widgets/debug/`.
- **Messages de commit en français**, conventional commits, **sans accents dans la ligne de sujet**
  (le corps peut en porter), terminés par
  `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Branche de travail : `feat/menu-debug-lot-1`, déjà créée.

## Structure des fichiers

| Fichier | Responsabilité |
|:---|:---|
| `lib/game/controllers/debug_taint_controller.dart` *(créé)* | Le drapeau seul. Volontairement séparé de `DebugActions` : `checkpoint_controller` en dépend, et ne doit pas tirer tout l'outil de debug derrière lui |
| `lib/game/services/debug_actions.dart` *(créé)* | Toutes les mutations. Aucun état propre |
| `lib/ui/widgets/debug/debug_menu_dialog.dart` *(créé)* | La coquille à onglets |
| `lib/ui/widgets/debug/debug_number_field.dart` *(créé)* | Champ entier réutilisé par trois onglets |
| `lib/ui/widgets/debug/tabs/*.dart` *(créés)* | Un fichier par onglet |
| `lib/game/controllers/checkpoint_controller.dart` *(modifié)* | Lit le drapeau avant de sauvegarder |
| `lib/game/controllers/run_controller.dart` *(modifié)* | Rabaisse le drapeau dans `startNewRun` |
| `lib/ui/widgets/hud/dialogs/pause_dialog.dart` *(modifié)* | Le bouton d'ouverture |

---

### Task 1 : Le drapeau de contamination et la suppression de l'autosave

**Files:**
- Create: `lib/game/controllers/debug_taint_controller.dart`
- Modify: `lib/game/controllers/checkpoint_controller.dart:18-23`
- Modify: `lib/game/controllers/run_controller.dart:238-270` (fin de `startNewRun`)
- Test: `test/unit/debug_taint_test.dart`

**Interfaces:**
- Consomme : `checkpointProvider`, `autosaveOrchestratorProvider`, `runProvider` — existants.
- Produit : `debugTaintProvider` (`NotifierProvider<DebugTaintNotifier, bool>`),
  `DebugTaintNotifier.taint()` → `void`, `DebugTaintNotifier.clear()` → `void`.

- [ ] **Étape 1 : écrire le test qui échoue**

Créer `test/unit/debug_taint_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_taint_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/save_service.dart';

void main() {
  const paladin = HeroData(
    id: 'paladin',
    nameEn: 'Paladin',
    nameFr: 'Paladin',
    descriptionEn: 'A holy knight',
    descriptionFr: 'Un saint chevalier',
    iconPath: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
    luck: 0,
    armorMastery: 0,
    passiveTrait: 'regen_armor',
  );

  group('Drapeau de contamination debug', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('une session neuve part non contaminee', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(debugTaintProvider), isFalse);
    });

    test('drapeau leve : un checkpoint ne declenche aucune sauvegarde', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(debugTaintProvider.notifier).taint();
      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isFalse);
    });

    test('startNewRun rabaisse le drapeau et l autosave reprend', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(debugTaintProvider.notifier).taint();
      container.read(runProvider.notifier).startNewRun(paladin);
      expect(container.read(debugTaintProvider), isFalse);

      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });

    test('drapeau baisse : le comportement d autosave existant est intact', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });
  });
}
```

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

```
flutter test test/unit/debug_taint_test.dart
```

Attendu : ÉCHEC à la compilation — `debug_taint_controller.dart` n'existe pas.

- [ ] **Étape 3 : créer le contrôleur du drapeau**

Créer `lib/game/controllers/debug_taint_controller.dart` :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vrai des qu'une action du menu de debug a touche la run en cours.
///
/// Une run trafiquee ne doit pas produire de sauvegarde : rechargee plus tard,
/// elle serait indistinguable d'une run legitime. Le drapeau est donc
/// volontairement sans retour arriere pour la run courante — seul
/// `RunController.startNewRun` le rabaisse, pour qu'une run neuve reparte
/// propre.
///
/// Ce drapeau vit a l'ecart de `DebugActions` pour que
/// `checkpoint_controller.dart`, qui le lit, ne depende pas de tout l'outillage
/// de debug.
class DebugTaintNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void taint() => state = true;

  /// Reserve au demarrage d'une nouvelle run.
  void clear() => state = false;
}

final debugTaintProvider =
    NotifierProvider<DebugTaintNotifier, bool>(DebugTaintNotifier.new);
```

- [ ] **Étape 4 : brancher la suppression de l'autosave**

Dans `lib/game/controllers/checkpoint_controller.dart`, ajouter l'import
`import 'debug_taint_controller.dart';` et remplacer le corps de l'orchestrateur :

```dart
/// Écoute checkpointProvider et déclenche une sauvegarde à chaque bump().
/// Doit être lu une fois au démarrage de l'app pour s'activer (voir main.dart).
///
/// Une run touchée par le menu de debug ne se sauvegarde plus : la sauvegarde
/// déjà présente sur le disque reste celle d'avant.
final autosaveOrchestratorProvider = Provider<void>((ref) {
  ref.listen<int>(checkpointProvider, (previous, next) {
    if (ref.read(debugTaintProvider)) return;
    SaveService.save(ref.read);
  });
});
```

- [ ] **Étape 5 : rabaisser le drapeau au démarrage d'une run**

Dans `lib/game/controllers/run_controller.dart`, ajouter l'import
`import 'debug_taint_controller.dart';`, puis, **à la fin** de `startNewRun`, juste après le bloc
`ref.read(inventoryProvider.notifier).reset(...)` :

```dart
    // Une run neuve repart propre : le menu de debug n'a pas encore touche a
    // son etat, l'autosave doit reprendre. `kDebugMode` etant une constante de
    // compilation, cette ligne disparait du build release.
    if (kDebugMode) {
      ref.read(debugTaintProvider.notifier).clear();
    }
```

`kDebugMode` est déjà importé en tête du fichier (`package:flutter/foundation.dart`) — ne pas
ajouter d'import en double.

- [ ] **Étape 6 : lancer les tests et vérifier qu'ils passent**

```
flutter test test/unit/debug_taint_test.dart test/unit/checkpoint_autosave_test.dart
```

Attendu : SUCCÈS pour les deux fichiers. `checkpoint_autosave_test.dart` est la non-régression :
il prouve que l'autosave existant n'a pas changé quand le drapeau est baissé.

- [ ] **Étape 7 : analyse statique**

```
dart analyze
```

Attendu : `No issues found!`

- [ ] **Étape 8 : commit**

```bash
git add lib/game/controllers/debug_taint_controller.dart \
        lib/game/controllers/checkpoint_controller.dart \
        lib/game/controllers/run_controller.dart \
        test/unit/debug_taint_test.dart
git commit -m "feat(debug): couper l autosave des qu une run est touchee par le debug

Une run trafiquee ne doit pas produire de sauvegarde : rechargee plus
tard, elle serait indistinguable d'une run legitime. Le drapeau est sans
retour arriere pour la run courante ; seul startNewRun le rabaisse.

La sauvegarde deja presente sur le disque reste intacte.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2 : `DebugActions` — le socle, la run et le héros

**Files:**
- Create: `lib/game/services/debug_actions.dart`
- Test: `test/unit/debug_actions_test.dart`

**Interfaces:**
- Consomme : `debugTaintProvider` (Task 1), `runProvider`, `inventoryProvider`.
- Produit :
  - `DebugActions.updateRun(RefReader read, RunState Function(RunState) mutate)` → `void`
  - `DebugActions.updateHeroStats(RefReader read, EntityStats Function(EntityStats) mutate)` → `void`
  - `DebugActions.setGold(RefReader read, int gold)` → `void`
  - `DebugActions.advanceToNextAct(RefReader read)` → `void`

`RefReader` est le typedef maison, `typedef RefReader = T Function<T>(ProviderListenable<T>)`,
déclaré dans `lib/services/save_service.dart:16`. Il accepte aussi bien le `ref.read` d'un
`Provider` que celui d'un `WidgetRef`.

- [ ] **Étape 1 : écrire le test qui échoue**

Créer `test/unit/debug_actions_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/debug_taint_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/debug_actions.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

const paladin = HeroData(
  id: 'paladin',
  nameEn: 'Paladin',
  nameFr: 'Paladin',
  descriptionEn: 'A holy knight',
  descriptionFr: 'Un saint chevalier',
  iconPath: 'paladin.png',
  maxHp: 100,
  maxMana: 3,
  baseDamage: 5,
  luck: 0,
  armorMastery: 0,
  passiveTrait: 'regen_armor',
);

ProviderContainer _startedRun() {
  final container = ProviderContainer();
  container.read(runProvider.notifier).startNewRun(paladin);
  return container;
}

void main() {
  group('DebugActions — run et heros', () {
    test('updateHeroStats ecrit les PV et contamine la run', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(debugTaintProvider), isFalse);

      DebugActions.updateHeroStats(
        container.read,
        (s) => s.copyWith(currentPv: 42),
      );

      expect(container.read(runProvider).heroStats.currentPv, 42);
      expect(container.read(debugTaintProvider), isTrue);
    });

    test('setGold fixe l or a la valeur exacte, a la hausse comme a la baisse', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(inventoryProvider).gold, 50);

      DebugActions.setGold(container.read, 999);
      expect(container.read(inventoryProvider).gold, 999);

      DebugActions.setGold(container.read, 7);
      expect(container.read(inventoryProvider).gold, 7);
    });

    test('updateRun force l acte sans toucher a la carte ni a la position', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final mapBefore = container.read(runProvider).mapNodes;
      final nodeBefore = container.read(runProvider).currentNodeId;

      DebugActions.updateRun(container.read, (s) => s.copyWith(act: 3));

      expect(container.read(runProvider).act, 3);
      expect(container.read(runProvider).mapNodes, same(mapBefore));
      expect(container.read(runProvider).currentNodeId, nodeBefore);
    });

    test('advanceToNextAct incremente l acte ET regenere la carte', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final mapBefore = container.read(runProvider).mapNodes;

      DebugActions.advanceToNextAct(container.read);

      expect(container.read(runProvider).act, 2);
      expect(container.read(runProvider).mapNodes, isNot(same(mapBefore)));
      expect(container.read(runProvider).currentNodeId, isNull);
      expect(container.read(debugTaintProvider), isTrue);
    });
  });
}
```

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

```
flutter test test/unit/debug_actions_test.dart
```

Attendu : ÉCHEC à la compilation — `debug_actions.dart` n'existe pas.

- [ ] **Étape 3 : écrire l'implémentation minimale**

Créer `lib/game/services/debug_actions.dart` :

```dart
import 'package:flutter/foundation.dart';

import '../../models/entity_stats.dart';
import '../../services/save_service.dart' show RefReader;
import '../controllers/debug_taint_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/run_controller.dart';

/// Mutations d'etat reservees au menu de debug.
///
/// Calquee sur `SaveService` : une classe statique qui recoit un `RefReader` et
/// compose les controleurs, sans detenir d'etat. Elle n'appelle que des methodes
/// deja publiques — celles que le systeme de sauvegarde avait deja rendues
/// necessaires.
///
/// Chaque methode publique est gardee par `kDebugMode`. C'est la seconde garde,
/// celle qui tient meme si un appel echappait un jour a celle de l'interface.
class DebugActions {
  const DebugActions._();

  static void _taint(RefReader read) {
    read(debugTaintProvider.notifier).taint();
  }

  /// Point de mutation unique de `RunState`. L'appelant decrit le changement
  /// avec `copyWith` ; la contamination et la garde sont traitees ici.
  static void updateRun(RefReader read, RunState Function(RunState) mutate) {
    if (!kDebugMode) return;
    final controller = read(runProvider.notifier);
    controller.updateState(mutate(controller.currentState));
    _taint(read);
  }

  /// Raccourci pour les champs d'`EntityStats`, imbriques dans `RunState`.
  static void updateHeroStats(
    RefReader read,
    EntityStats Function(EntityStats) mutate,
  ) {
    updateRun(read, (s) => s.copyWith(heroStats: mutate(s.heroStats)));
  }

  /// L'or vit sur `InventoryState`, pas sur `RunState`.
  static void setGold(RefReader read, int gold) {
    if (!kDebugMode) return;
    read(inventoryProvider.notifier)
        .hydrate(read(inventoryProvider).copyWith(gold: gold));
    _taint(read);
  }

  /// Acte suivant **avec** regeneration de la carte et perte de la position.
  /// A ne proposer que hors combat — voir §5 de la spec.
  static void advanceToNextAct(RefReader read) {
    if (!kDebugMode) return;
    read(runProvider.notifier).advanceToNextWorld();
    _taint(read);
  }
}
```

- [ ] **Étape 4 : lancer les tests et vérifier qu'ils passent**

```
flutter test test/unit/debug_actions_test.dart
```

Attendu : SUCCÈS, 4 tests.

- [ ] **Étape 5 : analyse statique et commit**

```
dart analyze
```

Attendu : `No issues found!`

```bash
git add lib/game/services/debug_actions.dart test/unit/debug_actions_test.dart
git commit -m "feat(debug): ajouter DebugActions pour la run et les stats du heros

Classe statique calquee sur SaveService : elle recoit un RefReader et
compose les controleurs existants, sans ajouter la moindre methode a
leur surface publique.

updateRun est le point de mutation unique de RunState ; il porte la
garde kDebugMode et la contamination, que les appelants n'ont donc pas
a repeter.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3 : `DebugActions` — deck et reliques

**Files:**
- Modify: `lib/game/services/debug_actions.dart`
- Test: `test/unit/debug_actions_test.dart`

**Interfaces:**
- Consomme : `DebugActions._taint` (Task 2), `deckProvider`, `inventoryProvider`.
- Produit :
  - `DebugActions.addCard(RefReader read, CardData card)` → `void`
  - `DebugActions.removeCard(RefReader read, String uniqueId)` → `void`
  - `DebugActions.drawCards(RefReader read, int amount)` → `void`
  - `DebugActions.discardHand(RefReader read)` → `void`
  - `DebugActions.addRelic(RefReader read, RelicData relic)` → `void`
  - `DebugActions.removeRelic(RefReader read, String relicId)` → `void`

- [ ] **Étape 1 : écrire les tests qui échouent**

Ajouter dans `test/unit/debug_actions_test.dart`, à la suite du groupe existant, et compléter les
imports avec `card_data.dart`, `deck_controller.dart` et `relic_data.dart` :

```dart
  group('DebugActions — deck et reliques', () {
    const strike = CardData(
      id: 'strike_basic',
      nameEn: 'Strike',
      nameFr: 'Frappe',
      descriptionEn: 'Deals 6 damage.',
      descriptionFr: 'Inflige 6 degats.',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 6)],
    );

    test('addCard ajoute une instance au deck maitre et contamine', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(deckProvider).masterDeck, isEmpty);

      DebugActions.addCard(container.read, strike);

      expect(container.read(deckProvider).masterDeck.length, 1);
      expect(container.read(deckProvider).masterDeck.first.data.id, 'strike_basic');
      expect(container.read(debugTaintProvider), isTrue);
    });

    test('removeCard retire exactement l instance visee', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      DebugActions.addCard(container.read, strike);
      DebugActions.addCard(container.read, strike);
      final victim = container.read(deckProvider).masterDeck.first.uniqueId;

      DebugActions.removeCard(container.read, victim);

      final remaining = container.read(deckProvider).masterDeck;
      expect(remaining.length, 1);
      expect(remaining.first.uniqueId, isNot(victim));
    });
  });
```

Les sept paramètres requis par `CardData` sont `id`, `cost`, `type`, `category`, `rarity`, `target`
et `effects` — le fixture ci-dessus est calqué sur celui de
`test/unit/combat_controller_test.dart:320`.

- [ ] **Étape 2 : lancer les tests et vérifier qu'ils échouent**

```
flutter test test/unit/debug_actions_test.dart
```

Attendu : ÉCHEC — `addCard` n'est pas défini sur `DebugActions`.

- [ ] **Étape 3 : écrire l'implémentation**

Ajouter à `lib/game/services/debug_actions.dart` (et compléter les imports avec
`../../models/card_instance.dart`, `../../models/data/card_data.dart`,
`../../models/data/relic_data.dart`, `../controllers/deck_controller.dart` et
`../game_constants.dart`) :

```dart
  static void addCard(RefReader read, CardData card) {
    if (!kDebugMode) return;
    read(deckProvider.notifier).addCardToMasterDeck(CardInstance(data: card));
    _taint(read);
  }

  static void removeCard(RefReader read, String uniqueId) {
    if (!kDebugMode) return;
    read(deckProvider.notifier).removeCardById(uniqueId);
    _taint(read);
  }

  static void drawCards(RefReader read, int amount) {
    if (!kDebugMode) return;
    read(deckProvider.notifier)
        .drawCards(amount, maxHandSize: GameConstants.maxHandSize);
    _taint(read);
  }

  static void discardHand(RefReader read) {
    if (!kDebugMode) return;
    read(deckProvider.notifier).discardHand();
    _taint(read);
  }

  /// `addRelic` declenche deja l'effet des reliques `startOfRun` : le
  /// comportement teste est celui du vrai jeu.
  static void addRelic(RefReader read, RelicData relic) {
    if (!kDebugMode) return;
    read(inventoryProvider.notifier).addRelic(relic);
    _taint(read);
  }

  static void removeRelic(RefReader read, String relicId) {
    if (!kDebugMode) return;
    read(inventoryProvider.notifier).removeRelics([relicId]);
    _taint(read);
  }
```

- [ ] **Étape 4 : lancer les tests et vérifier qu'ils passent**

```
flutter test test/unit/debug_actions_test.dart
```

Attendu : SUCCÈS, 6 tests.

- [ ] **Étape 5 : analyse statique et commit**

```
dart analyze
```

```bash
git add lib/game/services/debug_actions.dart test/unit/debug_actions_test.dart
git commit -m "feat(debug): ajouter les actions de deck et de reliques

addRelic passe par InventoryController, qui declenche deja l'effet des
reliques startOfRun : le comportement obtenu est celui du vrai jeu, pas
une approximation.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4 : `DebugActions` — combat

**Files:**
- Modify: `lib/game/services/debug_actions.dart`
- Test: `test/unit/debug_actions_test.dart`

**Interfaces:**
- Consomme : `DebugActions._taint` (Task 2), `combatProvider`.
- Produit :
  - `DebugActions.setEnemyHp(RefReader read, String enemyId, int currentPv)` → `void`
  - `DebugActions.killAllEnemies(RefReader read)` → `void`
  - `DebugActions.winCombat(RefReader read)` → `void`
  - `DebugActions.loseCombat(RefReader read)` → `void`
  - `DebugActions.skipEnemyPhase(RefReader read)` → `void`

> **Le cœur de cette tâche.** `setEnemyHp` et `killAllEnemies` empruntent le **vrai** chemin de
> mort : `cleanDeadEnemies()` distribue l'XP, déclenche les reliques et fait apparaître la vague
> suivante depuis `pendingEnemies`. `winCombat` court-circuite tout. Les tests ci-dessous existent
> précisément pour empêcher que ces deux comportements se confondent un jour.

- [ ] **Étape 1 : écrire les tests qui échouent**

Ajouter dans `test/unit/debug_actions_test.dart`, en complétant les imports avec
`combat_controller.dart`, `combat_state.dart`, `enemy_instance.dart`, `enemy_data.dart`,
`enemy_intent.dart` et `entity_stats.dart` :

```dart
  group('DebugActions — combat', () {
    final goblinData = EnemyData(
      id: 'goblin',
      nameEn: 'Goblin',
      nameFr: 'Gobelin',
      maxHp: 20,
      baseDamage: 5,
      spritePath: 'goblin.png',
      tier: 1,
      intents: [EnemyIntent(type: IntentType.attack, value: 5)],
    );

    EnemyInstance freshGoblin() => EnemyInstance(
          data: goblinData,
          stats: EntityStats(maxPv: 20, currentPv: 20, armure: 0, attaque: 5),
        );

    test('setEnemyHp a 0 tue la cible et laisse les autres intacts', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      final a = freshGoblin();
      final b = freshGoblin();
      final c = freshGoblin();
      combat.updateState(CombatState(enemies: [a, b, c]));

      DebugActions.setEnemyHp(container.read, b.id, 0);

      final remaining = container.read(combatProvider).enemies;
      expect(remaining.length, 2);
      expect(remaining.map((e) => e.id), containsAll([a.id, c.id]));
      expect(remaining.every((e) => e.stats.currentPv == 20), isTrue);
      expect(container.read(combatProvider).isCombatEnded, isFalse);
      expect(container.read(debugTaintProvider), isTrue);
    });

    test('setEnemyHp a une valeur non nulle laisse la cible en vie', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      final a = freshGoblin();
      combat.updateState(CombatState(enemies: [a]));

      DebugActions.setEnemyHp(container.read, a.id, 3);

      final enemies = container.read(combatProvider).enemies;
      expect(enemies.length, 1);
      expect(enemies.first.stats.currentPv, 3);
      expect(container.read(combatProvider).isCombatEnded, isFalse);
    });

    test('killAllEnemies fait apparaitre la vague suivante sans finir le combat', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      combat.updateState(CombatState(
        enemies: [freshGoblin()],
        pendingEnemies: [freshGoblin()],
      ));

      DebugActions.killAllEnemies(container.read);

      expect(container.read(combatProvider).enemies.length, 1);
      expect(container.read(combatProvider).pendingEnemies, isEmpty);
      expect(container.read(combatProvider).isCombatEnded, isFalse);
    });

    test('winCombat court-circuite tout, files comprises', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final combat = container.read(combatProvider.notifier);
      combat.updateState(CombatState(
        enemies: [freshGoblin()],
        pendingEnemies: [freshGoblin()],
      ));

      DebugActions.winCombat(container.read);

      expect(container.read(combatProvider).enemies, isEmpty);
      expect(container.read(combatProvider).pendingEnemies, isEmpty);
      expect(container.read(combatProvider).isCombatEnded, isTrue);
      expect(container.read(combatProvider).isVictory, isTrue);
    });

    test('loseCombat met le heros a 0 PV', () {
      final container = _startedRun();
      addTearDown(container.dispose);

      DebugActions.loseCombat(container.read);

      expect(container.read(runProvider).heroStats.currentPv, 0);
      expect(container.read(runProvider).isDead, isTrue);
    });
  });
```

- [ ] **Étape 2 : lancer les tests et vérifier qu'ils échouent**

```
flutter test test/unit/debug_actions_test.dart
```

Attendu : ÉCHEC — `setEnemyHp` n'est pas défini.

- [ ] **Étape 3 : écrire l'implémentation**

Ajouter à `lib/game/services/debug_actions.dart`, imports complétés avec
`../../models/combat_state.dart` et `../controllers/combat_controller.dart` :

```dart
  /// Fixe les PV d'un ennemi, puis resout les morts par le **vrai** chemin :
  /// `cleanDeadEnemies` distribue l'XP, declenche les reliques et fait
  /// apparaitre la vague suivante s'il en reste une. Ne pas confondre avec
  /// `winCombat`, qui court-circuite tout.
  static void setEnemyHp(RefReader read, String enemyId, int currentPv) {
    if (!kDebugMode) return;
    final combat = read(combatProvider.notifier);
    final index =
        combat.currentState.enemies.indexWhere((e) => e.id == enemyId);
    if (index == -1) return;
    final enemy = combat.currentState.enemies[index];
    combat.updateEnemyStats(enemyId, enemy.stats.copyWith(currentPv: currentPv));
    combat.cleanDeadEnemies();
    _taint(read);
  }

  static void killAllEnemies(RefReader read) {
    if (!kDebugMode) return;
    final combat = read(combatProvider.notifier);
    // Copie explicite : `updateEnemyStats` remplace la liste a chaque appel.
    for (final enemy in List.of(combat.currentState.enemies)) {
      combat.updateEnemyStats(
        enemy.id,
        enemy.stats.copyWith(currentPv: 0),
      );
    }
    combat.cleanDeadEnemies();
    _taint(read);
  }

  /// Termine le combat sans passer par la mort des ennemis : va directement a
  /// l'ecran de recompense.
  static void winCombat(RefReader read) {
    if (!kDebugMode) return;
    final combat = read(combatProvider.notifier);
    combat.updateState(combat.currentState.copyWith(
      enemies: const [],
      pendingEnemies: const [],
      isCombatEnded: true,
      isVictory: true,
    ));
    _taint(read);
  }

  static void loseCombat(RefReader read) {
    if (!kDebugMode) return;
    updateHeroStats(read, (s) => s.copyWith(currentPv: 0));
  }

  static void skipEnemyPhase(RefReader read) {
    if (!kDebugMode) return;
    final combat = read(combatProvider.notifier);
    combat.updateState(
      combat.currentState.copyWith(turnPhase: TurnPhase.player),
    );
    _taint(read);
  }
```

- [ ] **Étape 4 : lancer la suite complète**

```
flutter test
```

Attendu : SUCCÈS. Le compte total doit avoir augmenté du nombre de tests ajoutés, et **aucun test
existant ne doit être passé au rouge** — `cleanDeadEnemies` touche `runProvider` via
`onEnemyKilled`, c'est le point où une régression se verrait.

- [ ] **Étape 5 : analyse statique et commit**

```
dart analyze
```

```bash
git add lib/game/services/debug_actions.dart test/unit/debug_actions_test.dart
git commit -m "feat(debug): ajouter les actions de combat, ennemis ciblables un par un

setEnemyHp et killAllEnemies empruntent le vrai chemin de mort : XP,
reliques et vague suivante comprises. winCombat court-circuite tout.
Les tests fixent cette distinction, pour qu'un outil qui mentirait sur
ce qu'il vient de tester ne puisse pas s'installer par inadvertance.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5 : L'interface — coquille, champ numérique, onglets Héros et Run

**Files:**
- Create: `lib/ui/widgets/debug/debug_number_field.dart`
- Create: `lib/ui/widgets/debug/debug_menu_dialog.dart`
- Create: `lib/ui/widgets/debug/tabs/debug_hero_tab.dart`
- Create: `lib/ui/widgets/debug/tabs/debug_run_tab.dart`

**Interfaces:**
- Consomme : `DebugActions` (Tasks 2-4), `GameDialog`, `AppSpacing`.
- Produit : `DebugMenuDialog.show(BuildContext context)` → `Future<void>`,
  `DebugNumberField({required String label, required int value, required ValueChanged<int> onSubmitted})`.

Pas de test automatisé sur cette tâche : ce sont des widgets sans logique propre, et le dépôt ne
teste pas ses dialogues. La vérification est visuelle, à l'étape 5.

- [ ] **Étape 1 : le champ numérique partagé**

Créer `lib/ui/widgets/debug/debug_number_field.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_spacing.dart';

/// Champ entier du menu de debug : applique la valeur a la validation.
/// Purement local — il ne detient aucun etat metier.
class DebugNumberField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onSubmitted;

  const DebugNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onSubmitted,
  });

  @override
  State<DebugNumberField> createState() => _DebugNumberFieldState();
}

class _DebugNumberFieldState extends State<DebugNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());

  @override
  void didUpdateWidget(covariant DebugNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingVSm,
      child: Row(
        children: [
          Expanded(child: Text(widget.label)),
          SizedBox(
            width: 96,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(isDense: true),
              onSubmitted: (raw) {
                final parsed = int.tryParse(raw);
                if (parsed != null) widget.onSubmitted(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Étape 2 : l'onglet Héros**

Créer `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../debug_number_field.dart';

class DebugHeroTab extends ConsumerWidget {
  const DebugHeroTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(runProvider).heroStats;

    return ListView(
      children: [
        DebugNumberField(
          label: 'PV',
          value: stats.currentPv,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(currentPv: v)),
        ),
        DebugNumberField(
          label: 'PV max',
          value: stats.maxPv,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(maxPv: v)),
        ),
        DebugNumberField(
          label: 'Mana',
          value: stats.currentMana,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(currentMana: v)),
        ),
        DebugNumberField(
          label: 'Mana max',
          value: stats.maxMana,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(maxMana: v)),
        ),
        DebugNumberField(
          label: 'Armure',
          value: stats.armure,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(armure: v)),
        ),
        DebugNumberField(
          label: 'Attaque',
          value: stats.attaque,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(attaque: v)),
        ),
        DebugNumberField(
          label: 'Chance',
          value: stats.luck,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(luck: v)),
        ),
        DebugNumberField(
          label: 'Niveau',
          value: stats.level,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(level: v)),
        ),
        DebugNumberField(
          label: 'XP',
          value: stats.xp,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(xp: v)),
        ),
        DebugNumberField(
          label: 'Chance de critique (%)',
          value: stats.critChance,
          onSubmitted: (v) => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(critChance: v)),
        ),
        TextButton(
          onPressed: () => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(currentPv: s.maxPv)),
          child: const Text('Soin complet'),
        ),
        TextButton(
          onPressed: () => DebugActions.updateHeroStats(
              ref.read, (s) => s.copyWith(currentMana: s.maxMana)),
          child: const Text('Mana plein'),
        ),
      ],
    );
  }
}
```

- [ ] **Étape 3 : l'onglet Run**

Créer `lib/ui/widgets/debug/tabs/debug_run_tab.dart`. Même forme que l'onglet Héros, avec les
champs de `RunState` et l'or, plus le bouton d'acte suivant réservé à la carte :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/inventory_controller.dart';
import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../notification_overlay.dart';
import '../debug_number_field.dart';

class DebugRunTab extends ConsumerWidget {
  /// Faux pendant un combat : `advanceToNextAct` regenere la carte et efface
  /// la position, ce qui laisserait la run sans noeud courant.
  final bool canRegenerateMap;

  const DebugRunTab({super.key, required this.canRegenerateMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider);
    final gold = ref.watch(inventoryProvider).gold;

    return ListView(
      children: [
        DebugNumberField(
          label: 'Or',
          value: gold,
          onSubmitted: (v) => DebugActions.setGold(ref.read, v),
        ),
        DebugNumberField(
          label: 'Acte (sans regenerer la carte)',
          value: run.act,
          onSubmitted: (v) =>
              DebugActions.updateRun(ref.read, (s) => s.copyWith(act: v)),
        ),
        DebugNumberField(
          label: 'Niveau de run',
          value: run.currentLevel,
          onSubmitted: (v) => DebugActions.updateRun(
              ref.read, (s) => s.copyWith(currentLevel: v)),
        ),
        DebugNumberField(
          label: 'Drafts en attente',
          value: run.pendingDrafts,
          onSubmitted: (v) => DebugActions.updateRun(
              ref.read, (s) => s.copyWith(pendingDrafts: v)),
        ),
        DebugNumberField(
          label: 'Cartes par tour',
          value: run.cardsPerTurn,
          onSubmitted: (v) => DebugActions.updateRun(
              ref.read, (s) => s.copyWith(cardsPerTurn: v)),
        ),
        DebugNumberField(
          label: 'Slots de forge bonus',
          value: run.bonusForgeSlots,
          onSubmitted: (v) => DebugActions.updateRun(
              ref.read, (s) => s.copyWith(bonusForgeSlots: v)),
        ),
        if (canRegenerateMap)
          TextButton(
            onPressed: () {
              DebugActions.advanceToNextAct(ref.read);
              context.showNotification(
                'Acte ${ref.read(runProvider).act} — carte regeneree',
                type: NotificationType.success,
              );
            },
            child: const Text('Acte suivant (regenere la carte)'),
          ),
      ],
    );
  }
}
```

- [ ] **Étape 4 : la coquille à onglets**

Créer `lib/ui/widgets/debug/debug_menu_dialog.dart`. Les onglets Deck, Reliques et Combat sont
ajoutés à la Task 6 ; ne câbler ici que Héros et Run.

```dart
import 'package:flutter/material.dart';

import '../game_dialog.dart';
import 'tabs/debug_hero_tab.dart';
import 'tabs/debug_run_tab.dart';

/// Menu de manipulation d'etat, reserve au developpement.
///
/// Il n'est jamais construit dans un build release : son unique point d'appel,
/// dans `PauseDialog`, est garde par `kDebugMode`.
class DebugMenuDialog extends StatelessWidget {
  /// Faux hors combat : l'onglet Combat n'a alors rien a montrer, et
  /// l'action d'acte suivant redevient disponible.
  final bool inCombat;

  const DebugMenuDialog({super.key, required this.inCombat});

  static Future<void> show(BuildContext context, {required bool inCombat}) {
    return showDialog(
      context: context,
      builder: (_) => DebugMenuDialog(inCombat: inCombat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: GameDialog(
        title: const Text('Menu de debug', textAlign: TextAlign.center),
        content: SizedBox(
          height: 380,
          width: 460,
          child: Column(
            children: [
              const TabBar(
                tabs: [Tab(text: 'Heros'), Tab(text: 'Run')],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const DebugHeroTab(),
                    DebugRunTab(canRegenerateMap: !inCombat),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Étape 5 : analyse statique et vérification visuelle**

```
dart analyze
```

Attendu : `No issues found!`

Puis, une fois la Task 7 faite, ouvrir le menu et vérifier que chaque champ affiche la valeur
courante et que la validation l'applique. À cette étape-ci, seule l'analyse statique est
vérifiable — le menu n'a pas encore de point d'entrée.

- [ ] **Étape 6 : commit**

```bash
git add lib/ui/widgets/debug/
git commit -m "feat(debug): ajouter la coquille du menu et les onglets Heros et Run

L'action d'acte suivant est masquee en combat : elle regenere la carte
et efface la position, ce qui laisserait la run sans noeud courant.
Le champ d'acte simple, lui, reste disponible partout.

Libelles en francais dans le code, sans passer par l'ARB : ce menu
n'est jamais publie, et une quarantaine de cles bilingues pour un outil
de developpement serait un cout pur.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6 : L'interface — onglets Deck, Reliques et Combat

**Files:**
- Create: `lib/ui/widgets/debug/tabs/debug_deck_tab.dart`
- Create: `lib/ui/widgets/debug/tabs/debug_relics_tab.dart`
- Create: `lib/ui/widgets/debug/tabs/debug_combat_tab.dart`
- Modify: `lib/ui/widgets/debug/debug_menu_dialog.dart`

**Interfaces:**
- Consomme : `DebugActions` (Tasks 3-4), `DebugNumberField` (Task 5),
  `GameDataRegistry.instance`.
- Produit : `DebugDeckTab`, `DebugRelicsTab`, `DebugCombatTab` — tous `const`-constructibles sans
  paramètre.

- [ ] **Étape 1 : l'onglet Deck**

Créer `lib/ui/widgets/debug/tabs/debug_deck_tab.dart`. La liste de choix est le registre, trié par
le comparateur canonique déjà partagé par le dictionnaire de cartes :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/deck_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../../../models/data/card_data.dart';
import '../../../../models/data/game_data_registry.dart';
import '../../notification_overlay.dart';

class DebugDeckTab extends ConsumerWidget {
  const DebugDeckTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterDeck = ref.watch(deckProvider).masterDeck;
    final catalogue = List<CardData>.of(
      GameDataRegistry.instance?.cards ?? const <CardData>[],
    )..sort(CardData.compareByDisplayOrder);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  DebugActions.drawCards(ref.read, 1);
                  context.showNotification('1 carte piochee',
                      type: NotificationType.success);
                },
                child: const Text('Piocher 1'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  DebugActions.discardHand(ref.read);
                  context.showNotification('Main defaussee',
                      type: NotificationType.success);
                },
                child: const Text('Defausser la main'),
              ),
            ),
          ],
        ),
        const Divider(),
        const Text('Ajouter une carte'),
        for (final card in catalogue)
          ListTile(
            dense: true,
            title: Text('${card.nameFr}  (${card.cost})'),
            trailing: const Icon(Icons.add),
            onTap: () {
              DebugActions.addCard(ref.read, card);
              context.showNotification('Carte ajoutee : ${card.nameFr}',
                  type: NotificationType.success);
            },
          ),
        const Divider(),
        Text('Deck maitre (${masterDeck.length})'),
        for (final instance in masterDeck)
          ListTile(
            dense: true,
            title: Text(instance.data.nameFr),
            trailing: const Icon(Icons.remove),
            onTap: () {
              DebugActions.removeCard(ref.read, instance.uniqueId);
              context.showNotification('Carte retiree : ${instance.data.nameFr}',
                  type: NotificationType.success);
            },
          ),
      ],
    );
  }
}
```

- [ ] **Étape 2 : l'onglet Reliques**

Créer `lib/ui/widgets/debug/tabs/debug_relics_tab.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/inventory_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../../../models/data/game_data_registry.dart';
import '../../../../models/data/relic_data.dart';
import '../../notification_overlay.dart';

class DebugRelicsTab extends ConsumerWidget {
  const DebugRelicsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(inventoryProvider).relics;
    final catalogue =
        GameDataRegistry.instance?.relics ?? const <RelicData>[];

    return ListView(
      children: [
        const Text('Ajouter une relique'),
        for (final relic in catalogue)
          ListTile(
            dense: true,
            leading: Text(relic.emoji),
            title: Text(relic.nameFr),
            trailing: const Icon(Icons.add),
            onTap: () {
              DebugActions.addRelic(ref.read, relic);
              context.showNotification('Relique ajoutee : ${relic.nameFr}',
                  type: NotificationType.success);
            },
          ),
        const Divider(),
        Text('Reliques possedees (${owned.length})'),
        for (final relic in owned)
          ListTile(
            dense: true,
            leading: Text(relic.emoji),
            title: Text(relic.nameFr),
            trailing: const Icon(Icons.remove),
            onTap: () {
              DebugActions.removeRelic(ref.read, relic.id);
              context.showNotification('Relique retiree : ${relic.nameFr}',
                  type: NotificationType.success);
            },
          ),
      ],
    );
  }
}
```

> `addRelic` applique l'effet des reliques `startOfRun` à l'ajout, mais `removeRelic` passe par
> `InventoryController.removeRelics`, qui **ne défait pas** cet effet — c'est le comportement
> existant du jeu, pas une lacune du menu de debug. Retirer une relique `startOfRun` après l'avoir
> ajoutée laisse donc son bonus de stats en place. Ne pas « corriger » ce point ici : ce serait
> modifier le jeu depuis un outil de debug.

- [ ] **Étape 3 : l'onglet Combat**

Créer `lib/ui/widgets/debug/tabs/debug_combat_tab.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/combat_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../notification_overlay.dart';
import '../debug_number_field.dart';

class DebugCombatTab extends ConsumerWidget {
  const DebugCombatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enemies = ref.watch(combatProvider).enemies;

    return ListView(
      children: [
        for (var i = 0; i < enemies.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DebugNumberField(
                    // Le rang distingue deux ennemis du meme type.
                    label: '${i + 1}. ${enemies[i].data.nameFr}'
                        '  (${enemies[i].stats.currentPv}'
                        '/${enemies[i].stats.maxPv})',
                    value: enemies[i].stats.currentPv,
                    onSubmitted: (v) =>
                        DebugActions.setEnemyHp(ref.read, enemies[i].id, v),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      DebugActions.setEnemyHp(ref.read, enemies[i].id, 0),
                  child: const Text('0 PV'),
                ),
              ],
            ),
          ),
        const Divider(),
        TextButton(
          onPressed: () {
            DebugActions.killAllEnemies(ref.read);
            context.showNotification('Vague videe',
                type: NotificationType.success);
          },
          child: const Text('Tous les ennemis a 0 PV'),
        ),
        TextButton(
          onPressed: () {
            DebugActions.winCombat(ref.read);
            Navigator.of(context).pop();
          },
          child: const Text('Gagner le combat'),
        ),
        TextButton(
          onPressed: () {
            DebugActions.loseCombat(ref.read);
            Navigator.of(context).pop();
          },
          child: const Text('Perdre le combat'),
        ),
        TextButton(
          onPressed: () {
            DebugActions.skipEnemyPhase(ref.read);
            context.showNotification('Phase joueur forcee',
                type: NotificationType.success);
          },
          child: const Text('Sauter la phase ennemie'),
        ),
      ],
    );
  }
}
```

> **Deux dialogues empilés.** Le menu de debug s'ouvre par-dessus `PauseDialog`. « Gagner » et
> « perdre » ferment le menu, mais **laissent le dialogue de pause ouvert** au-dessus d'un combat
> déjà résolu ; il faut cliquer « reprendre » pour voir le résultat. C'est acceptable pour un outil
> de développement — à constater à l'étape 4 de la Task 7, pas à corriger par une double
> `Navigator.pop`, fragile dès qu'un dialogue est fermé autrement.

- [ ] **Étape 4 : câbler les onglets dans la coquille**

Remplacer le corps de `build` dans `lib/ui/widgets/debug/debug_menu_dialog.dart`, imports complétés
avec les trois nouveaux onglets :

```dart
  @override
  Widget build(BuildContext context) {
    final tabs = <(String, Widget)>[
      ('Heros', const DebugHeroTab()),
      ('Run', DebugRunTab(canRegenerateMap: !inCombat)),
      ('Deck', const DebugDeckTab()),
      ('Reliques', const DebugRelicsTab()),
      if (inCombat) ('Combat', const DebugCombatTab()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: GameDialog(
        title: const Text('Menu de debug', textAlign: TextAlign.center),
        content: SizedBox(
          height: 380,
          width: 460,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: [for (final (label, _) in tabs) Tab(text: label)],
              ),
              Expanded(
                child: TabBarView(
                  children: [for (final (_, view) in tabs) view],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Étape 5 : analyse statique et commit**

```
dart analyze
```

```bash
git add lib/ui/widgets/debug/
git commit -m "feat(debug): ajouter les onglets Deck, Reliques et Combat

Les commandes par ennemi vivent dans le dialogue et non sur les sprites :
poser un bouton sur un composant Flame ferait entrer de la logique de
debug dans la couche de rendu, que l'architecture tient a l'ecart de
toute decision.

Chaque ligne d'ennemi porte son rang, pour distinguer deux ennemis du
meme type.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7 : Le point d'entrée et la vérification du build release

**Files:**
- Modify: `lib/ui/widgets/hud/dialogs/pause_dialog.dart`
- Modify: `lib/ui/screens/game_screen.dart:541` et `lib/ui/screens/map_screen.dart:142`

**Interfaces:**
- Consomme : `DebugMenuDialog.show(context, inCombat:)` (Task 5).
- Produit : rien — c'est la tâche de raccordement.

- [ ] **Étape 1 : réécrire `PauseDialog`**

`PauseDialog` doit savoir s'il est ouvert en combat, pour le transmettre au menu. Remplacer
intégralement `lib/ui/widgets/hud/dialogs/pause_dialog.dart` :

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/debug/debug_menu_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';

class PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;

  /// Transmis au menu de debug : en combat, l'onglet Combat apparait et
  /// l'action d'acte suivant disparait.
  final bool inCombat;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onExit,
    required this.inCombat,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onResume,
    required VoidCallback onExit,
    required bool inCombat,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PauseDialog(
          onResume: onResume,
          onExit: onExit,
          inCombat: inCombat,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GameDialog(
      showCloseButton: false,
      title: Text(
        l10n.pauseTitle,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameButton(
            text: l10n.resumeCombat,
            onPressed: onResume,
          ),
          // `kDebugMode` est une constante de compilation : en release la
          // condition est repliee a false et tout ce sous-arbre devient
          // inatteignable, donc elimine au tree-shaking.
          if (kDebugMode) ...[
            AppSpacing.heightSm,
            GameButton(
              text: 'Menu de debug',
              baseColor: Colors.deepPurpleAccent,
              onPressed: () =>
                  DebugMenuDialog.show(context, inCombat: inCombat),
            ),
          ],
          AppSpacing.heightSm,
          GameButton(
            text: l10n.backToMainMenu,
            baseColor: Colors.redAccent,
            onPressed: onExit,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Étape 2 : renseigner les deux appelants**

- `lib/ui/screens/game_screen.dart:541` → `inCombat: true`
- `lib/ui/screens/map_screen.dart:142` → `inCombat: false`

- [ ] **Étape 3 : suite complète et analyse**

```
flutter test
dart analyze
```

Attendu : SUCCÈS et `No issues found!`.

- [ ] **Étape 4 : vérification manuelle en debug**

```
flutter run -d windows
```

1. Démarrer une run, ouvrir le menu pause **depuis la carte** : le bouton violet est là, l'onglet
   Combat est absent, l'action « acte suivant » est présente.
2. Entrer en combat, ouvrir le menu pause : l'onglet Combat est là, « acte suivant » a disparu.
3. Modifier l'or, valider : la valeur change à l'écran.
4. Mettre **un** ennemi à 0 PV : lui seul meurt, les autres gardent leurs PV.
5. Terminer le nœud, revenir à la carte, quitter, relancer l'application : **la run proposée au
   chargement est celle d'avant les modifications** — c'est le drapeau de contamination qui le
   prouve.

- [ ] **Étape 5 : vérification manuelle en release — la garantie du lot**

```
flutter build windows --release
```

Lancer le binaire produit sous `build/windows/x64/runner/Release/`, démarrer une run, ouvrir le
menu pause **depuis la carte puis depuis un combat**.

**Attendu : aucun bouton de debug, dans l'un comme dans l'autre.**

Aucun test automatisé ne peut prouver ce point — `kDebugMode` vaut toujours `true` sous
`flutter test`. C'est la raison d'être de cette étape, et elle est à refaire à chaque déplacement
du point d'entrée.

- [ ] **Étape 6 : commit**

```bash
git add lib/ui/widgets/hud/dialogs/pause_dialog.dart \
        lib/ui/screens/game_screen.dart \
        lib/ui/screens/map_screen.dart
git commit -m "feat(debug): ouvrir le menu depuis le dialogue de pause

PauseDialog etant deja appele depuis le combat et depuis la carte, une
seule insertion couvre les deux contextes. Le bouton est garde par
kDebugMode, constante de compilation : le sous-arbre entier devient
inatteignable en release.

Absence verifiee a la main sur un build windows release, seule preuve
possible : kDebugMode vaut toujours vrai sous flutter test.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Après le plan

Une fois les sept tâches vertes, deux gestes de suivi restent, **hors de ce plan** :

- Cocher le chantier dans `docs/ROADMAP.md` et faire une passe `memory-bank-sync`.
- **Ne pas rédiger de patch note.** Ce lot n'est visible d'aucun joueur : il n'a pas d'entrée à
  écrire dans `patch_notes.json`, et n'entraîne aucun changement de version.
