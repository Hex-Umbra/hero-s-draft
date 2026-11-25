import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/systems/decor_fit.dart';
import '../../models/data/location_data.dart';
import '../../services/game_data_service.dart';

/// Le décor du lieu courant derrière un écran (spec P-05, vague 2, §5.8) :
/// sans image pour [screen], le [fallback] ; sinon l'image, posée comme celle
/// du combat par [decorFitFor] et rognée à l'écran, puis [child] par-dessus.
class LocationBackdrop extends ConsumerWidget {
  final DecorScreen screen;
  final Widget fallback;
  final Widget child;

  const LocationBackdrop({
    super.key,
    required this.screen,
    required this.fallback,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(currentLocationProvider)?.decorFor(screen);
    if (path == null) return fallback;

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = decorFitFor(
          screen: constraints.biggest,
          devicePixelRatio: pixelRatio,
        );
        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: fit.left,
                top: fit.top,
                width: decorWidth * fit.scale,
                height: decorHeight * fit.scale,
                child: Image.asset(
                  path,
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned.fill(child: child),
            ],
          ),
        );
      },
    );
  }
}
