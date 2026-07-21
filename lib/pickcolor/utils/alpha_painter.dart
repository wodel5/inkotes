import 'package:flutter/material.dart';

/// Custom painter for rendering a checkerboard pattern to indicate transparency.
///
/// This painter is used to display a checkerboard background behind transparent
/// colors, making it easier to see the alpha channel. The pattern consists of
/// alternating squares of the specified color.
///
/// Example:
/// ```dart
/// CustomPaint(
///   painter: AlphaPainter(Colors.grey, 8.0),
///   child: YourWidget(),
/// )
/// ```
class AlphaPainter extends CustomPainter {
  /// Color of the checkerboard squares.
  final Color alphaColor;
  
  /// Size of each checkerboard square in logical pixels.
  final double alphaRectSize;

  /// Creates an alpha painter with the given color and square size.
  const AlphaPainter(this.alphaColor, this.alphaRectSize);

  /// Static method to paint an alpha checkerboard pattern directly on a canvas.
  /// 
  /// This is useful for painting checkerboard backgrounds behind transparent
  /// colors without creating a separate painter instance.
  ///
  /// Parameters:
  /// - [canvas]: The canvas to paint on
  /// - [rect]: The rectangle area to fill with the pattern
  /// - [color]: The color of the checkerboard squares
  /// - [size]: The size of each square
  /// - [initial]: Starting offset for the pattern (default: 0)
  /// - [layer]: Whether to use layer blend mode (default: false)
  static void paintAlpha(
    Canvas canvas,
    Rect rect,
    Color color,
    double size, [
    int initial = 0,
    bool layer = false,
  ]) {
    Paint paint = Paint()
      ..color = color
      ..blendMode = layer ? BlendMode.srcATop : BlendMode.srcOver;
    for (int i = initial; i * size < rect.width; i++) {
      for (int j = 0; j * size < rect.height; j++) {
        if (i % 2 != j % 2) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + i * size,
            rect.top + j * size,
            size,
            size,
          ),
          paint,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintAlpha(
        canvas,
        Rect.fromLTWH(0, 0, size.width, size.height),
        alphaColor,
        alphaRectSize,
        0,
        false,
      );

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

