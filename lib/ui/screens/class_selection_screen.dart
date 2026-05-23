import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data/hero_data.dart';
import '../../services/game_data_service.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import 'map_screen.dart';
import 'card_dictionary_screen.dart';
import '../widgets/sword_icon.dart';
import '../../models/data/passive_data.dart';

class ClassSelectionScreen extends ConsumerWidget {
  const ClassSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Les données sont déjà chargées par le SplashScreen
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    final classes = gameData.heroes;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

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
          padding: EdgeInsets.all(isMobile ? 10 : 20),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isMobile ? 200 : 400, // Divise par deux sur mobile pour afficher 2 colonnes réduites
              childAspectRatio: isMobile ? 0.68 : 0.75, // Plus haute sur mobile pour donner plus d'espace vertical
              crossAxisSpacing: isMobile ? 10 : 20,
              mainAxisSpacing: isMobile ? 10 : 20,
            ),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              return _InteractiveClassCard(
                playerClass: classes[index],
                ref: ref,
                isMobile: isMobile,
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
  final bool isMobile;

  const _InteractiveClassCard({
    required this.playerClass,
    required this.ref,
    required this.isMobile,
  });

  @override
  State<_InteractiveClassCard> createState() => _InteractiveClassCardState();
}

class _InteractiveClassCardState extends State<_InteractiveClassCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  Offset? _mousePosition;

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
      // Limit tilt angle (approx 0.025 radians max)
      _tiltX = relX * 0.05;
      _tiltY = relY * 0.05;
      _mousePosition = event.localPosition;
    });
  }

  void _onPointerExit() {
    setState(() {
      _isHovered = false;
      _tiltX = 0.0;
      _tiltY = 0.0;
      _mousePosition = null;
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
    final gameData = widget.ref.watch(gameDataLoaderProvider).requireValue;
    final passive = gameData.passives.firstWhere(
      (p) => p.id == playerClass.passiveTrait,
      orElse: () => PassiveData.fallback(playerClass.passiveTrait ?? ''),
    );
    
    Color classColor = Colors.blue;
    if (playerClass.id == 'berserker') classColor = Colors.red;
    if (playerClass.id == 'mage') classColor = Colors.purple;

    IconData icon = Icons.person;
    if (playerClass.id == 'paladin') icon = Icons.shield;
    if (playerClass.id == 'berserker') icon = Icons.whatshot;
    if (playerClass.id == 'mage') icon = Icons.auto_fix_high;

    final String traitName = passive.name;
    final String traitDesc = passive.description;

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
                    ..rotateX(currentTiltY) // Inversé : le côté avec le curseur s'éloigne (tilt vers l'arrière)
                    ..rotateY(-currentTiltX),
                  alignment: Alignment.center,
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
                      child: Stack(
                        children: [
                          if (_isHovered && _mousePosition != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment(
                                        (_mousePosition!.dx / cardSize.width) * 2 - 1,
                                        (_mousePosition!.dy / cardSize.height) * 2 - 1,
                                      ),
                                      radius: 0.6,
                                      colors: [
                                        classColor.withValues(alpha: 0.12),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.all(widget.isMobile ? 8 : 20),
                            child: Column(
                              children: [
                                SizedBox(height: widget.isMobile ? 3 : 10),
                                // Floating hero icon
                                AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) {
                                    final double floatOffset = _floatAnimation.value * (widget.isMobile ? 0.5 : 1.0);
                                    return Transform.translate(
                                      offset: Offset(0, floatOffset),
                                      child: Icon(
                                        icon,
                                        size: widget.isMobile ? 48 : 65,
                                        color: classColor,
                                        shadows: [
                                          Shadow(
                                            color: classColor.withValues(alpha: 0.5),
                                            blurRadius: widget.isMobile ? 5 : 10,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: widget.isMobile ? 4 : 15),
                                Text(
                                  playerClass.name,
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 20 : 26,
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
                                SizedBox(height: widget.isMobile ? 4 : 12),
                                // Stats with beautiful icons and display
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 4 : 12,
                                    vertical: widget.isMobile ? 4 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(widget.isMobile ? 6 : 10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatBadge(
                                        Icon(Icons.favorite, size: widget.isMobile ? 14 : 16, color: Colors.redAccent),
                                        '${playerClass.maxHp}',
                                      ),
                                      Container(width: 1, height: widget.isMobile ? 12 : 16, color: Colors.white24),
                                      _buildStatBadge(
                                        Icon(Icons.diamond_rounded, size: widget.isMobile ? 14 : 16, color: Colors.cyanAccent),
                                        '${playerClass.maxMana}',
                                      ),
                                      Container(width: 1, height: widget.isMobile ? 12 : 16, color: Colors.white24),
                                      _buildStatBadge(
                                        SwordIcon(size: widget.isMobile ? 14 : 16, color: Colors.orangeAccent),
                                        '${playerClass.baseDamage}',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 4 : 15),
                                // Passive trait
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 4 : 12,
                                    vertical: widget.isMobile ? 4 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(widget.isMobile ? 6 : 10),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withValues(alpha: 0.25),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shield, size: widget.isMobile ? 12 : 16, color: Colors.cyanAccent),
                                          SizedBox(width: widget.isMobile ? 3 : 6),
                                          Text(
                                            traitName.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: widget.isMobile ? 10 : 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.cyanAccent,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: widget.isMobile ? 2 : 5),
                                      Text(
                                        traitDesc,
                                        style: TextStyle(
                                          fontSize: widget.isMobile ? 9.5 : 10.5,
                                          color: Colors.cyanAccent.withValues(alpha: 0.85),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  color: Colors.white12,
                                  height: widget.isMobile ? 8 : 25,
                                ),
                                // Description text
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      playerClass.description,
                                      style: TextStyle(
                                        fontSize: widget.isMobile ? 11.5 : 13,
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 4 : 15),
                                // Premium Selection Button
                                _PremiumSelectionButton(
                                  classColor: classColor,
                                  isMobile: widget.isMobile,
                                  onPressed: () {
                                    widget.ref.read(deckProvider.notifier).clearDeck();
                                    widget.ref.read(runProvider.notifier).startNewRun(playerClass, passive);
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const MapScreen()),
                                      (route) => route.isFirst,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildStatBadge(Widget iconWidget, String value) {
    final bool isMobile = widget.isMobile;
    return Row(
      children: [
        iconWidget,
        SizedBox(width: isMobile ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
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
  final bool isMobile;

  const _PremiumSelectionButton({
    required this.classColor,
    required this.onPressed,
    required this.isMobile,
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
    final LinearGradient gradient = widget.classColor == Colors.blue
        ? const LinearGradient(
            colors: [
              Color(0xFF0D47A1), // Bleu marine profond
              Color(0xFF00B0FF), // Bleu azur/cyan éclatant
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
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
              height: widget.isMobile ? 38 : 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                boxShadow: [
                  BoxShadow(
                    color: widget.classColor.withValues(alpha: _isHovered ? 0.5 : 0.25),
                    blurRadius: _isHovered ? 15 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Sélectionner',
                  style: TextStyle(
                    fontSize: widget.isMobile ? 14 : 16,
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
