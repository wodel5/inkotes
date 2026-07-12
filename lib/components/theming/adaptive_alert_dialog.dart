import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveAlertDialog extends StatelessWidget {
  const AdaptiveAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final Widget title;
  final Widget content;
  final List<CupertinoDialogAction> actions;

  List<Widget> get _materialActions => actions
      .map(
        (CupertinoDialogAction action) =>
            TextButton(onPressed: action.onPressed, child: action.child),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions.isNotEmpty ? _materialActions : null,
    );
  }
}
