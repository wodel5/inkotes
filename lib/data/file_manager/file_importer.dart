import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:logging/logging.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/i18n/strings.g.dart';
import 'package:inkotes/pages/editor/editor.dart';

/// Handles importing files into the app's directory.
class FileImporter {
  FileImporter._();

  static final log = Logger('FileImporter');

  static Future<String> newFilePath([String parentPath = '/']) async {
    assert(parentPath.endsWith('/'));

    final DateTime now = DateTime.now();
    final String filePath =
        '$parentPath${DateFormat("yy-MM-dd").format(now)} '
        '${t.editor.untitled}';

    return await FileManager.suffixFilePathToMakeItUnique(filePath);
  }

  static Future<String?> importFile(
    String path,
    String? parentDir, {
    String? extension,
    bool awaitWrite = true,
  }) async {
    assert(parentDir == null ||
        parentDir.startsWith('/') && parentDir.endsWith('/'));

    if (extension == null) {
      extension = '.${path.split('.').last}';
      assert(extension.length > 1);
    } else {
      assert(extension.startsWith('.'));
    }

    String fileName = path.split(RegExp(r'[\\/]')).last;
    fileName = fileName.substring(0, fileName.lastIndexOf('.'));
    final String importedPath;

    final writeFutures = <Future>[];

    if (extension.toLowerCase() == '.fle') {
      final inputStream = InputFileStream(path);
      final archive = ZipDecoder().decodeStream(inputStream);

      final mainFile = archive.files.cast<ArchiveFile?>().firstWhere(
        (file) => file!.name.toLowerCase().endsWith(Editor.extension),
        orElse: () => null,
      );
      if (mainFile == null) {
        log.severe('Failed to find main note in fle: $path');
        return null;
      }
      final mainFileExtension =
          '.${mainFile.name.split('.').last}'.toLowerCase();
      importedPath = await FileManager.suffixFilePathToMakeItUnique(
        '${parentDir ?? '/'}$fileName',
        intendedExtension: mainFileExtension,
      );
      final mainFileContents = () {
        final output = OutputMemoryStream();
        mainFile.writeContent(output);
        return output.getBytes();
      }();
      writeFutures.add(
        FileManager.writeFile(importedPath + mainFileExtension, mainFileContents,
            awaitWrite: awaitWrite),
      );

      for (final file in archive.files) {
        if (!file.isFile) continue;
        if (file == mainFile) continue;

        final ext = file.name.split('.').last;
        final assetNumber = int.tryParse(ext);
        if (assetNumber == null || assetNumber < 0) continue;

        final assetBytes = () {
          final output = OutputMemoryStream();
          file.writeContent(output);
          return output.getBytes();
        }();
        writeFutures.add(
          FileManager.writeFile(
              '$importedPath$mainFileExtension.$assetNumber', assetBytes,
              awaitWrite: awaitWrite),
        );
      }
    } else {
      final file = File(path);
      final fileContents = await file.readAsBytes();
      importedPath = await FileManager.suffixFilePathToMakeItUnique(
        '${parentDir ?? '/'}$fileName',
        intendedExtension: extension.toLowerCase(),
      );
      writeFutures.add(
        FileManager.writeFile(importedPath + extension.toLowerCase(), fileContents,
            awaitWrite: awaitWrite),
      );
    }

    await Future.wait(writeFutures);
    return importedPath;
  }
}
