import 'dart:convert';

import 'content_file_system.dart';

/// Le catalogue des sons, relatif a la racine du projet.
const String kAudioCatalogPath = 'assets/data/audio.json';

/// Les identifiants declares sous `sounds`, tries. Vide si le fichier manque
/// ou ne decode pas : un champ de son sans catalogue ne propose rien.
List<String> soundIds(ContentFileSystem fs, String rootPath) {
  final absolute = '$rootPath/$kAudioCatalogPath';
  if (!fs.fileExists(absolute)) return const [];
  try {
    final decoded = jsonDecode(fs.readFile(absolute));
    final sounds = decoded is Map<String, dynamic> ? decoded['sounds'] : null;
    if (sounds is! Map<String, dynamic>) return const [];
    return sounds.keys.toList()..sort();
  } catch (_) {
    // Illisible, quelle qu'en soit la raison : un champ de son sans catalogue ne propose rien.
    return const [];
  }
}

/// [source] augmente d'une ligne `"<id>": { "file": "<file>" }` en fin du
/// bloc `sounds`.
///
/// **Insertion textuelle, pas reencodage** : `audio.json` est aligne a la
/// main, et le reencoder reecrirait ses cent lignes. Le resultat est controle
/// en le decodant — il doit valoir l'original plus l'entrée, sinon rien n'est
/// rendu.
String insertSound(String source, {required String id, required String file}) {
  final original = jsonDecode(source);
  final sounds = original is Map<String, dynamic> ? original['sounds'] : null;
  if (original is! Map<String, dynamic> || sounds is! Map<String, dynamic>) {
    throw StateError('audio.json ne porte pas de bloc "sounds"');
  }
  if (sounds.containsKey(id)) {
    throw StateError('le son "$id" est déjà déclaré');
  }

  final open = source.indexOf('{', source.indexOf('"sounds"'));
  final close = _matchingBrace(source, open);
  final newline = source.contains('\r\n') ? '\r\n' : '\n';
  final entry = '"$id": { "file": "$file" }';

  final String result;
  if (source.substring(open + 1, close).trim().isEmpty) {
    final indent = _indentOfLine(source, close);
    result = '${source.substring(0, open + 1)}$newline$indent  $entry'
        '$newline$indent${source.substring(close)}';
  } else {
    var last = close - 1;
    while (source[last].trim().isEmpty) {
      last--;
    }
    final indent = _indentOfLine(source, last);
    result = '${source.substring(0, last + 1)},$newline$indent$entry'
        '${source.substring(last + 1)}';
  }

  final expected = Map<String, dynamic>.from(original)
    ..['sounds'] = {
      ...sounds,
      id: {'file': file},
    };
  if (jsonEncode(jsonDecode(result)) != jsonEncode(expected)) {
    throw StateError('insertion dans audio.json non conforme : rien n\'est écrit');
  }
  return result;
}

int _matchingBrace(String source, int open) {
  var depth = 0;
  var inString = false;
  for (var i = open; i < source.length; i++) {
    final char = source[i];
    if (inString) {
      if (char == '\\') {
        i++;
      } else if (char == '"') {
        inString = false;
      }
      continue;
    }
    if (char == '"') {
      inString = true;
    } else if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  throw StateError('bloc "sounds" non refermé');
}

String _indentOfLine(String source, int index) {
  final start = source.lastIndexOf('\n', index) + 1;
  return RegExp(r'^[ \t]*').stringMatch(source.substring(start)) ?? '';
}
