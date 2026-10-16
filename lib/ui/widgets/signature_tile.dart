import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/data/signature_data.dart';
import 'ui_card/ui_card_helpers.dart';

/// La signature d'une classe hors combat : une tuile rectangulaire qui lit la
/// donnée, jamais une `SignatureInstance` (hors combat, il n'y a pas de run).
///
/// [detailed] est la version du dictionnaire : typographie pleine et libellé
/// du type sous le nom ; la version compacte est celle de la sélection de classe.
class SignatureTile extends StatelessWidget {
  final SignatureData signature;
  final Color classColor;
  final bool detailed;

  const SignatureTile({
    super.key,
    required this.signature,
    required this.classColor,
    this.detailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final nameSize = detailed ? 18.0 : 13.0;
    final bodySize = detailed ? 14.0 : 11.0;

    return Container(
      decoration: BoxDecoration(
        color: neutralCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: classColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(detailed ? 12 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              signature.getName(locale),
              style: TextStyle(
                color: Colors.white,
                fontSize: nameSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (detailed)
              Text(
                getCardTypeLabel(context, signature.type),
                style: TextStyle(
                  color: getCardTypeColor(signature.type),
                  fontSize: bodySize,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              l10n.signatureCostAndCooldown(signature.cost, signature.cooldown),
              style: TextStyle(color: Colors.amberAccent, fontSize: bodySize),
            ),
            const SizedBox(height: 4),
            Text(
              signature.getDescription(locale),
              style: TextStyle(color: Colors.white70, fontSize: bodySize),
            ),
          ],
        ),
      ),
    );
  }
}
