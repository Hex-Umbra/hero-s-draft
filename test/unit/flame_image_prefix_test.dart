import 'package:flame/flame.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/heros_draft_game.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

HerosDraftGame _buildGame({List<String> imagesToPreload = const []}) =>
    HerosDraftGame(
      audio: AudioDirector(
        backend: const SilentAudioBackend(),
        data: const AudioData.disabled(),
        settings: () => const AudioSettings(),
      ),
      imagesToPreload: imagesToPreload,
      onEnemiesDead: () {},
      onPhaseChanged: (_) {},
      onShowTooltip: (_, _, _) {},
      onHideTooltip: () {},
      onPlayCard: (_, _) => false,
      onEnemyKilled: () {},
      onResolveEnemyIntent: (_) {},
      onStartEnemyTurn: () {},
      onEndEnemyTurn: () {},
      onSelectEnemy: (_) {},
      onUpdateEnemyStats: (_, _) {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le jeu charge ses images sous un prefixe vide', () {
    expect(_buildGame().images.prefix, isEmpty);
  });

  test('le jeu n emprunte pas le cache global de Flame', () {
    // Muter `Flame.images` en place changerait le prefixe pour tout le
    // processus — et la mutation survivrait d un test widget a l autre dans
    // le meme isolate, rendant les tests dependants de leur ordre.
    final game = _buildGame();
    expect(identical(game.images, Flame.images), isFalse);
    expect(Flame.images.prefix, 'assets/images/');

    // Deux jeux ne partagent pas non plus leur cache entre eux.
    expect(identical(game.images, _buildGame().images), isFalse);
  });

  test('les 8 images se chargent sous des cles distinctes egales a leur chemin', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final game = _buildGame(imagesToPreload: registry.imagesToPreload);
    final paths = <String>{'assets/images/bg_dungeon.png', ...registry.imagesToPreload};

    await game.images.loadAll(paths.toList());

    // Le prefixe ne fait PAS partie des cles (`flame/.../images.dart:29-32`) :
    // avec un prefixe par dossier, les trois `icon.png` s ecraseraient. 8 cles
    // distinctes egales aux chemins complets, c est la preuve du contraire.
    expect(game.images.keys.toSet(), paths);
    expect(game.images.keys, hasLength(8));

    // Exactement l appel de HeroCard.onLoad (`hero_card.dart:113`), atteint par
    // `state_sync_system.dart:52`. `fromCache` leve si la cle est absente.
    for (final hero in registry.heroes) {
      expect(() => game.images.fromCache(hero.iconPath), returnsNormally);
    }
  });
}
