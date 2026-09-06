import 'package:meta/meta.dart';

/// Ce que rend un processus lance par l'editeur.
@immutable
class ProcessOutcome {
  const ProcessOutcome(this.exitCode, this.output);

  final int exitCode;
  final String output;

  bool get succeeded => exitCode == 0;
}

/// Les seules operations disque dont l'editeur de contenu a besoin.
///
/// Cette abstraction existe pour une raison de plateforme, et une seule :
/// `lib/` n'importait jusqu'ici `dart:io` nulle part, et le jeu est publie en
/// build web. Un import direct casserait cette cible. L'implementation reelle
/// est choisie par import conditionnel dans `platform_file_system.dart` ; sur
/// le web il n'y en a aucune, et l'editeur refuse de s'ouvrir.
///
/// Les chemins sont **toujours** separes par `/`, y compris sous Windows : les
/// API de `dart:io` l'acceptent, et une convention unique evite d'avoir a
/// normaliser a chaque comparaison.
abstract class ContentFileSystem {
  /// Repertoire d'ou part la remontee vers la racine du projet.
  String get startDirectory;

  bool fileExists(String path);

  bool directoryExists(String path);

  String readFile(String path);

  void writeFile(String path, String contents);

  void deleteFile(String path);

  /// Cree [path] et tous ses parents manquants.
  void createDirectory(String path);

  void copyFile(String from, String to);

  /// Les noms des entrees de [path], sans leur chemin. Rend une liste vide si
  /// le repertoire n'existe pas — l'appelant n'a pas a s'en premunir.
  List<String> listDirectory(String path);

  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  });
}
