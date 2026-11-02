import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../app/theme.dart';
import '../core/offline/local_db.dart';
import '../core/offline/offline_store.dart';
import '../core/offline/reachability.dart';
import '../core/providers.dart';
import '../core/team_time.dart';
import 'demo_banner.dart';
import 'demo_client.dart';
import 'demo_seed.dart';
import 'demo_store.dart';

class DemoApplication extends StatefulWidget {
  const DemoApplication({super.key, required this.preferences});
  final SharedPreferences preferences;
  @override
  State<DemoApplication> createState() => _DemoApplicationState();
}

class _DemoApplicationState extends State<DemoApplication> {
  static const _savedKey = 'praiseteam_demo_data';
  final _db = LocalDb();
  final _reachability = Reachability();
  late final _offline = OfflineStore(_db);
  DemoClient? _client;
  Object? _error;
  Timer? _saveSoon;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open({bool reset = false}) async {
    final old = _client;
    old?.store.onSaved = null;
    _saveSoon?.cancel();
    try {
      final raw = await rootBundle.loadString('assets/demo/reference.json');
      final reference = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final clock = TeamTime(
        reference['timezone'] as String? ?? TeamTime.defaultZone,
      );
      final day = clock.date(clock.now()).toIso8601String();
      final fingerprint = raw.codeUnits.fold<int>(
        0,
        (h, c) => (h * 31 + c) & 0x3fffffff,
      );
      Map<String, dynamic>? saved;
      if (!reset) {
        try {
          saved = jsonDecode(
            widget.preferences.getString(_savedKey) ?? 'null',
          ) as Map<String, dynamic>?;
        } catch (_) {}
      }
      final valid = saved?['day'] == day && saved?['reference'] == fingerprint;
      final tables = valid
          ? {
              for (final e
                  in (saved!['tables'] as Map<String, dynamic>).entries)
                e.key: [
                  for (final r in e.value as List) DemoRow.from(r as Map),
                ],
            }
          : seedDemo(reference);
      if (!valid) await _offline.clear();
      final store = DemoStore(tables);
      final client = DemoClient(store, _offline);
      await client.start();
      Future<bool> persist() => widget.preferences.setString(
        _savedKey,
        jsonEncode({
          'day': day,
          'reference': fingerprint,
          'tables': store.tables,
        }),
      );
      void save() {
        _saveSoon?.cancel();
        _saveSoon = Timer(const Duration(milliseconds: 250), () {
          persist();
        });
      }

      store.onSaved = save;
      // Reset is durable before it completes, including an immediate reload.
      await persist();
      if (!mounted) {
        await client.dispose();
        return;
      }
      setState(() {
        _client = client;
        _generation++;
        _error = null;
      });
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    } catch (error) {
      debugPrint('Demo initialization failed: $error');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _saveSoon?.cancel();
    _client?.dispose();
    _db.close();
    _reachability.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // A loading Navigator would consume a deep link before the actual
        // router is ready (e.g. /t/1/songs would become /t/1/home).
        builder: (context, child) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PraiseTeam',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (_error == null)
                  const CircularProgressIndicator()
                else
                  FilledButton(
                    onPressed: () => _open(reset: true),
                    child: const Text('데모 다시 열기'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return ProviderScope(
      key: ValueKey(_generation),
      overrides: [
        supabaseProvider.overrideWithValue(client),
        sharedPreferencesProvider.overrideWithValue(widget.preferences),
        reachabilityProvider.overrideWithValue(_reachability),
        localDbProvider.overrideWithValue(_db),
        offlineStoreProvider.overrideWithValue(_offline),
        resetDemoProvider.overrideWithValue(() => _open(reset: true)),
      ],
      child: const PraiseTeamApp(),
    );
  }
}
