import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:foledge/components/toolbar/size_picker.dart';
import 'package:foledge/data/tools/_tool.dart';
import 'package:foledge/data/tools/highlighter.dart';
import 'package:foledge/data/tools/pen.dart';
import 'package:foledge/data/tools/pencil.dart';

class PenModal extends StatefulWidget {
  const PenModal({super.key, required this.getTool, required this.setTool, this.onInteraction});

  final Tool Function() getTool;
  final void Function(Pen) setTool;
  final VoidCallback? onInteraction;

  @override
  State<PenModal> createState() => _PenModalState();
}

class _PenModalState extends State<PenModal> {
  late ValueNotifier<bool> _controller;

  @override
  void initState() {
    super.initState();
    final Tool currentTool = widget.getTool();
    _controller = ValueNotifier(currentTool is Pen && currentTool.toolId != Pen.fountainPen().toolId);
  }

  @override
  void didUpdateWidget(covariant PenModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Tool currentTool = widget.getTool();
    final bool isBallpoint = currentTool is Pen && currentTool.toolId != Pen.fountainPen().toolId;
    if (_controller.value != isBallpoint) {
      _controller.value = isBallpoint;
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
        AdvancedSwitch(
          controller: _controller,
          width: 50,
          height: 20,
          onChanged: (value) {
            setState(() {
              widget.setTool(value ? Pen.ballpointPen() : Pen.fountainPen());
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
          activeChild: Icon(
            IconData(0xec19, fontFamily: 'iconfont'),
            size: 20,
            color: Color(0xFFE3E2E9),
          ),
          inactiveChild: Icon(
            IconData(0xec18, fontFamily: 'iconfont'),
            size: 20,
            color: Color(0xFFE3E2E9),
          ),
        ),
      ],
    ];

    return Center(
      child: SizedBox(
        height: 34,
        child: SingleChildScrollView(
          scrollDirection: axis,
          child: Flex(direction: axis, children: children),
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
