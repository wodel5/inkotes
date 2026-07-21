import 'package:flutter/material.dart';

import 'color_picker_panel.dart';

/// Convenience function to show the solid-color picker in a dialog.
///
/// Returns the selected color, or null if cancelled.
Future<Color?> showColorPickerDialog({
  required BuildContext context,
  required Color initialColor,
  String title = 'Select Color',
  bool allowOpacity = true,
}) async {
  return showDialog<Color>(
    context: context,
    builder: (BuildContext context) => ColorPickerDialog(
      initialColor: initialColor,
      title: title,
      allowOpacity: allowOpacity,
    ),
  );
}

/// Dialog wrapper for the solid-color picker.
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;
  final bool allowOpacity;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.title = 'Select Color',
    this.allowOpacity = true,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: EdgeInsets.zero,
        ),
      ),
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 340,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ColorPickerPanel(
                  color: selectedColor,
                  onColorChanged: (Color color) {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  allowOpacity: widget.allowOpacity,
                  maxWidth: 340,
                ),
              ),
            ),
              // Dialog actions
              Container(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 0,
                  top: 4,
                  bottom: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: theme.textTheme.labelMedium,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: theme.textTheme.labelMedium,
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(selectedColor);
                      },
                      child: Text(MaterialLocalizations.of(context).okButtonLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
