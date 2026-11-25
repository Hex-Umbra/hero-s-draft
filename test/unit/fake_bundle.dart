import 'dart:convert';

import 'package:flutter/services.dart';

// `ByteData` et `Uint8List` viennent de `package:flutter/services.dart`, qui
// les reexporte : pas d import `dart:typed_data`, comme dans
// `test/unit/audio/load_audio_data_test.dart`.

/// Bundle factice : sert un `AssetManifest.bin` construit a la volee depuis
/// les cles de [files]. C est le seul moyen d exercer le chargeur sur une
/// arborescence choisie sans fabriquer un vrai bundle ni polluer celui de
/// l application.
class FakeBundle extends CachingAssetBundle {
  FakeBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = <String, Object>{
        for (final path in files.keys) path: <Object>[],
      };
      return const StandardMessageCodec().encodeMessage(manifest)!;
    }
    final content = files[key];
    if (content == null) throw Exception('asset introuvable : $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}
