import 'package:foledge/i18n/strings.g.dart';

/// 格式化编辑日期为相对时间字符串。
///
/// - 今天: "今天 HH:mm"
/// - 昨天: "昨天 HH:mm"
/// - 其他: "YYYY/MM/DD HH:mm"
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
