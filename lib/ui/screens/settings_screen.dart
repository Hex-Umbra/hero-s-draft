import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/audio/audio_providers.dart';

/// Ecran de reglages, accessible depuis l'accueil. Seule section pour
/// l'instant : l'audio (volumes + coupure globale), qui s'applique aussi
/// bien en dehors qu'au sein d'un combat.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(audioSettingsProvider);
    final notifier = ref.read(audioSettingsProvider.notifier);
    final conductor = ref.read(musicConductorProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.audioSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _VolumeSlider(
            label: l10n.volumeMaster,
            value: settings.master,
            onChanged: (v) {
              notifier.setMaster(v);
              conductor.refreshVolume();
            },
          ),
          _VolumeSlider(
            label: l10n.volumeSfx,
            value: settings.sfx,
            // Pas de refreshVolume() ici : les bruitages relisent les
            // reglages a chaque tir ponctuel, ils n'ont pas d'etat a
            // rafraichir comme la boucle de musique.
            onChanged: notifier.setSfx,
          ),
          _VolumeSlider(
            label: l10n.volumeMusic,
            value: settings.music,
            onChanged: (v) {
              notifier.setMusic(v);
              conductor.refreshVolume();
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.muteAll),
            value: settings.muted,
            onChanged: (_) {
              notifier.toggleMute();
              conductor.refreshVolume();
            },
          ),
        ],
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            label: '${(value * 100).round()} %',
            divisions: 20,
          ),
        ),
      ],
    );
  }
}
