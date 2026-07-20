import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:foledge/components/canvas/image/editor_image.dart';
import 'package:foledge/data/extensions/change_notifier_extensions.dart';

class CanvasImage extends StatefulHookWidget {
  CanvasImage({
    required this.filePath,
    required this.image,
    this.overrideBoxFit,
    required this.pageSize,
    required this.setAsBackground,
    this.isBackground = false,
    this.readOnly = false,
    this.selected = false,
  }) : super(key: Key('CanvasImage$filePath/${image.id}'));

  /// The path to the note that this image is in.
  final String filePath;
  final EditorImage image;
  final BoxFit? overrideBoxFit;
  final Size pageSize;
  final void Function(EditorImage image)? setAsBackground;
  final bool isBackground;
  final bool readOnly;
  final bool selected;

  /// When notified, all [CanvasImages] will have their [active] property set to false.
  static var activeListener = ChangeNotifier();

  /// The minimum size of the interactive area for the image.
  static double minInteractiveSize = 50;

  /// The minimum size of the image itself, inside of the interactive area.
  static double minImageSize = 10;

  /// The size of the edge midpoint handle dots.
  static const double handleSize = 16;

  @override
  State<CanvasImage> createState() => _CanvasImageState();
}

class _CanvasImageState extends State<CanvasImage> {
  var _active = false;

  /// Distance between the handle and the image edge.
  /// Positive = handles outside image, 0 = on edge, negative = inside.
  double handlePadding = 25;

  /// Whether this image can be dragged
  bool get active => _active;
  set active(bool value) {
    if (active == value) return;

    if (value) {
      CanvasImage.activeListener
          .notifyListenersPlease(); // de-activate all other images
    }

    _active = value;

    if (mounted) {
      try {
        setState(() {});
      } catch (e) {
        // setState throws error if widget is currently building
      }
    }
  }

  Rect panStartRect = .zero;
  Offset panStartPosition = .zero;

  @override
  void initState() {
    widget.image.loadIn();

    if (widget.image.newImage) {
      // if the image is new, make it [active]
      active = true;
      widget.image.newImage = false;
    }

    CanvasImage.activeListener.addListener(disableActive);

    super.initState();
  }

  void disableActive() {
    active = false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    useListenable(widget.image);
    if (widget.readOnly) active = false;

    final Widget unpositioned = IgnorePointer(
      ignoring: widget.readOnly,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          MouseRegion(
            cursor: active ? SystemMouseCursors.grab : MouseCursor.defer,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                active = !active;
              },
              onPanStart: active
                  ? (details) {
                      panStartRect = widget.image.dstRect;
                    }
                  : null,
              onPanUpdate: active
                  ? (details) {
                      setState(() {
                        final pad = handlePadding;
                        final maxX = widget.pageSize.width - widget.image.dstRect.width - pad;
                        final maxY = widget.pageSize.height - widget.image.dstRect.height - pad;
                        widget.image.dstRect = .fromLTWH(
                          (widget.image.dstRect.left + details.delta.dx)
                              .clamp(pad, max(pad, maxX))
                              .toDouble(),
                          (widget.image.dstRect.top + details.delta.dy)
                              .clamp(pad, max(pad, maxY))
                              .toDouble(),
                          widget.image.dstRect.width,
                          widget.image.dstRect.height,
                        );
                      });
                    }
                  : null,
              onPanEnd: active
                  ? (details) {
                      if (panStartRect == widget.image.dstRect) return;
                      widget.image.onMoveImage?.call(
                        widget.image,
                        .fromLTRB(
                          widget.image.dstRect.left - panStartRect.left,
                          widget.image.dstRect.top - panStartRect.top,
                          widget.image.dstRect.right - panStartRect.right,
                          widget.image.dstRect.bottom - panStartRect.bottom,
                        ),
                      );
                      panStartRect = .zero;
                    }
                  : null,
              child: Padding(
                padding: EdgeInsets.all(handlePadding),
                child: Center(
                  child: SizedBox(
                    width: widget.isBackground
                        ? widget.pageSize.width
                        : max(
                            widget.image.dstRect.width,
                            CanvasImage.minImageSize,
                          ),
                    height: widget.isBackground
                        ? widget.pageSize.height
                        : max(
                            widget.image.dstRect.height,
                            CanvasImage.minImageSize,
                          ),
                    child: SizedOverflowBox(
                      size: widget.image.srcRect.size,
                      child: Transform.translate(
                        offset: -widget.image.srcRect.topLeft,
                        child: widget.image.buildImageWidget(
                          context: context,
                          overrideBoxFit: widget.overrideBoxFit,
                          isBackground: widget.isBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.selected) // tint image if selected
            ColoredBox(color: colorScheme.primary.withValues(alpha: 0.5)),
          if (!widget.readOnly)
            for (double x = -20; x <= 20; x += 20)
              for (double y = -20; y <= 20; y += 20)
                if (x != 0 || y != 0) // ignore (0,0)
                  _CanvasImageResizeHandle(
                    active: active,
                    position: Offset(x, y),
                    image: widget.image,
                    parent: this,
                    afterDrag: () => setState(() {}),
                  ),
        ],
      ),
    );

    if (widget.isBackground) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastLinearToSlowEaseIn,
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        child: unpositioned,
      );
    }
    Widget positioned = AnimatedPositioned(
      // no animation if the image is being dragged or it's selected
      duration: (panStartRect != .zero || widget.selected)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.fastLinearToSlowEaseIn,

      left: widget.image.dstRect.left - handlePadding,
      top: widget.image.dstRect.top - handlePadding,
      width: max(widget.image.dstRect.width + handlePadding * 2, CanvasImage.minInteractiveSize),
      height: max(widget.image.dstRect.height + handlePadding * 2, CanvasImage.minInteractiveSize),

      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: unpositioned,
      ),
    );

    return positioned;
  }

  @override
  void dispose() {
    widget.image.loadOut();
    CanvasImage.activeListener.removeListener(disableActive);
    super.dispose();
  }
}

class _CanvasImageResizeHandle extends StatelessWidget {
  const _CanvasImageResizeHandle({
    required this.active,
    required this.position,
    required this.image,
    required this.parent,
    required this.afterDrag,
  });

  final bool active;
  final Offset position;
  final EditorImage image;
  final _CanvasImageState parent;
  final void Function() afterDrag;

  bool get isCorner => position.dx != 0 && position.dy != 0;

  double get _handleSize => 40;

  double get _left {
    final frameWidth = image.dstRect.width + _parentHandlePadding * 2;
    if (position.dx < 0) return 0;
    if (position.dx > 0) return frameWidth - _handleSize;
    return frameWidth / 2 - _handleSize / 2;
  }

  double get _top {
    final frameHeight = image.dstRect.height + _parentHandlePadding * 2;
    if (position.dy < 0) return 0;
    if (position.dy > 0) return frameHeight - _handleSize;
    return frameHeight / 2 - _handleSize / 2;
  }

  double get _parentHandlePadding => parent.handlePadding;

  double get _iconRotation {
    if (!isCorner) return 0;
    if (position.dx < 0 && position.dy < 0) return 45;
    if (position.dx > 0 && position.dy < 0) return -45;
    if (position.dx < 0 && position.dy > 0) return -45;
    return 45;
  }

  IconData get _icon =>
      position.dx < 0 ? Icons.chevron_left : Icons.chevron_right;

  Color _handleColor(ColorScheme colorScheme, Brightness brightness) {
    if (!active) return Colors.grey.shade500;
    final isDragging = parent.panStartRect != .zero;
    if (!isDragging) return Colors.grey.shade500;
    return brightness == Brightness.light ? Colors.grey.shade900 : Colors.grey.shade100;
  }

  Widget _buildHandleContent(ColorScheme colorScheme) {
    final brightness = Theme.of(parent.context).brightness;
    final color = _handleColor(colorScheme, brightness);
    if (isCorner) {
      return AnimatedRotation(
        turns: _iconRotation / 360,
        duration: const Duration(milliseconds: 100),
        child: Icon(
          _icon,
          size: 40,
          color: color,
        ),
      );
    }
    final edgeIcon = position.dx != 0 ? Icons.more_vert : Icons.more_horiz;
    return Icon(
      edgeIcon,
      size: 40,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Positioned(
      left: _left,
      top: _top,
      child: DeferPointer(
        paintOnTop: true,
        child: MouseRegion(
          cursor: () {
            if (!active) return MouseCursor.defer;

            if (position.dx == 0 && position.dy < 0)
              return SystemMouseCursors.resizeUp;
            if (position.dx == 0 && position.dy > 0)
              return SystemMouseCursors.resizeDown;
            if (position.dx < 0 && position.dy == 0)
              return SystemMouseCursors.resizeLeft;
            if (position.dx > 0 && position.dy == 0)
              return SystemMouseCursors.resizeRight;

            if (position.dx < 0 && position.dy < 0)
              return SystemMouseCursors.resizeUpLeft;
            if (position.dx < 0 && position.dy > 0)
              return SystemMouseCursors.resizeDownLeft;
            if (position.dx > 0 && position.dy < 0)
              return SystemMouseCursors.resizeUpRight;
            if (position.dx > 0 && position.dy > 0)
              return SystemMouseCursors.resizeDownRight;

            return MouseCursor.defer;
          }(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: active
                ? (details) {
                    parent.panStartRect = parent.widget.image.dstRect;
                    parent.panStartPosition = details.localPosition;
                  }
                : null,
            onPanUpdate: active
                ? (details) {
                    final Offset delta =
                        details.localPosition - parent.panStartPosition;

                    final pad = parent.handlePadding;

                    // Calculate new frame size from drag delta
                    double newFrameWidth;
                    if (position.dx < 0) {
                      newFrameWidth = parent.panStartRect.width + pad * 2 - delta.dx;
                    } else if (position.dx > 0) {
                      newFrameWidth = parent.panStartRect.width + pad * 2 + delta.dx;
                    } else {
                      newFrameWidth = parent.panStartRect.width + pad * 2;
                    }

                    double newFrameHeight;
                    if (position.dy < 0) {
                      newFrameHeight = parent.panStartRect.height + pad * 2 - delta.dy;
                    } else if (position.dy > 0) {
                      newFrameHeight = parent.panStartRect.height + pad * 2 + delta.dy;
                    } else {
                      newFrameHeight = parent.panStartRect.height + pad * 2;
                    }

                    // Image size = frame size - padding on both sides
                    double newWidth = newFrameWidth - pad * 2;
                    double newHeight = newFrameHeight - pad * 2;

                    if (newWidth <= 0 || newHeight <= 0) return;

                    // preserve aspect ratio if diagonal
                    if (position.dx != 0 && position.dy != 0) {
                      final aspectRatio =
                          image.dstRect.width / image.dstRect.height;
                      if (newWidth / newHeight > aspectRatio) {
                        newHeight = newWidth / aspectRatio;
                      } else {
                        newWidth = newHeight * aspectRatio;
                      }
                    }

                    // Calculate new image position (keep centered in frame)
                    double newLeft = image.dstRect.left;
                    double newTop = image.dstRect.top;
                    if (position.dx < 0) {
                      newLeft = parent.panStartRect.right - newWidth;
                    }
                    if (position.dy < 0) {
                      newTop = parent.panStartRect.bottom - newHeight;
                    }

                    // Clamp to page bounds (frame must stay within page)
                    final pageSize = parent.widget.pageSize;
                    newLeft = newLeft.clamp(pad, max(pad, pageSize.width - newWidth - pad));
                    newTop = newTop.clamp(pad, max(pad, pageSize.height - newHeight - pad));
                    newWidth = newWidth.clamp(0.0, pageSize.width - newLeft - pad);
                    newHeight = newHeight.clamp(0.0, pageSize.height - newTop - pad);

                    if (newWidth <= 0 || newHeight <= 0) return;

                    image.dstRect = .fromLTWH(newLeft, newTop, newWidth, newHeight);
                    afterDrag();
                  }
                : null,
            onPanEnd: active
                ? (details) {
                    if (parent.panStartRect == image.dstRect) return;
                    image.onMoveImage?.call(
                      image,
                      .fromLTRB(
                        image.dstRect.left - parent.panStartRect.left,
                        image.dstRect.top - parent.panStartRect.top,
                        image.dstRect.right - parent.panStartRect.right,
                        image.dstRect.bottom - parent.panStartRect.bottom,
                      ),
                    );
                    parent.panStartRect = .zero;
                  }
                : null,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: const Duration(milliseconds: 100),
              child: _buildHandleContent(colorScheme),
            ),
          ),
        ),
      ),
    );
  }
}
