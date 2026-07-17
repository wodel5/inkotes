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
      pageSize.height / pageSize.width * CanvasBackgroundPreview.fixedWidth,
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        // Enable drag scrolling on all devices (including mouse)
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 16),
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
                const Spacer(),
                Wrap(
                  spacing: 8,
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
                      child: Stack(
                        children: [
                          CanvasBackgroundPreview(
                            selected: backgroundImage.backgroundFit == boxFit,
                            backgroundColor:
                                widget.coreInfo.backgroundColor ??
                                InnerCanvas.defaultBackgroundColor,
                            backgroundPattern:
                                widget.coreInfo.backgroundPattern,
                            backgroundImage: backgroundImage,
                            overrideBoxFit: boxFit,
                            pageSize: pageSize,
                            lineHeight: widget.coreInfo.lineHeight,
                            lineThickness: widget.coreInfo.lineThickness,
                          ),
                          Positioned(
                            bottom: previewSize.height * 0.1,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _PermanentTooltip(
                                text: boxFit.localizedName,
                              ),
                            ),
                          ),
                        ],
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
            Text(
              t.editor.menu.backgroundPattern,
              style: TextTheme.of(context).titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: previewSize.height,
              child: Row(
                children: [
                  for (final backgroundPattern in CanvasBackgroundPattern.values) ...[
                    if (backgroundPattern != CanvasBackgroundPattern.values.first)
                      const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: const .all(.circular(8)),
                        onTap: () => setState(() {
                          widget.setBackgroundPattern(backgroundPattern);
                        }),
                        child: Stack(
                          children: [
                            CanvasBackgroundPreview(
                              selected:
                                  widget.coreInfo.backgroundPattern ==
                                  backgroundPattern,
                              backgroundColor:
                                  widget.coreInfo.backgroundColor ??
                                  InnerCanvas.defaultBackgroundColor,
                              backgroundPattern: backgroundPattern,
                              backgroundImage: null,
                              pageSize: pageSize,
                              lineHeight: widget.coreInfo.lineHeight,
                              lineThickness: widget.coreInfo.lineThickness,
                            ),
                            Positioned(
                              bottom: previewSize.height * 0.1,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _PermanentTooltip(
                                  text: backgroundPattern.localizedName,
                                ),
                              ),
                            ),
                          ],
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
          ],
        ),
      ),
    );
  }
}

class _PermanentTooltip extends StatelessWidget {
  const _PermanentTooltip({
    // ignore: unused_element_parameter
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const .all(.circular(8)),
        color: colorScheme.surface.withValues(alpha: 0.8),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: .center,
          textWidthBasis: TextWidthBasis.longestLine,
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
