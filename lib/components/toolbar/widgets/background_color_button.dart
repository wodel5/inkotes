import 'package:flutter/material.dart';
import 'package:foledge/components/canvas/inner_canvas.dart';

const backgroundColorPresets = [
  Color(0xFFFFFFFF),
  Color(0xFF272735),
  Color(0xFFFFFBF0),
  Color(0xFFF0FFF0),
  Color(0xFFF0F7FF),
];

class BackgroundColorButton extends StatelessWidget {
  const BackgroundColorButton({
    super.key,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Color? color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color ?? InnerCanvas.defaultBackgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 14,
                  color: color == null || (color!.computeLuminance() > 0.5)
                      ? colorScheme.primary
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
