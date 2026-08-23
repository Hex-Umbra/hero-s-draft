import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/enemy_instance.dart';
import '../../ui/widgets/ui_card.dart';
import '../tutorial_engine.dart';
import '../tutorial_fixtures.dart';

/// Valeur d'effet réelle (dégâts ou armure) utilisée pour le texte flottant
/// déclenché par le chemin tap-puis-tap ; applique le multiplicateur de
/// rareté, comme `TutorialEngine.playCard`.
int _effectValue(CardInstance card, String type) {
  for (final effect in card.data.effects) {
    if (effect.type == type) {
      return (effect.value * card.rarityMultiplier).round();
    }
  }
  return 0;
}

/// Étape 08 — jouer des cartes et finir le tour.
///
/// Le geste principal du jeu est le glisser-déposer d'une carte sur sa
/// cible : un ennemi pour les cartes d'attaque, la carte Héros au centre du
/// plateau pour les cartes qui visent le joueur. Le tap-puis-tap reste
/// disponible comme mode d'interaction alternatif. `TutorialEngine.endTurn`
/// illustre la double confirmation du jeu réel quand du mana reste, puis
/// remet l'armure à 0 et le mana au maximum pour le tour suivant.
class TutorialPlayCardWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialPlayCardWidget({super.key, required this.engine});

  @override
  State<TutorialPlayCardWidget> createState() => _TutorialPlayCardWidgetState();
}

class _TutorialPlayCardWidgetState extends State<TutorialPlayCardWidget> {
  CardInstance? _selectedCard;
  bool _showFloatingText = false;
  String _floatingText = '';
  Color _floatingColor = Colors.red;
  double _floatingYOffset = 0.0;

  // Pas de resetMockState() ici : `TutorialEngine.nextStep()`/`prevStep()`
  // l'ont déjà appelé avant que cette page ne soit montée. Le refaire ici
  // déclencherait notifyListeners() en plein passage de build de la
  // PageView (le AnimatedBuilder parent est déjà construit cette frame),
  // ce que Flutter refuse : « setState() or markNeedsBuild() called during
  // build. »

  void _triggerFloatingText(String text, Color color) {
    setState(() {
      _floatingText = text;
      _floatingColor = color;
      _showFloatingText = true;
      _floatingYOffset = 0.0;
    });

    // Animate upward
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _floatingYOffset = -40.0;
        });
      }
    });

    // Fade out
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showFloatingText = false;
        });
      }
    });
  }

  /// Carte de la main enveloppée dans un `Draggable`, avec le tap-puis-tap
  /// conservé via `onTap`/`isSelected` portés par le vrai `UiCard`.
  Widget _draggableCard(
    CardInstance card,
    String locale,
    AppLocalizations l10n, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final view = SizedBox(
      width: 84,
      child: UiCard.fromInstance(
        card: card,
        locale: locale,
        l10n: l10n,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );

    return Draggable<CardInstance>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.1, child: view),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: view),
      child: view,
    );
  }

  /// Zone qui accepte une carte glissée si elle correspond à [accepts].
  /// Rejoue la carte via le moteur au drop, comme le ferait un tap sur la
  /// cible. Une carte tap-sélectionnée puis déposée avec succès n'a plus sa
  /// place en main : on efface la sélection pour éviter un second `playCard`
  /// fantôme si le joueur retape ensuite une cible.
  Widget _dropTarget({
    required Widget child,
    required bool Function(CardInstance) accepts,
  }) {
    return DragTarget<CardInstance>(
      onWillAcceptWithDetails: (details) => accepts(details.data),
      onAcceptWithDetails: (details) {
        if (widget.engine.playCard(details.data)) {
          setState(() {
            if (_selectedCard == details.data) _selectedCard = null;
          });
        }
      },
      builder: (context, candidate, rejected) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: candidate.isNotEmpty ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildEnemyZone(double scale, bool isFrench) {
    final enemy = widget.engine.mockState.enemy!;

    return Stack(
      alignment: Alignment.center,
      children: [
        _dropTarget(
          accepts: (card) => card.data.target == CardTarget.singleEnemy,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              if (_selectedCard == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFrench
                          ? 'Sélectionnez d\'abord une carte en bas !'
                          : 'Select a card from the bottom first!',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
                return;
              }

              if (_selectedCard!.data.id == TutorialFixtureIds.strike) {
                final damage = _effectValue(_selectedCard!, 'damage');
                final success = widget.engine.playCard(_selectedCard!);
                if (success) {
                  _triggerFloatingText('-$damage HP', Colors.redAccent);
                  setState(() {
                    _selectedCard = null;
                  });
                }
              } else if (_selectedCard!.data.id == TutorialFixtureIds.defend) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFrench
                          ? 'La Défense doit être jouée sur vous-même ! Touchez votre carte Héros.'
                          : 'Defense must be played on yourself! Tap your Hero card.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: MouseRegion(
              cursor: _selectedCard != null
                  ? SystemMouseCursors.precise
                  : SystemMouseCursors.basic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(10 * scale),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (_selectedCard != null &&
                          _selectedCard!.data.id == TutorialFixtureIds.strike)
                      ? Colors.redAccent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border.all(
                    color:
                        (_selectedCard != null &&
                            _selectedCard!.data.id ==
                                TutorialFixtureIds.strike)
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 2 * scale,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Monster Icon (Slime representation)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.95, end: 1.05),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOutSine,
                      builder: (context, val, child) {
                        return Transform.scale(scale: val, child: child);
                      },
                      child: Icon(
                        Icons.pest_control_rodent_rounded,
                        size: 50 * scale,
                        color: enemy.stats.currentPv > 0
                            ? Colors.greenAccent
                            : Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    // Enemy Name
                    Text(
                      isFrench ? enemy.data.nameFr : enemy.data.nameEn,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    // Health Bar
                    Container(
                      width: 100 * scale,
                      height: 10 * scale,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(5 * scale),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width:
                                (100 * scale) *
                                (enemy.stats.currentPv / enemy.stats.maxPv),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(5 * scale),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${enemy.stats.currentPv}/${enemy.stats.maxPv}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating Damage/Block Text Overlay
        if (_showFloatingText)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutQuad,
            top: (30 * scale) + _floatingYOffset,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 700),
              opacity: _floatingYOffset == 0.0 ? 1.0 : 0.0,
              child: Text(
                _floatingText,
                style: TextStyle(
                  color: _floatingColor,
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// La cible « Héros » : plus une barre de PV/Mana, mais une carte visuelle
  /// explicitement libellée, au centre du plateau sous l'ennemi.
  Widget _buildHeroZone(double scale, bool isFrench) {
    final heroStats = widget.engine.mockState.heroStats;
    final isDefendSelected =
        _selectedCard != null && _selectedCard!.data.id == TutorialFixtureIds.defend;

    return _dropTarget(
      accepts: (card) => card.data.target == CardTarget.self,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (_selectedCard == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isFrench
                      ? 'Glissez ou touchez la carte Héros au centre !'
                      : 'Drag or tap the Hero card in the centre!',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
            return;
          }

          if (_selectedCard!.data.id == TutorialFixtureIds.defend) {
            final armor = _effectValue(_selectedCard!, 'armor');
            final success = widget.engine.playCard(_selectedCard!);
            if (success) {
              _triggerFloatingText('+$armor 🛡️', Colors.blueAccent);
              setState(() {
                _selectedCard = null;
              });
            }
          } else if (_selectedCard!.data.id == TutorialFixtureIds.strike) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isFrench
                      ? 'Ne vous attaquez pas vous-même ! Touchez le Slime.'
                      : 'Don\'t attack yourself! Tap the Slime.',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: MouseRegion(
          cursor: _selectedCard != null
              ? SystemMouseCursors.precise
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 8 * scale,
            ),
            margin: EdgeInsets.symmetric(vertical: 4 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(
                color: isDefendSelected
                    ? Colors.cyanAccent.withValues(alpha: 0.5)
                    : Colors.amber.withValues(alpha: 0.25),
                width: 1.5 * scale,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFrench ? 'HÉROS' : 'HERO',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // HP
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red, size: 14 * scale),
                        SizedBox(width: 6 * scale),
                        Text(
                          'HP: ${heroStats.currentPv}/${heroStats.maxPv}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (heroStats.armure > 0) ...[
                          SizedBox(width: 8 * scale),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4 * scale,
                              vertical: 2 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(4 * scale),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield,
                                  color: Colors.white,
                                  size: 10 * scale,
                                ),
                                SizedBox(width: 2 * scale),
                                Text(
                                  '${heroStats.armure}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Mana
                    Row(
                      children: [
                        Text(
                          isFrench ? 'MANA : ' : 'MANA: ',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10 * scale,
                          ),
                        ),
                        Row(
                          children: List.generate(heroStats.maxMana, (index) {
                            final active = index < heroStats.currentMana;
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.0 * scale,
                              ),
                              child: Icon(
                                Icons.diamond_rounded,
                                color: active
                                    ? Colors.cyanAccent
                                    : Colors.cyan.withValues(alpha: 0.15),
                                size: 13 * scale,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Consigne au-dessus de la main : nomme la vraie carte à jouer, en
  /// dérivant son titre de `card.data.getName`, jamais d'une valeur en dur.
  String _handHint(EnemyInstance? enemy, bool isFrench, String locale) {
    final strikeName = widget.engine.fixtures
        .card(TutorialFixtureIds.strike)
        .getName(locale);
    final defendName = widget.engine.fixtures
        .card(TutorialFixtureIds.defend)
        .getName(locale);

    final isPhaseOne = enemy == null || enemy.stats.currentPv == enemy.stats.maxPv;
    if (isPhaseOne) {
      return isFrench
          ? "Étape 1 : glissez ou touchez '$strikeName' sur le Slime."
          : "Step 1: drag or tap '$strikeName' onto the Slime.";
    }
    return isFrench
        ? "Étape 2 : glissez ou touchez '$defendName' sur votre carte Héros."
        : "Step 2: drag or tap '$defendName' onto your Hero card.";
  }

  Widget _buildHandZone(
    double scale,
    bool isFrench,
    String locale,
    AppLocalizations l10n,
  ) {
    final hand = widget.engine.mockState.hand;
    final enemy = widget.engine.mockState.enemy;

    // Filter hand in two phases to guide the player:
    // Phase 1 (slime has full HP): show only Strike to target the enemy.
    // Phase 2 (slime took damage): show only Defend to target the hero.
    final displayedHand = hand.where((card) {
      if (enemy != null && enemy.stats.currentPv == enemy.stats.maxPv) {
        return card.data.id == TutorialFixtureIds.strike;
      } else {
        return card.data.id == TutorialFixtureIds.defend;
      }
    }).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hand.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 6 * scale),
            child: Text(
              _handHint(enemy, isFrench, locale),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Expanded(
          child: hand.isEmpty
              ? Center(
                  child: Text(
                    isFrench
                        ? 'Bien joué ! Appuyez sur SUIVANT.'
                        : 'Well played! Tap NEXT to proceed.',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: displayedHand.map((card) {
                    final isSelected = _selectedCard == card;
                    return Padding(
                      key: ValueKey(card.uniqueId),
                      padding: EdgeInsets.symmetric(horizontal: 5 * scale),
                      child: _draggableCard(
                        card,
                        locale,
                        l10n,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedCard = isSelected ? null : card;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildEndTurnSection(bool isFrench, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.engine.manaWarningPending)
            Padding(
              padding: EdgeInsets.only(bottom: 6 * scale),
              child: Text(
                isFrench
                    ? 'Mana restant. Terminer le tour ?'
                    : 'Mana remaining. End the turn?',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          InkWell(
            onTap: () {
              widget.engine.endTurn();
              setState(() {});
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 10 * scale,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                isFrench ? 'Fin de Tour' : 'End Turn',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * scale,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bande basse dédiée à l'annulation : la carte n'a jamais quitté la main
  /// (elle n'est retirée que par `TutorialEngine.playCard`), donc ne rien
  /// faire à l'acceptation suffit à la « reposer ».
  Widget _buildCancelZone(bool isFrench) {
    return DragTarget<CardInstance>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {},
      builder: (context, candidate, rejected) => Container(
        height: 60,
        margin: const EdgeInsets.only(top: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: candidate.isNotEmpty
              ? Colors.redAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: candidate.isNotEmpty
                ? Colors.redAccent.withValues(alpha: 0.6)
                : Colors.grey.shade700,
            width: 1.5,
          ),
        ),
        child: Text(
          isFrench ? 'Relâcher ici pour annuler' : 'Drop here to cancel',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final locale = isFrench ? 'fr' : 'en';
    final l10n = AppLocalizations.of(context)!;
    final enemy = widget.engine.mockState.enemy;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double scaleHeight = constraints.maxHeight / 380.0;
          final double scaleWidth = constraints.maxWidth / 360.0;
          final double scale = (scaleHeight < scaleWidth ? scaleHeight : scaleWidth)
              .clamp(0.6, 1.35);

          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: EdgeInsets.all(8.0 * scale),
              child: Column(
                children: [
                  // Discreet reminder of the turn cycle's shape.
                  Text(
                    isFrench
                        ? 'Pioche : 5 cartes par tour · Main max : 10'
                        : 'Draw: 5 cards per turn · Max hand: 10',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 9 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 4 * scale),

                  // Top Part: Slime Enemy
                  if (enemy != null)
                    Expanded(flex: 4, child: _buildEnemyZone(scale, isFrench)),

                  // Mid Part: Hero card
                  Expanded(flex: 2, child: _buildHeroZone(scale, isFrench)),

                  // Bottom Part: Hand
                  Expanded(
                    flex: 3,
                    child: _buildHandZone(scale, isFrench, locale, l10n),
                  ),

                  _buildEndTurnSection(isFrench, scale),
                  _buildCancelZone(isFrench),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
