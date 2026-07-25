import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:foledge/components/canvas/save_indicator.dart';
import 'package:foledge/components/canvas/asset_cache.dart';
import 'package:foledge/components/canvas/image/editor_image.dart';
import 'package:foledge/data/editor/editor_core_info.dart';
import 'package:foledge/data/editor/editor_exporter.dart';
import 'package:foledge/data/file_manager/file_manager.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/data/tools/pen.dart';
import 'package:foledge/data/editor/editor_history.dart';
import 'package:foledge/pages/editor/editor_constants.dart';

/// Mixin that provides file I/O operations for the Editor.
///
/// Contains: autosaveAfterDelay, cancelAutosaveAndMarkSaved, saveToFile,
/// renameFile, _renameFileNow, _validateFilenameTextField, _loadCoreInfo,
/// _initAsync, _autoApplyPaperColor.
mixin EditorFileMixin<T extends StatefulWidget> on State<T> {
  // --- Abstract dependencies ---

  final log = Logger('EditorState');
  dynamic get coreInfo;
  set coreInfo(dynamic info);
  bool get mounted;
  void setState(VoidCallback fn);
  EditorHistory get history;

  // --- File state ---

  ValueNotifier<SavingState> savingState = ValueNotifier(SavingState.saved);
  Timer? delayedSaveTimer;
  Timer? renameTimer;

  final filenameFormKey = GlobalKey<FormState>();
  final filenameTextEditingController = TextEditingController();
  var needsNaming = false;

  // --- File methods ---

  void autoApplyPaperColor(Brightness brightness) {
    if (!stows.autoSwitchPaperColor.value) return;
    if (coreInfo.readOnly) return;
    final currentColor = coreInfo.backgroundColor?.toARGB32();
    const white = 0xFFFFFFFF;
    const dark = 0xFF272735;
    if (currentColor != white && currentColor != dark) return;
    final targetColor = brightness == Brightness.dark ? dark : white;
    if (currentColor == targetColor) return;
    setState(() {
      coreInfo.backgroundColor = Color(targetColor);
    });
    saveToFile(force: true);
  }

  void autosaveAfterDelay() {
    if (history.isCurrentStateSaved) return cancelAutosaveAndMarkSaved();

    late final void Function() callback;

    void startTimer() {
      delayedSaveTimer?.cancel();
      if (stows.autosaveDelay.value < 0) return;
      delayedSaveTimer = Timer(
        Duration(milliseconds: stows.autosaveDelay.value),
        callback,
      );
    }

    callback = () {
      if (Pen.currentStroke != null) {
        startTimer();
        return;
      }
      saveToFile();
    };

    savingState.value = SavingState.waitingToSave;
    startTimer();
  }

  void cancelAutosaveAndMarkSaved() {
    delayedSaveTimer?.cancel();
    savingState.value = SavingState.saved;
    history.markLastChangeAsSaved();
  }

  Future<void> saveToFile({bool force = false}) async {
    if (coreInfo.readOnly) return;

    switch (savingState.value) {
      case SavingState.saved:
        if (!force) return;
        savingState.value = SavingState.waitingToSave;
        break;
      case SavingState.saving:
        log.warning('saveToFile() called while already saving');
        return;
      case SavingState.waitingToSave:
        break;
    }
    delayedSaveTimer?.cancel();
    savingState.value = SavingState.saving;
    if (!force && history.isCurrentStateSaved) return cancelAutosaveAndMarkSaved();

    await renameFileNow();

    final filePath = coreInfo.filePath + EditorConstants.extension;
    final Uint8List bson;
    final OrderedAssetCache assets;
    coreInfo.assetCache.allowRemovingAssets = false;
    try {
      (bson, assets) = coreInfo.saveToBinary(
        currentPageIndex: currentPageIndex,
      );
    } finally {
      coreInfo.assetCache.allowRemovingAssets = true;
    }
    try {
      await Future.wait([
        FileManager.writeFile(filePath, bson, awaitWrite: true),
        for (int i = 0; i < assets.length; ++i)
          assets
              .getBytes(i)
              .then(
                (bytes) => FileManager.writeFile(
                  '$filePath.$i',
                  bytes,
                  awaitWrite: true,
                ),
              ),
        FileManager.removeUnusedAssets(filePath, numAssets: assets.length),
      ]);
      savingState.value = SavingState.saved;
      history.markLastChangeAsSaved();
    } catch (e, st) {
      log.severe('Failed to save file: $e', e, st);
      savingState.value = SavingState.waitingToSave;
      if (kDebugMode) rethrow;
      return;
    }

    if (!mounted) return;
    final page = coreInfo.pages.first;
    final previewHeight = page.previewHeight(lineHeight: coreInfo.lineHeight);
    final thumbnailSize = Size(720, 720 * previewHeight / page.size.width);
    final thumbnail = await EditorExporter.screenshotPage(
      coreInfo: coreInfo,
      pageIndex: 0,
      rasterizeAllStrokes: true,
      targetSize: thumbnailSize,
      cropHeight: previewHeight,
      pixelRatio: 1,
    );
    final thumbnailPng = await thumbnail.toByteData(format: .png);
    thumbnail.dispose();
    await FileManager.writeFile(
      '$filePath.p',
      thumbnailPng!.buffer.asUint8List(),
      awaitWrite: true,
    );
  }

  // Must be provided by the mixing class
  int get currentPageIndex;

  void renameFile([String? _]) {
    renameTimer?.cancel();
    renameTimer = Timer(const Duration(seconds: 5), renameFileNow);
  }

  Future<void> renameFileNow() async {
    final newName = filenameTextEditingController.text.trim();
    if (newName == coreInfo.fileName) return;

    if (filenameFormKey.currentState?.validate() ??
        _validateFilenameTextField(newName) == null) {
      coreInfo.filePath = await FileManager.moveFile(
        coreInfo.filePath + EditorConstants.extension,
        newName.trim() + EditorConstants.extension,
      );
      coreInfo.filePath = coreInfo.filePath.substring(
        0,
        coreInfo.filePath.lastIndexOf(EditorConstants.extension),
      );
      needsNaming = false;
    }

    final actualName = coreInfo.fileName;
    if (actualName != newName) {
      filenameTextEditingController.value = filenameTextEditingController.value
          .copyWith(
            text: actualName,
            selection: TextSelection.fromPosition(
              TextPosition(offset: actualName.length),
            ),
            composing: TextRange.empty,
          );
    }
  }

  String? _validateFilenameTextField(String? newName) {
    if (newName == null) return null;
    return FileManager.validateFilename(newName);
  }

  Future<void> loadCoreInfo(String filePath) async {
    coreInfo = await EditorCoreInfo.loadFromFilePath(filePath);
    if (coreInfo.readOnly) {
      log.info('Loaded file as read-only: ${coreInfo.readOnlyReason}');
    }

    if (coreInfo.isEmpty) {
      createPage(-1);
    } else {
      for (final page in coreInfo.pages) {
        page.backgroundImage?.onMoveImage = onMoveImage;
        page.backgroundImage?.onDeleteImage = onDeleteImage;
        page.backgroundImage?.onMiscChange = autosaveAfterDelay;
        for (final image in page.images) {
          image.onMoveImage = onMoveImage;
          image.onDeleteImage = onDeleteImage;
          image.onMiscChange = autosaveAfterDelay;
        }
      }
    }

    setState(() {});
    autoApplyPaperColor(Theme.of(context).brightness);
  }

  // Must be provided by the mixing class
  void onMoveImage(EditorImage image, Rect offset);
  void onDeleteImage(EditorImage image);
  void createPage(int pageIndex);

  void initAsync(String initialPath, String? pdfPath) async {
    final filePath = initialPath;
    filenameTextEditingController.text = p.basename(filePath);

    if (needsNaming) {
      filenameTextEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: filenameTextEditingController.text.length,
      );
    }

    await loadCoreInfo(filePath);

    if (pdfPath != null) {
      await importPdfFromFilePath(pdfPath);
    }
  }

  // Must be provided by the mixing class for PDF import
  Future<bool> importPdfFromFilePath(String path);
}
