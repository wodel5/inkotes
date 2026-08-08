import 'dart:async';
import 'dart:convert';
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
        '$parentPath${DateFormat("yy-MM-dd HH-mm").format(now)} '
        '${t.editor.untitled}';

    return await FileManager.suffixFilePathToMakeItUnique(filePath);
  }

  /// Validates that the ZIP archive is a valid Inkotes note archive.
  /// Returns null if valid, or an error message if invalid.
  static String? validateArchive(Archive archive) {
    // 检查是否存在 inkotes.json 验证文件
    final validationFile = archive.files.cast<ArchiveFile?>().firstWhere(
      (file) => file!.name == 'inkotes.json',
      orElse: () => null,
    );
    if (validationFile == null) {
      return t.home.import.invalidFile;
    }

    // 验证 inkotes.json 内容
    try {
      final output = OutputMemoryStream();
      validationFile.writeContent(output);
      final bytes = output.getBytes();
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map || json['app'] != 'inkotes') {
        return t.home.import.invalidFile;
      }
    } catch (e) {
      return t.home.import.invalidFile;
    }

    // 检查是否存在主笔记文件
    final mainFile = archive.files.cast<ArchiveFile?>().firstWhere(
      (file) => file!.name.toLowerCase().endsWith(Editor.extension),
      orElse: () => null,
    );
    if (mainFile == null) {
      return t.home.import.invalidFile;
    }

    return null; // 验证通过
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

    if (extension.toLowerCase() == '.zip') {
      final inputStream = InputFileStream(path);
      final archive = ZipDecoder().decodeStream(inputStream);

      // 验证是否为有效的 Inkotes 归档
      final validationError = validateArchive(archive);
      if (validationError != null) {
        log.warning('Archive validation failed: $validationError');
        return null;
      }

      final mainFile = archive.files.cast<ArchiveFile?>().firstWhere(
        (file) => file!.name.toLowerCase().endsWith(Editor.extension),
        orElse: () => null,
      );
      if (mainFile == null) {
        log.severe('Failed to find main note in archive: $path');
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
        if (file.name == 'inkotes.json') continue; // 跳过验证文件

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
