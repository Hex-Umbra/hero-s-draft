import 'package:file_picker/file_picker.dart';

/// Le choix d'un fichier par l'usager. Seam injectable : les tests le
/// remplacent, pour qu'aucune fenetre ne s'ouvre (spec §5.5).
abstract class AssetPicker {
  /// Chemin absolu choisi, ou `null` si l'usager annule.
  Future<String?> pickFile({required List<String> extensions});
}

/// L'implementation reelle, sur `file_picker`.
///
/// La v13 du paquet a retire `FilePicker.platform.pickFiles` : `pickFile`
/// est desormais une methode statique qui rend directement un
/// `PlatformFile?`, sans passer par un `FilePickerResult`.
class FilePickerAssetPicker implements AssetPicker {
  const FilePickerAssetPicker();

  @override
  Future<String?> pickFile({required List<String> extensions}) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    return file?.path;
  }
}
