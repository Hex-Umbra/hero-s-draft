import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/shop_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../services/game_data_service.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../../models/card_instance.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/gold_indicator.dart';

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

  void _buyCard(CardInstance card, int price) {
    final shopController = ref.read(shopProvider.notifier);

    if (shopController.buyCard(
      card,
      price,
    )) {
      final locale = Localizations.localeOf(context).languageCode;
      context.showNotification(
        AppLocalizations.of(context)!.purchased(card.data.getName(locale)),
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
                  return UiCard.fromInstance(
                    card: card,
                    locale: locale,
                    l10n: l10n,
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

  void _showCloneModal() {
    final shopState = ref.read(shopProvider);
    List<CardInstance> options = shopState.cloneOptions;

    if (options.isEmpty) {
      final deckState = ref.read(deckProvider);
      final masterDeck = List.of(deckState.masterDeck);
      masterDeck.shuffle();
      options = masterDeck.take(3).toList();
      if (options.isNotEmpty) {
        ref.read(shopProvider.notifier).setCloneOptions(options);
      }
    }

    if (options.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) {
        return GameDialog(
          maxWidth: 550,
          title: Text(
            l10n.chooseCardToClone,
          ),
          content: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: options.map((card) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: SizedBox(
                        width: 140,
                        child: _CloneCardItem(
                          card: card,
                          onPressed: () {
                            final shopController = ref.read(shopProvider.notifier);

                            if (shopController.cloneCard(
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
                      ),
                    );
                  }).toList(),
                ),
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
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final shopState = ref.watch(shopProvider);
    final int healPrice = 30;
    final int healAmount = (runState.heroStats.maxPv * 0.3).round();
    final l10n = AppLocalizations.of(context)!;

    final appBar = PageHeader(
      title: l10n.shop,
      showBackButton: false,
      isParchment: false,
      actions: const [
        GoldIndicator(isParchment: false),
      ],
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(shopProvider.notifier).clearCloneOptions();
        }
      },
      child: ScreenScaffold(
        backgroundType: ScreenBackgroundType.dark,
        appBar: appBar,
        body: Padding(
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
                                    card,
                                  );
                                  final bool canAfford =
                                      inventoryState.gold >= price;
                                    return SizedBox(
                                      width: 150,
                                      child: _ShopCardItem(
                                        card: card,
                                        price: price,
                                        onPressed: () => _buyCard(card, price),
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
                              onPressed: inventoryState.gold >= 15
                                  ? () => _rerollCards(15)
                                  : null,
                              buttonColor: Colors.teal.shade800,
                              canAfford: inventoryState.gold >= 15,
                            ),
                            _ShopServiceWidget(
                              icon: Icons.local_hospital,
                              iconColor: Colors.greenAccent,
                              title: l10n.healingPotion,
                              description: l10n.restoresHp(healAmount),
                              price: healPrice,
                              onPressed: shopState.purchasedHeal ||
                                      inventoryState.gold < healPrice
                                  ? null
                                  : () => _buyHeal(healPrice, healAmount),
                              buttonColor: Colors.green.shade800,
                              canAfford: inventoryState.gold >= healPrice &&
                                  !shopState.purchasedHeal,
                            ),
                            _ShopServiceWidget(
                              icon: Icons.delete_forever,
                              iconColor: Colors.redAccent,
                              title: l10n.shopPurge,
                              description: l10n.shopPurgeDesc,
                              price: 75,
                              onPressed: inventoryState.gold >= 75
                                  ? () => _showRemovalModal(75)
                                  : null,
                              buttonColor: Colors.red.shade800,
                              canAfford: inventoryState.gold >= 75,
                            ),
                            _ShopServiceWidget(
                              icon: Icons.add_shopping_cart,
                              iconColor: Colors.amberAccent,
                              title: l10n.shopExpand,
                              description: l10n.shopExpandDesc,
                              price: 100,
                              onPressed: inventoryState.gold >= 100
                                  ? () => _expandShop(100)
                                  : null,
                              buttonColor: Colors.amber.shade800,
                              canAfford: inventoryState.gold >= 100,
                            ),
                            _ShopServiceWidget(
                              icon: Icons.content_copy,
                              iconColor: Colors.blueAccent,
                              title: l10n.shopClone,
                              description: l10n.shopCloneDesc,
                              price: shopState.clonePrice,
                              onPressed: inventoryState.gold >= shopState.clonePrice
                                  ? () => _showCloneModal()
                                  : null,
                              buttonColor: Colors.blue.shade800,
                              canAfford: inventoryState.gold >= shopState.clonePrice,
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
    final bool isEnabled = widget.onPressed != null;
    return MouseRegion(
      onEnter: isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: isEnabled ? (_) => setState(() => _isHovered = false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: _isHovered && isEnabled ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 130,
            height: 170,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.black45 : Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered && isEnabled
                    ? Colors.amber.withValues(alpha: 0.5)
                    : Colors.white10,
                width: _isHovered && isEnabled ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: isEnabled ? widget.iconColor : widget.iconColor.withValues(alpha: 0.3),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.white30,
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
                      style: TextStyle(
                        color: isEnabled ? Colors.white70 : Colors.white24,
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
  final CardInstance card;
  final int price;
  final VoidCallback onPressed;
  final bool canAfford;

  const _ShopCardItem({
    required this.card,
    required this.price,
    required this.onPressed,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) {
                final locale = Localizations.localeOf(context).languageCode;
                final l10n = AppLocalizations.of(context)!;
                return SizedBox(
                  width: 150,
                  child: AspectRatio(
                    aspectRatio: 70 / 110,
                    child: UiCard.fromInstance(
                      card: widget.card,
                      locale: locale,
                      l10n: l10n,
                      onTap: widget.onPressed,
                    ),
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
    );
  }
}

class _CloneCardItem extends StatefulWidget {
  final CardInstance card;
  final VoidCallback onPressed;

  const _CloneCardItem({
    required this.card,
    required this.onPressed,
  });

  @override
  State<_CloneCardItem> createState() => _CloneCardItemState();
}

class _CloneCardItemState extends State<_CloneCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AspectRatio(
          aspectRatio: 70 / 110,
          child: UiCard.fromInstance(
            card: widget.card,
            locale: locale,
            l10n: l10n,
            isSelected: _isHovered,
            onTap: widget.onPressed,
          ),
        ),
      ),
    );
  }
}
