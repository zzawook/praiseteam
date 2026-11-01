# End-to-end flows

Two browsers (A: laptop size, B: phone size) drive the web build against the
local Supabase stack and assert what each user can see.

| Flow | Covers |
|---|---|
| `flow_m2.js` | sign-up, create team, join by code, approval (deep link), opt in to every setlist, songs, sheet upload (photo -> PDF), sessions, setlist, announcement, notification |
| `flow_m3.js` | annotations: private vs team strokes, live sync to another member |
| `flow_m4.js` | rotation: auto-assign, send, member accepts |
| `flow_m5.js` | chat: part channels, live messages, polls, announcements, unread markers |
| `flow_m6.js` | live mode: follow page turns, cues, follow off and back on, late joiner |

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
