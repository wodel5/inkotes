import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/color_utils.dart';

/// Text input formatter that converts text to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Custom formatter for hex color input that handles pasted values with #.
class HexColorInputFormatter extends TextInputFormatter {
  final bool allowAlpha;

  HexColorInputFormatter({this.allowAlpha = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.toUpperCase();

    // Detect if this is a paste operation (significant text change)
    final isPaste =
        (newValue.text.length - oldValue.text.length).abs() > 1 ||
        newValue.selection.baseOffset == newValue.text.length;

    // Remove all # symbols first
    newText = newText.replaceAll('#', '');

    // Filter to only allow hex digits
    newText = newText.replaceAll(RegExp(r'[^A-F0-9]'), '');

    // Limit length based on alpha support
    final maxLength = allowAlpha ? 8 : 6;
    if (newText.length > maxLength) {
      newText = newText.substring(0, maxLength);
    }

    // Add # at the start if we have any hex digits
    if (newText.isNotEmpty) {
      newText = '#$newText';
    }

    // Calculate new selection position
    int newSelectionOffset;
    if (isPaste || newText.isEmpty) {
      // For paste operations or empty text, place cursor at end
      newSelectionOffset = newText.length;
    } else {
      // For normal typing, try to maintain cursor position
      final newTextWithoutHash = newText.replaceFirst(RegExp(r'^#'), '');
      final oldHashLength = oldValue.text.startsWith('#') ? 1 : 0;
      final newHashLength = newText.startsWith('#') ? 1 : 0;

      // Adjust selection based on text changes
      final oldSelection = newValue.selection.baseOffset;
      if (oldSelection <= oldHashLength) {
        // Cursor was at or before the hash
        newSelectionOffset = newHashLength;
      } else {
        // Cursor was in the hex digits
        final oldHexPosition = oldSelection - oldHashLength;
        final newHexPosition = oldHexPosition.clamp(
          0,
          newTextWithoutHash.length,
        );
        newSelectionOffset = newHashLength + newHexPosition;
      }
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

/// Hex color input field widget with format validation and auto-formatting.
///
/// This widget provides a text input field for entering colors in hexadecimal
/// format. It supports multiple hex formats:
/// - `#RGB` or `RGB` (expands to `RRGGBB`)
/// - `#RRGGBB` or `RRGGBB`
/// - `#AARRGGBB` or `AARRGGBB` (with alpha channel)
///
/// The input automatically formats the text (uppercase, adds hash prefix) and
/// validates the input. When a valid hex color is entered, it calls [onColorChanged].
///
/// Example:
/// ```dart
/// ColorHexInput(
///   color: Colors.blue,
///   onColorChanged: (color) {
///     // Handle color change
///   },
/// )
/// ```
class ColorHexInput extends StatefulWidget {
  /// Current color value.
  final Color color;

  /// Called when color changes from hex input.
  final ValueChanged<Color>? onColorChanged;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChanged;

  /// Read-only mode.
  final bool readOnly;

  /// Text style for input.
  final TextStyle? textStyle;

  /// Allow alpha channel in hex (#AARRGGBB).
  final bool allowAlpha;

  /// Show label above input.
  final bool showLabel;

  /// Show outline border (always visible, not just on focus).
  final bool showOutline;

  const ColorHexInput({
    super.key,
    this.color = Colors.white,
    this.onColorChanged,
    this.onFocusChanged,
    this.readOnly = false,
    this.textStyle,
    this.allowAlpha = false,
    this.showLabel = true,
    this.showOutline = true,
  });

  @override
  State<ColorHexInput> createState() => _ColorHexInputState();
}

class _ColorHexInputState extends State<ColorHexInput> {
  late TextEditingController textController = TextEditingController();
  late FocusNode focusNode = FocusNode();

  /// Internal color variable.
  late Color colorHolder;

  @override
  void initState() {
    super.initState();
    colorHolder = widget.color;
    textController = TextEditingController(
      text: colorToHex(
        widget.color,
        withHashtag: true,
        withAlpha: widget.allowAlpha,
      ),
    );
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        // Select input text minus hashtag.
        textController.selection = TextSelection(
          baseOffset: textController.text.startsWith('#') ? 1 : 0,
          extentOffset: textController.text.length,
        );
        widget.onFocusChanged?.call(true);
      } else {
        // When losing focus, parse the current text and update if valid
        final currentText = textController.text.trim();
        if (currentText.isNotEmpty) {
          // Parse hex respecting allowAlpha setting
          Color? newColor;
          String hexWithoutHash = currentText.replaceFirst(RegExp(r'^#'), '');

          if (widget.allowAlpha) {
            // With alpha: parse as ARGB (8 digits) or RGB (6 digits -> add FF prefix)
            newColor = hexToColor(currentText, fallback: null);
          } else {
            // Without alpha: parse as RGB only (6 digits or 3 digits), preserve existing alpha
            if (hexWithoutHash.isNotEmpty) {
              // Handle 3-digit hex expansion (e.g., "96F" -> "9966FF")
              String expandedHex = hexWithoutHash;
              if (hexWithoutHash.length == 3) {
                expandedHex = hexWithoutHash.split('').map((c) => c + c).join();
              }
              // Parse as RGB (6 digits max)
              if (expandedHex.length <= 6) {
                final normalized = parseHex(expandedHex, withAlpha: false);
                if (normalized.length == 6) {
                  final rgbValue = int.tryParse('FF$normalized', radix: 16);
                  if (rgbValue != null) {
                    newColor = Color(rgbValue).withValues(alpha: colorHolder.a);
                  }
                }
              }
            }
          }

          if (newColor != null && newColor != colorHolder) {
            colorHolder = newColor;
            widget.onColorChanged?.call(newColor);
          }
        }
        // Always normalize the display text to match the current color
        final normalizedText = colorToHex(
          colorHolder,
          withHashtag: true,
          withAlpha: widget.allowAlpha,
        );
        if (textController.text != normalizedText) {
          textController.text = normalizedText;
        }
        widget.onFocusChanged?.call(false);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void updateColorHex(String text) {
    if (text.isEmpty) return;
    final color = hexToColor(text, fallback: colorHolder);
    if (color == null) return;

    if (widget.allowAlpha) {
      if (color != colorHolder) {
        colorHolder = color;
        widget.onColorChanged?.call(colorHolder);
      }
    } else {
      if (color.withValues(alpha: colorHolder.a) != colorHolder) {
        colorHolder = color.withValues(alpha: colorHolder.a);
        widget.onColorChanged?.call(colorHolder);
      }
    }
  }

  @override
  void didUpdateWidget(ColorHexInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color && widget.color != colorHolder) {
      setState(() => colorHolder = widget.color);
      textController.text = colorToHex(
        colorHolder,
        withHashtag: true,
        withAlpha: widget.allowAlpha,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Modern border colors following style guide
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    final focusBorderColor = colorScheme.primary;

    // Background colors for skeumorphic effect
    final backgroundColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 0,
        children: <Widget>[
          if (widget.showLabel)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Text(
                'Hex',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  height: 1.0,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: widget.showOutline || focusNode.hasFocus
                  ? backgroundColor
                  : null,
              border: Border.all(
                color: focusNode.hasFocus
                    ? focusBorderColor
                    : (widget.showOutline ? borderColor : Colors.transparent),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: widget.showOutline || focusNode.hasFocus
                  ? [
                      // Outer shadow for depth
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                      // Inner highlight for skeumorphic effect
                      if (!focusNode.hasFocus)
                        BoxShadow(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white.withValues(alpha: 0.5),
                          blurRadius: 1,
                          offset: const Offset(0, -1),
                        ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: SizedBox(
                width: widget.allowAlpha ? 98 : 76,
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  textAlign: TextAlign.left,
                  readOnly: widget.readOnly,
                  inputFormatters: <TextInputFormatter>[
                    HexColorInputFormatter(allowAlpha: widget.allowAlpha),
                  ],
                  style: (widget.textStyle ?? textTheme.bodyMedium)?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  cursorColor: colorScheme.primary,
                  cursorWidth: 1.5,
                  cursorRadius: const Radius.circular(1),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
