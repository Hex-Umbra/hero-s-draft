import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_file_system.dart';
import 'platform_file_system.dart';
import 'project_root.dart';

/// Le systeme de fichiers de la plateforme, ou `null` sur le web.
final contentFileSystemProvider = Provider<ContentFileSystem?>(
  (ref) => platformFileSystem(),
);

/// La racine de l'arborescence source, ou `null` si l'application ne tourne
/// pas depuis une. L'ecran refuse alors de s'ouvrir : mieux vaut ne rien
/// pouvoir faire que d'ecrire au hasard.
final projectRootProvider = Provider<String?>((ref) {
  final fs = ref.watch(contentFileSystemProvider);
  return fs == null ? null : ProjectRoot.find(fs);
});
