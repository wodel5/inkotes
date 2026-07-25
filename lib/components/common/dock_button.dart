import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 统一的 Dock 栏按钮，用于主页、回收站、编辑器工具栏。
///
/// 提供两种构造方式：
/// - `icon` (Object): 传入 IconData 或 FaIconData
/// - `child` (Widget): 传入任意 Widget
class DockButton extends StatefulWidget {
  const DockButton({
    super.key,
    this.icon,
    this.child,
    this.selected = false,
    this.enabled = true,
    this.onPressed,
  }) : assert(icon != null || child != null, '必须提供 icon 或 child');

  final Object? icon;
  final Widget? child;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<DockButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final brightness = Theme.of(context).brightness;

    final iconColor = !widget.enabled
        ? colorScheme.onSurface.withValues(alpha: 0.3)
        : widget.selected
            ? colorScheme.primary
            : colorScheme.onSurface;

    Color? backgroundColor;
    if (widget.selected) {
      backgroundColor = brightness == Brightness.light
          ? colorScheme.primary.withValues(alpha: 0.15)
          : colorScheme.primary.withValues(alpha: 0.25);
    } else if (_pressing && widget.enabled) {
      backgroundColor = brightness == Brightness.light
          ? Colors.grey.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.1);
    }

    final effectiveChild = widget.child ?? _buildIconFromObject(widget.icon!);

    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) => setState(() => _pressing = true)
          : null,
      onTapUp: widget.enabled
          ? (_) => setState(() => _pressing = false)
          : null,
      onTapCancel: () => setState(() => _pressing = false),
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: iconColor, size: 20),
            child: effectiveChild,
          ),
        ),
      ),
    );
  }

  Widget _buildIconFromObject(Object icon) {
    if (icon is IconData) return Icon(icon);
    if (icon is FaIconData) return FaIcon(icon);
    return const SizedBox.shrink();
  }
}
