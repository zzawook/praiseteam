/// Demo counterpart of private.setlist_diff. Match occurrences by item_id;
/// old announcements without IDs get a deterministic, one-to-one fallback.
/// Keep the published summary shape compatible with older clients.
Map<String, dynamic> diffSetlistSnapshots(List<Map<String, dynamic>> previous, List<Map<String, dynamic>> current) {
  final matches = List<int?>.filled(current.length, null);
  final used = <int>{};
  void match(int before, int after) {
    matches[after] = before;
    used.add(before);
  }

  for (final (i, after) in current.indexed) {
    if (after['item_id'] == null) continue;
    for (final (j, before) in previous.indexed) {
      if (!used.contains(j) && before['item_id'] == after['item_id'] && before['song_id'] == after['song_id']) {
        match(j, i);
        break;
      }
    }
  }
  for (final exact in [true, false]) {
    for (final (j, before) in previous.indexed) {
      if (used.contains(j)) continue;
      final candidates =
          [
            for (final (i, after) in current.indexed)
              if (matches[i] == null &&
                  before['song_id'] == after['song_id'] &&
                  (before['item_id'] == null || after['item_id'] == null) &&
                  (!exact ||
                      (before['key'] == after['key'] &&
                          (!before.containsKey('version_id') || before['version_id'] == after['version_id']) &&
                          (!before.containsKey('bpm') || before['bpm'] == after['bpm']))))
                i,
          ]..sort((a, b) {
            final proximity = (a - j).abs().compareTo((b - j).abs());
            return proximity == 0 ? a.compareTo(b) : proximity;
          });
      if (candidates.isNotEmpty) match(j, candidates.first);
    }
  }

  String title(Map<String, dynamic> row, int index) {
    final repeated =
        previous.where((r) => r['song_id'] == row['song_id']).length > 1 ||
        current.where((r) => r['song_id'] == row['song_id']).length > 1;
    return '${repeated ? '${index + 1}. ' : ''}${row['title']}';
  }

  final result = <String, dynamic>{
    'added': [
      for (final (i, row) in current.indexed)
        if (matches[i] == null) title(row, i),
    ],
    'removed': [
      for (final (i, row) in previous.indexed)
        if (!used.contains(i)) title(row, i),
    ],
  };
  for (final (field, label) in [('version_id', 'version_changed'), ('key', 'key_changed'), ('bpm', 'tempo_changed')]) {
    result[label] = [
      for (final (i, after) in current.indexed)
        if (matches[i] case final j?)
          if ((field == 'key' || previous[j].containsKey(field)) && previous[j][field] != after[field])
            {
              'title': title(after, i),
              'from': ?previous[j][field == 'version_id' ? 'version' : field],
              'to': ?after[field == 'version_id' ? 'version' : field],
            },
    ];
  }
  result.removeWhere((_, value) => value is List && value.isEmpty);
  final beforeOrder = used.toList()..sort();
  final afterOrder = matches.whereType<int>().toList();
  if (beforeOrder.indexed.any((e) => e.$2 != afterOrder[e.$1])) result['reordered'] = true;
  return result;
}
