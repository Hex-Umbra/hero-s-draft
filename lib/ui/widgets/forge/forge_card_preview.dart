import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/card_instance.dart';
import '../ui_card.dart';
import '../ui_card/ui_card_helpers.dart';

/// La carte d'un dialogue de forge, et une prise par rune qu'elle porte —
/// aucune vide : la capacité n'existe plus (spec P-43 E2, §4.5, §4.10).
class ForgeCardPreview extends StatelessWidget {
  final CardInstance card;
  final String locale;
  final AppLocalizations l10n;

  const ForgeCardPreview({
    super.key,
    required this.card,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 170,
          child: UiCard.fromInstance(
            card: card,
            locale: locale,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 120.0,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 6.0,
            runSpacing: 6.0,
            children: [
              ...card.forgeUpgrades.map((upgrade) => Container(
                    width: 18.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                      border: Border.all(
                        color: Colors.cyanAccent,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 3.0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          getRuneEmoji(upgrade),
                          style: const TextStyle(fontSize: 11.0),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
