import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data/hero_data.dart';
import '../../services/game_data_service.dart';
import '../../game/controllers/run_controller.dart';
import 'map_screen.dart';
import 'card_dictionary_screen.dart';

class ClassSelectionScreen extends ConsumerWidget {
  const ClassSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Les données sont déjà chargées par le SplashScreen
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    final classes = gameData.heroes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisissez votre Classe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Dictionnaire des cartes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CardDictionaryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400, // Largeur max d'une carte
              childAspectRatio:
                  0.75, // Ajustement de l'aspect ratio pour la verticalité
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              return _InteractiveClassCard(
                playerClass: classes[index],
                ref: ref,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InteractiveClassCard extends StatefulWidget {
  final HeroData playerClass;
  final WidgetRef ref;

  const _InteractiveClassCard({
    required this.playerClass,
    required this.ref,
  });

  @override
  State<_InteractiveClassCard> createState() => _InteractiveClassCardState();
}

class _InteractiveClassCardState extends State<_InteractiveClassCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // For float/breath animation of icon
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event, Size cardSize) {
    if (cardSize.width == 0 || cardSize.height == 0) return;
    
    // Relative position from center (-0.5 to 0.5)
    final double relX = (event.localPosition.dx / cardSize.width) - 0.5;
    final double relY = (event.localPosition.dy / cardSize.height) - 0.5;

    setState(() {
      // Limit tilt angle (approx 0.15 radians max)
      _tiltX = relX * 0.3;
      _tiltY = relY * 0.3;
    });
  }

  void _onPointerExit() {
    setState(() {
      _isHovered = false;
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  void _onPointerEnter() {
    setState(() {
      _isHovered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerClass = widget.playerClass;
    
    Color classColor = Colors.blue;
    if (playerClass.id == 'berserker') classColor = Colors.red;
    if (playerClass.id == 'mage') classColor = Colors.purple;

    IconData icon = Icons.person;
    if (playerClass.id == 'paladin') icon = Icons.shield;
    if (playerClass.id == 'berserker') icon = Icons.whatshot;
    if (playerClass.id == 'mage') icon = Icons.auto_fix_high;

    String traitName = 'Aucun trait';
    String traitDesc = '';
    switch (playerClass.passiveTrait) {
      case 'regenArmor':
        traitName = 'Régénération d\'Armure';
        traitDesc = 'Gagne 2 d\'Armure à la fin du tour';
        break;
      case 'berserkerArmor':
        traitName = 'Armure du Berserker';
        traitDesc = 'Gagne 1 d\'Armure par tranche de 10 PV manquants (au début du tour)';
        break;
      case 'spellArmor':
        traitName = 'Armure Magique';
        traitDesc = 'Gagne 1 d\'Armure en jouant une carte Compétence';
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onEnter: (_) => _onPointerEnter(),
          onExit: (_) => _onPointerExit(),
          child: Listener(
            onPointerMove: (e) => _onPointerMove(e, cardSize),
            onPointerHover: (e) => _onPointerMove(e, cardSize),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0.0, end: _isHovered ? 1.0 : 0.0),
              builder: (context, hoverVal, child) {
                // Interpolate rotation to standard or tilt value
                final double currentTiltX = _tiltX * hoverVal;
                final double currentTiltY = _tiltY * hoverVal;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective 3D
                    ..rotateX(-currentTiltY) // Inverser pour que ça penche vers le curseur
                    ..rotateY(currentTiltX),
                  alignment: FractionalOffset.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: classColor.withValues(alpha: _isHovered ? 1.0 : 0.7),
                        width: _isHovered ? 3.0 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: classColor.withValues(alpha: _isHovered ? 0.4 : 0.15),
                          blurRadius: _isHovered ? 25 : 10,
                          spreadRadius: _isHovered ? 4 : 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // Floating hero icon
                            AnimatedBuilder(
                              animation: _floatAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: Icon(
                                    icon,
                                    size: 65,
                                    color: classColor,
                                    shadows: [
                                      Shadow(
                                        color: classColor.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 15),
                            Text(
                              playerClass.name,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: classColor,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: classColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Stats with beautiful icons and display
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatBadge(Icons.favorite, '${playerClass.maxHp}', Colors.redAccent),
                                  Container(width: 1, height: 16, color: Colors.white24),
                                  _buildStatBadge(Icons.bolt, '${playerClass.maxMana}', Colors.purpleAccent),
                                  Container(width: 1, height: 16, color: Colors.white24),
                                  _buildStatBadge(Icons.flash_on, '${playerClass.baseDamage}', Colors.orangeAccent),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Passive trait
                            Tooltip(
                              message: traitDesc,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.shield, size: 16, color: Colors.cyanAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      traitName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white12, height: 25),
                            // Description text
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  playerClass.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Premium Selection Button
                            _PremiumSelectionButton(
                              classColor: classColor,
                              onPressed: () {
                                widget.ref.read(runProvider.notifier).startNewRun(playerClass);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const MapScreen()),
                                  (route) => route.isFirst,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PremiumSelectionButton extends StatefulWidget {
  final Color classColor;
  final VoidCallback onPressed;

  const _PremiumSelectionButton({
    required this.classColor,
    required this.onPressed,
  });

  @override
  State<_PremiumSelectionButton> createState() => _PremiumSelectionButtonState();
}

class _PremiumSelectionButtonState extends State<_PremiumSelectionButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        widget.classColor,
        widget.classColor.withBlue(255).withGreen(100),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedScale(
          scale: _isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.classColor.withValues(alpha: _isHovered ? 0.5 : 0.25),
                    blurRadius: _isHovered ? 15 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Sélectionner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
