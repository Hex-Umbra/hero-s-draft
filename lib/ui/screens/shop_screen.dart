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
            'Choisissez une carte à purger',
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
                  type: card.data.type,
                  isExhaust: card.data.isExhaust,
                  onTap: () {
                    final runController = ref.read(runProvider.notifier);
                    if (runController.spendGold(price)) {
                      ref
                          .read(deckProvider.notifier)
                          .removeCardFromMasterDeck(card);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Carte purgée !'),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Section (75%) - Cards for Sale
              Expanded(
                flex: 3,
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
                    Expanded(
                      child: _cardsForSale.isEmpty
                          ? const Center(
                              child: Text(
                                'Plus de cartes en stock !',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 18),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 20,
                                children: _cardsForSale.map((card) {
                                  int price = 25;
                                  if (card.rarity == CardRarity.uncommon) {
                                    price = 50;
                                  }
                                  if (card.rarity == CardRarity.rare) {
                                    price = 100;
                                  }

                                  return _ShopCardItem(
                                    card: card,
                                    price: price,
                                    onPressed: () => _buyCard(card, price),
                                    rarityLabel: _getRarityLabel(card.rarity),
                                    targetLabel: _getTargetLabel(card.target),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(color: Colors.white24, width: 40),
              // Sidebar Section (25%) - Services
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.services,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _ShopServiceWidget(
                              icon: Icons.local_hospital,
                              iconColor: Colors.greenAccent,
                              title: l10n.healingPotion,
                              description: l10n.restoresHp(healAmount),
                              price: healPrice,
                              onPressed: _purchasedHeal
                                  ? null
                                  : () => _buyHeal(healPrice, healAmount),
                              buttonColor: Colors.green.shade800,
                            ),
                            _ShopServiceWidget(
                              icon: Icons.delete_forever,
                              iconColor: Colors.redAccent,
                              title: 'Purger',
                              description: 'Retire une carte de votre deck',
                              price: 75,
                              onPressed: () => _showRemovalModal(75),
                              buttonColor: Colors.red.shade800,
                            ),
                            _ShopServiceWidget(
                              icon: Icons.content_copy,
                              iconColor: Colors.blueAccent,
                              title: 'Miroir Magique',
                              description: 'Clone une carte de votre deck',
                              price: 150,
                              onPressed: () => _showCloneModal(150),
                              buttonColor: Colors.blue.shade800,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopServiceWidget extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final int price;
  final VoidCallback? onPressed;
  final Color buttonColor;

  const _ShopServiceWidget({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.price,
    required this.onPressed,
    required this.buttonColor,
  });

  @override
  State<_ShopServiceWidget> createState() => _ShopServiceWidgetState();
}

class _ShopServiceWidgetState extends State<_ShopServiceWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 130,
            height: 170,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? Colors.amber.withValues(alpha: 0.5) : Colors.white10,
                width: _isHovered ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: widget.onPressed,
                  icon: const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 12,
                  ),
                  label: Text(
                    '${widget.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.onPressed == null ? Colors.grey : widget.buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: const Size(double.infinity, 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopCardItem extends StatefulWidget {
  final CardData card;
  final int price;
  final VoidCallback onPressed;
  final String rarityLabel;
  final String targetLabel;

  const _ShopCardItem({
    required this.card,
    required this.price,
    required this.onPressed,
    required this.rarityLabel,
    required this.targetLabel,
  });

  @override
  State<_ShopCardItem> createState() => _ShopCardItemState();
}

class _ShopCardItemState extends State<_ShopCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 220,
                child: UiCard(
                  title: widget.card.name,
                  description: widget.card.description,
                  cost: widget.card.cost,
                  effects: widget.card.effects,
                  level: 1,
                  rarity: widget.rarityLabel,
                  target: widget.targetLabel,
                  onTap: widget.onPressed,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 14,
                ),
                label: Text(
                  '${widget.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHovered ? Colors.amber.shade900 : Colors.black45,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _isHovered ? Colors.amber : Colors.transparent,
                      width: 1,
                    ),
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
