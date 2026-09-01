import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/game_moment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class GameButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final int? goldCost;
  final Color? baseColor;
  final bool isParchmentOverride;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;

  const GameButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.goldCost,
    this.baseColor,
    this.isParchmentOverride = false,
    this.icon,
    this.width,
    this.height = 48,
    this.fontSize = 16,
  });

  @override
  ConsumerState<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends ConsumerState<GameButton> {
  bool _isHovered = false;

  /// Point unique du son de validation d'interface : tout menu passe par ce
  /// bouton, donc aucun ecran n'a besoin de cabler `uiTap` lui-meme.
  void _handleTap() {
    ref.read(audioDirectorProvider).onMoment(GameMoment.uiTap);
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isParchment = widget.isParchmentOverride ||
        theme.scaffoldBackgroundColor == AppColors.parchmentBg;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color buttonColor;
    Color textColor;
    Color borderColor;

    if (!isEnabled) {
      buttonColor = isParchment ? Colors.grey.shade300 : Colors.white12;
      textColor = isParchment ? Colors.grey.shade500 : Colors.white30;
      borderColor = isParchment ? Colors.grey.shade400 : Colors.white24;
    } else {
      if (isParchment) {
        buttonColor =
            _isHovered ? AppColors.parchmentSurface : AppColors.parchmentBg;
        textColor = AppColors.parchmentText;
        borderColor = AppColors.parchmentBorder;
      } else {
        final primaryColor = widget.baseColor ?? theme.colorScheme.primary;
        buttonColor = _isHovered
            ? primaryColor.withValues(alpha: 0.25)
            : primaryColor.withValues(alpha: 0.1);
        textColor = primaryColor;
        borderColor =
            _isHovered ? primaryColor : primaryColor.withValues(alpha: 0.5);
      }
    }

    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: widget.fontSize,
            height: widget.fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          AppSpacing.widthSm,
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, color: textColor, size: widget.fontSize + 2),
          if (widget.text.isNotEmpty) AppSpacing.widthSm,
        ],
        if (widget.text.isNotEmpty)
          Flexible(
            child: Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (widget.goldCost != null) ...[
          if (widget.text.isNotEmpty) AppSpacing.widthSm,
          Icon(
            Icons.monetization_on,
            color: Colors.amber,
            size: widget.fontSize + 2,
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.goldCost}',
            style: TextStyle(
              color: Colors.amber,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );

    return MouseRegion(
      onEnter: isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: isEnabled ? (_) => setState(() => _isHovered = false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: _isHovered && isEnabled ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (_isHovered && isEnabled && !isParchment)
                BoxShadow(
                  color: (widget.baseColor ?? theme.colorScheme.primary)
                      .withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: isEnabled ? _handleTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(child: buttonContent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
