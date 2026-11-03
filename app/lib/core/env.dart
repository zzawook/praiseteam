import 'package:flutter/foundation.dart' show kIsWeb;

/// Compile-time configuration, supplied with
/// `--dart-define-from-file=env/<name>.json` (see env/README.md).
abstract final class Env {
  /// The sample build runs entirely in the browser, without real credentials.
  static const demo = bool.fromEnvironment('DEMO_MODE');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// OAuth client id of the *web* client. Android/iOS use it as the
  /// server client id so Google returns an ID token Supabase accepts.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Turn on only after Apple's provider, signing key and revocation worker
  /// are configured. Store release validation requires this for iOS.
  static const appleSignInEnabled = bool.fromEnvironment(
    'APPLE_SIGN_IN_ENABLED',
  );

  /// Web push key pair from Firebase (Cloud Messaging > Web Push
  /// certificates). Empty: Firebase's default key is used.
  static const webPushKey = String.fromEnvironment('WEB_PUSH_KEY');

  /// Where the web app is served; the privacy policy page lives next to it.
  static const webAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://praiseteam-sg.web.app',
  );

  /// The privacy policy, next to the web app (the same origin on the web).
  static Uri get privacyPolicy => kIsWeb
      ? Uri.base.resolve('/privacy.html')
      : Uri.parse('$webAppUrl/privacy.html');

  /// Email/password login, only for a local Supabase stack.
  static const devLogin = bool.fromEnvironment('DEV_LOGIN');

  static void ensureConfigured() {
    if (demo) return;
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY are missing. '
        'Run with --dart-define-from-file=env/local.json',
      );
    }
  }
}
