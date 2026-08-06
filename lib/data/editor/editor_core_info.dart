import 'dart:async';

import 'package:archive/archive_io.dart';
import 'package:bson/bson.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:inkotes/components/canvas/asset_cache.dart';
import 'package:inkotes/data/editor/page.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/data/flavor_config.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/tools/stroke_properties.dart';
import 'package:inkotes/pages/editor/editor.dart';
import 'package:inkotes/data/models/canvas_background_pattern.dart';
import 'package:inkotes/data/models/read_only_reason.dart';
import 'package:worker_manager/worker_manager.dart';

class EditorCoreInfo {
  static final log = Logger('EditorCoreInfo');

  /// The version of the file format.
  /// Increment this if earlier versions of the app can't satisfiably read the file.
  static const formatVersion = 1;

  /// The reason why the note is read-only,
  /// or `null` if the note is editable.
  ReadOnlyReason? readOnlyReason;

  /// Whether the note is read-only.
  /// See [readOnlyReason] for the reason.
  bool get readOnly => readOnlyReason != null;

  String filePath;

  /// The file name without its parent directories.
  String get fileName => p.basename(filePath);

  AssetCache assetCache;
  int nextImageId;
  Color? backgroundColor;
  CanvasBackgroundPattern backgroundPattern;
  int lineHeight;
  int lineThickness;
  List<EditorPage> pages;

  /// Whether this note is in the trash.
  bool isTrashed;

  /// Stores the current page index so that it can be restored when the file is reloaded.
  int? initialPageIndex;

  static final placeholder =
      EditorCoreInfo._(
        filePath: '',
        readOnlyReason: .placeholder,
        nextImageId: 0,
        backgroundColor: null,
        backgroundPattern: .none,
        lineHeight: stows.lastLineHeight.value,
        lineThickness: stows.lastLineThickness.value,
        pages: [EditorPage()],
        initialPageIndex: null,
        assetCache: null,
      );

  bool get isEmpty => pages.every((EditorPage page) => page.isEmpty);
  bool get isNotEmpty => !isEmpty;

  @visibleForTesting
  EditorCoreInfo({required this.filePath, this.readOnlyReason})
    : nextImageId = 0,
      backgroundColor = _initialBackgroundColor(),
      backgroundPattern = stows.lastBackgroundPattern.value,
      lineHeight = stows.lastLineHeight.value,
      lineThickness = stows.lastLineThickness.value,
      pages = [],
      isTrashed = false,
      assetCache = AssetCache();

  /// Returns the background color for a new note based on the current theme.
  static Color? _initialBackgroundColor() {
    final isDark = () {
      try {
        final mode = stows.appTheme.value;
        if (mode == ThemeMode.dark) return true;
        if (mode == ThemeMode.light) return false;
        return WidgetsBinding.instance.platformDispatcher
            .platformBrightness == Brightness.dark;
      } catch (_) {
        return false;
      }
    }();
    return isDark ? const Color(0xFF272735) : const Color(0xFFFFFFFF);
  }

  EditorCoreInfo._({
    required this.filePath,
    required this.readOnlyReason,
    required this.nextImageId,
    this.backgroundColor,
    required this.backgroundPattern,
    required this.lineHeight,
    required this.lineThickness,
    required this.pages,
    required this.initialPageIndex,
    required AssetCache? assetCache,
    this.isTrashed = false,
  }) : assetCache = assetCache ?? AssetCache() {
    _handleEmptyImageIds();
  }

  factory EditorCoreInfo.fromJson(
    Map<String, dynamic> json, {
    required String filePath,
    required bool onlyFirstPage,
  }) {
    ReadOnlyReason? readOnlyReason;
    final fileVersion = json['ver'] as int? ?? 0;
    if (fileVersion > formatVersion) {
      readOnlyReason ??= .versionTooNew;
      log.warning(
        'File version $fileVersion is newer than supported $formatVersion. '
        'Note may be read incorrectly or incompletely.',
      );
    }

    final Color? backgroundColor;
    switch (json['bgc']) {
      case (final int value):
        backgroundColor = Color(value);
      case (final Int64 value):
        backgroundColor = Color(value.toInt());
      case null:
        backgroundColor = null;
      default:
        throw Exception(
          'Invalid color value: (${json['bgc'].runtimeType}) ${json['bgc']}',
        );
    }

    final assetCache = AssetCache();

    return EditorCoreInfo._(
        filePath: filePath,
        readOnlyReason: readOnlyReason,
        nextImageId: json['imgc'] as int? ?? 0,
        backgroundColor: backgroundColor,
        backgroundPattern: CanvasBackgroundPattern.fromName(
          json['pat'] as String?,
        ),
        lineHeight: json['lh'] as int? ?? stows.lastLineHeight.value,
        lineThickness: json['lw'] as int? ?? stows.lastLineThickness.value,
        pages: _parsePagesJson(
          json['pgs'] as List?,
          readOnlyReason: readOnlyReason,
          onlyFirstPage: onlyFirstPage,
          fileVersion: fileVersion,
          notePath: filePath,
          assetCache: assetCache,
        ),
        initialPageIndex: json['pg'] as int?,
        assetCache: assetCache,
        isTrashed: json['del'] as bool? ?? false,
      )
      .._ensurePage()
      .._sortStrokes();
  }

  static List<EditorPage> _parsePagesJson(
    List<dynamic>? pages, {
    required ReadOnlyReason? readOnlyReason,
    required bool onlyFirstPage,
    required int fileVersion,
    required String notePath,
    required AssetCache assetCache,
  }) {
    if (pages == null || pages.isEmpty) return [];
    return pages
        .take(onlyFirstPage ? 1 : pages.length)
        .map(
          (dynamic page) => EditorPage.fromJson(
            page as Map<String, dynamic>,
            readOnly: readOnlyReason != null,
            fileVersion: fileVersion,
            notePath: notePath,
            assetCache: assetCache,
          ),
        )
        .toList();
  }

  void _handleEmptyImageIds() {
    for (final page in pages) {
      for (final image in page.images) {
        if (image.id == -1) image.id = nextImageId++;
      }
    }
  }

  /// Adds a page if there are no pages.
  void _ensurePage() {
    if (pages.isEmpty) {
      pages.add(EditorPage());
    }
  }

  void _sortStrokes() {
    for (final page in pages) {
      page.sortStrokes();
    }
  }

  static Future<EditorCoreInfo> loadFromFilePath(
    String path, {
    bool onlyFirstPage = false,
  }) async {
    final bsonBytes = await FileManager.readFile(path + Editor.extension);

    if (bsonBytes == null) {
      return EditorCoreInfo(filePath: path);
    }

    return loadFromFileContents(
      bsonBytes: bsonBytes,
      path: path,
      onlyFirstPage: onlyFirstPage,
    );
  }

  /// Quickly checks if a file is trashed without loading the full content.
  /// Returns `false` if the file doesn't exist or can't be read.
  static Future<bool> isFileTrashed(String path) async {
    final bsonBytes = await FileManager.readFile(path + Editor.extension);
    if (bsonBytes == null) return false;

    try {
      final bsonBinary = BsonBinary.from(bsonBytes);
      final json = BsonCodec.deserialize(bsonBinary);
      return json['del'] as bool? ?? false;
    } catch (e) {
      // If we can't parse, assume not trashed
    }
    return false;
  }

  @visibleForTesting
  static Future<EditorCoreInfo> loadFromFileContents({
    Uint8List? bsonBytes,
    required String path,
    required bool onlyFirstPage,
    bool alwaysUseIsolate = false,
  }) async {
    EditorCoreInfo coreInfo;
    try {
      EditorCoreInfo isolate() => _loadFromFileIsolate(bsonBytes, path, onlyFirstPage);

      final length = bsonBytes!.length;
      if (alwaysUseIsolate || length > 2 * 1024 * 1024) {
        // > 2 MB, run on a separate isolate
        final documentsDirectory = FileManager.documentsDirectory;
        coreInfo = await workerManager.execute(
          () async {
            // We need to rerun some "init" methods in the isolate,
            // see https://github.com/inkotes-notes/inkotes/issues/1031.
            FlavorConfig.setupFromEnvironment();
            await FileManager.init(
              documentsDirectory: documentsDirectory,
              shouldWatchRootDirectory: false,
            );
            StrokeOptionsExtension.setDefaults();
            return isolate();
          },
          // less important than [WorkPriority.immediately]
          priority: WorkPriority.veryHigh,
        );
      } else {
        // if the file is small, just run it on the main thread
        coreInfo = isolate();
      }
    } catch (e, st) {
      log.severe('Failed to load file: $e', e, st);
      if (kDebugMode) {
        rethrow;
      } else {
        coreInfo = EditorCoreInfo(filePath: path, readOnlyReason: .corrupted);
      }
    }

    return coreInfo;
  }

  static EditorCoreInfo _loadFromFileIsolate(
    Uint8List? bsonBytes,
    String path,
    bool onlyFirstPage,
  ) {
    final dynamic json;
    try {
      final bsonBinary = BsonBinary.from(bsonBytes!);
      json = BsonCodec.deserialize(bsonBinary);
    } catch (e, st) {
      log.severe('Failed to parse file: $e', e, st);
      rethrow;
    }

    if (json is! Map<String, dynamic>) {
      throw Exception('Failed to parse json');
    }
    return EditorCoreInfo.fromJson(
      json,
      filePath: path,
      onlyFirstPage: onlyFirstPage,
    );
  }

  /// Returns the json map and a list of assets.
  /// Assets are stored in separate files.
  (Map<String, dynamic> json, OrderedAssetCache) toJson() {
    /// This will be populated in various [toJson] methods.
    final OrderedAssetCache assets = OrderedAssetCache();

    final json = {
      'ver': formatVersion,
      'imgc': nextImageId,
      'bgc': backgroundColor?.toARGB32(),
      'pat': backgroundPattern.name,
      'lh': lineHeight,
      'lw': lineThickness,
      'pgs': pages.map((EditorPage page) => page.toJson(assets)).toList(),
      'pg': initialPageIndex,
      'del': isTrashed,
    };

    return (json, assets);
  }

  /// Converts the current note as an FLE (inkotes Archive) file,
  /// which contains the main bson file and all the assets
  /// compressed into a zip file.
  ///
  /// In the archive, the main bson file is named `main.fln`,
  /// and the assets are named `main.fln.0`, `main.fln.1`, etc.
  ///
  /// If [currentPageIndex] isn't null,
  /// [initialPageIndex] will be updated to it before saving.
  Future<List<int>> saveToFle({required int? currentPageIndex}) async {
    final (bson, assets) = saveToBinary(currentPageIndex: currentPageIndex);
    const filePath = 'main${Editor.extension}';

    final archive = Archive();
    archive.addFile(ArchiveFile(filePath, bson.length, bson));

    await Future.wait([
      for (int i = 0; i < assets.length; ++i)
        assets
            .getBytes(i)
            .then(
              (bytes) => archive.addFile(
                ArchiveFile('$filePath.$i', bytes.length, bytes),
              ),
            ),
    ]);

    return ZipEncoder().encode(archive);
  }

  /// Returns the bson bytes and the assets.
  (Uint8List bson, OrderedAssetCache assets) saveToBinary({
    required int? currentPageIndex,
  }) {
    initialPageIndex = currentPageIndex ?? initialPageIndex;
    final (json, assets) = toJson();
    final bson = BsonCodec.serialize(json);
    return (bson.byteList, assets);
  }

  void dispose() {
    for (final page in pages) {
      page.dispose();
    }
    assetCache.dispose();
  }

  EditorCoreInfo copyWith({
    String? filePath,
    ReadOnlyReason? readOnlyReason,
    int? nextImageId,
    Color? backgroundColor,
    CanvasBackgroundPattern? backgroundPattern,
    int? lineHeight,
    int? lineThickness,
    List<EditorPage>? pages,
  }) {
    return EditorCoreInfo._(
      filePath: filePath ?? this.filePath,
      readOnlyReason: readOnlyReason ?? this.readOnlyReason,
      nextImageId: nextImageId ?? this.nextImageId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundPattern: backgroundPattern ?? this.backgroundPattern,
      lineHeight: lineHeight ?? this.lineHeight,
      lineThickness: lineThickness ?? this.lineThickness,
      pages: pages ?? this.pages,
      initialPageIndex: initialPageIndex,
      assetCache: assetCache,
    );
  }
}
