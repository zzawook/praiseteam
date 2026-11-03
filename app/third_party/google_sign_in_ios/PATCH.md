# Native SDK compatibility patch

Source: `google_sign_in_ios` 6.3.8 from pub.dev, published by the Flutter team.
The upstream BSD license is retained in `LICENSE`.

The first Codemagic build failed because the plugin requires GoogleSignIn 9,
whose GTMSessionFetcher constraint conflicts with Firebase Apple SDK 13.1.1.
[GoogleSignIn 10.1.0](https://github.com/google/GoogleSignIn-iOS/releases/tag/10.1.0)
explicitly adds Firebase 13 / AppCheckCore 12 compatibility.

Only the native dependency manifests are patched: GoogleSignIn is pinned to
10.1.0 and its minimum OS versions are reflected (iOS 15, macOS 12). Dart and
Swift bridge implementations are unchanged. Example and upstream test projects
are omitted from this application-local copy.

Remove the override when an upstream Flutter plugin release supports this SDK,
and rerun the Codemagic simulator workflow and a real Google sign-in on iOS.
