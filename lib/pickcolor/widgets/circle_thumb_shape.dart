import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Circular thumb shape for sliders.
class CircleThumbShape extends SliderComponentShape {
  final double? thumbRadius;
  final Color? strokeColor;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? shadowColor;
  final Color? outlineColor;

  const CircleThumbShape({
    this.thumbRadius,
    this.strokeColor,
    this.strokeWidth = 2,
    this.backgroundColor,
    this.shadowColor,
    this.outlineColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius ?? 10);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    // Painting canvas.
    Canvas canvas = context.canvas;
    // Thumb radius. Default half of track height.
    final double radius = thumbRadius ?? (sliderTheme.trackHeight ?? 0) / 2;
    
    // Solid white background to show behind transparent colors.
    // This is intentionally white for proper transparency visualization.
    Paint backgroundPaint = Paint()
      ..color = backgroundColor ?? const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    
    // Thumb color.
    Paint fillPaint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    
    // Thumb outline.
    Paint borderPaint = Paint()
      ..color = strokeColor ?? const Color(0xFFFFFFFF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    // Thumb outline to emulate shadow.
    Paint outlinePaint = Paint()
      ..color = outlineColor ?? const Color(0x1F000000) // ~12% opacity black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Thumb shadow path.
    Path path = Path()
      ..addArc(
        Rect.fromCenter(
          center: center,
          width: 2 * radius,
          height: 2 * radius,
        ),
        0,
        2 * math.pi,
      );
    
    // Draw shadow using theme-aware shadow color
    final shadowColorValue = shadowColor ?? const Color(0x80000000); // ~50% opacity black
    canvas.drawShadow(path, shadowColorValue, 4, true);
    // Draw thumb background.
    canvas.drawCircle(center, radius, backgroundPaint);
    // Draw thumb color.
    canvas.drawCircle(center, radius, fillPaint);
    // Draw thumb outline.
    canvas.drawCircle(center, radius, borderPaint);
    // Draw thumb shadow outline.
    canvas.drawCircle(center, radius + 1, outlinePaint);
  }
}

