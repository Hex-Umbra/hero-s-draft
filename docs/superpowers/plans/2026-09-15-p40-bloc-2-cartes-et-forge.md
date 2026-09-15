# P-40 bloc 2 — Trois bugs de cartes et de forge : plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** corriger la capacité de forge des cartes de classe, la fusion des légendaires, la duplication des cartes `unique` et la rune Persistant, en supprimant les trois causes racines plutôt que leurs symptômes.

**Architecture :** l'échelle de rareté et la règle d'acquisition deviennent des accesseurs de `CardRarity` (modèle pur), la règle d'épuisement un accesseur de `CardInstance`, et le caractère cumulable d'une rune une clé de donnée lue par un unique service de combinaison, `ForgeRuneRules`. Chaque site qui recalculait l'une de ces règles la lit désormais.

**Tech Stack :** Flutter, Dart 3.11 (switch expressions, patterns `||`), Riverpod 2 (`Notifier`), `flutter_test`.

**Spec :** [`docs/superpowers/specs/2026-09-15-p40-bloc-2-cartes-et-forge-design.md`](../specs/2026-09-15-p40-bloc-2-cartes-et-forge-design.md)

## Global Constraints

- Branche `fix/p40-bloc-2`. Référence de départ : **773 tests au vert** (mesuré le 2026-09-15, après suppression d'un dossier de classe vide laissé par l'éditeur).
- `dart analyze` à **zéro problème** après chaque tâche (`CLAUDE.md`). Ne jamais lancer `dart format`.
- Toute clé ajoutée à un `fromJson` de `lib/models/data/` s'ajoute aussi au gabarit de l'éditeur et à la table de `test/unit/content_editor/entity_descriptor_test.dart`.
- Aucun code mort, aucun import inutilisé, aucun bloc commenté.
- Messages de commit en français **sans accents**, préfixe conventionnel à portée (`fix(forge): ...`), comme l'historique.
- Aucune migration de sauvegarde, `schemaVersion` inchangé.

---

### Task 1 : l'échelle de rareté devient explicite (B4, B5)

**Files :**
- Modify : `lib/models/data/card_data.dart` (enum `CardRarity`, `CardData.forgeCapacityAt`)
- Modify : `lib/models/card_instance.dart` (`forgeCapacity`)
- Modify : `lib/game/controllers/deck_controller.dart:288-331` (`mergeCards`), `:341-352` (suppression de `upgradeCard`)
- Modify : `lib/ui/screens/deck_screen.dart:1, 106, 172-179, 222-226`
- Modify : `lib/ui/widgets/forge_upgrade_dialog.dart:50-52`
- Modify : `lib/ui/screens/rest_card_selection_screen.dart:30-34`
- Modify : `lib/game/controllers/shop_controller.dart:204-205`
- Modify : `lib/game/components/widgets/card_text_renderer.dart:514-516`
- Modify : `lib/ui/widgets/ui_card.dart`, `lib/ui/widgets/ui_card/card_rune_sockets.dart`, `lib/ui/widgets/ui_card/ui_card_helpers.dart:215-246`
- Modify : `lib/tutorial/tutorial_engine.dart:400-405`
- Test : `test/unit/card_rarity_test.dart` (création), `test/unit/deck_controller_test.dart`, `test/unit/decoupled_forge_test.dart:49-70`, `test/widget/deck_screen_test.dart`, `test/widget/ui_card_rune_sockets_test.dart` (création)

**Interfaces :**
- Produces : `CardRarity? CardRarity.next` · `int CardRarity.forgeSlotBonus` · `int CardData.forgeCapacityAt(CardRarity rarity)` · `int CardInstance.forgeCapacity` · `UiCard({int forgeCapacity = 1, ...})` · `CardRuneSockets({required List<String> forgeUpgrades, required int totalSlots})`

- [ ] **Step 1 : écrire les tests du modèle**

Créer `test/unit/card_rarity_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

CardData _cardData({
  CardRarity rarity = CardRarity.common,
  int baseMaxForgeUpgrades = 1,
}) =>
    CardData(
      id: 'test_card',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: rarity,
      target: CardTarget.singleEnemy,
      effects: const [],
      baseMaxForgeUpgrades: baseMaxForgeUpgrades,
    );

void main() {
  group('CardRarity.next', () {
    test('chaque rarete de l echelle mene a la suivante', () {
      expect(CardRarity.common.next, CardRarity.uncommon);
      expect(CardRarity.uncommon.next, CardRarity.rare);
      expect(CardRarity.rare.next, CardRarity.epic);
      expect(CardRarity.epic.next, CardRarity.legendary);
    });

    test('legendaire est le sommet de l echelle', () {
      expect(CardRarity.legendary.next, isNull);
    });

    test('unique est hors de l echelle, bien que declaree apres legendaire', () {
      expect(CardRarity.unique.next, isNull);
    });
  });

  group('Capacite de forge', () {
    test('une carte globale gagne un emplacement par palier de rarete', () {
      final data = _cardData();
      expect(
        [for (final rarity in CardRarity.values.take(5)) data.forgeCapacityAt(rarity)],
        [1, 2, 3, 4, 5],
      );
    });

    test('une carte de classe garde sa capacite fixe de 5 (ADR-026)', () {
      final data = _cardData(rarity: CardRarity.unique, baseMaxForgeUpgrades: 5);
      expect(CardInstance(data: data).forgeCapacity, 5);
    });

    test('forgeCapacity lit la rarete de l instance, pas celle du modele', () {
      final data = _cardData(baseMaxForgeUpgrades: 2);
      expect(CardInstance(data: data, rarity: CardRarity.epic).forgeCapacity, 5);
    });
  });
}
```

- [ ] **Step 2 : écrire les tests de comportement**

Dans `test/unit/deck_controller_test.dart`, à la fin du groupe `'DeckNotifier Tests'` (après le test `'mergeCards limits upgrades to the capacity of the next rarity level'`) :

```dart
    test('mergeCards refuse trois legendaires : aucune rarete au-dela', () {
      final copies = List.generate(
        3,
        (_) => CardInstance(data: _card('strike').data, rarity: CardRarity.legendary),
      );
      notifier.initializeStarterDeck(copies);

      notifier.mergeCards(copies.map((c) => c.uniqueId).toList(), const []);

      expect(notifier.state.masterDeck, hasLength(3));
      expect(
        notifier.state.masterDeck.map((c) => c.rarity).toSet(),
        {CardRarity.legendary},
      );
    });
```

Dans `test/widget/deck_screen_test.dart`, à la fin de `main()` :

```dart
  testWidgets(
    'DeckScreen ne propose aucune fusion pour trois legendaires',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      for (var i = 0; i < 3; i++) {
        deckNotifier.addCardToMasterDeck(
          CardInstance(data: strikeCard, rarity: CardRarity.legendary),
        );
      }

      await tester.pumpWidget(buildApp(container, allowMerge: true));
      await tester.pumpAndSettle();

      expect(find.text('FUSIONNER (3)'), findsNothing);
      expect(find.text('Fusion possible'), findsNothing);
    },
  );
```

Créer `test/widget/ui_card_rune_sockets_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_rune_sockets.dart';

Future<void> _pumpCard(WidgetTester tester, CardInstance card) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 140,
            height: 196,
            child: Builder(
              builder: (context) => UiCard.fromInstance(
                card: card,
                locale: 'fr',
                l10n: AppLocalizations.of(context)!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Chaque emplacement, vide ou garni, est un `Container` enfant direct du
/// `Wrap` de `CardRuneSockets`.
int _socketCount(WidgetTester tester) => tester
    .widgetList(
      find.descendant(
        of: find.byType(CardRuneSockets),
        matching: find.byType(Container),
      ),
    )
    .length;

CardData _cardData(CardRarity rarity, int baseMaxForgeUpgrades) => CardData(
      id: 'holy_shield',
      nameEn: 'Holy Shield',
      nameFr: 'Bouclier Sacre',
      descriptionEn: 'Gain armor',
      descriptionFr: 'Gagne de l armure',
      cost: 1,
      type: CardType.skill,
      category: CardCategory.global,
      rarity: rarity,
      target: CardTarget.self,
      effects: const [],
      baseMaxForgeUpgrades: baseMaxForgeUpgrades,
    );

void main() {
  testWidgets('une carte de classe affiche 5 emplacements de rune, pas 10', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, CardInstance(data: _cardData(CardRarity.unique, 5)));

    expect(_socketCount(tester), 5);
  });

  testWidgets('une carte globale legendaire affiche 5 emplacements', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      CardInstance(data: _cardData(CardRarity.common, 1), rarity: CardRarity.legendary),
    );

    expect(_socketCount(tester), 5);
  });
}
```

- [ ] **Step 3 : lancer les tests, vérifier qu'ils échouent**

Run : `flutter test test/unit/card_rarity_test.dart test/unit/deck_controller_test.dart test/widget/deck_screen_test.dart test/widget/ui_card_rune_sockets_test.dart`
Expected : `card_rarity_test` ne compile pas (`next`, `forgeCapacityAt`, `forgeCapacity` inconnus) ; `mergeCards refuse trois legendaires` échoue (`hasLength(3)`, 1 carte `unique` obtenue) ; `DeckScreen ne propose aucune fusion` échoue (`FUSIONNER (3)` trouvé) ; `une carte de classe affiche 5 emplacements` échoue (10 trouvés).

- [ ] **Step 4 : l'échelle sur l'enum et la capacité sur les modèles**

`lib/models/data/card_data.dart`, remplacer `enum CardRarity { common, uncommon, rare, epic, legendary, unique }` par :

```dart
enum CardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  unique;

  /// Rareté que produit une fusion 3→1 de cartes de cette rareté.
  ///
  /// `null` au sommet de l'échelle (`legendary`) comme hors d'elle (`unique`,
  /// qui ne fusionne jamais — ADR-026). Ne jamais la dériver de `index` :
  /// `unique` est déclarée après `legendary` sans lui succéder.
  CardRarity? get next => switch (this) {
        CardRarity.common => CardRarity.uncommon,
        CardRarity.uncommon => CardRarity.rare,
        CardRarity.rare => CardRarity.epic,
        CardRarity.epic => CardRarity.legendary,
        CardRarity.legendary || CardRarity.unique => null,
      };

  /// Emplacements de rune que cette rareté ajoute à `baseMaxForgeUpgrades`.
  ///
  /// Nul pour `unique` : une carte de classe a une capacité fixe (ADR-026).
  int get forgeSlotBonus => switch (this) {
        CardRarity.common || CardRarity.unique => 0,
        CardRarity.uncommon => 1,
        CardRarity.rare => 2,
        CardRarity.epic => 3,
        CardRarity.legendary => 4,
      };
}
```

Toujours dans `card_data.dart`, sous `getDescription` :

```dart
  /// Nombre de runes de forge qu'une carte de ce modèle porte à [rarity].
  int forgeCapacityAt(CardRarity rarity) =>
      baseMaxForgeUpgrades + rarity.forgeSlotBonus;
```

`lib/models/card_instance.dart`, sous `int get currentCost => data.cost;` :

```dart
  /// Nombre de runes de forge que cette carte peut porter.
  int get forgeCapacity => data.forgeCapacityAt(rarity);
```

- [ ] **Step 5 : la fusion 3→1 lit l'échelle**

`lib/game/controllers/deck_controller.dart`, dans `mergeCards`, remplacer :

```dart
    if (selectedCards.length == 3) {
      if (selectedCards.any((c) => c.rarity == CardRarity.unique)) {
        return;
      }
      final baseCardData = selectedCards[0].data;
      final rarity = selectedCards[0].rarity;

      // Retire les 3 exemplaires
      currentMasterDeck.removeWhere((c) => selectedIds.contains(c.uniqueId));

      // Détermine la rareté suivante
      final nextRarityIndex = min(rarity.index + 1, CardRarity.values.length - 1);
      final nextRarity = CardRarity.values[nextRarityIndex];
```

par :

```dart
    if (selectedCards.length == 3) {
      // Une carte `unique` ou légendaire n'a pas de rareté au-delà.
      final nextRarity = selectedCards[0].rarity.next;
      if (nextRarity == null || selectedCards.any((c) => c.rarity.next == null)) {
        return;
      }
      final baseCardData = selectedCards[0].data;

      // Retire les 3 exemplaires
      currentMasterDeck.removeWhere((c) => selectedIds.contains(c.uniqueId));
```

puis remplacer `final capacity = baseCardData.baseMaxForgeUpgrades + nextRarityIndex;` par `final capacity = baseCardData.forgeCapacityAt(nextRarity);`.

Supprimer la méthode `upgradeCard` entière (commentaire `/// Améliore une carte définitivement (Forge) en augmentant sa rareté` compris) : elle n'a aucun appelant dans `lib/` ni `test/`, et porte le même calcul. `import 'dart:math';` reste, pour `Random`.

- [ ] **Step 6 : l'écran de deck lit l'échelle**

`lib/ui/screens/deck_screen.dart` :
- ligne 106, `if (card.rarity == CardRarity.unique)` devient `if (card.rarity.next == null)` ;
- dans `_confirmMerge`, remplacer :

```dart
    if (merged == true) {
      if (context.mounted) {
        final nextRarityIndex =
            min(card.rarity.index + 1, CardRarity.values.length - 1);
        context.showNotification(
          l10n.deckMergeSuccess(cardName, nextRarityIndex + 1),
          type: NotificationType.success,
        );
      }
    }
```

par :

```dart
    final nextRarity = card.rarity.next;
    if (merged == true && nextRarity != null) {
      if (context.mounted) {
        context.showNotification(
          l10n.deckMergeSuccess(cardName, nextRarity.index + 1),
          type: NotificationType.success,
        );
      }
    }
```

- dans `_proceedToUpgrades`, remplacer :

```dart
    final nextRarityIndex =
        min(firstCard.rarity.index + 1, CardRarity.values.length - 1);
    _capacity = firstCard.data.baseMaxForgeUpgrades + nextRarityIndex;
```

par :

```dart
    final nextRarity = firstCard.rarity.next;
    if (nextRarity == null) return;
    _capacity = firstCard.data.forgeCapacityAt(nextRarity);
```

- supprimer `import 'dart:math';` (plus aucun `min`).

- [ ] **Step 7 : les cinq autres lectures de capacité**

`lib/ui/widgets/forge_upgrade_dialog.dart`, remplacer :

```dart
    final rarityIndex = widget.card.rarity.index;
    _totalMaxForgeUpgrades =
        widget.card.data.baseMaxForgeUpgrades + rarityIndex;
```

par `_totalMaxForgeUpgrades = widget.card.forgeCapacity;`.

`lib/ui/screens/rest_card_selection_screen.dart`, remplacer les trois lignes `rarityIndex` / `totalMaxForgeUpgrades` et la ligne blanche qui suit par rien, et la condition par `if (card.forgeUpgrades.length >= card.forgeCapacity) {`.

`lib/game/controllers/shop_controller.dart`, remplacer :

```dart
    final int rarityIndex = CardRarity.values.indexOf(finalRarity);
    final int maxUpgrades = data.baseMaxForgeUpgrades + rarityIndex;
```

par `final int maxUpgrades = data.forgeCapacityAt(finalRarity);`.

`lib/game/components/widgets/card_text_renderer.dart`, remplacer :

```dart
    final int baseMaxForgeUpgrades = card.card.data.baseMaxForgeUpgrades;
    final int rarityIndex = card.card.rarity.index;
    final int totalSlots = baseMaxForgeUpgrades + rarityIndex;
```

par `final int totalSlots = card.card.forgeCapacity;`.

`lib/tutorial/tutorial_engine.dart`, dans `mergeCards`, remplacer :

```dart
    final nextIndex = (base.rarity.index + 1).clamp(0, CardRarity.values.length - 1);
    mockState.hand = [
      CardInstance(data: base.data, rarity: CardRarity.values[nextIndex]),
    ];
```

par :

```dart
    mockState.hand = [
      CardInstance(data: base.data, rarity: base.rarity.next ?? base.rarity),
    ];
```

- [ ] **Step 8 : `UiCard` reçoit la capacité au lieu de la recalculer depuis un libellé**

`lib/ui/widgets/ui_card/card_rune_sockets.dart` : remplacer les champs `baseMaxForgeUpgrades` et `rarityIndex` par `final int totalSlots;` (constructeur : `required this.totalSlots,`) et supprimer la ligne `final totalSlots = baseMaxForgeUpgrades + rarityIndex;` de `build`.

`lib/ui/widgets/ui_card.dart` :
- champ `final int baseMaxForgeUpgrades;` → `final int forgeCapacity;` ; constructeur `this.baseMaxForgeUpgrades = 1,` → `this.forgeCapacity = 1,` ;
- `UiCard.fromInstance` : `baseMaxForgeUpgrades: card.data.baseMaxForgeUpgrades,` → `forgeCapacity: card.forgeCapacity,` ;
- `UiCard.fromData` : `baseMaxForgeUpgrades: card.baseMaxForgeUpgrades,` → `forgeCapacity: card.forgeCapacityAt(card.rarity),` ;
- dans `build`, supprimer `final rarityIndex = getCardRarityIndex(context, rarity);` ;
- l'appel devient `CardRuneSockets(forgeUpgrades: forgeUpgrades, totalSlots: forgeCapacity)`.

`lib/ui/widgets/ui_card/ui_card_helpers.dart` : supprimer `getCardRarityIndex` entière, désormais sans appelant.

`test/unit/decoupled_forge_test.dart`, dans `'Capacity limit calculation works as expected based on rarity'`, remplacer les deux calculs recopiés par la lecture de production :

```dart
      // Common card capacity = 2 + 0 = 2
      final commonInstance = CardInstance(data: baseCard, rarity: CardRarity.common);
      expect(commonInstance.forgeCapacity, 2);

      // Epic card capacity = 2 + 3 = 5
      final epicInstance = CardInstance(data: baseCard, rarity: CardRarity.epic);
      expect(epicInstance.forgeCapacity, 5);
```

- [ ] **Step 9 : lancer les tests, vérifier qu'ils passent**

Run : `flutter test test/unit/card_rarity_test.dart test/unit/deck_controller_test.dart test/unit/decoupled_forge_test.dart test/widget/deck_screen_test.dart test/widget/ui_card_rune_sockets_test.dart test/tutorial` puis `dart analyze`
Expected : tout passe ; `No issues found!`. Contrôle : `grep -rn "rarity.index + 1\|rarityIndex\|CardRarity.values.length" lib` ne rend rien.

- [ ] **Step 10 : commit**

```bash
git add lib test
git commit -m "fix(forge): capacite fixe des cartes de classe et fusion des legendaires refusee"
```

---

### Task 2 : une carte `unique` n'est plus copiée (B2)

**Files :**
- Modify : `lib/models/data/card_data.dart` (`CardRarity.isAcquirable`)
- Modify : `lib/game/controllers/deck_controller.dart` (`DeckState.copyableCards`)
- Modify : `lib/game/controllers/reward_controller.dart:170-191`
- Modify : `lib/game/controllers/shop_controller.dart:44-50`
- Modify : `lib/ui/screens/shop_screen.dart:208-216`
- Modify : `lib/ui/screens/draft_screen.dart:563-570`
- Test : `test/unit/card_rarity_test.dart`, `test/unit/deck_controller_test.dart`, `test/unit/reward_controller_test.dart`, `test/widget/shop_screen_test.dart`, `test/widget/draft_screen_test.dart`

**Interfaces :**
- Consumes : rien de la tâche 1.
- Produces : `bool CardRarity.isAcquirable` · `List<CardInstance> DeckState.copyableCards` (liste neuve à chaque appel, mélangeable sans toucher l'état)

- [ ] **Step 1 : écrire les tests**

`test/unit/card_rarity_test.dart`, nouveau groupe :

```dart
  group('CardRarity.isAcquirable', () {
    test('une carte de classe n entre dans le deck qu au draft de depart', () {
      expect(CardRarity.unique.isAcquirable, isFalse);
    });

    test('toute rarete de l echelle s acquiert en cours de run', () {
      for (final rarity in CardRarity.values.take(5)) {
        expect(rarity.isAcquirable, isTrue, reason: rarity.name);
      }
    });
  });
```

`test/unit/deck_controller_test.dart`, à la fin du groupe `'DeckNotifier Tests'` :

```dart
    test('copyableCards ecarte les cartes unique du master deck', () {
      final strike = _card('strike');
      final signature = CardInstance(
        data: const CardData(
          id: 'holy_shield',
          cost: 1,
          type: CardType.skill,
          category: CardCategory.characterSpecific,
          rarity: CardRarity.unique,
          target: CardTarget.self,
          effects: [],
        ),
      );

      expect(DeckState(masterDeck: [strike, signature]).copyableCards, [strike]);
    });
```

`test/unit/reward_controller_test.dart`, après `'handleVictory rolls up to 5 cards from the master deck only when bossRewardType is cards'` :

```dart
    test('handleVictory ne propose jamais de carte unique au draft de boss', () {
      deckNotifier.addCardToMasterDeck(CardInstance(data: allCards[0]));
      deckNotifier.addCardToMasterDeck(CardInstance(data: allCards[2]));

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(bossRewardType: BossRewardType.cards),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );

      expect(
        rewardController.state.rolledCards.map((c) => c.data.id),
        ['c_normal'],
      );
    });
```

`test/widget/shop_screen_test.dart` : ajouter sous `mockCards` une carte de classe,

```dart
  const signatureCard = CardData(
    id: 'holy_shield',
    nameEn: 'Holy Shield',
    nameFr: 'Bouclier Sacre',
    descriptionEn: 'Gain armor',
    descriptionFr: 'Gagne de l armure',
    cost: 1,
    type: CardType.skill,
    category: CardCategory.characterSpecific,
    heroClass: 'paladin',
    rarity: CardRarity.unique,
    target: CardTarget.self,
    effects: [],
  );
```

et à la fin de `main()` :

```dart
  testWidgets(
    'Le Miroir Magique ne propose jamais de copier une carte unique',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
      );
      addTearDown(container.dispose);

      container.read(runProvider.notifier).startNewRun(mockHero);
      container.read(inventoryProvider.notifier).reset(initialGold: 200);

      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.addCardToMasterDeck(CardInstance(data: mockCards[0]));
      deckNotifier.addCardToMasterDeck(CardInstance(data: signatureCard));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', ''), Locale('fr', '')],
            locale: const Locale('fr', ''),
            home: const Scaffold(body: ShopScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Miroir Magique'));
      await tester.pumpAndSettle();

      expect(
        container.read(shopProvider).cloneOptions.map((c) => c.data.id),
        ['strike'],
      );

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );
```

`test/widget/draft_screen_test.dart` : importer `game/controllers/deck_controller.dart`, `models/card_instance.dart` et `models/data/card_data.dart`, puis à la fin de `main()` :

```dart
  testWidgets(
    'Le Miroir de montee de niveau ne propose jamais de copier une carte unique',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.addCardToMasterDeck(
        CardInstance(
          data: const CardData(
            id: 'strike',
            nameEn: 'Strike',
            nameFr: 'Frappe',
            cost: 1,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [],
          ),
        ),
      );
      deckNotifier.addCardToMasterDeck(
        CardInstance(
          data: const CardData(
            id: 'holy_shield',
            nameEn: 'Holy Shield',
            nameFr: 'Bouclier Sacre',
            cost: 1,
            type: CardType.skill,
            category: CardCategory.characterSpecific,
            heroClass: 'paladin',
            rarity: CardRarity.unique,
            target: CardTarget.self,
            effects: [],
          ),
        ),
      );

      // forceLegendary rend le Miroir certain (voir le test precedent).
      await tester.pumpWidget(
        _wrap(
          container,
          DraftScreen(onDraftComplete: () {}, forceLegendary: true),
        ),
      );
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 13000));

      await tester.tap(find.text('Miroir'));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 800));

      expect(find.text('Frappe'), findsOneWidget);
      expect(find.text('Bouclier Sacre'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run : `flutter test test/unit/card_rarity_test.dart test/unit/deck_controller_test.dart test/unit/reward_controller_test.dart test/widget/shop_screen_test.dart test/widget/draft_screen_test.dart`
Expected : `isAcquirable` et `copyableCards` inconnus à la compilation. Une fois ces deux accesseurs posés (Step 3), les trois tests de source échouent encore : `['c_normal']` attendu contre deux cartes, `['strike']` contre deux options, `Bouclier Sacre` trouvé.

- [ ] **Step 3 : la règle sur l'enum et la liste sur l'état du deck**

`lib/models/data/card_data.dart`, dans l'enum `CardRarity`, après `forgeSlotBonus` :

```dart

  /// Une carte de cette rareté peut-elle entrer dans le deck en cours de run :
  /// achat, récompense, copie par un Miroir ? Une carte `unique` n'y entre
  /// qu'au draft de départ (ADR-026, ADR-051).
  bool get isAcquirable => this != CardRarity.unique;
```

`lib/game/controllers/deck_controller.dart`, dans `DeckState`, sous `copyWith` :

```dart
  /// Cartes du master deck qu'une récompense peut copier : draft de boss,
  /// Miroir Magique, Miroir de montée de niveau.
  List<CardInstance> get copyableCards =>
      masterDeck.where((card) => card.rarity.isAcquirable).toList();
```

- [ ] **Step 4 : les cinq sources lisent la règle**

`lib/game/controllers/reward_controller.dart`, remplacer :

```dart
      final playerDeck = ref.read(deckProvider).masterDeck;
      if (playerDeck.isNotEmpty) {
        final random = Random();
        final List<CardInstance> candidates = List<CardInstance>.from(playerDeck);
        candidates.shuffle(random);
```

par :

```dart
      final candidates = ref.read(deckProvider).copyableCards;
      if (candidates.isNotEmpty) {
        final random = Random();
        candidates.shuffle(random);
```

et, pour la carte bonus, `c.rarity != CardRarity.unique` par `c.rarity.isAcquirable`.

`lib/game/controllers/shop_controller.dart`, dans `_getEligibleCards`, `c.rarity != CardRarity.unique` devient `c.rarity.isAcquirable`.

`lib/ui/screens/shop_screen.dart`, dans `_showCloneModal`, remplacer :

```dart
      final deckState = ref.read(deckProvider);
      final masterDeck = List.of(deckState.masterDeck);
      masterDeck.shuffle();
      options = masterDeck.take(3).toList();
```

par :

```dart
      final copyableCards = ref.read(deckProvider).copyableCards;
      copyableCards.shuffle();
      options = copyableCards.take(3).toList();
```

`lib/ui/screens/draft_screen.dart`, dans `_showCloneModal`, remplacer :

```dart
    final deckState = ref.read(deckProvider);
    final masterDeck = List.of(deckState.masterDeck);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    masterDeck.shuffle();
    final options = masterDeck.take(3).toList();
```

par :

```dart
    final copyableCards = ref.read(deckProvider).copyableCards;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    copyableCards.shuffle();
    final options = copyableCards.take(3).toList();
```

- [ ] **Step 5 : lancer les tests, vérifier qu'ils passent**

Run : même commande qu'au Step 2, puis `dart analyze`
Expected : tout passe ; `No issues found!`. Contrôle : `grep -rn "CardRarity.unique" lib/game/controllers/reward_controller.dart lib/ui/screens/shop_screen.dart lib/ui/screens/draft_screen.dart` ne rend rien ; `shop_controller.dart` garde les siens, étrangers à l'acquisition (prix, `_rollRarity`).

- [ ] **Step 6 : commit**

```bash
git add lib test
git commit -m "fix(cartes): une carte unique n est plus copiee par le draft de boss ni les miroirs"
```

---

### Task 3 : Persistant retire l'épuisement à tout tier (B1, cœur)

**Files :**
- Modify : `lib/models/card_instance.dart` (`exhaustsOnPlay`)
- Modify : `lib/game/controllers/deck_controller.dart:242-260` (`playCard`)
- Test : `test/unit/deck_controller_test.dart`

**Interfaces :**
- Produces : `bool CardInstance.exhaustsOnPlay`

- [ ] **Step 1 : écrire les tests**

`test/unit/deck_controller_test.dart`, nouveau groupe à la fin de `main()` :

```dart
  group('DeckNotifier.playCard — epuisement', () {
    late ProviderContainer container;
    late DeckNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(deckProvider.notifier);
    });

    tearDown(() => container.dispose());

    CardInstance cardWith({
      CardType type = CardType.skill,
      bool isExhaust = true,
      List<String> runes = const [],
    }) =>
        CardInstance(
          data: CardData(
            id: 'heal_potion',
            cost: 1,
            type: type,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.self,
            isExhaust: isExhaust,
            effects: const [],
          ),
          forgeUpgrades: runes,
        );

    void play(CardInstance card) {
      notifier.state = notifier.state.copyWith(hand: [card]);
      notifier.playCard(card);
    }

    test('une carte isExhaust sans rune est epuisee', () {
      final card = cardWith();
      play(card);
      expect(notifier.state.exhaustPile, [card]);
      expect(notifier.state.discardPile, isEmpty);
    });

    test('Persistant au tier 1 envoie la carte en defausse', () {
      final card = cardWith(runes: const ['enduring:1']);
      play(card);
      expect(notifier.state.discardPile, [card]);
      expect(notifier.state.exhaustPile, isEmpty);
    });

    test('Persistant au tier 2 envoie aussi la carte en defausse', () {
      final card = cardWith(runes: const ['sharp:1', 'enduring:2']);
      play(card);
      expect(notifier.state.discardPile, [card]);
      expect(notifier.state.exhaustPile, isEmpty);
    });

    test('un pouvoir est epuise meme s il porte Persistant', () {
      final card = cardWith(type: CardType.power, isExhaust: false, runes: const ['enduring:1']);
      play(card);
      expect(notifier.state.exhaustPile, [card]);
    });
  });
```

- [ ] **Step 2 : lancer les tests, vérifier qu'ils échouent**

Run : `flutter test test/unit/deck_controller_test.dart`
Expected : seul `Persistant au tier 2 envoie aussi la carte en defausse` échoue (carte trouvée en `exhaustPile`) — les trois autres épinglent le comportement actuel.

- [ ] **Step 3 : une seule règle d'épuisement**

`lib/models/card_instance.dart`, sous `forgeCapacity` :

```dart
  /// La carte est-elle épuisée une fois jouée ? Un pouvoir l'est toujours ;
  /// une carte `isExhaust` l'est sauf si elle porte la rune `enduring`,
  /// **quel que soit son tier** : la fusion de runes et la fusion 3→1 en ont
  /// produit des tiers supérieurs, qu'une sauvegarde peut encore contenir.
  bool get exhaustsOnPlay =>
      data.type == CardType.power ||
      (data.isExhaust &&
          !forgeUpgrades.any((rune) => rune.split(':').first == 'enduring'));
```

`lib/game/controllers/deck_controller.dart`, dans `playCard`, remplacer :

```dart
      final isExhausted = cardToPlay.data.isExhaust && !cardToPlay.forgeUpgrades.contains('enduring:1');

      if (cardToPlay.data.type == CardType.power || isExhausted) {
```

par :

```dart
      if (cardToPlay.exhaustsOnPlay) {
```

et le commentaire de la méthode par `/// Joue une carte : la retire de la main et l'envoie dans la défausse, ou l'épuise (voir `CardInstance.exhaustsOnPlay`)`.

- [ ] **Step 4 : lancer les tests, vérifier qu'ils passent**

Run : `flutter test test/unit/deck_controller_test.dart test/unit/combat_controller_test.dart` puis `dart analyze`
Expected : tout passe ; `No issues found!`.

- [ ] **Step 5 : commit**

```bash
git add lib test
git commit -m "fix(forge): la rune Persistant retire l epuisement a tout tier"
```

---

### Task 4 : une rune se déclare non cumulable, et les fusions le respectent (B1, règle)

**Files :**
- Modify : `lib/models/data/forge_upgrade_data.dart` (champ `stackable`)
- Modify : `assets/data/forge_upgrades/enduring.json`
- Modify : `lib/services/content_editor/entity_descriptor.dart:304-313` (gabarit)
- Create : `lib/game/services/forge_rune_rules.dart`
- Modify : `lib/game/controllers/deck_controller.dart:302-313` (`mergeCards`)
- Modify : `lib/ui/screens/deck_screen.dart:228-245` (`_proceedToUpgrades`)
- Modify : `lib/ui/screens/forge_fusion_screen.dart:18-68` et les cinq appels de `_getFusionsForCard`
- Test : `test/unit/forge_rune_rules_test.dart` (création), `test/unit/decoupled_forge_test.dart`, `test/widget/forge_fusion_screen_test.dart`, `test/unit/content_editor/entity_descriptor_test.dart:218-227`, `test/unit/real_bundle_load_test.dart:95`

**Interfaces :**
- Produces : `bool ForgeUpgradeData.stackable` (clé JSON `stackable`, défaut `true`) · `class FusionOption` (déplacée, champs inchangés) · `ForgeRuneRules.isStackable(String runeId) → bool` · `ForgeRuneRules.consolidate(Iterable<String> runes) → List<String>` · `ForgeRuneRules.fusionOptionsFor(CardInstance card) → List<FusionOption>`

- [ ] **Step 1 : écrire les tests unitaires**

Créer `test/unit/forge_rune_rules_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

ForgeUpgradeData _rune(String id, {bool stackable = true}) => ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      pools: const ['common'],
      stackable: stackable,
    );

CardInstance _cardWith(List<String> runes) => CardInstance(
      data: const CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      ),
      forgeUpgrades: runes,
    );

void main() {
  setUp(() {
    // Construire le registre renseigne `GameDataRegistry.instance`, que lit
    // `ForgeUpgradeData.getById`.
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: [
        _rune('sharp'),
        _rune('hardened'),
        _rune('enduring', stackable: false),
      ],
    );
  });

  group('ForgeUpgradeData.stackable', () {
    test('une rune est cumulable par defaut', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'sharp',
        'pools': ['common'],
      });
      expect(rune.stackable, isTrue);
    });

    test('le JSON declare une rune non cumulable, et toJson la conserve', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'enduring',
        'pools': ['rare'],
        'stackable': false,
      });
      expect(rune.stackable, isFalse);
      expect(ForgeUpgradeData.fromJson(rune.toJson()).stackable, isFalse);
    });
  });

  group('ForgeRuneRules.consolidate', () {
    test('additionne les tiers des runes cumulables de meme id', () {
      expect(
        ForgeRuneRules.consolidate(['sharp:1', 'hardened:1', 'sharp:2']),
        ['sharp:3', 'hardened:1'],
      );
    });

    test('garde une rune non cumulable une seule fois, au tier 1', () {
      expect(
        ForgeRuneRules.consolidate(['enduring:1', 'sharp:1', 'enduring:1']),
        ['enduring:1', 'sharp:1'],
      );
    });

    test('ramene au tier 1 une rune non cumulable deja montee', () {
      expect(ForgeRuneRules.consolidate(['enduring:3']), ['enduring:1']);
    });

    test('traite une rune absente du registre comme cumulable', () {
      expect(ForgeRuneRules.consolidate(['legacy:1', 'legacy:1']), ['legacy:2']);
    });

    test('ignore une reference mal formee ou de tier nul', () {
      expect(
        ForgeRuneRules.consolidate(['sharp', 'sharp:0', 'sharp:x', 'hardened:2']),
        ['hardened:2'],
      );
    });
  });

  group('ForgeRuneRules.fusionOptionsFor', () {
    test('une fusion par rune cumulable portee au moins deux fois', () {
      final options = ForgeRuneRules.fusionOptionsFor(
        _cardWith(['sharp:1', 'sharp:2', 'hardened:1']),
      );

      expect(options, hasLength(1));
      expect(options.single.upgradeId, 'sharp');
      expect(options.single.originalUpgrades, ['sharp:1', 'sharp:2']);
      expect(options.single.totalTier, 3);
      expect(options.single.cost, 80);
    });

    test('jamais de fusion pour une rune non cumulable', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['enduring:1', 'enduring:1'])),
        isEmpty,
      );
    });
  });
}
```

- [ ] **Step 2 : écrire les tests de comportement**

`test/unit/decoupled_forge_test.dart` : ajouter au registre du `setUp` une troisième amélioration,

```dart
          const ForgeUpgradeData(
            id: 'enduring',
            nameEn: 'Enduring',
            nameFr: 'Persistant',
            descriptionEn: 'Removes Exhaust',
            descriptionFr: 'Retire Épuisement',
            icon: 'hourglass_bottom_rounded',
            color: 'greenAccent',
            pools: ['rare'],
            requiresExhaust: true,
            stackable: false,
          ),
```

et à la fin du groupe :

```dart
    test('mergeCards garde une seule rune non cumulable, au tier 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cardData = CardData(
        id: 'heal_potion',
        cost: 1,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        isExhaust: true,
        effects: [],
      );
      final copies = List.generate(
        3,
        (_) => CardInstance(data: cardData, forgeUpgrades: ['enduring:1']),
      );
      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.initializeStarterDeck(copies);

      deckNotifier.mergeCards(
        copies.map((c) => c.uniqueId).toList(),
        ['enduring:1', 'enduring:1', 'enduring:1'],
      );

      expect(
        container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['enduring:1'],
      );
    });
```

`test/widget/forge_fusion_screen_test.dart` : sous `sharpUpgrade`,

```dart
  const enduringUpgrade = ForgeUpgradeData(
    id: 'enduring',
    nameEn: 'Enduring',
    nameFr: 'Persistant',
    descriptionEn: 'Removes Exhaust',
    descriptionFr: 'Retire Épuisement',
    icon: 'hourglass_bottom_rounded',
    color: 'greenAccent',
    pools: ['rare'],
    requiresExhaust: true,
    stackable: false,
  );
```

`forgeUpgrades: const [sharpUpgrade]` devient `forgeUpgrades: const [sharpUpgrade, enduringUpgrade]`, et à la fin de `main()` :

```dart
  testWidgets(
    'une rune non cumulable portee deux fois ne rend pas la carte eligible',
    (WidgetTester tester) async {
      final card = CardInstance(
        data: strikeCard,
        forgeUpgrades: const ['enduring:1', 'enduring:1'],
      );

      await pumpForgeFusionScreen(tester, masterDeck: [card]);

      expect(
        find.text('No cards in your deck have identical runes to merge.'),
        findsOneWidget,
      );
    },
  );
```

`test/unit/real_bundle_load_test.dart`, sous `expect(registry.forgeUpgrades, hasLength(8));` :

```dart
    expect(
      registry.forgeUpgrades.where((u) => !u.stackable).map((u) => u.id),
      ['enduring'],
    );
```

`test/unit/content_editor/entity_descriptor_test.dart`, dans l'ensemble attendu d'`EntityCategory.forgeUpgrade`, ajouter `'stackable',` après `'requiresExhaust',`.

- [ ] **Step 3 : lancer les tests, vérifier qu'ils échouent**

Run : `flutter test test/unit/forge_rune_rules_test.dart test/unit/decoupled_forge_test.dart test/widget/forge_fusion_screen_test.dart test/unit/real_bundle_load_test.dart test/unit/content_editor/entity_descriptor_test.dart`
Expected : échec de compilation (`stackable`, `ForgeRuneRules` inconnus). Une fois le champ posé (Step 4), échouent encore : `mergeCards garde une seule rune non cumulable` (`enduring:3`), `une rune non cumulable portee deux fois` (carte listée), le chargement réel (`enduring.json` sans la clé), le gabarit (clé manquante).

- [ ] **Step 4 : le champ en donnée**

`lib/models/data/forge_upgrade_data.dart` :
- sous `final bool requiresExhaust;` :

```dart
  /// Une rune cumulable additionne ses tiers : deux `sharp:1` valent un
  /// `sharp:2`. Une rune non cumulable est binaire — `enduring` retire
  /// l'épuisement ou non — et n'a qu'un tier, 1 (voir `ForgeRuneRules`).
  final bool stackable;
```

- constructeur, sous `this.requiresExhaust = false,` : `this.stackable = true,` ;
- `fromJson`, sous `requiresExhaust:` : `stackable: json['stackable'] as bool? ?? true,` ;
- `toJson`, sous `'requiresExhaust': requiresExhaust,` : `'stackable': stackable,`.

`assets/data/forge_upgrades/enduring.json`, sous `"requiresExhaust": true,` : `"stackable": false,`.

`lib/services/content_editor/entity_descriptor.dart`, gabarit d'amélioration, sous `"requiresExhaust": false,` : `"stackable": true,`.

- [ ] **Step 5 : le service de combinaison**

Créer `lib/game/services/forge_rune_rules.dart` :

```dart
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';

/// Une fusion que propose la Forge de Fusion : toutes les runes d'un même id
/// portées par une carte, réunies en une seule dont le tier est la somme.
class FusionOption {
  final String upgradeId;
  final List<String> originalUpgrades;
  final int totalTier;
  final int cost;

  FusionOption({
    required this.upgradeId,
    required this.originalUpgrades,
    required this.totalTier,
    required this.cost,
  });
}

/// Règles de combinaison des runes de forge, notées `id:tier`.
///
/// La Forge de Fusion et la fusion 3→1 additionnent les tiers des runes de
/// même id. Une rune non cumulable (`ForgeUpgradeData.stackable`) n'a pas de
/// tier qui vaille : elle n'est jamais proposée à la fusion, et une fusion 3→1
/// n'en garde qu'un exemplaire, au tier 1.
class ForgeRuneRules {
  const ForgeRuneRules._();

  /// Une rune absente du registre est traitée comme cumulable, ce qu'étaient
  /// toutes les runes avant l'apparition du champ.
  static bool isStackable(String runeId) =>
      ForgeUpgradeData.getById(runeId)?.stackable ?? true;

  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, une rune non cumulable est
  /// gardée une fois au tier 1. Une référence mal formée ou de tier nul est
  /// ignorée.
  static List<String> consolidate(Iterable<String> runes) {
    final tiers = <String, int>{};
    for (final rune in runes) {
      final parts = rune.split(':');
      if (parts.length != 2) continue;
      final tier = int.tryParse(parts[1]) ?? 0;
      if (tier <= 0) continue;
      final id = parts[0];
      tiers[id] = isStackable(id) ? (tiers[id] ?? 0) + tier : 1;
    }
    return [for (final entry in tiers.entries) '${entry.key}:${entry.value}'];
  }

  /// Fusions que la Forge de Fusion propose pour [card] : une par id de rune
  /// cumulable que la carte porte au moins deux fois, au coût de
  /// `80 × (N - 1)` or.
  static List<FusionOption> fusionOptionsFor(CardInstance card) {
    final groups = <String, List<String>>{};
    for (final rune in card.forgeUpgrades) {
      groups.putIfAbsent(rune.split(':')[0], () => []).add(rune);
    }

    final options = <FusionOption>[];
    groups.forEach((id, runes) {
      if (runes.length < 2 || !isStackable(id)) return;
      var totalTier = 0;
      for (final rune in runes) {
        final parts = rune.split(':');
        totalTier += parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
      }
      options.add(FusionOption(
        upgradeId: id,
        originalUpgrades: runes,
        totalTier: totalTier,
        cost: 80 * (runes.length - 1),
      ));
    });
    return options;
  }
}
```

- [ ] **Step 6 : les trois combinaisons lisent le service**

`lib/game/controllers/deck_controller.dart` : importer `'../services/forge_rune_rules.dart'`, et dans `mergeCards` remplacer :

```dart
      // Auto-fusionne les upgrades identiques (cumul des tiers)
      final Map<String, int> consolidatedMap = {};
      for (var upgrade in inheritedUpgrades) {
        final parts = upgrade.split(':');
        if (parts.length != 2) continue;
        final id = parts[0];
        final tier = int.tryParse(parts[1]) ?? 0;
        if (tier <= 0) continue;
        consolidatedMap[id] = (consolidatedMap[id] ?? 0) + tier;
      }

      var finalUpgrades = consolidatedMap.entries.map((e) => '${e.key}:${e.value}').toList();
```

par :

```dart
      // Réunit les runes identiques (voir `ForgeRuneRules.consolidate`)
      var finalUpgrades = ForgeRuneRules.consolidate(inheritedUpgrades);
```

`lib/ui/screens/deck_screen.dart` : importer `'../../game/services/forge_rune_rules.dart'`, et dans `_proceedToUpgrades` remplacer :

```dart
    final Map<String, int> consolidatedMap = {};
    for (var card in _selectedCards) {
      for (var upgrade in card.forgeUpgrades) {
        final parts = upgrade.split(':');
        if (parts.length != 2) continue;
        final id = parts[0];
        final tier = int.tryParse(parts[1]) ?? 0;
        if (tier <= 0) continue;
        consolidatedMap[id] = (consolidatedMap[id] ?? 0) + tier;
      }
    }

    _consolidatedUpgrades = [];
    consolidatedMap.forEach((id, tier) {
      _consolidatedUpgrades.add('$id:$tier');
    });
```

par :

```dart
    _consolidatedUpgrades = ForgeRuneRules.consolidate(
      _selectedCards.expand((card) => card.forgeUpgrades),
    );
```

`lib/ui/screens/forge_fusion_screen.dart` : supprimer la classe `FusionOption` et la méthode `_getFusionsForCard`, importer `'../../game/services/forge_rune_rules.dart'`, et remplacer chacun des cinq appels `_getFusionsForCard(x)` par `ForgeRuneRules.fusionOptionsFor(x)`.

- [ ] **Step 7 : lancer les tests, vérifier qu'ils passent**

Run : même commande qu'au Step 3, plus `flutter test test/widget/deck_screen_test.dart test/unit/deck_controller_test.dart test/unit/content_editor test/widget/content_editor`, puis `dart analyze` et `dart run tool/sync_assets.dart --check`
Expected : tout passe ; `No issues found!` ; `sync_assets` sort en 0 (aucun dossier ajouté).

- [ ] **Step 8 : commit**

```bash
git add lib test assets
git commit -m "fix(forge): une rune non cumulable ne se fusionne plus"
```

---

### Task 5 : le tirage et l'affichage des tiers lisent `stackable`

**Files :**
- Modify : `lib/game/controllers/shop_controller.dart:145-155`
- Modify : `lib/ui/widgets/forge_upgrade_dialog.dart:176-186`
- Modify : `lib/ui/widgets/forge/forge_slot_row.dart:196-198`
- Modify : `lib/ui/screens/deck_screen.dart:297-300, 375-378`
- Test : `test/unit/shop_controller_test.dart`

**Interfaces :**
- Consumes : `ForgeRuneRules.isStackable(String runeId)` et `ForgeUpgradeData.stackable` (tâche 4).

- [ ] **Step 1 : écrire le test**

`test/unit/shop_controller_test.dart` : importer `models/data/forge_upgrade_data.dart` et `models/data/game_data_registry.dart`, puis **en dernier test du groupe** (le registre statique qu'il installe resterait visible des tests suivants) :

```dart
    test('la boutique ne tire une rune non cumulable qu au tier 1', () {
      // Un id autre qu'`enduring` : c'est la donnee qui decide, pas l'id.
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [
          ForgeUpgradeData(
            id: 'steadfast',
            nameEn: 'Steadfast',
            nameFr: 'Inebranlable',
            descriptionEn: '',
            descriptionFr: '',
            icon: '',
            color: '',
            pools: ['common', 'uncommon', 'rare'],
            stackable: false,
          ),
        ],
      );
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      final rolled = <String>{};
      for (var i = 0; i < 100; i++) {
        shopController.initializeShop(testCardPool, 0);
        for (final card in shopController.state.cardsForSale) {
          rolled.addAll(card.forgeUpgrades);
        }
      }

      expect(rolled, {'steadfast:1'});
    });
```

- [ ] **Step 2 : lancer le test, vérifier qu'il échoue**

Run : `flutter test test/unit/shop_controller_test.dart --plain-name "la boutique ne tire une rune non cumulable"`
Expected : FAIL, l'ensemble contient aussi `steadfast:2` et `steadfast:3` (le tirage actuel ne connaît que l'id `enduring`).

- [ ] **Step 3 : les deux tirages**

`lib/game/controllers/shop_controller.dart` : importer `'../services/forge_rune_rules.dart'` ; dans `_rollRandomUpgrade`, `if (rolledId != 'enduring') {` devient `if (ForgeRuneRules.isStackable(rolledId)) {`.

`lib/ui/widgets/forge_upgrade_dialog.dart` : importer `'../../game/services/forge_rune_rules.dart'` ; dans `_rollSlotUpgrade`, `if (rolledId != 'enduring') {` devient `if (ForgeRuneRules.isStackable(rolledId)) {`.

- [ ] **Step 4 : les trois affichages**

`lib/ui/widgets/forge/forge_slot_row.dart` :

```dart
    final upgradeName = upgradeData != null
        ? upgradeData.getName(locale) + (upgradeData.stackable ? ' $tier' : '')
        : _getUpgradeName(slot.upgrade);
```

`lib/ui/screens/deck_screen.dart`, sous-titre de la sélection :

```dart
                            return upgradeData != null
                                ? (upgradeData.stackable ? '${upgradeData.getName(locale)} $tier' : upgradeData.getName(locale))
                                : '$id $tier';
```

et libellé du choix d'héritage :

```dart
                    final displayName = upgradeData != null 
                        ? (upgradeData.stackable ? '${upgradeData.getName(locale)} (Niveau $tier)' : upgradeData.getName(locale))
                        : '${id.toUpperCase()} (Niveau $tier)';
```

- [ ] **Step 5 : lancer les tests, vérifier qu'ils passent**

Run : `flutter test test/unit/shop_controller_test.dart test/widget/shop_screen_test.dart test/widget/deck_screen_test.dart test/widget/rest_screen_test.dart` puis `dart analyze`
Expected : tout passe ; `No issues found!`. Contrôle : `grep -rn "'enduring" lib | grep -v "case 'enduring':"` ne rend qu'une ligne, `card_instance.dart` — la règle d'épuisement de la tâche 3, qui reconnaît l'effet à son id quel que soit le tier.

- [ ] **Step 6 : commit**

```bash
git add lib test
git commit -m "refactor(forge): le tirage et l affichage des tiers lisent stackable"
```

---

### Task 6 : vérification finale

- [ ] **Step 1 : suite complète**

Run : `flutter test`
Expected : `All tests passed!`, **773 + tests ajoutés** (8 dans `card_rarity_test`, 2 dans `deck_controller_test` plus 4 dans son groupe d'épuisement, 1 dans `reward_controller_test`, 1 dans `shop_controller_test`, 1 dans `decoupled_forge_test`, 9 dans `forge_rune_rules_test`, 2 dans `ui_card_rune_sockets_test`, 1 dans chacun de `deck_screen_test`, `shop_screen_test`, `draft_screen_test`, `forge_fusion_screen_test` — soit 773 + 32 = **805** ; `real_bundle_load_test` et `entity_descriptor_test` sont modifiés, pas augmentés. À re-compter sur la sortie réelle).

- [ ] **Step 2 : analyse et assets**

Run : `dart analyze` puis `dart run tool/sync_assets.dart --check`
Expected : `No issues found!` ; code de sortie 0.

- [ ] **Step 3 : plus aucune trace des trois causes**

Run : `grep -rn "rarity.index + 1\|CardRarity.values.length\|rarityIndex" lib` puis `grep -rn "'enduring" lib | grep -v "case 'enduring':"`
Expected : aucune ligne pour la première ; pour la seconde, la seule `card_instance.dart` (`exhaustsOnPlay`). Les `case 'enduring':` restants sont les textes de runes codés en dur par id, hors périmètre (spec §6).

> **Mesuré le 2026-09-15** : 805 tests au vert, `No issues found!`, `sync_assets --check` à 0, contrôles conformes.
