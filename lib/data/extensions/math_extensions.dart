import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:bson/bson.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:vector_math/vector_math_64.dart';

extension AxisExtensions on Axis {
  Axis get opposite => switch (this) {
    Axis.horizontal => Axis.vertical,
    Axis.vertical => Axis.horizontal,
  };
}

extension AxisDirectionExtensions on AxisDirection {
  Axis get axis => switch (this) {
    AxisDirection.up || AxisDirection.down => Axis.vertical,
    AxisDirection.left || AxisDirection.right => Axis.horizontal,
  };
}

extension Matrix4Extensions on Matrix4 {
  /// A fast approximation of the matrix's scale factor.
  double get approxScale => entry(0, 0);
}

extension PointExtensions on PointVector {
  @Deprecated(
    'Use fromBsonBinary instead; fromJson is only for backward compatibility',
  )
  static Point fromJson({
    required Map<String, dynamic> json,
    Offset offset = .zero,
  }) => Point(json['x'] + offset.dx, json['y'] + offset.dy, json['p']);

  static PointVector fromBsonBinary({
    required BsonBinary json,
    Offset offset = .zero,
  }) {
    final point = json.byteList.buffer.asFloat32List();
    return PointVector(
      point[0] + offset.dx,
      point[1] + offset.dy,
      point.length == 2 ? null : point[2],
    );
  }

  BsonBinary toBsonBinary() {
    final point = Float32List.fromList([x, y, ?pressure]);
    return BsonBinary.from(point.buffer.asUint8List());
  }

  PointVector operator +(Offset offset) =>
      PointVector(x + offset.dx, y + offset.dy, pressure);
}
