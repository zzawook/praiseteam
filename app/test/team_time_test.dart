import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/core/dates.dart';
import 'package:praiseteam/core/team_time.dart';
import 'package:praiseteam/features/sessions/models.dart';
import 'package:praiseteam/l10n/app_localizations_en.dart';

void main() {
  final singapore = TeamTime('Asia/Singapore');
  final newYork = TeamTime('America/New_York');

  test('an instant has the team date regardless of the device date', () {
    final instant = DateTime.utc(2026, 11, 7, 20, 30);
    expect(singapore.date(instant), DateTime.utc(2026, 11, 8));
    expect(newYork.date(instant), DateTime.utc(2026, 11, 7));
    expect(singapore.local(instant).hour, 4);
    expect(newYork.local(instant).hour, 15);
    expect(singapore.at(2026, 11, 8, 11).toUtc(), DateTime.utc(2026, 11, 8, 3));
  });

  test('calendar days across DST are counted as days, not 24-hour spans', () {
    final before = newYork.at(2026, 3, 8);
    final after = newYork.at(2026, 3, 9);
    expect(after.difference(before).inHours, 23);
    expect(newYork.daysUntil(after, from: before), 1);
    expect(timeAgo(AppLocalizationsEn(), before, now: after, time: newYork), 'yesterday');
  });

  test('weekly templates retain the team wall time across DST', () {
    const template = SessionTemplate(id: 1, teamId: 1, title: 'Sunday', weekday: 7, startTime: '11:00:00');
    final first = template.nextStart(DateTime.utc(2026, 3, 1, 12), const [], time: newYork);
    final second = template.nextStart(first, const [], time: newYork);
    expect(first.toUtc(), DateTime.utc(2026, 3, 1, 16));
    expect(second.toUtc(), DateTime.utc(2026, 3, 8, 15));
    expect((newYork.local(first).hour, newYork.local(second).hour), (11, 11));
  });

  test('templates find occupied weeks using team dates, including UTC midnight crossings', () {
    const template = SessionTemplate(id: 1, teamId: 1, title: 'Early Sunday', weekday: 7, startTime: '00:30:00');
    final existing = [
      Session(
        id: 1,
        teamId: 1,
        title: 'Early Sunday',
        startsAt: DateTime.utc(2026, 11, 7, 16, 30),
        setlistStatus: SetlistStatus.draft,
      ),
    ];
    final next = template.nextStart(DateTime.utc(2026, 11, 7, 12), existing, time: singapore);
    expect(next.toUtc(), DateTime.utc(2026, 11, 14, 16, 30));
  });
}
