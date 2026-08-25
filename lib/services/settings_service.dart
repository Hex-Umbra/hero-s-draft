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

  static Future<void> save(AudioSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'schemaVersion': _schemaVersion,
      ...settings.toJson(),
    };
    await prefs.setString(_settingsKey, jsonEncode(payload));
  }

  static Future<AudioSettings> load() async {
    try {
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
