import 'package:flutter/material.dart';

/// Default size for checkerboard squares.
const double _defaultCheckerboardSize = 4.0;

/// Default color for checkerboard squares.
const Color _defaultCheckerboardColor = Color(0xFFD3D3D3);

/// Custom painter for checkerboard pattern behind transparent colors.
class CheckerboardPainter extends CustomPainter {
  /// Border radius for clipping.
  final Radius borderRadius;
  
  /// Color of the checkerboard squares.
  final Color? color;
  
  /// Size of each square.
  final double? size;
  
  /// Optional foreground color overlay.
  final Color? foregroundColor;
  
  /// Background color (default white for light, dark for dark mode).
  final Color? backgroundColor;

  const CheckerboardPainter(
    this.borderRadius, {
    this.color,
    this.size,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Rect rect = Offset.zero & canvasSize;

    if (borderRadius != Radius.zero) {
      canvas.clipRRect(RRect.fromRectAndRadius(rect, borderRadius));
    }

    // Draw background first if provided
    if (backgroundColor != null) {
      canvas.drawRect(rect, Paint()..color = backgroundColor!);
    }

    final paint = Paint()
      ..color = color ?? _defaultCheckerboardColor
      ..blendMode = BlendMode.srcOver;
    
    final rectSize = size ?? _defaultCheckerboardSize;
    final widthCount = (rect.width / rectSize).ceil();
    final heightCount = (rect.height / rectSize).ceil();
    
    // Optimize loop by pre-calculating bounds
    for (int i = 0; i < widthCount; i++) {
      for (int j = 0; j < heightCount; j++) {
        if (i % 2 != j % 2) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + i * rectSize,
            rect.top + j * rectSize,
            rectSize,
            rectSize,
          ),
          paint,
        );
      }
    }
    if (foregroundColor != null) {
      paint.color = foregroundColor!;
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CheckerboardPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CheckerboardPainter oldDelegate) => false;
}

