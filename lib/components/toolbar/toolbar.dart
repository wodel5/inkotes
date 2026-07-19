import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:keybinder/keybinder.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:foledge/components/theming/uni_icon.dart';
import 'package:foledge/components/toolbar/color_bar.dart';
import 'package:foledge/components/toolbar/export_bar.dart';
import 'package:foledge/components/toolbar/pen_modal.dart';
import 'package:foledge/components/toolbar/selection_bar.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/data/tools/_tool.dart';
import 'package:foledge/data/tools/eraser.dart';
import 'package:foledge/data/tools/highlighter.dart';
import 'package:foledge/data/tools/laser_pointer.dart';
import 'package:foledge/data/tools/pen.dart';
import 'package:foledge/data/tools/pencil.dart';
import 'package:foledge/data/tools/select.dart';

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
    required this.exportAsSba,
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

  final Future Function(BuildContext)? exportAsSba;
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

  @override
  void initState() {
    _assignKeybindings();
    stows.editorFingerDrawing.addListener(_onFingerDrawingChanged);

    super.initState();
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
    showExportOptions.value = false;
    showColorOptions.value = false;
    toolOptionsType.value = ToolOptions.hide;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    final currentColor = switch (widget.currentTool) {
      final Pen pen => pen.color,
      final Select select => select.getDominantStrokeColor(),
      _ => null,
    };

    if (widget.currentTool == Select.currentSelect) {
      // Enable selection bar only when selection is done
      toolOptionsType.value = Select.currentSelect.doneSelecting
          ? .select
          : .hide;
    }

    final bars = <Widget>[
      Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF9999BB).withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: IntrinsicWidth(
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
                                  height: 50,
                                  child: ExportBar(
                                    axis: Axis.horizontal,
                                    toggleExportBar: toggleExportBar,
                                    exportAsSba: widget.exportAsSba,
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
                                  height: 50,
                                  child: ColorBar(
                                    axis: Axis.horizontal,
                                    setColor: widget.setColor,
                                    currentColor: currentColor,
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
                                  height: 50,
                                  child: switch (toolOptionsType) {
                                      .pen => PenModal(
                                          getTool: () => Pen.currentPen,
                                          setTool: widget.setTool,
                                        ),
                                      .highlighter => PenModal(
                                          getTool: () => Highlighter.currentHighlighter,
                                          setTool: widget.setTool,
                                        ),
                                      .pencil => PenModal(
                                          getTool: () => Pencil.currentPencil,
                                          setTool: widget.setTool,
                                        ),
                                      .select => SelectionBar(
                                          duplicateSelection: widget.duplicateSelection,
                                          deleteSelection: widget.deleteSelection,
                                        ),
                                      _ => const SizedBox.shrink(),
                                    },
                                ),
                        );
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    _DockButton(
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
                      child: UniIcon(Pen.currentPen.icon, size: 18),
                    ),
                    _DockButton(
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
                      child: const FaIcon(Pencil.pencilIcon, size: 18),
                    ),
                    _DockButton(
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
                      child: const FaIcon(Highlighter.highlighterIcon, size: 18),
                    ),
                    _DockButton(
                      enabled: !widget.readOnly && widget.currentTool is! LaserPointer && widget.currentTool is! Eraser,
                      onPressed: toggleColorOptions,
                      child: currentColor == null
                          ? const FaIcon(FontAwesomeIcons.palette, size: 18)
                          : FaIcon(FontAwesomeIcons.palette, size: 18, color: currentColor),
                    ),
                    _DockDivider(),
                    _DockButton(
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
                    _DockButton(
                      selected: widget.currentTool is Select,
                      enabled: !widget.readOnly,
                      onPressed: () {
                        toolOptionsType.value = .hide;
                        showColorOptions.value = false;
                        showExportOptions.value = false;
                        widget.setTool(Select.currentSelect);
                      },
                      child: const FaIcon(FontAwesomeIcons.solidObjectGroup, size: 18),
                    ),
                    _DockButton(
                      selected: widget.currentTool is Eraser,
                      enabled: !widget.readOnly,
                      onPressed: () {
                        showColorOptions.value = false;
                        showExportOptions.value = false;
                        toggleEraser();
                      },
                      child: const FaIcon(FontAwesomeIcons.eraser, size: 18),
                    ),
                    _DockDivider(),
                    _DockButton(
                      enabled: !widget.readOnly,
                      onPressed: () {
                        showColorOptions.value = false;
                        showExportOptions.value = false;
                        widget.pickPhoto();
                      },
                      child: const FaIcon(FontAwesomeIcons.solidImage, size: 18),
                    ),
                    if (widget.canRasterPdf)
                      _DockButton(
                        enabled: !widget.readOnly,
                        onPressed: () async {
                          showColorOptions.value = false;
                          showExportOptions.value = false;
                          await widget.importPdf();
                        },
                        child: const FaIcon(FontAwesomeIcons.solidFilePdf, size: 18),
                      ),
                    _DockDivider(),
                    _DockButton(
                      selected: stows.editorFingerDrawing.value,
                      enabled: !widget.readOnly,
                      onPressed: () {
                        showColorOptions.value = false;
                        showExportOptions.value = false;
                        stows.editorFingerDrawing.value = !stows.editorFingerDrawing.value;
                      },
                      child: Icon(const IconData(0xe7de, fontFamily: 'iconfont'), size: 18),
                    ),
                    _DockDivider(),
                    _DockButton(
                      enabled: !widget.readOnly && widget.isUndoPossible,
                      onPressed: () {
                        showColorOptions.value = false;
                        showExportOptions.value = false;
                        widget.undo();
                      },
                      child: Transform.scale(
                        scaleX: -1,
                        child: const FaIcon(FontAwesomeIcons.share, size: 18),
                      ),
                    ),
                    _DockButton(
                      enabled: !widget.readOnly && widget.isRedoPossible,
                      onPressed: () {
                        showColorOptions.value = false;
                        showExportOptions.value = false;
                        widget.redo();
                      },
                      child: const FaIcon(FontAwesomeIcons.share, size: 18),
                    ),
                    _DockDivider(),
                    _DockButton(
                      enabled: !widget.readOnly,
                      onPressed: () {
                        showColorOptions.value = false;
                        toggleExportBar();
                      },
                      child: const FaIcon(FontAwesomeIcons.shareNodes, size: 18),
                    ),
                  ],
                ),
                ],  // Column children
                ),  // Column
                ),  // IntrinsicWidth
              ),  // Container
            ),  // BackdropFilter
          ),  // ClipRRect
        ),  // Padding
      ),  // Center
    ];

    return Flex(
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.down,
      children: bars,
    );
  }

  @override
  void dispose() {
    stows.editorFingerDrawing.removeListener(_onFingerDrawingChanged);
    _removeKeybindings();
    super.dispose();
  }
}

enum ToolOptions { hide, pen, highlighter, pencil, select }

class _DockButton extends StatefulWidget {
  const _DockButton({
    required this.child,
    this.selected = false,
    this.enabled = true,
    this.onPressed,
  });

  final Widget child;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final brightness = Theme.of(context).brightness;

    final iconColor = !widget.enabled
        ? colorScheme.onSurface.withValues(alpha: 0.3)
        : widget.selected
            ? colorScheme.primary
            : colorScheme.onSurface;

    // 选中状态的背景色
    Color? backgroundColor;
    if (widget.selected) {
      backgroundColor = brightness == Brightness.light
          ? colorScheme.primary.withValues(alpha: 0.15)
          : colorScheme.primary.withValues(alpha: 0.25);
    } else if (_pressing) {
      backgroundColor = brightness == Brightness.light
          ? Colors.grey.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.1);
    }

    return GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressing = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressing = false) : null,
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: iconColor, size: 18),
              child: widget.child,
            ),
          ),
        ),
    );
  }
}

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
