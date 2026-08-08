import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:inkotes/components/home/sort_button.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/i18n/strings.g.dart';
import 'package:inkotes/pages/editor/editor.dart';

/// A collection of cross-platform utility functions for working with a virtual file system.
class FileManager {
  // disable constructor
  FileManager._();

  static final log = Logger('FileManager');

  static const appRootDirectoryPrefix = 'inkotes';
  static const maxRecentlyAccessedFiles = 30;

  /// This isn't final because isolates sometimes init multiple times.
  /// Realistically, this value never changes.
  static late String documentsDirectory;

  static final fileWriteStream = StreamController<FileOperation>.broadcast();

  /// A regex that matches the file names/paths of asset files,
  /// including previews, e.g. `mynote.ikn.1`.
  static final assetFileRegex = RegExp(r'\.ikn\.[\dp]+$');

  static String sanitisePath(String path) => File(path).path;

  /// Forbidden names for files and directories (on any/all platforms).
  static List<(String, RegExp)> _getForbiddenFilenamePatterns() => [
    (
      t.home.renameNote.noteNameForbiddenCharacters,
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
    ),
    (
      t.home.renameNote.noteNameReserved,
      RegExp(
        r'^((con|prn|aux|nul|com[1-9]|lpt[1-9])(\..*)?)|\.+$',
        caseSensitive: false,
      ),
    ),
  ];

  static String? validateFilename(String filename) {
    if (filename.isEmpty) return t.home.renameNote.noteNameEmpty;
    for (final (error, regexp) in _getForbiddenFilenamePatterns()) {
      if (regexp.hasMatch(filename)) return error;
    }
    return null;
  }

  // ─── Init ─────────────────────────────────────────────────────────────

  static Future<void> init({
    String? documentsDirectory,
    bool shouldWatchRootDirectory = true,
  }) async {
    FileManager.documentsDirectory =
        documentsDirectory ?? await _getDocumentsDirectory();

    if (shouldWatchRootDirectory) unawaited(watchRootDirectory());
  }

  static Future<String> _getDocumentsDirectory() async =>
      '${(await getApplicationDocumentsDirectory()).path}/$appRootDirectoryPrefix';

  static Future<void> migrateDataDir() async {
    final oldDir = Directory(documentsDirectory);
    final newDir = Directory(await _getDocumentsDirectory());
    if (oldDir.path == newDir.path) return;
    log.info('Migrating data directory from $oldDir to $newDir');

    late final oldDirEmpty =
        oldDir.existsSync() ? oldDir.listSync().isEmpty : true;
    late final newDirEmpty =
        newDir.existsSync() ? newDir.listSync().isEmpty : true;

    if (!oldDirEmpty && !newDirEmpty) {
      log.severe('New and old data directory aren\'t empty, can\'t migrate');
      return;
    }

    documentsDirectory = newDir.path;
    if (oldDirEmpty) {
      log.fine('Old data directory is empty or missing, nothing to migrate');
    } else {
      await _moveDirContents(oldDir: oldDir, newDir: newDir);
      await oldDir.delete(recursive: true);
    }
  }

  static Future<void> _moveDirContents({
    required Directory oldDir,
    required Directory newDir,
  }) async {
    await newDir.create(recursive: true);

    await for (final entity in oldDir.list(recursive: true)) {
      final relative = p.relative(entity.path, from: oldDir.path);
      final targetPath = p.join(newDir.path, relative);

      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
        continue;
      }

      if (entity is File) {
        await entity.parent.create(recursive: true);
        try {
          await entity.rename(targetPath);
        } on FileSystemException catch (e) {
          const exdev = 18;
          if (e.osError?.errorCode == exdev) {
            await entity.copy(targetPath);
            await entity.delete();
          } else {
            rethrow;
          }
        }
      }
    }
  }

  @visibleForTesting
  static Future<void> watchRootDirectory() async {
    final rootDir = Directory(documentsDirectory);
    await rootDir.create(recursive: true);
    if (Platform.isIOS) return;
    rootDir.watch(recursive: true).listen((event) {
      final FileOperationType type = switch (event.type) {
        FileSystemEvent.delete => .delete,
        FileSystemEvent.create => .write,
        FileSystemEvent.modify => .write,
        FileSystemEvent.move => .write,
        _ =>
          kDebugMode
              ? throw UnimplementedError(
                  'Unhandled FileSystemEvent type: ${event.type}')
              : .write,
      };
      final String path = event.path
          .replaceAll('\\', '/')
          .replaceFirst(documentsDirectory, '');
      broadcastFileWrite(type, path);
    });
  }

  @visibleForTesting
  static void broadcastFileWrite(FileOperationType type, String path) {
    if (!fileWriteStream.hasListener) return;

    if (path.endsWith(Editor.extension)) {
      path = path.substring(0, path.length - Editor.extension.length);
    }

    fileWriteStream.add(FileOperation(type, path));
  }

  // ─── File I/O ─────────────────────────────────────────────────────────

  static Future<Uint8List?> readFile(String filePath, {int retries = 3}) async {
    filePath = sanitisePath(filePath);

    Uint8List? result;
    final file = getFile(filePath);
    if (file.existsSync()) {
      result = await file.readAsBytes();
      if (result.isEmpty) result = null;
    } else {
      retries = 0;
    }

    if (result == null && retries > 0) {
      await Future.delayed(const Duration(milliseconds: 100));
      return readFile(filePath, retries: retries - 1);
    }
    return result;
  }

  @visibleForTesting
  static var shouldUseRawFilePath = false;

  static File getFile(String filePath) {
    if (shouldUseRawFilePath) {
      return File(filePath);
    } else {
      assert(
        filePath.startsWith('/'),
        'Expected filePath to start with a slash, got $filePath',
      );
      return File(documentsDirectory + filePath);
    }
  }

  static Directory getRootDirectory() => Directory(documentsDirectory);

  static Future<void> writeFile(
    String filePath,
    List<int> toWrite, {
    bool awaitWrite = false,
    DateTime? lastModified,
  }) async {
    filePath = sanitisePath(filePath);
    log.fine('Writing to $filePath');

    saveFileAsRecentlyAccessed(filePath);

    final file = getFile(filePath);
    await createFileDirectory(filePath);
    Future<void> writeFuture = file.writeAsBytes(toWrite).then((file) async {
      if (lastModified != null) await file.setLastModified(lastModified);
    });

    void afterWrite() {
      broadcastFileWrite(FileOperationType.write, filePath);
    }

    writeFuture = writeFuture.then((_) => afterWrite());
    if (awaitWrite) await writeFuture;
  }

  static Future<void> createFolder(String folderPath) async {
    folderPath = sanitisePath(folderPath);
    final dir = Directory(documentsDirectory + folderPath);
    await dir.create(recursive: true);
  }

  // ─── File Operations ──────────────────────────────────────────────────

  static Future<String> moveFile(
    String fromPath,
    String toPath, {
    bool replaceExistingFile = false,
    bool alsoMoveAssets = true,
  }) async {
    fromPath = sanitisePath(fromPath);
    toPath = sanitisePath(toPath);

    if (!toPath.contains('/')) {
      toPath = fromPath.substring(0, fromPath.lastIndexOf('/') + 1) + toPath;
    }

    if (!replaceExistingFile || Editor.isReservedPath(toPath)) {
      toPath = await suffixFilePathToMakeItUnique(
        toPath,
        currentPath: fromPath,
      );
    }

    if (fromPath == toPath) return toPath;

    final fromFile = getFile(fromPath);
    final toFile = getFile(toPath);
    await createFileDirectory(toPath);
    if (fromFile.existsSync()) {
      await fromFile.rename(toFile.path);
    } else {
      log.warning(
          'Tried to move non-existent file from $fromPath to $toPath');
    }

    renameReferences(fromPath, toPath);
    broadcastFileWrite(FileOperationType.delete, fromPath);
    broadcastFileWrite(FileOperationType.write, toPath);

    if (alsoMoveAssets && !assetFileRegex.hasMatch(fromPath)) {
      final assets = <String>[];
      for (int assetNumber = 0; true; assetNumber++) {
        final assetFile = getFile('$fromPath.$assetNumber');
        if (assetFile.existsSync()) {
          assets.add('$assetNumber');
        } else {
          break;
        }
      }
      {
        const assetNumber = 'p';
        final assetFile = getFile('$fromPath.$assetNumber');
        if (assetFile.existsSync()) {
          assets.add(assetNumber);
        }
      }

      await Future.wait([
        for (final assetNumber in assets)
          moveFile(
            '$fromPath.$assetNumber',
            '$toPath.$assetNumber',
            replaceExistingFile: replaceExistingFile,
          ),
      ]);
    }

    return toPath;
  }

  static Future deleteFile(
    String filePath, {
    bool alsoDeleteAssets = true,
  }) async {
    filePath = sanitisePath(filePath);

    final file = getFile(filePath);
    if (!file.existsSync()) return;
    await file.delete();

    removeReferences(filePath);
    broadcastFileWrite(FileOperationType.delete, filePath);

    if (alsoDeleteAssets && !assetFileRegex.hasMatch(filePath)) {
      final assets = <int>[];
      for (int assetNumber = 0; true; assetNumber++) {
        final assetFile = getFile('$filePath.$assetNumber');
        if (assetFile.existsSync()) {
          assets.add(assetNumber);
        } else {
          break;
        }
      }

      final previewFile = getFile('$filePath.p');
      await Future.wait([
        for (final assetNumber in assets)
          deleteFile('$filePath.$assetNumber', alsoDeleteAssets: false),
        if (previewFile.existsSync())
          deleteFile('$filePath.p', alsoDeleteAssets: false),
      ]);
    }
  }

  static Future removeUnusedAssets(
    String filePath, {
    required int numAssets,
  }) async {
    final futures = <Future>[];

    for (int assetNumber = numAssets; true; assetNumber++) {
      final assetPath = '$filePath.$assetNumber';
      if (getFile(assetPath).existsSync()) {
        futures.add(deleteFile(assetPath));
      } else {
        break;
      }
    }

    await Future.wait(futures);
  }

  static Future renameDirectory(String directoryPath, String newName) async {
    directoryPath = sanitisePath(directoryPath);

    final directory = Directory(documentsDirectory + directoryPath);
    if (!directory.existsSync()) return;

    final List<String> children = [];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        children.add(entity.path.substring(directory.path.length));
      }
    }

    final String newPath =
        directoryPath.substring(0, directoryPath.lastIndexOf('/') + 1) +
            newName;
    await directory.rename(documentsDirectory + newPath);

    for (final child in children) {
      renameReferences(directoryPath + child, newPath + child);
      broadcastFileWrite(FileOperationType.delete, directoryPath + child);
      broadcastFileWrite(FileOperationType.write, newPath + child);
    }
  }

  static Future deleteDirectory(
    String directoryPath, [
    bool recursive = true,
  ]) async {
    directoryPath = sanitisePath(directoryPath);

    final directory = Directory(documentsDirectory + directoryPath);
    if (!directory.existsSync()) return;

    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          await deleteFile(entity.path.substring(documentsDirectory.length));
        }
      }
    }

    await directory.delete(recursive: recursive);
  }

  // ─── Directory Listing ────────────────────────────────────────────────

  static Future<DirectoryChildren?> getChildrenOfDirectory(
    String directory, {
    bool includeExtensions = false,
    bool includeAssets = false,
    SortMetric sortMetric = .nameAToZ,
  }) async {
    assert(
      !includeAssets || includeExtensions,
      'includeAssets can\'t be true without includeExtensions',
    );

    directory = sanitisePath(directory);
    if (!directory.endsWith('/')) directory += '/';

    final List<String> directories = [], files = [];

    final dir = Directory(documentsDirectory + directory);
    if (!dir.existsSync()) return null;

    final int directoryPrefixLength =
        directory.endsWith('/') ? directory.length : directory.length + 1;
    final allChildren = await dir
        .list()
        .map((FileSystemEntity entity) {
          final filePath =
              entity.path.substring(documentsDirectory.length);

          if (entity is Directory) return filePath;

          if (Editor.isReservedPath(filePath)) return null;

          late final isFln = filePath.endsWith(Editor.extension);

          if (!includeExtensions) {
            if (isFln) {
              return filePath.substring(
                  0, filePath.length - Editor.extension.length);
            } else {
              return null;
            }
          } else if (!includeAssets) {
            if (!isFln) return null;
          }

          return filePath;
        })
        .where((String? file) => file != null)
        .map((file) => file!.substring(directoryPrefixLength))
        .toList();

    for (final child in allChildren) {
      if (isDirectory(directory + child) && !directories.contains(child)) {
        directories.add(child);
      } else if (!includeAssets && assetFileRegex.hasMatch(child)) {
        // skip assets
      } else {
        files.add(child);
      }
    }

    switch (sortMetric) {
      case .nameAToZ:
        files.sortBy((child) => child);
      case .nameZToA:
        files.sortByCompare(
          (child) => child,
          (child, other) => -child.compareTo(other),
        );
      case .lastModifiedNewToOld:
        files.sortByCompare(
          (child) => lastModified(directory + child + Editor.extension),
          (date, other) => -date.compareTo(other),
        );
      case .lastModifiedOldToNew:
        files.sortBy(
          (child) => lastModified(directory + child + Editor.extension),
        );
    }

    return DirectoryChildren(directories, files);
  }

  static Future<List<String>> getAllFiles({
    bool includeExtensions = false,
    bool includeAssets = false,
  }) async {
    final allFiles = <String>[];
    final directories = <String>['/'];

    while (directories.isNotEmpty) {
      final directory = directories.removeLast();
      final children = await getChildrenOfDirectory(
        directory,
        includeExtensions: includeExtensions,
        includeAssets: includeAssets,
      );
      if (children == null) continue;

      for (final file in children.files) {
        allFiles.add('$directory$file');
      }
      for (final childDirectory in children.directories) {
        directories.add('$directory$childDirectory/');
      }
    }

    return allFiles;
  }

  static Future<List<String>> getRecentlyAccessed() async {
    if (!stows.recentFiles.loaded) await stows.recentFiles.waitUntilRead();
    for (final file in stows.recentFiles.value.toList()) {
      if (!doesFileExist(file)) removeReferences(file);
    }
    return stows.recentFiles.value
        .map((String filePath) {
          if (filePath.endsWith(Editor.extension)) {
            return filePath.substring(
                0, filePath.length - Editor.extension.length);
          } else {
            return filePath;
          }
        })
        .where((String file) => !Editor.isReservedPath(file))
        .toList();
  }

  // ─── Queries ──────────────────────────────────────────────────────────

  static bool isDirectory(String filePath) {
    filePath = sanitisePath(filePath);
    final directory = Directory(documentsDirectory + filePath);
    return directory.existsSync();
  }

  static bool doesFileExist(String filePath) {
    filePath = sanitisePath(filePath);
    final file = getFile(filePath);
    return file.existsSync();
  }

  static DateTime lastModified(String filePath) {
    filePath = sanitisePath(filePath);
    final file = getFile(filePath);
    if (!file.existsSync()) return DateTime(2023);
    return file.lastModifiedSync();
  }

  // ─── Path Utilities ───────────────────────────────────────────────────

  static Future<String> suffixFilePathToMakeItUnique(
    String filePath, {
    String? intendedExtension,
    String? currentPath,
  }) async {
    String newFilePath = filePath;
    bool hasExtension = false;

    if (filePath.endsWith(Editor.extension)) {
      filePath = filePath.substring(
          0, filePath.length - Editor.extension.length);
      newFilePath = filePath;
      hasExtension = true;
      intendedExtension ??= Editor.extension;
    } else {
      intendedExtension ??= Editor.extension;
    }

    int i = 1;
    while (true) {
      if (!doesFileExist(newFilePath + Editor.extension)) break;
      if (newFilePath + Editor.extension == currentPath) break;
      i++;
      newFilePath = '$filePath ($i)';
    }

    return newFilePath + (hasExtension ? intendedExtension : '');
  }

  // ─── Internal Helpers ─────────────────────────────────────────────────

  static Future createFileDirectory(String filePath) async {
    assert(
        filePath.contains('/'), 'filePath must be a path, not a file name');
    final parentDirectory = filePath.substring(0, filePath.lastIndexOf('/'));
    await Directory(documentsDirectory + parentDirectory)
        .create(recursive: true);
  }

  static void renameReferences(String fromPath, String toPath) {
    bool replaced = false;
    for (int i = 0; i < stows.recentFiles.value.length; i++) {
      if (stows.recentFiles.value[i] != fromPath) continue;
      if (!replaced) {
        stows.recentFiles.value[i] = toPath;
        replaced = true;
      } else {
        stows.recentFiles.value.removeAt(i);
      }
    }
    stows.recentFiles.notifyListeners();
  }

  static void removeReferences(String filePath) {
    for (int i = 0; i < stows.recentFiles.value.length; i++) {
      if (stows.recentFiles.value[i] != filePath) continue;
      stows.recentFiles.value.removeAt(i);
    }
    stows.recentFiles.notifyListeners();
  }

  static void saveFileAsRecentlyAccessed(String filePath) {
    if (assetFileRegex.hasMatch(filePath)) return;

    stows.recentFiles.value.remove(filePath);
    stows.recentFiles.value.insert(0, filePath);
    if (stows.recentFiles.value.length > maxRecentlyAccessedFiles) {
      stows.recentFiles.value.removeLast();
    }

    stows.recentFiles.notifyListeners();
  }
}

class DirectoryChildren {
  final List<String> directories;
  final List<String> files;

  DirectoryChildren(this.directories, this.files);

  bool onlyOneChild() => directories.length + files.length <= 1;

  bool get isEmpty => directories.isEmpty && files.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

enum FileOperationType { write, delete }

class FileOperation {
  final FileOperationType type;
  final String filePath;

  const FileOperation(this.type, this.filePath);
}
