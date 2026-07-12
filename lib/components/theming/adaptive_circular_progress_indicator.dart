import 'package:flutter/material.dart';

class AdaptiveCircularProgressIndicator extends StatelessWidget {
  const AdaptiveCircularProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final double? value;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;
  final double? strokeWidth;
  final String? semanticsLabel;
  final String? semanticsValue;

  static Widget textStyled({double? value, double alpha = 1.0}) => Builder(
    builder: (context) {
      final textStyle = DefaultTextStyle.of(context).style;
      final textSize = textStyle.fontSize ?? 14;
      final textColor = textStyle.color ?? ColorScheme.of(context).onSurface;
      return SizedBox.square(
        dimension: textSize,
        child: AdaptiveCircularProgressIndicator(
          value: value,
          strokeWidth: textSize / 4,
          valueColor: AlwaysStoppedAnimation(
            textColor.withValues(alpha: alpha),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator.adaptive(
      value: value,
      backgroundColor: backgroundColor,
      valueColor: valueColor,
      strokeWidth: strokeWidth ?? 4,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
    );
  }
}
