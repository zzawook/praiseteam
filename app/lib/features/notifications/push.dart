import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/router.dart';
import '../../core/env.dart';
import '../../core/providers.dart';
import '../../firebase_options.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import 'notifications_providers.dart';
import 'notifications_screen.dart' show notificationRoute;

part 'push.g.dart';

/// iOS delivery also requires the app's APNs key in Firebase.
bool get pushSupported =>
    !Env.demo &&
    (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Called once in main(), before runApp.
Future<void> initPush() async {
  if (pushSupported) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

enum PushState { unsupported, off, blocked, on }

/// This device's push registration for the signed-in user.
///
/// FCM addresses an app installation by its Firebase Installation ID (FID):
/// [FirebaseMessaging.register] asks FCM to accept pushes for it, and
/// [FirebaseMessaging.onRegistered] reports the FID once FCM has. The FID
/// stays the same for the installation, so it is also kept on the device
/// and handed to the server again at each sign-in (register_device_token
/// moves it to whoever is signed in).
///
/// On a phone, push is switched on at sign-in (Android asks once). Browsers
/// should only ask after a click, so on the web it starts when the person
/// turns it on in settings, or by itself if the browser already allows it.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  static const _fidKey = 'push_fid';
  final _subscriptions = <StreamSubscription<String>>[];

  @override
  Future<PushState> build() async {
    ref.onDispose(() {
      for (final s in _subscriptions) {
        s.cancel();
      }
      _subscriptions.clear();
    });
    final user = ref.watch(currentUserIdProvider);
    if (!pushSupported) return PushState.unsupported;
    if (user == null) return PushState.off;
    final status = (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
    switch (status) {
      case AuthorizationStatus.authorized || AuthorizationStatus.provisional:
        return _register();
      case AuthorizationStatus.notDetermined:
        // Never asked: a phone asks now; a browser waits for a click.
        return kIsWeb ? PushState.off : _register();
      case AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently:
        // Android may ask again, but only when the person turns it on, not
        // at every sign-in.
        return _whenRefused(status);
    }
  }

  /// Off if Android may still ask (the switch asks again), blocked if only
  /// the device or browser settings can change it.
  static PushState _whenRefused(AuthorizationStatus status) =>
      status == AuthorizationStatus.denied &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android
      ? PushState.off
      : PushState.blocked;

  String? get _fid => ref.read(sharedPreferencesProvider).getString(_fidKey);

  Future<PushState> _register() async {
    final messaging = FirebaseMessaging.instance;
    final status = (await messaging.requestPermission()).authorizationStatus;
    if (status == AuthorizationStatus.denied ||
        status == AuthorizationStatus.deniedPermanently) {
      return _whenRefused(status);
    }
    if (_subscriptions.isEmpty) {
      _subscriptions
        ..add(messaging.onRegistered.listen((fid) => _save(fid).ignore()))
        ..add(messaging.onUnregistered.listen((fid) => _forget(fid).ignore()));
    }
    try {
      await messaging.register(
        vapidKey: kIsWeb && Env.webPushKey.isNotEmpty ? Env.webPushKey : null,
      );
    } catch (e) {
      debugPrint('push: FCM registration failed: $e');
      rethrow;
    }
    // Already registered before: FCM may not report it again.
    final known = _fid;
    if (known != null) await _save(known);
    return PushState.on;
  }

  Future<void> _save(String fid) async {
    await ref.read(sharedPreferencesProvider).setString(_fidKey, fid);
    if (ref.read(currentUserIdProvider) == null) return;
    await ref
        .read(supabaseProvider)
        .rpc(
          'register_device_token',
          params: {
            'p_token': fid,
            'p_platform': kIsWeb
                ? 'web'
                : defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          },
        );
  }

  Future<void> _forget(String fid) async {
    await ref.read(sharedPreferencesProvider).remove(_fidKey);
    if (ref.read(currentUserIdProvider) == null) return;
    await ref
        .read(supabaseProvider)
        .from('device_tokens')
        .delete()
        .eq('token', fid);
  }

  /// Turned on with a click (the web needs one before it may ask).
  /// Errors reach the caller, so the switch can say why it stayed off.
  Future<void> enable() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_register);
    if (state case AsyncError(:final error, :final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// No more pushes to this device for this user: turned off, or signing
  /// out (so the next person on a shared tablet gets none of them).
  Future<void> disable() async {
    if (!pushSupported) return;
    final fid = _fid;
    if (fid != null) await _forget(fid);
    await FirebaseMessaging.instance.unregister();
    state = const AsyncData(PushState.off);
  }
}

/// The in-app notification a push stands for (see the push function's data).
AppNotification? notificationOf(RemoteMessage message) {
  final data = message.data;
  final id = int.tryParse('${data['notification_id']}');
  final category = data['category'];
  if (id == null || category is! String) return null;
  Map<String, dynamic> params;
  try {
    params = Map<String, dynamic>.from(
      jsonDecode('${data['params'] ?? '{}'}') as Map,
    );
  } catch (_) {
    params = const {};
  }
  return AppNotification(
    id: id,
    teamId: int.tryParse('${data['team_id']}'),
    category: category,
    params: params,
    createdAt: message.sentTime ?? DateTime.now(),
  );
}

/// Opens the right screen when a notification is tapped, and shows pushes
/// that arrive while the app is open (the system does not, on Android).
class PushHandler extends ConsumerStatefulWidget {
  const PushHandler({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PushHandler> createState() => _PushHandlerState();
}

class _PushHandlerState extends ConsumerState<PushHandler> {
  final _subscriptions = <StreamSubscription<RemoteMessage>>[];

  @override
  void initState() {
    super.initState();
    if (!pushSupported) return;
    _subscriptions
      ..add(FirebaseMessaging.onMessage.listen(_whileOpen))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((m) => m == null ? null : _open(m))
        .ignore();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _open(RemoteMessage message) {
    final n = notificationOf(message);
    if (n?.teamId != null) ref.read(routerProvider).go(notificationRoute(n!));
  }

  void _whileOpen(RemoteMessage message) {
    final n = notificationOf(message);
    // Chat shows new messages and unread counts on its own.
    if (n == null || n.category == 'chat_message' || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final text = [
      message.notification?.title,
      message.notification?.body,
    ].whereType<String>().join('\n');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: n.teamId == null
              ? null
              : SnackBarAction(
                  label: l10n.open,
                  onPressed: () => _open(message),
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Registers this device once someone is signed in.
    ref.listen(pushRegistrationProvider, (_, _) {});
    return widget.child;
  }
}
