import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'team_time.dart';

/// Above the router's navigator, so dialogs and bottom sheets share the
/// same team clock as the screen that opened them.
class TeamTimeScope extends InheritedWidget {
  const TeamTimeScope({super.key, required this.time, required super.child});
  final TeamTime time;

  static TeamTime of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TeamTimeScope>()?.time ?? TeamTime(TeamTime.defaultZone);

  @override
  bool updateShouldNotify(TeamTimeScope oldWidget) => time.name != oldWidget.time.name;
}

/// "3주 전" style distance from [now], in whole team-calendar days.
String timeAgo(AppLocalizations l10n, DateTime when, {DateTime? now, TeamTime? time}) {
  final clock = time ?? TeamTime(TeamTime.defaultZone);
  final days = -clock.daysUntil(when, from: now);
  if (days <= 0) return l10n.today;
  if (days < 14) return l10n.daysAgo(days);
  if (days < 60) return l10n.weeksAgo(days ~/ 7);
  if (days < 730) return l10n.monthsAgo(days ~/ 30);
  return l10n.yearsAgo(days ~/ 365);
}

/// Date and time formats in the app's language.
class DateFormats {
  DateFormats(BuildContext context)
    : _locale = Localizations.localeOf(context).toLanguageTag(),
      _l10n = AppLocalizations.of(context),
      clock = TeamTimeScope.of(context);
  final String _locale;
  final AppLocalizations _l10n;
  final TeamTime clock;

  String ago(DateTime when) => timeAgo(_l10n, when, time: clock);

  /// 11월 2일 (일)
  String dayWithWeekday(DateTime t) => DateFormat.MMMEd(_locale).format(clock.local(t));

  /// 오후 7:30
  String time(DateTime t) => DateFormat.jm(_locale).format(clock.local(t));

  /// A template's wall-clock time, with no date or device zone involved.
  String wallTime(int hour, int minute) => DateFormat.jm(_locale).format(DateTime.utc(2024, 1, 1, hour, minute));

  /// 2026년 11월 2일
  String fullDate(DateTime t) => DateFormat.yMMMd(_locale).format(clock.local(t));

  String calendarDate(DateTime day) => DateFormat.yMMMd(_locale).format(day);

  String dateAndTime(DateTime t) => DateFormat.MMMd(_locale).add_jm().format(clock.local(t));

  String weekdayShort(DateTime t) => DateFormat.E(_locale).format(clock.local(t));

  /// 일요일 (or 일 when [short]) for an ISO weekday, as [DateTime.weekday].
  String weekdayName(int weekday, {bool short = false}) =>
      // 1 January 2024 was a Monday.
      (short ? DateFormat.E(_locale) : DateFormat.EEEE(_locale)).format(DateTime(2024, 1, weekday));

  /// 11월
  String monthShort(DateTime t) => DateFormat.MMM(_locale).format(clock.local(t));
}
