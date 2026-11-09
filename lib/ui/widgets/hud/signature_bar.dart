import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../game/services/effect_line_texts.dart';
import '../../../game/services/effect_resolver.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/combat_state.dart';
import '../../../models/data/card_data.dart';
import '../../../models/data/effect_icon_table.dart';
import '../../../models/data/effect_kind.dart';
import '../../../models/data/signature_evolution_data.dart';
import '../../../models/entity_stats.dart';
import '../../../models/signature_instance.dart';
import '../effect_style.dart';
import '../ui_card/ui_card_helpers.dart';
import 'combat_side_panels.dart';
import 'combat_top_bar.dart';

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

/// L'échelle et le haut de la colonne des signatures (A38) : [available] est
/// la hauteur que reçoit la barre, [natural] celle de la colonne mesurée.
({double scale, double top}) signatureBandPlacement({
  required double available,
  required double natural,
}) {
  const bandTop = CombatTopBar.bandTop;
  const bandBottom = CombatSidePanels.statusPanelBottom +
      CombatSidePanels.statusPanelReserve;
  final band = available - bandTop - bandBottom;
  // 1. L'échelle : 1 tant que la colonne tient, 0,75 au plus bas.
  final scale = (band / natural).clamp(0.75, 1.0);
  // 2. La hauteur posée.
  final placed = scale * natural;
  // 3. À mi-hauteur ; décalée vers le haut si elle sortirait de la bande
  // par le bas ; jamais au-dessus de bandTop.
  final top = max(
    bandTop,
    min(available / 2 - placed / 2, available - bandBottom - placed),
  );
  return (scale: scale, top: top);
}

/// Les signatures du joueur, en colonne au milieu gauche de l'écran de combat,
/// en miroir du bouton de fin de tour. Sans état : tout vient de l'appelant,
/// qui relie les gestes au moteur.
class SignatureBar extends StatelessWidget {
  final List<SignatureInstance> signatures;
  final CombatState combatState;
  final EntityStats heroStats;
  final EffectIconTable effectIcons;
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
    required this.heroStats,
    this.effectIcons = const EffectIconTable.empty(),
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
      child: _SignatureBandLayout(
        // Seule la colonne des tuiles est posée : l'invite pend sous elle,
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
        effectIcons: effectIcons,
        turnsLeft: turnsLeft,
        state: signatureTileStateOf(
          interactive: interactive,
          turnsLeft: turnsLeft,
          affordable: EffectResolver.canAfford(signature.asCard, heroStats),
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

/// Pose la colonne des signatures dans sa bande (A38, PN18) : la colonne est
/// mesurée, puis décalée de 20 px du bord gauche, posée à la hauteur et à
/// l'échelle de [signatureBandPlacement]. La transformation est connue dès la
/// mise en page ; la peinture et le toucher la lisent.
class _SignatureBandLayout extends SingleChildRenderObjectWidget {
  const _SignatureBandLayout({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSignatureBand();
}

class _RenderSignatureBand extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  static const double _left = 20;

  Matrix4 _transform = Matrix4.identity();

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    // La largeur seule est bornée : la colonne garde sa hauteur naturelle.
    child.layout(
      BoxConstraints(maxWidth: max(0.0, size.width - _left)),
      parentUsesSize: true,
    );
    final (:scale, :top) = signatureBandPlacement(
      available: size.height,
      natural: child.size.height,
    );
    _transform = Matrix4.translationValues(_left, top, 0) *
        Matrix4.diagonal3Values(scale, scale, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      layer = null;
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) =>
          child.hitTest(result, position: position),
    );
  }
}

// Le médaillon et son écart : la colonne de texte commence après eux.
const double _medallionSize = 20;
const double _medallionGap = 6;

class _SignatureTile extends StatefulWidget {
  final SignatureInstance signature;
  final bool compact;
  final Color classColor;
  final EffectIconTable effectIcons;
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
    required this.effectIcons,
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

  // Seules les tuiles jouables réagissent au survol : une tuile grisée, même
  // sensible au toucher, ne doit pas avoir l'air jouable.
  static bool _responds(SignatureTileState state) =>
      state == SignatureTileState.available ||
      state == SignatureTileState.armed;

  // Recharge ou mana insuffisant : la tuile porte le même aspect grisé.
  static bool _grayedOut(SignatureTileState state) =>
      state == SignatureTileState.recharging ||
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
        // La cible évoluée : une évolution peut viser tous les ennemis.
        if (widget.signature.asCard.data.target == CardTarget.singleEnemy) {
          widget.onArm();
        } else {
          widget.onPlay();
        }
    }
  }

  // La tuile déployée de l'appui long (A42), posée dans le calque.
  final OverlayPortalController _list = OverlayPortalController();

  // Le survol ne soulève pas la tuile sous sa liste : la tuile soulevée
  // déborderait du calque, posé à la taille de la tuile au repos.
  bool get _lifted =>
      _responds(widget.state) && _hovered && !_list.isShowing;

  // L'appui long ne lit pas l'état : la liste s'ouvre aussi sur une tuile
  // inactive, et rien ne se joue, ne s'arme ni ne se désarme.
  void _showList() => setState(_list.show);

  // Gardé : un appui court, ou une tuile démontée avant le délai de l'appui
  // long, appelle aussi onLongPressCancel, la liste fermée.
  void _hideList() {
    if (_list.isShowing) setState(_list.hide);
  }

  /// Le contenu de la tuile, de haut en bas : l'en-tête (médaillon, nom, type
  /// et badge), la bande d'icônes sur toute la largeur — la liste des effets
  /// sur la tuile déployée —, puis, dans la colonne de texte, les puces
  /// d'évolution et le compte de recharge.
  Widget _content(
    BuildContext context,
    AppLocalizations l10n, {
    required bool expanded,
  }) {
    final signature = widget.signature;
    final state = widget.state;
    final grayedOut = _grayedOut(state);
    final compact = widget.compact;
    final taken = signature.taken;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CostMedallion(
              cost: signature.cost,
              unaffordable: state == SignatureTileState.unaffordable,
            ),
            const SizedBox(width: _medallionGap),
            Expanded(child: _header(context, l10n)),
          ],
        ),
        const SizedBox(height: 4),
        if (expanded)
          _EffectList(
            lines: signature.effectLines,
            effectIcons: widget.effectIcons,
            compact: compact,
            grayedOut: grayedOut,
          )
        else
          _EffectBand(
            lines: signature.effectLines,
            effectIcons: widget.effectIcons,
            compact: compact,
            grayedOut: grayedOut,
          ),
        if (taken.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(
              left: _medallionSize + _medallionGap,
            ),
            // Un niveau écrit à côté d'une puce peut porter la rangée au-delà
            // de la colonne de texte : elle se réduit alors d'un bloc.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  for (final (evolution, level) in taken)
                    _evolutionChip(evolution, level, grayedOut),
                ],
              ),
            ),
          ),
        ],
        if (widget.turnsLeft > 0) ...[
          const SizedBox(height: 4),
          Center(child: _turnsLeft(l10n)),
        ],
      ],
    );
  }

  /// La taille du type et du badge, que reprend le niveau d'une puce.
  double get _typeSize => widget.compact ? 9 : 10;

  /// Une puce d'évolution : l'icône sans son chiffre superposé, illisible à
  /// cette taille, puis, dès le niveau 2, le niveau écrit à sa droite, à la
  /// taille du badge et à la couleur de la puce.
  Widget _evolutionChip(
    SignatureEvolutionData evolution,
    int level,
    bool grayedOut,
  ) {
    final color = grayedOut ? Colors.white38 : null;
    final icon = EvolutionIcon(
      evolution: evolution,
      size: widget.compact ? 16 : 18,
      color: color,
    );
    if (level < 2) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 1,
      children: [
        icon,
        Text(
          '$level',
          style: TextStyle(
            color: color ?? EvolutionIcon.tintOf(evolution),
            fontSize: _typeSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Le nom, puis le type et, à son bout, le badge de niveau (A36).
  Widget _header(BuildContext context, AppLocalizations l10n) {
    final signature = widget.signature;
    final data = signature.data;
    final grayedOut = _grayedOut(widget.state);
    final compact = widget.compact;
    final level = signature.level;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.getName(l10n.localeName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: grayedOut ? Colors.white38 : Colors.white,
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            Flexible(
              child: Text(
                getCardTypeLabel(context, data.type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: getCardTypeColor(data.type, isGrayedOut: grayedOut),
                  fontSize: _typeSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (level > 0) ...[
              const SizedBox(width: 4),
              Text(
                l10n.levelLabel(level),
                maxLines: 1,
                style: TextStyle(
                  color: grayedOut ? Colors.white38 : Colors.amberAccent,
                  fontSize: _typeSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _turnsLeft(AppLocalizations l10n) {
    final compact = widget.compact;
    return Row(
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
    );
  }

  /// La tuile, ou sa forme déployée (A42) : le même cadre — sa largeur, sa
  /// bordure et la pulsation armée, son gris — autour du même contenu, la
  /// liste des effets à la place de la bande. Seule la tuile prend l'opacité
  /// de l'état inactif, jamais sa forme déployée.
  Widget _body(
    BuildContext context,
    AppLocalizations l10n, {
    required bool expanded,
  }) {
    final state = widget.state;
    final grayedOut = _grayedOut(state);
    final armed = state == SignatureTileState.armed;
    final lifted = _lifted;

    return AnimatedBuilder(
      animation: _pulse,
      // Le contenu ne dépend pas de l'impulsion : construit une fois.
      child: _content(context, l10n, expanded: expanded),
      builder: (context, content) {
        final borderColor = switch (state) {
          SignatureTileState.recharging ||
          SignatureTileState.unaffordable => Colors.grey,
          SignatureTileState.armed => Color.lerp(
            widget.classColor,
            Colors.white,
            _pulse.value,
          )!,
          _ => widget.classColor,
        };
        return Opacity(
          opacity: !expanded && state == SignatureTileState.inactive ? 0.45 : 1,
          child: Container(
            width: widget.compact ? 170 : 220,
            constraints: BoxConstraints(
              minHeight: widget.compact ? 64 : 80,
            ),
            // La bordure armée, plus épaisse d'un point, le prend sur la
            // marge : la tuile garde sa taille, ses voisines leur place.
            padding: EdgeInsets.all(armed ? 5 : 6),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: grayedOut ? const Color(0xFF2A2A2A) : neutralCardBackground,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final responsive = _responds(widget.state);

    // Le calque pose la tuile déployée sur la tuile, par-dessus ses voisines :
    // la colonne ne change ni de hauteur, ni d'échelle, ni de place.
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _list,
      overlayChildBuilder: (context, info) => IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _ExpandedTileLayout(info),
          child: Transform.scale(
            scale: _ExpandedTileLayout.scaleOf(info),
            alignment: Alignment.topLeft,
            child: _body(context, l10n, expanded: true),
          ),
        ),
      ),
      // La zone de survol est hors de l'agrandissement : elle garde la taille
      // au repos, pour que la tuile ne clignote pas sur son propre bord.
      child: MouseRegion(
        cursor:
            responsive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onLongPressStart: (_) => _showList(),
          onLongPressEnd: (_) => _hideList(),
          onLongPressCancel: _hideList,
          // Effet de peinture seulement : la mise en page ne bouge pas.
          child: AnimatedScale(
            scale: _lifted ? 1.05 : 1,
            alignment: Alignment.centerLeft,
            // Sous la liste, la tuile retombe d'un coup : en 100 ms, elle
            // déborderait du calque.
            duration: _list.isShowing
                ? Duration.zero
                : const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: AnimatedBuilder(
              animation: _shake,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeOffset.evaluate(_shake), 0),
                child: child,
              ),
              child: _body(context, l10n, expanded: false),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pose la tuile déployée dans le calque (A42, PN19) : à l'échelle et au haut
/// de la tuile, à sa largeur ; vers le bas si elle tient sous ce haut, sinon
/// vers le haut, son bas au bas de la tuile.
class _ExpandedTileLayout extends SingleChildLayoutDelegate {
  final OverlayChildLayoutInfo info;

  const _ExpandedTileLayout(this.info);

  /// L'échelle de la tuile dans le calque, lue sur sa largeur transformée :
  /// `getMaxScaleOnAxis` lirait aussi l'axe Z, laissé à 1 par la barre, et
  /// rendrait 1 sur une barre réduite.
  static double scaleOf(OverlayChildLayoutInfo info) =>
      MatrixUtils.transformRect(
        info.childPaintTransform,
        Offset.zero & info.childSize,
      ).width /
      info.childSize.width;

  // La largeur de la tuile ; jamais moins haute qu'elle, pour la couvrir.
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: info.childSize.width)
          .copyWith(minHeight: info.childSize.height);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final scale = scaleOf(info);
    final top = MatrixUtils.transformPoint(info.childPaintTransform, Offset.zero);
    final placed = scale * childSize.height;
    if (top.dy + placed <= info.overlaySize.height) return top;
    return Offset(top.dx, top.dy + scale * info.childSize.height - placed);
  }

  @override
  bool shouldRelayout(_ExpandedTileLayout oldDelegate) =>
      oldDelegate.info != info;
}

/// La bande d'icônes (A40) : une cellule par entrée de [lines], dans l'ordre,
/// trois par ligne ; chaque ligne centrée dans la largeur de la tuile, et
/// réduite d'un bloc si elle est plus large.
class _EffectBand extends StatelessWidget {
  final List<EffectLine> lines;
  final EffectIconTable effectIcons;
  final bool compact;
  final bool grayedOut;

  const _EffectBand({
    required this.lines,
    required this.effectIcons,
    required this.compact,
    required this.grayedOut,
  });

  static const int _perRow = 3;

  /// La valeur affichée : le critique en pourcentage, rien pour la cible ; la
  /// durée d'un statut jamais.
  static String? _valueLabel(EffectLine line, AppLocalizations l10n) {
    final value = line.value;
    if (value == null || line.kind == EffectKind.allEnemies) return null;
    return line.kind == EffectKind.crit
        ? l10n.effectValuePercent(value)
        : '$value';
  }

  Widget _cell(EffectLine line, AppLocalizations l10n) {
    final visuals = effectVisualsOf(effectIcons, line.kind);
    final label = _valueLabel(line, l10n);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(
          visuals.icon,
          size: compact ? 24 : 28,
          color: grayedOut ? Colors.white38 : visuals.color,
        ),
        if (label != null)
          Text(
            label,
            style: TextStyle(
              color: grayedOut ? Colors.white38 : Colors.white,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        for (var start = 0; start < lines.length; start += _perRow)
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  for (final line in lines.sublist(
                    start,
                    min(start + _perRow, lines.length),
                  ))
                    _cell(line, l10n),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// La liste de la tuile déployée (A42) : une ligne par entrée de [lines], dans
/// l'ordre de la bande — l'icône, toujours à sa couleur, puis sa phrase sur
/// autant de lignes qu'il lui faut ; l'icône seule pour une sorte sans phrase.
class _EffectList extends StatelessWidget {
  final List<EffectLine> lines;
  final EffectIconTable effectIcons;
  final bool compact;
  final bool grayedOut;

  const _EffectList({
    required this.lines,
    required this.effectIcons,
    required this.compact,
    required this.grayedOut,
  });

  Widget _line(EffectLine line, AppLocalizations l10n) {
    final visuals = effectVisualsOf(effectIcons, line.kind);
    final phrase = EffectLineTexts.phrase(l10n, line);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Icon(visuals.icon, size: 16, color: visuals.color),
        if (phrase != null)
          Expanded(
            child: Text(
              phrase,
              style: TextStyle(
                color: grayedOut ? Colors.white38 : Colors.white70,
                fontSize: compact ? 10 : 11,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [for (final line in lines) _line(line, l10n)],
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
      width: _medallionSize,
      height: _medallionSize,
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
