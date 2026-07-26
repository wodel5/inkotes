import 'package:flutter/material.dart';

/// Color channel enum for internal calculations.
enum ColorChannel { red, green, blue }

/// Get sorted color channels by value (descending).
List<MapEntry<ColorChannel, int>> getSortedChannels(Color color) =>
    <MapEntry<ColorChannel, int>>[
      MapEntry(ColorChannel.red, (color.r * 255.0).round() & 0xff),
      MapEntry(ColorChannel.green, (color.g * 255.0).round() & 0xff),
      MapEntry(ColorChannel.blue, (color.b * 255.0).round() & 0xff),
    ]..sort((MapEntry<ColorChannel, int> a, MapEntry<ColorChannel, int> b) =>
        b.value.compareTo(a.value));
