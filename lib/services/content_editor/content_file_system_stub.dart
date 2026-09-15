import 'content_file_system.dart';

/// Plateforme sans systeme de fichiers accessible — le web. Aucune
/// implementation n'est possible, et l'editeur refuse de s'ouvrir plutot que
/// de faire semblant d'ecrire.
ContentFileSystem? create() => null;
