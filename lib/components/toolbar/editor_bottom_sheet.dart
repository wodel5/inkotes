import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foledge/components/canvas/canvas_background_preview.dart';
import 'package:foledge/components/canvas/canvas_preview.dart';
import 'package:foledge/components/canvas/inner_canvas.dart';
import 'package:foledge/data/editor/editor_core_info.dart';
import 'package:foledge/data/editor/page.dart';
import 'package:foledge/data/extensions/color_extensions.dart';
import 'package:foledge/data/extensions/list_extensions.dart';
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
        padding: const .symmetric(horizontal: 16, vertical: 0), // 弹窗左右内边距
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
            const SizedBox(height: 8), // 标题"更多"下方间距
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
            const SizedBox(height: 8), // 画纸类型标题与预览图之间间距
            SizedBox(
              height: previewSize.height,
              child: Row(
                children: [
                  for (final backgroundPattern
                      in CanvasBackgroundPattern.values) ...[
                    if (backgroundPattern !=
                        CanvasBackgroundPattern.values.first)
                      const SizedBox(width: 4), // 画纸预览卡片之间的间距
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
            const SizedBox(height: 8), // 画纸预览图与行高之间间距
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
              ],
            ),
            Row(
              // 行高与线条粗细之间无间距，紧挨着
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
              ],
            ),
            const SizedBox(height: 8), // 线条粗细与页面标题之间间距
            Text(t.editor.pages, style: TextTheme.of(context).titleMedium),
            const SizedBox(height: 8), // 页面标题与缩略图之间间距
            SizedBox(
              height: previewSize.height + 24,
              child: ListView.separated(
                controller: _pageScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: pages.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 10), // 页面缩略图之间的间距
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
            const SizedBox(height: 8), // 缩略图与操作按钮之间间距
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _PageActionButton(
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
                    child: _PageActionButton(
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
                    child: _PageActionButton(
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
                    child: _PageActionButton(
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

const _backgroundColorPresets = [
  Color(0xFFFFFBF0), // 暖白
  Color(0xFFF0FFF0), // 浅绿
  Color(0xFFF0F7FF), // 浅蓝
  Color(0xFFF5F5F5), // 浅灰
  Color(0xFF272735), // 深色
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
                  color: color == null || (color!.computeLuminance() > 0.5)
                      ? colorScheme.primary
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _PageActionButton extends StatefulWidget {
  const _PageActionButton({
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
  State<_PageActionButton> createState() => _PageActionButtonState();
}

class _PageActionButtonState extends State<_PageActionButton> {
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
