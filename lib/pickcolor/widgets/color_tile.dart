import 'package:flutter/material.dart';

import '../utils/color_utils.dart';
import 'checkerboard_painter.dart';

/// Individual color tile widget for displaying colors in grids.
class ColorTile extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;
  final bool isSelected;
  final double borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final bool showCheckerboard;

  const ColorTile({
    super.key,
    required this.color,
    this.onTap,
    this.size = 24,
    this.tooltip,
    this.isSelected = false,
    this.borderRadius = 6,
    this.borderWidth,
    this.borderColor,
    this.showCheckerboard = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasTransparency = color.a < 1.0;

    final checkerboardColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.15);
    final backgroundColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);

    final effectiveBorderRadius = BorderRadius.circular(borderRadius);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        color: color,
        border: Border.all(
          color: borderColor ??
              (isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.15)),
          width: borderWidth ?? (isSelected ? 2.5 : 1.5),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );

    if (showCheckerboard && hasTransparency) {
      content = SizedBox.square(
        dimension: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: CheckerboardPainter(
            effectiveBorderRadius.bottomLeft,
            color: checkerboardColor,
            backgroundColor: backgroundColor,
          ),
          child: content,
        ),
      );
    }

    return Tooltip(
      message: tooltip ?? colorToHex(color, withHashtag: true),
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
