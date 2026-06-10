import 'package:flutter/material.dart';
import '../sword_icon.dart';

class PlayerHealthBar extends StatefulWidget {
  final int currentPv;
  final int maxPv;
  final int armure;
  final int effectiveAttaque;

  const PlayerHealthBar({
    super.key,
    required this.currentPv,
    required this.maxPv,
    required this.armure,
    required this.effectiveAttaque,
  });

  @override
  State<PlayerHealthBar> createState() => _PlayerHealthBarState();
}

class _PlayerHealthBarState extends State<PlayerHealthBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late double _greenStart;
  late double _greenEnd;
  late double _catchUpStart;
  late double _catchUpEnd;

  @override
  void initState() {
    super.initState();
    _greenStart = widget.currentPv.toDouble();
    _greenEnd = widget.currentPv.toDouble();
    _catchUpStart = widget.currentPv.toDouble();
    _catchUpEnd = widget.currentPv.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get currentGreen {
    return _greenStart + (_greenEnd - _greenStart) * _animation.value;
  }

  double get currentCatchUp {
    return _catchUpStart + (_catchUpEnd - _catchUpStart) * _animation.value;
  }

  @override
  void didUpdateWidget(covariant PlayerHealthBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPv != oldWidget.currentPv) {
      final double activeGreen = currentGreen;
      final double activeCatchUp = currentCatchUp;
      final double newPv = widget.currentPv.toDouble();

      if (newPv < activeGreen) {
        // Damage: green drops instantly, catchUp animates down
        _greenStart = newPv;
        _greenEnd = newPv;

        _catchUpStart = activeCatchUp;
        _catchUpEnd = newPv;
      } else {
        // Healing: catchUp jumps instantly, green animates up
        _catchUpStart = newPv;
        _catchUpEnd = newPv;

        _greenStart = activeGreen;
        _greenEnd = newPv;
      }
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculate adaptive values
    final double textScaleFactor = textScaler.scale(1.0);
    final double healthBarHeight = (26.0 * textScaleFactor).clamp(20.0, 40.0);
    final double healthBarWidth = (screenWidth * 0.26).clamp(120.0, 300.0);
    final double fontSize = (16.0 * textScaleFactor).clamp(12.0, 22.0);
    final double healthFontSize = (13.0 * textScaleFactor).clamp(10.0, 18.0);
    final double iconSize = (20.0 * textScaleFactor).clamp(16.0, 28.0);

    return Row(
      children: [
        // 1. Stats à gauche (alignés à droite pour s'accoler à la barre de vie)
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14.0,
              runSpacing: 4.0,
              children: [
                // Dégâts d'Attaque (Rouge Gradient, sans fond)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF2A2A), Color(0xFFFF7A7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwordIcon(size: iconSize, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.effectiveAttaque}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                ),

                // Armure (Bleu Gradient, sans fond, toujours affiché)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, color: Colors.white, size: iconSize),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.armure}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14), // Espacement avec la barre de vie

        // 2. Barre de vie progressive centrée
        SizedBox(
          width: healthBarWidth,
          child: Container(
            height: healthBarHeight,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(50), width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final double greenVal = currentGreen;
                  final double catchUpVal = currentCatchUp;

                  return Stack(
                    children: [
                      // Remplissage Catch-Up (Barre d'arrière-plan rouge/orange)
                      if (widget.maxPv > 0 && catchUpVal > 0)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (catchUpVal / widget.maxPv).clamp(0.0, 1.0),
                          heightFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3.0,
                              horizontal: 1.5,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFC0392B), // Rouge foncé
                                    Color(0xFFE74C3C), // Rouge vif
                                    Color(0xFFE67E22), // Orange
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Remplissage PV (Vert - Core interne avec padding)
                      if (widget.maxPv > 0 && greenVal > 0)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (greenVal / widget.maxPv).clamp(0.0, 1.0),
                          heightFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3.0,
                              horizontal: 1.5,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E824C), // Vert forêt foncé
                                    Color(0xFF27AE60), // Vert éclatant
                                    Color(0xFF58D68D), // Vert doux / menthe
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Remplissage Armure (Bleu Translucide - Englobant avec 0.5px de padding)
                      if (widget.armure > 0 && widget.maxPv > 0)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (widget.armure / widget.maxPv).clamp(0.0, 1.0),
                          heightFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 0.5,
                              horizontal: 0.5,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blueAccent.withValues(alpha: 0.45),
                                    Colors.lightBlueAccent.withValues(alpha: 0.65),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                                  width: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Texte des PV
                      Center(
                        child: Text(
                          '${widget.currentPv} / ${widget.maxPv} PV',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: healthFontSize,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // 3. Espaceur symétrique à droite (pour garantir le centrage parfait de la barre de vie)
        const Expanded(flex: 1, child: SizedBox()),
      ],
    );
  }
}

