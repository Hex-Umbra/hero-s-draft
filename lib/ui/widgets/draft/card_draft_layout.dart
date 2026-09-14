import 'package:flutter/material.dart';
import '../screen_scaffold.dart';
import '../game_button.dart';

class CardDraftLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cardCountText;
  final String confirmButtonText;
  final VoidCallback? onConfirm;
  final bool isConfirmEnabled;
  final Color themeColor;
  final Widget child;

  /// Affiche un bouton retour dans l'en-tête quand il est fourni. Un draft de
  /// récompense en cours de run n'en a pas : on ne revient pas sur un combat.
  final VoidCallback? onBack;

  const CardDraftLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cardCountText,
    required this.confirmButtonText,
    required this.onConfirm,
    required this.isConfirmEnabled,
    this.themeColor = Colors.amber,
    required this.child,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER immersif
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                // Transmet la largeur imposée : en `loose`, l'en-tête se
                // réduirait à son contenu et ne serait plus centré.
                fit: StackFit.passthrough,
                children: [
                  Padding(
                    // Le titre est centré : sans marge symétrique, il
                    // passerait sous le bouton retour sur un écran étroit.
                    padding: EdgeInsets.symmetric(
                      horizontal: onBack == null ? 0 : 40,
                    ),
                    child: _buildHeaderContent(isMobile),
                  ),
                  if (onBack != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: onBack,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contenu principal (Grille de cartes)
            Expanded(child: child),

            // Pied de page (Bouton valider)
            const SizedBox(height: 20),
            Center(
              child: GameButton(
                text: confirmButtonText.toUpperCase(),
                onPressed: isConfirmEnabled ? onConfirm : null,
                baseColor: isConfirmEnabled ? Colors.green : Colors.grey,
                width: 250,
                height: 50,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent(bool isMobile) {
    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w900,
            color: themeColor,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: themeColor.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isMobile ? 11 : 14,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Badge Compteur
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isConfirmEnabled
                ? Colors.green.withValues(alpha: 0.2)
                : themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConfirmEnabled
                  ? Colors.green
                  : themeColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            cardCountText,
            style: TextStyle(
              color: isConfirmEnabled
                  ? Colors.greenAccent
                  : themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
