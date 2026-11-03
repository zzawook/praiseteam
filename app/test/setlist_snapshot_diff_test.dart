import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/sessions/setlist_snapshot_diff.dart';

void main() {
  // One contract corpus for the production database and the isolated demo.
  final sql = File('../supabase/tests/database/14_setlist_occurrences.test.sql').readAsStringSync();
  final cases = jsonDecode(sql.split(r'$cases$')[1]) as List;
  for (final c in cases.cast<Map<String, dynamic>>()) {
    test(c['name'] as String, () {
      expect(
        diffSetlistSnapshots(
          (c['previous'] as List).cast<Map<String, dynamic>>(),
          (c['current'] as List).cast<Map<String, dynamic>>(),
        ),
        c['expected'],
      );
    });
  }
}
