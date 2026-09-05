import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/controllers/debug_run_controller.dart';
import '../game/controllers/run_controller.dart';
import '../game/controllers/deck_controller.dart';
import '../game/controllers/inventory_controller.dart';
import '../models/inventory_state.dart';
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

  /// Une run debug ne persiste rien : ni ecriture, ni effacement.
  ///
  /// Le verrou est ici, et non chez les appelants, pour deux raisons. Il y a
  /// quatre points d'appel — un pour `save`, trois pour `clear` — et rien ne
  /// garantit qu'il n'y en aura pas un cinquieme. Surtout, l'effacement est
  /// aussi destructeur que l'ecriture : un menu de debug capable de tuer le
  /// heros mene a `DeathOverlay`, qui efface la sauvegarde. Proteger la seule
  /// ecriture aurait laisse la vraie partie disparaitre par la porte d'a cote.
  static bool _isDebugRun(RefReader read) => read(debugRunProvider).isDebugRun;

  static Future<void> save(RefReader read) async {
    if (_isDebugRun(read)) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'schemaVersion': _schemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'run': read(runProvider).toJson(),
      'deck': read(deckProvider).toJson(),
      'inventory': read(inventoryProvider).toJson(),
    };
    await prefs.setString(_saveKey, jsonEncode(payload));
  }

  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  static Future<void> clear(RefReader read) async {
    if (_isDebugRun(read)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  static Future<SaveLoadResult> load(RefReader read) async {
    // Charger, c'est reprendre une run legitime : le mode debug d'une run
    // precedente ne doit pas la suivre. Fait en premier, avant les `clear`
    // du chemin « sauvegarde corrompue », qu'il debloque au passage.
    read(debugRunProvider.notifier).clearForLoadedRun();

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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SaveService.load: corrupted or unsupported save data ($e)');
      }
      await clear(read);
      return const SaveLoadResult(success: false);
    }

    try {
      final (inventory, invMissing) = InventoryState.fromJsonWithReport(
        json['inventory'] as Map<String, dynamic>,
      );
      final (deck, deckMissing) = DeckState.fromJsonWithReport(
        json['deck'] as Map<String, dynamic>,
      );
      final (run, runMissing) = RunState.fromJsonWithReport(
        json['run'] as Map<String, dynamic>,
      );

      read(inventoryProvider.notifier).hydrate(inventory);
      read(deckProvider.notifier).hydrate(deck);
      read(runProvider.notifier).hydrate(run);

      return SaveLoadResult(
        success: true,
        missingItems: [...invMissing, ...deckMissing, ...runMissing],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SaveService.load: failed to hydrate save data ($e)');
      }
      await clear(read);
      return const SaveLoadResult(success: false);
    }
  }
}
