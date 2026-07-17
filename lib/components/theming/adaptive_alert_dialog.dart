import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveAlertDialog extends StatelessWidget {
  const AdaptiveAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.backgroundColor,
  });

  final Widget title;
  final Widget content;
  final List<CupertinoDialogAction> actions;
  final Color? backgroundColor;

  List<Widget> get _materialActions => actions
      .map(
        (CupertinoDialogAction action) =>
            TextButton(onPressed: action.onPressed, child: action.child),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AlertDialog(
      title: title,
      content: content,
      actions: actions.isNotEmpty ? _materialActions : null,
      backgroundColor: backgroundColor ?? (isLight ? const Color(0xFFF2F4F8) : null),
    );
  }
}
