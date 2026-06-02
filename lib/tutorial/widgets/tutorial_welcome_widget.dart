import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialWelcomeWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialWelcomeWidget({super.key, required this.engine});

  @override
  State<TutorialWelcomeWidget> createState() => _TutorialWelcomeWidgetState();
}

class _TutorialWelcomeWidgetState extends State<TutorialWelcomeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animation.value),
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x22F59E0B), Colors.transparent],
                    radius: 0.6,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_motion,
                  size: 80,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'HERO\'S DRAFT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  shadows: [
                    Shadow(
                      color: Color(0x88F59E0B),
                      blurRadius: 15,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFrench
                    ? 'Préparez votre deck. Affrontez votre destin.'
                    : 'Prepare your deck. Draft your destiny.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

