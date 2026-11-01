import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) => Supabase.instance.client;

/// Overridden in main() with the instance loaded before runApp.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');
