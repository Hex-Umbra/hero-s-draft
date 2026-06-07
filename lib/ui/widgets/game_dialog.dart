import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class GameDialog extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget content;
  final List<Widget>? actions;
  final Color? glowColor;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double maxWidth;
  final double blurSigmaX;
  final double blurSigmaY;

  const GameDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions,
    this.glowColor,
    this.showCloseButton = true,
    this.onClose,
    this.maxWidth = 500,
    this.blurSigmaX = 5.0,
    this.blurSigmaY = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeGlowColor = glowColor ?? Theme.of(context).colorScheme.primary;
    final isParchment =
        Theme.of(context).scaffoldBackgroundColor == AppColors.parchmentBg;

    final border = Border.all(
      color: isParchment
          ? AppColors.parchmentBorder
          : themeGlowColor.withValues(alpha: 0.6),
      width: 2,
    );

    final boxDecoration = BoxDecoration(
      color: isParchment
          ? AppColors.parchmentSurface
          : AppColors.darkSurface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      border: border,
      boxShadow: [
        if (!isParchment)
          BoxShadow(
            color: themeGlowColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );

    final titleStyle = TextStyle(
      color: isParchment ? AppColors.parchmentText : Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );

    final subtitleStyle = TextStyle(
      color: isParchment
          ? AppColors.parchmentInk.withValues(alpha: 0.7)
          : Colors.white70,
      fontSize: 14,
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: boxDecoration,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultTextStyle(
                              style: titleStyle,
                              child: title,
                            ),
                            if (subtitle != null) ...[
                              AppSpacing.heightXs,
                              DefaultTextStyle(
                                style: subtitleStyle,
                                child: subtitle!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showCloseButton)
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: isParchment
                              ? AppColors.parchmentText
                              : Colors.white70,
                          onPressed: onClose ?? () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                  const Divider(height: AppSpacing.md, thickness: 1),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: content,
                  ),
                  // Actions
                  if (actions != null && actions!.isNotEmpty) ...[
                    AppSpacing.heightMd,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.sm),
                              child: a,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
