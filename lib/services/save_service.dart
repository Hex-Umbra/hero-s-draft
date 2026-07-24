import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/controllers/run_controller.dart';
import '../game/controllers/deck_controller.dart';
import '../game/controllers/inventory_controller.dart';
import '../game/controllers/skill_controller.dart';
import '../models/inventory_state.dart';
import '../models/skill_state.dart';
import '../models/missing_save_item.dart';

/// The subset of Ref/WidgetRef/ProviderContainer that SaveService needs:
/// a plain synchronous provider read. Accepting this instead of `Ref`
/// lets the same code run from a Notifier's `ref`, a widget's `WidgetRef`,
/// and a bare `ProviderContainer` in tests — none of which share a common
/// supertype in riverpod 2.6.1, but all of which expose this exact method.
typedef RefReader = T Function<T>(ProviderListenable<T> provider);

class SaveLoadResult {
  final bool success;
  final List<MissingSaveItem> missingItems;

  const SaveLoadResult({required this.success, this.missingItems = const []});
}

class SaveService {
  static const String _saveKey = 'run_save_v1';
  static const int _schemaVersion = 1;

  static Future<void> save(RefReader read) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'schemaVersion': _schemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'run': read(runProvider).toJson(),
      'deck': read(deckProvider).toJson(),
      'inventory': read(inventoryProvider).toJson(),
      'skills': read(skillProvider).toJson(),
    };
    await prefs.setString(_saveKey, jsonEncode(payload));
  }

  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  static Future<SaveLoadResult> load(RefReader read) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) {
      return const SaveLoadResult(success: false);
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['schemaVersion'] != _schemaVersion) {
        throw const FormatException('Unsupported or missing schemaVersion');
      }
      json = decoded;
    } catch (_) {
      await clear();
      return const SaveLoadResult(success: false);
    }

    try {
      final skills = SkillState.fromJson(json['skills'] as Map<String, dynamic>);
      final (inventory, invMissing) = InventoryState.fromJsonWithReport(
        json['inventory'] as Map<String, dynamic>,
      );
      final (deck, deckMissing) = DeckState.fromJsonWithReport(
        json['deck'] as Map<String, dynamic>,
      );
      final (run, runMissing) = RunState.fromJsonWithReport(
        json['run'] as Map<String, dynamic>,
      );

      read(skillProvider.notifier).hydrate(skills);
      read(inventoryProvider.notifier).hydrate(inventory);
      read(deckProvider.notifier).hydrate(deck);
      read(runProvider.notifier).hydrate(run);

      return SaveLoadResult(
        success: true,
        missingItems: [...invMissing, ...deckMissing, ...runMissing],
      );
    } catch (_) {
      await clear();
      return const SaveLoadResult(success: false);
    }
  }
}
