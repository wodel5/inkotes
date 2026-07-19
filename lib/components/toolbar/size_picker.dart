import 'package:flutter/material.dart';
import 'package:foledge/data/tools/pen.dart';
import 'package:foledge/i18n/strings.g.dart';

class SizePicker extends StatefulWidget {
  const SizePicker({super.key, required this.axis, required this.pen});

  final Axis axis;
  final Pen pen;

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

    return Flex(
      direction: widget.axis,
      mainAxisSize: .min,
      children: [
        Text(
          '${t.editor.penOptions.size} ${_prettyNum(widget.pen.options.size)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 20,
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
              thumbShape: const _RingThumbShape(visualRadius: 7, strokeWidth: 5.5),
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
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape({required this.visualRadius, required this.strokeWidth});

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

    // 白色圆环
    canvas.drawCircle(
      center,
      drawRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }
}
