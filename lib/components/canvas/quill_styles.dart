import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:foledge/components/theming/font_fallbacks.dart';

typedef _ArgRecord = ({bool invert, Color secondary});

abstract class FoledgeQuillStyles {
  static DefaultStyles get({
    required bool invert,
    required Color secondary,
  }) {
    final _ArgRecord args = (
      invert: invert,
      secondary: secondary,
    );
    if (_lastArgs == args) {
      return _cachedStyles;
    }

    _lastArgs = args;
    return _cachedStyles = _createStyles(
      invert: invert,
      secondary: secondary,
    );
  }

  static _ArgRecord? _lastArgs;
  static late DefaultStyles _cachedStyles;

  /// Adapted from https://github.com/singerdmx/flutter-quill/blob/master/lib/src/editor/widgets/default_styles.dart
  static DefaultStyles _createStyles({
    required bool invert,
    required Color secondary,
  }) {
    const double fixedFontSize = 20;
    final baseStyle = TextStyle(
      inherit: false,
      fontFamily: 'Neucha',
      fontFamilyFallback: foledgeHandwritingFontFallbacks,
      color: invert ? Colors.white : Colors.black,
      fontSize: fixedFontSize,
      height: 1 / 1,
      decoration: TextDecoration.none,
    );
    final textTheme = (
      bodyLarge: baseStyle.copyWith(
        fontSize: fixedFontSize * 0.7,
        height: 1 / 0.7,
      ),
      displayLarge: baseStyle.copyWith(
        fontSize: fixedFontSize * 1.15,
        height: 1 / 1.15,
        decoration: TextDecoration.underline,
        decorationColor: baseStyle.color?.withValues(alpha: 0.6),
        decorationThickness: 3,
      ),
      displayMedium: baseStyle.copyWith(
        fontSize: fixedFontSize * 1,
        height: 1 / 1,
        decoration: TextDecoration.underline,
        decorationColor: baseStyle.color?.withValues(alpha: 0.5),
        decorationThickness: 3,
      ),
      displaySmall: baseStyle.copyWith(
        fontSize: fixedFontSize * 0.9,
        height: 1 / 0.9,
        decoration: TextDecoration.underline,
        decorationColor: baseStyle.color?.withValues(alpha: 0.4),
        decorationThickness: 3,
      ),
    );

    final lineHeightBlockStyle = DefaultTextBlockStyle(
      baseStyle,
      HorizontalSpacing.zero,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    );

    return DefaultStyles(
      h1: DefaultTextBlockStyle(
        textTheme.displayLarge,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      h2: DefaultTextBlockStyle(
        textTheme.displayMedium,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      h3: DefaultTextBlockStyle(
        textTheme.displaySmall,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      h4: DefaultTextBlockStyle(
        textTheme.displaySmall,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      h5: DefaultTextBlockStyle(
        textTheme.displaySmall,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      h6: DefaultTextBlockStyle(
        textTheme.displaySmall,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      lineHeightNormal: lineHeightBlockStyle,
      lineHeightTight: lineHeightBlockStyle,
      lineHeightOneAndHalf: lineHeightBlockStyle,
      lineHeightDouble: lineHeightBlockStyle,
      paragraph: DefaultTextBlockStyle(
        textTheme.bodyLarge,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      small: TextStyle(fontSize: fixedFontSize * 0.4, height: 1 / 0.4),
      inlineCode: InlineCodeStyle(
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
        radius: const .circular(3),
        style: textTheme.bodyLarge.copyWith(
          fontFamily: 'FiraMono',
          fontFamilyFallback: foledgeMonoFontFallbacks,
        ),
        header1: textTheme.displayLarge.copyWith(
          fontFamily: 'FiraMono',
          fontFamilyFallback: foledgeMonoFontFallbacks,
        ),
        header2: textTheme.displayMedium.copyWith(
          fontFamily: 'FiraMono',
          fontFamilyFallback: foledgeMonoFontFallbacks,
        ),
        header3: textTheme.displaySmall.copyWith(
          fontFamily: 'FiraMono',
          fontFamilyFallback: foledgeMonoFontFallbacks,
        ),
      ),
      link: TextStyle(color: secondary, decoration: TextDecoration.underline),
      placeHolder: DefaultTextBlockStyle(
        textTheme.bodyLarge.copyWith(color: Colors.grey.withValues(alpha: 0.6)),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      lists: DefaultListBlockStyle(
        textTheme.bodyLarge,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
        null,
      ),
      quote: DefaultTextBlockStyle(
        TextStyle(color: textTheme.bodyLarge.color!.withValues(alpha: 0.6)),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        BoxDecoration(
          border: Border(
            left: BorderSide(
              color: textTheme.bodyLarge.color!.withValues(alpha: 0.6),
              width: 4,
            ),
          ),
        ),
      ),
      code: DefaultTextBlockStyle(
        textTheme.bodyLarge.copyWith(
          fontFamily: 'FiraMono',
          fontFamilyFallback: foledgeMonoFontFallbacks,
        ),
        HorizontalSpacing.zero,
        VerticalSpacing(-fixedFontSize * 0.16, fixedFontSize * 0.8),
        VerticalSpacing.zero,
        BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: .all(.circular(3)),
        ),
      ),
      indent: DefaultTextBlockStyle(
        textTheme.bodyLarge,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      align: DefaultTextBlockStyle(
        textTheme.bodyLarge,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      leading: DefaultTextBlockStyle(
        textTheme.bodyLarge,
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      sizeSmall: TextStyle(
        fontSize: textTheme.bodyLarge.fontSize!,
        height: textTheme.bodyLarge.height!,
      ),
      sizeLarge: TextStyle(
        fontSize: textTheme.bodyLarge.fontSize!,
        height: textTheme.bodyLarge.height!,
      ),
      sizeHuge: TextStyle(
        fontSize: textTheme.bodyLarge.fontSize!,
        height: textTheme.bodyLarge.height!,
      ),
    );
  }
}
