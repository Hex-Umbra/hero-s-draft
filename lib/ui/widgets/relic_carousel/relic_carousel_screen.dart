import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/data/relic_data.dart';
import 'relic_carousel_card.dart';

class RelicCarouselScreen extends StatefulWidget {
  final List<RelicData> relicPool;
  final RelicData wonRelic;
  final VoidCallback onCollect;
  final VoidCallback? onTick;
  final VoidCallback? onLand;

  const RelicCarouselScreen({
    super.key,
    required this.relicPool,
    required this.wonRelic,
    required this.onCollect,
    this.onTick,
    this.onLand,
  });

  @override
  State<RelicCarouselScreen> createState() => _RelicCarouselScreenState();
}

class _RelicCarouselScreenState extends State<RelicCarouselScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late List<RelicData> _carouselItems;
  final int _targetIndex = 22; // Index where the winning relic will sit
  int _focusedIndex = 0;
  bool _isWon = false;
  int _lastTickedPage = 0;
  AnimationController? _particleAnimationController;
  List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _particleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addListener(() {
        setState(() {});
      });

    // Generate pool of relics excluding the winning one to avoid premature duplication during spin
    final otherRelics = widget.relicPool
        .where((r) => r.id != widget.wonRelic.id)
        .toList();
    final random = Random();

    // Populate carousel items
    _carouselItems = List.generate(_targetIndex + 4, (index) {
      if (index == _targetIndex) {
        return widget.wonRelic;
      }
      // Fill others randomly
      final source = otherRelics.isNotEmpty ? otherRelics : widget.relicPool;
      return source[random.nextInt(source.length)];
    });

    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.45, // Crucial for displaying 3 cards side-by-side
    );

    _pageController.addListener(_onScroll);

    // Trigger the auto-spin after building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSpin();
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final page = _pageController.page;
    if (page != null) {
      final intPage = page.round();
      if (intPage != _lastTickedPage && intPage <= _targetIndex) {
        _lastTickedPage = intPage;
        // Trigger tick sound hook!
        widget.onTick?.call();
        // Log it to confirm hook execution
        debugPrint('🎵 Relic Carousel Hook: onTick (index: $intPage)');
      }
      if (intPage != _focusedIndex) {
        setState(() {
          _focusedIndex = intPage;
        });
      }
    }
  }

  void _startSpin() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _pageController
          .animateToPage(
            _targetIndex,
            duration: const Duration(milliseconds: 4000),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (mounted) {
              final random = Random();
              setState(() {
                _isWon = true;
                _particles = List.generate(55, (index) {
                  final angle = random.nextDouble() * 2 * pi;
                  final speed = 150.0 + random.nextDouble() * 350.0;
                  final size = 3.0 + random.nextDouble() * 5.0;
                  final initialOpacity = 0.6 + random.nextDouble() * 0.4;
                  return _Particle(
                    angle: angle,
                    speed: speed,
                    size: size,
                    initialOpacity: initialOpacity,
                  );
                });
              });
              _particleAnimationController?.forward(from: 0.0);
              // Trigger land sound hook!
              widget.onLand?.call();
              debugPrint('🎉 Relic Carousel Hook: onLand (Winner locked!)');
            }
          });
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _particleAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    Color rarityColor = Colors.grey;
    String rarityText = l10n.rarityCommon;
    switch (widget.wonRelic.rarity) {
      case RelicRarity.common:
        rarityColor = const Color(0xFF8E8E93);
        rarityText = l10n.rarityCommon;
        break;
      case RelicRarity.uncommon:
        rarityColor = const Color(0xFF34C759);
        rarityText = l10n.rarityUncommon;
        break;
      case RelicRarity.rare:
        rarityColor = const Color(0xFF007AFF);
        rarityText = l10n.rarityRare;
        break;
      case RelicRarity.epic:
        rarityColor = const Color(0xFFAF52DE);
        rarityText = l10n.rarityEpic;
        break;
      case RelicRarity.legendary:
        rarityColor = const Color(0xFFFFCC00);
        rarityText = l10n.rarityLegendary;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Blur & Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.85)),
          ),

          // Core UI Container
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              // Header
              Column(
                children: [
                  Text(
                    locale == 'fr' ? 'RÉCOMPENSE DE RELIQUE' : 'RELIC REWARD',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _isWon ? 1.0 : 0.0,
                    child: Text(
                      rarityText.toUpperCase(),
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        shadows: [
                          Shadow(
                            color: rarityColor.withValues(alpha: 0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Carousel
              SizedBox(
                height: 350,
                child: PageView.builder(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Managed only by script
                  itemCount: _carouselItems.length,
                  itemBuilder: (context, index) {
                    final relic = _carouselItems[index];
                    final isFocused = index == _focusedIndex;
                    return RelicCarouselCard(
                      relic: relic,
                      isFocused: isFocused,
                      isWon: _isWon && isFocused,
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Bottom Button (Collect)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isWon ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 500),
                  scale: _isWon ? 1.0 : 0.7,
                  curve: Curves.elasticOut,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rarityColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: rarityColor.withValues(alpha: 0.4),
                    ),
                    onPressed: _isWon ? widget.onCollect : null,
                    child: Text(
                      locale == 'fr' ? '✨ RÉCUPÉRER ✨' : '✨ COLLECT ✨',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Particle overlay when winning
          if (_isWon)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  color: rarityColor,
                  particles: _particles,
                  progress: _particleAnimationController?.value ?? 0.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Color color;
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.color,
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var particle in particles) {
      particle.draw(canvas, center, progress, color);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.particles != particles;
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double initialOpacity;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.initialOpacity,
  });

  void draw(Canvas canvas, Offset center, double progress, Color baseColor) {
    // Apply drag to radial speed
    // progress goes from 0.0 to 1.0
    // Distance from center:
    final double distance = speed * progress * (1.0 - 0.5 * progress);
    
    // Gravity pulls downwards
    final double gravity = 250.0;
    final double gravityY = gravity * progress * progress;
    
    final double x = cos(angle) * distance;
    final double y = sin(angle) * distance + gravityY;
    
    // Fade opacity to 0
    final double currentOpacity = (initialOpacity * (1.0 - progress)).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = baseColor.withValues(alpha: currentOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(center + Offset(x, y), size, paint);
  }
}
