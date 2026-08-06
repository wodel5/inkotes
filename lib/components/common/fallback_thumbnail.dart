import 'package:flutter/material.dart';
import 'package:inkotes/components/canvas/inner_canvas.dart';
import 'package:inkotes/i18n/strings.g.dart';

/// 空缩略图占位组件，用于笔记卡片和回收站卡片。
class FallbackThumbnail extends StatelessWidget {
  const FallbackThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: InnerCanvas.defaultBackgroundColor,
      child: Center(
        child: Text(
          t.home.noPreviewAvailable,
          style: TextTheme.of(context).bodyMedium?.copyWith(
                color: Colors.grey.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
