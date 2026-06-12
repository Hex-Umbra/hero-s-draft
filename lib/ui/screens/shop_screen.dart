import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/shop_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../services/game_data_service.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      Future.microtask(() {
        final gameData = ref.read(gameDataLoaderProvider).requireValue;
        final inventoryState = ref.read(inventoryProvider);
        ref
            .read(shopProvider.notifier)
            .initializeShop(gameData.cards, inventoryState.bonusShopCards);
      });
      _isInitialized = true;
    }
  }

  void _buyCard(CardData card, int price) {
    final shopController = ref.read(shopProvider.notifier);

    if (shopController.buyCard(
      card,
      price,
    )) {
      final locale = Localizations.localeOf(context).languageCode;
      context.showNotification(
        AppLocalizations.of(context)!.purchased(card.getName(locale)),
        type: NotificationType.success,
      );
    } else {
      context.showNotification(
        AppLocalizations.of(context)!.notEnoughGold,
        type: NotificationType.error,
      );
    }
  }

  void _buyHeal(int price, int amount) {
    final shopController = ref.read(shopProvider.notifier);
    final currentPv = ref.read(runProvider).heroStats.currentPv;
    final maxPv = ref.read(runProvider).heroStats.maxPv;

    if (currentPv >= maxPv) {
      context.showNotification(
        AppLocalizations.of(context)!.fullHp,
        type: NotificationType.warning,
      );
      return;
    }

    if (shopController.buyHeal(
      price,
      amount,
    )) {
      context.showNotification(
        AppLocalizations.of(context)!.healApplied,
        type: NotificationType.success,
      );
    } else {
      context.showNotification(
        AppLocalizations.of(context)!.notEnoughGold,
        type: NotificationType.error,
      );
    }
  }

  void _expandShop(int price) {
    final shopController = ref.read(shopProvider.notifier);
    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    if (shopController.expandShop(price, gameData.cards)) {
      context.showNotification(
        AppLocalizations.of(context)!.shopExpanded,
        type: NotificationType.success,
      );
    } else {
      context.showNotification(
        AppLocalizations.of(context)!.notEnoughGold,
        type: NotificationType.error,
      );
    }
  }

  void _rerollCards(int price) {
    final shopController = ref.read(shopProvider.notifier);
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    final inventoryState = ref.read(inventoryProvider);

    if (shopController.rerollCards(
      price,
      gameData.cards,
      inventoryState.bonusShopCards,
    )) {
      context.showNotification(
        AppLocalizations.of(context)!.shopRerolled,
        type: NotificationType.success,
      );
    } else {
      context.showNotification(
        AppLocalizations.of(context)!.notEnoughGold,
        type: NotificationType.error,
      );
    }
  }

  void _showRemovalModal(int price) {
    final deckState = ref.read(deckProvider);
    final masterDeck = deckState.masterDeck;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) {
        return GameDialog(
          title: Text(
            l10n.chooseCardToPurge,
          ),
          content: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: masterDeck.length,
                itemBuilder: (context, index) {
                  final card = masterDeck[index];
                  return UiCard(
                    title: card.data.getName(locale),
                    description: card.data.getDescription(locale),
                    cost: card.data.cost,
                    effects: card.data.effects,
                    rarity: card.rarity.getLabel(l10n),
                    target: card.data.target.getLabel(l10n),
                    type: card.data.type,
                    targetType: card.data.target,
                    isExhaust: card.data.isExhaust,
                    onTap: () {
                      final shopController = ref.read(shopProvider.notifier);

                      if (shopController.purgeCard(
                        price,
                        card,
                      )) {
                        Navigator.of(ctx).pop();
                        context.showNotification(
                          l10n.cardPurged,
                          type: NotificationType.success,
                        );
                      } else {
                        Navigator.of(ctx).pop();
                        context.showNotification(
                          l10n.notEnoughGold,
                          type: NotificationType.error,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            GameButton(
              text: l10n.cancel,
              baseColor: Colors.white70,
              onPressed: () => Navigator.of(ctx).pop(),
              height: 40,
              width: 100,
            ),
          ],
        );
      },
    );
  }

  void _showCloneModal(int price) {
    final deckState = ref.read(deckProvider);
    final masterDeck = List.of(deckState.masterDeck);

    masterDeck.shuffle();
    final options = masterDeck.take(3).toList();

    if (options.isEmpty) {
      return;
    }

    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) {
        return GameDialog(
          title: Text(
            l10n.chooseCardToClone,
          ),
          content: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options
                    .map(
                      (card) => ListTile(
                        title: Text(
                          card.data.getName(locale),
                          style: const TextStyle(color: Colors.amber),
                        ),
                        subtitle: Text(
                          card.rarity.getLabel(l10n),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () {
                          final shopController = ref.read(shopProvider.notifier);

                          if (shopController.cloneCard(
                            price,
                            card,
                          )) {
                            Navigator.of(ctx).pop();
                            context.showNotification(
                              l10n.cardCloned,
                              type: NotificationType.success,
                            );
                          } else {
                            Navigator.of(ctx).pop();
                            context.showNotification(
                              l10n.notEnoughGold,
                              type: NotificationType.error,
                            );
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            GameButton(
              text: l10n.cancel,
              baseColor: Colors.white70,
              onPressed: () => Navigator.of(ctx).pop(),
              height: 40,
              width: 100,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final shopState = ref.watch(shopProvider);
    final int healPrice = 30;
    final int healAmount = (runState.heroStats.maxPv * 0.3).round();
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      child: Scaffold(
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
                    '${inventoryState.gold}',
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
                        child: shopState.cardsForSale.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.noCardsInStock,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 20,
                                  children: shopState.cardsForSale.map((card) {
                                    final int price =
                                        ShopController.getCardPrice(
                                      card.rarity,
                                    );
                                    final bool canAfford =
                                        inventoryState.gold >= price;
                                      return SizedBox(
                                        width: 150,
                                        child: _ShopCardItem(
                                          card: card,
                                          price: price,
                                          onPressed: () => _buyCard(card, price),
                                          rarityLabel: card.rarity.getLabel(l10n),
                                          targetLabel: card.target.getLabel(l10n),
                                          canAfford: canAfford,
                                        ),
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
                                icon: Icons.refresh,
                                iconColor: Colors.tealAccent,
                                title: l10n.shopReroll,
                                description: l10n.shopRerollDesc,
                                price: 15,
                                onPressed: () => _rerollCards(15),
                                buttonColor: Colors.teal.shade800,
                                canAfford: inventoryState.gold >= 15,
                              ),
                              _ShopServiceWidget(
                                icon: Icons.local_hospital,
                                iconColor: Colors.greenAccent,
                                title: l10n.healingPotion,
                                description: l10n.restoresHp(healAmount),
                                price: healPrice,
                                onPressed: shopState.purchasedHeal
                                    ? null
                                    : () => _buyHeal(healPrice, healAmount),
                                buttonColor: Colors.green.shade800,
                                canAfford: inventoryState.gold >= healPrice,
                              ),
                              _ShopServiceWidget(
                                icon: Icons.delete_forever,
                                iconColor: Colors.redAccent,
                                title: l10n.shopPurge,
                                description: l10n.shopPurgeDesc,
                                price: 75,
                                onPressed: () => _showRemovalModal(75),
                                buttonColor: Colors.red.shade800,
                                canAfford: inventoryState.gold >= 75,
                              ),
                              _ShopServiceWidget(
                                icon: Icons.add_shopping_cart,
                                iconColor: Colors.amberAccent,
                                title: l10n.shopExpand,
                                description: l10n.shopExpandDesc,
                                price: 100,
                                onPressed: () => _expandShop(100),
                                buttonColor: Colors.amber.shade800,
                                canAfford: inventoryState.gold >= 100,
                              ),
                              _ShopServiceWidget(
                                icon: Icons.content_copy,
                                iconColor: Colors.blueAccent,
                                title: l10n.shopClone,
                                description: l10n.shopCloneDesc,
                                price: 150,
                                onPressed: () => _showCloneModal(150),
                                buttonColor: Colors.blue.shade800,
                                canAfford: inventoryState.gold >= 150,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GameButton(
                        text: l10n.leaveShop,
                        onPressed: () {
                          ref.read(runProvider.notifier).completeCurrentNode();
                          Navigator.of(context).pop();
                        },
                        baseColor: Colors.blueAccent,
                        height: 54,
                        fontSize: 18,
                      ),
                    ],
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

class _ShopServiceWidget extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final int price;
  final VoidCallback? onPressed;
  final Color buttonColor;
  final bool canAfford;

  const _ShopServiceWidget({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.price,
    required this.onPressed,
    required this.buttonColor,
    required this.canAfford,
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
                color: _isHovered
                    ? Colors.amber.withValues(alpha: 0.5)
                    : Colors.white10,
                width: _isHovered ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 28),
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
                GameButton(
                  text: '',
                  goldCost: widget.price,
                  onPressed: widget.onPressed,
                  baseColor: widget.onPressed == null
                      ? Colors.grey
                      : (widget.canAfford ? Colors.green : Colors.red),
                  height: 32,
                  fontSize: 12,
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
  final bool canAfford;

  const _ShopCardItem({
    required this.card,
    required this.price,
    required this.onPressed,
    required this.rarityLabel,
    required this.targetLabel,
    required this.canAfford,
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
              Builder(
                builder: (context) {
                  final locale = Localizations.localeOf(context).languageCode;
                  return SizedBox(
                    width: 150,
                    height: 220,
                    child: UiCard(
                      title: widget.card.getName(locale),
                      description: widget.card.getDescription(locale),
                      cost: widget.card.cost,
                      effects: widget.card.effects,
                      level: 1,
                      rarity: widget.rarityLabel,
                      target: widget.targetLabel,
                      type: widget.card.type,
                      targetType: widget.card.target,
                      isExhaust: widget.card.isExhaust,
                      onTap: widget.onPressed,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              GameButton(
                text: '',
                goldCost: widget.price,
                onPressed: widget.onPressed,
                baseColor: widget.canAfford ? Colors.green : Colors.red,
                height: 32,
                fontSize: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
