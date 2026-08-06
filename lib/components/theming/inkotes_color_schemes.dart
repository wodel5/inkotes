import 'package:flutter/material.dart';

/// Inkotes 固定配色方案。
///
/// 这些颜色提取自开发时模拟器的 Material You 动态取色并硬编码固定，
/// 保证在所有设备上主题色一致（不随系统壁纸变化）。
/// 以后加主题或改配色，只需要修改/新增这里的方案。
abstract class InkotesColorSchemes {
  /// 浅色主题
  static const ColorScheme light = ColorScheme.light(
    primary: Color(0xFF495D92),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDAE2FF),
    onPrimaryContainer: Color(0xFF001849),
    secondary: Color(0xFF585E71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDDE2F9),
    onSecondaryContainer: Color(0xFF151B2C),
    tertiary: Color(0xFF735471),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFED6F9),
    onTertiaryContainer: Color(0xFF2B122B),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFEFBFF),
    onSurface: Color(0xFF1A1B21),
    onSurfaceVariant: Color(0xFF45464F),
    outline: Color(0xFF757780),
    outlineVariant: Color(0xFFC5C6D0),
    inverseSurface: Color(0xFF2F3036),
    onInverseSurface: Color(0xFFF1F0F7),
    inversePrimary: Color(0xFFB2C5FF),
    surfaceTint: Color(0xFF495D92),
    surfaceContainerHighest: Color(0xFFFEFBFF),
    surfaceContainerHigh: Color(0xFFFEFBFF),
    surfaceContainer: Color(0xFFFEFBFF),
    surfaceContainerLow: Color(0xFFFEFBFF),
    surfaceContainerLowest: Color(0xFFFEFBFF),
  );

  /// 深色主题
  static const ColorScheme dark = ColorScheme.dark(
    primary: Color(0xFFB2C5FF),
    onPrimary: Color(0xFF182E60),
    primaryContainer: Color(0xFF314578),
    onPrimaryContainer: Color(0xFFDAE2FF),
    secondary: Color(0xFFC0C6DD),
    onSecondary: Color(0xFF2A3042),
    secondaryContainer: Color(0xFF404659),
    onSecondaryContainer: Color(0xFFDDE2F9),
    tertiary: Color(0xFFE1BBDC),
    onTertiary: Color(0xFF422741),
    tertiaryContainer: Color(0xFF5A3D59),
    onTertiaryContainer: Color(0xFFFED6F9),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF1A1B21),
    onSurface: Color(0xFFE3E2E9),
    onSurfaceVariant: Color(0xFFC5C6D0),
    outline: Color(0xFF8F909A),
    outlineVariant: Color(0xFF45464F),
    inverseSurface: Color(0xFFE3E2E9),
    onInverseSurface: Color(0xFF2F3036),
    inversePrimary: Color(0xFF495D92),
    surfaceTint: Color(0xFFB2C5FF),
    surfaceContainerHighest: Color(0xFF1A1B21),
    surfaceContainerHigh: Color(0xFF1A1B21),
    surfaceContainer: Color(0xFF1A1B21),
    surfaceContainerLow: Color(0xFF1A1B21),
    surfaceContainerLowest: Color(0xFF1A1B21),
  );
}
