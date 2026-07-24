import 'package:flutter/material.dart';

class LevelUpOverlay extends StatefulWidget {
  final VoidCallback onTap;

  const LevelUpOverlay({super.key, required this.onTap});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85 * _opacityAnimation.value),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.amberAccent.withValues(alpha: 0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🎉 LEVEL UP ! 🎉',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.amber,
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Votre héros a gagné en puissance !',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'TOUCHEZ POUR OBTENIR VOS RÉCOMPENSES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
