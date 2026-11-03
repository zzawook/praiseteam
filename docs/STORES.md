# Mobile store releases

Android package / iOS bundle: `com.kjaehyeok.praiseteam`. Version and Android
version code live in `app/pubspec.yaml`. The iOS target supports iOS 15+.

## Verify before a release

- `flutter analyze --no-pub` and `flutter test --no-pub` from `app/`.
- `node e2e/run_native.cjs` on a disposable Android emulator and the existing
  local Supabase stack. No database reset is performed. See `e2e/README.md`.
- `node e2e/run_native.cjs --device-extras` checks the Android file picker,
  image-to-PDF upload, thumbnails and offline cache/ink reconnection.
- The Codemagic `ios-simulator` workflow runs native UI/PDF tests with the sample
  team. This verifies native libraries and layouts, not live Apple/Google OAuth
  or APNs delivery. Those need a signed build and real accounts/devices.
- Run database and Edge Function tests when authentication/backend code changes:
  `supabase test db --local`, `deno task check`, `deno task test` (Deno 2.5.6).

## Android / Google Play

Run `python3 scripts/build_store.py`. It rejects development/demo configuration
and privileged backend keys, then produces signed AAB/APK files and checksums
under `output/store/android/`. Gradle fails if release signing is missing.
Run `python3 scripts/verify_android_release.py` to verify APK/AAB signatures,
APK ZIP alignment and every 64-bit native library's 16 KB ELF alignment.

Keep the existing `.secrets/praiseteam-release.jks` and its passwords. In Play
Console, upload the AAB to internal testing first. Once Play App Signing is
configured, register **its app-signing SHA-1**, package name and project in a
Google Android OAuth client. It can differ from the local upload/signing key;
a locally working Google login does not prove a Play-installed copy works.

Current requirements checked on 3 November 2026:

- [New Play submissions require target API 36](https://support.google.com/googleplay/android-developer/answer/11926878).
- For [personal developer accounts created after 13 November 2023](https://support.google.com/googleplay/android-developer/answer/14151465), production access requires at least 12 opted-in closed testers for 14 continuous days. This condition does not apply to every developer account.
- Review the actual installed release for Google login, notification permission,
  background pushes, PDF file selection and offline behavior before production.

## iOS / Codemagic

The [PraiseTeam Codemagic project](https://codemagic.io/app/6ae971120307f527d0b74bd8/settings)
is connected only to `zzawook/praiseteam`. Both workflows are manual.

`ios-simulator` needs no Apple signing credentials. It exports screenshots and
`PraiseTeam-iOS-Simulator.zip`; that ZIP is for Simulator, not installation on an iPhone.

`ios-testflight` needs the following setup by the account holder:

1. An active Apple Developer Program membership. Register the bundle ID with
   **Sign in with Apple** and **Push Notifications**, and create its App Store
   Connect app record.
2. Add an App Store Connect API integration named `praiseteam-app-store` in
   Codemagic, and add the matching App Store distribution certificate/profile
   in code signing identities. Store keys in those secure settings, not Git.
3. Add variable group `praiseteam-production` with `APP_CONFIG_JSON`: the
   client-only values from `app/env/prod.json`, with `APPLE_SIGN_IN_ENABLED=true`.
   Keep `DEV_LOGIN` and `DEMO_MODE` false. The build validates these fields and
   assigns a unique build number using the Codemagic project counter + 1000.
4. Complete the Apple login/revocation and APNs setup below before enabling the
   signed release. Verify both sign-in providers and account deletion on device.

The workflow uses Xcode 27.2 and uploads signed IPA builds to TestFlight. Public
App Store review is a separate step. The current minimum upload requirement is
[Xcode 26 / iOS 26 SDK](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).

The registered Firebase iOS app is
`1:677984922607:ios:76ab9e34d0d60119cd241a`. Its public configuration is included
in the Runner target. The Google iOS OAuth client and callback URL scheme are
also configured. A small, licensed `google_sign_in_ios` override pins the
Firebase-13-compatible Google SDK; see `app/third_party/google_sign_in_ios/PATCH.md`.

## Apple sign-in and account deletion

Enable the Apple provider in Supabase Auth with native Client ID
`com.kjaehyeok.praiseteam`. This implementation uses native ID-token login;
it does not enable Apple OAuth on Android or the web.

Create a **Sign in with Apple** key in Apple Developer (different purpose from
the App Store Connect API key). Keep the downloaded `.p8` under `.secrets/`, then:

```sh
python3 scripts/prepare_apple_secrets.py --team-id YOURTEAMID \
  --key-id YOUR_KEY_ID --private-key .secrets/AuthKey_YOUR_KEY_ID.p8
scripts/deploy.sh db
scripts/deploy.sh functions
```

The helper preserves a private 32-byte encryption key and writes
`.secrets/apple-signin.env`. The deployment script installs that file's five
Apple settings when present. Never put Apple private keys in `APP_CONFIG_JSON`.

The client verifies a nonce-bound Apple ID token in a temporary Supabase session.
The `apple-auth` function verifies the same user's identity and authorization
code, then retains the provider refresh token encrypted in a private table.
Only then is the app session persisted. Normal account deletion, including from
other platforms, atomically queues all retained grants for revocation. The
private `apple-revoke` worker retries failures on a five-minute schedule.

Back up the Apple signing key **and** `.secrets/apple-token-encryption.key`.
Replacing the encryption key alone would make existing records unreadable.
After activation, inspect queue age and `last_status` if revocations fail; never
print/decrypt tokens into logs. The migration and functions can be deployed
before Apple setup, but Apple login must stay disabled until setup is complete.

## iOS push

Upload an APNs authentication key and the correct Team/Key IDs to Firebase's
Cloud Messaging settings for the iOS app. APNs credentials are not part of the
repository. Runner has the push entitlement, remote-notification background
mode and early UIScene notification delegate setup. The app uses Firebase
Installation IDs consistently on Android, iOS and web.

## Store listing and review inputs

Prepared Korean/English copy and console URLs are in [STORE_LISTING.md](STORE_LISTING.md).
The existing 512/1024 px icons and rendered feature graphic are exported by
`scripts/store_assets.py` to `output/store/listing/`.

Use the actual app's capabilities and the published privacy/deletion/support
pages. Declare account identifiers, contact data, uploaded files/images,
messages, annotations/schedules, read markers and push device identifiers as
app functionality. The app has no advertising or cross-app tracking. The iOS
privacy manifest records linked functional data; each native SDK supplies its
own manifest too. Review store questionnaire answers against the final build.

Provide a reviewer-accessible team and an allowed sign-in method. The local
`DEV_LOGIN` test credentials never belong in a store release or review notes.
Keep any real review account credentials outside this repository.
