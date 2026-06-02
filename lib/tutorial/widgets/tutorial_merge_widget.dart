import 'package:flutter/material.dart';
import '../tutorial_engine.dart';
import 'tutorial_cards_widget.dart'; // Reuses TutorialUiCard

class TutorialMergeWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialMergeWidget({super.key, required this.engine});

  @override
  State<TutorialMergeWidget> createState() => _TutorialMergeWidgetState();
}

class _TutorialMergeWidgetState extends State<TutorialMergeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  bool _isMerged = false;
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    widget.engine.resetMockState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInQuad,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFlash = true;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() {
            _showFlash = false;
            _isMerged = true;
          });
          widget.engine.mergeCards();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runMerge() {
    if (_isMerged || _controller.isAnimating) return;
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          height: 240,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_isMerged) ...[
                        // Left Card
                        AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_slideAnimation.value * 85, 0),
                              child: child,
                            );
                          },
                          child: Opacity(
                            opacity: 1.0 - _controller.value * 0.5,
                            child: const SizedBox(
                              width: 80,
                              child: TutorialUiCard(
                                title: 'Frappe',
                                description: 'Lvl 1',
                                cost: 1,
                                type: 'attack',
                                isSelected: false,
                                onTap: _dummyTap,
                              ),
                            ),
                          ),
                        ),

                        // Right Card
                        AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(-_slideAnimation.value * 85, 0),
                              child: child,
                            );
                          },
                          child: Opacity(
                            opacity: 1.0 - _controller.value * 0.5,
                            child: const SizedBox(
                              width: 80,
                              child: TutorialUiCard(
                                title: 'Frappe',
                                description: 'Lvl 1',
                                cost: 1,
                                type: 'attack',
                                isSelected: false,
                                onTap: _dummyTap,
                              ),
                            ),
                          ),
                        ),

                        // Center Card
                        Opacity(
                          opacity: 1.0 - _controller.value * 0.2,
                          child: const SizedBox(
                            width: 80,
                            child: TutorialUiCard(
                              title: 'Frappe',
                              description: 'Lvl 1',
                              cost: 1,
                              type: 'attack',
                              isSelected: false,
                              onTap: _dummyTap,
                            ),
                          ),
                        ),
                      ],

                      // Upgraded Merge Result Card
                      if (_isMerged)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1.1),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (context, val, child) {
                            return Transform.scale(scale: val, child: child);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            width: 95,
                            child: TutorialUiCard(
                              title: isFrench ? 'Frappe Niv.2' : 'Strike Lvl 2',
                              description: isFrench
                                  ? 'Inflige 9 dégâts.'
                                  : 'Deals 9 damage.',
                              cost: 1,
                              type: 'attack',
                              isSelected: true,
                              onTap: _dummyTap,
                            ),
                          ),
                        ),

                      // Flash Screen Effect
                      if (_showFlash)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Button
                if (!_isMerged)
                  InkWell(
                    onTap: _runMerge,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        isFrench ? 'Fusionner 🔮' : 'Merge 🔮',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    isFrench ? 'Fusion Complétée ! ✨' : 'Merge Complete! ✨',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _dummyTap() {}
}
