import 'dart:io';

import 'content_file_system.dart';

/// **Le seul fichier de `lib/` qui importe `dart:io`.** Il n'est compile que
/// sur les plateformes qui en disposent, l'import etant conditionnel dans
/// `platform_file_system.dart`.
class IoContentFileSystem implements ContentFileSystem {
  const IoContentFileSystem();

  @override
  String get startDirectory =>
      toSlashes(File(Platform.resolvedExecutable).parent.path);

  @override
  bool fileExists(String path) => File(path).existsSync();

  @override
  bool directoryExists(String path) => Directory(path).existsSync();

  @override
  String readFile(String path) => File(path).readAsStringSync();

  @override
  void writeFile(String path, String contents) =>
      File(path).writeAsStringSync(contents);

  @override
  void deleteFile(String path) => File(path).deleteSync();

  @override
  void createDirectory(String path) =>
      Directory(path).createSync(recursive: true);

  @override
  void copyFile(String from, String to) => File(from).copySync(to);

  @override
  List<String> listDirectory(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) return const [];
    return directory
        .listSync()
        .map((entity) => toSlashes(entity.path).split('/').last)
        .toList();
  }

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    // `runInShell: true` est INDISPENSABLE. L'hote de `flutter test` n'est pas
    // un shell : sans ce drapeau, `Process.run` leve une `ProcessException`
    // sous Windows. Meme constat, meme remede que dans
    // `test/unit/sync_assets_test.dart`.
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    return ProcessOutcome(
      result.exitCode,
      '${result.stdout}${result.stderr}',
    );
  }

  /// Windows rend des chemins a antislash ; tout le reste de l'editeur n'en
  /// connait qu'un seul, `/`.
  static String toSlashes(String path) => path.replaceAll('\\', '/');
}

/// Consomme par l'import conditionnel de `platform_file_system.dart`.
ContentFileSystem? create() => const IoContentFileSystem();
