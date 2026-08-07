import 'package:flutter/material.dart';
import 'package:inkotes/components/canvas/stroke.dart';
import 'package:inkotes/components/canvas/image/editor_image.dart';
import 'package:inkotes/components/canvas/canvas_gesture_detector.dart';
import 'package:inkotes/data/editor/editor_history.dart';
import 'package:inkotes/data/editor/editor_page.dart';
import 'package:inkotes/data/tools/select.dart';

/// Mixin that provides history (undo/redo) and page management for the Editor.
///
/// Contains: undo, redo, createPage, removeExcessPages, insertPageAfter,
/// clearPage, clearAllPages.
mixin EditorHistoryMixin<T extends StatefulWidget> on State<T> {
  // --- Abstract dependencies ---

  dynamic get coreInfo;
  bool get mounted;
  void setState(VoidCallback fn);

  TransformationController get transformationController;
  void autosaveAfterDelay();

  // --- History state ---

  var history = EditorHistory();

  // --- History methods ---

  void undo([EditorHistoryItem? item]) {
    if (item == null) {
      if (!history.canUndo) return;

      if (!history.canRedo) {
        history.clearRedo();
        history.canRedo = true;
      }

      item = history.undo();
    }

    setState(() {
      switch (item!.type) {
        case EditorHistoryItemType.draw:
          for (final stroke in item.strokes) {
            coreInfo.pages[stroke.pageIndex].strokes.remove(stroke);
          }
          for (final image in item.images) {
            coreInfo.pages[image.pageIndex].images.remove(image);
          }
          removeExcessPages();

        case EditorHistoryItemType.erase:
          for (final stroke in item.strokes) {
            createPage(stroke.pageIndex);
            coreInfo.pages[stroke.pageIndex].insertStroke(stroke);
          }
          for (final image in item.images) {
            createPage(image.pageIndex);
            coreInfo.pages[image.pageIndex].images.add(image);
            image.newImage = true;
          }

        case EditorHistoryItemType.deletePage:
          createPage(item.pageIndex - 1);
          coreInfo.pages.insert(item.pageIndex, item.page!);
          for (int i = item.pageIndex + 1; i < coreInfo.pages.length; ++i) {
            final page = coreInfo.pages[i];
            page.updatePageIndex(i);
          }

        case EditorHistoryItemType.insertPage:
          coreInfo.pages.removeAt(item.pageIndex);
          for (int i = item.pageIndex; i < coreInfo.pages.length; ++i) {
            final page = coreInfo.pages[i];
            page.updatePageIndex(i);
          }

        case EditorHistoryItemType.move:
          for (final stroke in item.strokes) {
            stroke.shift(Offset(-item.offset!.left, -item.offset!.top));
          }
          final select = Select.currentSelect;
          if (select.doneSelecting) {
            select.selectResult.path = select.selectResult.path.shift(
              Offset(-item.offset!.left, -item.offset!.top),
            );
          }
          for (final image in item.images) {
            image.dstRect = Rect.fromLTRB(
              image.dstRect.left - item.offset!.left,
              image.dstRect.top - item.offset!.top,
              image.dstRect.right - item.offset!.right,
              image.dstRect.bottom - item.offset!.bottom,
            );
          }

        case EditorHistoryItemType.quillChange:
          final quill = coreInfo.pages[item.pageIndex].quill;
          quill.controller.undo();

        case EditorHistoryItemType.quillUndoneChange:
          final quill = coreInfo.pages[item.pageIndex].quill;
          quill.controller.redo();

        case EditorHistoryItemType.changeColor:
          for (final stroke in item.strokes) {
            stroke.color = item.colorChange![stroke]!.previous;
          }

        case EditorHistoryItemType.backgroundPattern:
          coreInfo.backgroundPattern = item.backgroundPatternChange!.previous;
      }

      if (item.type != EditorHistoryItemType.move) {
        Select.currentSelect.unselect();
      }
    });

    autosaveAfterDelay();
  }

  void redo() {
    if (!history.canRedo) return;
    final item = history.redo();

    switch (item.type) {
      case EditorHistoryItemType.draw:
        undo(item.copyWith(type: EditorHistoryItemType.erase));
      case EditorHistoryItemType.erase:
        undo(item.copyWith(type: EditorHistoryItemType.draw));
      case EditorHistoryItemType.deletePage:
        undo(item.copyWith(type: EditorHistoryItemType.insertPage));
      case EditorHistoryItemType.insertPage:
        undo(item.copyWith(type: EditorHistoryItemType.deletePage));
      case EditorHistoryItemType.move:
        undo(
          item.copyWith(
            offset: Rect.fromLTRB(
              -item.offset!.left,
              -item.offset!.top,
              -item.offset!.right,
              -item.offset!.bottom,
            ),
          ),
        );
      case EditorHistoryItemType.quillChange:
        undo(item.copyWith(type: EditorHistoryItemType.quillUndoneChange));
      case EditorHistoryItemType.quillUndoneChange:
        throw Exception('history should not contain quillUndoneChange items');
      case EditorHistoryItemType.changeColor:
        undo(
          item.copyWith(
            colorChange: item.colorChange!.map(
              (key, value) => MapEntry(key, value.reverse()),
            ),
          ),
        );
      case EditorHistoryItemType.backgroundPattern:
        undo(
          item.copyWith(
            backgroundPatternChange: item.backgroundPatternChange!.reverse(),
          ),
        );
    }
  }

  void createPage(int pageIndex) {
    while (pageIndex >= coreInfo.pages.length - 1) {
      final page = EditorPage();
      coreInfo.pages.add(page);
    }
  }

  void removeExcessPages() {
    bool removedAPage = false;

    for (int i = coreInfo.pages.length - 1; i >= 1; --i) {
      final thisPage = coreInfo.pages[i];
      final prevPage = coreInfo.pages[i - 1];
      if (thisPage.isEmpty && prevPage.isEmpty) {
        final page = coreInfo.pages.removeAt(i);
        page.dispose();
        removedAPage = true;
      } else {
        break;
      }
    }

    if (removedAPage) {
      final scrollY = this.scrollY;
      late final topOfLastPage = -CanvasGestureDetector.getTopOfPage(
        pageIndex: coreInfo.pages.length - 1,
        pages: coreInfo.pages,
        screenWidth: MediaQuery.sizeOf(context).width,
      );
      final bottomOfLastPage = -CanvasGestureDetector.getTopOfPage(
        pageIndex: coreInfo.pages.length,
        pages: coreInfo.pages,
        screenWidth: MediaQuery.sizeOf(context).width,
      );

      if (scrollY < bottomOfLastPage) {
        transformationController.value = Matrix4.translationValues(
          0,
          topOfLastPage + 50,
          0,
        );
      }
    }
  }

  // Must be provided by the mixing class
  double get scrollY;

  void insertPageAfter(int pageIndex) => setState(() {
    if (coreInfo.readOnly) return;
    final page = EditorPage();
    coreInfo.pages.insert(pageIndex + 1, page);
    history.recordChange(
      EditorHistoryItem(
        type: EditorHistoryItemType.insertPage,
        pageIndex: pageIndex + 1,
        strokes: const [],
        images: const [],
        page: page,
      ),
    );
    autosaveAfterDelay();
  });

  void clearPage(int pageIndex) {
    if (coreInfo.readOnly) return;
    final page = coreInfo.pages[pageIndex];
    setState(() {
      final removedStrokes = page.strokes.toList();
      final removedImages = page.images.toList();
      page.strokes.clear();
      page.images.clear();
      history.recordChange(
        EditorHistoryItem(
          type: EditorHistoryItemType.erase,
          pageIndex: pageIndex,
          strokes: removedStrokes,
          images: removedImages,
        ),
      );
      autosaveAfterDelay();
    });
  }

  void clearAllPages() {
    if (coreInfo.readOnly) return;
    setState(() {
      final removedStrokes = <Stroke>[];
      final removedImages = <EditorImage>[];
      for (final page in coreInfo.pages) {
        removedStrokes.addAll(page.strokes);
        removedImages.addAll(page.images);
        page.strokes.clear();
        page.images.clear();
      }
      removeExcessPages();
      history.recordChange(
        EditorHistoryItem(
          type: EditorHistoryItemType.erase,
          pageIndex: 0,
          strokes: removedStrokes,
          images: removedImages,
        ),
      );
    });
  }
}
