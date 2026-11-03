import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/http_client.dart';

/// Keep the app signed out until its Apple refresh token is safely retained
/// for revocation on account deletion. No Apple refresh token reaches Dart.
Future<void> signInWithNativeApple(SupabaseClient client) async {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.iOS ||
      !Env.appleSignInEnabled) {
    throw StateError('Native Apple sign-in is not enabled.');
  }
  final random = Random.secure();
  final nonce = base64Url
      .encode(List.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');
  final hashedNonce = sha256.convert(utf8.encode(nonce)).toString();
  AuthorizationCredentialAppleID credential;
  try {
    credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
  } on SignInWithAppleAuthorizationException catch (error) {
    if (error.code == AuthorizationErrorCode.canceled) return;
    rethrow;
  }
  final idToken = credential.identityToken;
  if (idToken == null || credential.authorizationCode.isEmpty) {
    throw const AuthException('Apple returned incomplete sign-in credentials.');
  }
  final temporary = SupabaseClient(
    Env.supabaseUrl,
    Env.supabasePublishableKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: ClockSkewRetryClient(),
  );
  var handedOff = false;
  try {
    final response = await temporary.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: nonce,
    );
    final session = response.session;
    if (session?.refreshToken == null) {
      throw const AuthException('Apple sign-in did not create a session.');
    }
    final stored = await temporary.functions.invoke(
      'apple-auth',
      body: {'authorization_code': credential.authorizationCode},
    );
    if (stored.data is! Map || stored.data['stored'] != true) {
      throw const AuthException('Apple sign-in could not be completed.');
    }
    await client.auth.setSession(session!.refreshToken!);
    handedOff = true;

    // Apple only supplies a name on initial consent. Do not overwrite an
    // existing display name when a Google account is linked to Apple.
    final name = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ').trim();
    if (name.isNotEmpty) {
      final fullName = String.fromCharCodes(name.runes.take(40));
      final user = client.auth.currentUser!;
      final defaultName = String.fromCharCodes(
        (user.email?.split('@').first ?? 'member').runes.take(40),
      );
      try {
        await client.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
        await client
            .from('profiles')
            .update({'display_name': fullName})
            .eq('id', user.id)
            .eq('display_name', defaultName);
      } catch (_) {
        /* The optional name can still be edited in settings. */
      }
    }
  } finally {
    if (!handedOff) {
      try {
        await temporary.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
    }
    await temporary.dispose();
  }
}
