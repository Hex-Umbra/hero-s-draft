import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing Constants
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Height SizedBox Helpers
  static const SizedBox heightXs = SizedBox(height: xs);
  static const SizedBox heightSm = SizedBox(height: sm);
  static const SizedBox heightMd = SizedBox(height: md);
  static const SizedBox heightLg = SizedBox(height: lg);
  static const SizedBox heightXl = SizedBox(height: xl);
  static const SizedBox heightXxl = SizedBox(height: xxl);

  // Width SizedBox Helpers
  static const SizedBox widthXs = SizedBox(width: xs);
  static const SizedBox widthSm = SizedBox(width: sm);
  static const SizedBox widthMd = SizedBox(width: md);
  static const SizedBox widthLg = SizedBox(width: lg);
  static const SizedBox widthXl = SizedBox(width: xl);
  static const SizedBox widthXxl = SizedBox(width: xxl);

  // Common EdgeInsets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  static const EdgeInsets paddingHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVMd = EdgeInsets.symmetric(vertical: md);
}
