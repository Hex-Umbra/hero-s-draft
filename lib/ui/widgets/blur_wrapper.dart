import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BlurWrapper extends StatelessWidget {
  final Widget child;
  final double sigma;

  const BlurWrapper({super.key, required this.child, this.sigma = 8.0});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: child,
      );
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}
