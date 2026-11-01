// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(PushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

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
final class PushRegistrationProvider
    extends $AsyncNotifierProvider<PushRegistration, PushState> {
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
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  PushRegistration create() => PushRegistration();
}

String _$pushRegistrationHash() => r'2acbcc1bde930021545558b85f557d3a7380914b';

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

abstract class _$PushRegistration extends $AsyncNotifier<PushState> {
  FutureOr<PushState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PushState>, PushState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PushState>, PushState>,
              AsyncValue<PushState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
