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
  static const double largeLength = 150;
}

String _prettyNum(double num) {
  final rounded = num.round();
  if (num == rounded) return rounded.toString();
  return num.toStringAsFixed(1);
}

class _SizePickerState extends State<SizePicker> {
  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: widget.axis,
      mainAxisSize: .min,
      children: [
        Column(
          children: [
            Text(
              t.editor.penOptions.size,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 10,
                height: 1,
              ),
            ),
            Text(
              _prettyNum(widget.pen.options.size),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: SizePicker.largeLength,
          child: SliderTheme(
            data: SliderThemeData(
              trackShape: const RoundedRectSliderTrackShape(),
              overlayShape: SliderComponentShape.noOverlay,
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
