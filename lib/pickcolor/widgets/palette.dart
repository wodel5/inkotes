import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Color channel enum for internal calculations.
enum _ColorChannel { red, green, blue }

/// Get sorted color channels by value (descending).
List<MapEntry<_ColorChannel, int>> _getSortedChannels(Color color) =>
    <MapEntry<_ColorChannel, int>>[
      MapEntry(_ColorChannel.red, (color.r * 255.0).round() & 0xff),
      MapEntry(_ColorChannel.green, (color.g * 255.0).round() & 0xff),
      MapEntry(_ColorChannel.blue, (color.b * 255.0).round() & 0xff),
    ]..sort((MapEntry<_ColorChannel, int> a, MapEntry<_ColorChannel, int> b) =>
        b.value.compareTo(a.value));

/// Callback for position changes with color.
typedef ColorPositionChanged<TPosition> = void Function(
  TPosition position,
  Color color,
);

/// 2D color palette widget for saturation and brightness selection.
///
/// This widget displays a two-dimensional color picker where:
/// - The X-axis represents saturation (left = desaturated, right = fully saturated)
/// - The Y-axis represents brightness (top = bright, bottom = dark)
/// - The base color (hue) is typically provided by a [RainbowSlider]
///
/// Users can interact by dragging or tapping to select a color position.
/// The widget provides callbacks for position changes and interaction events.
///
/// Example:
/// ```dart
/// Palette(
///   baseColor: Colors.blue,
///   position: Offset(0.5, 0.5),
///   onPositionChanged: (position, color) {
///     // Handle color selection
///   },
///   onPanStart: () {
///     // Handle interaction start
///   },
///   onPanEnd: (oldColor, newColor) {
///     // Handle interaction end
///   },
/// )
/// ```
class Palette extends StatefulWidget {
  /// Base color (hue) - typically from RainbowSlider.
  final Color baseColor;

  /// Current position on palette (0.0-1.0 for x and y).
  final Offset position;

  /// Called when position changes.
  final ColorPositionChanged<Offset> onPositionChanged;

  /// Called when interaction starts.
  final VoidCallback onPanStart;

  /// Called when interaction ends.
  final Function(Color, Color) onPanEnd;

  /// Size of the selection thumb.
  final double thumbSize;

  /// Read-only mode.
  final bool readOnly;

  /// Calculate position from color (static utility).
  /// Maps color to hue and saturation palette.
  static Offset getPosition(Color color) {
    List<MapEntry<_ColorChannel, int>> channels = _getSortedChannels(color);
    double brightness = channels[0].value / 0xff;
    if (brightness == 0) return const Offset(1, 1);
    double y = 1 - brightness;
    double x = channels[2].value / brightness / 0xff;
    return Offset(x, y);
  }

  /// Get selected palette color (static utility).
  /// Calculate selected color from [baseColor] and hue and saturation [position].
  static Color getColor(Color baseColor, Offset position) =>
      Color.lerp(
        Color.lerp(baseColor, Colors.white, position.dx),
        Colors.black,
        position.dy,
      ) ??
      Colors.white;

  const Palette({
    super.key,
    this.baseColor = Colors.white,
    this.position = Offset.zero,
    required this.onPanStart,
    required this.onPositionChanged,
    required this.onPanEnd,
    this.thumbSize = 20,
    this.readOnly = false,
  });

  @override
  State<Palette> createState() => _PaletteState();
}

class _PaletteState extends State<Palette> {
  /// A relative 0 - 1 selection position value.
  late Offset selectionPosition;

  /// Selected color computed from [Palette.getColor].
  late Color selectionColor;

  /// This is the color at pan start, which is used on pan end.
  Color? previousColor;

  @override
  void initState() {
    super.initState();
    initValues();
  }

  /// Initialize internal widget state values.
  void initValues() {
    selectionPosition = widget.position;
    selectionColor = Palette.getColor(widget.baseColor, widget.position);
  }

  @override
  void didUpdateWidget(Palette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.baseColor != oldWidget.baseColor ||
        (widget.position != oldWidget.position &&
            widget.position != selectionPosition)) {
      setState(initValues);
    }
  }

  /// Update [selectionPosition] from user selection [position].
  /// Map user selection [position] to a relative 0 - 1
  /// scale based on the selection area [width] and [height].
  void updatePosition(Offset position, double width, double height) {
    // Because selection position can exceed width and height
    // bounds, clamp output values.
    double x = ((width - position.dx) / width).clamp(0.0, 1.0);
    double y = (position.dy / height).clamp(0.0, 1.0);

    setState(() {
      selectionPosition = Offset(x, y);
      selectionColor = Palette.getColor(widget.baseColor, selectionPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        double thumbRadius = widget.thumbSize / 2;

        return GestureDetector(
          onTapDown: widget.readOnly
              ? null
              : (TapDownDetails details) {
                  previousColor = selectionColor;
                },
          onPanStart: widget.readOnly
              ? null
              : (DragStartDetails details) {
                  previousColor = selectionColor;
                  updatePosition(details.localPosition, width, height);
                  widget.onPanStart();
                },
          onPanUpdate: widget.readOnly
              ? null
              : (DragUpdateDetails details) {
                  updatePosition(details.localPosition, width, height);
                  // Notify position and color callback.
                  widget.onPositionChanged(selectionPosition, selectionColor);
                },
          onPanEnd: widget.readOnly
              ? null
              : (DragEndDetails details) {
                  widget.onPanEnd(previousColor ?? selectionColor, selectionColor);
                },
          onTapUp: widget.readOnly
              ? null
              : (TapUpDetails details) {
                  updatePosition(details.localPosition, width, height);
                  // Notify position and color callback.
                  widget.onPositionChanged(selectionPosition, selectionColor);
                  widget.onPanEnd(previousColor ?? selectionColor, selectionColor);
                },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: <Widget>[
              // Gradient square gets its own RepaintBoundary so thumb motion
              // doesn't invalidate the (expensive) gradient layer.
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _PalettePainter(widget.baseColor),
                    size: Size(width, height),
                  ),
                ),
              ),
              Positioned(
                left: width * (1 - selectionPosition.dx) - thumbRadius,
                top: (height * selectionPosition.dy) - thumbRadius,
                child: RepaintBoundary(
                  child: SizedBox(
                    width: widget.thumbSize,
                    height: widget.thumbSize,
                    child: CustomPaint(
                      painter: _ThumbPainter(color: selectionColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Paint palette gradient. Caches shaders per (color, size).
class _PalettePainter extends CustomPainter {
  _PalettePainter(this.color);

  final Color color;

  // Cache last-used shaders so rapid repaints at the same size skip shader
  // construction. Keyed by size (which rarely changes).
  static final Map<int, _PaletteShaderCache> _cache =
      <int, _PaletteShaderCache>{};

  _PaletteShaderCache _getShaders(Size size) {
    final int key = Object.hash(color.toARGB32(), size.width, size.height);
    final cached = _cache[key];
    if (cached != null) return cached;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final ui.Shader hueShader = ui.Gradient.linear(
      rect.topLeft,
      rect.topRight,
      <Color>[Colors.white, color],
    );
    final ui.Shader valueShader = ui.Gradient.linear(
      rect.bottomCenter,
      rect.topCenter,
      <Color>[Colors.black, Colors.black.withValues(alpha: 0.0)],
    );
    // Evict when cache grows unbounded.
    if (_cache.length > 16) _cache.clear();
    final entry = _PaletteShaderCache(hueShader, valueShader);
    _cache[key] = entry;
    return entry;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shaders = _getShaders(size);
    canvas.drawRect(rect, Paint()..shader = shaders.hue);
    canvas.drawRect(rect, Paint()..shader = shaders.value);
  }

  @override
  bool shouldRepaint(covariant _PalettePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PaletteShaderCache {
  final ui.Shader hue;
  final ui.Shader value;
  _PaletteShaderCache(this.hue, this.value);
}

/// Paint thumb indicator.
class _ThumbPainter extends CustomPainter {
  final Color color;

  _ThumbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = size.center(Offset.zero);
    // Solid white background to show behind transparent colors.
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    // Thumb color fill.
    canvas.drawCircle(center, radius, Paint()..color = color);
    // White border ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    // Outer shadow ring to lift the thumb off the gradient.
    canvas.drawCircle(
      center,
      radius + 1,
      Paint()
        ..color = Colors.black12
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter oldDelegate) =>
      oldDelegate.color != color;
}
