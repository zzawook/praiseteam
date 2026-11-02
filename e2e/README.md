# End-to-end flows

Two browsers (A: laptop size, B: phone size) drive the web build against the
local Supabase stack and assert what each user can see.

| Flow | Covers |
|---|---|
| `flow_m2.js` | sign-up, create team, join by code, approval (deep link), opt in to every setlist, songs, sheet upload (photo -> PDF), sessions, setlist, announcement, notification |
| `flow_m3.js` | annotations: private vs team strokes, live sync to another member |
| `flow_m4.js` | rotation: auto-assign, send, member accepts; the rotation as a table, a cell opening its part of the service |
| `flow_m5.js` | chat: part channels, live messages, polls, announcements, unread markers |
| `flow_m6.js` | live mode: follow page turns, cues, follow off and back on, late joiner |
| `flow_offline.js` | offline: this week's services kept on the device; the stand opens a never-opened service without a connection; notes drawn offline upload on reconnect |
| `flow_templates.js` | service templates on a phone: save one while adding a service, add the next service from it (the following free week, same time and place), edit, delete and add templates |
| `flow_versions.js` | song versions: a song added with its first version, a second version on the song's page, the version chosen when adding the song to a setlist (bringing its tempo), and switched in the entry's editor |
| `flow_handoff.js` | team time from a Los Angeles browser; desktop/mobile rotation and song artwork screenshots; last-owner protection, account deletion and Storage API cleanup. Uses isolated fixtures and removes them afterwards; no DB reset needed. Requires `supabase functions serve` with `PUSH_WEBHOOK_SECRET=local-dev-push-secret`. |
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

Pages are awaited with `load`, then the text each step expects: the app's local
database runs in a web worker, and Playwright never reports that worker's script
request as finished, so `networkidle` would not come.
