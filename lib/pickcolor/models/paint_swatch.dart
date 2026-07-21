import 'package:flutter/material.dart';

/// A solid color swatch for display in recent colors, presets, etc.
class PaintSwatch {
  final Color color;
  final String? label;

  const PaintSwatch(this.color, {this.label});

  factory PaintSwatch.fromColor(Color color, {String? label}) {
    return PaintSwatch(color, label: label);
  }

  PaintSwatch copyWith({Color? color, String? label}) {
    return PaintSwatch(color ?? this.color, label: label ?? this.label);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintSwatch &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          label == other.label;

  @override
  int get hashCode => Object.hash(color, label);

  @override
  String toString() {
    if (label != null) {
      return 'PaintSwatch(color: $color, label: "$label")';
    }
    return 'PaintSwatch(color: $color)';
  }
}
