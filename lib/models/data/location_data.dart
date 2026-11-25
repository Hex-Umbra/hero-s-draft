/// Les écrans qu'un décor de lieu peut habiller, et le fichier de chacun
/// (spec P-05, vague 2, §4.2). Le combat, l'élite et le boss partagent
/// l'écran de combat.
enum DecorScreen {
  combat('combat.png'),
  rest('rest.png'),
  shop('shop.png'),
  event('event.png'),
  relicExchange('relic_exchange.png'),
  forgeFusion('forge_fusion.png');

  const DecorScreen(this.fileName);

  final String fileName;
}

/// Les images d'un lieu, lues dans le manifeste d'assets : ses décors par
/// écran et ses fonds de fenêtre, dans l'ordre de leur numéro.
class LocationAssets {
  final String id;
  final Map<DecorScreen, String> _decors;

  /// Les chemins de `window_<n>.png`, dans l'ordre de leur numéro.
  final List<String> windowBackgrounds;

  const LocationAssets._(this.id, this._decors, this.windowBackgrounds);

  /// Le chemin complet du décor de [screen], ou `null` quand le lieu n'en
  /// porte pas : le repli de B76.
  String? decorFor(DecorScreen screen) => _decors[screen];

  /// Tous les chemins d'images du lieu : décors puis fonds.
  Iterable<String> get images => [..._decors.values, ...windowBackgrounds];
}

/// Les lieux du jeu, lus depuis le manifeste d'assets sans aucun JSON :
/// `assets/data/locations/<id>/<fichier>`. Les fautes de lecture sont
/// conservées dans [faults], que `loadGameDataRegistry` remonte avec celles
/// des entités ; un catalogue vide (registre fait à la main) n'en a aucune.
class LocationCatalog {
  final List<LocationAssets> locations;
  final List<String> faults;

  const LocationCatalog.empty()
      : locations = const [],
        faults = const [];

  const LocationCatalog._(this.locations, this.faults);

  static const String _root = 'assets/data/locations';
  static final RegExp _idPattern = RegExp(r'^[a-z0-9_]+$');
  static final RegExp _windowPattern = RegExp(r'^window_([1-9][0-9]*)\.png$');
  static const List<int> _windowNumbers = [1, 2, 3];

  /// Le lieu courant : le seul, ou `null` pour un catalogue sans lieu.
  LocationAssets? get current => locations.isEmpty ? null : locations.single;

  factory LocationCatalog.fromAssetKeys(Iterable<String> keys) {
    final filesByLocation = <String, List<String>>{};
    for (final key in keys) {
      final segments = key.split('/');
      if (segments.length != 5 || !key.startsWith('$_root/')) continue;
      filesByLocation.putIfAbsent(segments[3], () => []).add(segments[4]);
    }

    final faults = <String>[];
    final locations = <LocationAssets>[];
    final ids = filesByLocation.keys.toList()..sort();

    if (ids.isEmpty) {
      faults.add('$_root : aucun lieu, il en faut un dossier');
    } else if (ids.length > 1) {
      faults.add('$_root : un seul lieu est admis, trouvés : ${ids.join(', ')}');
    }

    for (final id in ids) {
      final folder = '$_root/$id';
      if (!_idPattern.hasMatch(id)) {
        faults.add('$folder : l\'id d\'un lieu est en snake_case ASCII minuscule');
      }
      final decors = <DecorScreen, String>{};
      final windows = <int, String>{};
      for (final file in filesByLocation[id]!) {
        final path = '$folder/$file';
        if (!file.endsWith('.png')) {
          faults.add('$path : un fichier de lieu est un .png en minuscules');
          continue;
        }
        final window = _windowPattern.firstMatch(file);
        final screen =
            DecorScreen.values.where((s) => s.fileName == file).firstOrNull;
        if (screen != null) {
          decors[screen] = path;
        } else if (window != null) {
          windows[int.parse(window[1]!)] = path;
        } else {
          faults.add('$path : nom de fichier inconnu');
        }
      }
      if (!decors.containsKey(DecorScreen.combat)) {
        faults.add('$folder : combat.png manquant');
      }
      if (windows.length != _windowNumbers.length ||
          !_windowNumbers.every(windows.containsKey)) {
        faults.add(
          '$folder : trois fonds exactement, window_1.png à window_3.png — '
          'trouvés : ${(windows.keys.toList()..sort()).map((n) => 'window_$n.png').join(', ')}',
        );
      }
      locations.add(LocationAssets._(
        id,
        {for (final s in DecorScreen.values) if (decors[s] != null) s: decors[s]!},
        [for (final n in windows.keys.toList()..sort()) windows[n]!],
      ));
    }

    return LocationCatalog._(List.unmodifiable(locations), List.unmodifiable(faults));
  }
}
