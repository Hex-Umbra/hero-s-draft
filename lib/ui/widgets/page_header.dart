import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool isParchment;
  final VoidCallback? onBackPressed;

  const PageHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.isParchment = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isParchment ? const Color(0xFF4A3728) : Colors.white;
    final iconColor = isParchment ? const Color(0xFF4A3728) : Colors.white;

    final leadingButton = showBackButton
        ? IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: iconColor, size: 20),
            onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
          )
        : null;

    return AppBar(
      title: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          fontSize: 20,
          shadows: isParchment
              ? null
              : [
                  Shadow(
                    color: Colors.black.withAlpha(150),
                    offset: const Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
        ),
      ),
      leading: leadingButton,
      actions: actions,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
