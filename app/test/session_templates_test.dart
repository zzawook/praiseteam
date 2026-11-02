import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/sessions/models.dart';
import 'package:praiseteam/core/team_time.dart';

final time = TeamTime('Asia/Singapore');

SessionTemplate template({int weekday = DateTime.sunday, String startTime = '11:00:00', String title = '주일 2부 예배'}) =>
    SessionTemplate(id: 1, teamId: 1, title: title, weekday: weekday, startTime: startTime);

Session session(String title, DateTime startsAt) =>
    Session(id: 1, teamId: 1, title: title, startsAt: startsAt, setlistStatus: SetlistStatus.draft);

void main() {
  test('reads the time Postgres sends', () {
    final t = SessionTemplate.fromJson({
      'id': 3,
      'team_id': 1,
      'title': '금요 기도회',
      'weekday': 5,
      'start_time': '20:30:00',
      'location': null,
    });
    expect((t.weekday, t.hour, t.minute), (5, 20, 30));
  });

  group('next start', () {
    final wednesday = time.at(2026, 11, 4, 10);

    test('is the coming weekday at its time', () {
      expect(template().nextStart(wednesday, const [], time: time), time.at(2026, 11, 8, 11));
      expect(
        template(weekday: DateTime.friday, startTime: '20:00:00').nextStart(wednesday, const [], time: time),
        time.at(2026, 11, 6, 20),
      );
    });

    test('is today while the service is still ahead, else next week', () {
      expect(template().nextStart(time.at(2026, 11, 8, 8), const [], time: time), time.at(2026, 11, 8, 11));
      expect(template().nextStart(time.at(2026, 11, 8, 12), const [], time: time), time.at(2026, 11, 15, 11));
    });

    test('skips weeks that already have the service', () {
      final planned = [session('주일 2부 예배', time.at(2026, 11, 8, 11)), session('주일 2부 예배', time.at(2026, 11, 15, 11))];
      expect(template().nextStart(wednesday, planned, time: time), time.at(2026, 11, 22, 11));
    });

    test('skips a week whose time is taken by another service', () {
      final christmas = [session('성탄 예배', time.at(2026, 11, 8, 11))];
      expect(template().nextStart(wednesday, christmas, time: time), time.at(2026, 11, 15, 11));
    });

    test('keeps a week where other services meet at other times', () {
      final first = [session('주일 1부 예배', time.at(2026, 11, 8, 9))];
      expect(template().nextStart(wednesday, first, time: time), time.at(2026, 11, 8, 11));
    });

    test('runs on into the next month', () {
      final saturday = time.at(2026, 11, 28, 10);
      expect(template().nextStart(saturday, const [], time: time), time.at(2026, 11, 29, 11));
      expect(
        template().nextStart(saturday, [session('주일 2부 예배', time.at(2026, 11, 29, 11))], time: time),
        time.at(2026, 12, 6, 11),
      );
    });
  });

  test('lists Sunday first, then the week, earlier services first', () {
    final templates = [
      template(title: '토요 새벽', weekday: DateTime.saturday, startTime: '07:00:00'),
      template(title: '금요 기도회', weekday: DateTime.friday, startTime: '20:00:00'),
      template(title: '주일 2부', startTime: '11:00:00'),
      template(title: '수요 예배', weekday: DateTime.wednesday, startTime: '19:30:00'),
      template(title: '주일 1부', startTime: '09:00:00'),
    ]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    expect([for (final t in templates) t.title], ['주일 1부', '주일 2부', '수요 예배', '금요 기도회', '토요 새벽']);
  });
}
