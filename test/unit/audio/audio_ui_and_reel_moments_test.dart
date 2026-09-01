import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

/// Monte le directeur sur le VRAI `assets/data/audio.json`.
///
/// Les autres tests de resolution travaillent sur un catalogue jouet, ce qui
/// est le bon choix pour eprouver la mecanique. Ici c'est l'inverse qu'on
/// veut : verifier que la donnee livree cable bien les nouveaux moments, et
/// que les cles de rarete du catalogue correspondent aux valeurs reellement
/// emises par `RewardRarity`.
Future<AudioDirector> _directorOnRealCatalogue(FakeAudioBackend backend) async {
  final raw = await rootBundle.loadString('assets/data/audio.json');
  final director = AudioDirector(
    backend: backend,
    data: AudioData.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
    random: Random(42),
  );
  await director.preloadAll();
  return director;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Moments d interface et de rouleau', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('chaque nouveau moment produit un son sur le catalogue livre', () async {
      final director = await _directorOnRealCatalogue(backend);

      for (final moment in [
        GameMoment.uiTap,
        GameMoment.mapNodeSelect,
        GameMoment.draftCardPick,
        GameMoment.carouselTick,
        GameMoment.carouselLand,
        GameMoment.reelTick,
        GameMoment.reelLand,
        GameMoment.armorGain,
      ]) {
        director.onMoment(moment);
      }

      expect(backend.playedOnce, hasLength(8));
    });

    // Le defaut d'origine : gagner de l'armure jouait `armor_hit`, le son du
    // coup ENCAISSE. Une carte defensive sonnait donc comme une carte subie.
    test('gagner de l armure ne joue pas le son du coup encaisse', () async {
      final director = await _directorOnRealCatalogue(backend);

      director.onMoment(GameMoment.armorHit);
      director.onMoment(GameMoment.armorGain);

      expect(backend.playedOnce, hasLength(2));
      expect(backend.playedOnce.first, isNot(backend.playedOnce.last));
    });

    // Les cles de `byAnimation` doivent correspondre a `RewardRarity.name`.
    // Le libelle passe a `DraftCardReel.rarity` est localise ; s'y fier
    // aurait rendu le son dependant de la langue.
    test('la revelation du rouleau change de son selon la rarete', () async {
      final director = await _directorOnRealCatalogue(backend);

      for (final rarity in ['common', 'uncommon', 'rare', 'epic', 'legendary']) {
        director.onMoment(GameMoment.reelLand,
            source: VariantAudioSource(rarity));
      }

      expect(backend.playedOnce.toSet(), hasLength(5),
          reason: 'les 5 raretes doivent resoudre 5 fichiers distincts');
    });

    test('une rarete inconnue du catalogue retombe sur le son par defaut', () async {
      final director = await _directorOnRealCatalogue(backend);

      director.onMoment(GameMoment.reelLand,
          source: const VariantAudioSource('rarete_inventee'));
      director.onMoment(GameMoment.reelLand);

      expect(backend.playedOnce.first, backend.playedOnce.last);
    });

    test('VariantAudioSource ne declare jamais de son propre', () {
      const source = VariantAudioSource('legendary');

      // Sinon elle court-circuiterait au niveau 1 la variante qu'elle pose.
      expect(source.sfx, isNull);
      expect(source.animation, 'legendary');
    });
  });
}
