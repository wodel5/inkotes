import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PageActionButton extends StatefulWidget {
  const PageActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final Object icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<PageActionButton> createState() => _PageActionButtonState();
}

class _PageActionButtonState extends State<PageActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pressColor = brightness == Brightness.dark
        ? const Color(0xFFB2C5FF)
        : const Color(0xFF4A5E92);

    final usePressColor = _isPressed && widget.enabled;
    final colorScheme = ColorScheme.of(context);
    final iconColor = !widget.enabled
        ? colorScheme.onSurface.withValues(alpha: 0.3)
        : usePressColor
            ? pressColor
            : colorScheme.onSurface;
    final textColor = !widget.enabled
        ? colorScheme.onSurface.withValues(alpha: 0.3)
        : usePressColor
            ? pressColor
            : colorScheme.onSurface;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon is IconData)
                Icon(widget.icon as IconData, size: 20, color: iconColor)
              else
                FaIcon(widget.icon as FaIconData, size: 20, color: iconColor),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(fontSize: 12, color: textColor),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
