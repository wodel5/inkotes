import 'dart:io';
import 'dart:ui';

import 'package:collapsible/collapsible.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:keybinder/keybinder.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:foledge/components/theming/uni_icon.dart';
import 'package:foledge/components/toolbar/color_bar.dart';
import 'package:foledge/components/toolbar/export_bar.dart';
import 'package:foledge/components/toolbar/pen_modal.dart';
import 'package:foledge/components/toolbar/selection_bar.dart';
import 'package:foledge/components/toolbar/size_picker.dart';
import 'package:foledge/data/editor/page.dart';
import 'package:foledge/data/extensions/color_extensions.dart';
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
    required this.quillFocus,
    required this.textEditing,
    required this.toggleTextEditing,
    required this.undo,
    required this.isUndoPossible,
    required this.redo,
    required this.isRedoPossible,
    required this.pickPhoto,
    required this.paste,
    required this.duplicateSelection,
    required this.deleteSelection,
    required this.exportAsSba,
    required this.exportAsPdf,
    required this.exportAsPng,
  });

  final bool readOnly;

  final ValueChanged<Tool> setTool;
  final Tool currentTool;
  final ValueChanged<Color> setColor;

  final ValueNotifier<QuillStruct?> quillFocus;
  final bool textEditing;
  final VoidCallback toggleTextEditing;

  final VoidCallback undo;
  final bool isUndoPossible;
  final VoidCallback redo;
  final bool isRedoPossible;

  final VoidCallback pickPhoto;

  final VoidCallback paste;

  final VoidCallback duplicateSelection;
  final VoidCallback deleteSelection;

  final Future Function(BuildContext)? exportAsSba;
  final Future Function(BuildContext)? exportAsPdf;
  final Future Function(BuildContext)? exportAsPng;

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  ValueNotifier<bool> showExportOptions = ValueNotifier(false);
  ValueNotifier<bool> showColorOptions = ValueNotifier(false);
  ValueNotifier<ToolOptions> toolOptionsType = ValueNotifier(ToolOptions.hide);

  @override
  void initState() {
    _assignKeybindings();

    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    final brightness = Theme.brightnessOf(context);
    final invert = brightness == .dark;

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
      ValueListenableBuilder(
        valueListenable: showExportOptions,
        builder: (context, showExportOptions, child) {
          return Collapsible(
            axis: CollapsibleAxis.vertical,
            maintainState: true,
            collapsed: !showExportOptions,
            child: child!,
          );
        },
        child: ExportBar(
          axis: Axis.horizontal,
          toggleExportBar: toggleExportBar,
          exportAsSba: widget.exportAsSba,
          exportAsPdf: widget.exportAsPdf,
          exportAsPng: widget.exportAsPng,
        ),
      ),
      ValueListenableBuilder(
        valueListenable: toolOptionsType,
        builder: (context, toolOptionsType, _) {
          return Collapsible(
            axis: CollapsibleAxis.vertical,
            maintainState: true,
            collapsed: toolOptionsType == .hide,
            child: switch (toolOptionsType) {
              .hide => const SizedBox.square(dimension: SizePicker.smallLength),
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
            },
          );
        },
      ),
      ValueListenableBuilder(
        valueListenable: showColorOptions,
        builder: (context, showColorOptions, child) {
          return Collapsible(
            axis: CollapsibleAxis.vertical,
            maintainState: true,
            collapsed: !showColorOptions,
            child: child!,
          );
        },
        child: ColorBar(
          axis: Axis.horizontal,
          setColor: widget.setColor,
          currentColor: currentColor,
          invert: invert,
        ),
      ),
      ValueListenableBuilder(
        valueListenable: widget.quillFocus,
        builder: (context, quill, _) {
          final baseButtonStyle =
              IconButtonTheme.of(context).style ?? const ButtonStyle();

          final iconTheme = QuillIconTheme(
            iconButtonUnselectedData: IconButtonData(
              style: baseButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                foregroundColor: WidgetStateProperty.all(colorScheme.primary),
              ),
            ),
            iconButtonSelectedData: IconButtonData(
              style: baseButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
              ),
            ),
          );
          return Collapsible(
            axis: CollapsibleAxis.vertical,
            maintainState: false,
            collapsed: !widget.textEditing || quill == null,
            child: quill != null
                ? QuillSimpleToolbar(
                    controller: quill.controller,
                    config: QuillSimpleToolbarConfig(
                      axis: Axis.horizontal,
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          iconTheme: iconTheme,
                        ),
                      ),
                      // scrollable on Android and iOS
                      multiRowsDisplay: !Platform.isAndroid && !Platform.isIOS,
                      showUndo: false,
                      showRedo: false,
                      showFontSize: false,
                      showFontFamily: false,
                      showClearFormat: false,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF9999BB).withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
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
                          widget.setTool(Highlighter.currentHighlighter);
                        }
                      },
                      child: const FaIcon(Highlighter.highlighterIcon, size: 18),
                    ),
                    _DockButton(
                      selected: showColorOptions.value,
                      enabled: !widget.readOnly,
                      onPressed: toggleColorOptions,
                      child: currentColor == null
                          ? const FaIcon(FontAwesomeIcons.palette, size: 18)
                          : Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: currentColor.withInversion(invert).withValues(alpha: 1),
                                shape: .circle,
                                border: Border.all(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                    ),
                    _DockDivider(),
                    _DockButton(
                      selected: widget.currentTool == LaserPointer.currentLaserPointer,
                      enabled: true,
                      onPressed: () {
                        toolOptionsType.value = .hide;
                        widget.setTool(LaserPointer.currentLaserPointer);
                      },
                      child: const Icon(Symbols.stylus_laser_pointer),
                    ),
                    _DockButton(
                      selected: widget.currentTool is Select,
                      enabled: !widget.readOnly,
                      onPressed: () {
                        toolOptionsType.value = .hide;
                        widget.setTool(Select.currentSelect);
                      },
                      child: const FaIcon(FontAwesomeIcons.solidObjectGroup, size: 18),
                    ),
                    _DockButton(
                      selected: widget.currentTool is Eraser,
                      enabled: !widget.readOnly,
                      onPressed: toggleEraser,
                      child: const FaIcon(FontAwesomeIcons.eraser, size: 18),
                    ),
                    _DockDivider(),
                    _DockButton(
                      enabled: !widget.readOnly,
                      onPressed: widget.pickPhoto,
                      child: const FaIcon(FontAwesomeIcons.solidImage, size: 18),
                    ),
                    _DockButton(
                      selected: widget.textEditing,
                      enabled: !widget.readOnly,
                      onPressed: widget.toggleTextEditing,
                      child: const FaIcon(FontAwesomeIcons.t, size: 18),
                    ),
                    _DockDivider(),
                    _DockButton(
                      selected: stows.editorFingerDrawing.value,
                      enabled: !widget.readOnly,
                      onPressed: () {
                        stows.editorFingerDrawing.value = !stows.editorFingerDrawing.value;
                      },
                      child: const Icon(CupertinoIcons.hand_draw, size: 18),
                    ),
                    _DockDivider(),
                    _DockButton(
                      enabled: !widget.readOnly && widget.isUndoPossible,
                      onPressed: widget.undo,
                      child: Transform.scale(
                        scaleX: -1,
                        child: const FaIcon(FontAwesomeIcons.share, size: 18),
                      ),
                    ),
                    _DockButton(
                      enabled: !widget.readOnly && widget.isRedoPossible,
                      onPressed: widget.redo,
                      child: const FaIcon(FontAwesomeIcons.share, size: 18),
                    ),
                    _DockDivider(),
                    _DockButton(
                      selected: showExportOptions.value,
                      enabled: !widget.readOnly,
                      onPressed: toggleExportBar,
                      child: const FaIcon(FontAwesomeIcons.shareNodes, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];

    return Flex(
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.down,
      children: bars,
    );
  }

  @override
  void dispose() {
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
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final scale = _hovering ? 1.3 : 1.0;

    final iconColor = !widget.enabled
        ? colorScheme.onSurface.withValues(alpha: 0.3)
        : widget.selected
            ? colorScheme.primary
            : colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: IconTheme(
              data: IconThemeData(color: iconColor),
              child: widget.child,
            ),
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
