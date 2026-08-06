import 'package:flutter/material.dart';
import 'package:inkotes/pages/home/settings.dart';

/// Settings overlay that appears as a floating panel.
class SettingsOverlay extends StatefulWidget {
  const SettingsOverlay({super.key, required this.buttonRect});

  final Rect buttonRect;

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  Orientation? _lastOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentOrientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != null && _lastOrientation != currentOrientation) {
      Navigator.of(context).pop();
    }
    _lastOrientation = currentOrientation;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const maxWidth = 350.0;
    const maxHeight = 500.0;

    double top = widget.buttonRect.bottom + 8;
    double left = widget.buttonRect.right - maxWidth;

    if (left < 16) left = 16;
    if (left + maxWidth > screenSize.width - 16) {
      left = screenSize.width - maxWidth - 16;
    }
    if (top + maxHeight > screenSize.height - 16) {
      top = widget.buttonRect.top - maxHeight - 8;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const SettingsContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
