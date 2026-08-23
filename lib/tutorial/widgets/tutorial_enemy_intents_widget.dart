import 'package:flutter/material.dart';

import '../../models/enemy_instance.dart';
import '../../models/enemy_intent.dart';
import '../../models/entity_stats.dart';
import '../../ui/widgets/hud/enemy_intents_panel.dart';
import '../tutorial_engine.dart';

/// Un palier d'attaque de `enemy_intents_panel.dart` : son icône, sa
/// couleur, son libellé bilingue et le seuil de valeur qui le déclenche.
/// Sert uniquement à légender le panneau ci-dessous ; le calcul du palier
/// lui-même reste dans `EnemyIntentsPanel`, jamais dupliqué ici.
class _IntentTierLegend {
  final IconData icon;
  final Color color;
  final String labelFr;
  final String labelEn;
  final String range;

  const _IntentTierLegend({
    required this.icon,
    required this.color,
    required this.labelFr,
    required this.labelEn,
    required this.range,
  });
}

/// Étape 11 — les intentions ennemies, sur le vrai panneau du HUD.
///
/// Le panneau réellement affiché en combat (`EnemyIntentsPanel`) est
/// réutilisé tel quel, avec quatre `EnemyInstance` fixtures qui ne varient
/// que par la valeur de leur intention (4, 8, 15, 22). `effectiveIntent`
/// range chacune dans un des quatre paliers d'attaque réels : les icônes,
/// couleurs et libellés affichés viennent du panneau lui-même, jamais d'une
/// copie locale.
class TutorialEnemyIntentsWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialEnemyIntentsWidget({super.key, required this.engine});

  static const List<_IntentTierLegend> _tiers = [
    _IntentTierLegend(
      icon: Icons.bolt,
      color: Color(0xFFF39C12),
      labelFr: 'Rapide',
      labelEn: 'Quick',
      range: '< 6',
    ),
    _IntentTierLegend(
      icon: Icons.flash_on,
      color: Color(0xFFFF7675),
      labelFr: 'Attaque',
      labelEn: 'Attack',
      range: '6–11',
    ),
    _IntentTierLegend(
      icon: Icons.whatshot,
      color: Color(0xFFE74C3C),
      labelFr: 'Lourde',
      labelEn: 'Heavy',
      range: '12–19',
    ),
    _IntentTierLegend(
      icon: Icons.gavel,
      color: Color(0xFFC0392B),
      labelFr: 'Dévastatrice',
      labelEn: 'Devastating',
      range: '≥ 20',
    ),
  ];

  /// Ennemi d'entraînement dont l'intention d'attaque affichée vaut [value].
  ///
  /// `attaque: data.baseDamage` annule le multiplicateur de mise à l'échelle
  /// d'`EnemyInstance.effectiveIntent` (`stats.attaque / data.baseDamage`) :
  /// la valeur rendue par le panneau est bien [value].
  EnemyInstance _sample(int value) {
    final data = engine.fixtures.trainingEnemy;
    return EnemyInstance(
      data: data,
      stats: EntityStats(
        maxPv: data.maxHp,
        currentPv: data.maxHp,
        armure: 0,
        attaque: data.baseDamage,
      ),
      currentIntent: EnemyIntent(type: IntentType.attack, value: value),
    );
  }

  Widget _legendRow(bool isFrench, _IntentTierLegend tier) {
    final label = isFrench ? tier.labelFr : tier.labelEn;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(tier.icon, color: tier.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: tier.color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            tier.range,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final enemies = [4, 8, 15, 22].map(_sample).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            isFrench
                ? 'Le panneau réel (normalement en bas à droite) :'
                : 'The real panel (normally bottom-right):',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          EnemyIntentsPanel(enemies: enemies),
          const SizedBox(height: 20),
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF334155).withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isFrench ? 'Paliers d\'attaque' : 'Attack tiers',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const Divider(color: Colors.white12, height: 14),
                ..._tiers.map((tier) => _legendRow(isFrench, tier)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
