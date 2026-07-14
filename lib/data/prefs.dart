import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:foledge/components/home/home_layout_button.dart';
import 'package:foledge/components/home/sort_button.dart';
import 'package:foledge/data/tools/highlighter.dart';
import 'package:foledge/data/tools/pen.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/tool_id.dart';
import 'package:stow/stow.dart';
import 'package:stow_codecs/stow_codecs.dart';
import 'package:stow_plain/stow_plain.dart';

enum LayoutSize {
  auto,
  phone,
  tablet;

  static const codec = EnumCodec(values);
}

/// If false, all stows are stuck at their default values.
var _isOnMainIsolate = false;

final stows = Stows();

class Stows {
  Stows() {}

  /// Call this before [runApp] to set [_isOnMainIsolate] to true.
  static void markAsOnMainIsolate() {
    _isOnMainIsolate = true;
  }

  final log = Logger('Stows');

  final appTheme = PlainStow(
    'appTheme',
    ThemeMode.system,
    codec: const EnumCodec(ThemeMode.values),
    volatile: !_isOnMainIsolate,
  );

  final layoutSize = PlainStow(
    'layoutSize',
    LayoutSize.auto,
    codec: LayoutSize.codec,
    volatile: !_isOnMainIsolate,
  );

  final editorFingerDrawing = PlainStow(
    'editorFingerDrawing',
    true,
    volatile: !_isOnMainIsolate,
  );
  final autoDisableFingerDrawingWhenStylusDetected = PlainStow(
    'autoDisableFingerDrawingWhenStylusDetected',
    true,
    volatile: !_isOnMainIsolate,
  );
  final autosaveDelay = PlainStow(
    'autosaveDelay',
    10000,
    volatile: !_isOnMainIsolate,
  );
  final shapeRecognitionDelay = PlainStow(
    'shapeRecognitionDelay',
    500,
    volatile: !_isOnMainIsolate,
  );
  final autoStraightenLines = PlainStow(
    'autoStraightenLines',
    true,
    volatile: !_isOnMainIsolate,
  );

  final printPageIndicators = PlainStow(
    'printPageIndicators',
    false,
    volatile: !_isOnMainIsolate,
  );

  final maxImageSize = PlainStow<double>(
    'maxImageSize',
    2000,
    volatile: !_isOnMainIsolate,
  );

  final autoClearWhiteboardOnExit = PlainStow(
    'autoClearWhiteboardOnExit',
    false,
    volatile: !_isOnMainIsolate,
  );

  final recentColorsChronological = PlainStow(
    'recentColorsChronological',
    <String>[],
    volatile: !_isOnMainIsolate,
  );
  final recentColorsPositioned = PlainStow(
    'recentColorsPositioned',
    <String>[],
    volatile: !_isOnMainIsolate,
  );
  final pinnedColors = PlainStow(
    'pinnedColors',
    <String>[],
    volatile: !_isOnMainIsolate,
  );

  final lastTool = PlainStow(
    'lastTool',
    ToolId.fountainPen,
    codec: ToolId.codec,
    volatile: !_isOnMainIsolate,
  );
  static StrokeOptions _strokeOptionsFromJson(Object json) =>
      StrokeOptions.fromJson(json as Map<String, dynamic>);
  final lastFountainPenOptions = PlainStow.json(
        'lastFountainPenProperties',
        Pen.fountainPenOptions,
        fromJson: _strokeOptionsFromJson,
        volatile: !_isOnMainIsolate,
      ),
      lastBallpointPenOptions = PlainStow.json(
        'lastBallpointPenProperties',
        Pen.ballpointPenOptions,
        fromJson: _strokeOptionsFromJson,
        volatile: !_isOnMainIsolate,
      ),
      lastHighlighterOptions = PlainStow.json(
        'lastHighlighterProperties',
        Pen.highlighterOptions,
        fromJson: _strokeOptionsFromJson,
        volatile: !_isOnMainIsolate,
      ),
      lastPencilOptions = PlainStow.json(
        'lastPencilProperties',
        Pen.pencilOptions,
        fromJson: _strokeOptionsFromJson,
        volatile: !_isOnMainIsolate,
      ),
      lastShapePenOptions = PlainStow.json(
        'lastShapePenProperties',
        Pen.shapePenOptions,
        fromJson: _strokeOptionsFromJson,
        volatile: !_isOnMainIsolate,
      );
  final lastFountainPenColor = PlainStow(
        'lastFountainPenColor',
        Colors.black.toARGB32(),
        volatile: !_isOnMainIsolate,
      ),
      lastBallpointPenColor = PlainStow(
        'lastBallpointPenColor',
        Colors.black.toARGB32(),
        volatile: !_isOnMainIsolate,
      ),
      lastHighlighterColor = PlainStow(
        'lastHighlighterColor',
        Colors.yellow.withAlpha(Highlighter.alpha).toARGB32(),
        volatile: !_isOnMainIsolate,
      ),
      lastPencilColor = PlainStow(
        'lastPencilColor',
        Colors.black.toARGB32(),
        volatile: !_isOnMainIsolate,
      ),
      lastShapePenColor = PlainStow(
        'lastShapePenColor',
        Colors.black.toARGB32(),
        volatile: !_isOnMainIsolate,
      );
  final lastBackgroundPattern = PlainStow(
    'lastBackgroundPattern',
    CanvasBackgroundPattern.none,
    codec: const EnumCodec(CanvasBackgroundPattern.values),
    volatile: !_isOnMainIsolate,
  );
  static const defaultLineHeight = 40;
  static const defaultLineThickness = 3;
  final lastLineHeight = PlainStow(
    'lastLineHeight',
    defaultLineHeight,
    volatile: !_isOnMainIsolate,
  );
  final lastLineThickness = PlainStow(
    'lastLineThickness',
    defaultLineThickness,
    volatile: !_isOnMainIsolate,
  );
  final lastZoomLock = PlainStow(
        'lastZoomLock',
        false,
        volatile: !_isOnMainIsolate,
      ),
      lastSingleFingerPanLock = PlainStow(
        'lastSingleFingerPanLock',
        false,
        volatile: !_isOnMainIsolate,
      ),
      lastAxisAlignedPanLock = PlainStow(
        'lastAxisAlignedPanLock',
        false,
        volatile: !_isOnMainIsolate,
      );

  final homeLayout = PlainStow(
    'homeLayout',
    HomeLayout.masonryGrid,
    codec: HomeLayout.codec,
    volatile: !_isOnMainIsolate,
  );
  final browseSortMetric = PlainStow(
    'browseSortMetric',
    SortMetric.nameAToZ,
    codec: SortMetric.codec,
    volatile: !_isOnMainIsolate,
  );
  final recentFiles = PlainStow(
    'recentFiles',
    <String>[],
    volatile: !_isOnMainIsolate,
  );

  final locale = PlainStow('locale', '', volatile: !_isOnMainIsolate);
}

/// An [Stow] that transforms the value of another [Stow].
class TransformedStow<T_in, T_out> extends Stow<dynamic, T_out, dynamic> {
  final Stow<dynamic, T_in, dynamic> parent;
  final T_out Function(T_in) transform;
  final T_in Function(T_out) reverseTransform;

  @override
  T_out get value => transform(parent.value);

  @override
  set value(T_out value) => parent.value = reverseTransform(value);

  TransformedStow(this.parent, this.transform, this.reverseTransform)
    : super(parent.key, transform(parent.defaultValue), volatile: true) {
    parent.addListener(notifyListeners);
  }

  @override
  Future<dynamic> protectedRead() async => null;

  @override
  Future<void> protectedWrite(dynamic value) async {}

  @override
  String toString() {
    return 'TransformedPref<$T_in, $T_out>(from ${parent.key}, $value)';
  }

  @override
  void dispose() {
    parent.removeListener(notifyListeners);
    super.dispose();
  }
}
