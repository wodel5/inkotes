import 'package:flutter/material.dart';
import 'package:foledge/i18n/strings.g.dart';

extension ListExtensions<T> on List<T> {
  T? getOrNull(int index) {
    if (index < 0 || index >= length) {
      return null;
    } else {
      return this[index];
    }
  }
}

extension OffsetListExtensions on List<Offset> {
  void shift(Offset offset) {
    for (int i = 0; i < length; i++) {
      this[i] += offset;
    }
  }
}

extension StringExtensions on String {
  /// Acts like [String.replaceAllMapped]
  /// but accepts an async [replace] function.
  Future<String> replaceAllMappedAsync(
    Pattern exp,
    Future<String> Function(Match match) replace,
  ) async {
    final buffer = StringBuffer();
    final matches = exp.allMatches(this).toList();

    final replacements = await Future.wait([
      for (final match in matches) replace(match),
    ]);

    int stringIndex = 0;
    for (int matchIndex = 0; matchIndex < matches.length; matchIndex++) {
      final match = matches[matchIndex];
      final prefix = substring(stringIndex, match.start);

      buffer
        ..write(prefix)
        ..write(replacements[matchIndex]);

      stringIndex = match.end;
    }

    buffer.write(substring(stringIndex));
    return buffer.toString();
  }

  String? get ifNotEmpty => isEmpty ? null : this;
}

/// Formats an edited date as a relative time string.
String formatEditedDate(DateTime modified) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final modifiedDay = DateTime(modified.year, modified.month, modified.day);
  final timeStr =
      '${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';

  if (modifiedDay == today) {
    return '${t.home.today} $timeStr';
  } else if (modifiedDay == today.subtract(const Duration(days: 1))) {
    return '${t.home.yesterday} $timeStr';
  } else {
    return '${modified.year}/${modified.month.toString().padLeft(2, '0')}/${modified.day.toString().padLeft(2, '0')} $timeStr';
  }
}
