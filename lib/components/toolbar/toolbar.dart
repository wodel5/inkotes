import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:keybinder/keybinder.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:inkotes/components/canvas/canvas_image.dart';
import 'package:inkotes/components/common/dock_button.dart';
import 'package:inkotes/components/common/glassmorphism_dock.dart';
import 'package:inkotes/components/theming/uni_icon.dart';
import 'package:inkotes/components/toolbar/color_bar.dart';
import 'package:inkotes/components/toolbar/export_bar.dart';
import 'package:inkotes/components/toolbar/pen_modal.dart';
import 'package:inkotes/components/toolbar/selection_bar.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/tools/tool.dart';
import 'package:inkotes/data/tools/eraser.dart';
import 'package:inkotes/data/tools/highlighter.dart';
import 'package:inkotes/data/tools/laser_pointer.dart';
import 'package:inkotes/data/tools/pen.dart';
import 'package:inkotes/data/tools/pencil.dart';
import 'package:inkotes/data/tools/select.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({
    super.key,
    required this.readOnly,
    required this.setTool,
    required this.currentTool,
    required this.setColor,
    required this.undo,
    required this.isUndoPossible,
    required this.redo,
    required this.isRedoPossible,
    required this.pickPhoto,
    required this.importPdf,
    required this.canRasterPdf,
    required this.paste,
    required this.duplicateSelection,
    required this.deleteSelection,
    this.onDuplicateActiveImage,
    this.onDeleteActiveImage,
    required this.exportAsFle,
    required this.exportAsPdf,
    required this.exportAsPng,
    this.collapsePanels,
  });

  final bool readOnly;

  final ValueChanged<Tool> setTool;
  final Tool currentTool;
  final ValueChanged<Color> setColor;

  final VoidCallback undo;
  final bool isUndoPossible;
  final VoidCallback redo;
  final bool isRedoPossible;

  final VoidCallback pickPhoto;
  final Future<bool> Function() importPdf;
  final bool canRasterPdf;

  final VoidCallback paste;

  final VoidCallback duplicateSelection;
  final VoidCallback deleteSelection;

  /// Callbacks for when an image is tap-activated (rather than Select-tool selection).
  final VoidCallback? onDuplicateActiveImage;
  final VoidCallback? onDeleteActiveImage;

  final Future Function(BuildContext)? exportAsFle;
  final Future Function(BuildContext)? exportAsPdf;
  final Future Function(BuildContext)? exportAsPng;
  final VoidCallback? collapsePanels;

  @override
  State<Toolbar> createState() => ToolbarState();
}

class ToolbarState extends State<Toolbar> {
  ValueNotifier<bool> showExportOptions = ValueNotifier(false);
  ValueNotifier<bool> showColorOptions = ValueNotifier(false);
  ValueNotifier<ToolOptions> toolOptionsType = ValueNotifier(ToolOptions.hide);
  Timer? _autoCollapseTimer;

  void _startAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) collapseAll();
    });
  }

  void _resetAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _startAutoCollapseTimer();
  }

  bool get _hasActivePanel =>
      showExportOptions.value ||
      showColorOptions.value ||
      toolOptionsType.value != ToolOptions.hide;

  @override
  void initState() {
    _assignKeybindings();
    stows.editorFingerDrawing.addListener(_onFingerDrawingChanged);
    showExportOptions.addListener(_onPanelChanged);
    showColorOptions.addListener(_onPanelChanged);
    toolOptionsType.addListener(_onPanelChanged);
    CanvasImage.activeImageNotifier.addListener(_onActiveImageChanged);

    super.initState();
  }

  void _onActiveImageChanged() {
    if (!mounted) return;
    // Defer setState to avoid calling it during build when a CanvasImage
    // initializes its active state (e.g. new image insertion).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onPanelChanged() {
    if (_hasActivePanel) {
      _startAutoCollapseTimer();
    } else {
      _autoCollapseTimer?.cancel();
    }
  }

  void _onFingerDrawingChanged() {
    if (mounted) setState(() {});
  }

  Keybinding? _ctrlF;
  Keybinding? _ctrlE;
  Keybinding? _ctrlC;
  Keybinding? _ctrlShiftS;
  Keybinding? _ctrlV;
  void _assignKeybindings() {
    _ctrlF = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyF),
    ], inclusive: true);
    _ctrlE = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyE),
    ], inclusive: true);
    _ctrlC = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyC),
    ], inclusive: true);
    _ctrlShiftS = Keybinding([
      KeyCode.ctrl,
      KeyCode.shift,
      KeyCode.from(LogicalKeyboardKey.keyS),
    ], inclusive: true);
    _ctrlV = Keybinding([
      KeyCode.ctrl,
      KeyCode.from(LogicalKeyboardKey.keyV),
    ], inclusive: true);

    Keybinder.bind(_ctrlE!, toggleEraser);
    Keybinder.bind(_ctrlC!, toggleColorOptions);
    Keybinder.bind(_ctrlShiftS!, toggleExportBar);
    Keybinder.bind(_ctrlV!, widget.paste);
  }

  void _removeKeybindings() {
    if (_ctrlF != null) Keybinder.remove(_ctrlF!);
    if (_ctrlE != null) Keybinder.remove(_ctrlE!);
    if (_ctrlC != null) Keybinder.remove(_ctrlC!);
    if (_ctrlShiftS != null) Keybinder.remove(_ctrlShiftS!);
    if (_ctrlV != null) Keybinder.remove(_ctrlV!);
  }

  void toggleEraser() {
    toolOptionsType.value = .hide;
    widget.setTool(Eraser()); // this toggles eraser
  }

  void toggleColorOptions() {
    showColorOptions.value = !showColorOptions.value;
  }

  void toggleExportBar() {
    showExportOptions.value = !showExportOptions.value;
  }

  void collapseAll() {
    _autoCollapseTimer?.cancel();
    showExportOptions.value = false;
    showColorOptions.value = false;
    toolOptionsType.value = ToolOptions.hide;
  }

  /// Shows the selection bar (called after a circle-select is completed).
  void showSelectPanel() {
    _autoCollapseTimer?.cancel();
    showExportOptions.value = false;
    showColorOptions.value = false;
    if (toolOptionsType.value != ToolOptions.select) {
      toolOptionsType.value = ToolOptions.select;
    }
  }

  void resetAutoCollapseTimer() {
    _resetAutoCollapseTimer();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = switch (widget.currentTool) {
      final Pen pen => pen.color,
      final Select select => select.getDominantStrokeColor(),
      _ => null,
    };

    if (CanvasImage.activeImageNotifier.value != null) {
      // Show selection bar when an image is tap-activated
      toolOptionsType.value = .select;
    } else if (toolOptionsType.value == ToolOptions.select &&
        !(widget.currentTool == Select.currentSelect &&
            Select.currentSelect.doneSelecting)) {
      // Panel was shown but no longer has a reason (no active image, no Select selection)
      toolOptionsType.value = .hide;
    }

    final bars = <Widget>[
      Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: GlassmorphismDock(
            child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    ValueListenableBuilder(
                      valueListenable: showExportOptions,
                      builder: (context, showExportOptions, _) {
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          child: showExportOptions
                              ? SizedBox(
                                  height: 40,
                                  child: ExportBar(
                                    axis: Axis.horizontal,
                                    toggleExportBar: toggleExportBar,
                                    exportAsFle: widget.exportAsFle,
                                    exportAsPdf: widget.exportAsPdf,
                                    exportAsPng: widget.exportAsPng,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: showColorOptions,
                      builder: (context, showColorOptions, _) {
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          child: showColorOptions
                              ? SizedBox(
                                  height: 40,
                                  child: ColorBar(
                                    axis: Axis.horizontal,
                                    setColor: widget.setColor,
                                    currentColor: currentColor,
                                    onInteraction: resetAutoCollapseTimer,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: toolOptionsType,
                      builder: (context, toolOptionsType, _) {
                        final isHidden = toolOptionsType == .hide;
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          child: isHidden
                              ? const SizedBox.shrink()
                              : SizedBox(
                                  height: 40,
                                  child: switch (toolOptionsType) {
                                      .pen => PenModal(
                                          getTool: () => Pen.currentPen,
                                          setTool: widget.setTool,
                                          onInteraction: resetAutoCollapseTimer,
                                        ),
                                      .highlighter => PenModal(
                                          getTool: () => Highlighter.currentHighlighter,
                                          setTool: widget.setTool,
                                          onInteraction: resetAutoCollapseTimer,
                                        ),
                                      .pencil => PenModal(
                                          getTool: () => Pencil.currentPencil,
                                          setTool: widget.setTool,
                                          onInteraction: resetAutoCollapseTimer,
                                        ),
                                      .select => SelectionBar(
                                          duplicateSelection: CanvasImage.activeImageNotifier.value != null
                                              ? widget.onDuplicateActiveImage ?? widget.duplicateSelection
                                              : widget.duplicateSelection,
                                          deleteSelection: CanvasImage.activeImageNotifier.value != null
                                              ? widget.onDeleteActiveImage ?? widget.deleteSelection
                                              : widget.deleteSelection,
                                        ),
                                      _ => const SizedBox.shrink(),
                                    },
                                ),
                        );
                      },
                    ),
                    _buildToolButtons(currentColor),
                    ],  // Column children
                    ),  // Column
          ),  // GlassmorphismDock
        ),  // Padding
      ),  // Center
    ];

    return Flex(
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.down,
      children: bars,
    );
  }

  Widget _buildToolButtons(Color? currentColor) {
    return IntrinsicWidth(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DockButton(
              selected: widget.currentTool == Pen.currentPen,
              enabled: !widget.readOnly,
              onPressed: () {
                if (widget.currentTool == Pen.currentPen) {
                  toolOptionsType.value = toolOptionsType.value == .pen
                      ? .hide
                      : .pen;
                } else {
                  toolOptionsType.value = .hide;
                  showColorOptions.value = false;
                  showExportOptions.value = false;
                  widget.setTool(Pen.currentPen);
                }
              },
              child: UniIcon(Pen.currentPen.icon, size: 20),
            ),
            DockButton(
              selected: widget.currentTool == Pencil.currentPencil,
              enabled: !widget.readOnly,
              onPressed: () {
                if (widget.currentTool == Pencil.currentPencil) {
                  toolOptionsType.value = toolOptionsType.value == .pencil
                      ? .hide
                      : .pencil;
                } else {
                  toolOptionsType.value = .hide;
                  showColorOptions.value = false;
                  showExportOptions.value = false;
                  widget.setTool(Pencil.currentPencil);
                }
              },
              child: const FaIcon(Pencil.pencilIcon, size: 20),
            ),
            DockButton(
              selected: widget.currentTool == Highlighter.currentHighlighter,
              enabled: !widget.readOnly,
              onPressed: () {
                if (widget.currentTool == Highlighter.currentHighlighter) {
                  toolOptionsType.value = toolOptionsType.value == .highlighter
                      ? .hide
                      : .highlighter;
                } else {
                  toolOptionsType.value = .hide;
                  showColorOptions.value = false;
                  showExportOptions.value = false;
                  widget.setTool(Highlighter.currentHighlighter);
                }
              },
              child: const FaIcon(Highlighter.highlighterIcon, size: 20),
            ),
            DockButton(
              enabled: !widget.readOnly && widget.currentTool is! LaserPointer && widget.currentTool is! Eraser,
              onPressed: toggleColorOptions,
              child: currentColor == null
                  ? const FaIcon(FontAwesomeIcons.palette, size: 20)
                  : FaIcon(FontAwesomeIcons.palette, size: 20, color: currentColor),
            ),
            _DockDivider(),
            DockButton(
              selected: widget.currentTool == LaserPointer.currentLaserPointer,
              enabled: true,
              onPressed: () {
                toolOptionsType.value = .hide;
                showColorOptions.value = false;
                showExportOptions.value = false;
                widget.setTool(LaserPointer.currentLaserPointer);
              },
              child: const Icon(Symbols.stylus_laser_pointer),
            ),
            DockButton(
              selected: widget.currentTool is Select,
              enabled: !widget.readOnly,
              onPressed: () {
                if (widget.currentTool == Select.currentSelect) {
                  if (toolOptionsType.value == .select) {
                    toolOptionsType.value = .hide;
                  } else if (Select.currentSelect.doneSelecting ||
                      CanvasImage.activeImageNotifier.value != null) {
                    toolOptionsType.value = .select;
                  }
                } else {
                  Select.currentSelect.unselect();
                  toolOptionsType.value = .hide;
                  showColorOptions.value = false;
                  showExportOptions.value = false;
                  widget.setTool(Select.currentSelect);
                }
              },
              child: const FaIcon(FontAwesomeIcons.solidObjectGroup, size: 20),
            ),
            DockButton(
              selected: widget.currentTool is Eraser,
              enabled: !widget.readOnly,
              onPressed: () {
                showColorOptions.value = false;
                showExportOptions.value = false;
                toggleEraser();
              },
              child: const FaIcon(FontAwesomeIcons.eraser, size: 20),
            ),
            _DockDivider(),
            DockButton(
              enabled: !widget.readOnly,
              onPressed: () {
                showColorOptions.value = false;
                showExportOptions.value = false;
                widget.pickPhoto();
              },
              child: const FaIcon(FontAwesomeIcons.solidImage, size: 20),
            ),
            if (widget.canRasterPdf)
              DockButton(
                enabled: !widget.readOnly,
                onPressed: () async {
                  showColorOptions.value = false;
                  showExportOptions.value = false;
                  await widget.importPdf();
                },
                child: const FaIcon(FontAwesomeIcons.solidFilePdf, size: 20),
              ),
            _DockDivider(),
            DockButton(
              selected: stows.editorFingerDrawing.value,
              enabled: !widget.readOnly,
              onPressed: () {
                showColorOptions.value = false;
                showExportOptions.value = false;
                stows.editorFingerDrawing.value = !stows.editorFingerDrawing.value;
              },
              child: Icon(const IconData(0xe7de, fontFamily: 'iconfont'), size: 20),
            ),
            _DockDivider(),
            DockButton(
              enabled: !widget.readOnly && widget.isUndoPossible,
              onPressed: () {
                showColorOptions.value = false;
                showExportOptions.value = false;
                widget.undo();
              },
              child: Transform.scale(
                scaleX: -1,
                child: const FaIcon(FontAwesomeIcons.share, size: 20),
              ),
            ),
            DockButton(
              enabled: !widget.readOnly && widget.isRedoPossible,
              onPressed: () {
                showColorOptions.value = false;
                showExportOptions.value = false;
                widget.redo();
              },
              child: const FaIcon(FontAwesomeIcons.share, size: 20),
            ),
            _DockDivider(),
            DockButton(
              enabled: !widget.readOnly,
              onPressed: () {
                showColorOptions.value = false;
                toggleExportBar();
              },
              child: const FaIcon(FontAwesomeIcons.shareNodes, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    showExportOptions.removeListener(_onPanelChanged);
    showColorOptions.removeListener(_onPanelChanged);
    toolOptionsType.removeListener(_onPanelChanged);
    CanvasImage.activeImageNotifier.removeListener(_onActiveImageChanged);
    stows.editorFingerDrawing.removeListener(_onFingerDrawingChanged);
    _removeKeybindings();
    super.dispose();
  }
}

enum ToolOptions { hide, pen, highlighter, pencil, select }

class _DockDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
