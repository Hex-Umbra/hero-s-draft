import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/decor_fit.dart';

/// Le cadrage du décor de combat (spec P-05, vague 2, §5.2).
void main() {
  DecorFit fit(double width, double height, {double ratio = 1}) =>
      decorFitFor(screen: Size(width, height), devicePixelRatio: ratio);

  test('3, 4 et 6 en 1080p, 1440p et 4K, sans decalage', () {
    for (final (width, height, scale) in [
      (1920.0, 1080.0, 3.0),
      (2560.0, 1440.0, 4.0),
      (3840.0, 2160.0, 6.0),
    ]) {
      final result = fit(width, height);

      expect(result.scale, scale);
      expect(result.left, 0);
      expect(result.top, 0);
    }
  });

  test('3 en 1920 x 1009, centre', () {
    final result = fit(1920, 1009);

    expect(result.scale, 3);
    expect(result.left, 0);
    expect(result.top, -36);
    expect(1080 + result.top * 2 - 1009, -1, reason: '36 en haut, 35 en bas');
  });

  test('2 en 1280 x 720', () {
    expect(fit(1280, 720).scale, 2);
  });

  test('1,975 dans la fenetre restauree, 1264 x 681', () {
    expect(fit(1264, 681).scale, closeTo(1.975, 1e-9));
  });

  test('2,22 en 1280 x 800, centre, 71 pixels rognes de chaque cote (B88)',
      () {
    final result = fit(1280, 800);

    expect(result.scale, closeTo(2.2222, 1e-4));
    expect(result.left, -71);
    expect(result.top, 0);
  });

  test('le rapport de pixels', () {
    final result = fit(1536, 864, ratio: 1.25);

    expect(result.scale, closeTo(2.4, 1e-9));
    expect(result.left, 0);
    expect(result.top, 0);
  });
}
