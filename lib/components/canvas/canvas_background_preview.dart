import 'package:flutter/material.dart';
import 'package:foledge/components/canvas/_canvas_background_painter.dart';
import 'package:foledge/components/canvas/inner_canvas.dart';
import 'package:foledge/data/extensions/color_extensions.dart';
import 'package:sbn/canvas_background_pattern.dart';

class CanvasBackgroundPreview extends StatelessWidget {
  const CanvasBackgroundPreview({
    super.key,
    required this.selected,
    required this.backgroundColor,
    required this.backgroundPattern,
    required this.pageSize,
    required this.lineHeight,
    required this.lineThickness,
    required this.label,
  });

  final bool selected;
  final Color? backgroundColor;
  final CanvasBackgroundPattern backgroundPattern;
  final Size pageSize;
  final int lineHeight;
  final int lineThickness;
  final String label;

  static const double fixedWidth = 100;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final previewSize = Size(
      fixedWidth,
      pageSize.height / pageSize.width * fixedWidth,
    );
    final canvasSize = pageSize / 2;
    return Container(
      width: previewSize.width,
      height: previewSize.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.greenAccent
              .withSaturation(selected ? 1 : 0)
              .withValues(alpha: selected ? 1 : 0.1),
          width: 2,
        ),
        borderRadius: const .all(.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: const .all(.circular(8)),
        child: Stack(
          fit: StackFit.expand,
        children: [
          FittedBox(
            child: CustomPaint(
              size: canvasSize,
              painter: CanvasBackgroundPainter(
                backgroundColor:
                    backgroundColor ?? InnerCanvas.defaultBackgroundColor,
                backgroundPattern: backgroundPattern,
                lineHeight: lineHeight,
                lineThickness: lineThickness,
                primaryColor: colorScheme.primary
                    .withSaturation(selected ? 1 : 0)
                    .withValues(alpha: selected ? 1 : 0.5),
                secondaryColor: colorScheme.secondary
                    .withSaturation(selected ? 1 : 0)
                    .withValues(alpha: selected ? 1 : 0.5),
                preview: true,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: previewSize.width * 0.9,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
