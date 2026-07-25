import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Multiplies the color's HSL saturation by [saturationMultiplier].
  Color withSaturation(double saturationMultiplier) {
    final HSLColor hsl = HSLColor.fromColor(this);
    return hsl.withSaturation(hsl.saturation * saturationMultiplier).toColor();
  }
}

extension ChangeNotifierExtensions on ChangeNotifier {
  /// This is a hack to allow us to call [notifyListeners]
  /// which is usually protected.
  void notifyListenersPlease() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifyListeners();
  }
}
