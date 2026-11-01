# Environments

Run with `--dart-define-from-file=env/<name>.json`:

| File | Backend | Use |
|---|---|---|
| `local.json` | local Supabase (`supabase start`) | web (`flutter run -d chrome --web-port 3000`) |
| `local.android.json` | local Supabase via the emulator host alias `10.0.2.2` | Android emulator |
| `prod.json` | hosted project (Singapore) | release builds |

These files are git-ignored; copy `example.json` to create one.
