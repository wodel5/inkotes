import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/tools/pen.dart';
import 'package:inkotes/i18n/strings.g.dart';

class Highlighter extends Pen {
  Highlighter()
    : super(
        name: t.editor.pens.highlighter,
        sizeMin: 5,
        sizeMax: 50,
        sizeStep: 5,
        icon: highlighterIcon,
        options: stows.lastHighlighterOptions.value,
        pressureEnabled: false,
        color: Colors.yellow.withAlpha(Highlighter.alpha),
        toolId: .highlighter,
      );

  static const alpha = 100;

  static Pen currentHighlighter = Highlighter();

  static const highlighterIcon = FontAwesomeIcons.highlighter;
}
