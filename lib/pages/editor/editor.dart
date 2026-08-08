import 'dart:async';
import 'dart:math' show max;

import 'package:collapsible/collapsible.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as flutter_quill;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:keybinder/keybinder.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:inkotes/components/canvas/canvas.dart';
import 'package:inkotes/components/canvas/canvas_gesture_detector.dart';
import 'package:inkotes/components/canvas/canvas_image.dart';
import 'package:inkotes/components/canvas/save_indicator.dart';
import 'package:inkotes/pages/editor/widgets/more_menu_overlay.dart';
import 'package:inkotes/pages/editor/widgets/read_only_banner.dart';
import 'package:inkotes/components/theming/adaptive_icon.dart';
import 'package:inkotes/components/toolbar/editor_bottom_sheet.dart';
import 'package:inkotes/components/toolbar/toolbar.dart';
import 'package:inkotes/data/editor/editor_core_info.dart';
import 'package:inkotes/data/editor/editor_history.dart';
import 'package:inkotes/data/editor/editor_page.dart';
import 'package:inkotes/data/extensions/flutter_extensions.dart';
import 'package:inkotes/data/file_manager/file_importer.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/tools/tool.dart';
import 'package:inkotes/data/tools/eraser.dart';
import 'package:inkotes/data/tools/highlighter.dart';
import 'package:inkotes/data/tools/laser_pointer.dart';
import 'package:inkotes/data/tools/pen.dart';
import 'package:inkotes/data/tools/pencil.dart';
import 'package:inkotes/data/tools/select.dart';
import 'package:inkotes/components/canvas/stroke.dart';
import 'package:inkotes/components/canvas/image/editor_image.dart';
import 'package:inkotes/components/toolbar/color_bar.dart';
import 'package:inkotes/data/extensions/math_extensions.dart';
import 'package:inkotes/i18n/strings.g.dart';
import 'package:inkotes/data/models/change.dart';
import 'package:inkotes/pages/editor/editor_constants.dart';
import 'package:inkotes/pages/editor/mixins/editor_drawing_mixin.dart';
import 'package:inkotes/pages/editor/mixins/editor_file_mixin.dart';
import 'package:inkotes/pages/editor/mixins/editor_history_mixin.dart';
import 'package:inkotes/pages/editor/mixins/editor_import_export_mixin.dart';

class Editor extends StatefulWidget {
  Editor({super.key, String? path, this.customTitle, this.pdfPath})
    : initialPath = path != null
          ? Future.value(path)
          : FileImporter.newFilePath('/'),
      needsNaming = path == null;

  final Future<String> initialPath;
  final bool needsNaming;
  final String? customTitle;
  final String? pdfPath;

  static const extension = EditorConstants.extension;
  static const double gapBetweenPages = EditorConstants.gapBetweenPages;

  static bool isReservedPath(String path) {
    return _reservedFilePaths.any((regex) => regex.hasMatch(path));
  }

  static final _reservedFilePaths = <RegExp>[];
  static bool get canRasterPdf => EditorConstants.canRasterPdf;
  static set canRasterPdf(bool value) => EditorConstants.canRasterPdf = value;

  @override
  State<Editor> createState() => EditorState();
}

class EditorState extends State<Editor>
    with
        EditorHistoryMixin<Editor>,
        EditorDrawingMixin<Editor>,
        EditorFileMixin<Editor>,
        EditorImportExportMixin<Editor> {
  final log = Logger('EditorState');

  late var coreInfo = EditorCoreInfo.placeholder;
  Brightness? _lastBrightness;

  final _canvasGestureDetectorKey = GlobalKey<CanvasGestureDetectorState>();
  final _toolbarKey = GlobalKey<ToolbarState>();
  final _transformationController = TransformationController();

  double get scrollY {
    final transformation = _transformationController.value;
    final scale = transformation.approxScale;
    final translation = transformation.getTranslation();
    final gestureDetector = _canvasGestureDetectorKey.currentState;

    if (gestureDetector == null) {
      log.warning('scrollY: Could not find CanvasGestureDetectorState');
      return translation.y / scale;
    } else {
      final middle = gestureDetector.containerBounds.maxHeight / 2;
      return (translation.y - middle) / scale + middle;
    }
  }

  late bool needsNaming = widget.needsNaming;

  late Tool _currentTool = () {
    switch (stows.lastTool.value) {
      case .fountainPen:
        if (Pen.currentPen.toolId != stows.lastTool.value) {
          Pen.currentPen = Pen.fountainPen();
        }
        return Pen.currentPen;
      case .ballpointPen:
        if (Pen.currentPen.toolId != stows.lastTool.value) {
          Pen.currentPen = Pen.ballpointPen();
        }
        return Pen.currentPen;
      case .highlighter:
        return Highlighter.currentHighlighter;
      case .pencil:
        return Pencil.currentPencil;
      case .eraser:
        return Eraser();
      case .select:
        return Select.currentSelect;
      case .laserPointer:
        return LaserPointer.currentLaserPointer;
      default:
        return Pen.currentPen;
    }
  }();
  Tool get currentTool => _currentTool;
  set currentTool(Tool tool) {
    _currentTool = tool;
    if (tool is! Eraser) _lastNonEraserTool = tool;
    stows.lastTool.value = tool.toolId;
  }

  late Tool _lastNonEraserTool = Pen.currentPen;

  @override
  GlobalKey<ToolbarState> get toolbarKey => _toolbarKey;

  @override
  TransformationController get transformationController =>
      _transformationController;

  @override
  Tool get lastNonEraserTool => _lastNonEraserTool;
  @override
  set lastNonEraserTool(Tool tool) => _lastNonEraserTool = tool;

  late int _lastCurrentPageIndex = coreInfo.initialPageIndex ?? 0;
  @override
  int get currentPageIndex {
    if (!mounted) return _lastCurrentPageIndex;

    final screenWidth = MediaQuery.sizeOf(context).width;

    return _lastCurrentPageIndex = getPageIndexFromScrollPosition(
      scrollY: -scrollY,
      screenWidth: screenWidth,
      pages: coreInfo.pages,
    );
  }

  @override
  void onMoveImage(EditorImage image, Rect offset) {
    history.recordChange(
      EditorHistoryItem(
        type: EditorHistoryItemType.move,
        pageIndex: image.pageIndex,
        strokes: [],
        images: [image],
        offset: offset,
      ),
    );
    setState(() {});
    autosaveAfterDelay();
  }

  @override
  void onDeleteImage(EditorImage image) {
    history.recordChange(
      EditorHistoryItem(
        type: EditorHistoryItemType.erase,
        pageIndex: image.pageIndex,
        strokes: [],
        images: [image],
      ),
    );
    setState(() {
      coreInfo.pages[image.pageIndex].images.remove(image);
    });
    autosaveAfterDelay();
  }

  EditorImage _duplicateImage(EditorImage image, {Offset offset = const Offset(25, -25)}) {
    final newImage = image.copy()
      ..id = coreInfo.nextImageId++
      ..dstRect = image.dstRect.shift(offset);
    const pad = 25.0;
    final r = newImage.dstRect;
    final pageSize = coreInfo.pages[image.pageIndex].size;
    newImage.dstRect = Rect.fromLTWH(
      r.left.clamp(pad, max(pad, pageSize.width - r.width - pad)).toDouble(),
      r.top.clamp(pad, max(pad, pageSize.height - r.height - pad)).toDouble(),
      r.width,
      r.height,
    );
    return newImage;
  }

  @override
  void initState() {
    super.initState();
    _initAsync();
    _assignKeybindings();
    _transformationController.addListener(_onTransformChanged);
    CanvasImage.activeImageNotifier.addListener(_onActiveImageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentBrightness = Theme.of(context).brightness;
    if (_lastBrightness != null && _lastBrightness != currentBrightness) {
      autoApplyPaperColor(currentBrightness);
    }
    _lastBrightness = currentBrightness;
  }

  void _onActiveImageChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _initAsync() async {
    final filePath = await widget.initialPath;
    filenameTextEditingController.text = p.basename(filePath);

    if (needsNaming) {
      filenameTextEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: filenameTextEditingController.text.length,
      );
    }

    await loadCoreInfo(filePath);

    if (widget.pdfPath != null) {
      await importPdfFromFilePath(widget.pdfPath!);
    }
  }

  void _onTransformChanged() {
    _toolbarKey.currentState?.collapseAll();
  }

  Keybinding? _ctrlZ, _ctrlY, _ctrlShiftZ;
  void _assignKeybindings() {
    _ctrlZ = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyZ),
    ], inclusive: true);
    _ctrlY = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyY),
    ], inclusive: true);
    _ctrlShiftZ = Keybinding([
      KeyCode.ctrl,
      KeyCode.shift,
      KeyCode.from(LogicalKeyboardKey.keyZ),
    ], inclusive: true);
    Keybinder.bind(_ctrlZ!, undo);
    Keybinder.bind(_ctrlY!, redo);
    Keybinder.bind(_ctrlShiftZ!, redo);
  }

  void _removeKeybindings() {
    if (_ctrlZ != null) Keybinder.remove(_ctrlZ!);
    if (_ctrlY != null) Keybinder.remove(_ctrlY!);
    if (_ctrlShiftZ != null) Keybinder.remove(_ctrlShiftZ!);
  }

  void updateColorBar(Color color) {
    final newColorString = color.toARGB32().toString();

    if (ColorBar.colorPresets.any((c) => c.color.toARGB32() == color.toARGB32())) {
      return;
    }

    if (stows.recentColorsChronological.value.length !=
        stows.recentColorsPositioned.value.length) {
      stows.recentColorsChronological.value = List.of(
        stows.recentColorsPositioned.value,
      );
    }

    stows.recentColorsPositioned.value.remove(newColorString);
    stows.recentColorsChronological.value.remove(newColorString);

    stows.recentColorsPositioned.value.insert(0, newColorString);
    stows.recentColorsChronological.value.add(newColorString);

    if (stows.recentColorsPositioned.value.length > 5) {
      stows.recentColorsPositioned.value.removeLast();
      stows.recentColorsChronological.value.removeAt(0);
    }

    stows.recentColorsChronological.notifyListeners();
    stows.recentColorsPositioned.notifyListeners();
  }

  @visibleForTesting
  static int getPageIndexFromScrollPosition({
    required double scrollY,
    required double screenWidth,
    required List<EditorPage> pages,
  }) {
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final bottomOfPage = CanvasGestureDetector.getTopOfPage(
        pageIndex: pageIndex + 1,
        pages: pages,
        screenWidth: screenWidth,
      );

      if (scrollY < bottomOfPage) {
        return pageIndex;
      }
    }
    return pages.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final Widget canvas = CanvasGestureDetector(
      key: _canvasGestureDetectorKey,
      filePath: coreInfo.filePath,
      isDrawGesture: isDrawGesture,
      onInteractionEnd: onInteractionEnd,
      onDrawStart: onDrawStart,
      onDrawUpdate: onDrawUpdate,
      onDrawEnd: onDrawEnd,
      onHovering: onHovering,
      onHoveringEnd: onHoveringEnd,
      onStylusButtonChanged: onStylusButtonChanged,
      updatePointerData: updatePointerData,
      undo: undo,
      redo: redo,
      pages: coreInfo.pages,
      initialPageIndex: coreInfo.initialPageIndex,
      pageBuilder: pageBuilder,
      placeholderPageBuilder: (BuildContext context, int pageIndex) {
        return Canvas(
          path: coreInfo.filePath,
          page: coreInfo.pages[pageIndex],
          pageIndex: 0,
          coreInfo: EditorCoreInfo.placeholder,
          currentStroke: null,
          currentStrokeDetectedShape: null,
          currentSelection: null,
          placeholder: true,
          setAsBackground: null,
          currentTool: currentTool,
          currentScale: double.minPositive,
        );
      },
      transformationController: _transformationController,
    );

    final readonlyBanner = ReadOnlyBanner(
      coreInfo.readOnlyReason,
    );

    final Widget toolbar = Collapsible(
      axis: CollapsibleAxis.vertical,
      collapsed: false,
      maintainState: true,
      child: SafeArea(
        bottom: true,
        child: Toolbar(
          key: _toolbarKey,
          readOnly: coreInfo.readOnly,
          setTool: (tool) {
            currentTool = tool;

            if (tool is Highlighter) {
              Highlighter.currentHighlighter = tool;
            } else if (tool is Pencil) {
              Pencil.currentPencil = tool;
            } else if (tool is Pen) {
              Pen.currentPen = tool;
            }

            if (mounted) setState(() {});
          },
          currentTool: currentTool,
          duplicateSelection: () {
            final select = currentTool as Select;
            if (!select.doneSelecting) return;

            setState(() {
              final page = coreInfo.pages[select.selectResult.pageIndex];
              final strokes = select.selectResult.strokes;
              final images = select.selectResult.images;

              const duplicationFeedbackOffset = Offset(25, -25);

              final duplicatedStrokes = strokes.map((stroke) {
                return stroke.copy()..shift(duplicationFeedbackOffset);
              }).toList();

              final duplicatedImages = images.map((image) {
                return _duplicateImage(image, offset: duplicationFeedbackOffset);
              }).toList();

              page.strokes.addAll(duplicatedStrokes);
              page.images.addAll(duplicatedImages);

              select.selectResult = select.selectResult.copyWith(
                strokes: duplicatedStrokes,
                images: duplicatedImages,
                path: select.selectResult.path.shift(duplicationFeedbackOffset),
              );

              history.recordChange(
                EditorHistoryItem(
                  type: EditorHistoryItemType.draw,
                  pageIndex: select.selectResult.pageIndex,
                  strokes: duplicatedStrokes,
                  images: duplicatedImages,
                ),
              );
              autosaveAfterDelay();
            });
          },
          deleteSelection: () {
            final select = currentTool as Select;
            if (!select.doneSelecting) return;

            setState(() {
              final page = coreInfo.pages[select.selectResult.pageIndex];
              final strokes = select.selectResult.strokes;
              final images = select.selectResult.images;

              for (final stroke in strokes) {
                page.strokes.remove(stroke);
              }
              for (final image in images) {
                page.images.remove(image);
              }

              select.unselect();

              history.recordChange(
                EditorHistoryItem(
                  type: EditorHistoryItemType.erase,
                  pageIndex: strokes.first.pageIndex,
                  strokes: strokes,
                  images: images,
                ),
              );
              autosaveAfterDelay();
            });
          },
          onDuplicateActiveImage: () {
            final image = CanvasImage.activeImageNotifier.value;
            if (image == null) return;

            setState(() {
              final page = coreInfo.pages[image.pageIndex];
              final duplicatedImage = _duplicateImage(image);

              page.images.add(duplicatedImage);

              history.recordChange(
                EditorHistoryItem(
                  type: EditorHistoryItemType.draw,
                  pageIndex: image.pageIndex,
                  strokes: const [],
                  images: [duplicatedImage],
                ),
              );
              autosaveAfterDelay();
            });
          },
          onDeleteActiveImage: () {
            final image = CanvasImage.activeImageNotifier.value;
            if (image == null) return;

            onDeleteImage(image);
            CanvasImage.activeImageNotifier.value = null;
          },
          setColor: (color) {
            setState(() {
              updateColorBar(color);

              if (currentTool is Highlighter) {
                (currentTool as Highlighter).color = color.withAlpha(
                  Highlighter.alpha,
                );
              } else if (currentTool is Pen) {
                (currentTool as Pen).color = color;
              } else if (currentTool is Select) {
                final select = currentTool as Select;
                if (select.doneSelecting) {
                  final strokes = select.selectResult.strokes;

                  final colorChange = <Stroke, Change<Color>>{};
                  for (final stroke in strokes) {
                    colorChange[stroke] = Change(
                      previous: stroke.color,
                      current: color,
                    );
                    stroke.color = color;
                  }

                  history.recordChange(
                    EditorHistoryItem(
                      type: EditorHistoryItemType.changeColor,
                      pageIndex: strokes.first.pageIndex,
                      strokes: strokes,
                      colorChange: colorChange,
                      images: [],
                    ),
                  );
                  autosaveAfterDelay();
                }
              }
            });
          },
          undo: undo,
          isUndoPossible: history.canUndo,
          redo: redo,
          isRedoPossible: history.canRedo,
          pickPhoto: pickPhotos,
          importPdf: importPdf,
          canRasterPdf: EditorConstants.canRasterPdf,
          paste: paste,
          exportAsIks: exportAsIks,
          exportAsPdf: exportAsPdf,
          exportAsPng: exportAsPng,
        ),
      ),
    );

    final Widget body;
    body = Stack(
      children: [
        Positioned.fill(child: canvas),
        Positioned(left: 0, right: 0, bottom: 0, child: toolbar),
        if (coreInfo.readOnly) readonlyBanner,
      ],
    );

    return ValueListenableBuilder(
      valueListenable: savingState,
      builder: (context, savingState, child) {
        return PopScope(
          canPop: savingState == SavingState.saved,
          onPopInvokedWithResult: (didPop, _) {
            switch (savingState) {
              case SavingState.waitingToSave:
                assert(!didPop);
                saveToFile();
                _waitForSaveAndPop();
              case SavingState.saving:
                assert(!didPop);
                _waitForSaveAndPop();
              case SavingState.saved:
                break;
            }
          },
          child: child!,
        );
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
                toolbarHeight: kToolbarHeight,
                title: widget.customTitle != null
                    ? Text(widget.customTitle!)
                    : Form(
                        key: filenameFormKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          controller: filenameTextEditingController,
                          onChanged: renameFile,
                          autofocus: needsNaming,
                          validator: (v) {
                            if (v == null) return null;
                            return FileManager.validateFilename(v);
                          },
                        ),
                      ),
                leading: SaveIndicator(
                  savingState: savingState,
                  triggerSave: saveToFile,
                ),
                actions: [
                  Builder(
                    builder: (context) {
                      final gestureDetector =
                          _canvasGestureDetectorKey.currentState;
                      final isLocked = gestureDetector?.isZoomLocked ?? false;
                      return IconButton(
                        icon: FaIcon(
                          isLocked
                              ? FontAwesomeIcons.lock
                              : FontAwesomeIcons.unlockKeyhole,
                        ),
                        tooltip: isLocked
                            ? t.editor.hud.unlockZoom
                            : t.editor.hud.lockZoom,
                        onPressed: () {
                          gestureDetector?.setZoomLock(!isLocked);
                          setState(() {});
                        },
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final gestureDetector =
                          _canvasGestureDetectorKey.currentState;
                      final isLocked =
                          gestureDetector?.singleFingerPanLock ?? false;
                      return IconButton(
                        icon: Icon(
                          isLocked ? Icons.swipe_vertical : Icons.swipe_up,
                        ),
                        tooltip: isLocked
                            ? t.editor.hud.unlockSingleFingerPan
                            : t.editor.hud.lockSingleFingerPan,
                        onPressed: () {
                          gestureDetector?.setSingleFingerPanLock(!isLocked);
                          setState(() {});
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.insert_page_break),
                    tooltip: t.editor.menu.insertPage,
                    onPressed: () => setState(() {
                      final currentPageIndex = this.currentPageIndex;
                      insertPageAfter(currentPageIndex);
                      CanvasGestureDetector.scrollToPage(
                        pageIndex: currentPageIndex + 1,
                        pages: coreInfo.pages,
                        screenWidth: MediaQuery.sizeOf(context).width,
                        transformationController: _transformationController,
                      );
                    }),
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const AdaptiveIcon(icon: Icons.more_vert),
                        onPressed: () {
                          _showMoreMenu(context);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
        body: body,
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final buttonRect = button.localToGlobal(Offset.zero) & button.size;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MoreMenu',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MoreMenuOverlay(
          buttonRect: buttonRect,
          child: bottomSheet(context),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  void _waitForSaveAndPop() {
    void listener() {
      if (savingState.value == SavingState.saved) {
        savingState.removeListener(listener);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
    savingState.addListener(listener);
  }

  Widget bottomSheet(BuildContext context) {
    final int currentPageIndex = this.currentPageIndex;

    return EditorBottomSheet(
      coreInfo: coreInfo,
      currentPageIndex: currentPageIndex,
      setBackgroundPattern: (pattern) => setState(() {
        if (coreInfo.readOnly) return;
        final previous = coreInfo.backgroundPattern;
        coreInfo.backgroundPattern = pattern;
        stows.lastBackgroundPattern.value = pattern;
        history.recordChange(
          EditorHistoryItem(
            type: EditorHistoryItemType.backgroundPattern,
            pageIndex: currentPageIndex,
            backgroundPatternChange: Change(
              previous: previous,
              current: pattern,
            ),
            strokes: [],
            images: [],
          ),
        );
        autosaveAfterDelay();
      }),
      setBackgroundColor: (color) {
        setState(() {
          if (coreInfo.readOnly) return;
          coreInfo.backgroundColor = color;
          stows.lastBackgroundColor.value = color?.toARGB32();
        });
        saveToFile(force: true);
      },
      setLineHeight: (lineHeight) => setState(() {
        if (coreInfo.readOnly) return;
        coreInfo.lineHeight = lineHeight;
        stows.lastLineHeight.value = lineHeight;
        saveToFile(force: true);
      }),
      setLineThickness: (lineThickness) => setState(() {
        if (coreInfo.readOnly) return;
        coreInfo.lineThickness = lineThickness;
        stows.lastLineThickness.value = lineThickness;
        saveToFile(force: true);
      }),
      clearPage: (pageIndex) {
        clearPage(pageIndex);
      },
      insertPageAfter: insertPageAfter,
      duplicatePage: (int pageIndex) => setState(() {
        if (coreInfo.readOnly) return;
        final page = coreInfo.pages[pageIndex];
        final newPage = page.copyWith(
          strokes: page.strokes
              .map((stroke) => stroke.copy()..pageIndex += 1)
              .toList(),
          images: page.images
              .map((image) => image.copy()..pageIndex += 1)
              .toList(),
          quill: QuillStruct(
            controller: flutter_quill.QuillController(
              document: flutter_quill.Document.fromDelta(
                page.quill.controller.document.toDelta(),
              ),
              selection: const TextSelection.collapsed(offset: 0),
            ),
            focusNode: FocusNode(debugLabel: 'Quill Focus Node'),
          ),
          backgroundImage: page.backgroundImage?.copy()?..pageIndex += 1,
        );
        coreInfo.pages.insert(pageIndex + 1, newPage);
        history.recordChange(
          EditorHistoryItem(
            type: EditorHistoryItemType.insertPage,
            pageIndex: pageIndex,
            strokes: const [],
            images: const [],
            page: newPage,
          ),
        );
        autosaveAfterDelay();
      }),
      deletePage: (int pageIndex) {
        setState(() {
          if (coreInfo.readOnly) return;
          final page = coreInfo.pages.removeAt(pageIndex);
          if (coreInfo.pages.isEmpty) {
            coreInfo.pages.add(EditorPage());
          }
          history.recordChange(
            EditorHistoryItem(
              type: EditorHistoryItemType.deletePage,
              pageIndex: pageIndex,
              strokes: const [],
              images: const [],
              page: page,
            ),
          );
          autosaveAfterDelay();
        });
        final targetIndex = pageIndex < coreInfo.pages.length
            ? pageIndex
            : coreInfo.pages.length - 1;
        CanvasGestureDetector.scrollToPage(
          pageIndex: targetIndex,
          pages: coreInfo.pages,
          screenWidth: MediaQuery.sizeOf(context).width,
          transformationController: _transformationController,
        );
        if (pageIndex >= coreInfo.pages.length) {
          final state = _canvasGestureDetectorKey.currentState;
          if (state == null) return;
          final totalH = CanvasGestureDetector.getTopOfPage(
            pageIndex: coreInfo.pages.length,
            pages: coreInfo.pages,
            screenWidth: state.containerBounds.maxWidth,
          ) + 16;
          final targetY = state.containerBounds.maxHeight - totalH;
          final currentY = _transformationController.value.getTranslation().y;
          state.bypassTopClamping();
          _transformationController.value.leftTranslateByDouble(
            0, targetY - currentY, 0, 1,
          );
        }
      },
      scrollToPage: (pageIndex) => CanvasGestureDetector.scrollToPage(
        pageIndex: pageIndex,
        pages: coreInfo.pages,
        screenWidth: MediaQuery.sizeOf(context).width,
        transformationController: _transformationController,
      ),
      redrawAndSave: () => setState(() {
        if (coreInfo.readOnly) return;
        autosaveAfterDelay();
      }),
      pickPhotos: pickPhotos,
      importPdf: importPdf,
      canRasterPdf: Editor.canRasterPdf,
    );
  }

  Widget pageBuilder(BuildContext context, int pageIndex) {
    final page = coreInfo.pages[pageIndex];
    final currentStroke = Pen.currentStroke?.pageIndex == pageIndex
        ? Pen.currentStroke
        : null;
    return Canvas(
      path: coreInfo.filePath,
      page: page,
      pageIndex: pageIndex,
      coreInfo: coreInfo,
      currentStroke: currentStroke,
      currentStrokeDetectedShape: null,
      currentSelection: () {
        if (currentTool is! Select) return null;
        final selectResult = (currentTool as Select).selectResult;
        if (selectResult.pageIndex != pageIndex) return null;
        return selectResult;
      }(),
      setAsBackground: (image) {
        if (page.backgroundImage != null) {
          page.images.add(page.backgroundImage!);
        }
        page.images.remove(image);
        page.backgroundImage = image;

        CanvasImage.activeListener.notifyListenersPlease();

        autosaveAfterDelay();
        setState(() {});
      },
      currentTool: currentTool,
      currentScale: _transformationController.value.approxScale,
    );
  }

  @override
  void dispose() {
    unawaited(_cleanUpAsync());

    delayedSaveTimer?.cancel();
    lastSeenPointerCountTimer?.cancel();
    _transformationController.removeListener(_onTransformChanged);
    CanvasImage.activeImageNotifier.removeListener(_onActiveImageChanged);

    _removeKeybindings();

    stows.lastFountainPenOptions.notifyListeners();
    stows.lastBallpointPenOptions.notifyListeners();
    stows.lastHighlighterOptions.notifyListeners();
    stows.lastPencilOptions.notifyListeners();

    super.dispose();
  }

  Future<void> _cleanUpAsync() async {
    try {
      if (renameTimer?.isActive ?? false) {
        renameTimer!.cancel();
        await renameFileNow();
        filenameTextEditingController.dispose();
      }
      await saveToFile(force: true);
    } finally {
      coreInfo.dispose();
    }
  }
}
