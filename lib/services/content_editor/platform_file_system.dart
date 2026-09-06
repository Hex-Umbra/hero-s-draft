import 'content_file_system.dart';
import 'content_file_system_stub.dart'
    if (dart.library.io) 'content_file_system_io.dart' as impl;

/// L'implementation de la plateforme courante, ou `null` sur le web.
///
/// **Seul endroit du depot ou l'import conditionnel est ecrit.** L'ajouter
/// ailleurs ferait entrer `dart:io` dans un second fichier.
ContentFileSystem? platformFileSystem() => impl.create();
