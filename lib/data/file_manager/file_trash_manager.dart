import 'dart:async';

import 'package:logging/logging.dart';
import 'package:inkotes/data/editor/editor_core_info.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/pages/editor/editor.dart';

/// Handles trash operations for notes (mark as trashed, restore, query).
class FileTrashManager {
  FileTrashManager._();

  static final log = Logger('FileTrashManager');

  static Future<void> markAsTrashed(String filePath) async {
    await _setTrashStatus(filePath, true);
  }

  static Future<void> restoreFromTrash(String filePath) async {
    await _setTrashStatus(filePath, false);
  }

  static Future<void> _setTrashStatus(String filePath, bool isTrashed) async {
    filePath = FileManager.sanitisePath(filePath);
    final coreInfo = await EditorCoreInfo.loadFromFilePath(filePath);
    coreInfo.isTrashed = isTrashed;
    final (bson, assets) = coreInfo.saveToBinary(
      currentPageIndex: coreInfo.initialPageIndex,
    );
    final filePathWithExt = filePath + Editor.extension;
    await Future.wait([
      FileManager.writeFile(filePathWithExt, bson, awaitWrite: true),
      for (int i = 0; i < assets.length; ++i)
        assets.getBytes(i).then(
              (bytes) => FileManager.writeFile(
                '$filePathWithExt.$i',
                bytes,
                awaitWrite: true,
              ),
            ),
    ]);
    FileManager.broadcastFileWrite(FileOperationType.write, filePath);
  }

  static Future<List<String>> getTrashedFiles() async {
    final allFiles = await FileManager.getAllFiles();
    final trashedFiles = <String>[];

    for (final file in allFiles) {
      final isTrashed = await EditorCoreInfo.isFileTrashed(file);
      if (isTrashed) {
        trashedFiles.add(file);
      }
    }

    return trashedFiles;
  }

  static Future<List<String>> filterOutTrashed(List<String> files) async {
    final result = <String>[];
    for (final file in files) {
      final isTrashed = await EditorCoreInfo.isFileTrashed(file);
      if (!isTrashed) {
        result.add(file);
      }
    }
    return result;
  }
}
