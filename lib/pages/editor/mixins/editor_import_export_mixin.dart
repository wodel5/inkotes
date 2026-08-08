import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:inkotes/components/canvas/image/editor_image.dart';
import 'package:inkotes/components/common/app_toast.dart';
import 'package:inkotes/data/editor/editor_exporter.dart';
import 'package:inkotes/data/editor/editor_history.dart';
import 'package:inkotes/data/editor/editor_page.dart';
import 'package:inkotes/data/file_manager/file_exporter.dart';
import 'package:inkotes/i18n/strings.g.dart';
import 'package:inkotes/pages/editor/editor_constants.dart';
import 'package:super_clipboard/super_clipboard.dart';

typedef PhotoInfo = ({Uint8List bytes, String extension});

/// Mixin that provides import/export operations for the Editor.
///
/// Contains: _pickPhotos, _pickPhotosWithFilePicker, importPdf,
/// importPdfFromFilePath, paste, exportAsPdf, exportAsIks, exportAsPng.
mixin EditorImportExportMixin<T extends StatefulWidget> on State<T> {
  // --- Abstract dependencies ---

  final log = Logger('EditorImportExport');
  dynamic get coreInfo;
  bool get mounted;
  void setState(VoidCallback fn);

  int get currentPageIndex;
  void autosaveAfterDelay();
  void createPage(int pageIndex);

  void onMoveImage(EditorImage image, Rect offset);
  void onDeleteImage(EditorImage image);

  // --- Import/Export methods ---

  Future<int> pickPhotos([List<PhotoInfo>? photoInfos]) async {
    if (coreInfo.readOnly) return 0;

    final currentPageIndex = this.currentPageIndex;

    photoInfos ??= await _pickPhotosWithFilePicker();
    if (photoInfos.isEmpty) return 0;

    final images = [
      for (final photoInfo in photoInfos)
        if (photoInfo.extension == '.svg')
          SvgEditorImage(
            id: coreInfo.nextImageId++,
            svgString: utf8.decode(photoInfo.bytes),
            svgFile: null,
            pageIndex: currentPageIndex,
            pageSize: coreInfo.pages[currentPageIndex].size,
            onMoveImage: onMoveImage,
            onDeleteImage: onDeleteImage,
            onMiscChange: autosaveAfterDelay,
            onLoad: () => setState(() {}),
            assetCache: coreInfo.assetCache,
          )
        else
          PngEditorImage(
            id: coreInfo.nextImageId++,
            extension: photoInfo.extension,
            imageProvider: MemoryImage(photoInfo.bytes),
            pageIndex: currentPageIndex,
            pageSize: coreInfo.pages[currentPageIndex].size,
            onMoveImage: onMoveImage,
            onDeleteImage: onDeleteImage,
            onMiscChange: autosaveAfterDelay,
            onLoad: () => setState(() {}),
            assetCache: coreInfo.assetCache,
          ),
    ];

    history.recordChange(
      EditorHistoryItem(
        type: EditorHistoryItemType.draw,
        pageIndex: currentPageIndex,
        strokes: [],
        images: images,
      ),
    );
    createPage(currentPageIndex);
    coreInfo.pages[currentPageIndex].images.addAll(images);
    setState(() {});
    autosaveAfterDelay();

    return images.length;
  }

  EditorHistory get history;

  Future<List<PhotoInfo>> _pickPhotosWithFilePicker() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isEmpty) return const [];

    final List<PhotoInfo> result = [];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final extension = '.${image.name.split('.').last.toLowerCase()}';
      result.add((bytes: bytes, extension: extension));
    }
    return result;
  }

  Future<bool> importPdf() async {
    if (coreInfo.readOnly) return false;
    if (!EditorConstants.canRasterPdf) return false;

    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null) return false;

    final PlatformFile file = result.files.single;
    return importPdfFromFilePath(file.path!);
  }

  Future<bool> importPdfFromFilePath(String path) async {
    final pdfDocument = await coreInfo.assetCache.pdfDocumentCache.load(path);

    final emptyPage = coreInfo.pages.removeLast();
    assert(emptyPage.isEmpty);

    try {
      for (final pdfPage in pdfDocument.pages) {
        assert(pdfPage.pageNumber >= 1, 'pdfrx page numbers start at 1');

        final pageSize = Size(
          EditorPage.defaultWidth,
          EditorPage.defaultWidth * pdfPage.height / pdfPage.width,
        );

        final page = EditorPage(
          size: pageSize,
          backgroundImage: PdfEditorImage(
            id: coreInfo.nextImageId++,
            pdfBytes: null,
            pdfFile: File(path),
            pdfPage: pdfPage.pageNumber - 1,
            pageIndex: coreInfo.pages.length,
            pageSize: pageSize,
            // 注意：不能用 pdfPage.size（那是 pdfrx 的扩展，coreInfo 是
            // dynamic 导致这里解析为实例成员而崩溃），改用实例成员。
            naturalSize: Size(pdfPage.width, pdfPage.height),
            onMoveImage: onMoveImage,
            onDeleteImage: onDeleteImage,
            onMiscChange: autosaveAfterDelay,
            onLoad: () => setState(() {}),
            assetCache: coreInfo.assetCache,
          ),
        );
        coreInfo.pages.add(page);
        history.recordChange(
          EditorHistoryItem(
            type: EditorHistoryItemType.insertPage,
            pageIndex: coreInfo.pages.length - 1,
            strokes: const [],
            images: const [],
            page: page,
          ),
        );
      }
    } finally {
      // 即使导入中途失败也恢复空页，避免 pages 为空导致保存崩溃
      coreInfo.pages.add(emptyPage);
    }

    if (mounted) setState(() {});

    autosaveAfterDelay();

    return true;
  }

  Future paste() async {
    const Map<SimpleFileFormat, String> formats = {
      Formats.jpeg: '.jpeg',
      Formats.png: '.png',
      Formats.gif: '.gif',
      Formats.tiff: '.tiff',
      Formats.bmp: '.bmp',
      Formats.ico: '.ico',
      Formats.svg: '.svg',
      Formats.webp: '.webp',
    };

    final reader = await SystemClipboard.instance?.read();
    if (reader == null) return;

    final List<PhotoInfo> photoInfos = [];
    final List<ReadProgress> progresses = [];

    for (final format in formats.keys) {
      if (!reader.canProvide(format)) continue;
      final progress = reader.getFile(format, (file) async {
        final stream = file.getStream();
        final List<int> bytes = [];
        await for (final chunk in stream) {
          bytes.addAll(chunk);
        }
        if (bytes.isEmpty) {
          log.warning('Pasted empty file: $file (${formats[format]})');
          return;
        }

        String extension;
        if (file.fileName != null) {
          extension = file.fileName!.substring(file.fileName!.lastIndexOf('.'));
        } else {
          extension = formats[format]!;
        }

        photoInfos.add((
          bytes: Uint8List.fromList(bytes),
          extension: extension,
        ));
      });
      if (progress != null) progresses.add(progress);
    }

    while (progresses.isNotEmpty) {
      progresses.removeWhere((progress) => progress.fraction.value == 1);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await pickPhotos(photoInfos);
  }

  Future exportAsPdf(BuildContext context) async {
    try {
      final pdf = await EditorExporter.generatePdf(coreInfo, context);
      final bytes = await pdf.save();
      // 不能用传入的 context 做 mounted 检查：导出耗时期间工具栏面板可能
      // 因自动折叠被移除，导致 context 失效而跳过保存。改用 State 的 context。
      await FileExporter.exportFile(
        '${coreInfo.fileName}.pdf',
        bytes,
        context: this.context,
      );
      if (mounted) {
        AppToast.show(this.context, message: t.editor.export.pdfSuccess);
      }
    } catch (e, st) {
      log.severe('Failed to export PDF', e, st);
      if (mounted) {
        AppToast.show(
          this.context,
          message: t.editor.export.pdfFailed,
          isError: true,
        );
      }
    }
  }

  Future exportAsIks(BuildContext context) async {
    try {
      final iks = await coreInfo.saveToFle(currentPageIndex: currentPageIndex);
      await FileExporter.exportFile(
        '${coreInfo.fileName}.zip',
        iks,
        context: this.context,
      );
      if (mounted) {
        AppToast.show(this.context, message: t.editor.export.iksSuccess);
      }
    } catch (e, st) {
      log.severe('Failed to export IKS', e, st);
      if (mounted) {
        AppToast.show(
          this.context,
          message: t.editor.export.iksFailed,
          isError: true,
        );
      }
    }
  }

  Future exportAsPng(BuildContext context) async {
    final page = coreInfo.pages[currentPageIndex];

    const maxRasterizableSize = 3000.0;
    var targetPixelRatio = maxRasterizableSize / page.size.longestSide;
    if (targetPixelRatio > 1) targetPixelRatio = 1;

    try {
      final image = await EditorExporter.screenshotPage(
        coreInfo: coreInfo,
        pageIndex: currentPageIndex,
        rasterizeAllStrokes: true,
        pixelRatio: targetPixelRatio,
      );
      final pngBytes = await image.toByteData(format: .png);
      image.dispose();

      if (!context.mounted) return;
      final success = await FileExporter.exportFile(
        '${coreInfo.fileName}_page_${currentPageIndex + 1}.png',
        pngBytes!.buffer.asUint8List(),
        isImage: true,
        context: context,
      );

      if (context.mounted) {
        if (success) {
          AppToast.show(context, message: t.editor.export.pngSuccess);
        } else {
          AppToast.show(
            context,
            message: t.editor.export.pngFailed,
            isError: true,
          );
        }
      }
    } catch (e, st) {
      log.severe('Failed to export PNG', e, st);
      if (context.mounted) {
        AppToast.show(
          context,
          message: t.editor.export.pngFailed,
          isError: true,
        );
      }
    }
  }
}
