import 'package:flutter/material.dart';

/// Alpha/opacity input widget with drag support.
class GradientAlphaInput extends StatefulWidget {
  final Color color;
  final ValueChanged<Color>? onValueUpdate;
  final ValueChanged<Color>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final bool readOnly;
  final String label;
  final FocusNode? focus;

  const GradientAlphaInput({
    super.key,
    required this.color,
    this.onValueUpdate,
    this.onDragUpdate,
    this.onDragEnd,
    this.readOnly = false,
    this.label = 'Opacity',
    this.focus,
  });

  @override
  State<GradientAlphaInput> createState() => _GradientAlphaInputState();
}

class _GradientAlphaInputState extends State<GradientAlphaInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isDragging = false;
  double _dragStartValue = 0.0;
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focus ?? FocusNode();
    final opacityPercent = (widget.color.a * 100).round();
    _controller = TextEditingController(text: '$opacityPercent%');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(GradientAlphaInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focus != oldWidget.focus) {
      oldWidget.focus?.removeListener(_onFocusChange);
      if (oldWidget.focus == null) _focusNode.dispose();
      _focusNode = widget.focus ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
    if (widget.color.a != oldWidget.color.a &&
        !_focusNode.hasFocus &&
        !_isDragging) {
      final int newPercent = (widget.color.a * 100).round();
      final String currentText = _controller.text;
      final int? currentPercent =
          int.tryParse(currentText.replaceAll('%', '').trim());
      if (currentPercent != newPercent) {
        _controller.text = '$newPercent%';
      }
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      final textWithoutPercent = _controller.text.replaceAll('%', '');
      _controller.text = textWithoutPercent;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: textWithoutPercent.length,
      );
    } else if (!_isDragging) {
      final text = _controller.text.trim().replaceAll('%', '');
      if (text.isEmpty) {
        final opacityPercent = (widget.color.a * 100).round();
        _controller.text = '$opacityPercent%';
        return;
      }
      final numValue = num.tryParse(text);
      if (numValue != null) {
        final clampedValue = numValue.clamp(0, 100);
        final newOpacity = (clampedValue / 100).clamp(0.0, 1.0);
        _controller.text = '${clampedValue.round()}%';
        widget.onValueUpdate?.call(
          widget.color.withValues(alpha: newOpacity),
        );
      } else {
        final opacityPercent = (widget.color.a * 100).round();
        _controller.text = '$opacityPercent%';
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    if (widget.focus == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final opacity = widget.color.a;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);
    final focusBorderColor = colorScheme.primary;
    final hoverBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.15);
    final backgroundColor =
        isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            widget.label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              height: 1.0,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),
        MouseRegion(
          cursor: _isDragging
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.readOnly
                ? null
                : () {
                    if (!_focusNode.hasFocus) _focusNode.requestFocus();
                  },
            onHorizontalDragStart: widget.readOnly
                ? null
                : (DragStartDetails details) {
                    if (_focusNode.hasFocus) _focusNode.unfocus();
                    setState(() {
                      _isDragging = true;
                      _dragStartValue = opacity;
                      _dragStartPosition = details.globalPosition;
                    });
                  },
            onHorizontalDragUpdate: widget.readOnly
                ? null
                : (DragUpdateDetails details) {
                    if (_dragStartPosition == null) return;
                    final delta =
                        (details.globalPosition.dx - _dragStartPosition!.dx) *
                        0.01;
                    final newOpacity = (_dragStartValue + delta).clamp(
                      0.0,
                      1.0,
                    );
                    widget.onDragUpdate?.call(
                      widget.color.withValues(alpha: newOpacity),
                    );
                    final opacityPercent = (newOpacity * 100).round();
                    _controller.text = '$opacityPercent%';
                  },
            onHorizontalDragEnd: widget.readOnly
                ? null
                : (DragEndDetails details) {
                    setState(() {
                      _isDragging = false;
                      _dragStartPosition = null;
                    });
                    widget.onDragEnd?.call();
                  },
            child: SizedBox(
              width: 78,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color:
                      _focusNode.hasFocus || _isDragging
                      ? backgroundColor
                      : null,
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? focusBorderColor
                        : (_isDragging
                              ? hoverBorderColor
                              : borderColor),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _focusNode.hasFocus || _isDragging
                      ? [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: IgnorePointer(
                    ignoring: _isDragging || !_focusNode.hasFocus,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      readOnly: widget.readOnly,
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        final cleanValue = value.trim().replaceAll('%', '');
                        final numValue = num.tryParse(cleanValue);
                        if (numValue != null) {
                          final clampedValue = numValue.clamp(0, 100);
                          final newOpacity = (clampedValue / 100).clamp(
                            0.0,
                            1.0,
                          );
                          _controller.text = '${clampedValue.round()}%';
                          widget.onValueUpdate?.call(
                            widget.color.withValues(alpha: newOpacity),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
