import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/combat_state.dart';
import '../../../models/data/card_data.dart';
import '../../../models/signature_instance.dart';
import '../ui_card/ui_card_helpers.dart';

/// Les états d'une tuile de signature, dans l'ordre de priorité de la spec
/// P-43 E4 §5.2 : le premier qui s'applique l'emporte.
enum SignatureTileState { inactive, recharging, unaffordable, armed, available }

SignatureTileState signatureTileStateOf({
  required bool interactive,
  required int turnsLeft,
  required bool affordable,
  required bool armed,
}) {
  if (!interactive) return SignatureTileState.inactive;
  if (turnsLeft > 0) return SignatureTileState.recharging;
  if (!affordable) return SignatureTileState.unaffordable;
  if (armed) return SignatureTileState.armed;
  return SignatureTileState.available;
}

/// Les signatures du joueur, en colonne au milieu gauche de l'écran de combat,
/// en miroir du bouton de fin de tour. Sans état : tout vient de l'appelant,
/// qui relie les gestes au moteur.
class SignatureBar extends StatelessWidget {
  final List<SignatureInstance> signatures;
  final CombatState combatState;
  final int currentMana;
  final bool interactive;
  final Color classColor;
  final String? armedId;
  final ValueChanged<SignatureInstance> onPlay;
  final ValueChanged<SignatureInstance> onArm;
  final VoidCallback onDisarm;
  final VoidCallback onInsufficientMana;

  const SignatureBar({
    super.key,
    required this.signatures,
    required this.combatState,
    required this.currentMana,
    required this.interactive,
    required this.classColor,
    required this.armedId,
    required this.onPlay,
    required this.onArm,
    required this.onDisarm,
    required this.onInsufficientMana,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          // Seule la colonne des tuiles est centrée : l'invite pend sous elle,
          // hors de sa taille, pour qu'armer ne déplace aucune tuile.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final signature in signatures)
                    _tileFor(signature, compact),
                ],
              ),
              if (armedId != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FractionalTranslation(
                    translation: const Offset(0, 1),
                    child: Text(
                      l10n.signatureChooseTarget,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileFor(SignatureInstance signature, bool compact) {
    final turnsLeft = combatState.signatureTurnsLeft(signature.data.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _SignatureTile(
        signature: signature,
        compact: compact,
        classColor: classColor,
        turnsLeft: turnsLeft,
        state: signatureTileStateOf(
          interactive: interactive,
          turnsLeft: turnsLeft,
          affordable: currentMana >= signature.cost,
          armed: armedId == signature.data.id,
        ),
        onPlay: () => onPlay(signature),
        onArm: () => onArm(signature),
        onDisarm: onDisarm,
        onInsufficientMana: onInsufficientMana,
      ),
    );
  }
}

class _SignatureTile extends StatefulWidget {
  final SignatureInstance signature;
  final bool compact;
  final Color classColor;
  final int turnsLeft;
  final SignatureTileState state;
  final VoidCallback onPlay;
  final VoidCallback onArm;
  final VoidCallback onDisarm;
  final VoidCallback onInsufficientMana;

  const _SignatureTile({
    required this.signature,
    required this.compact,
    required this.classColor,
    required this.turnsLeft,
    required this.state,
    required this.onPlay,
    required this.onArm,
    required this.onDisarm,
    required this.onInsufficientMana,
  });

  @override
  State<_SignatureTile> createState() => _SignatureTileState();
}

class _SignatureTileState extends State<_SignatureTile>
    with TickerProviderStateMixin {
  // Même secousse qu'une carte inabordable : +5, -5, +5, -5, retour, en 250 ms.
  static final Animatable<double> _shakeOffset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
  ]);

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool _hovered = false;

  // Seules les tuiles qui répondent au toucher réagissent au survol.
  static bool _responds(SignatureTileState state) =>
      state == SignatureTileState.available ||
      state == SignatureTileState.armed ||
      state == SignatureTileState.unaffordable;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_SignatureTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final armed = widget.state == SignatureTileState.armed;
    if (armed && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!armed && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onTap() {
    switch (widget.state) {
      case SignatureTileState.inactive:
      case SignatureTileState.recharging:
        return;
      case SignatureTileState.unaffordable:
        widget.onInsufficientMana();
        _shake.forward(from: 0);
      case SignatureTileState.armed:
        widget.onDisarm();
      case SignatureTileState.available:
        if (widget.signature.data.target == CardTarget.singleEnemy) {
          widget.onArm();
        } else {
          widget.onPlay();
        }
    }
  }

  /// Le nom, le type, la description et, en recharge seulement, le compte :
  /// de haut en bas, à droite du médaillon.
  Widget _details(BuildContext context, AppLocalizations l10n) {
    final data = widget.signature.data;
    final recharging = widget.state == SignatureTileState.recharging;
    final compact = widget.compact;
    final locale = l10n.localeName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.getName(locale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: recharging ? Colors.white38 : Colors.white,
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          getCardTypeLabel(context, data.type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: getCardTypeColor(data.type, isGrayedOut: recharging),
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.getDescription(locale),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: recharging ? Colors.white38 : Colors.white70,
            fontSize: compact ? 10 : 11,
          ),
        ),
        if (widget.turnsLeft > 0) ...[
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_bottom,
                size: compact ? 11 : 12,
                color: Colors.white,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  l10n.signatureTurnsLeft(widget.turnsLeft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.signature.data;
    final state = widget.state;
    final recharging = state == SignatureTileState.recharging;
    final armed = state == SignatureTileState.armed;

    final responsive = _responds(state);
    final lifted = responsive && _hovered;

    // La zone de survol est hors de l'agrandissement : elle garde la taille au
    // repos, pour que la tuile ne clignote pas sur son propre bord.
    return MouseRegion(
      cursor: responsive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        // Effet de peinture seulement : la mise en page ne bouge pas.
        child: AnimatedScale(
          scale: lifted ? 1.05 : 1,
          alignment: Alignment.centerLeft,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeOffset.evaluate(_shake), 0),
              child: child,
            ),
            child: AnimatedBuilder(
          animation: _pulse,
          // Le contenu ne dépend pas de l'impulsion : construit une fois.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CostMedallion(
                cost: widget.signature.cost,
                unaffordable: state == SignatureTileState.unaffordable,
              ),
              const SizedBox(width: 6),
              Expanded(child: _details(context, l10n)),
            ],
          ),
          builder: (context, content) {
            final borderColor = switch (state) {
              SignatureTileState.recharging => Colors.grey,
              SignatureTileState.armed => Color.lerp(
                widget.classColor,
                Colors.white,
                _pulse.value,
              )!,
              _ => widget.classColor,
            };
            return Opacity(
              opacity: state == SignatureTileState.inactive ? 0.45 : 1,
              child: Container(
                key: ValueKey('signature-tile-${data.id}'),
                width: widget.compact ? 170 : 220,
                constraints: BoxConstraints(
                  minHeight: widget.compact ? 64 : 80,
                ),
                // La bordure armée, plus épaisse d'un point, le prend sur la
                // marge : la tuile garde sa taille, ses voisines leur place.
                padding: EdgeInsets.all(armed ? 5 : 6),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: recharging
                      ? const Color(0xFF2A2A2A)
                      : neutralCardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: armed ? 3 : 2,
                  ),
                  boxShadow: [
                    if (state == SignatureTileState.available)
                      BoxShadow(
                        color: widget.classColor.withAlpha(150),
                        blurRadius: 8,
                      ),
                    // Le survol intensifie la lueur de classe.
                    if (lifted)
                      BoxShadow(
                        color: widget.classColor.withAlpha(230),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: content,
              ),
            );
          },
            ),
          ),
        ),
      ),
    );
  }
}

class _CostMedallion extends StatelessWidget {
  final int cost;
  final bool unaffordable;

  const _CostMedallion({required this.cost, required this.unaffordable});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unaffordable ? Colors.redAccent : Colors.blueAccent,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        '$cost',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
