import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/data/signature_evolution_data.dart';
import '../../models/signature_instance.dart';
import 'effect_style.dart';
import 'ui_card/ui_card_helpers.dart';

/// La fiche d'une signature de la run, hors combat : ce qu'elle fait avec ses
/// évolutions, celles qui ont été prises, et quand viendra la prochaine.
///
/// Elle lit une `SignatureInstance`, là où `SignatureTile` lit la donnée de
/// base. La prochaine évolution se dit par son rang et le niveau du héros,
/// sans chiffre d'XP : une signature n'a pas d'expérience à elle.
class SignatureRunCard extends StatelessWidget {
  final SignatureInstance signature;
  final int heroLevel;
  final Color classColor;

  const SignatureRunCard({
    super.key,
    required this.signature,
    required this.heroLevel,
    required this.classColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final data = signature.data;
    final level = signature.level;
    final taken = signature.taken;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: neutralCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: classColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.getName(locale),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (level > 0) _levelBadge(l10n.levelLabel(level)),
            ],
          ),
          Text(
            getCardTypeLabel(context, data.type),
            style: TextStyle(color: getCardTypeColor(data.type), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.signatureCostAndCooldown(signature.cost, signature.cooldown),
            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            signature.asCard.data.getDescription(locale),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (taken.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 16),
            for (final (evolution, evolutionLevel) in taken)
              _evolutionRow(evolution, evolutionLevel, locale),
          ],
          const SizedBox(height: 6),
          _nextEvolution(l10n),
        ],
      ),
    );
  }

  Widget _levelBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.withAlpha(120), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Une évolution prise : son icône, son nom, son niveau dès qu'il dépasse 1,
  /// et ce qu'elle apporte à ce niveau.
  Widget _evolutionRow(
    SignatureEvolutionData evolution,
    int level,
    String locale,
  ) {
    final name = evolution.getName(locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvolutionIcon(evolution: evolution, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: level > 1 ? '$name $level  ' : '$name  ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: evolution.getDescription(
                      level,
                      locale,
                      cost: signature.data.cost,
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextEvolution(AppLocalizations l10n) {
    if (signature.pendingFor(heroLevel) > 0) {
      return Text(
        l10n.signatureEvolutionPending,
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    final nextLevel = signature.nextEvolutionHeroLevel;
    return Text(
      signature.nextTier == EvolutionTier.minor
          ? l10n.signatureNextMinor(nextLevel)
          : l10n.signatureNextMajor(nextLevel),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 10.5,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
