import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/components/canvas/canvas_background_preview.dart';
import 'package:inkotes/components/canvas/canvas_preview.dart';
import 'package:inkotes/components/canvas/inner_canvas.dart';
import 'package:inkotes/components/toolbar/size_picker.dart';
import 'package:inkotes/components/toolbar/widgets/background_color_button.dart';
import 'package:inkotes/components/toolbar/widgets/page_action_button.dart';
import 'package:inkotes/data/editor/editor_core_info.dart';
import 'package:inkotes/data/editor/page.dart';
import 'package:inkotes/data/extensions/flutter_extensions.dart';
import 'package:inkotes/data/extensions/collection_extensions.dart';
import 'package:inkotes/i18n/extensions/canvas_background_pattern_localized.dart';
import 'package:inkotes/i18n/strings.g.dart';
import 'package:inkotes/data/models/canvas_background_pattern.dart';

class EditorBottomSheet extends StatefulWidget {
  const EditorBottomSheet({
    super.key,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.setBackgroundPattern,
    required this.setBackgroundColor,
    required this.setLineHeight,
    required this.setLineThickness,
    required this.clearPage,
    required this.insertPageAfter,
    required this.duplicatePage,
    required this.deletePage,
    required this.redrawAndSave,
    required this.scrollToPage,
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
  final void Function(int) clearPage;
  final void Function(int) insertPageAfter;
  final void Function(int) duplicatePage;
  final void Function(int) deletePage;
  final VoidCallback redrawAndSave;
  final void Function(int) scrollToPage;
  final Future<int> Function() pickPhotos;
  final Future<bool> Function() importPdf;
  final bool canRasterPdf;

  @override
  State<EditorBottomSheet> createState() => _EditorBottomSheetState();
}

class _EditorBottomSheetState extends State<EditorBottomSheet> {
  late int _selectedPageIndex = widget.currentPageIndex ?? 0;
  final _pageScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedPage();
    });
  }

  void _scrollToSelectedPage() {
    if (!mounted || _pageScrollController.hasClients == false) return;
    final offset = _selectedPageIndex * (CanvasBackgroundPreview.fixedWidth + 10);
    _pageScrollController.animateTo(
      offset.clamp(0, _pageScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.coreInfo.pages.getOrNull(widget.currentPageIndex ?? -1);
    final pageSize = page?.size ?? EditorPage.defaultSize;

    final previewSize = Size(
      CanvasBackgroundPreview.fixedWidth,
      CanvasBackgroundPreview.fixedWidth * 1.4,
    );

    final pages = widget.coreInfo.pages;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 0),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Text(
                  t.editor.more,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  t.editor.menu.backgroundPattern,
                  style: TextTheme.of(context).titleMedium,
                ),
                const Spacer(),
                for (final preset in backgroundColorPresets) ...[
                  const SizedBox(width: 6),
                  BackgroundColorButton(
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
              height: previewSize.height + 24,
              child: Row(
                children: [
                  for (final backgroundPattern
                      in CanvasBackgroundPattern.values) ...[
                    if (backgroundPattern !=
                        CanvasBackgroundPattern.values.first)
                      const SizedBox(width: 4),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
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
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              backgroundPattern.localizedName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  t.editor.menu.lineHeight,
                  style: TextTheme.of(context).titleMedium,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.coreInfo.lineHeight.toString(),
                  style: TextTheme.of(context).titleMedium,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackShape: const RoundedRectSliderTrackShape(),
                      trackHeight: 18,
                      overlayShape: SliderComponentShape.noOverlay,
                      inactiveTrackColor: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF9999BB).withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      activeTrackColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF44495F)
                          : null,
                      thumbShape: const RingThumbShape(visualRadius: 7, strokeWidth: 5.5),
                      thumbColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE3E2E9)
                          : Colors.white,
                      tickMarkShape: const SmallTickMarkShape(),
                    ),
                    child: Slider(
                      value: widget.coreInfo.lineHeight.toDouble(),
                      min: 20,
                      max: 100,
                      divisions: 8,
                      onChanged:
                          widget.coreInfo.backgroundPattern ==
                              CanvasBackgroundPattern.none
                          ? null
                          : (double value) => setState(() {
                              widget.setLineHeight(value.toInt());
                            }),
                    ),
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
                Text(
                  widget.coreInfo.lineThickness.toString(),
                  style: TextTheme.of(context).titleMedium,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackShape: const RoundedRectSliderTrackShape(),
                      trackHeight: 18,
                      overlayShape: SliderComponentShape.noOverlay,
                      inactiveTrackColor: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF9999BB).withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      activeTrackColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF44495F)
                          : null,
                      thumbShape: const RingThumbShape(visualRadius: 7, strokeWidth: 5.5),
                      thumbColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE3E2E9)
                          : Colors.white,
                      tickMarkShape: const SmallTickMarkShape(),
                    ),
                    child: Slider(
                      value: widget.coreInfo.lineThickness.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      onChanged:
                          widget.coreInfo.backgroundPattern ==
                              CanvasBackgroundPattern.none
                          ? null
                          : (double value) => setState(() {
                              widget.setLineThickness(value.toInt());
                            }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(t.editor.pages, style: TextTheme.of(context).titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: previewSize.height + 24,
              child: ListView.separated(
                controller: _pageScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: pages.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, pageIndex) {
                  final isSelected = pageIndex == _selectedPageIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPageIndex = pageIndex;
                      });
                      widget.scrollToPage(pageIndex);
                      _scrollToSelectedPage();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: previewSize.width,
                          height: previewSize.height,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary
                                  .withSaturation(isSelected ? 1 : 0)
                                  .withValues(alpha: isSelected ? 1 : 0.1),
                              width: 2,
                            ),
                            borderRadius: const .all(.circular(8)),
                          ),
                          child: ClipRRect(
                            borderRadius: const .all(.circular(8)),
                            child: FittedBox(
                              child: SizedBox(
                                width: pages[pageIndex].size.width,
                                height: pages[pageIndex].size.height,
                                child: CanvasPreview(
                                  pageIndex: pageIndex,
                                  height: pages[pageIndex].size.height,
                                  coreInfo: widget.coreInfo,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pageIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: PageActionButton(
                      icon: Icons.insert_page_break,
                      label: t.editor.menu.insertPage,
                      enabled: true,
                      onTap: () {
                        widget.insertPageAfter(_selectedPageIndex);
                        setState(() {
                          _selectedPageIndex++;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: PageActionButton(
                      icon: FontAwesomeIcons.solidCopy,
                      label: t.editor.menu.duplicatePage,
                      enabled: true,
                      onTap: () {
                        widget.duplicatePage(_selectedPageIndex);
                        setState(() {
                          _selectedPageIndex++;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: PageActionButton(
                      icon: Icons.cleaning_services,
                      label: t.editor.menu.clearPage,
                      enabled: pages[_selectedPageIndex].isNotEmpty,
                      onTap: () {
                        widget.clearPage(_selectedPageIndex);
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: PageActionButton(
                      icon: FontAwesomeIcons.trash,
                      label: t.editor.menu.deletePage,
                      enabled: pages.length > 1,
                      onTap: () {
                        widget.deletePage(_selectedPageIndex);
                        setState(() {
                          if (_selectedPageIndex >= pages.length) {
                            _selectedPageIndex = pages.length - 1;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
