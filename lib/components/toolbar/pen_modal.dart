import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:inkotes/components/toolbar/size_picker.dart';
import 'package:inkotes/data/tools/tool.dart';
import 'package:inkotes/data/tools/highlighter.dart';
import 'package:inkotes/data/tools/pen.dart';
import 'package:inkotes/data/tools/pencil.dart';
import 'package:inkotes/i18n/strings.g.dart';

class PenModal extends StatefulWidget {
  const PenModal({super.key, required this.getTool, this.onInteraction});

  final Tool Function() getTool;
  final VoidCallback? onInteraction;

  @override
  State<PenModal> createState() => _PenModalState();
}

class _PenModalState extends State<PenModal> {
  late ValueNotifier<bool> _controller;

  bool _isPressureEnabled() {
    final tool = widget.getTool();
    return tool is Pen && tool.pressureEnabled;
  }

  @override
  void initState() {
    super.initState();
    _controller = ValueNotifier(_isPressureEnabled());
  }

  @override
  void didUpdateWidget(covariant PenModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isPressureEnabled = _isPressureEnabled();
    if (_controller.value != isPressureEnabled) {
      _controller.value = isPressureEnabled;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    final children = <Widget>[
      SizePicker(axis: axis, pen: currentPen, onChanged: widget.onInteraction),
      if (currentPen is! Highlighter && currentPen is! Pencil) ...[
        const SizedBox(width: 8),
        Text(
          t.editor.penOptions.pressure,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        AdvancedSwitch(
          controller: _controller,
          width: 50,
          height: 20,
          onChanged: (value) {
            setState(() {
              final tool = widget.getTool();
              if (tool is Pen) {
                tool.pressureEnabled = value;
              }
            });
            widget.onInteraction?.call();
          },
          activeColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF44495F)
              : Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF44495F)
              : Theme.of(context).colorScheme.primary,
          thumb: CustomPaint(
            size: const Size(14, 14),
            painter: _RingPainter(),
          ),
          activeChild: const Icon(
            IconData(0xec18, fontFamily: 'iconfont'),
            size: 20,
            color: Color(0xFFE3E2E9),
          ),
          inactiveChild: const Icon(
            IconData(0xec19, fontFamily: 'iconfont'),
            size: 20,
            color: Color(0xFFE3E2E9),
          ),
        ),
      ],
    ];

    return IntrinsicWidth(
      child: Center(
        child: SizedBox(
          height: 34,
          child: SingleChildScrollView(
            scrollDirection: axis,
            child: Flex(direction: axis, children: children),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const visualRadius = 7.0;
    const strokeWidth = 5.5;
    final drawRadius = visualRadius - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      drawRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}
