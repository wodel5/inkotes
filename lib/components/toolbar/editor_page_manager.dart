import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foledge/components/canvas/canvas_gesture_detector.dart';
import 'package:foledge/components/canvas/canvas_preview.dart';
import 'package:foledge/components/theming/adaptive_icon.dart';
import 'package:foledge/data/editor/editor_core_info.dart';
import 'package:foledge/i18n/strings.g.dart';

class EditorPageManager extends StatefulWidget {
  const EditorPageManager({
    super.key,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.redrawAndSave,
    required this.insertPageAfter,
    required this.duplicatePage,
    required this.clearPage,
    required this.deletePage,
    required this.transformationController,
  });

  final EditorCoreInfo coreInfo;
  final int? currentPageIndex;
  final VoidCallback redrawAndSave;

  final void Function(int) insertPageAfter;
  final void Function(int) duplicatePage;
  final void Function(int) clearPage;
  final void Function(int) deletePage;

  final TransformationController transformationController;

  @override
  State<EditorPageManager> createState() => _EditorPageManagerState();
}

class _EditorPageManagerState extends State<EditorPageManager> {
  void scrollToPage(int pageIndex) => CanvasGestureDetector.scrollToPage(
    pageIndex: pageIndex,
    pages: widget.coreInfo.pages,
    screenWidth: MediaQuery.sizeOf(context).width,
    transformationController: widget.transformationController,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: null,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: widget.coreInfo.pages.length,
        itemBuilder: (context, pageIndex) {
          final isEmptyLastPage =
              pageIndex == widget.coreInfo.pages.length - 1 &&
              widget.coreInfo.pages[pageIndex].isEmpty;
          return InkWell(
            key: ValueKey(pageIndex),
            onTap: () => scrollToPage(pageIndex),
            child: Padding(
              padding: const .all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: .spaceAround,
                    children: [
                      Text(
                        '${pageIndex + 1} / ${widget.coreInfo.pages.length}',
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 150,
                          maxHeight: 250,
                        ),
                        child: FittedBox(
                          child: CanvasPreview(
                            pageIndex: pageIndex,
                            height: null,
                            coreInfo: widget.coreInfo,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: ReorderableDragStartListener(
                          index: pageIndex,
                          child: const Padding(
                            padding: .all(8),
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      IconButton(
                        tooltip: t.editor.menu.insertPage,
                        icon: const AdaptiveIcon(
                          icon: Icons.insert_page_break,
                        ),
                        onPressed: () => setState(() {
                          widget.insertPageAfter(pageIndex);
                          scrollToPage(pageIndex + 1);
                        }),
                      ),
                      IconButton(
                        tooltip: t.editor.menu.duplicatePage,
                        icon: const FaIcon(FontAwesomeIcons.solidCopy, size: 18),
                        onPressed: () => setState(() {
                          widget.duplicatePage(pageIndex);
                          scrollToPage(pageIndex + 1);
                        }),
                      ),
                      IconButton(
                        tooltip: t.editor.menu.clearPage,
                        icon: const Icon(Icons.cleaning_services),
                        onPressed: isEmptyLastPage
                            ? null
                            : () => setState(() {
                                widget.clearPage(pageIndex);
                                scrollToPage(pageIndex);
                              }),
                      ),
                      IconButton(
                        tooltip: t.editor.menu.deletePage,
                        icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18),
                        onPressed: isEmptyLastPage
                            ? null
                            : () => setState(() {
                                widget.deletePage(pageIndex);
                                scrollToPage(pageIndex);
                              }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        onReorderItem: (oldIndex, newIndex) {
          if (oldIndex == newIndex) return;
          widget.coreInfo.pages.insert(
            newIndex,
            widget.coreInfo.pages.removeAt(oldIndex),
          );

          // reassign pageIndex of pages' strokes and images
          for (int i = 0; i < widget.coreInfo.pages.length; i++) {
            final page = widget.coreInfo.pages[i];
            page.updatePageIndex(i);
          }

          widget.redrawAndSave();
        },
      ),
    );
  }
}
