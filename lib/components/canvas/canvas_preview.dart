import 'package:flutter/material.dart';
import 'package:inkotes/components/canvas/inner_canvas.dart';
import 'package:inkotes/data/editor/editor_core_info.dart';
import 'package:inkotes/data/editor/editor_page.dart';
import 'package:inkotes/data/extensions/collection_extensions.dart';
import 'package:inkotes/data/prefs.dart';

class CanvasPreview extends StatelessWidget implements PreferredSizeWidget {
  CanvasPreview({
    super.key,
    this.pageIndex = 0,
    required this.height,
    required this.coreInfo,
  });

  final int pageIndex;
  final double? height;
  final EditorCoreInfo coreInfo;

  late final pageSize =
      coreInfo.pages.getOrNull(pageIndex)?.size ?? EditorPage.defaultSize;
  @override
  late final preferredSize = Size(pageSize.width, height ?? pageSize.height);

  @override
  Widget build(BuildContext context) {
    return InnerCanvas(
      pageIndex: pageIndex,
      width: preferredSize.width,
      height: preferredSize.height,
      showPageIndicator: stows.printPageIndicators.value,
      coreInfo: coreInfo,
      currentStroke: null,
      currentStrokeDetectedShape: null,
      currentSelection: null,
      currentToolIsSelect: false,
      currentScale: double.maxFinite,
    );
  }
}
