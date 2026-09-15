import 'package:flutter/material.dart';

import 'editor_style.dart';

/// Le poids d'un bouton de l'editeur.
enum EditorButtonTone {
  /// Un geste secondaire : Charger, aucune.
  quiet,

  /// Un geste courant : Valider, Importer…
  outlined,

  /// Le seul geste qui engage le disque : Écrire.
  primary,
}

/// Un bouton de l'editeur, dessine comme `GameButton` — bord neon, lueur et
/// leger grossissement au survol — mais sans son d'interface : l'editeur n'est
/// pas un menu du jeu, et `GameButton` exigerait le directeur audio dans
/// chaque test.
class EditorButton extends StatefulWidget {
  const EditorButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = EditorButtonTone.outlined,
    this.dense = false,
  });

  final String label;
  final IconData icon;

  /// `null` : le bouton est inerte, et le montre.
  final VoidCallback? onPressed;
  final EditorButtonTone tone;

  /// Le format des gestes de champ : Importer…, aucune.
  final bool dense;

  @override
  State<EditorButton> createState() => _EditorButtonState();
}

class _EditorButtonState extends State<EditorButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final hovered = _hovered && enabled;
    final dense = widget.dense;
    const accent = EditorColors.accent;

    final Color fill;
    final Color edge;
    final Color ink;
    if (!enabled) {
      fill = Colors.white.withValues(alpha: 0.05);
      edge = EditorColors.line;
      ink = EditorColors.faint;
    } else {
      switch (widget.tone) {
        case EditorButtonTone.quiet:
          fill = hovered ? const Color(0xFF1C1C34) : Colors.transparent;
          edge = hovered ? const Color(0xFF6A6A95) : EditorColors.lineStrong;
          ink = EditorColors.soft;
        case EditorButtonTone.outlined:
          fill = accent.withValues(alpha: hovered ? 0.22 : 0.1);
          edge = hovered ? accent : accent.withValues(alpha: 0.5);
          ink = accent;
        case EditorButtonTone.primary:
          fill = hovered ? const Color(0xFF45E0FF) : accent;
          edge = accent;
          ink = EditorColors.accentInk;
      }
    }
    final glows = enabled &&
        widget.tone != EditorButtonTone.quiet &&
        (hovered || widget.tone == EditorButtonTone.primary);
    final radius = BorderRadius.circular(dense ? 7 : 11);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedScale(
        scale: hovered && !MediaQuery.disableAnimationsOf(context) ? 1.03 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: dense ? 32 : 40,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: edge, width: dense ? 1 : 2),
            boxShadow: [
              if (glows)
                BoxShadow(
                  color: accent.withValues(alpha: hovered ? 0.45 : 0.28),
                  blurRadius: hovered ? 20 : 16,
                ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: dense ? 16 : 19, color: ink),
                    SizedBox(width: dense ? 5 : 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: ink,
                        fontSize: dense ? 12.5 : 14,
                        fontWeight: dense ? FontWeight.w600 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
