import 'package:flutter/material.dart';

import 'color_picker.dart';

/// Solid-color picker panel with a simple layout.
class ColorPickerPanel extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback? onColorChangeStart;
  final VoidCallback? onColorChangeEnd;
  final bool allowOpacity;
  final EdgeInsets? slidersPadding;
  final double? paletteHeight;
  final bool readOnly;
  final double? maxWidth;

  const ColorPickerPanel({
    super.key,
    this.color = Colors.white,
    required this.onColorChanged,
    this.onColorChangeStart,
    this.onColorChangeEnd,
    this.allowOpacity = true,
    this.slidersPadding,
    this.paletteHeight,
    this.readOnly = false,
    this.maxWidth = 300.0,
  });

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  @override
  Widget build(BuildContext context) {
    final content = ColorPicker(
      color: widget.color,
      onColorChanged: widget.onColorChanged,
      onColorChangeStart: widget.onColorChangeStart,
      onColorChangeEnd: widget.onColorChangeEnd,
      allowOpacity: widget.allowOpacity,
      slidersPadding: widget.slidersPadding,
      paletteHeight: widget.paletteHeight,
      readOnly: widget.readOnly,
    );

    Widget result = content;
    if (widget.maxWidth != null) {
      result = SizedBox(width: widget.maxWidth, child: result);
    }
    return result;
  }
}
