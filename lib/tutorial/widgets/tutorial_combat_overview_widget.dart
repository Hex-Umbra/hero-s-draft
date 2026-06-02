import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialCombatOverviewWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialCombatOverviewWidget({super.key, required this.engine});

  @override
  State<TutorialCombatOverviewWidget> createState() =>
      _TutorialCombatOverviewWidgetState();
}

class _TutorialCombatOverviewWidgetState
    extends State<TutorialCombatOverviewWidget> {
  bool _showEnemyLabel = false;
  bool _showHeroLabel = false;
  bool _showHandLabel = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showEnemyLabel = true);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showHeroLabel = true);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showHandLabel = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 250,
          child: Stack(
            children: [
              // Subtly simulated dungeon grid background
              Positioned.fill(
                child: CustomPaint(painter: DungeonBackgroundPainter()),
              ),

              // Act & Level header indicator
              Positioned(
                top: 8,
                left: 12,
                child: Text(
                  isFrench ? 'Acte 1 - Niveau : 1' : 'Act 1 - Level: 1',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Main Layout Grid
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 22,
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Player effects & Draw pile
                    Expanded(flex: 3, child: _buildLeftPanel(isFrench)),

                    // Center Column: Enemy Card (top), Hero Card (bottom), Hand & Mana (lowest)
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Enemy Zone Card
                          _buildEnemyCard(isFrench),

                          // Hero Zone Card
                          _buildHeroCard(isFrench),

                          // Player Hand, Mana, and HP bar
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFannedHand(),
                              const SizedBox(height: 2),
                              _buildManaCrystals(),
                              const SizedBox(height: 2),
                              _buildHealthBar(isFrench),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right Column: End Turn, Tour count, Enemy Intentions & Discard pile
                    Expanded(flex: 3, child: _buildRightPanel(isFrench)),
                  ],
                ),
              ),

              // Floating Annotation Labels
              // Label 1: Enemy zone (Top Center)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                top: _showEnemyLabel ? 55 : 40,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _showEnemyLabel ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildAnnotationBubble(
                    text: isFrench
                        ? '1. L\'Ennemi est en haut. Ses intentions et actions sont détaillées à droite.'
                        : '1. The Enemy is at the top. Their actions and intent are detailed on the right.',
                    color: Colors.redAccent,
                  ),
                ),
              ),

              // Label 2: Hero card, Hand, and HP (Center/Bottom Center)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                top: _showHeroLabel ? 115 : 100,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _showHeroLabel ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildAnnotationBubble(
                    text: isFrench
                        ? '2. Votre Héros est en bas. Vos cartes, cristaux de Mana et PV sont juste en dessous.'
                        : '2. Your Hero is below. Your cards, Mana crystals, and HP bar are directly under.',
                    color: Colors.blueAccent,
                  ),
                ),
              ),

              // Label 3: Side Panels (Left & Right Column Elements)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                bottom: _showHandLabel ? 80 : 65,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _showHandLabel ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildAnnotationBubble(
                    text: isFrench
                        ? '3. Les côtés gèrent les effets (gauche), la pioche/défausse et le bouton Fin de Tour (droite).'
                        : '3. Side columns manage status effects (left), piles, and the End Turn button (right).',
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(bool isFrench) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // EFFETS DU JOUEUR card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFrench ? '🔵 EFFETS DU JOUEUR' : '🔵 PLAYER EFFECTS',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 6.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isFrench ? 'Aucun effet actif' : 'No active effects',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 6),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Pioche Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: Text(
            isFrench ? 'Pioche: 2' : 'Draw: 2',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 6.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(bool isFrench) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Fin de Tour Button & Tour 1 Count
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 3),
                ],
              ),
              child: Text(
                isFrench ? '✓ Fin de Tour' : '✓ End Turn',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isFrench ? 'Tour 1' : 'Turn 1',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 6.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        // INTENTIONS ENNEMIES card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFrench ? '👁 INTENTIONS ENNEMIES' : '👁 ENEMY INTENTIONS',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 6.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isFrench ? 'Gobelin (Niv. 1)' : 'Goblin (Lvl. 1)',
                style: const TextStyle(color: Colors.white70, fontSize: 6),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on, color: Colors.amber, size: 7),
                  const SizedBox(width: 1),
                  Text(
                    isFrench ? 'Attaque Rapide : 5' : 'Quick Attack: 5',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Défausse Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: Text(
            isFrench ? 'Défausse: 0' : 'Discard: 0',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 6.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnemyCard(bool isFrench) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Health Bar & Stats above enemy card
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on, color: Colors.redAccent, size: 8),
            const Text(
              '5',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.shield, color: Colors.blueAccent, size: 8),
            const Text(
              '0',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '28/28',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Card Body
        Container(
          width: 42,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.greenAccent.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pest_control,
                color: Colors.greenAccent,
                size: 18,
              ),
              const SizedBox(height: 1),
              Text(
                isFrench ? 'Gobelin' : 'Goblin',
                style: TextStyle(
                  color: Colors.greenAccent.shade100,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isFrench) {
    return Container(
      width: 42,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield, color: Colors.amber, size: 18),
          const SizedBox(height: 1),
          Text(
            isFrench ? 'Héros' : 'Hero',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFannedHand() {
    final List<String> cardNames = [
      'Frappe',
      'Rage',
      'Téméraire',
      'Feu',
      'Frappe',
    ];
    final List<Color> cardColors = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.redAccent,
    ];

    return SizedBox(
      height: 38,
      width: 140,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(5, (index) {
          final double rotation = (index - 2) * 0.08;
          final double translationX = (index - 2) * 15.0;
          final double translationY = (index - 2).abs() * 1.5;

          return Transform.translate(
            offset: Offset(translationX, translationY),
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: 24,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A40),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: cardColors[index].withOpacity(0.6),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 1.5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    cardNames[index],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 4.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildManaCrystals() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(Icons.diamond, color: Colors.cyanAccent, size: 9),
        );
      }),
    );
  }

  Widget _buildHealthBar(bool isFrench) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flash_on, color: Colors.redAccent, size: 7),
        const Text(
          '0',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(Icons.shield, color: Colors.blueAccent, size: 7),
        const Text(
          '0',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 76,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.greenAccent.withOpacity(0.2),
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Center(
                child: Text(
                  isFrench ? '80 / 80 PV' : '80 / 80 HP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 5.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnotationBubble({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 9, height: 1.2),
      ),
    );
  }
}

class DungeonBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fill background with subtle dark color
    final bgPaint = Paint()..color = const Color(0xFF0B0F19);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.15)
      ..strokeWidth = 1.0;

    const double step = 30.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
