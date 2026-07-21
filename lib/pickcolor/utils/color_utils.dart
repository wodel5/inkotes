import 'package:flutter/material.dart';

/// Parses and normalizes a hex color string.
///
/// Supports multiple hex formats:
/// - `#RGB` or `RGB` (expands to `RRGGBB`)
/// - `#RRGGBB` or `RRGGBB`
/// - `#AARRGGBB` or `AARRGGBB` (when `withAlpha` is true)
///
/// The hash prefix is optional and will be removed. Short formats are
/// automatically expanded (e.g., `ABC` becomes `AABBCC`).
///
/// Returns a normalized uppercase hex string without the hash prefix.
///
/// Example:
/// ```dart
/// parseHex('#abc') // Returns 'AABBCC'
/// parseHex('FF0000') // Returns 'FF0000'
/// parseHex('#FF0000FF', withAlpha: true) // Returns 'FF0000FF'
/// ```
String parseHex(String hex, {bool withAlpha = false}) {
  if (hex.isEmpty) return '';
  
  // Remove hex prefix if present
  String textHolder = hex.startsWith('#') ? hex.substring(1) : hex;
  if (textHolder.isEmpty) return '';
  
  final int targetLength = withAlpha ? 8 : 6;
  
  // Handle short hex codes (2-char expands to 6, 3-char RGB expands to 6)
  if (textHolder.length == 2) {
    // Expand "FF" → "FFFFFF"
    textHolder = textHolder * 3;
  } else if (textHolder.length == 3) {
    // Expand "ABC" → "AABBCC" - optimized to avoid split/join
    final buffer = StringBuffer();
    for (int i = 0; i < textHolder.length; i++) {
      final char = textHolder[i];
      buffer.write(char);
      buffer.write(char);
    }
    textHolder = buffer.toString();
  }
  
  // Trim excess values
  if (textHolder.length > targetLength) {
    textHolder = textHolder.substring(0, targetLength);
  }
  
  // Pad missing values with zeros
  if (textHolder.length < targetLength) {
    textHolder = textHolder.padRight(targetLength, '0');
  }
  
  return textHolder.toUpperCase();
}

/// Converts a [Color] to a hex string representation.
///
/// The output format can be customized:
/// - `withAlpha`: Include alpha channel (8 characters) or omit it (6 characters)
/// - `withHashtag`: Include `#` prefix or omit it
///
/// Returns an uppercase hex string.
///
/// Example:
/// ```dart
/// colorToHex(Colors.red) // Returns 'FF0000'
/// colorToHex(Colors.red, withHashtag: true) // Returns '#FF0000'
/// colorToHex(Colors.red.withOpacity(0.5), withAlpha: true) // Returns '80FF0000'
/// ```
String colorToHex(
  Color color, {
  bool withAlpha = false,
  bool withHashtag = false,
}) {
  // Use component accessors (r, g, b, a are 0.0-1.0, convert to 0-255 integers)
  final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final a = ((color.a * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  return '${withHashtag ? '#' : ''}${withAlpha ? a : ''}$r$g$b'.toUpperCase();
}

/// Parses a hex string to a [Color] object.
///
/// Supports multiple hex formats:
/// - `#RGB` or `RGB` (expands to `RRGGBB`)
/// - `#RRGGBB` or `RRGGBB`
/// - `#AARRGGBB` or `AARRGGBB` (with alpha channel)
///
/// The hash prefix is optional. If the hex string is invalid or empty,
/// returns the `fallback` color (or `null` if no fallback is provided).
///
/// Example:
/// ```dart
/// hexToColor('#FF0000') // Returns Color(0xFFFF0000)
/// hexToColor('abc') // Returns Color(0xFFAABBCC)
/// hexToColor('invalid', fallback: Colors.black) // Returns Colors.black
/// ```
Color? hexToColor(String hex, {Color? fallback}) {
  if (hex.isEmpty) return fallback;
  
  String normalized = parseHex(hex, withAlpha: true);
  if (normalized.length < 8) {
    normalized = 'FF$normalized';
  }
  
  int? value = int.tryParse(normalized, radix: 16);
  if (value == null) return fallback;
  
  return Color(value);
}

/// Normalizes a hex string to a standard format.
///
/// This is a convenience wrapper around [parseHex] that normalizes the hex
/// string (uppercase, padding, etc.) without changing its meaning.
///
/// Example:
/// ```dart
/// normalizeHex('#abc') // Returns 'AABBCC'
/// normalizeHex('ff0000', withAlpha: true) // Returns 'FF0000'
/// ```
String normalizeHex(String hex, {bool withAlpha = false}) {
  return parseHex(hex, withAlpha: withAlpha);
}

/// Validates whether a string is a valid hex color format.
///
/// Checks that the string:
/// - Contains only valid hex digits (0-9, A-F, a-f)
/// - Has an acceptable length (2, 3, 6, or 8 characters when `withAlpha` is true)
/// - Optionally starts with `#` (which is ignored)
///
/// Returns `true` if the format is valid, `false` otherwise.
///
/// Example:
/// ```dart
/// isValidHex('#FF0000') // Returns true
/// isValidHex('abc') // Returns true
/// isValidHex('invalid') // Returns false
/// isValidHex('#FF0000FF', withAlpha: true) // Returns true
/// ```
bool isValidHex(String hex, {bool withAlpha = false}) {
  if (hex.isEmpty) return false;
  
  String textHolder = hex;
  if (textHolder.startsWith('#')) {
    textHolder = textHolder.substring(1);
  }
  
  // Check if all characters are valid hex digits
  if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(textHolder)) {
    return false;
  }
  
  int expectedLength = withAlpha ? 8 : 6;
  // Accept 2-char (short), 3-char (short RGB), 6-char (RGB), or 8-char (ARGB)
  return textHolder.length == 2 ||
      textHolder.length == 3 ||
      textHolder.length == expectedLength ||
      (withAlpha && textHolder.length == 8);
}

