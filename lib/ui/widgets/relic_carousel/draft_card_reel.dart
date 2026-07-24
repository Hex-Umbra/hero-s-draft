import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../draft/draft_choice_card.dart';

class DraftCardReel extends StatefulWidget {
  final String title;
  final String description;
  final String rarity;
  final VoidCallback onTap;
  final int index;
  final VoidCallback? onTick;
  final VoidCallback? onLand;

  final bool initialLanded;

  const DraftCardReel({
    super.key,
    required this.title,
    required this.description,
    required this.rarity,
    required this.onTap,
    required this.index,
    this.onTick,
    this.onLand,
    this.initialLanded = false,
  });

  @override
  State<DraftCardReel> createState() => _DraftCardReelState();
}

class _DraftCardReelState extends State<DraftCardReel>
    with TickerProviderStateMixin {
  late AnimationController _rollController;
  late AnimationController _rarityController;
  late AnimationController _shakeController;
  late AnimationController _glowController;

  bool _prepareToLand = false;
  bool _hasLanded = false;
  Timer? _landTimer;

  // Themed upgrade mock data to scroll through during spin phase (neutral / no rarity)
  final List<Map<String, String>> _mockUpgrades = [
    {'title': 'Vitalité', 'description': '+10 PV Max'},
    {'title': 'Aiguisage', 'description': '+4 Attaque'},
    {'title': 'Forge d\'Acier', 'description': '+2 gains d\'Armure'},
    {'title': 'Sagesse', 'description': '+1 Mana Max'},
    {'title': 'Trèfle à 4 feuilles', 'description': '+1 Chance'},
    {'title': 'Miroir', 'description': 'Cloner une carte'},
  ];

  late Map<String, String> _currentCardData;
  late Map<String, String> _nextCardData;

  @override
  void initState() {
    super.initState();

    final isLegendary =
        widget.rarity.toUpperCase() == 'LÉGENDAIRE' ||
        widget.rarity.toUpperCase() == 'LEGENDARY';
    final isMythic =
        widget.rarity.toUpperCase() == 'MYTHIQUE' ||
        widget.rarity.toUpperCase() == 'MYTHIC';
    final isHighRarity = isLegendary || isMythic;

    // 1. Initialize random starting cards for the roll
    final random = Random();
    _currentCardData = _mockUpgrades[random.nextInt(_mockUpgrades.length)];
    _nextCardData = _mockUpgrades[random.nextInt(_mockUpgrades.length)];

    // 2. Infinite vertical roll controller
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _rollController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        if (_prepareToLand && !_hasLanded) {
          // Landed! Stop the roll, set final stationary state, trigger rarity reveal
          setState(() {
            _currentCardData = {
              'title': widget.title,
              'description': widget.description,
            };
            _hasLanded = true;
          });
          _rollController.stop();
          _shakeController.stop();
          _triggerRarityReveal();
        } else if (!_hasLanded) {
          // Standard infinite mock roll loop
          setState(() {
            _currentCardData = _nextCardData;
            _nextCardData = _mockUpgrades[random.nextInt(_mockUpgrades.length)];
          });
          widget.onTick?.call();
          _rollController.forward(from: 0.0);
        }
      }
    });

    // 3. Rarity reveal & flash controller (pop overlay + fade border/shadow)
    _rarityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 4. Screenshake for high rarity choice
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    if (isHighRarity && !widget.initialLanded) {
      _shakeController.repeat(reverse: true);
    }

    // 5. Pulsing outer glow for high rarity choice
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    if (widget.initialLanded) {
      _currentCardData = {
        'title': widget.title,
        'description': widget.description,
      };
      _hasLanded = true;
      _prepareToLand = true;
      _rarityController.value = 1.0;
    } else {
      // Start fast rolling immediately
      _rollController.forward();
      // Staggered landing calculation: staggered lock-in delay based on slot index
      final int delayMs =
          1200 +
          widget.index * 600 +
          (isMythic ? 800 : (isLegendary ? 400 : 0));
      _landTimer = Timer(Duration(milliseconds: delayMs), _landReel);
    }
  }

  void _landReel() {
    if (!mounted) return;
    setState(() {
      _prepareToLand = true;
      // Pre-load the target card as incoming in the final roll cycle
      _nextCardData = {
        'title': widget.title,
        'description': widget.description,
      };
    });
  }

  void _triggerRarityReveal() {
    _rarityController.forward().then((_) {
      if (mounted) {
        widget.onLand?.call();
        debugPrint('🎉 Draft Reel Land: Index ${widget.index} Revealed!');
      }
    });
  }

  @override
  void dispose() {
    _landTimer?.cancel();
    _rollController.dispose();
    _rarityController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLegendary =
        widget.rarity.toUpperCase() == 'LÉGENDAIRE' ||
        widget.rarity.toUpperCase() == 'LEGENDARY';
    final isMythic =
        widget.rarity.toUpperCase() == 'MYTHIQUE' ||
        widget.rarity.toUpperCase() == 'MYTHIC';
    final isHighRarity = isLegendary || isMythic;

    // Match rarity color
    Color rarityColor = const Color(0xFF8E8E93);
    if (widget.rarity.toUpperCase() == 'HORS NORME' ||
        widget.rarity.toUpperCase() == 'UNCOMMON' ||
        widget.rarity.toUpperCase() == 'ATYPIQUE') {
      rarityColor = const Color(0xFF34C759);
    } else if (widget.rarity.toUpperCase() == 'RARE') {
      rarityColor = const Color(0xFF007AFF);
    } else if (widget.rarity.toUpperCase() == 'ÉPIQUE' ||
        widget.rarity.toUpperCase() == 'EPIC') {
      rarityColor = const Color(0xFFAF52DE);
    } else if (isLegendary) {
      rarityColor = const Color(0xFFFFCC00);
    } else if (isMythic) {
      rarityColor = const Color(0xFFE53E3E);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _rollController,
        _rarityController,
        _shakeController,
        _glowController,
      ]),
      builder: (context, child) {
        // Screenshake translations during fast spin (for legendary/mythic)
        double shakeX = 0.0;
        double shakeY = 0.0;
        if (!_hasLanded && isHighRarity) {
          final random = Random();
          final shakeScale = isMythic ? 12.0 : 6.0;
          shakeX = (random.nextDouble() - 0.5) * shakeScale;
          shakeY = (random.nextDouble() - 0.5) * shakeScale;
        }

        // Inner roll stack containing outgoing & incoming cards
        Widget cardReelContent;
        if (!_hasLanded) {
          cardReelContent = ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 160,
              height: 240,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Outgoing Card (slides down and out)
                  Positioned(
                    top: _rollController.value * 240,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      // Motion blur effect by fading out fast-moving card slightly
                      opacity: 0.85,
                      child: DraftChoiceCard(
                        title: _currentCardData['title']!,
                        description: _currentCardData['description']!,
                        rarity: widget.rarity,
                        onTap: () {},
                        showRarity: false,
                      ),
                    ),
                  ),
                  // Incoming Card (slides down and in from top)
                  Positioned(
                    top: (_rollController.value - 1.0) * 240,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: 0.85,
                      child: DraftChoiceCard(
                        title: _nextCardData['title']!,
                        description: _nextCardData['description']!,
                        rarity: widget.rarity,
                        onTap: () {},
                        showRarity: false,
                      ),
                    ),
                  ),
                  // Motion blur vertical overlay line streaks
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return Opacity(
                            opacity: 0.08,
                            child: Container(height: 3, color: Colors.white),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Stationary fully-revealed card with smooth progressive rarity fade-in
          cardReelContent = DraftChoiceCard(
            title: widget.title,
            description: widget.description,
            rarity: widget.rarity,
            onTap: widget.onTap,
            showRarity: true,
            rarityProgress: _rarityController.value,
          );
        }

        return Transform(
          transform: Matrix4.translationValues(shakeX, shakeY, 0.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              cardReelContent,
              // Dynamic Rarity Flash overlay upon landing (quick bright flash fading out)
              if (_hasLanded && _rarityController.value < 0.99)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(
                          alpha: 0.80 * (1.0 - _rarityController.value),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              // sparks overlay for locked high-rarity choices
              if (_hasLanded && isHighRarity)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SparkPainter(
                        color: rarityColor,
                        progress: _glowController.value,
                        isMythic: isMythic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isMythic;

  _SparkPainter({
    required this.color,
    required this.progress,
    this.isMythic = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(
        alpha:
            (isMythic ? 0.4 : 0.3) + (isMythic ? 0.6 : 0.5) * (1.0 - progress),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isMythic ? 5.0 : 3.0) + (isMythic ? 3.0 : 2.0) * progress
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMythic ? 8 : 5);

    // Glowing border outline
    final rect = Rect.fromLTWH(-4, -4, size.width + 8, size.height + 8);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isMythic != isMythic;
  }
}
