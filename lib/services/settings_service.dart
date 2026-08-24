import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_settings.dart';

/// Persistance des preferences du joueur.
///
/// Cle distincte de celle de `SaveService` : `GameOverScreen` efface la
/// sauvegarde de run a la mort du heros, et le volume ne doit pas mourir
/// avec le personnage.
///
/// Asymetrie assumee avec `SaveService` : un JSON illisible ou une version
/// de schema inconnue retombe **silencieusement** sur les defauts. Perdre un
/// reglage de volume ne justifie pas un ecran d'erreur.
class SettingsService {
  static const String _settingsKey = 'settings_v1';
  static const int _schemaVersion = 1;

  /// L'ecriture disque en cours, le cas echeant.
  ///
  /// `AudioSettingsNotifier` appelle [save] sans l'attendre : un curseur de
  /// volume ne doit pas se figer pour une ecriture disque. Sans ce suivi,
  /// un [load] lance juste apres une [save] non attendue peut gagner la
  /// course face au tout premier `SharedPreferences.getInstance()` du
  /// processus (son Completer interne resout les appels concurrents dans un
  /// ordre qui ne respecte pas l'ordre d'appel) et relire l'ancienne valeur.
  /// [load] attend donc l'ecriture en cours avant de lire.
  static Future<void>? _pendingSave;

  static Future<void> save(AudioSettings settings) {
    final future = _persist(settings);
    _pendingSave = future;
    return future;
  }

  static Future<void> _persist(AudioSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'schemaVersion': _schemaVersion,
      ...settings.toJson(),
    };
    await prefs.setString(_settingsKey, jsonEncode(payload));
  }

  static Future<AudioSettings> load() async {
    try {
      if (_pendingSave != null) {
        await _pendingSave;
      }
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw == null) return const AudioSettings();

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const AudioSettings();
      if (decoded['schemaVersion'] != _schemaVersion) return const AudioSettings();

      return AudioSettings.fromJson(decoded);
    } catch (_) {
      return const AudioSettings();
    }
  }
}
