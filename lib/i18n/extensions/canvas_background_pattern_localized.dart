import 'package:foledge/i18n/strings.g.dart';
import 'package:sbn/canvas_background_pattern.dart';

extension CanvasBackgroundPatternLocalized on CanvasBackgroundPattern {
  String get localizedName => switch (this) {
    .none => t.editor.menu.bgPatterns.none,
    .lined => t.editor.menu.bgPatterns.lined,
    .dots => t.editor.menu.bgPatterns.dots,
  };
}
