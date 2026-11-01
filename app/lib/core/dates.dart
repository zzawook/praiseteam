import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// "3주 전" style distance from [now] (in whole days, local time).
String timeAgo(AppLocalizations l10n, DateTime when, {DateTime? now}) {
  final today = _day(now ?? DateTime.now());
  final days = today.difference(_day(when.toLocal())).inDays;
  if (days <= 0) return l10n.today;
  if (days < 14) return l10n.daysAgo(days);
  if (days < 60) return l10n.weeksAgo(days ~/ 7);
  if (days < 730) return l10n.monthsAgo(days ~/ 30);
  return l10n.yearsAgo(days ~/ 365);
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Date and time formats in the app's language.
class DateFormats {
  DateFormats(BuildContext context) : _locale = Localizations.localeOf(context).toLanguageTag();
  final String _locale;

  /// 11월 2일 (일)
  String dayWithWeekday(DateTime t) => DateFormat.MMMEd(_locale).format(t.toLocal());

  /// 오후 7:30
  String time(DateTime t) => DateFormat.jm(_locale).format(t.toLocal());

  /// 2026년 11월 2일
  String fullDate(DateTime t) => DateFormat.yMMMd(_locale).format(t.toLocal());

  String weekdayShort(DateTime t) => DateFormat.E(_locale).format(t.toLocal());

  /// 11월
  String monthShort(DateTime t) => DateFormat.MMM(_locale).format(t.toLocal());
}
