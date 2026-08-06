import 'package:flutter/material.dart';
import 'package:inkotes/data/tools/pen.dart';
import 'package:inkotes/i18n/strings.g.dart';

class SizePicker extends StatefulWidget {
  const SizePicker({super.key, required this.axis, required this.pen, this.onChanged});

  final Axis axis;
  final Pen pen;
  final VoidCallback? onChanged;

  @override
  State<SizePicker> createState() => _SizePickerState();

  static const double smallLength = 25;
  static const double largeLength = 180;
}

String _prettyNum(double num) {
  final rounded = num.round();
  if (num == rounded) return rounded.toString();
  return num.toStringAsFixed(1);
}

class _SizePickerState extends State<SizePicker> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: Flex(
        direction: widget.axis,
        mainAxisSize: .min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${t.editor.penOptions.size} ${_prettyNum(widget.pen.options.size)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: SizePicker.largeLength,
            child: SliderTheme(
            data: SliderThemeData(
              trackShape: const RoundedRectSliderTrackShape(),
              trackHeight: 18,
              overlayShape: SliderComponentShape.noOverlay,
              inactiveTrackColor: brightness == Brightness.light
                  ? const Color(0xFF9999BB).withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              activeTrackColor: brightness == Brightness.dark
                  ? const Color(0xFF44495F)
                  : null,
              thumbShape: const RingThumbShape(visualRadius: 7, strokeWidth: 5.5),
              thumbColor: brightness == Brightness.dark
                  ? const Color(0xFFE3E2E9)
                  : Colors.white,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: Slider(
              value: widget.pen.options.size,
              min: widget.pen.sizeMin,
              max: widget.pen.sizeMax,
              divisions: widget.pen.sizeStepsBetweenMinAndMax,
              onChanged: (value) {
                setState(() {
                  widget.pen.options.size = value;
                });
                widget.onChanged?.call();
              },
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class RingThumbShape extends SliderComponentShape {
  const RingThumbShape({required this.visualRadius, required this.strokeWidth});

  final double visualRadius;
  final double strokeWidth;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(visualRadius);
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
    TextDirection? textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final drawRadius = visualRadius - strokeWidth / 2;

    // 圆环颜色
    final thumbColor = sliderTheme.thumbColor ?? Colors.white;

    canvas.drawCircle(
      center,
      drawRadius,
      Paint()
        ..color = thumbColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }
}

/// Smaller tick mark dots for sliders that keep divisions visible but less obtrusive.
class SmallTickMarkShape extends SliderTickMarkShape {
  const SmallTickMarkShape();

  @override
  Size getPreferredSize({required bool isEnabled, required SliderThemeData sliderTheme}) {
    return const Size(4, 4);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required bool isEnabled,
    required TextDirection textDirection,
  }) {
    final paint = Paint()..color = sliderTheme.activeTickMarkColor ?? Colors.black;
    context.canvas.drawCircle(center, 2, paint);
  }
}
