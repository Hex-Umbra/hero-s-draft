import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../draft/draft_choice_card.dart';

// Helper enum to match choice rarity string
enum DraftChoiceRarity { common, uncommon, rare, epic, legendary }

class DraftCardReel extends StatefulWidget {
  final String title;
  final String description;
  final String rarity;
  final VoidCallback onTap;
  final int index;
  final VoidCallback? onTick;
  final VoidCallback? onLand;

  const DraftCardReel({
    super.key,
    required this.title,
    required this.description,
    required this.rarity,
    required this.onTap,
    required this.index,
    this.onTick,
    this.onLand,
  });

  @override
  State<DraftCardReel> createState() => _DraftCardReelState();
}

class _DraftCardReelState extends State<DraftCardReel>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _flipController;
  late AnimationController _shakeController;
  late AnimationController _glowController;

  bool _isSpinning = true;
  bool _isFlipped = false;
  late Timer _landTimer;
  late Timer _tickTimer;

  final List<String> _mockTitles = [
    '???',
    'PUISSANCE',
    'DÉFENSE',
    'CHANCE',
    'MANA',
    'FORGE'
  ];
  String _currentMockTitle = '???';
  int _mockTitleIndex = 0;

  @override
  void initState() {
    super.initState();

    final isLegendary = widget.rarity.toUpperCase() == 'LÉGENDAIRE' ||
        widget.rarity.toUpperCase() == 'LEGENDARY';

    // Spin speed: rotates mock texts rapidly
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat();

    // 3D Flip animation
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Screen-shake for legendary card during its spin
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    if (isLegendary) {
      _shakeController.repeat(reverse: true);
    }

    // Glowing golden halo for legendary choice
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Staggered landing calculation
    final int delayMs = 1000 + widget.index * 600 + (isLegendary ? 400 : 0);

    _landTimer = Timer(Duration(milliseconds: delayMs), _landReel);

    // Rapid ticks sound hook timer during spin
    int tickRate = 120;
    _tickTimer = Timer.periodic(Duration(milliseconds: tickRate), (timer) {
      if (_isSpinning) {
        // Change mock title for slot visual feel
        setState(() {
          _mockTitleIndex = (_mockTitleIndex + 1) % _mockTitles.length;
          _currentMockTitle = _mockTitles[_mockTitleIndex];
        });
        widget.onTick?.call();
        debugPrint('🎵 Draft Reel Tick: Index ${widget.index}');
      } else {
        timer.cancel();
      }
    });
  }

  void _landReel() {
    if (!mounted) return;
    setState(() {
      _isSpinning = false;
    });
    _spinController.stop();
    _shakeController.stop();

    // Trigger flip to reveal the card
    _flipController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isFlipped = true;
        });
        widget.onLand?.call();
        debugPrint('🎉 Draft Reel Land: Index ${widget.index} Revealed!');
      }
    });
  }

  @override
  void dispose() {
    _landTimer.cancel();
    _tickTimer.cancel();
    _spinController.dispose();
    _flipController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLegendary = widget.rarity.toUpperCase() == 'LÉGENDAIRE' ||
        widget.rarity.toUpperCase() == 'LEGENDARY';

    // Rarity color matching
    Color rarityColor = const Color(0xFF8E8E93);
    if (widget.rarity.toUpperCase() == 'HORS CORME' ||
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
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_flipController, _shakeController, _glowController]),
      builder: (context, child) {
        // 1. Calculations for 3D flip rotation
        final double angle = _flipController.value * pi;
        final bool showBack = angle < (pi / 2);

        // 2. Calculations for Screenshake translation (during spin)
        double shakeX = 0.0;
        double shakeY = 0.0;
        if (_isSpinning && isLegendary) {
          final random = Random();
          shakeX = (random.nextDouble() - 0.5) * 5.0;
          shakeY = (random.nextDouble() - 0.5) * 5.0;
        }

        Widget cardFace;
        if (showBack) {
          // Spinning / Back mystery card
          cardFace = Container(
            width: 160,
            height: 240,
            decoration: BoxDecoration(
              color: isLegendary
                  ? const Color(0xFF3D3010) // Legendary mystery color
                  : const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLegendary
                    ? rarityColor.withValues(alpha: 0.8)
                    : Colors.white24,
                width: isLegendary ? 3.0 : 1.5,
              ),
              boxShadow: isLegendary
                  ? [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Motion blur lines scrolling vertically during spin
                if (_isSpinning)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          return Opacity(
                            opacity: 0.15,
                            child: Container(
                              height: 2,
                              color: isLegendary ? Colors.amber : Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                // Glowing text indicator
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentMockTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLegendary ? Colors.amberAccent : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.lock_open,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          // Revealed card
          cardFace = Transform(
            transform: Matrix4.identity()..rotateX(pi),
            alignment: Alignment.center,
            child: DraftChoiceCard(
              title: widget.title,
              description: widget.description,
              onTap: widget.onTap,
              rarity: widget.rarity,
            ),
          );
        }

        return Transform(
          transform: Matrix4.translationValues(shakeX, shakeY, 0.0)
            ..setEntry(3, 2, 0.002) // Perspective factor
            ..rotateX(angle),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              cardFace,
              // Golden burning halo sparks overlay for locked Legendary choices
              if (_isFlipped && isLegendary)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SparkPainter(
                        color: rarityColor,
                        progress: _glowController.value,
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

  _SparkPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3 + 0.5 * (1.0 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + 2.0 * progress
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Glowing border outline
    final rect = Rect.fromLTWH(-4, -4, size.width + 8, size.height + 8);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
