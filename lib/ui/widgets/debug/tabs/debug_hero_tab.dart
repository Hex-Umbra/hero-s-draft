import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../debug_number_field.dart';

class DebugHeroTab extends ConsumerWidget {
  const DebugHeroTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(runProvider).heroStats;

    return ListView(
      children: [
        DebugNumberField(
          label: 'PV',
          value: stats.currentPv,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(currentPv: v),
          ),
        ),
        DebugNumberField(
          label: 'PV max',
          value: stats.maxPv,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(maxPv: v),
          ),
        ),
        DebugNumberField(
          label: 'Mana',
          value: stats.currentMana,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(currentMana: v),
          ),
        ),
        DebugNumberField(
          label: 'Mana max',
          value: stats.maxMana,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(maxMana: v),
          ),
        ),
        DebugNumberField(
          label: 'Armure',
          value: stats.armure,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(armure: v),
          ),
        ),
        DebugNumberField(
          label: 'Attaque',
          value: stats.attaque,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(attaque: v),
          ),
        ),
        DebugNumberField(
          label: 'Chance',
          value: stats.luck,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(luck: v),
          ),
        ),
        DebugNumberField(
          label: 'Niveau',
          value: stats.level,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(level: v),
          ),
        ),
        DebugNumberField(
          label: 'XP',
          value: stats.xp,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(xp: v),
          ),
        ),
        DebugNumberField(
          label: 'Chance de critique (%)',
          value: stats.critChance,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(critChance: v),
          ),
        ),
        TextButton(
          onPressed: () => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(currentPv: s.maxPv),
          ),
          child: const Text('Soin complet'),
        ),
        TextButton(
          onPressed: () => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(currentMana: s.maxMana),
          ),
          child: const Text('Mana plein'),
        ),
      ],
    );
  }
}
