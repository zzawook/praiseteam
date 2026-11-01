/// Compile-time configuration, supplied with
/// `--dart-define-from-file=env/<name>.json` (see env/README.md).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// OAuth client id of the *web* client. Android/iOS use it as the
  /// server client id so Google returns an ID token Supabase accepts.
  static const googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Email/password login, only for a local Supabase stack.
  static const devLogin = bool.fromEnvironment('DEV_LOGIN');

  static void ensureConfigured() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY are missing. '
        'Run with --dart-define-from-file=env/local.json',
      );
    }
  }
}
