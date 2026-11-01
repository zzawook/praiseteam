import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/core/providers.dart';
import 'package:praiseteam/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> containerWith(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('Korean until someone picks another language', () async {
    final container = await containerWith({});
    expect(container.read(appLocaleProvider), const Locale('ko'));
  });

  test('English and "follow the device" are kept as chosen', () async {
    expect((await containerWith({'locale': 'en'})).read(appLocaleProvider), const Locale('en'));
    expect((await containerWith({'locale': 'system'})).read(appLocaleProvider), isNull);
  });

  test('choosing "follow the device" survives a restart', () async {
    final container = await containerWith({});
    await container.read(appLocaleProvider.notifier).choose(null);
    expect(container.read(appLocaleProvider), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'system', reason: 'stored, not removed: removed means Korean');
  });
}
