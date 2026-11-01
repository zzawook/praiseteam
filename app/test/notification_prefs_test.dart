import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/notifications/notification_prefs.dart';

void main() {
  test('push is on by default; every-setlist is opt-in', () {
    const none = NotificationPrefs({});
    expect(PushGroup.values.every(none.push), isTrue);
    expect(none.allSetlists, isFalse);
    expect(none.updated(const [allSetlistsCategory], true).allSetlists, isTrue);
  });

  test('a group reads as on only while all of its categories are', () {
    const none = NotificationPrefs({});
    expect(none.updated(const ['setlist_updated'], false).push(PushGroup.setlists), isFalse);
    final chatOff = none.updated(PushGroup.chat.categories, false);
    expect(chatOff.push(PushGroup.chat), isFalse);
    expect(chatOff.push(PushGroup.setlists), isTrue);
  });

  test('every category the server can push has exactly one switch', () {
    final source = File('../supabase/functions/push/messages.ts').readAsStringSync();
    final templates = source.substring(source.indexOf('const templates'), source.indexOf('const fallback'));
    final pushed = RegExp(r'^  ([a-z_]+):', multiLine: true).allMatches(templates).map((m) => m[1]!).toSet();
    final switches = [for (final g in PushGroup.values) ...g.categories];
    expect(switches.toSet(), pushed);
    expect(switches.length, switches.toSet().length, reason: 'no category under two switches');
  });
}
