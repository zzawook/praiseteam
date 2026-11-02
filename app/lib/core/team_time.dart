import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

/// Calendar operations use the team's IANA zone, never the device's zone.
/// UTC date-only values below represent calendar dates, not instants.
class TeamTime {
  TeamTime(this.name) {
    if (!_initialized) {
      data.initializeTimeZones();
      _initialized = true;
    }
    location = tz.getLocation(name);
  }

  static const defaultZone = 'Asia/Singapore';
  static bool _initialized = false;
  final String name;
  late final tz.Location location;

  tz.TZDateTime now() => tz.TZDateTime.now(location);
  tz.TZDateTime local(DateTime instant) => tz.TZDateTime.from(instant, location);
  tz.TZDateTime at(int year, int month, int day, [int hour = 0, int minute = 0]) =>
      tz.TZDateTime(location, year, month, day, hour, minute);

  DateTime date(DateTime instant) => calendarDate(local(instant));
  static DateTime calendarDate(DateTime day) => DateTime.utc(day.year, day.month, day.day);

  tz.TZDateTime startOfDay([DateTime? instant]) {
    final day = local(instant ?? now());
    return at(day.year, day.month, day.day);
  }

  int daysUntil(DateTime instant, {DateTime? from}) => date(instant).difference(date(from ?? now())).inDays;
}
