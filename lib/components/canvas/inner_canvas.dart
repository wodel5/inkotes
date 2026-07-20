import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:one_dollar_unistroke_recognizer/one_dollar_unistroke_recognizer.dart';
import 'package:foledge/components/canvas/_canvas_background_painter.dart';
import 'package:foledge/components/canvas/_canvas_painter.dart';
import 'package:foledge/components/canvas/_stroke.dart';
import 'package:foledge/components/canvas/canvas_image.dart';
import 'package:foledge/components/canvas/image/editor_image.dart';
import 'package:foledge/data/editor/editor_core_info.dart';
import 'package:foledge/data/tools/select.dart';
import 'package:sbn/canvas_background_pattern.dart';

class InnerCanvas extends StatefulWidget {
  const InnerCanvas({
    super.key,
    required this.pageIndex,
    this.redrawPageListenable,
    required this.width,
    required this.height,
    this.showPageIndicator = true,
    required this.coreInfo,
    required this.currentStroke,
    required this.currentStrokeDetectedShape,
    required this.currentSelection,
    this.setAsBackground,
    this.onRenderObjectChange,
    required this.currentToolIsSelect,
    required this.currentScale,
  });

  final int pageIndex;
  final Listenable? redrawPageListenable;
  final double width;
  final double height;
  final bool showPageIndicator;
  final EditorCoreInfo coreInfo;
  final Stroke? currentStroke;
  final RecognizedUnistroke? currentStrokeDetectedShape;
  final SelectResult? currentSelection;
  final void Function(EditorImage image)? setAsBackground;
  final ValueChanged<RenderObject>? onRenderObjectChange;

  final bool currentToolIsSelect;

  final double currentScale;

  static const defaultBackgroundColor = Color(0xFFFCFCFC);

  @override
  State<InnerCanvas> createState() => _InnerCanvasState();
}

class _InnerCanvasState extends State<InnerCanvas> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color backgroundColor =
        widget.coreInfo.backgroundColor ?? InnerCanvas.defaultBackgroundColor;

    if (widget.coreInfo.pages.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    final page = widget.coreInfo.pages[widget.pageIndex];

    return RepaintBoundary(
      child: CustomPaint(
        painter: CanvasBackgroundPainter(
          backgroundColor: () {
            if (page.backgroundImage != null) {
              return Colors.white;
            } else {
              return backgroundColor;
            }
          }(),
          backgroundPattern: () {
            if (page.backgroundImage != null) {
              return CanvasBackgroundPattern.none;
            } else {
              return widget.coreInfo.backgroundPattern;
            }
          }(),
          lineHeight: widget.coreInfo.lineHeight,
          lineThickness: widget.coreInfo.lineThickness,
          primaryColor: colorScheme.primary,
          secondaryColor: colorScheme.secondary,
        ),
        foregroundPainter: CanvasPainter(
          repaint: widget.redrawPageListenable,
          strokes: page.strokes,
          laserStrokes: page.laserStrokes,
          currentStroke: widget.currentStroke,
          currentSelection: widget.currentSelection,
          primaryColor: colorScheme.primary,
          page: page,
          showPageIndicator: widget.showPageIndicator,
          pageIndex: widget.pageIndex,
          totalPages: widget.coreInfo.pages.length,
          currentScale: widget.currentScale,
          defaultTextStyle: theme.textTheme.bodyMedium!,
          backgroundColor: backgroundColor,
        ),
        isComplex: true,
        willChange: true,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: DeferredPointerHandler(
            child: ValueListenableBuilder<EditorImage?>(
              valueListenable: CanvasImage.activeImageNotifier,
              builder: (context, activeImage, _) {
                final images = page.images;

                // Build all image widgets with stable keys for reordering
                final imageWidgets = <Widget>[];
                Widget? activeImageWidget;
                for (int i = 0; i < images.length; i++) {
                  final image = images[i];
                  final imageWidget = CanvasImage(
                    key: ValueKey('CanvasImage_${image.id}'),
                    filePath: widget.coreInfo.filePath,
                    image: image,
                    pageSize: Size(widget.width, widget.height),
                    setAsBackground: widget.setAsBackground,
                    readOnly:
                        widget.coreInfo.readOnly || !widget.currentToolIsSelect,
                    selected:
                        widget.currentSelection?.images.contains(image) ??
                        false,
                  );
                  if (image == activeImage) {
                    activeImageWidget = imageWidget;
                  } else {
                    imageWidgets.add(imageWidget);
                  }
                }

                return Stack(
                  children: [
                    if (page.backgroundImage != null)
                      CanvasImage(
                        filePath: widget.coreInfo.filePath,
                        image: page.backgroundImage!,
                        pageSize: Size(widget.width, widget.height),
                        setAsBackground: null,
                        isBackground: true,
                        readOnly: true,
                      ),
                    // Non-active images in their normal order
                    ...imageWidgets,
                    // Active image on top so it's visible when overlapped
                    if (activeImageWidget != null) activeImageWidget,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
