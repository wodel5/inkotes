import 'package:flutter/material.dart';

import 'alpha_slider.dart';
import 'color_inputs.dart';
import 'gradient_alpha_input.dart';
import 'palette.dart';
import 'rainbow_slider.dart';

// Default horizontal padding for color picker components
const double _kDefaultHorizontalPadding = 12.0;

/// Main solid-color picker widget.
///
/// Provides:
/// - 2D color palette for saturation/brightness
/// - Rainbow/hue slider
/// - Alpha/opacity slider
/// - Hex color input
class ColorPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback? onColorChangeStart;
  final VoidCallback? onColorChangeEnd;
  final bool allowOpacity;
  final EdgeInsets? inputsPadding;
  final EdgeInsets? slidersPadding;
  final double? paletteHeight;
  final bool readOnly;
  final bool showToolbar;

  const ColorPicker({
    super.key,
    this.color = Colors.white,
    required this.onColorChanged,
    this.onColorChangeStart,
    this.onColorChangeEnd,
    this.allowOpacity = true,
    this.inputsPadding,
    this.slidersPadding,
    this.paletteHeight,
    this.readOnly = false,
    this.showToolbar = true,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color color;
  late double opacity;
  late Color rainbowColor;
  late double rainbowPosition;
  late Offset palettePosition;

  final FocusNode alphaFocusNode = FocusNode();
  final ValueNotifier<int> _dragTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    color = widget.color;
    opacity = widget.allowOpacity ? color.a : 1;
    palettePosition = Palette.getPosition(color);
    rainbowPosition = RainbowSlider.getPosition(color);
    rainbowColor = RainbowSlider.getColor(rainbowPosition);
  }

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (color != widget.color) {
      setState(() {
        color = widget.color;
        opacity = widget.allowOpacity ? widget.color.a : 1;
        palettePosition = Palette.getPosition(color);
        rainbowPosition = RainbowSlider.getPosition(color);
        rainbowColor = RainbowSlider.getColor(rainbowPosition);
      });
    }
  }

  @override
  void dispose() {
    alphaFocusNode.dispose();
    _dragTick.dispose();
    super.dispose();
  }

  void _tick() => _dragTick.value = _dragTick.value + 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Toolbar (hex/opacity inputs)
        if (widget.showToolbar)
          Padding(
            padding:
                widget.inputsPadding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: ColorHexInput(
                    color: color,
                    readOnly: widget.readOnly,
                    allowAlpha: false,
                    onColorChanged: (Color value) {
                      setState(() {
                        color = value.withValues(alpha: opacity);
                        rainbowPosition = RainbowSlider.getPosition(color);
                        rainbowColor = RainbowSlider.getColor(rainbowPosition);
                        palettePosition = Palette.getPosition(color);
                      });
                      widget.onColorChanged(color);
                      widget.onColorChangeEnd?.call();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                GradientAlphaInput(
                  focus: alphaFocusNode,
                  color: color,
                  readOnly: widget.readOnly || !widget.allowOpacity,
                  label: 'Opacity',
                  onValueUpdate: (Color value) =>
                      _commitColor(value, fireEnd: true),
                  onDragUpdate: (Color value) => _liveColor(value),
                  onDragEnd: widget.onColorChangeEnd,
                ),
              ],
            ),
          ),
        // Palette
        ClipRect(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 20,
              maxHeight: widget.paletteHeight ?? 200,
            ),
            child: SizedBox(
              height: widget.paletteHeight,
              child: TextFieldTapRegion(
                enabled: !widget.readOnly,
                child: ListenableBuilder(
                  listenable: _dragTick,
                  builder: (BuildContext context, Widget? _) {
                    return Palette(
                      readOnly: widget.readOnly,
                      baseColor: rainbowColor,
                      position: palettePosition,
                      thumbSize: 15,
                      onPanStart: widget.onColorChangeStart ?? () {},
                      onPositionChanged:
                          (Offset position, Color paletteColor) {
                            color = paletteColor.withValues(alpha: opacity);
                            palettePosition = position;
                            _tick();
                            widget.onColorChanged(color);
                          },
                      onPanEnd: (Color previousColor, Color updatedColor) {
                        widget.onColorChangeEnd?.call();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: widget.slidersPadding?.top ?? 12),
        // Rainbow slider
        Padding(
          padding: EdgeInsets.only(
            left: widget.slidersPadding?.left ?? _kDefaultHorizontalPadding,
            right: widget.slidersPadding?.right ?? _kDefaultHorizontalPadding,
          ),
          child: SizedBox(
            height: 15,
            child: ListenableBuilder(
              listenable: _dragTick,
              builder: (BuildContext context, Widget? _) {
                return RainbowSlider(
                  readOnly: widget.readOnly,
                  position: rainbowPosition,
                  trackHeight: 15,
                  onPanStart: (Color previousColor, Color updatedColor) {
                    widget.onColorChangeStart?.call();
                  },
                  onPositionChanged: (double position, Color rainbow) {
                    rainbowColor = rainbow;
                    rainbowPosition = position;
                    color = Palette.getColor(
                      rainbow,
                      palettePosition,
                    ).withValues(alpha: opacity);
                    _tick();
                    widget.onColorChanged(color);
                  },
                  onPanEnd: (Color previousColor, Color updatedColor) {
                    widget.onColorChangeEnd?.call();
                  },
                );
              },
            ),
          ),
        ),
        SizedBox(height: widget.slidersPadding?.bottom ?? 12),
        // Alpha slider
        Padding(
          padding: EdgeInsets.only(
            left: widget.slidersPadding?.left ?? _kDefaultHorizontalPadding,
            right: widget.slidersPadding?.right ?? _kDefaultHorizontalPadding,
          ),
          child: MouseRegion(
            cursor: widget.allowOpacity
                ? MouseCursor.defer
                : SystemMouseCursors.forbidden,
            child: SizedBox(
              height: 15,
              child: ListenableBuilder(
                listenable: _dragTick,
                builder: (BuildContext context, Widget? _) {
                  return AlphaSlider(
                    readOnly: widget.readOnly || !widget.allowOpacity,
                    color: color,
                    alpha: opacity,
                    trackHeight: 15,
                    onValueUpdate: (double value) {
                      opacity = value;
                      color = color.withValues(alpha: value);
                      _tick();
                      widget.onColorChanged(color);
                    },
                    onDragEnd: (double previous, double updated) {
                      widget.onColorChangeEnd?.call();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _liveColor(Color value) {
    color = value;
    opacity = color.a;
    rainbowPosition = RainbowSlider.getPosition(color);
    rainbowColor = RainbowSlider.getColor(rainbowPosition);
    palettePosition = Palette.getPosition(color);
    _tick();
    widget.onColorChanged(color);
  }

  void _commitColor(Color value, {bool fireEnd = false}) {
    setState(() {
      color = value;
      opacity = color.a;
      rainbowPosition = RainbowSlider.getPosition(color);
      rainbowColor = RainbowSlider.getColor(rainbowPosition);
      palettePosition = Palette.getPosition(color);
    });
    widget.onColorChanged(color);
    if (fireEnd) widget.onColorChangeEnd?.call();
  }
}
