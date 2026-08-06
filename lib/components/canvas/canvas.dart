import 'package:flutter/material.dart';
import 'package:one_dollar_unistroke_recognizer/one_dollar_unistroke_recognizer.dart';
import 'package:inkotes/components/canvas/stroke.dart';
import 'package:inkotes/components/canvas/image/editor_image.dart';
import 'package:inkotes/components/canvas/inner_canvas.dart';
import 'package:inkotes/data/editor/editor_core_info.dart';
import 'package:inkotes/data/editor/page.dart';
import 'package:inkotes/data/tools/tool.dart';
import 'package:inkotes/data/tools/select.dart';
import 'package:inkotes/data/models/tool_id.dart';

class Canvas extends StatelessWidget {
  const Canvas({
    super.key,
    required this.path,
    required this.page,
    required this.pageIndex,
    required this.coreInfo,
    required this.currentStroke,
    required this.currentStrokeDetectedShape,
    required this.currentSelection,
    required this.setAsBackground,
    required this.currentTool,
    required this.currentScale,
    this.placeholder = false,
  });

  final String path;
  final EditorPage page;
  final int pageIndex;

  final EditorCoreInfo coreInfo;
  final Stroke? currentStroke;
  final RecognizedUnistroke? currentStrokeDetectedShape;
  final SelectResult? currentSelection;

  final void Function(EditorImage image)? setAsBackground;

  final Tool currentTool;
  final double currentScale;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.1,
                ), // dark regardless of theme
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: !placeholder
              ? SizedBox(
                  width: page.size.width,
                  height: page.size.height,
                  child: InnerCanvas(
                    key: page.innerCanvasKey,
                    pageIndex: pageIndex,
                    redrawPageListenable: page,
                    width: page.size.width,
                    height: page.size.height,
                    coreInfo: coreInfo,
                    currentStroke: currentStroke,
                    currentStrokeDetectedShape: currentStrokeDetectedShape,
                    currentSelection: currentSelection,
                    setAsBackground: setAsBackground,
                    currentToolIsSelect: currentTool.toolId == ToolId.select,
                    currentScale: currentScale,
                  ),
                )
              : SizedBox(width: page.size.width, height: page.size.height),
        ),
      ),
    );
  }
}
