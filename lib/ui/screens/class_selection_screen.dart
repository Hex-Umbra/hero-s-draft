import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/systems/passive_availability.dart';
import '../../models/data/hero_data.dart';
import '../../services/game_data_service.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import 'card_dictionary_screen.dart';
import 'starter_deck_draft_screen.dart';
import '../../models/data/model_extensions.dart';
import '../widgets/class_identity.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

class ClassSelectionScreen extends ConsumerWidget {
  const ClassSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(musicConductorProvider).onScene(MusicScene.menu);

    // Les données sont déjà chargées par le SplashScreen
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    final classes = [...gameData.heroes]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: PageHeader(
        title: l10n.selectClass,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: l10n.cardDictionary,
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
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 20),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isMobile
                ? 200
                : 400, // Divise par deux sur mobile pour afficher 2 colonnes réduites
            childAspectRatio: isMobile
                ? 0.24
                : 0.75, // Plus haute sur mobile pour donner plus d'espace vertical
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

  /// Le passif retenu, par son rang dans `availablePassivesFor` — le point
  /// d'accès unique de P-49 (spec §5.1, P5). Le premier par défaut, et le
  /// choix du joueur ensuite (spec §8.3).
  int _passiveIndex = 0;

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
    final passives = availablePassivesFor(playerClass, gameData);
    // Le rang peut sortir de la liste si la donnée change sous l'écran : on
    // retombe sur le premier plutôt que de lever.
    final index = _passiveIndex < passives.length ? _passiveIndex : 0;
    final passive = passives.isEmpty ? null : passives[index];
    final locale = Localizations.localeOf(context).languageCode;

    final classColor = ClassIdentity.colorOf(playerClass);

    // PV et mana toujours : ce sont les deux reperes que le joueur compare
    // d'une classe a l'autre. Les trois autres seulement si elles disent
    // quelque chose — « PV max et stats de depart non nulles » (spec §8.3).
    // Genere depuis la donnee : aucun `hero.id` n'est compare (ADR-090).
    final statBadges = <({Widget icon, String value})>[
      (
        icon: Icon(
          Icons.favorite,
          size: widget.isMobile ? 14 : 16,
          color: Colors.redAccent,
        ),
        value: '${playerClass.maxHp}',
      ),
      (
        icon: Icon(
          Icons.diamond_rounded,
          size: widget.isMobile ? 14 : 16,
          color: Colors.cyanAccent,
        ),
        value: '${playerClass.maxMana}',
      ),
      if (playerClass.mastery > 0)
        (
          icon: Icon(
            Icons.shield_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.lightBlueAccent,
          ),
          value: '${playerClass.mastery}',
        ),
      if (playerClass.critChance > 0)
        (
          icon: Icon(
            Icons.bolt_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.redAccent,
          ),
          value: '${playerClass.critChance}%',
        ),
      if (playerClass.luck > 0)
        (
          icon: Icon(
            Icons.casino_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.amberAccent,
          ),
          value: '${playerClass.luck}',
        ),
    ];

    final String traitDesc = passive?.getDescription(locale) ?? '';
    // Ce qu'un point de Maîtrise apporte au passif (spec P-49, §6.5).
    final String? masteryPerPoint = passive?.mastery?.describe(locale, 1);
    final l10n = AppLocalizations.of(context)!;

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
                    ..rotateX(
                      currentTiltY,
                    ) // Inversé : le côté avec le curseur s'éloigne (tilt vers l'arrière)
                    ..rotateY(-currentTiltX),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: classColor.withValues(
                          alpha: _isHovered ? 1.0 : 0.7,
                        ),
                        width: _isHovered ? 3.0 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: classColor.withValues(
                            alpha: _isHovered ? 0.4 : 0.15,
                          ),
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
                                        (_mousePosition!.dx / cardSize.width) *
                                                2 -
                                            1,
                                        (_mousePosition!.dy / cardSize.height) *
                                                2 -
                                            1,
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
                            padding: EdgeInsets.all(widget.isMobile ? 5 : 20),
                            child: Column(
                              children: [
                                SizedBox(height: widget.isMobile ? 2 : 10),
                                // Floating hero image
                                AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) {
                                    final double floatOffset =
                                        _floatAnimation.value *
                                        (widget.isMobile ? 0.5 : 1.0);
                                    return Transform.translate(
                                      offset: Offset(0, floatOffset),
                                      child: child,
                                    );
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: classColor,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: classColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: widget.isMobile ? 5 : 10,
                                        ),
                                      ],
                                    ),
                                    child: ClassAvatar(
                                      hero: playerClass,
                                      diameter: widget.isMobile ? 48 : 65,
                                    ),
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 1 : 15),
                                Text(
                                  playerClass.getName(locale),
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 20 : 26,
                                    fontWeight: FontWeight.bold,
                                    color: classColor,
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: classColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 2 : 12),
                                // Stats with beautiful icons and display
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 4 : 12,
                                    vertical: widget.isMobile ? 2 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(
                                      widget.isMobile ? 6 : 10,
                                    ),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: widget.isMobile ? 8 : 14,
                                    runSpacing: widget.isMobile ? 2 : 4,
                                    children: [
                                      for (final badge in statBadges)
                                        _buildStatBadge(badge.icon, badge.value),
                                    ],
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 1 : 8),
                                // Ce que renforce la Puissance de la classe,
                                // et ce qu'elle convertit — genere depuis
                                // `mightTargets` et `statRules`, jamais ecrit
                                // classe par classe (spec §8.3, ADR-090).
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 4 : 12,
                                    vertical: widget.isMobile ? 2 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(
                                      widget.isMobile ? 6 : 10,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        playerClass.mightTargets.sentence(l10n),
                                        style: TextStyle(
                                          fontSize: widget.isMobile ? 9.5 : 10.5,
                                          color: Colors.orangeAccent.withValues(
                                            alpha: 0.9,
                                          ),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      for (final rule in playerClass.statRules) ...[
                                        SizedBox(height: widget.isMobile ? 2 : 4),
                                        Text(
                                          rule.describe(l10n),
                                          style: TextStyle(
                                            fontSize: widget.isMobile ? 9.5 : 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.orangeAccent.withValues(
                                              alpha: 0.75,
                                            ),
                                            height: 1.25,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 1 : 8),
                                // Passive trait
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 3 : 12,
                                    vertical: widget.isMobile ? 2 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      widget.isMobile ? 6 : 10,
                                    ),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: widget.isMobile ? 4 : 10,
                                        runSpacing: widget.isMobile ? 1 : 2,
                                        children: [
                                          for (var i = 0;
                                              i < passives.length;
                                              i++)
                                            GestureDetector(
                                              onTap: passives.length == 1
                                                  ? null
                                                  : () => setState(
                                                        () => _passiveIndex =
                                                            i,
                                                      ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.shield,
                                                    size: widget.isMobile
                                                        ? 12
                                                        : 16,
                                                    color: Colors.cyanAccent
                                                        .withValues(
                                                      alpha: i == index
                                                          ? 1.0
                                                          : 0.35,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        widget.isMobile ? 2 : 6,
                                                  ),
                                                  // `Flexible` (jamais
                                                  // `Expanded`) : le nom
                                                  // enjambe une seconde ligne
                                                  // quand la donnee reelle
                                                  // (ex. « REGENERATION
                                                  // D'ARMURE ») ne tient pas
                                                  // sur la largeur mobile,
                                                  // sans deborder ni couper
                                                  // le texte (defaut 2).
                                                  Flexible(
                                                    child: Text(
                                                      passives[i]
                                                          .getName(locale)
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize:
                                                            widget.isMobile
                                                                ? 10
                                                                : 11,
                                                        fontWeight: i == index
                                                            ? FontWeight.bold
                                                            : FontWeight
                                                                .normal,
                                                        color: Colors
                                                            .cyanAccent
                                                            .withValues(
                                                          alpha: i == index
                                                              ? 1.0
                                                              : 0.45,
                                                        ),
                                                        letterSpacing: 0.8,
                                                        decoration:
                                                            passives.length >
                                                                        1 &&
                                                                    i == index
                                                                ? TextDecoration
                                                                    .underline
                                                                : null,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (passives.isEmpty)
                                            Text(
                                              '—',
                                              style: TextStyle(
                                                fontSize:
                                                    widget.isMobile ? 10 : 11,
                                                color: Colors.cyanAccent,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: widget.isMobile ? 2 : 5),
                                      Text(
                                        traitDesc,
                                        style: TextStyle(
                                          fontSize: widget.isMobile
                                              ? 9.5
                                              : 10.5,
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.85,
                                          ),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (masteryPerPoint != null) ...[
                                        SizedBox(
                                          height: widget.isMobile ? 1 : 3,
                                        ),
                                        Text(
                                          l10n.passiveMasteryPerPoint(
                                            masteryPerPoint,
                                          ),
                                          style: TextStyle(
                                            fontSize: widget.isMobile
                                                ? 9
                                                : 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.cyanAccent.withValues(
                                              alpha: 0.7,
                                            ),
                                            height: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Divider(
                                  color: Colors.white12,
                                  height: widget.isMobile ? 6 : 25,
                                ),
                                // Description text
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      playerClass.getDescription(locale),
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
                                SizedBox(height: widget.isMobile ? 1 : 15),
                                // Premium Selection Button
                                _PremiumSelectionButton(
                                  classColor: classColor,
                                  isMobile: widget.isMobile,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StarterDeckDraftScreen(
                                              playerClass: playerClass,
                                              passive: passive,
                                            ),
                                      ),
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
      // Ces badges vivent dans un `Wrap` (tache 5) : un `Row` a sa taille par
      // defaut (`MainAxisSize.max`) y revendique toute la largeur restante,
      // ce qui force chaque badge suivant sur sa propre ligne. `min` laisse
      // le badge se limiter a son contenu, pour que le `Wrap` les aligne
      // vraiment cote a cote (defaut 1 du 2026-09-18).
      mainAxisSize: MainAxisSize.min,
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
  State<_PremiumSelectionButton> createState() =>
      _PremiumSelectionButtonState();
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradient = ClassIdentity.gradientOf(widget.classColor);

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
                    color: widget.classColor.withValues(
                      alpha: _isHovered ? 0.5 : 0.25,
                    ),
                    blurRadius: _isHovered ? 15 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.select,
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
