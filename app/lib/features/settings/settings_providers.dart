import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../auth/auth.dart';

part 'settings_providers.g.dart';

const supportedLanguageCodes = ['ko', 'en'];

/// The language the user picked, or null to follow the device.
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  static const _key = 'locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    return supportedLanguageCodes.contains(code) ? Locale(code!) : null;
  }

  Future<void> choose(Locale? locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    state = locale;
  }
}

class ProfileRepository {
  ProfileRepository(this._db);
  final SupabaseClient _db;

  Future<({String displayName, String locale})> mine(String userId) async {
    final row = await _db.from('profiles').select('display_name, locale').eq('id', userId).single();
    return (displayName: row['display_name'] as String, locale: row['locale'] as String);
  }

  Future<void> update(String userId, {String? displayName, String? locale}) => _db
      .from('profiles')
      .update({'display_name': ?displayName?.trim(), 'locale': ?locale})
      .eq('id', userId);
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => ProfileRepository(ref.watch(supabaseProvider));

@Riverpod(keepAlive: true)
Future<({String displayName, String locale})?> myProfile(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).mine(userId);
}

/// Push texts are rendered on the server in the profile's language, so keep
/// it equal to the language the app is actually showing.
@Riverpod(keepAlive: true)
class ProfileLocaleSync extends _$ProfileLocaleSync {
  /// The language code last confirmed on the server; resets per user.
  @override
  String? build() {
    ref.watch(currentUserIdProvider);
    return null;
  }

  Future<void> sync(String languageCode) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || state == languageCode) return;
    final profile = await ref.read(myProfileProvider.future);
    if (profile != null && profile.locale != languageCode) {
      await ref.read(profileRepositoryProvider).update(userId, locale: languageCode);
      ref.invalidate(myProfileProvider);
    }
    state = languageCode;
  }
}
