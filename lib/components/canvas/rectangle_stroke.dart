import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:one_dollar_unistroke_recognizer/one_dollar_unistroke_recognizer.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:foledge/components/canvas/stroke.dart';
import 'package:foledge/data/models/has_size.dart';

class RectangleStroke extends Stroke {
  Rect rect;

  RectangleStroke({
    required super.color,
    required super.pressureEnabled,
    required super.options,
    required super.pageIndex,
    required super.page,
    required super.toolId,
    required this.rect,
  }) {
    options.isComplete = true;
  }

  factory RectangleStroke.fromJson(
    Map<String, dynamic> json, {
    required int fileVersion,
    required int pageIndex,
    required HasSize page,
  }) {
    assert(json['shp'] == 'rect');
    assert(json['pg'] == pageIndex || json['pg'] == null);

    final Color color;
    switch (json['col']) {
      case (final int value):
        color = Color(value);
      case (final Int64 value):
        color = Color(value.toInt());
      case null:
        color = Stroke.defaultColor;
      default:
        throw Exception(
          'Invalid color value: (${json['col'].runtimeType}) ${json['col']}',
        );
    }

    return RectangleStroke(
      color: color,
      pressureEnabled: json['prs'] ?? Stroke.defaultPressureEnabled,
      options: StrokeOptions.fromJson(json),
      pageIndex: pageIndex,
      page: page,
      toolId: .parsePenType(json['tool'], fallback: .shapePen),
      rect: .fromLTWH(
        json['rl'] ?? 0,
        json['rt'] ?? 0,
        json['rw'] ?? 0,
        json['rh'] ?? 0,
      ),
    );
  }
  @override
  Map<String, dynamic> toJson() {
    return {
      'shp': 'rect',
      'pg': pageIndex,
      'rl': rect.left,
      'rt': rect.top,
      'rw': rect.width,
      'rh': rect.height,
      'prs': pressureEnabled,
      'col': color.toARGB32(),
    }..addAll(options.toJson());
  }

  @override
  bool get isEmpty => rect.isEmpty;
  @override
  int get length => 100;

  /// A list of points that form the rectangle's perimeter.
  /// Each side has 24/N points.
  @override
  List<Offset> getPolygon({required StrokeQuality quality}) => [
    // left side
    for (int i = 0; i < 24 / quality.N; ++i)
      Offset(rect.left, rect.top + rect.height * i / 24),
    // bottom side
    for (int i = 0; i < 24 / quality.N; ++i)
      Offset(rect.left + rect.width * i / 24, rect.bottom),
    // right side
    for (int i = 0; i < 24 / quality.N; ++i)
      Offset(rect.right, rect.bottom - rect.height * i / 24),
    // top side
    for (int i = 0; i < 24 / quality.N; ++i)
      Offset(rect.right - rect.width * i / 24, rect.top),
  ];

  /// Returns a [Path] with four lines for each side of the rectangle.
  @override
  Path getPath(List<Offset> polygon, {bool smooth = true}) =>
      Path()..addRect(rect);

  @override
  @Deprecated('Cannot add points to a rectangle stroke.')
  void addPoint(Offset point, [double? pressure]) {
    throw UnsupportedError('Cannot add points to a rectangle stroke.');
  }

  @override
  @Deprecated('Cannot pop points from a rectangle stroke.')
  void popFirstPoint() {
    throw UnsupportedError('Cannot pop points from a rectangle stroke.');
  }

  @override
  void optimisePoints({double thresholdMultiplier = 0}) {
    // no-op
  }

  @override
  String toSvgPath() {
    return 'M${rect.left},${rect.top} '
        'L${rect.right},${rect.top} '
        'L${rect.right},${rect.bottom} '
        'L${rect.left},${rect.bottom} '
        'Z';
  }

  @override
  double get maxY {
    return rect.bottom;
  }

  @override
  void shift(Offset offset) {
    rect = rect.shift(offset);
    super.shift(offset);
  }

  @override
  @Deprecated('We already know the shape is a rectangle.')
  RecognizedUnistroke detectShape() {
    return RecognizedUnistroke(
      DefaultUnistrokeNames.rectangle,
      1,
      originalPoints: lowQualityPolygon,
      referenceUnistrokes: default$1Unistrokes,
    );
  }

  @override
  @Deprecated('We already know the shape is a rectangle.')
  bool isStraightLine([int minLength = 0]) => false;

  @override
  RectangleStroke copy() => RectangleStroke(
    color: color,
    pressureEnabled: pressureEnabled,
    options: options.copyWith(),
    pageIndex: pageIndex,
    page: page,
    toolId: toolId,
    rect: rect,
  );
}
