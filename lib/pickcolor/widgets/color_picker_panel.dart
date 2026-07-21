import 'package:flutter/material.dart';

import 'color_picker.dart';

/// Solid-color picker panel with a simple layout.
class ColorPickerPanel extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback? onColorChangeStart;
  final VoidCallback? onColorChangeEnd;
  final bool allowOpacity;
  final EdgeInsets? inputsPadding;
  final EdgeInsets? slidersPadding;
  final EdgeInsets? contentPadding;
  final double? paletteHeight;
  final bool readOnly;
  final double? maxWidth;
  final String? title;

  const ColorPickerPanel({
    super.key,
    this.color = Colors.white,
    required this.onColorChanged,
    this.onColorChangeStart,
    this.onColorChangeEnd,
    this.allowOpacity = true,
    this.inputsPadding,
    this.slidersPadding,
    this.contentPadding,
    this.paletteHeight,
    this.readOnly = false,
    this.maxWidth = 300.0,
    this.title,
  });

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final content = ColorPicker(
      color: widget.color,
      onColorChanged: widget.onColorChanged,
      onColorChangeStart: widget.onColorChangeStart,
      onColorChangeEnd: widget.onColorChangeEnd,
      allowOpacity: widget.allowOpacity,
      inputsPadding: widget.inputsPadding,
      slidersPadding: widget.slidersPadding,
      paletteHeight: widget.paletteHeight,
      readOnly: widget.readOnly,
      showToolbar: true,
    );

    Widget result = content;
    if (widget.maxWidth != null) {
      result = SizedBox(width: widget.maxWidth, child: result);
    }
    if (widget.contentPadding != null) {
      result = Padding(padding: widget.contentPadding!, child: result);
    }

    return result;
  }
}
