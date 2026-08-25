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
    final heroStats = widget.engine.mockState.heroStats;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double scaleHeight = constraints.maxHeight / 350.0;
          final double scaleWidth = constraints.maxWidth / 500.0;
          final double scale = (scaleHeight < scaleWidth ? scaleHeight : scaleWidth).clamp(0.65, 1.4);

          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final double colWidth = (width - 24 * scale) * 3.0 / 11.0;

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // Subtly simulated dungeon grid background
                Positioned.fill(
                  child: CustomPaint(painter: DungeonBackgroundPainter()),
                ),

                // Act & Level header indicator
                Positioned(
                  top: 8 * scale,
                  left: 12 * scale,
                  child: Text(
                    isFrench ? 'Acte 1 - Niveau : 1' : 'Act 1 - Level: 1',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Boutons Mon Deck & Pause (Haut Droit), comme CombatTopBar
                Positioned(
                  top: 6 * scale,
                  right: 8 * scale,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.style, color: Colors.amber, size: 16 * scale),
                      SizedBox(width: 8 * scale),
                      Icon(
                        Icons.pause_circle_outline,
                        color: Colors.white,
                        size: 16 * scale,
                      ),
                    ],
                  ),
                ),

                // Main Layout Grid
                Padding(
                  padding: EdgeInsets.only(
                    left: 12 * scale,
                    right: 12 * scale,
                    top: 30 * scale,
                    bottom: 8 * scale,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Column: Player effects & Draw pile
                      Expanded(flex: 3, child: _buildLeftPanel(isFrench, scale)),

                      // Center Column: Enemy Card (top), Hero Card (bottom), Hand & Mana (lowest)
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Enemy Zone Card
                            _buildEnemyCard(isFrench, scale),

                            // Hero Zone Card
                            _buildHeroCard(isFrench, scale),

                            // Player Hand, Mana, and HP bar
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFannedHand(scale),
                                SizedBox(height: 2 * scale),
                                _buildManaCrystals(scale),
                                SizedBox(height: 2 * scale),
                                _buildHealthBar(
                                  isFrench,
                                  scale,
                                  heroStats.currentPv,
                                  heroStats.maxPv,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right Column: End Turn, Tour count, Enemy Intentions & Discard pile
                      Expanded(flex: 3, child: _buildRightPanel(isFrench, scale)),
                    ],
                  ),
                ),

                // Floating Annotation Labels
                // Label 1: Enemy zone (Top Left, aligned to left panel)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  top: _showEnemyLabel ? 100 * scale : 90 * scale,
                  left: 12 * scale,
                  width: colWidth,
                  child: AnimatedOpacity(
                    opacity: _showEnemyLabel ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildAnnotationBubble(
                      text: isFrench
                          ? '1. L\'Ennemi est en haut. Ses intentions et actions sont détaillées à droite.'
                          : '1. The Enemy is at the top. Their actions and intent are detailed on the right.',
                      color: Colors.redAccent,
                      scale: scale,
                    ),
                  ),
                ),

                // Label 2: Hero card, Hand, and HP (Lower Left, aligned to left panel)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  top: _showHeroLabel ? 175 * scale : 165 * scale,
                  left: 12 * scale,
                  width: colWidth,
                  child: AnimatedOpacity(
                    opacity: _showHeroLabel ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildAnnotationBubble(
                      text: isFrench
                          ? '2. Votre Héros est en bas. Vos cartes, cristaux de Mana et PV sont juste en dessous.'
                          : '2. Your Hero is below. Your cards, Mana crystals, and HP bar are directly under.',
                      color: Colors.blueAccent,
                      scale: scale,
                    ),
                  ),
                ),

                // Label 3: Side Panels (Lower Right, aligned to right panel)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  top: _showHandLabel ? 180 * scale : 170 * scale,
                  right: 12 * scale,
                  width: colWidth,
                  child: AnimatedOpacity(
                    opacity: _showHandLabel ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildAnnotationBubble(
                      text: isFrench
                          ? '3. Les côtés gèrent les effets (gauche), la pioche/défausse et le bouton Fin de Tour (droite).'
                          : '3. Side columns manage status effects (left), piles, and the End Turn button (right).',
                      color: Colors.amber,
                      scale: scale,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftPanel(bool isFrench, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // EFFETS DU JOUEUR card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6 * scale),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFrench ? '🔵 EFFETS DU JOUEUR' : '🔵 PLAYER EFFECTS',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5 * scale),
              Text(
                isFrench ? 'Aucun effet actif' : 'No active effects',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 8.5 * scale),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Pioche Button
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4 * scale),
            border: Border.all(color: Colors.white24, width: 0.8 * scale),
          ),
          child: Text(
            isFrench ? 'Pioche: 2' : 'Draw: 2',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.5 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(bool isFrench, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sur le vrai écran de combat, le bouton Fin de Tour et le compteur
        // de tour sont ancrés au centre vertical du bord droit
        // (TurnControlPanel, `top: screenHeight / 2 - 25`), pas en haut :
        // les deux Spacer() qui encadrent ce bloc reproduisent ce centrage.
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10 * scale),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 3 * scale),
                ],
              ),
              child: Text(
                isFrench ? '✓ Fin de Tour' : '✓ End Turn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              isFrench ? 'Tour 1' : 'Turn 1',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 9.5 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        // INTENTIONS ENNEMIES card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6 * scale),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFrench ? '👁 INTENTIONS ENNEMIES' : '👁 ENEMY INTENTIONS',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                isFrench ? 'Gobelin (Niv. 1)' : 'Goblin (Lvl. 1)',
                style: TextStyle(color: Colors.white70, fontSize: 8.5 * scale),
              ),
              SizedBox(height: 2 * scale),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, color: Colors.amber, size: 10 * scale),
                  SizedBox(width: 2 * scale),
                  // La colonne qui contient cette maquette a une largeur
                  // derivee du viewport : sans `Flexible`, « Attaque Rapide :
                  // 5 » deborde de la `Row` et Flutter peint la bande
                  // d'erreur jaune et noire a la place, en plein tutoriel.
                  //
                  // Troisieme occurrence du meme motif, apres
                  // `EnemyIntentsPanel` (PR #28) et `StatusEffectsPanel` :
                  // une `Icon` et un `Text` sans contrainte dans une `Row`
                  // de largeur bornee. Meme correctif, meme repli sur
                  // plusieurs lignes plutot qu'une troncature — la valeur
                  // chiffree est en fin de libelle.
                  Flexible(
                    child: Text(
                      isFrench ? 'Attaque Rapide : 5' : 'Quick Attack: 5',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 8.5 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),
        // Défausse Button
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4 * scale),
            border: Border.all(color: Colors.white24, width: 0.8 * scale),
          ),
          child: Text(
            isFrench ? 'Défausse: 0' : 'Discard: 0',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.5 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnemyCard(bool isFrench, double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Health Bar & Stats above enemy card
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on, color: Colors.redAccent, size: 10 * scale),
            Text(
              '5',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 6 * scale),
            Icon(Icons.shield, color: Colors.blueAccent, size: 10 * scale),
            Text(
              '0',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8 * scale),
            Container(
              width: 50 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(3 * scale),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 50 * scale,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(3 * scale),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6 * scale),
            Text(
              '28/28',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * scale),
        // Card Body
        Container(
          width: 54 * scale,
          height: 76 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(5 * scale),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.4),
              width: 1.2 * scale,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pest_control,
                color: Colors.greenAccent,
                size: 22 * scale,
              ),
              SizedBox(height: 2 * scale),
              Text(
                isFrench ? 'Gobelin' : 'Goblin',
                style: TextStyle(
                  color: Colors.greenAccent.shade100,
                  fontSize: 9 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isFrench, double scale) {
    return Container(
      width: 54 * scale,
      height: 76 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(5 * scale),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.2 * scale),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield, color: Colors.amber, size: 22 * scale),
          SizedBox(height: 2 * scale),
          Text(
            isFrench ? 'Héros' : 'Hero',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 9 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFannedHand(double scale) {
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
      height: 48 * scale,
      width: 160 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(5, (index) {
          final double rotation = (index - 2) * 0.08;
          final double translationX = (index - 2) * 16.0 * scale;
          final double translationY = (index - 2).abs() * 2.0 * scale;

          return Transform.translate(
            offset: Offset(translationX, translationY),
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: 28 * scale,
                height: 40 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A40),
                  borderRadius: BorderRadius.circular(3 * scale),
                  border: Border.all(
                    color: cardColors[index].withValues(alpha: 0.6),
                    width: 0.8 * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 1.5 * scale,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    cardNames[index],
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 6.5 * scale,
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

  Widget _buildManaCrystals(double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0 * scale),
          child: Icon(Icons.diamond, color: Colors.cyanAccent, size: 14 * scale),
        );
      }),
    );
  }

  Widget _buildHealthBar(
    bool isFrench,
    double scale,
    int currentPv,
    int maxPv,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flash_on, color: Colors.redAccent, size: 10 * scale),
        Text(
          '0',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 10 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4 * scale),
        Icon(Icons.shield, color: Colors.blueAccent, size: 10 * scale),
        Text(
          '0',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 10 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 6 * scale),
        Container(
          width: 110 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4 * scale),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.2),
              width: 0.8 * scale,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4 * scale),
                ),
              ),
              Center(
                child: Text(
                  isFrench ? '$currentPv / $maxPv PV' : '$currentPv / $maxPv HP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9 * scale,
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

  Widget _buildAnnotationBubble({required String text, required Color color, required double scale}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: color, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3 * scale,
            offset: Offset(0, 1.5 * scale),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: (12 * scale).clamp(9.0, 14.0),
          height: 1.25,
        ),
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
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.15)
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

