import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:inkotes/components/canvas/canvas_image.dart';
import 'package:inkotes/components/toolbar/toolbar.dart';
import 'package:inkotes/data/editor/editor_history.dart';
import 'package:inkotes/data/extensions/flutter_extensions.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/tools/eraser.dart';
import 'package:inkotes/data/tools/laser_pointer.dart';
import 'package:inkotes/data/tools/pen.dart';
import 'package:inkotes/data/tools/select.dart';
import 'package:inkotes/data/tools/tool.dart';

/// Mixin that provides drawing gesture handling for the Editor.
///
/// Contains: isDrawGesture, onDrawStart, onDrawUpdate, onDrawEnd,
/// onInteractionEnd, updatePointerData, onHovering/End, onStylusButtonChanged,
/// onWhichPageIsFocalPoint, onMoveImage, onDeleteImage.
mixin EditorDrawingMixin<T extends StatefulWidget> on State<T> {
  // --- Abstract dependencies (must be provided by the mixing class) ---

  dynamic get coreInfo;
  Tool get currentTool;
  set currentTool(Tool tool);
  EditorHistory get history;
  GlobalKey<ToolbarState> get toolbarKey;
  TransformationController get transformationController;
  Tool get lastNonEraserTool;
  set lastNonEraserTool(Tool tool);
  bool get mounted;
  void setState(VoidCallback fn);

  void autosaveAfterDelay();
  void removeExcessPages();
  void undo([EditorHistoryItem? item]);
  void createPage(int pageIndex);

  // --- Drawing state ---

  var lastSeenPointerCount = 0;
  Timer? lastSeenPointerCountTimer;

  Offset previousPosition = Offset.zero;
  Offset moveOffset = Offset.zero;

  var isHovering = true;
  int? dragPageIndex;
  PointerDeviceKind? currentPointerKind;
  double? currentPressure;
  var stylusButtonWasPressed = false;

  // --- Drawing methods ---

  int? onWhichPageIsFocalPoint(Offset focalPoint) {
    for (int i = 0; i < coreInfo.pages.length; ++i) {
      if (coreInfo.pages[i].renderBox == null) continue;
      final pageBounds = Offset.zero & coreInfo.pages[i].size;
      if (pageBounds.contains(
        coreInfo.pages[i].renderBox!.globalToLocal(focalPoint),
      ))
        return i;
    }
    return null;
  }

  bool isDrawGesture(ScaleStartDetails details) {
    if (coreInfo.readOnly) return false;

    CanvasImage.activeListener.notifyListenersPlease();

    lastSeenPointerCountTimer?.cancel();
    if (lastSeenPointerCount >= 2) {
      lastSeenPointerCount = lastSeenPointerCount;
      return false;
    } else if (details.pointerCount >= 2) {
      if (lastSeenPointerCount == 1 &&
          stows.editorFingerDrawing.value &&
          (currentTool is Pen || currentTool is Eraser)) {
        final item = history.removeAccidentalStroke();
        if (item != null) undo(item);
      }
      lastSeenPointerCount = details.pointerCount;
      return false;
    } else {
      lastSeenPointerCount = details.pointerCount;
    }

    dragPageIndex = onWhichPageIsFocalPoint(details.focalPoint);
    if (dragPageIndex == null) return false;

    if (stows.editorFingerDrawing.value ||
        currentPointerKind == PointerDeviceKind.stylus ||
        currentPointerKind == PointerDeviceKind.invertedStylus ||
        currentPressure != null) {
      return true;
    } else {
      return false;
    }
  }

  void onDrawStart(ScaleStartDetails details) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      toolbarKey.currentState?.collapseAll();
    });
    final page = coreInfo.pages[dragPageIndex!];
    final position = page.renderBox!.globalToLocal(details.focalPoint);
    history.canRedo = false;

    if (currentTool is Pen) {
      final pageSize = page.size;
      if (position.dx < 0 ||
          position.dx > pageSize.width ||
          position.dy < 0 ||
          position.dy > pageSize.height) {
        return;
      }
      (currentTool as Pen).onDragStart(
        position,
        page,
        dragPageIndex!,
        currentPressure,
      );
    } else if (currentTool is Eraser) {
      for (final stroke in (currentTool as Eraser).checkForOverlappingStrokes(
        position,
        page.strokes,
      )) {
        page.strokes.remove(stroke);
      }
      removeExcessPages();
    } else if (currentTool is Select) {
      final select = currentTool as Select;
      if (select.doneSelecting &&
          select.selectResult.pageIndex == dragPageIndex! &&
          select.selectResult.path.contains(position)) {
        // drag selection in onDrawUpdate
      } else {
        select.onDragStart(position, dragPageIndex!);
        history.canRedo = true;
      }
    } else if (currentTool is LaserPointer) {
      (currentTool as LaserPointer).onDragStart(position, page, dragPageIndex!);
    }

    previousPosition = position;
    moveOffset = Offset.zero;

    if (currentTool is! Select) {
      Select.currentSelect.unselect();
    }

    setState(() {});
  }

  void onDrawUpdate(ScaleUpdateDetails details) {
    final page = coreInfo.pages[dragPageIndex!];
    final position = page.renderBox!.globalToLocal(details.focalPoint);
    final offset = position - previousPosition;

    if (currentTool is Pen) {
      final pageSize = page.size;
      if (position.dx >= 0 &&
          position.dx <= pageSize.width &&
          position.dy >= 0 &&
          position.dy <= pageSize.height) {
        if (Pen.currentStroke == null) {
          (currentTool as Pen).onDragStart(
            position,
            page,
            dragPageIndex!,
            currentPressure,
          );
          setState(() {});
        }
        (currentTool as Pen).onDragUpdate(position, currentPressure);
      } else {
        final stroke = (currentTool as Pen).onDragEnd();
        if (stroke != null) {
          page.insertStroke(stroke);
          history.recordChange(
            EditorHistoryItem(
              type: .draw,
              pageIndex: dragPageIndex!,
              strokes: [stroke],
              images: const [],
            ),
          );
        }
        autosaveAfterDelay();
      }
      page.redrawStrokes();
    } else if (currentTool is Eraser) {
      for (final stroke in (currentTool as Eraser).checkForOverlappingStrokes(
        position,
        page.strokes,
      )) {
        page.strokes.remove(stroke);
      }
      page.redrawStrokes();
      removeExcessPages();
    } else if (currentTool is Select) {
      final select = currentTool as Select;
      if (select.doneSelecting) {
        for (final stroke in select.selectResult.strokes) {
          stroke.shift(offset);
        }
        for (final image in select.selectResult.images) {
          image.dstRect = image.dstRect.shift(offset);
        }
        select.selectResult.path = select.selectResult.path.shift(offset);
      } else {
        select.onDragUpdate(position);
      }
      page.redrawStrokes();
    } else if (currentTool is LaserPointer) {
      (currentTool as LaserPointer).onDragUpdate(position);
      page.redrawStrokes();
    }
    previousPosition = position;
    moveOffset += offset;
  }

  void onDrawEnd(ScaleEndDetails details) {
    final page = coreInfo.pages[dragPageIndex!];
    bool shouldSave = true;
    setState(() {
      if (currentTool is Pen) {
        final newStroke = (currentTool as Pen).onDragEnd();
        if (newStroke == null) return;
        if (newStroke.isEmpty) return;

        page.insertStroke(newStroke);
        history.recordChange(
          EditorHistoryItem(
            type: .draw,
            pageIndex: dragPageIndex!,
            strokes: [newStroke],
            images: [],
          ),
        );
      } else if (currentTool is Eraser) {
        final erased = (currentTool as Eraser).onDragEnd();
        if (stylusButtonWasPressed) {
          stylusButtonWasPressed = false;
          currentTool = lastNonEraserTool;
        }
        if (erased.isEmpty) return;
        history.recordChange(
          EditorHistoryItem(
            type: .erase,
            pageIndex: dragPageIndex!,
            strokes: erased,
            images: [],
          ),
        );
      } else if (currentTool is Select) {
        if (moveOffset == Offset.zero) return;
        final select = currentTool as Select;
        if (select.doneSelecting) {
          history.recordChange(
            EditorHistoryItem(
              type: .move,
              pageIndex: dragPageIndex!,
              strokes: select.selectResult.strokes,
              images: select.selectResult.images,
              offset: Rect.fromLTRB(
                moveOffset.dx,
                moveOffset.dy,
                moveOffset.dx,
                moveOffset.dy,
              ),
            ),
          );
        } else {
          shouldSave = false;
          select.onDragEnd(page.strokes, page.images);

          if (select.selectResult.isEmpty) {
            Select.currentSelect.unselect();
          }
        }
      } else if (currentTool is LaserPointer) {
        shouldSave = false;
        final newStroke = (currentTool as LaserPointer).onDragEnd(
          page.redrawStrokes,
          (stroke) {
            page.laserStrokes.remove(stroke);
          },
        );
        if (newStroke != null) page.laserStrokes.add(newStroke);
      }
    });

    if (currentTool is Select &&
        Select.currentSelect.doneSelecting &&
        !Select.currentSelect.selectResult.isEmpty) {
      toolbarKey.currentState?.showSelectPanel();
    }

    if (shouldSave) autosaveAfterDelay();
  }

  void onInteractionEnd(ScaleEndDetails details) {
    lastSeenPointerCountTimer?.cancel();
    lastSeenPointerCountTimer = Timer(const Duration(milliseconds: 10), () {
      lastSeenPointerCount = 0;
    });
  }

  void updatePointerData(PointerDeviceKind kind, double? pressure) {
    currentPointerKind = kind;
    currentPressure = pressure;
  }

  void onHovering() {
    isHovering = true;
  }

  void onHoveringEnd() {
    isHovering = false;
  }

  void onStylusButtonChanged(bool buttonIsPressed) {
    stylusButtonWasPressed |= buttonIsPressed;

    if (!isHovering) return;
    if (buttonIsPressed) {
      if (currentTool is! Eraser) {
        currentTool = Eraser();
      }
    } else {
      if (currentTool is Eraser) {
        currentTool = lastNonEraserTool;
      }
    }

    if (mounted) setState(() {});
  }
}
