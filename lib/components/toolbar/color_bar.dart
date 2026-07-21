import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foledge/components/toolbar/color_option.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:foledge/pickcolor/pickcolor.dart';

typedef NamedColor = ({String name, Color color});

class ColorBar extends StatefulWidget {
  const ColorBar({
    super.key,
    required this.axis,
    required this.setColor,
    required this.currentColor,
    this.onInteraction,
  });

  final Axis axis;
  final ValueChanged<Color> setColor;
  final Color? currentColor;
  final VoidCallback? onInteraction;

  static List<NamedColor> get colorPresets => normalColorOptions;
  static final List<NamedColor> normalColorOptions = [
    (name: t.editor.colors.black, color: Colors.black),
    (name: t.editor.colors.red, color: Colors.red),
    (name: t.editor.colors.orange, color: Colors.orange),
    (name: t.editor.colors.yellow, color: Colors.yellow),
    (name: t.editor.colors.green, color: Colors.green),
    (name: t.editor.colors.cyan, color: Colors.cyan),
    (name: t.editor.colors.blue, color: Colors.blue),
    (name: t.editor.colors.purple, color: Colors.purple),
    (name: t.editor.colors.pink, color: Colors.pink),
    (name: t.editor.colors.white, color: Colors.white),
  ];
  static final List<NamedColor> greyScaleColorOptions = [
    (name: t.editor.colors.black, color: Colors.black),
    (name: t.editor.colors.darkGrey, color: Colors.grey[800] ?? Colors.black54),
    (name: t.editor.colors.grey, color: Colors.grey),
    (
      name: t.editor.colors.lightGrey,
      color: Colors.grey[200] ?? Colors.black12,
    ),
    (name: t.editor.colors.white, color: Colors.white),
  ];
  static final List<NamedColor> _allColors = [
    ...normalColorOptions,
    ...greyScaleColorOptions,
  ];
  static String findColorName(Color searchColor) {
    for (final namedColor in _allColors) {
      if (namedColor.color == searchColor) {
        return namedColor.name;
      }
    }
    return describeColor(searchColor);
  }

  @visibleForTesting
  static String describeColor(Color color) {
    final hsl = HSLColor.fromColor(color);

    final String hueName;
    if (hsl.saturation < 0.1 || hsl.lightness < 0.05 || hsl.lightness > 0.95) {
      hueName = t.editor.colors.grey.toLowerCase();
    } else {
      hueName = switch (hsl.hue) {
        < 10 => t.editor.colors.red.toLowerCase(),
        < 35 => t.editor.colors.orange.toLowerCase(),
        < 70 => t.editor.colors.yellow.toLowerCase(),
        < 150 => t.editor.colors.green.toLowerCase(),
        < 200 => t.editor.colors.cyan.toLowerCase(),
        < 250 => t.editor.colors.blue.toLowerCase(),
        < 285 => t.editor.colors.purple.toLowerCase(),
        < 340 => t.editor.colors.pink.toLowerCase(),
        _ => t.editor.colors.red.toLowerCase(),
      };
    }

    final lightnessName = switch (hsl.lightness) {
      < 0.35 => t.editor.colors.dark,
      < 0.65 => null,
      _ => t.editor.colors.light,
    };

    if (lightnessName == null) {
      return t.editor.colors.customHue(h: hueName);
    } else {
      return t.editor.colors.customBrightnessHue(b: lightnessName, h: hueName);
    }
  }

  @override
  State<ColorBar> createState() => _ColorBarState();
}

class _ColorBarState extends State<ColorBar> {
  static var pickedColor = const Color.fromRGBO(255, 0, 0, 1);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    final children = <Widget>[
      const ColorOptionSeparatorIcon(icon: FontAwesomeIcons.clockRotateLeft),

      // recent colors
      for (final colorString in stows.recentColorsPositioned.value)
        ColorOption(
          isSelected:
              widget.currentColor?.withAlpha(255).toARGB32() ==
              int.parse(colorString),
          enabled: widget.currentColor != null,
          onTap: () {
            widget.setColor(Color(int.parse(colorString)));
            widget.onInteraction?.call();
          },
          tooltip: ColorBar.findColorName(Color(int.parse(colorString))),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(int.parse(colorString)),
              shape: .circle,
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
        ),
      // placeholders for recent colors
      for (int i = 0; i < 5 - stows.recentColorsPositioned.value.length; ++i)
        ColorOption(
          isSelected: false,
          enabled: widget.currentColor != null,
          onTap: null,
          tooltip: null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: .circle,
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
        ),

      // custom color
      ColorOption(
        isSelected:
            widget.currentColor?.withAlpha(255).toARGB32() ==
            pickedColor.toARGB32(),
        enabled: true,
        onTap: () => openColorPicker(context),
        tooltip: t.editor.colors.colorPicker,
        child: const DecoratedBox(
          decoration: BoxDecoration(color: Colors.transparent, shape: .circle),
          child: Center(
            child: FaIcon(FontAwesomeIcons.featherPointed, size: 16),
          ),
        ),
      ),

      // color presets
      for (final namedColor in ColorBar.colorPresets)
        ColorOption(
          isSelected:
              widget.currentColor?.withAlpha(255).toARGB32() ==
              namedColor.color.toARGB32(),
          enabled: widget.currentColor != null,
          onTap: () {
            widget.setColor(namedColor.color);
            widget.onInteraction?.call();
          },
          tooltip: namedColor.name,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: namedColor.color,
              shape: .circle,
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
        ),
    ];

    return Center(
      child: SingleChildScrollView(
        scrollDirection: widget.axis,
        child: Flex(direction: widget.axis, children: children),
      ),
    );
  }

  void openColorPicker(BuildContext context) async {
    final Color? newColor = await showColorPickerDialog(
      context: context,
      initialColor: pickedColor,
      title: t.settings.accentColorPicker.pickAColor,
      allowOpacity: true,
    );
    if (newColor != null) {
      pickedColor = newColor;
      widget.setColor(newColor);
    }
  }
}
