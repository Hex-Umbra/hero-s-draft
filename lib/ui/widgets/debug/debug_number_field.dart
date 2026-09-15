import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_spacing.dart';

/// Champ entier du menu de debug : applique la valeur a la validation.
/// Purement local — il ne detient aucun etat metier.
class DebugNumberField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onSubmitted;

  const DebugNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onSubmitted,
  });

  @override
  State<DebugNumberField> createState() => _DebugNumberFieldState();
}

class _DebugNumberFieldState extends State<DebugNumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value.toString(),
  );

  @override
  void didUpdateWidget(covariant DebugNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingVSm,
      child: Row(
        children: [
          Expanded(child: Text(widget.label)),
          SizedBox(
            width: 96,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(isDense: true),
              onSubmitted: (raw) {
                final parsed = int.tryParse(raw);
                if (parsed != null) widget.onSubmitted(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
