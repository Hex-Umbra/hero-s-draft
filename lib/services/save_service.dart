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
import 'save_migrations.dart';

/// The subset of Ref/WidgetRef/ProviderContainer that SaveService needs:
/// a plain synchronous provider read. Accepting this instead of `Ref`
/// lets the same code run from a Notifier's `ref`, a widget's `WidgetRef`,
/// and a bare `ProviderContainer` in tests — none of which share a common
/// supertype in riverpod 2.6.1, but all of which expose this exact method.
typedef RefReader = T Function<T>(ProviderListenable<T> provider);

class SaveLoadResult {
  final bool success;
  final List<MissingSaveItem> missingItems;

  /// La sauvegarde a été écrite par un build plus récent : elle n'est pas
  /// chargée, mais elle est conservée pour ce build-là.
  final bool savedByNewerBuild;

  const SaveLoadResult({
    required this.success,
    this.missingItems = const [],
    this.savedByNewerBuild = false,
  });
}

class SaveService {
  // La version vit dans le blob, et `saveMigrator` amène un blob ancien à la
  // version courante. La clé n'a changé qu'une fois : les builds publiés
  // jusqu'à 0.5.1 lisent `run_save_v1` et effacent toute version autre que 1.
  // Toutes les versions web partagent le même stockage, et ces builds-là ne
  // se corrigent plus (spec P-41, §4.3).
  static const String _saveKey = 'run_save';
  static const String _legacySaveKey = 'run_save_v1';

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
      'schemaVersion': saveMigrator.currentVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'run': read(runProvider).toJson(),
      'deck': read(deckProvider).toJson(),
      'inventory': read(inventoryProvider).toJson(),
    };
    await prefs.setString(_saveKey, jsonEncode(payload));
    // La partie vit désormais sous la nouvelle clé : l'ancienne copie ne doit
    // plus être proposée, ni ici, ni par un build antérieur.
    await prefs.remove(_legacySaveKey);
  }

  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey) || prefs.containsKey(_legacySaveKey);
  }

  static Future<void> clear(RefReader read) async {
    if (_isDebugRun(read)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    await prefs.remove(_legacySaveKey);
  }

  static Future<SaveLoadResult> load(RefReader read) async {
    // Charger, c'est reprendre une run legitime : le mode debug d'une run
    // precedente ne doit pas la suivre. Fait en premier, avant les `clear`
    // du chemin « sauvegarde corrompue », qu'il debloque au passage.
    read(debugRunProvider.notifier).clearForLoadedRun();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey) ?? prefs.getString(_legacySaveKey);
    if (raw == null) {
      return const SaveLoadResult(success: false);
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Save data is not a JSON object');
      }
      json = saveMigrator.migrate(decoded);
    } on SaveFromNewerBuildException catch (e) {
      // Ni lisible ici, ni corrompue : la laisser intacte pour le build qui
      // l'a écrite. L'écran d'accueil l'explique au joueur.
      if (kDebugMode) {
        debugPrint('SaveService.load: save written by a newer build ($e)');
      }
      return const SaveLoadResult(success: false, savedByNewerBuild: true);
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
