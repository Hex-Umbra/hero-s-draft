import 'dart:math';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../services/game_data_service.dart';
import '../../models/data/card_data.dart';
import '../../models/card_instance.dart';
import '../widgets/ui_card.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isInitialized = false;
  List<CardData> _cardsForSale = [];
  bool _purchasedHeal = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeShop();
      _isInitialized = true;
    }
  }

  void _initializeShop() {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    final allCards = gameData.cards
        .where((c) => c.type != CardType.status)
        .toList();

    final rng = Random();
    List<CardData> shuffled = List.from(allCards)..shuffle(rng);
    _cardsForSale = shuffled.take(3).toList();
  }

  void _buyCard(CardData card, int price) {
    final runController = ref.read(runProvider.notifier);
    if (runController.spendGold(price)) {
      setState(() {
        _cardsForSale.remove(card);
      });
      final instance = CardInstance(data: card);
      ref.read(deckProvider.notifier).addCardToMasterDeck(instance);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.purchased(card.name)),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notEnoughGold),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _buyHeal(int price, int amount) {
    final runController = ref.read(runProvider.notifier);
    final currentPv = ref.read(runProvider).heroStats.currentPv;
    final maxPv = ref.read(runProvider).heroStats.maxPv;

    if (currentPv >= maxPv) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fullHp),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (runController.spendGold(price)) {
      setState(() {
        _purchasedHeal = true;
      });
      runController.heal(amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.healApplied),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notEnoughGold),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRemovalModal(int price) {
    final deckState = ref.read(deckProvider);
    final masterDeck = deckState.masterDeck;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: const Text(
            'Choisissez une carte à oublier',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200, // Doublé pour un affichage plus clair
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: masterDeck.length,
              itemBuilder: (context, index) {
                final card = masterDeck[index];
                return UiCard(
                  title: card.data.name,
                  description: card.data.description,
                  cost: card.data.cost,
                  effects: card.data.effects,
                  rarity: 'Niveau ${card.level}',
                  target: _getTargetLabel(card.data.target),
                  onTap: () {
                    final runController = ref.read(runProvider.notifier);
                    if (runController.spendGold(price)) {
                      ref
                          .read(deckProvider.notifier)
                          .removeCardFromMasterDeck(card);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Carte oubliée !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pas assez d\'or !'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getRarityLabel(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 'Commun';
      case CardRarity.uncommon:
        return 'Peu Commun';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.epic:
        return 'Épique';
    }
  }

  String _getTargetLabel(CardTarget target) {
    switch (target) {
      case CardTarget.singleEnemy:
        return 'Cible unique';
      case CardTarget.allEnemies:
        return 'Tous les ennemis';
      case CardTarget.self:
        return 'Soi-même';
      case CardTarget.none:
        return 'Aucune';
    }
  }

  void _showCloneModal(int price) {
    final deckState = ref.read(deckProvider);
    final masterDeck = List.of(deckState.masterDeck);

    masterDeck.shuffle();
    final options = masterDeck.take(3).toList();

    if (options.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: const Text(
            'Choisissez une carte à cloner',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (card) => ListTile(
                      title: Text(
                        card.data.name,
                        style: const TextStyle(color: Colors.amber),
                      ),
                      subtitle: Text(
                        'Niveau ${card.level}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        final runController = ref.read(runProvider.notifier);
                        if (runController.spendGold(price)) {
                          ref
                              .read(deckProvider.notifier)
                              .addCardToMasterDeck(
                                CardInstance(
                                  data: card.data,
                                  level: card.level,
                                ),
                              );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Carte clonée !'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pas assez d\'or !'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final int healPrice = 30;
    final int healAmount = (runState.heroStats.maxPv * 0.3).round();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          l10n.shop,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black45,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '${runState.gold}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cardsForSale,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_cardsForSale.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Plus de cartes en stock !',
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cardsForSale.length,
                    itemBuilder: (context, index) {
                      final card = _cardsForSale[index];
                      int price = 25;
                      if (card.rarity == CardRarity.uncommon) price = 50;
                      if (card.rarity == CardRarity.rare) price = 100;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 170,
                              child: UiCard(
                                title: card.name,
                                description: card.description,
                                cost: card.cost,
                                effects: card.effects,
                                level: 1,
                                rarity: _getRarityLabel(card.rarity),
                                target: _getTargetLabel(card.target),
                                onTap: () => _buyCard(card, price),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton.icon(
                              onPressed: () => _buyCard(card, price),
                              icon: const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 12,
                              ),
                              label: Text(
                                '$price',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black45,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(50, 24),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const Divider(color: Colors.white24, height: 40),
              Text(
                l10n.services,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.black45,
                child: ListTile(
                  leading: const Icon(
                    Icons.local_hospital,
                    color: Colors.greenAccent,
                    size: 40,
                  ),
                  title: Text(
                    l10n.healingPotion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    l10n.restoresHp(healAmount),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _purchasedHeal
                        ? null
                        : () => _buyHeal(healPrice, healAmount),
                    icon: const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    label: Text(
                      '$healPrice',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purchasedHeal
                          ? Colors.grey
                          : Colors.green.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.black45,
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                  title: const Text(
                    'Oubli',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Retire une carte de votre deck',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showRemovalModal(75),
                    icon: const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    label: const Text(
                      '75',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.black45,
                child: ListTile(
                  leading: const Icon(
                    Icons.content_copy,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                  title: const Text(
                    'Miroir Magique',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Clone une carte de votre deck',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showCloneModal(150),
                    icon: const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    label: const Text(
                      '150',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ref.read(runProvider.notifier).completeCurrentNode();
                  Navigator.of(context).pop();
                },
                child: Text(
                  l10n.leaveShop,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
