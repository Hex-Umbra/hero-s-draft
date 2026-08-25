import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/services/audio/audio_providers.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioSettings', () {
    test('le volume effectif est le produit du general et de la categorie', () {
      const settings = AudioSettings(master: 0.5, sfx: 0.8, music: 0.6);

      expect(settings.effectiveSfx, closeTo(0.4, 0.0001));
      expect(settings.effectiveMusic, closeTo(0.3, 0.0001));
    });

    test('la coupure prime sur les deux volumes', () {
      const settings = AudioSettings(master: 1.0, sfx: 1.0, music: 1.0, muted: true);

      expect(settings.effectiveSfx, 0.0);
      expect(settings.effectiveMusic, 0.0);
    });
  });

  group('SettingsService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('aller-retour de persistance', () async {
      const written = AudioSettings(master: 0.3, sfx: 0.4, music: 0.5, muted: true);

      await SettingsService.save(written);
      final read = await SettingsService.load();

      expect(read.master, closeTo(0.3, 0.0001));
      expect(read.sfx, closeTo(0.4, 0.0001));
      expect(read.music, closeTo(0.5, 0.0001));
      expect(read.muted, isTrue);
    });

    test('sans reglage enregistre, retourne les defauts', () async {
      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });

    test('un JSON corrompu retombe silencieusement sur les defauts', () async {
      SharedPreferences.setMockInitialValues({'settings_v1': 'ceci n est pas du json'});

      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });

    test('une version de schema inconnue retombe sur les defauts', () async {
      SharedPreferences.setMockInitialValues({
        'settings_v1': '{"schemaVersion": 99, "master": 0.1}',
      });

      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });
  });

  group('AudioSettingsNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('la coupure bascule et se persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(audioSettingsProvider.notifier);

      expect(container.read(audioSettingsProvider).muted, isFalse);

      notifier.toggleMute();
      expect(container.read(audioSettingsProvider).muted, isTrue);

      await notifier.pendingSave;

      final persisted = await SettingsService.load();
      expect(persisted.muted, isTrue);
    });

    test(
      'les reglages rapproches (glisser un curseur) sont regroupes : '
      'une seule ecriture, avec la derniere valeur',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(audioSettingsProvider.notifier);

        // Simule les dizaines d'appels d'onChanged pendant un glisser de
        // Slider : la valeur en memoire suit chaque appel immediatement...
        notifier.setSfx(0.9);
        notifier.setSfx(0.7);
        notifier.setSfx(0.5);
        expect(container.read(audioSettingsProvider).sfx, closeTo(0.5, 0.0001));

        // ...mais tant que le geste n'est pas stabilise, rien n'est encore
        // ecrit sur disque : c'est ce qui evite une ecriture par frame.
        await Future<void>.delayed(AudioSettingsNotifier.debounceDelay ~/ 4);
        final duringDebounce = await SettingsService.load();
        expect(duringDebounce.sfx, closeTo(1.0, 0.0001));

        // Une fois le train d'appels stabilise, `pendingSave` se resout et
        // c'est bien la DERNIERE valeur (0.5, pas 0.9 ni 0.7) qui est ecrite.
        await notifier.pendingSave;
        final persisted = await SettingsService.load();
        expect(persisted.sfx, closeTo(0.5, 0.0001));
      },
    );

    test(
      'detruire le conteneur pendant le debounce ecrit quand meme la '
      'derniere valeur, et pendingSave se resout malgre tout',
      () async {
        // Pas de addTearDown(container.dispose) : ce test dispose lui-meme,
        // au milieu du test, et un double dispose leverait.
        final container = ProviderContainer();
        final notifier = container.read(audioSettingsProvider.notifier);

        notifier.setSfx(0.42);
        final pending = notifier.pendingSave;

        // Detruit le conteneur alors que le Timer de debounce (300 ms) est
        // encore en vol : simule un ecran de reglages ferme, ou une
        // navigation, en plein glisser de curseur.
        container.dispose();

        // pendingSave doit se resoudre grace au flush de `onDispose`, sans
        // attendre l'echeance normale du debounce. Le timeout rend un echec
        // lisible si jamais il ne se resout pas, plutot que de bloquer la
        // suite indefiniment.
        await pending!.timeout(
          AudioSettingsNotifier.debounceDelay * 3,
          onTimeout: () => fail(
            'pendingSave ne s est jamais resolu apres la destruction du '
            'conteneur : le reglage aurait ete perdu silencieusement.',
          ),
        );

        final persisted = await SettingsService.load();
        expect(persisted.sfx, closeTo(0.42, 0.0001));
      },
    );
  });
}
