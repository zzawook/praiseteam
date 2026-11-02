import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/errors.dart';
import '../../core/providers.dart';

part 'auth.g.dart';

/// Sign-in methods.
///  * Android/iOS: native Google sheet -> ID token -> Supabase.
///  * Web: Google's page via Supabase OAuth redirect.
///  * Dev builds against a local stack: email + password.
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;
  bool _googleReady = false;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: Uri.base.origin);
      return;
    }
    if (Env.googleWebClientId.isEmpty) {
      throw const AppError(AppErrorKind.googleNotConfigured);
    }
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId: Env.googleIosClientId.isEmpty ? null : Env.googleIosClientId,
        serverClientId: Env.googleWebClientId,
      );
      _googleReady = true;
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AppError(AppErrorKind.other, 'Google returned no ID token');
    }
    await _client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
  }

  Future<void> signInWithPassword(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signUpWithPassword(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _client.auth.signOut();
  }

  Future<void> deleteAccount() => _client.rpc('delete_account');

  Future<void> clearDeletedSession() async {
    try {
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } finally {
      // GoTrue removes local credentials before attempting its server call;
      // the deleted account's sessions have already been revoked in SQL.
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(ref.watch(supabaseProvider));

/// The current session; emits on sign-in, sign-out and token refresh.
@Riverpod(keepAlive: true)
Stream<Session?> session(Ref ref) async* {
  final client = ref.watch(supabaseProvider);
  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((event) => event.session);
}

/// The signed-in user's id, or null.
@Riverpod(keepAlive: true)
String? currentUserId(Ref ref) => ref.watch(sessionProvider).value?.user.id;
