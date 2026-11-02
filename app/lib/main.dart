import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/env.dart';
import 'core/http_client.dart';
import 'core/offline/reachability.dart';
import 'core/providers.dart';
import 'demo/demo_application.dart';
import 'features/notifications/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.ensureConfigured();
  usePathUrlStrategy(); // clean URLs on the web (/t/1/team); no-op elsewhere
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/GowunBatang-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Gowun Batang'], ofl);
  });

  if (Env.demo) {
    runApp(DemoApplication(preferences: await SharedPreferences.getInstance()));
    return;
  }

  // Every request reports whether the server answered, so the app knows
  // when to read the copies it keeps on the device instead.
  await initPush();
  final reachability = Reachability();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    httpClient: ReachabilityClient(
      ClockSkewRetryClient(),
      reachability,
      probeUrl: Uri.parse('${Env.supabaseUrl}/auth/v1/health'),
    ),
    // A read with no answer in 8 s counts as offline (saved copies are
    // shown instead); one retry rather than three, so that happens quickly.
    postgrestOptions: const PostgrestClientOptions(retryCount: 1, requestTimeout: Duration(seconds: 8)),
  );
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reachabilityProvider.overrideWithValue(reachability),
      ],
      child: const PraiseTeamApp(),
    ),
  );
}
