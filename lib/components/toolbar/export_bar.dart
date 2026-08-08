import 'package:flutter/material.dart';
import 'package:inkotes/components/theming/adaptive_circular_progress_indicator.dart';
import 'package:inkotes/i18n/strings.g.dart';

class ExportBar extends StatefulWidget {
  const ExportBar({
    super.key,
    required this.axis,
    required this.toggleExportBar,
    required this.exportAsIks,
    required this.exportAsPdf,
    required this.exportAsPng,
  });

  final Axis axis;

  final VoidCallback toggleExportBar;

  final Future Function(BuildContext)? exportAsIks;
  final Future Function(BuildContext)? exportAsPdf;
  final Future Function(BuildContext)? exportAsPng;

  @override
  State<ExportBar> createState() => _ExportBarState();
}

class _ExportBarState extends State<ExportBar> {
  /// The current export function being executed.
  /// If this is null, no export is being executed.
  Future Function(BuildContext)? _currentlyExporting;

  void Function()? _onPressed(
    Future Function(BuildContext)? exportFunction,
    BuildContext context,
  ) {
    if (_currentlyExporting != null) return null;
    if (exportFunction == null) return null;
    return () {
      setState(() => _currentlyExporting = exportFunction);
      exportFunction(context).then((_) {
        widget.toggleExportBar();
        if (mounted) {
          setState(() => _currentlyExporting = null);
        }
      }).catchError((Object _) {
        // 导出失败时也要恢复按钮状态，避免一直转圈
        if (mounted) {
          setState(() => _currentlyExporting = null);
        }
      });
    };
  }

  Widget _buttonChild(
    Future Function(BuildContext)? exportFunction,
    String text,
  ) {
    if (exportFunction == null || _currentlyExporting != exportFunction) {
      return Text(text);
    } else {
      // if this is currently exporting, show a loading icon
      return AdaptiveCircularProgressIndicator.textStyled(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final children = <Widget>[
      Text(t.editor.toolbar.exportAs),
      const SizedBox.square(dimension: 8),
      Builder(
        builder: (context) {
          return TextButton(
            onPressed: _onPressed(widget.exportAsIks, context),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: _buttonChild(widget.exportAsIks, 'IKS'),
          );
        },
      ),
      Builder(
        builder: (context) {
          return TextButton(
            onPressed: _onPressed(widget.exportAsPdf, context),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: _buttonChild(widget.exportAsPdf, 'PDF'),
          );
        },
      ),
      Builder(
        builder: (context) {
          return TextButton(
            onPressed: _onPressed(widget.exportAsPng, context),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: _buttonChild(widget.exportAsPng, 'PNG'),
          );
        },
      ),
    ];

    return IntrinsicWidth(
      child: Center(
        child: SizedBox(
          height: 34,
          child: SingleChildScrollView(
            scrollDirection: widget.axis,
            child: Flex(direction: widget.axis, children: children),
          ),
        ),
      ),
    );
  }
}
