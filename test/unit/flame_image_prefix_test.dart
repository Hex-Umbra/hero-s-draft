import 'package:flame/flame.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/heros_draft_game.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';

HerosDraftGame _buildGame() => HerosDraftGame(
      audio: AudioDirector(
        backend: const SilentAudioBackend(),
        data: const AudioData.disabled(),
        settings: () => const AudioSettings(),
      ),
      imagesToPreload: const [],
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
}
