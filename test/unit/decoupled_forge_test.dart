import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

void main() {
  group('Decoupled Forge Unit Tests', () {
    // Frappe : 6 degats en commune, 10 en epique.
    const strike = CardData(
      id: 'strike',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 6)],
    );

    // Initialise le registre statique avec de fausses améliorations pour les tests
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        cards: [],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'sharp',
            nameEn: 'Sharp',
            nameFr: 'Tranchant',
            descriptionEn: '+{val} Damage ({percent}%, {tier})',
            descriptionFr: '+{val} Dégâts ({percent}%, {tier})',
            icon: 'hardware_rounded',
            color: 'redAccent',
            pools: ['common'],
            deltas: [
              PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 15),
            ],
            weight: 100,
          ),
          const ForgeUpgradeData(
            id: 'hardened',
            nameEn: 'Hardened',
            nameFr: 'Endurci',
            descriptionEn: '+{val} Block ({percent}%, {tier})',
            descriptionFr: '+{val} Armure ({percent}%, {tier})',
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
            deltas: [
              PercentBonusDelta(effect: 'armor', valuePercentPerLevel: 15),
            ],
            weight: 80,
          ),
          const ForgeUpgradeData(
            id: 'eco',
            nameEn: 'Eco',
            nameFr: 'Économe',
            descriptionEn: 'Gains +{tier} Mana on play',
            descriptionFr: 'Gagne +{tier} Mana à l\'utilisation',
            icon: 'diamond_rounded',
            color: 'cyanAccent',
            pools: ['rare'],
            maxLevel: 1,
            deltas: [AddEffectDelta(effect: 'gain_mana', valuePerLevel: 1)],
            weight: 40,
          ),
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
        ],
      );
    });

    test('addForgeUpgrade correctly adds an upgrade to the master deck card', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cardData = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      final card = CardInstance(data: cardData);
      final deckNotifier = container.read(deckProvider.notifier);

      deckNotifier.initializeStarterDeck([card]);

      // Initially no upgrades
      expect(container.read(deckProvider).masterDeck.first.forgeUpgrades, isEmpty);

      // Add a sharp:1 upgrade
      deckNotifier.addForgeUpgrade(card.uniqueId, 'sharp:1');

      final updatedCard = container.read(deckProvider).masterDeck.first;
      expect(updatedCard.forgeUpgrades, contains('sharp:1'));
      expect(updatedCard.forgeUpgrades.length, 1);
    });

    test('ForgeUpgradeData dit son nom, et sa description sur la carte', () {
      final sharp = ForgeUpgradeData.getById('sharp');
      expect(sharp, isNotNull);
      expect(sharp!.getName('fr'), 'Tranchant');
      expect(sharp.getName('en'), 'Sharp');
      // 6 en commune : +1 au niveau 1 ; 10 en epique : 15 % x 2 x 10 = +3.
      expect(sharp.getDescription(1, 'fr', strike, CardRarity.common),
          '+1 Dégâts (15%, 1)');
      expect(sharp.getDescription(2, 'en', strike, CardRarity.epic),
          '+3 Damage (30%, 2)');
    });

    test('{val} dit le gain marginal sur une carte qui porte deja la rune', () {
      // Frappe epique (10) portant Tranchant 1 (+2) : une fente Tranchant 1 la
      // mene au niveau 2 (+3), soit +1 (spec P-43 E1, §5.1).
      expect(
        ForgeUpgradeData.getById('sharp')!
            .getDescription(1, 'fr', strike, CardRarity.epic, carried: 1),
        '+1 Dégâts (15%, 1)',
      );
    });

    // Review Focus 4 : une sauvegarde peut porter Endurci sur une carte sans
    // armure.
    test('{val} vaut 0 sur une carte sans l effet que la rune vise', () {
      expect(
        ForgeUpgradeData.getById('hardened')!
            .getDescription(1, 'fr', strike, CardRarity.common),
        '+0 Armure (15%, 1)',
      );
    });

    test('setForgeUpgrades updates master deck card upgrades directly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cardData = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      final card = CardInstance(data: cardData, forgeUpgrades: ['sharp:1', 'sharp:2']);
      final deckNotifier = container.read(deckProvider.notifier);

      deckNotifier.initializeStarterDeck([card]);

      // Initially sharp:1 and sharp:2
      expect(container.read(deckProvider).masterDeck.first.forgeUpgrades, equals(['sharp:1', 'sharp:2']));

      // Set to fused sharp:3
      deckNotifier.setForgeUpgrades(card.uniqueId, ['sharp:3']);

      final updatedCard = container.read(deckProvider).masterDeck.first;
      expect(updatedCard.forgeUpgrades, equals(['sharp:3']));
    });

    List<CardInstance> threeCopies(List<String> runes) => List.generate(
          3,
          (_) => CardInstance(data: strike, forgeUpgrades: runes),
        );

    test('mergeCards borne trois eco:1 a eco:1 (spec P-43 E1, A9)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final copies = threeCopies(const ['eco:1']);
      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.initializeStarterDeck(copies);

      deckNotifier.mergeCards(copies.map((c) => c.uniqueId).toList());

      expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
          ['eco:1']);
    });

    test('mergeCards additionne trois sharp:1 en sharp:3', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final copies = threeCopies(const ['sharp:1']);
      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.initializeStarterDeck(copies);

      deckNotifier.mergeCards(copies.map((c) => c.uniqueId).toList());

      expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
          ['sharp:3']);
    });

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

      deckNotifier.mergeCards(copies.map((c) => c.uniqueId).toList());

      expect(
        container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['enduring:1'],
      );
    });
  });
}
