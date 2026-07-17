import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Multiplies the color's HSL saturation by [saturationMultiplier].
  Color withSaturation(double saturationMultiplier) {
    final HSLColor hsl = HSLColor.fromColor(this);
    return hsl.withSaturation(hsl.saturation * saturationMultiplier).toColor();
  }
}
