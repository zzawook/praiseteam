# End-to-end flows

Two browsers (A: laptop size, B: phone size) drive the web build against the
local Supabase stack and assert what each user can see.

| Flow | Covers |
|---|---|
| `flow_m2.js` | sign-up, create team, join by code, approval (deep link), opt in to every setlist, songs, sheet upload (photo -> PDF), sessions, setlist, announcement, notification |
| `flow_m3.js` | annotations: private vs team strokes, live sync to another member |
| `flow_m4.js` | rotation: auto-assign, send, member accepts; the rotation as a table, a cell opening its part of the service |
| `flow_m5.js` | chat: part channels, live messages, polls, announcements, unread markers |
| `flow_m6.js` | live mode: view-only sheets vs one-click live entry from a service, follow page turns, cues, follow off and back on, late joiner and reopening live |
| `flow_offline.js` | offline: this week's services kept on the device; the stand opens a never-opened service without a connection; notes drawn offline upload on reconnect |
| `flow_templates.js` | service templates on a phone: save one while adding a service, add the next service from it (the following free week, same time and place), edit, delete and add templates |
| `flow_versions.js` | song versions: a song added with its first version, a second version on the song's page, the version chosen when adding the song to a setlist (bringing its tempo), and switched in the entry's editor |
| `flow_handoff.js` | team time from a Los Angeles browser; desktop/mobile rotation and song artwork screenshots; last-owner protection, account deletion and Storage API cleanup. Uses isolated fixtures and removes them afterwards; no DB reset needed. Requires `supabase functions serve` with `PUSH_WEBHOOK_SECRET=local-dev-push-secret`. |
| `flow_sheet_upload.js` | browser-only demo, in Chromium and WebKit: delayed file delivery after window focus, visible preparation, PDF save and preview after reload, cancellation/retry, invalid PDFs and photo uploads. No backend or real user files. |
| `flow_setlist_details.js` | browser-only demo, in Chromium and WebKit: leaders and members open song details from the service, selected-arrangement reference opens in a new tab, leader-only editing, full song details, and view-only sheets. YouTube navigation is intercepted locally. |
| `flow_zoom.js` | browser-only demo: zoom the real PDF, draw and persist normalized ink, fit back, pan without page turns, and reopen saved notes without PDF reloads during interaction. Native sample checks also exercise two-finger pinch/eraser cancellation. |
| `showcase.js` | not a test: fills a believable team (members, services, setlists, rotation, chat) and screenshots the main screens on a phone in light and dark, for design reviews (`node e2e/showcase.js <dir> <label>`) |

```sh
# once
npm install
# each run (from the repo root)
supabase db reset --local && docker restart supabase_kong_praiseteam   # clean data
(cd app && flutter build web --dart-define-from-file=env/local.json)
python3 e2e/spa_server.py app/build/web 3000 &                          # serves with SPA fallback
node e2e/flow_m3.js /tmp/shots                                         # screenshots go here
```

Uses the system Chrome (`/usr/bin/google-chrome`) through playwright-core.

The sheet upload regression also runs with Playwright WebKit and an iPhone
viewport. This verifies the browser engine and simulated picker event ordering,
not the real iOS Files/iCloud UI. After building/serving the demo on port 3001:

```sh
(cd e2e && npm ci && npx playwright-core install --with-deps webkit)
BROWSER=webkit node e2e/flow_sheet_upload.js
BROWSER=chromium node e2e/flow_sheet_upload.js
```

## Native mobile smoke test

The Flutter integration test runs the real native screens, SQLite storage and
PDF plugin with the isolated sample team. It covers setlist edits/publication,
song versions, the rota table, unavailable dates, the live stand, annotations,
chat/polls and settings. It does not claim to verify Google/Apple OAuth or push
delivery. Android screenshots are written to `output/native/`.

```sh
cd app
flutter pub get --enforce-lockfile
flutter drive -d emulator-5554 --driver=test_driver/mobile_driver.dart \
  --target=integration_test/mobile_demo_test.dart --dart-define=DEMO_MODE=true
```

The manual `ios-simulator` workflow in root `codemagic.yaml` runs the same suite
on an installed iPhone simulator, then packages the normal sample app (without
the test entry point). It requires no Apple signing credentials and never
publishes to a store. Test screenshots and the Simulator ZIP are build artifacts.

For the real local backend on Android, start the existing Supabase stack and
the disposable emulator, then run `node e2e/run_native.cjs`. It creates its own
test accounts/team and removes them and their uploaded files on completion or
failure. It never resets the database. `app/env/local.android.json` must target
`http://10.0.2.2:54321` with `DEV_LOGIN=true`.

`node e2e/run_native.cjs --device-extras` also drives the real Android system
file picker using the SDK's UI Automator dump and selects only `e2e/sheet.png`.
It verifies network thumbnails, the image-to-PDF upload/preview, native SQLite
offline caching and durable ink upload after reconnecting. A localhost-only TCP
proxy on port 3940 interrupts this test app's backend connection; the actual
Supabase services and the host's network remain running. Port 3939 controls the
disposable fixture/proxy. Run one native suite at a time.

`node e2e/run_native.cjs --listing` captures seven native store screenshots with
the fictional fixture team, without the sample-build banner. For a 9:16 phone
set, set the disposable emulator to 1080×1920 at density 420 first. Captures go
to `output/store/listing/android/`; reset any display overrides when finished.
The runner refreshes locked dependencies before driving the app so the native
integration-test plugin is registered even after a production build.

That suite exercises signup, team creation, approval, last-owner protection,
account deletion, song versions and links, native PDF decoding/Storage, service
templates and publication, rota assignment/response, live page/cue exchange
with a second authenticated client, private/shared ink permissions, realtime
chat, polls, pinned announcements and calendar subscription. The fixture server
depends on the ignored `demo/media/work/seed.json`, produced by
`(cd app && dart run tool/export_demo_data.dart)` from the repository root.

Pages are awaited with `load`, then the text each step expects: the app's local
database runs in a web worker, and Playwright never reports that worker's script
request as finished, so `networkidle` would not come.
