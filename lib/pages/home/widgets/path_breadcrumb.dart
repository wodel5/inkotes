import 'package:flutter/material.dart';

/// Breadcrumb navigation for path display.
class PathBreadcrumb extends StatelessWidget {
  const PathBreadcrumb({
    super.key,
    required this.path,
    required this.onTap,
    required this.rootLabel,
  });

  final String path;
  final void Function(String path) onTap;
  final String rootLabel;

  @override
  Widget build(BuildContext context) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => onTap(''),
              child: Text(
                rootLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            for (int i = 0; i < segments.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 16),
              ),
              GestureDetector(
                onTap: () => onTap('/${segments.sublist(0, i + 1).join('/')}'),
                child: Text(
                  segments[i],
                  style: TextStyle(
                    color: i == segments.length - 1
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: i == segments.length - 1
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
