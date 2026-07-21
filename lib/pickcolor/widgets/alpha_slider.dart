import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'circle_thumb_shape.dart';

/// Color for alpha checkerboard squares (fallback when theme not available).
const Color alphaSquareColorFallback = Color(0xffE0E0E0);

/// Opacity slider widget with checkerboard pattern background.
///
/// This widget displays a horizontal slider for adjusting the alpha (opacity)
/// channel of a color. The slider shows a checkerboard pattern background to
/// make transparency visible, and displays a gradient from transparent to
/// opaque using the provided color.
///
/// The alpha value ranges from 0.0 (fully transparent) to 1.0 (fully opaque).
///
/// Example:
/// ```dart
/// AlphaSlider(
///   alpha: 0.5,
///   color: Colors.blue,
///   onValueUpdate: (alpha) {
///     // Handle opacity change during drag
///   },
///   onDragEnd: (oldAlpha, newAlpha) {
///     // Handle drag end
///   },
/// )
/// ```
class AlphaSlider extends StatefulWidget {
  /// Current alpha value (0.0 to 1.0).
  final double alpha;

  /// Color to show opacity for (RGB only, alpha is ignored).
  final Color color;

  /// Height of the track.
  final double trackHeight;

  /// Custom thumb shape.
  final SliderComponentShape? thumbShape;

  /// Called during drag.
  final ValueChanged<double> onValueUpdate;

  /// Called when drag ends.
  final Function(double, double) onDragEnd;

  /// Read-only mode.
  final bool readOnly;

  const AlphaSlider({
    super.key,
    this.alpha = 1.0,
    this.color = const Color(0xffff0000),
    this.trackHeight = 20,
    this.thumbShape,
    required this.onValueUpdate,
    required this.onDragEnd,
    this.readOnly = false,
  }) : assert(alpha >= 0.0 && alpha <= 1.0);

  @override
  State<AlphaSlider> createState() => _AlphaSliderState();
}

class _AlphaSliderState extends State<AlphaSlider> {
  late double alphaHolder;
  double? previousAlpha;

  final FocusNode _focusNode = FocusNode(canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    alphaHolder = widget.alpha;
  }

  @override
  void didUpdateWidget(AlphaSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Float imprecision tolerance — Color.a round-trips differ by ~1e-7.
    if (widget.alpha != oldWidget.alpha &&
        (widget.alpha - alphaHolder).abs() > 1e-4) {
      setState(() => alphaHolder = widget.alpha);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract pure RGB values, ignoring any alpha in the input color
    final int r = (widget.color.r * 255.0).round() & 0xff;
    final int g = (widget.color.g * 255.0).round() & 0xff;
    final int b = (widget.color.b * 255.0).round() & 0xff;

    // Create opaque version of the color for the gradient
    final Color opaqueColor = Color.fromARGB(255, r, g, b);

    // Thumb shows the color with current alpha
    final Color thumbColor = Color.fromARGB(
      (alphaHolder * 255).round(),
      r,
      g,
      b,
    );

    // Get theme colors for checkerboard and border
    final isDark = theme.brightness == Brightness.dark;
    // Use better contrast colors for checkerboard in both modes
    final checkerboardColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.15);
    final backgroundColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFFFFF);
    // Border: standard theme-aware values
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    return RepaintBoundary(
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: widget.trackHeight,
          trackShape: _AlphaSliderV2TrackShape(
            color: opaqueColor,
            checkerboardColor: checkerboardColor,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
          ),
          thumbShape: widget.thumbShape ?? const CircleThumbShape(),
          thumbColor: thumbColor,
          overlayColor: Colors.transparent,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
        ),
        child: TextFieldTapRegion(
          enabled: !widget.readOnly,
          child: Slider(
            focusNode: _focusNode,
            value: alphaHolder.clamp(0.0, 1.0),
            max: 1.0,
            onChangeStart: widget.readOnly
                ? null
                : (double position) {
                    previousAlpha = alphaHolder;
                  },
            onChanged: widget.readOnly
                ? null
                : (double position) {
                    setState(() => alphaHolder = position);
                    widget.onValueUpdate(position);
                  },
            onChangeEnd: widget.readOnly
                ? null
                : (double position) {
                    widget.onDragEnd(previousAlpha ?? alphaHolder, alphaHolder);
                  },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Cached checkerboard tile shader.
// =============================================================================
// Instead of issuing hundreds of drawRect calls per paint, we render a tiny
// 2-square checker tile into a ui.Image once per (color, size) and reuse it
// as a TileMode.repeated ImageShader.

class _CheckerboardTileCache {
  static final Map<int, ui.Image> _cache = <int, ui.Image>{};

  static ui.Image? get(Color color, double squareSize) {
    final int key = Object.hash(color.toARGB32(), squareSize);
    return _cache[key];
  }

  static Future<ui.Image> build(Color color, double squareSize) async {
    final int key = Object.hash(color.toARGB32(), squareSize);
    final existing = _cache[key];
    if (existing != null) return existing;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    final s = squareSize;
    // 2x2 pattern with two filled squares (top-left + bottom-right).
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), paint);
    canvas.drawRect(Rect.fromLTWH(s, s, s, s), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage((s * 2).ceil(), (s * 2).ceil());
    picture.dispose();
    if (_cache.length > 8) {
      for (final img in _cache.values) {
        img.dispose();
      }
      _cache.clear();
    }
    _cache[key] = image;
    return image;
  }
}

/// Custom track shape for alpha slider with checkerboard pattern.
class _AlphaSliderV2TrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  _AlphaSliderV2TrackShape({
    required this.color,
    required this.checkerboardColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  /// The opaque color to show (RGB only).
  final Color color;

  /// Color for checkerboard squares.
  final Color checkerboardColor;

  /// Background color for checkerboard.
  final Color backgroundColor;

  /// Color for border.
  final Color borderColor;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 20;
    final double thumbRadius = trackHeight / 2;

    final double trackLeft = offset.dx + thumbRadius;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - (thumbRadius * 2);

    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    Offset? secondaryOffset,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 20;
    if (trackHeight <= 0) return;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final double thumbRadius = trackHeight / 2;
    final Radius cornerRadius = Radius.circular(thumbRadius);
    final Canvas canvas = context.canvas;

    // Extended rect to cover thumb ends
    final RRect paintRect = RRect.fromLTRBR(
      trackRect.left - thumbRadius,
      trackRect.top,
      trackRect.right + thumbRadius,
      trackRect.bottom,
      cornerRadius,
    );
    final Rect outerRect = paintRect.outerRect;

    // Save canvas state
    canvas.save();
    // Clip to rounded rect
    canvas.clipRRect(paintRect);

    // Step 1: background.
    canvas.drawRRect(paintRect, Paint()..color = backgroundColor);

    // Step 2: checkerboard pattern via ImageShader (cached tile).
    final double squareSize = thumbRadius / 2.5;
    final ui.Image? tile =
        _CheckerboardTileCache.get(checkerboardColor, squareSize);
    if (tile != null) {
      final Paint checkerPaint = Paint()
        ..shader = ui.ImageShader(
          tile,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.translationValues(outerRect.left, outerRect.top, 0).storage,
        );
      canvas.drawRect(outerRect, checkerPaint);
    } else {
      // First paint: kick off async build + mark needs-paint next frame.
      _CheckerboardTileCache.build(checkerboardColor, squareSize).then((_) {
        parentBox.markNeedsPaint();
      });
      // Fallback: draw solid color at reduced alpha so we still see something.
      canvas.drawRect(outerRect, Paint()..color = checkerboardColor);
    }

    // Step 3: color gradient from transparent to opaque.
    final Shader gradient = ui.Gradient.linear(
      outerRect.centerLeft,
      outerRect.centerRight,
      <Color>[color.withValues(alpha: 0.0), color],
    );
    canvas.drawRect(outerRect, Paint()..shader = gradient);

    // Step 4: border.
    canvas.drawRRect(
      paintRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Restore canvas
    canvas.restore();
  }
}
