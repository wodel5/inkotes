import 'package:flutter/material.dart';
import 'package:foledge/components/toolbar/size_picker.dart';
import 'package:foledge/data/tools/_tool.dart';
import 'package:foledge/data/tools/highlighter.dart';
import 'package:foledge/data/tools/pen.dart';
import 'package:foledge/data/tools/pencil.dart';
import 'package:foledge/i18n/strings.g.dart';

class PenModal extends StatefulWidget {
  const PenModal({super.key, required this.getTool, required this.setTool});

  final Tool Function() getTool;
  final void Function(Pen) setTool;

  @override
  State<PenModal> createState() => _PenModalState();
}

class _PenModalState extends State<PenModal> {
  @override
  Widget build(BuildContext context) {
    final axis = Axis.horizontal;
    final Tool currentTool = widget.getTool();
    final Pen currentPen;
    if (currentTool is Pen) {
      currentPen = currentTool;
    } else {
      return const SizedBox();
    }

    return Flex(
      direction: axis,
      mainAxisAlignment: .center,
      children: [
        SizePicker(axis: axis, pen: currentPen),
        if (currentPen is! Highlighter && currentPen is! Pencil) ...[
          const SizedBox.square(dimension: 8),
          IconButton(
            onPressed: () => setState(() {
              widget.setTool(Pen.fountainPen());
            }),
            style: TextButton.styleFrom(
              foregroundColor: Pen.currentPen.icon == Pen.fountainPenIcon
                  ? ColorScheme.of(context).secondary
                  : ColorScheme.of(context).onSurface,
              backgroundColor: Pen.currentPen.icon == Pen.fountainPenIcon
                  ? Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: const CircleBorder(),
            ),
            tooltip: t.editor.pens.fountainPen,
            icon: Icon(
              IconData(0xec18, fontFamily: 'iconfont'),
              size: 32,
              color: Pen.currentPen.icon == Pen.fountainPenIcon
                  ? ColorScheme.of(context).secondary
                  : ColorScheme.of(context).onSurface,
            ),
          ),
          const SizedBox.square(dimension: 8),
          IconButton(
            onPressed: () => setState(() {
              widget.setTool(Pen.ballpointPen());
            }),
            style: TextButton.styleFrom(
              foregroundColor: Pen.currentPen.icon == Pen.ballpointPenIcon
                  ? ColorScheme.of(context).secondary
                  : ColorScheme.of(context).onSurface,
              backgroundColor: Pen.currentPen.icon == Pen.ballpointPenIcon
                  ? Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: const CircleBorder(),
            ),
            tooltip: t.editor.pens.ballpointPen,
            icon: Icon(
              IconData(0xec19, fontFamily: 'iconfont'),
              size: 32,
              color: Pen.currentPen.icon == Pen.ballpointPenIcon
                  ? ColorScheme.of(context).secondary
                  : ColorScheme.of(context).onSurface,
            ),
          ),
        ],
      ],
    );
  }
}
