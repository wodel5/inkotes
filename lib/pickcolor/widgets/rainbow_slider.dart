import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'circle_thumb_shape.dart';
import 'palette.dart' show ColorPositionChanged;

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

/// Rainbow gradient colors for hue slider.
const LinearGradient _rainbow = LinearGradient(colors: <Color>[
  Color(0xFFFF0000),
  Color(0xFFFFFF00),
  Color(0xFF00FF00),
  Color(0xFF00FFFF),
  Color(0xFF0000FF),
  Color(0xFFFF00FF),
  Color(0xFFFF0000),
]);

/// Hue slider widget displaying the full color spectrum.
///
/// This widget provides a horizontal slider that displays a rainbow gradient
/// representing all hues. The position ranges from 0.0 to 6.0, where each
/// integer represents a color segment (red, yellow, green, cyan, blue, magenta).
///
/// The slider is typically used in conjunction with a [Palette] widget:
/// - [RainbowSlider] selects the hue (color family)
/// - [Palette] selects saturation and brightness within that hue
///
/// Example:
/// ```dart
/// RainbowSlider(
///   position: 2.0, // Green hue
///   onPositionChanged: (position, color) {
///     // Handle hue selection
///   },
///   onPanStart: (oldColor, newColor) {
///     // Handle interaction start
///   },
///   onPanEnd: (oldColor, newColor) {
///     // Handle interaction end
///   },
/// )
/// ```
class RainbowSlider extends StatefulWidget {
  /// Current position (0.0 to 6.0, representing hue).
  final double position;

  /// Height of the track.
  final double trackHeight;

  /// Custom thumb shape.
  final SliderComponentShape? thumbShape;

  /// Called when interaction starts.
  final Function(Color, Color) onPanStart;

  /// Called when position changes.
  final ColorPositionChanged<double> onPositionChanged;

  /// Called when interaction ends.
  final Function(Color, Color) onPanEnd;

  /// Read-only mode.
  final bool readOnly;

  /// Calculate position from color (static utility).
  static double getPosition(Color color) {
    List<MapEntry<_ColorChannel, int>> channels = _getSortedChannels(color);
    double c0 = channels[0].value.toDouble();
    double c1 = channels[1].value.toDouble();
    double c2 = channels[2].value.toDouble();
    if (c0 == c1 && c0 == c2) return 0.0;
    _ColorChannel second = channels[1].key;
    double coEfficient = (c1 - c2) / (c0 - c2);
    switch (channels[0].key) {
      case _ColorChannel.red: // red / purple
        return second == _ColorChannel.blue ? 6 - coEfficient : 0 + coEfficient;
      case _ColorChannel.green: // yellow / green
        return second == _ColorChannel.red ? 2 - coEfficient : 2 + coEfficient;
      case _ColorChannel.blue: // blue / purple
        return second == _ColorChannel.green
            ? 4 - coEfficient
            : 4 + coEfficient;
    }
  }

  /// Calculate color from position (static utility).
  static Color getColor(double position) {
    final List<Color> colors = _rainbow.colors;
    final double clamped = position.clamp(0.0, (colors.length - 1).toDouble());
    final int index = clamped.truncate();
    if (index >= colors.length - 1) return colors.last;
    final Color color = colors[index];
    final double coEfficient = clamped - index;
    return coEfficient < 0.00001
        ? color
        : (Color.lerp(color, colors[index + 1], coEfficient) ?? Colors.white);
  }

  const RainbowSlider({
    super.key,
    this.position = 0.0,
    this.trackHeight = 20,
    this.thumbShape,
    required this.onPanStart,
    required this.onPositionChanged,
    required this.onPanEnd,
    this.readOnly = false,
  });

  @override
  State<RainbowSlider> createState() => _RainbowSliderState();
}

class _RainbowSliderState extends State<RainbowSlider> {
  late double _position;
  late Color _color;
  Color? previousColor;

  // FocusNode must live across rebuilds — do NOT allocate in build().
  final FocusNode _focusNode = FocusNode(canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    _color = RainbowSlider.getColor(_position);
  }

  @override
  void didUpdateWidget(RainbowSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    double position = widget.position;
    if (position != oldWidget.position && position != _position) {
      _updatePosition(position);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updatePosition(double position) => setState(() {
        _position = position;
        _color = RainbowSlider.getColor(position);
      });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SliderTheme(
        data: SliderThemeData(
          trackShape: const _RainbowSliderTrackShape(),
          thumbShape: widget.thumbShape ?? const CircleThumbShape(),
          thumbColor: _color,
          trackHeight: widget.trackHeight,
          overlayColor: Colors.transparent,
        ),
        child: TextFieldTapRegion(
          enabled: !widget.readOnly,
          child: Slider(
            focusNode: _focusNode,
            value: _position,
            max: _rainbow.colors.length - 1.0,
            onChangeStart: widget.readOnly
                ? null
                : (double position) {
                    previousColor = _color;
                    widget.onPanStart(previousColor ?? _color, _color);
                  },
            onChanged: widget.readOnly
                ? null
                : (double position) {
                    _updatePosition(position);
                    widget.onPositionChanged(_position, _color);
                  },
            onChangeEnd: widget.readOnly
                ? null
                : (double position) {
                    widget.onPanEnd(previousColor ?? _color, _color);
                  },
          ),
        ),
      ),
    );
  }
}

/// Custom track shape for rainbow slider. Caches the shader per rect.
class _RainbowSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const _RainbowSliderTrackShape();

  /// Override size to eliminate side padding.
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    // Default thumb radius is half of the track height.
    double thumbRadius = (sliderTheme.trackHeight ?? 0) / 2;
    double trackHeight = sliderTheme.trackHeight ?? 0;
    // Offset track start by thumb radius to prevent overflow.
    double trackLeft = offset.dx + thumbRadius;
    // Track top position is the track height minus the top slider padding.
    double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    // Find track width offset by thumb size.
    double trackWidth = parentBox.size.width - thumbRadius * 2;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    Offset? secondaryOffset,
  }) {
    if ((sliderTheme.trackHeight ?? 0) <= 0) return;
    final Rect rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Default thumb radius is half of the track height.
    final double thumbRadius = rect.height / 2;
    // Thumb radius variable.
    final Radius radius = Radius.circular(thumbRadius);
    // Track painting area. Add thumb radius
    // to the slider width to cover the thumb ends.
    final RRect backgroundRRect = RRect.fromLTRBR(
      rect.left - thumbRadius,
      rect.top,
      rect.right + thumbRadius,
      rect.bottom,
      radius,
    );

    context.canvas.drawRRect(
      backgroundRRect,
      Paint()..shader = _getShader(rect),
    );
  }

  // Shader cache — a single track instance is `const`, so cache is process-wide.
  static final Map<int, ui.Shader> _shaderCache = <int, ui.Shader>{};

  ui.Shader _getShader(Rect rect) {
    final int key = Object.hash(
      rect.left,
      rect.top,
      rect.width,
      rect.height,
    );
    final cached = _shaderCache[key];
    if (cached != null) return cached;
    if (_shaderCache.length > 8) _shaderCache.clear();
    final colors = _rainbow.colors;
    final int last = colors.length - 1;
    final stops = <double>[
      for (int i = 0; i <= last; i++) i / last,
    ];
    final shader = ui.Gradient.linear(
      rect.centerLeft,
      rect.centerRight,
      colors,
      stops,
    );
    _shaderCache[key] = shader;
    return shader;
  }
}
