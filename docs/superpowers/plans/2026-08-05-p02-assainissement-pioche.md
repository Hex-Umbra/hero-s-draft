# P-02 — Assainissement du système de pioche — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre le moteur de pioche correct et testable — remélange à sec, limite de main, aléatoire injectable — en déplaçant la règle de tour hors de `game_screen.dart` et en supprimant six éléments de code mort.

**Architecture:** `DeckNotifier` garantit les invariants de piles via un cœur pur `_drawInto` ; `TurnPhaseManager` décide quand piocher, via deux nouveaux points d'entrée `startPlayerCombat()` / `startPlayerTurn()` symétriques des deux existants côté ennemi ; `game_screen.dart` ne fait plus qu'animer. `cardsPerTurn` devient une statistique de run modifiable par relique, `maxHandSize` une constante.

**Tech Stack:** Flutter · Riverpod 2.x (`Notifier` / `NotifierProvider`) · Flame · `flutter_test`

**Spec de référence :** `docs/superpowers/specs/2026-08-04-p02-assainissement-pioche-design.md`

## Global Constraints

- **`dart analyze` doit être propre (zéro issue) après chaque tâche**, avant tout commit. Règle du `CLAUDE.md`, non négociable.
- **Aucun code mort, aucun import inutilisé, aucun bloc commenté** dans le code commité (`CLAUDE.md`).
- **Toute entrée JSON à texte visible porte `_fr` ET `_en`** (`CLAUDE.md`). Concerne `assets/data/relics.json` en tâche 6.
- **Aucun nouveau `StateNotifier`** — Riverpod 2.x `Notifier` uniquement (`CLAUDE.md`).
- **Les couches ne se mélangent pas** : aucune logique métier dans `lib/ui/`, aucun widget Flutter dans un composant Flame, aucune référence Flame dans `lib/ui/`.
- **`assets/data/patch_notes.json` et `pubspec.yaml` ne sont JAMAIS édités à la main** — ils appartiennent au skill `patch-notes-writer`, hors périmètre de ce plan.
- **`.obsidian_vault/` et `docs/ROADMAP.md` ne sont pas édités par ce plan** — ils appartiennent au skill `memory-bank-sync`, à lancer après la livraison.
- Les fichiers `lib/l10n/app_localizations*.dart` sont **générés** (`l10n.yaml`, `generate: true`). Ne jamais les éditer à la main : modifier les `.arb` puis lancer `flutter gen-l10n`.
- Branche de travail : `feat/p02-assainissement-pioche` (déjà créée, porte la spec).

## Structure des fichiers

| Fichier | Responsabilité après le chantier | Tâches |
|:---|:---|:---:|
| `lib/game/controllers/deck_controller.dart` | Invariants de piles. `_drawInto` (cœur pur), `drawCards`, `startCombat`, `deckRandomProvider`, `DeckState.reshuffleCount` | 1, 2, 3 |
| `lib/game/game_constants.dart` | Ajout de `maxHandSize` | 2 |
| `lib/game/controllers/run_controller.dart` | Ajout de `RunState.cardsPerTurn` + façade `applyRunRuleModifier` | 4 |
| `lib/game/controllers/run/player_stats_manager.dart` | `applyRunRuleModifier`, `case increase_cards_per_turn` (apply + remove) | 4, 6 |
| `lib/game/controllers/combat/turn_phase_manager.dart` | Ajout de `startPlayerCombat()` / `startPlayerTurn()` — la moitié joueur du cycle | 5 |
| `lib/game/controllers/combat_controller.dart` | Façade : expose les deux nouvelles méthodes | 5 |
| `lib/ui/screens/game_screen.dart` | N'anime plus que. Perd la règle de pioche, `_turnCount`, le deck de secours, 2 callbacks | 2, 3, 5, 7, 8 |
| `lib/game/heros_draft_game.dart` | Passe de 13 à 11 callbacks | 8 |
| `lib/models/card_instance.dart` | Perd `temporaryCost` | 8 |
| `lib/models/enemy_intent.dart` | Perd `IntentType.debuffDeck` | 8 |
| `assets/data/relics.json` | +1 relique `increase_cards_per_turn` | 6 |
| `lib/l10n/app_{en,fr}.arb` | +`deckReshuffled`, −`intentCurse` | 7, 8 |

---

## Ordre des tâches et dépendances

```
1. Aléatoire injectable + reshuffleCount      (fondation, aucun changement de comportement)
2. Le moteur de pioche                         (dépend de 1)
3. DeckNotifier.startCombat                    (dépend de 2)
4. RunState.cardsPerTurn                       (indépendant)
5. TurnPhaseManager + nettoyage game_screen    (dépend de 3 et 4)
6. La relique increase_cards_per_turn          (dépend de 4)
7. Le toast de remélange                       (dépend de 1 et 5)
8. Suppression du code mort résiduel           (dépend de 5)
```

---

### Task 1: Aléatoire injectable et compteur de remélange

Fondation pure : aucun changement de comportement en jeu. On rend le mélange reproductible en test et on ajoute le compteur qui servira à la fois d'assertion (tâche 2) et de déclencheur de toast (tâche 7).

**Files:**
- Modify: `lib/game/controllers/deck_controller.dart`
- Test: `test/unit/deck_controller_test.dart`

**Interfaces:**
- Consumes: rien
- Produces:
  - `final deckRandomProvider = Provider<Random>((ref) => Random());`
  - `DeckState.reshuffleCount` — `int`, défaut `0`, présent dans `copyWith`, `toJson`, `fromJsonWithReport`
  - `DeckNotifier._random` — champ `Random` privé, initialisé dans `build()`

- [ ] **Step 1: Écrire les tests qui échouent**

Ajouter en tête de `test/unit/deck_controller_test.dart`, **après** les imports existants et **avant** `void main()`, ce helper :

```dart
CardInstance _card(String id) => CardInstance(
      data: CardData(
        id: id,
        nameEn: id,
        nameFr: id,
        cost: 1,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: const [],
      ),
    );
```

Ajouter `import 'dart:math';` aux imports du fichier de test.

Puis ajouter ce groupe **à l'intérieur de `void main()`**, après le groupe `DeckNotifier Tests` existant :

```dart
  group('DeckNotifier — aléatoire et compteur de remélange', () {
    test('deckRandomProvider rend le mélange déterministe', () {
      final cards = List.generate(10, (i) => _card('c$i'));

      List<String> orderWithSeed(int seed) {
        final container = ProviderContainer(
          overrides: [deckRandomProvider.overrideWithValue(Random(seed))],
        );
        addTearDown(container.dispose);
        final notifier = container.read(deckProvider.notifier);
        notifier.initializeStarterDeck(cards);
        notifier.initializeCombat();
        return notifier.state.drawPile.map((c) => c.uniqueId).toList();
      }

      expect(orderWithSeed(42), equals(orderWithSeed(42)));
      expect(orderWithSeed(42), isNot(equals(orderWithSeed(7))));
    });

    test('reshuffleCount vaut 0 par défaut et survit à la sérialisation', () {
      const state = DeckState(reshuffleCount: 3);
      final json = state.toJson();
      expect(json['reshuffleCount'], 3);

      final (restored, missing) = DeckState.fromJsonWithReport(json);
      expect(restored.reshuffleCount, 3);
      expect(missing, isEmpty);
    });

    test('reshuffleCount vaut 0 sur une sauvegarde antérieure à P-02', () {
      const state = DeckState();
      final legacy = Map<String, dynamic>.from(state.toJson())
        ..remove('reshuffleCount');

      final (restored, _) = DeckState.fromJsonWithReport(legacy);
      expect(restored.reshuffleCount, 0);
    });
  });
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/deck_controller_test.dart`
Expected: FAIL — `deckRandomProvider` et le paramètre nommé `reshuffleCount` n'existent pas (erreurs de compilation).

- [ ] **Step 3: Ajouter `reshuffleCount` à `DeckState`**

Dans `lib/game/controllers/deck_controller.dart`, classe `DeckState` — quatre points de couture.

Champ, après `exhaustPile` :

```dart
  final List<CardInstance> exhaustPile;

  /// Nombre de remélanges défausse → pioche depuis le début du combat.
  /// Remis à 0 par `startCombat`. Observé par l'UI pour signaler l'événement.
  final int reshuffleCount;
```

Constructeur :

```dart
  const DeckState({
    this.masterDeck = const [],
    this.drawPile = const [],
    this.hand = const [],
    this.discardPile = const [],
    this.exhaustPile = const [],
    this.reshuffleCount = 0,
  });
```

`copyWith` — ajouter le paramètre et la ligne de construction :

```dart
  DeckState copyWith({
    List<CardInstance>? masterDeck,
    List<CardInstance>? drawPile,
    List<CardInstance>? hand,
    List<CardInstance>? discardPile,
    List<CardInstance>? exhaustPile,
    int? reshuffleCount,
  }) {
    return DeckState(
      masterDeck: masterDeck ?? this.masterDeck,
      drawPile: drawPile ?? this.drawPile,
      hand: hand ?? this.hand,
      discardPile: discardPile ?? this.discardPile,
      exhaustPile: exhaustPile ?? this.exhaustPile,
      reshuffleCount: reshuffleCount ?? this.reshuffleCount,
    );
  }
```

`toJson` — ajouter la clé après `exhaustPile` :

```dart
        'exhaustPile': exhaustPile.map((c) => c.toJson()).toList(),
        'reshuffleCount': reshuffleCount,
      };
```

`fromJsonWithReport` — ajouter le champ dans le `DeckState(...)` retourné :

```dart
      DeckState(
        masterDeck: masterDeck,
        drawPile: drawPile,
        hand: hand,
        discardPile: discardPile,
        exhaustPile: exhaustPile,
        reshuffleCount: json['reshuffleCount'] as int? ?? 0,
      ),
```

- [ ] **Step 4: Injecter le `Random` dans `DeckNotifier`**

Toujours dans `lib/game/controllers/deck_controller.dart`.

En bas du fichier, **au-dessus** de `deckProvider` :

```dart
/// Source d'aléatoire de la pioche. Surchargeable en test via
/// `deckRandomProvider.overrideWithValue(Random(42))` pour rendre les
/// séquences de pioche reproductibles.
final deckRandomProvider = Provider<Random>((ref) => Random());

final deckProvider = NotifierProvider<DeckNotifier, DeckState>(DeckNotifier.new);
```

Dans `DeckNotifier`, remplacer le `build()` existant :

```dart
class DeckNotifier extends Notifier<DeckState> {
  late final Random _random;

  @override
  DeckState build() {
    _random = ref.read(deckRandomProvider);
    return const DeckState();
  }
```

Remplacer les deux `shuffle(Random())` par `shuffle(_random)` :
- `initializeCombat()` : `newDrawPile.shuffle(_random);`
- `shuffleDiscardIntoDraw()` : `newDrawPile.shuffle(_random);`

- [ ] **Step 5: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/deck_controller_test.dart`
Expected: PASS — 7 tests (4 existants + 3 nouveaux).

- [ ] **Step 6: Vérifier la non-régression et l'analyse**

Run: `flutter test test/unit/deck_state_persistence_test.dart test/unit/save_service_test.dart`
Expected: PASS

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/game/controllers/deck_controller.dart test/unit/deck_controller_test.dart
git commit -m "feat(P-02): aleatoire de pioche injectable et compteur de remelange"
```

---

### Task 2: Le moteur de pioche — remélange à sec et arrêt net

Le cœur du chantier. `drawCards` remélange la défausse dès que la pioche est vide, y compris au milieu d'une pioche, et s'arrête net quand la main est pleine.

**Files:**
- Modify: `lib/game/game_constants.dart`
- Modify: `lib/game/controllers/deck_controller.dart`
- Modify: `lib/game/services/effects/strategies.dart:120`
- Modify: `lib/game/services/effect_resolver.dart:165`
- Modify: `lib/ui/screens/game_screen.dart:213-217` et `:276`
- Test: `test/unit/deck_controller_test.dart`

**Interfaces:**
- Consumes: `DeckState.reshuffleCount`, `DeckNotifier._random` (tâche 1)
- Produces:
  - `GameConstants.maxHandSize` — `static const int`, valeur `10`
  - `DeckNotifier.drawCards(int amount, {required int maxHandSize})` — **signature modifiée**
  - `DeckNotifier._drawInto({...})` — cœur pur, `static`, réutilisé par `startCombat` en tâche 3
  - `DeckNotifier.shuffleDiscardIntoDraw()` — **supprimée**

> **Note de conception.** La spec §4.7 indiquait que `DrawEffectStrategy` et la rune `quick`
> accèderaient à `maxHandSize` « via le `runController` déjà présent ». La spec §5.1 ayant
> tranché que `maxHandSize` est une **constante** et non une statistique, ces deux appelants
> lisent directement `GameConstants.maxHandSize`. Le paramètre nommé reste sur `drawCards`
> pour que les tests puissent le faire varier.

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/unit/deck_controller_test.dart`, ajouter ce groupe à l'intérieur de `void main()` :

```dart
  group('DeckNotifier — moteur de pioche', () {
    late ProviderContainer container;
    late DeckNotifier notifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [deckRandomProvider.overrideWithValue(Random(42))],
      );
      notifier = container.read(deckProvider.notifier);
    });

    tearDown(() => container.dispose());

    /// Invariant central : aucune carte ne se perd ni ne se duplique.
    void expectConservation(DeckState s) {
      expect(
        s.drawPile.length + s.hand.length + s.discardPile.length + s.exhaustPile.length,
        s.masterDeck.length,
        reason: 'masterDeck != draw + hand + discard + exhaust',
      );
    }

    test('remélange à sec au milieu d\'une pioche', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: cards.sublist(0, 3),
        hand: [],
        discardPile: cards.sublist(3, 10),
      );

      notifier.drawCards(5, maxHandSize: 10);

      expect(notifier.state.hand.length, 5);
      expect(notifier.state.drawPile.length, 5);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.reshuffleCount, 1);
      expectConservation(notifier.state);
    });

    test('deck totalement épuisé : sortie propre, aucune exception', () {
      final cards = List.generate(3, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: [],
        discardPile: [],
        exhaustPile: cards,
      );

      notifier.drawCards(3, maxHandSize: 10);

      expect(notifier.state.hand, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('arrêt net sur main pleine : aucune pile touchée, aucun remélange', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: cards.sublist(0, 3),
        discardPile: cards.sublist(3, 10),
      );

      notifier.drawCards(2, maxHandSize: 3);

      expect(notifier.state.hand.length, 3);
      expect(notifier.state.drawPile, isEmpty);
      expect(notifier.state.discardPile.length, 7);
      // L'assertion qui distingue « arrêt net » de « carte consommée vers la défausse » :
      // la seconde aurait remélangé les 7 cartes pour ne rien donner au joueur.
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('pioche partielle : on prend ce qui existe puis on s\'arrête', () {
      final cards = List.generate(4, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: cards.sublist(0, 2),
        hand: [],
        discardPile: [],
        exhaustPile: cards.sublist(2, 4),
      );

      notifier.drawCards(5, maxHandSize: 10);

      expect(notifier.state.hand.length, 2);
      expect(notifier.state.drawPile, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('reshuffleCount s\'incrémente exactement une fois par remélange', () {
      final cards = List.generate(4, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: [],
        discardPile: cards,
      );

      notifier.drawCards(4, maxHandSize: 10);
      expect(notifier.state.reshuffleCount, 1);

      // Tour suivant : on renvoie tout en défausse et on repioche.
      notifier.discardHand();
      notifier.drawCards(4, maxHandSize: 10);
      expect(notifier.state.reshuffleCount, 2);
      expectConservation(notifier.state);
    });
  });
```

Réécrire ensuite les **deux tests existants périmés** du groupe `DeckNotifier Tests` :

Remplacer intégralement le test `'drawCards draws up to active drawPile size mid-turn and does not shuffle discard'` (`test/unit/deck_controller_test.dart:21-75`) par :

```dart
    test(
      'drawCards remélange désormais la défausse quand la pioche est vide',
      () {
        final cardA = _card('strike');
        final cardB = _card('defend');

        notifier.initializeStarterDeck([cardA, cardB]);
        notifier.state = notifier.state.copyWith(
          drawPile: [cardA],
          hand: [],
          discardPile: [cardB],
        );

        notifier.drawCards(2, maxHandSize: 10);

        // Comportement inversé par P-02 : cardB ne reste plus bloquée en défausse.
        expect(notifier.state.hand.length, 2);
        expect(notifier.state.drawPile, isEmpty);
        expect(notifier.state.discardPile, isEmpty);
        expect(notifier.state.reshuffleCount, 1);
      },
    );
```

Remplacer intégralement le test `'shuffleDiscardIntoDraw manually merges discard into draw pile'` (`:77-131`) par :

```dart
    test('la défausse rejoint la pioche sans appel manuel', () {
      final cardA = _card('strike');
      final cardB = _card('defend');

      notifier.initializeStarterDeck([cardA, cardB]);
      notifier.state = notifier.state.copyWith(
        drawPile: [cardA],
        hand: [],
        discardPile: [cardB],
      );

      // Une seule carte demandée : la pioche se vide, pas de remélange.
      notifier.drawCards(1, maxHandSize: 10);
      expect(notifier.state.reshuffleCount, 0);
      expect(notifier.state.discardPile.length, 1);

      // La suivante déclenche le remélange.
      notifier.drawCards(1, maxHandSize: 10);
      expect(notifier.state.hand.length, 2);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.reshuffleCount, 1);
    });
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/deck_controller_test.dart`
Expected: FAIL — `drawCards` n'accepte pas le paramètre nommé `maxHandSize`.

- [ ] **Step 3: Ajouter `GameConstants.maxHandSize`**

Dans `lib/game/game_constants.dart`, après le bloc `--- MAP GENERATION QUOTAS ---` :

```dart
  // --- DECK RULES ---
  /// Nombre maximum de cartes en main. Au-delà, la pioche s'interrompt sans
  /// consommer de carte ni déclencher de remélange (règle « arrêt net »).
  static const int maxHandSize = 10;
```

- [ ] **Step 4: Écrire le moteur et réécrire `drawCards`**

Dans `lib/game/controllers/deck_controller.dart`, **remplacer intégralement** `drawCards` et `shuffleDiscardIntoDraw` par :

```dart
  /// Cœur de la pioche. Fonction pure : ne touche pas à `state`, mute les
  /// listes qu'on lui passe et rend le nombre de remélanges effectués.
  ///
  /// Deux conditions d'arrêt, dans cet ordre :
  ///  1. la main a atteint [maxHandSize] — on s'arrête sans consommer de carte
  ///     ni déclencher de remélange ;
  ///  2. pioche ET défausse vides — le deck est épuisé, sortie propre.
  static ({
    List<CardInstance> draw,
    List<CardInstance> hand,
    List<CardInstance> discard,
    int reshuffles,
  }) _drawInto({
    required List<CardInstance> draw,
    required List<CardInstance> hand,
    required List<CardInstance> discard,
    required int amount,
    required int maxHandSize,
    required Random random,
  }) {
    var reshuffles = 0;

    for (var i = 0; i < amount; i++) {
      if (hand.length >= maxHandSize) break;
      if (draw.isEmpty) {
        if (discard.isEmpty) break;
        draw
          ..addAll(discard)
          ..shuffle(random);
        discard.clear();
        reshuffles++;
      }
      hand.add(draw.removeLast());
    }

    return (draw: draw, hand: hand, discard: discard, reshuffles: reshuffles);
  }

  /// Pioche [amount] cartes. Remélange la défausse dans la pioche dès que
  /// celle-ci est vide, y compris au milieu d'une pioche. Une seule
  /// affectation de `state`, donc une seule notification Riverpod.
  void drawCards(int amount, {required int maxHandSize}) {
    final result = _drawInto(
      draw: List<CardInstance>.from(state.drawPile),
      hand: List<CardInstance>.from(state.hand),
      discard: List<CardInstance>.from(state.discardPile),
      amount: amount,
      maxHandSize: maxHandSize,
      random: _random,
    );

    state = state.copyWith(
      drawPile: result.draw,
      hand: result.hand,
      discardPile: result.discard,
      reshuffleCount: state.reshuffleCount + result.reshuffles,
    );
  }
```

`shuffleDiscardIntoDraw` disparaît complètement : la règle cesse d'être optionnelle.

- [ ] **Step 5: Propager la signature aux trois appelants**

`lib/game/services/effects/strategies.dart` — ajouter l'import en tête du fichier, après `import '../effect_resolver.dart';` :

```dart
import '../../game_constants.dart';
```

Puis, dans `DrawEffectStrategy.resolve` :

```dart
    deckController.drawCards(scaledValue, maxHandSize: GameConstants.maxHandSize);
```

`lib/game/services/effect_resolver.dart` — ajouter l'import après `import 'effects/effect_strategy.dart';` :

```dart
import '../game_constants.dart';
```

Puis, dans `resolveCard` :

```dart
    if (extraDraw > 0) {
      deckController.drawCards(extraDraw, maxHandSize: GameConstants.maxHandSize);
    }
```

`lib/ui/screens/game_screen.dart` — ajouter l'import après `import '../../game/heros_draft_game.dart';` :

```dart
import '../../game/game_constants.dart';
```

Dans `_startPlayerNewTurn`, **supprimer le seuil `< 5`** — `drawCards` s'en charge désormais :

```dart
    ref.read(runProvider.notifier).startTurn();
    ref
        .read(deckProvider.notifier)
        .drawCards(5, maxHandSize: GameConstants.maxHandSize);
```

Dans la microtask d'`initState`, ligne 276 :

```dart
      ref
          .read(deckProvider.notifier)
          .drawCards(5, maxHandSize: GameConstants.maxHandSize);
```

- [ ] **Step 6: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/deck_controller_test.dart`
Expected: PASS — 12 tests.

- [ ] **Step 7: Vérifier la non-régression sur les appelants**

Run: `flutter test test/unit/effect_resolver_test.dart test/unit/combat_controller_test.dart test/unit/decoupled_forge_test.dart`
Expected: PASS

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/game/game_constants.dart lib/game/controllers/deck_controller.dart lib/game/services/effects/strategies.dart lib/game/services/effect_resolver.dart lib/ui/screens/game_screen.dart test/unit/deck_controller_test.dart
git commit -m "feat(P-02): remelange a sec et limite de main dans drawCards"
```

---

### Task 3: `DeckNotifier.startCombat` — la main d'ouverture en une passe

`initializeCombat()` et le `drawCards(5)` séparé fusionnent. La main d'ouverture respecte exactement les mêmes invariants que toute autre pioche, et `state` n'est affecté qu'une fois — donc un seul `layoutHand()` au lieu de deux.

**Files:**
- Modify: `lib/game/controllers/deck_controller.dart`
- Modify: `lib/ui/screens/game_screen.dart:275-278`
- Test: `test/unit/deck_controller_test.dart`
- Modify (appelants de test): `test/unit/combat_controller_test.dart:334` et `:481`

**Interfaces:**
- Consumes: `_drawInto` (tâche 2)
- Produces: `DeckNotifier.startCombat({required int handSize, required int maxHandSize})`. `DeckNotifier.initializeCombat()` est **supprimée**.

- [ ] **Step 1: Écrire les tests qui échouent**

Ajouter dans le groupe `DeckNotifier — moteur de pioche` de `test/unit/deck_controller_test.dart` :

```dart
    test('startCombat constitue la pioche et tire la main d\'ouverture', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);

      notifier.startCombat(handSize: 5, maxHandSize: 10);

      expect(notifier.state.hand.length, 5);
      expect(notifier.state.drawPile.length, 5);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.exhaustPile, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('startCombat repart d\'un état propre et remet reshuffleCount à 0', () {
      final cards = List.generate(6, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);

      // État sale hérité d'un combat précédent.
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: cards.sublist(0, 2),
        discardPile: cards.sublist(2, 4),
        exhaustPile: cards.sublist(4, 6),
        reshuffleCount: 4,
      );

      notifier.startCombat(handSize: 5, maxHandSize: 10);

      expect(notifier.state.hand.length, 5);
      expect(notifier.state.drawPile.length, 1);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.exhaustPile, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('startCombat respecte maxHandSize', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);

      notifier.startCombat(handSize: 5, maxHandSize: 3);

      expect(notifier.state.hand.length, 3);
      expect(notifier.state.drawPile.length, 7);
      expectConservation(notifier.state);
    });
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/deck_controller_test.dart`
Expected: FAIL — `startCombat` n'est pas défini sur `DeckNotifier`.

- [ ] **Step 3: Remplacer `initializeCombat` par `startCombat`**

Dans `lib/game/controllers/deck_controller.dart`, **remplacer intégralement** la méthode `initializeCombat()` par :

```dart
  /// Prépare les piles pour un nouveau combat et tire la main d'ouverture,
  /// en une seule affectation d'état. La main de départ respecte exactement
  /// les mêmes invariants que toutes les pioches suivantes.
  void startCombat({required int handSize, required int maxHandSize}) {
    final result = _drawInto(
      draw: List<CardInstance>.from(state.masterDeck)..shuffle(_random),
      hand: <CardInstance>[],
      discard: <CardInstance>[],
      amount: handSize,
      maxHandSize: maxHandSize,
      random: _random,
    );

    state = state.copyWith(
      drawPile: result.draw,
      hand: result.hand,
      discardPile: result.discard,
      exhaustPile: [],
      reshuffleCount: 0,
    );
  }
```

- [ ] **Step 4: Mettre à jour les appelants**

`lib/ui/screens/game_screen.dart` — dans la microtask d'`initState`, remplacer les deux lignes `initializeCombat()` / `drawCards(5, ...)` par un seul appel :

```dart
      ref.read(deckProvider.notifier).startCombat(
            handSize: 5,
            maxHandSize: GameConstants.maxHandSize,
          );
```

`test/unit/combat_controller_test.dart` — aux **deux** sites (`:334` et `:481`), remplacer :

```dart
        deckNotifier.initializeCombat();
```

par :

```dart
        deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.maxHandSize);
```

`handSize: 0` préserve l'intention d'origine : ces tests écrasent la main juste après avec `copyWith(hand: [strikeCard])`.

Ajouter l'import en tête de `test/unit/combat_controller_test.dart` :

```dart
import 'package:roguelike_card_game/game/game_constants.dart';
```

- [ ] **Step 5: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/deck_controller_test.dart test/unit/combat_controller_test.dart`
Expected: PASS

- [ ] **Step 6: Vérifier l'analyse**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/game/controllers/deck_controller.dart lib/ui/screens/game_screen.dart test/unit/deck_controller_test.dart test/unit/combat_controller_test.dart
git commit -m "feat(P-02): startCombat absorbe la main d ouverture en une passe"
```

---

### Task 4: `RunState.cardsPerTurn` — le 5 codé en dur devient une statistique

**Files:**
- Modify: `lib/game/controllers/run_controller.dart` (classe `RunState` + façade `RunController`)
- Modify: `lib/game/controllers/run/player_stats_manager.dart`
- Test: `test/unit/run_controller_test.dart`
- Test: `test/unit/run_state_persistence_test.dart`

**Interfaces:**
- Consumes: rien
- Produces:
  - `RunState.cardsPerTurn` — `int`, défaut `5`, présent dans `copyWith`, `toJson`, `fromJsonWithReport`
  - `PlayerStatsManager.applyRunRuleModifier({int cardsPerTurnAcc = 0})`
  - `RunController.applyRunRuleModifier({int cardsPerTurnAcc = 0})` — façade

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/unit/run_controller_test.dart`, ajouter ce groupe à l'intérieur de `void main()` :

```dart
  group('RunState.cardsPerTurn', () {
    const dummyHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regenArmor',
    );

    test('vaut 5 au démarrage d\'une run', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(dummyHero);

      expect(container.read(runProvider).cardsPerTurn, 5);
    });

    test('applyRunRuleModifier ajoute puis retire symétriquement', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(dummyHero);

      runController.applyRunRuleModifier(cardsPerTurnAcc: 1);
      expect(container.read(runProvider).cardsPerTurn, 6);

      runController.applyRunRuleModifier(cardsPerTurnAcc: -1);
      expect(container.read(runProvider).cardsPerTurn, 5);
    });
  });
```

Aucun import à ajouter : `run_controller_test.dart` importe déjà `HeroData` (ligne 5), `runProvider` (ligne 3) et `ProviderContainer` (ligne 2).

Dans `test/unit/run_state_persistence_test.dart`, ajouter `cardsPerTurn: 7,` dans le `buildRunState()` existant (juste après `pendingDrafts: 2,`), puis ajouter ce test à l'intérieur du groupe `RunState persistence` :

```dart
    test('cardsPerTurn round-trip et vaut 5 sur une sauvegarde antérieure', () {
      final json = buildRunState().toJson();
      expect(json['cardsPerTurn'], 7);

      final (restored, _) = RunState.fromJsonWithReport(json);
      expect(restored.cardsPerTurn, 7);

      final legacy = Map<String, dynamic>.from(json)..remove('cardsPerTurn');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.cardsPerTurn, 5);
    });
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/run_controller_test.dart test/unit/run_state_persistence_test.dart`
Expected: FAIL — `cardsPerTurn` et `applyRunRuleModifier` n'existent pas.

- [ ] **Step 3: Ajouter le champ à `RunState`**

Dans `lib/game/controllers/run_controller.dart`, classe `RunState` — cinq points de couture.

Champ, après `pendingDrafts` :

```dart
  final int pendingDrafts; // Nombre de drafts de montée de niveau en attente

  /// Cartes piochées au début de chaque tour, et taille de la main d'ouverture.
  /// Règle de run propre au joueur : elle n'a pas sa place sur `EntityStats`,
  /// qui est partagé avec les ennemis.
  final int cardsPerTurn;
```

Constructeur — ajouter après `this.pendingDrafts = 0,` :

```dart
    this.cardsPerTurn = 5,
```

`copyWith` — ajouter le paramètre après `int? pendingDrafts,` :

```dart
    int? cardsPerTurn,
```

et la ligne de construction après `pendingDrafts: pendingDrafts ?? this.pendingDrafts,` :

```dart
      cardsPerTurn: cardsPerTurn ?? this.cardsPerTurn,
```

`toJson` — ajouter après `'pendingDrafts': pendingDrafts,` :

```dart
        'cardsPerTurn': cardsPerTurn,
```

`fromJsonWithReport` — ajouter dans le `RunState(...)` construit, après `pendingDrafts: json['pendingDrafts'] as int? ?? 0,` :

```dart
      cardsPerTurn: json['cardsPerTurn'] as int? ?? 5,
```

- [ ] **Step 4: Ajouter le mutateur**

Dans `lib/game/controllers/run/player_stats_manager.dart`, juste **après** la méthode `applyHeroStatModifier` :

```dart
  /// Applique un modificateur aux règles de run propres au joueur.
  /// Distinct d'`applyHeroStatModifier`, qui opère sur `EntityStats` — lequel
  /// est partagé avec les ennemis et n'a donc pas à porter de notion de deck.
  void applyRunRuleModifier({int cardsPerTurnAcc = 0}) {
    controller.updateState(
      controller.currentState.copyWith(
        cardsPerTurn: controller.currentState.cardsPerTurn + cardsPerTurnAcc,
      ),
    );
  }
```

Dans `lib/game/controllers/run_controller.dart`, classe `RunController`, juste **après** la façade `applyHeroStatModifier` :

```dart
  /// Applique un modificateur aux règles de run propres au joueur
  void applyRunRuleModifier({int cardsPerTurnAcc = 0}) {
    _playerStatsManager.applyRunRuleModifier(cardsPerTurnAcc: cardsPerTurnAcc);
  }
```

- [ ] **Step 5: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/run_controller_test.dart test/unit/run_state_persistence_test.dart`
Expected: PASS

- [ ] **Step 6: Vérifier la non-régression et l'analyse**

Run: `flutter test test/unit/save_service_test.dart test/unit/notifier_hydrate_test.dart`
Expected: PASS

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/game/controllers/run_controller.dart lib/game/controllers/run/player_stats_manager.dart test/unit/run_controller_test.dart test/unit/run_state_persistence_test.dart
git commit -m "feat(P-02): cardsPerTurn devient une regle de run sur RunState"
```

---

### Task 5: La règle de tour quitte le widget

Le cœur architectural. `TurnPhaseManager` gagne la moitié joueur du cycle, `game_screen.dart` ne fait plus qu'animer, et `_turnCount` ainsi que le deck de secours disparaissent.

**Files:**
- Modify: `lib/game/controllers/combat/turn_phase_manager.dart`
- Modify: `lib/game/controllers/combat_controller.dart`
- Modify: `lib/ui/screens/game_screen.dart` (`_startPlayerNewTurn`, microtask d'`initState`, `_turnCount`, `TurnControlPanel`)
- Test: `test/unit/combat_controller_test.dart`

**Interfaces:**
- Consumes: `DeckNotifier.startCombat` / `drawCards` (tâches 2-3), `RunState.cardsPerTurn` (tâche 4), `GameConstants.maxHandSize` (tâche 2)
- Produces:
  - `TurnPhaseManager.startPlayerCombat()` et `TurnPhaseManager.startPlayerTurn()`
  - `CombatController.startPlayerCombat()` et `CombatController.startPlayerTurn()` — façades
  - `_GameScreenState._turnCount` — **supprimé**

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/unit/combat_controller_test.dart`, ajouter ce groupe à l'intérieur de `void main()` :

> **Attention au périmètre lexical.** `paladinHero`, `goblinData` et `orcData` sont déclarés
> **à l'intérieur** du groupe `CombatController Tests` (`combat_controller_test.dart:20-58`),
> pas au niveau de `main()`. Le nouveau groupe étant un frère, il ne les voit pas : il déclare
> donc son propre héros.

```dart
  group('CombatController — moitié joueur du cycle de tour', () {
    final paladinHero = HeroData(
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
      passiveTrait: 'regenArmor',
    );

    const ironTalisman = RelicData(
      id: 'iron_talisman',
      nameEn: 'Iron Talisman',
      nameFr: 'Talisman de Fer',
      trigger: RelicTrigger.startOfTurn,
      effectType: 'gain_armor',
      value: 2,
      rarity: RelicRarity.common,
      emoji: '🪙',
    );

    CardInstance card(String id) => CardInstance(
          data: CardData(
            id: id,
            nameEn: id,
            nameFr: id,
            cost: 1,
            type: CardType.skill,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.self,
            effects: const [],
          ),
        );

    test('startPlayerTurn exécute la relique startOfTurn ET la pioche', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      final deckNotifier = container.read(deckProvider.notifier);
      final combatController = container.read(combatProvider.notifier);

      runController.startNewRun(paladinHero);
      container.read(inventoryProvider.notifier).addRelic(ironTalisman);
      deckNotifier.initializeStarterDeck(List.generate(10, (i) => card('c$i')));
      deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.maxHandSize);

      combatController.startPlayerTurn();

      // Moitié « run » : mana restauré au max et armure de la relique appliquée.
      expect(runController.currentState.heroStats.currentMana,
          runController.currentState.heroStats.maxMana);
      expect(runController.currentState.heroStats.armure, 2);
      // Moitié « deck » : la main vaut cardsPerTurn.
      expect(deckNotifier.state.hand.length, 5);
    });

    test('startPlayerTurn pioche cardsPerTurn, pas 5 en dur', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      final deckNotifier = container.read(deckProvider.notifier);
      final combatController = container.read(combatProvider.notifier);

      runController.startNewRun(paladinHero);
      runController.applyRunRuleModifier(cardsPerTurnAcc: 1);
      deckNotifier.initializeStarterDeck(List.generate(10, (i) => card('c$i')));
      deckNotifier.startCombat(handSize: 0, maxHandSize: GameConstants.maxHandSize);

      combatController.startPlayerTurn();

      expect(deckNotifier.state.hand.length, 6);
    });

    test('startPlayerCombat ouvre le combat et tire la main de départ', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      final deckNotifier = container.read(deckProvider.notifier);
      final combatController = container.read(combatProvider.notifier);

      runController.startNewRun(paladinHero);
      deckNotifier.initializeStarterDeck(List.generate(10, (i) => card('c$i')));
      // Statut résiduel d'un combat précédent : startCombat doit le nettoyer.
      runController.addStatus(const StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 3,
        duration: 3,
      ));

      combatController.startPlayerCombat();

      // Cible le poison plutôt que `isEmpty` : le test resterait vrai si un
      // passif ou une relique ajoutait un statut au début du combat.
      expect(
        runController.currentState.heroStats.statuses
            .any((s) => s.id == 'poison'),
        isFalse,
      );
      expect(runController.currentState.heroStats.currentMana,
          runController.currentState.heroStats.maxMana);
      expect(deckNotifier.state.hand.length, 5);
      expect(deckNotifier.state.drawPile.length, 5);
      expect(deckNotifier.state.reshuffleCount, 0);
    });
  });
```

Ajouter exactement ces **deux** imports en tête de `test/unit/combat_controller_test.dart` :

```dart
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
```

> **Ni plus, ni moins.** `status_effect.dart` est **déjà** importé (ligne 13) : le ré-importer
> déclencherait `duplicate_import` et casserait `dart analyze`. Sont également déjà présents
> `combat_controller.dart` (3), `run_controller.dart` (4), `deck_controller.dart` (5),
> `hero_data.dart` (10), `card_data.dart` (11), `card_instance.dart` (12) ; `game_constants.dart`
> a été ajouté par la tâche 3. Manquent seulement `inventoryProvider` et le trio
> `RelicData` / `RelicTrigger` / `RelicRarity`, d'où les deux lignes ci-dessus.

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/combat_controller_test.dart`
Expected: FAIL — `startPlayerTurn` et `startPlayerCombat` ne sont pas définis sur `CombatController`.

- [ ] **Step 3: Ajouter les deux méthodes à `TurnPhaseManager`**

Dans `lib/game/controllers/combat/turn_phase_manager.dart`, ajouter ces imports en tête :

```dart
import 'package:flutter/foundation.dart';
import '../deck_controller.dart';
import '../../game_constants.dart';
```

Puis insérer ces deux méthodes **avant** `startEnemyTurn()` :

```dart
  /// Ouvre le combat côté joueur : nettoyage des statuts, mana au max,
  /// reliques `startOfCombat`, puis main d'ouverture.
  ///
  /// L'ordre est celui d'avant P-02 et doit le rester : `startCombat()`
  /// déclenche les reliques, la pioche vient après.
  void startPlayerCombat() {
    final runController = ref.read(runProvider.notifier);
    final deckController = ref.read(deckProvider.notifier);

    if (kDebugMode && ref.read(deckProvider).masterDeck.isEmpty) {
      debugPrint('startPlayerCombat: masterDeck vide — '
          'StarterDeckDraftScreen a-t-il été court-circuité ?');
    }

    runController.startCombat();
    deckController.startCombat(
      handSize: runController.currentState.cardsPerTurn,
      maxHandSize: GameConstants.maxHandSize,
    );
  }

  /// Ouvre un tour joueur : mana, armure, reliques `startOfTurn`, statuts,
  /// cooldowns et passifs, puis pioche.
  ///
  /// L'ordre est celui d'avant P-02 et doit le rester : inverser les deux
  /// appels décalerait toute relique `startOfTurn` d'un tour.
  void startPlayerTurn() {
    final runController = ref.read(runProvider.notifier);

    runController.startTurn();
    ref.read(deckProvider.notifier).drawCards(
          runController.currentState.cardsPerTurn,
          maxHandSize: GameConstants.maxHandSize,
        );
  }
```

- [ ] **Step 4: Exposer les deux méthodes sur `CombatController`**

Dans `lib/game/controllers/combat_controller.dart`, ajouter **avant** `startEnemyTurn()` :

```dart
  /// Ouvre le combat côté joueur (statuts, mana, reliques, main d'ouverture)
  void startPlayerCombat() {
    _turnPhaseManager.startPlayerCombat();
  }

  /// Ouvre un tour joueur (mana, reliques, statuts, pioche)
  void startPlayerTurn() {
    _turnPhaseManager.startPlayerTurn();
  }
```

- [ ] **Step 5: Alléger `game_screen.dart`**

Dans `lib/ui/screens/game_screen.dart` :

**a.** Supprimer le champ `int _turnCount = 1;` (ligne 63).

**b.** Remplacer intégralement `_startPlayerNewTurn` :

```dart
  void _startPlayerNewTurn() {
    setState(() {
      _showManaWarning = false;
      _showRemainingManaWarning = false;
    });
    _game.currentPhase = TurnPhase.player;
    _game.heroCard?.suppressArmorChangeAnimation = true;
    ref.read(combatProvider.notifier).startPlayerTurn();
  }
```

**c.** Dans la microtask d'`initState`, supprimer le bloc du deck de secours (`if (deck.masterDeck.isEmpty) { … initializeStarterDeck(starterCards); }`) **et** la ligne `final deck = ref.read(deckProvider);` qui le précède, puis remplacer l'appel à `runController.startCombat()` et l'appel `deckProvider.notifier.startCombat(...)` de sorte que la microtask devienne :

```dart
    Future.microtask(() {
      ref.read(combatProvider.notifier).startPlayerCombat();

      final runState = ref.read(runProvider);
      final currentNode = runState.mapNodes.firstWhere(
        (n) => n.id == runState.currentNodeId,
        orElse: () => runState.mapNodes.first,
      );
      final bossEnemyId = currentNode.bossEnemyId;
      final gameData = ref.read(gameDataLoaderProvider).requireValue;
      ref
          .read(combatProvider.notifier)
          .initializeCombat(
            runState.currentLevel,
            runState.currentNodeType,
            gameData.enemies,
            playerLevel: runState.heroStats.level,
            act: runState.act,
            playerMaxHp: runState.heroStats.maxPv,
            playerAttaque: runState.heroStats.attaque,
            playerMaxMana: runState.heroStats.maxMana,
            playerRelicsCount: ref.read(inventoryProvider).relics.length,
            playerCardsCount: ref.read(deckProvider).masterDeck.length,
            bossEnemyId: bossEnemyId,
          );
    });
```

**d.** Dans le `build`, alimenter `TurnControlPanel` par l'état de combat :

```dart
                      turnCount: combatState.turnCount,
```

**e.** Supprimer les imports devenus inutilisés. Après les points **a** à **d**, `game_screen.dart` n'appelle plus ni `drawCards` ni `startCombat` (la tâche 5 les a tous transférés dans `TurnPhaseManager`) et ne construit plus de deck de secours. **Les deux imports suivants doivent donc disparaître :**

```dart
import '../../models/card_instance.dart';   // plus de deck de secours
import '../../game/game_constants.dart';    // ajouté en tâche 2, plus d'appelant ici
```

`dart analyze` fait foi : si d'autres imports remontent en `unused_import`, les retirer aussi ; si l'un de ces deux ne remonte PAS, c'est qu'un appelant a été oublié — le chercher avant de continuer.

- [ ] **Step 6: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/combat_controller_test.dart`
Expected: PASS

- [ ] **Step 7: Vérifier la non-régression et l'analyse**

Run: `flutter test`
Expected: PASS sur les 42 fichiers

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/game/controllers/combat/turn_phase_manager.dart lib/game/controllers/combat_controller.dart lib/ui/screens/game_screen.dart test/unit/combat_controller_test.dart
git commit -m "feat(P-02): la regle de tour joueur quitte game_screen pour TurnPhaseManager"
```

---

### Task 6: La relique `increase_cards_per_turn`

Première relique du jeu à toucher au deck. Rareté `legendary`, calibrée sur la Couronne des Rois (+1 Mana Max permanent, `relics.json:279`).

**Files:**
- Modify: `lib/game/controllers/run/player_stats_manager.dart` (`applyRelicEffect` + `removeRelicEffect`)
- Modify: `assets/data/relics.json`
- Test: `test/unit/relic_exchange_test.dart`

**Interfaces:**
- Consumes: `PlayerStatsManager.applyRunRuleModifier` (tâche 4)
- Produces: `effectType: 'increase_cards_per_turn'`, reconnu à l'application **et** au retrait

- [ ] **Step 1: Écrire le test qui échoue**

Dans `test/unit/relic_exchange_test.dart`, ajouter ce test à l'intérieur du groupe `Relic Exchange Transaction Logic Tests` :

```dart
    test('increase_cards_per_turn s\'applique et se retire symétriquement', () {
      const satchel = RelicData(
        id: 'scholars_satchel',
        nameEn: "Scholar's Satchel",
        nameFr: "Besace de l'Érudit",
        trigger: RelicTrigger.startOfRun,
        effectType: 'increase_cards_per_turn',
        value: 1,
        rarity: RelicRarity.legendary,
        emoji: '🎒',
      );
      const filler = RelicData(
        id: 'filler',
        nameEn: 'Filler',
        nameFr: 'Bouche-trou',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_strength',
        value: 1,
        rarity: RelicRarity.common,
        emoji: '⬜',
      );

      expect(runController.currentState.cardsPerTurn, 5);

      inventoryController.addRelic(satchel);
      runController.applyRelicEffect(satchel);
      expect(runController.currentState.cardsPerTurn, 6);

      // Sacrifice via l'Échange de Reliques : le bonus ne doit pas fuiter.
      runController.exchangeRelics([satchel], filler);
      expect(runController.currentState.cardsPerTurn, 5);
      expect(
        inventoryController.state.relics.any((r) => r.id == 'scholars_satchel'),
        isFalse,
      );
    });
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

Run: `flutter test test/unit/relic_exchange_test.dart --plain-name "increase_cards_per_turn"`
Expected: FAIL — `cardsPerTurn` reste à 5 après `applyRelicEffect` (aucun `case` ne reconnaît l'`effectType`).

- [ ] **Step 3: Ajouter le `case` d'application**

Dans `lib/game/controllers/run/player_stats_manager.dart`, méthode `applyRelicEffect`, ajouter ce `case` juste **après** le `case 'heal':` :

```dart
      // Cet effectType n'a de sens qu'en `startOfRun` : une variante par combat
      // ou par tour cumulerait indéfiniment. Aucune garde n'est posée ici, le
      // contrat étant porté par la donnée (`relics.json`) et par le `case`
      // symétrique de `removeRelicEffect`.
      case 'increase_cards_per_turn':
        applyRunRuleModifier(cardsPerTurnAcc: relic.value);
        break;
```

- [ ] **Step 4: Ajouter le `case` de retrait**

Toujours dans `player_stats_manager.dart`, méthode `removeRelicEffect`, **à l'intérieur** du bloc `if (relic.trigger == RelicTrigger.startOfRun)`, après `case 'gain_crit':` :

```dart
        case 'increase_cards_per_turn':
          applyRunRuleModifier(cardsPerTurnAcc: -relic.value);
          break;
```

- [ ] **Step 5: Ajouter l'entrée de données**

Dans `assets/data/relics.json`, ajouter cette entrée **à la fin du tableau**, après `crown_kings` (penser à la virgule après l'accolade fermante de `crown_kings`) :

```json
  {
    "id": "scholars_satchel",
    "name_en": "Scholar's Satchel",
    "name_fr": "Besace de l'Érudit",
    "description_en": "Draw 1 additional card at the start of each turn, for the entire run.",
    "description_fr": "Pioche 1 carte supplémentaire au début de chaque tour, pour toute la run.",
    "trigger": "startOfRun",
    "effectType": "increase_cards_per_turn",
    "value": 1,
    "rarity": "legendary",
    "emoji": "🎒"
  }
```

- [ ] **Step 6: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/relic_exchange_test.dart`
Expected: PASS

- [ ] **Step 7: Vérifier le JSON, la non-régression et l'analyse**

Run: `flutter test test/unit/probabilities_test.dart test/unit/reward_controller_test.dart test/unit/save_catalog_lookups_test.dart`
Expected: PASS — ces suites parcourent le pool de reliques et détecteront un JSON malformé.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/game/controllers/run/player_stats_manager.dart assets/data/relics.json test/unit/relic_exchange_test.dart
git commit -m "feat(P-02): relique Besace de l Erudit, +1 carte piochee par tour"
```

---

### Task 7: Le toast de remélange

Le remélange devient un moment significatif : il marque désormais la fin d'un cycle de deck complet au lieu de se déclencher presque chaque tour.

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/ui/screens/game_screen.dart` (dans `build`)
- Regenerate: `lib/l10n/app_localizations*.dart` via `flutter gen-l10n`

**Interfaces:**
- Consumes: `DeckState.reshuffleCount` (tâche 1)
- Produces: `AppLocalizations.deckReshuffled` — `String`, sans placeholder

- [ ] **Step 1: Ajouter les chaînes localisées**

Dans `lib/l10n/app_en.arb`, ajouter cette paire clé/valeur (à côté des autres chaînes de combat) :

```json
  "deckReshuffled": "Discard pile reshuffled",
```

Dans `lib/l10n/app_fr.arb`, à la position correspondante :

```json
  "deckReshuffled": "Défausse remélangée",
```

- [ ] **Step 2: Régénérer les fichiers de localisation**

Run: `flutter gen-l10n`
Expected: aucune erreur ; `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` gagnent `deckReshuffled`.

- [ ] **Step 3: Vérifier la parité des clés**

Run: `flutter test test/unit/localization_test.dart`
Expected: PASS — cette suite vérifie la cohérence entre les deux locales.

- [ ] **Step 4: Brancher l'écoute dans `game_screen.dart`**

Dans `lib/ui/screens/game_screen.dart`, méthode `build`, ajouter ce `ref.listen` juste **après** le `ref.listen<CombatState>(combatProvider, …)` existant :

```dart
    ref.listen<DeckState>(deckProvider, (previous, next) {
      if (previous != null && next.reshuffleCount > previous.reshuffleCount) {
        context.showNotification(
          '🔄 ${AppLocalizations.of(context)!.deckReshuffled}',
          type: NotificationType.info,
        );
      }
    });
```

`AppLocalizations`, `NotificationType`, `showNotification`, `DeckState` et `deckProvider` sont déjà importés par ce fichier.

La remise à 0 par `startCombat` ne déclenche rien : le compteur diminue, la condition est stricte.

- [ ] **Step 5: Vérifier la compilation et l'analyse**

Run: `flutter test`
Expected: PASS

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/ lib/ui/screens/game_screen.dart
git commit -m "feat(P-02): notification joueur au remelange de la defausse"
```

---

### Task 8: Suppression du code mort résiduel

Quatre éléments morts vérifiés par grep sur `lib/` **et** `test/`. Aucun n'a de consommateur réel. `HerosDraftGame` passe de 13 à 11 callbacks.

**Files:**
- Modify: `lib/models/card_instance.dart`
- Modify: `lib/models/enemy_intent.dart`
- Modify: `lib/game/controllers/combat/turn_phase_manager.dart:110-111`
- Modify: `lib/models/data/model_extensions.dart:108-109`
- Modify: `lib/ui/widgets/hud/enemy_intents_panel.dart:129-133`
- Modify: `lib/game/heros_draft_game.dart` (champs 57-58, paramètres 76-77)
- Modify: `lib/ui/screens/game_screen.dart` (arguments `onEnemyDebuffDeck`, `onTurnEnded`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (retrait d'`intentCurse`)

**Interfaces:**
- Consumes: `CombatController.startPlayerTurn` (tâche 5) — le flux ne dépend plus des callbacks supprimés
- Produces: `CardInstance.currentCost` devient `=> data.cost` ; `IntentType` n'a plus que `attack, defend, buff`

- [ ] **Step 1: Vérifier qu'aucun consommateur ne subsiste**

Run:
```bash
grep -rn "temporaryCost\|clearTemporaryCost\|debuffDeck\|onEnemyDebuffDeck\|onTurnEnded\|intentCurse" lib/ test/
```
Expected: uniquement les sites listés ci-dessus. Si un site inattendu apparaît, **arrêter** et le traiter avant de continuer.

- [ ] **Step 2: Supprimer `temporaryCost`**

Dans `lib/models/card_instance.dart`, **remplacer intégralement** la classe par :

```dart
import 'package:uuid/uuid.dart';
import 'data/card_data.dart';

class CardInstance {
  final String uniqueId;
  final CardData data;
  final CardRarity rarity;
  final List<String> forgeUpgrades;

  CardInstance({
    String? uniqueId,
    required this.data,
    CardRarity? rarity,
    List<String>? forgeUpgrades,
  })  : uniqueId = uniqueId ?? const Uuid().v4(),
        rarity = rarity ?? data.rarity,
        forgeUpgrades = forgeUpgrades != null
            ? List<String>.unmodifiable(forgeUpgrades)
            : const <String>[];

  int get currentCost => data.cost;

  double get rarityMultiplier {
    switch (rarity) {
      case CardRarity.common:
        return 1.0;
      case CardRarity.uncommon:
        return 1.2;
      case CardRarity.rare:
        return 1.4;
      case CardRarity.epic:
        return 1.6;
      case CardRarity.legendary:
        return 2.0;
      case CardRarity.unique:
        return 1.0;
    }
  }

  CardInstance copyWith({
    String? uniqueId,
    CardData? data,
    CardRarity? rarity,
    List<String>? forgeUpgrades,
  }) {
    return CardInstance(
      uniqueId: uniqueId ?? this.uniqueId,
      data: data ?? this.data,
      rarity: rarity ?? this.rarity,
      forgeUpgrades: forgeUpgrades ?? this.forgeUpgrades,
    );
  }

  factory CardInstance.fromJson(Map<String, dynamic> json) {
    return CardInstance(
      uniqueId: json['uniqueId'] as String?,
      data: CardData.fromJson(json['data'] as Map<String, dynamic>),
      rarity: CardRarity.values.firstWhere((e) => e.name == json['rarity']),
      forgeUpgrades: (json['forgeUpgrades'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uniqueId': uniqueId,
        'data': data.toJson(),
        'rarity': rarity.name,
        'forgeUpgrades': forgeUpgrades,
      };
}
```

Une sauvegarde antérieure contenant `temporaryCost` verra simplement la clé ignorée.

- [ ] **Step 3: Supprimer `IntentType.debuffDeck` et ses trois `case`**

`lib/models/enemy_intent.dart` — première ligne :

```dart
enum IntentType { attack, defend, buff }
```

`lib/game/controllers/combat/turn_phase_manager.dart` — dans `resolveEnemyIntent`, supprimer les deux lignes :

```dart
      case IntentType.debuffDeck:
        break;
```

`lib/models/data/model_extensions.dart` — supprimer les deux lignes :

```dart
      case IntentType.debuffDeck:
        return l10n.intentCurse(value);
```

`lib/ui/widgets/hud/enemy_intents_panel.dart` — supprimer les cinq lignes :

```dart
                case IntentType.debuffDeck:
                  icon = Icons.sick;
                  color = const Color(0xFF69F0AE);
                  label = l10n.intentCurse(intent.value);
                  break;
```

- [ ] **Step 4: Retirer `intentCurse` des fichiers de localisation**

Dans `lib/l10n/app_en.arb`, supprimer la clé **et** son bloc de métadonnées :

```json
  "intentCurse": "Curse: {value}",
  "@intentCurse": {
    "placeholders": {
      "value": { "type": "int" }
    }
  },
```

Dans `lib/l10n/app_fr.arb`, supprimer la ligne :

```json
  "intentCurse": "Malédiction : {value}",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; `intentCurse` disparaît des trois fichiers générés.

- [ ] **Step 5: Supprimer les deux callbacks morts**

`lib/game/heros_draft_game.dart` — supprimer les deux déclarations de champ :

```dart
  final void Function(int) onEnemyDebuffDeck;
  final void Function() onTurnEnded;
```

et les deux paramètres du constructeur :

```dart
    required this.onEnemyDebuffDeck,
    required this.onTurnEnded,
```

`lib/ui/screens/game_screen.dart` — dans l'instanciation de `HerosDraftGame`, supprimer les deux arguments :

```dart
      onEnemyDebuffDeck: (count) {
        // Logique retirée car la carte "Blessure" de test a été supprimée
      },
      onTurnEnded: _startPlayerNewTurn,
```

`_startPlayerNewTurn` reste utilisé par `onEndEnemyTurn`, qui l'appelle explicitement — ne pas le supprimer.

- [ ] **Step 6: Lancer la suite complète et l'analyse**

Run: `flutter test`
Expected: PASS sur les 42 fichiers

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 7: Confirmer que le code mort a bien disparu**

Run:
```bash
grep -rn "temporaryCost\|clearTemporaryCost\|debuffDeck\|onEnemyDebuffDeck\|onTurnEnded\|intentCurse" lib/ test/
```
Expected: aucun résultat.

- [ ] **Step 8: Commit**

```bash
git add lib/models/card_instance.dart lib/models/enemy_intent.dart lib/models/data/model_extensions.dart lib/game/controllers/combat/turn_phase_manager.dart lib/ui/widgets/hud/enemy_intents_panel.dart lib/game/heros_draft_game.dart lib/ui/screens/game_screen.dart lib/l10n/
git commit -m "refactor(P-02): suppression de six elements de code mort lies au deck"
```

---

## Validation finale (après la tâche 8)

Ces trois étapes ne sont pas optionnelles : la ROADMAP conditionne P-16 (refonte des probabilités) à leur résultat.

- [ ] **`dart analyze` propre**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Suite complète verte**

Run: `flutter test`
Expected: PASS. Compter les tests : le chantier en ajoute **11 neufs** et en réécrit **2**.

- [ ] **Playtest de plusieurs combats complets**

Run: `flutter run`

Points à observer, dans l'ordre :
1. **Main d'ouverture** : 5 cartes au tour 1, comme avant.
2. **Remélange à sec** : jouer jusqu'à vider la pioche en milieu de tour. La pioche doit se reconstituer et la pioche se poursuivre, avec le toast « Défausse remélangée ».
3. **Cartes de pioche** : jouer `Concentration` (0 mana, pioche 2) avec une pioche vide et une défausse pleine. Elle doit désormais donner 2 cartes — avant P-02 elle ne faisait rien.
4. **Compteur de tour** : sauvegarder en plein combat, quitter, recharger. Le HUD doit afficher le bon numéro de tour, plus « Tour 1 ».
5. **Reliques `startOfTurn`** : équiper le Talisman de Fer. L'armure doit apparaître à chaque début de tour, avant la pioche — un décalage d'un tour signalerait une inversion d'ordre.
6. **Difficulté ressentie** : c'est le point qui ne se teste pas automatiquement. Le passage du seuil `< 5` au remélange à sec fait revoir les bonnes cartes moins souvent en début de combat et rend le deck plus prévisible en fin de combat. **Noter l'impression avant de considérer P-02 clos.**

- [ ] **Documentation**

Après validation, lancer les deux skills propriétaires — ce plan n'édite ni l'un ni l'autre périmètre :
- `patch-notes-writer` → entrée joueur dans `assets/data/patch_notes.json` + `pubspec.yaml`
- `memory-bank-sync` → `.obsidian_vault/_memory_bank/`, ADR de conception, et coche de **P-02** dans `docs/ROADMAP.md`
