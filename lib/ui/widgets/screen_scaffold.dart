import 'package:flutter/material.dart';

enum ScreenBackgroundType { dark, parchment, none }

class ScreenScaffold extends StatelessWidget {
  final ScreenBackgroundType backgroundType;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool useSafeArea;
  final bool? canPop;
  final void Function(bool, dynamic)? onPopInvokedWithResult;

  const ScreenScaffold({
    super.key,
    required this.body,
    this.backgroundType = ScreenBackgroundType.dark,
    this.appBar,
    this.useSafeArea = true,
    this.canPop,
    this.onPopInvokedWithResult,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    Decoration? decoration;
    Color? backgroundColor;

    switch (backgroundType) {
      case ScreenBackgroundType.dark:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              const Color(0xFF1A0A00).withAlpha(120),
              Colors.black,
            ],
          ),
        );
        backgroundColor = const Color(0xFF0D0D1A);
        break;
      case ScreenBackgroundType.parchment:
        decoration = const BoxDecoration(
          color: Color(0xFFF5DEB3),
          gradient: RadialGradient(
            colors: [
              Color(0xFFF5DEB3),
              Color(0xFFE8D5B5),
              Color(0xFFD2B48C),
            ],
            radius: 1.5,
          ),
        );
        backgroundColor = const Color(0xFFE8D5B5);
        break;
      case ScreenBackgroundType.none:
        backgroundColor = Colors.transparent;
        break;
    }

    Widget scaffoldBody = content;
    if (decoration != null) {
      scaffoldBody = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: decoration,
        child: content,
      );
    }

    Widget mainWidget = Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: scaffoldBody,
    );

    if (canPop != null || onPopInvokedWithResult != null) {
      mainWidget = PopScope(
        canPop: canPop ?? true,
        onPopInvokedWithResult: onPopInvokedWithResult,
        child: mainWidget,
      );
    }

    return mainWidget;
  }
}
