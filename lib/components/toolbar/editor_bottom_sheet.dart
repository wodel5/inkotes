import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:foledge/components/canvas/canvas_background_preview.dart';
import 'package:foledge/components/canvas/canvas_image_dialog.dart';
import 'package:foledge/components/canvas/inner_canvas.dart';
import 'package:foledge/data/editor/editor_core_info.dart';
import 'package:foledge/data/editor/page.dart';
import 'package:foledge/data/extensions/list_extensions.dart';
import 'package:foledge/i18n/extensions/box_fit_localized.dart';
import 'package:foledge/i18n/extensions/canvas_background_pattern_localized.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:sbn/canvas_background_pattern.dart';

class EditorBottomSheet extends StatefulWidget {
  const EditorBottomSheet({
    super.key,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.setBackgroundPattern,
    required this.setBackgroundColor,
    required this.setLineHeight,
    required this.setLineThickness,
    required this.removeBackgroundImage,
    required this.redrawImage,
    required this.clearPage,
    required this.clearAllPages,
    required this.redrawAndSave,
    required this.pickPhotos,
    required this.importPdf,
    required this.canRasterPdf,
  });

  final EditorCoreInfo coreInfo;
  final int? currentPageIndex;
  final void Function(CanvasBackgroundPattern) setBackgroundPattern;
  final void Function(Color?) setBackgroundColor;
  final void Function(int) setLineHeight;
  final void Function(int) setLineThickness;
  final VoidCallback removeBackgroundImage;
  final VoidCallback redrawImage;
  final VoidCallback clearPage;
  final VoidCallback clearAllPages;
  final VoidCallback redrawAndSave;
  final Future<int> Function() pickPhotos;
  final Future<bool> Function() importPdf;
  final bool canRasterPdf;

  @override
  State<EditorBottomSheet> createState() => _EditorBottomSheetState();
}

class _EditorBottomSheetState extends State<EditorBottomSheet> {
  static const imageBoxFits = <BoxFit>[.fill, .cover, .contain];

  @override
  Widget build(BuildContext context) {
    final page = widget.coreInfo.pages.getOrNull(widget.currentPageIndex ?? -1);
    final pageSize = page?.size ?? EditorPage.defaultSize;
    final backgroundImage = page?.backgroundImage;

    final previewSize = Size(
      CanvasBackgroundPreview.fixedWidth,
      CanvasBackgroundPreview.fixedWidth * 1.4,
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        // Enable drag scrolling on all devices (including mouse)
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12),
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  t.editor.more,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (backgroundImage != null) ...[
              Text(
                t.editor.menu.backgroundImageFit,
                style: TextTheme.of(context).titleMedium,
              ),
              SizedBox(
                height: previewSize.height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageBoxFits.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final boxFit = imageBoxFits[index];
                    return InkWell(
                      borderRadius: const .all(.circular(8)),
                      onTap: () => setState(() {
                        backgroundImage.backgroundFit = boxFit;
                        widget.redrawAndSave();
                      }),
                      child: CanvasBackgroundPreview(
                        selected: backgroundImage.backgroundFit == boxFit,
                        backgroundColor:
                            widget.coreInfo.backgroundColor ??
                            InnerCanvas.defaultBackgroundColor,
                        backgroundPattern:
                            widget.coreInfo.backgroundPattern,
                        pageSize: pageSize,
                        lineHeight: widget.coreInfo.lineHeight,
                        lineThickness: widget.coreInfo.lineThickness,
                        label: boxFit.localizedName,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              CanvasImageDialog(
                filePath: widget.coreInfo.filePath,
                image: backgroundImage,
                redrawImage: () => setState(() {
                  widget.redrawImage();
                }),
                isBackground: true,
                toggleAsBackground: widget.removeBackgroundImage,
                singleRow: true,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Text(
                  t.editor.menu.backgroundPattern,
                  style: TextTheme.of(context).titleMedium,
                ),
                const Spacer(),
                _BackgroundColorButton(
                  color: null,
                  label: t.editor.menu.defaultColor,
                  isSelected: widget.coreInfo.backgroundColor == null,
                  onTap: () => setState(() {
                    widget.setBackgroundColor(null);
                  }),
                ),
                for (final preset in _backgroundColorPresets) ...[
                  const SizedBox(width: 6),
                  _BackgroundColorButton(
                    color: preset,
                    label: '',
                    isSelected: widget.coreInfo.backgroundColor == preset,
                    onTap: () => setState(() {
                      widget.setBackgroundColor(preset);
                    }),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: previewSize.height,
              child: Row(
                children: [
                  for (final backgroundPattern in CanvasBackgroundPattern.values) ...[
                    if (backgroundPattern != CanvasBackgroundPattern.values.first)
                      const SizedBox(width: 4),
                    Expanded(
                      child: Center(
                        child: InkWell(
                          borderRadius: const .all(.circular(8)),
                          onTap: () => setState(() {
                            widget.setBackgroundPattern(backgroundPattern);
                          }),
                          child: CanvasBackgroundPreview(
                            selected:
                                widget.coreInfo.backgroundPattern ==
                                backgroundPattern,
                            backgroundColor:
                                widget.coreInfo.backgroundColor ??
                                InnerCanvas.defaultBackgroundColor,
                            backgroundPattern: backgroundPattern,
                            pageSize: pageSize,
                            lineHeight: widget.coreInfo.lineHeight,
                            lineThickness: widget.coreInfo.lineThickness,
                            label: backgroundPattern.localizedName,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  t.editor.menu.lineHeight,
                  style: TextTheme.of(context).titleMedium,
                ),
                const SizedBox(width: 12),
                Text(widget.coreInfo.lineHeight.toString()),
                Expanded(
                  child: Slider(
                    value: widget.coreInfo.lineHeight.toDouble(),
                    min: 20,
                    max: 100,
                    divisions: 8,
                    onChanged: widget.coreInfo.backgroundPattern == CanvasBackgroundPattern.none
                        ? null
                        : (double value) => setState(() {
                              widget.setLineHeight(value.toInt());
                            }),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  t.editor.menu.lineThickness,
                  style: TextTheme.of(context).titleMedium,
                ),
                const SizedBox(width: 12),
                Text(widget.coreInfo.lineThickness.toString()),
                Expanded(
                  child: Slider(
                    value: widget.coreInfo.lineThickness.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: widget.coreInfo.backgroundPattern == CanvasBackgroundPattern.none
                        ? null
                        : (double value) => setState(() {
                              widget.setLineThickness(value.toInt());
                            }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: widget.coreInfo.isNotEmpty
                      ? () {
                          widget.clearPage();
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    t.editor.menu.clearPage(
                      page: widget.currentPageIndex == null
                          ? '?'
                          : widget.currentPageIndex! + 1,
                      totalPages: widget.coreInfo.pages.length,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.coreInfo.isNotEmpty
                      ? () {
                          widget.clearAllPages();
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(t.editor.menu.clearAllPages),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _backgroundColorPresets = [
  Color(0xFFFFFBF0), // 暖白
  Color(0xFFF0FFF0), // 浅绿
  Color(0xFFF0F7FF), // 浅蓝
  Color(0xFFF5F5F5), // 浅灰
];

class _BackgroundColorButton extends StatelessWidget {
  const _BackgroundColorButton({
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
                  color: color == null ||
                          (color!.computeLuminance() > 0.5)
                      ? colorScheme.primary
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
