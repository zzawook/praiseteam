// Fills the local stack with a believable team and screenshots the main
// screens on a phone, in light and dark, for design reviews:
//   node e2e/showcase.js <out dir> [label]
// Run against a freshly reset local database (see README).
const { chromium } = require('playwright-core');
const { execSync } = require('child_process');
const crypto = require('crypto');
const OUT = process.argv[2];
const LABEL = process.argv[3] || 'now';
const BASE = 'http://127.0.0.1:3000';
const stamp = Date.now();
const email = `leader${stamp}@praise.local`;

const sql = (q) => execSync(`docker exec -i supabase_db_praiseteam psql -U postgres -d postgres -Atq -v ON_ERROR_STOP=1`, { input: q }).toString().trim();
async function semantics(page) {
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(800);
}
async function waitText(page, text, timeout = 20000) {
  await page.waitForFunction((t) => [...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || e.textContent || '').includes(t)), text, { timeout });
}
async function type(page, label, text) {
  await page.locator(`input[aria-label^="${label}"]`).first().click();
  await page.waitForFunction(() => ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName), null, { timeout: 5000 });
  await page.waitForTimeout(250);
  await page.keyboard.type(text, { delay: 10 });
}
async function signIn(page, { create }) {
  await page.goto(BASE + '/', { waitUntil: 'load' });
  await semantics(page);
  await type(page, '이메일', email);
  await type(page, '비밀번호', 'password123');
  await page.getByRole('button', { name: create ? '계정 만들기' : '로그인', exact: true }).click();
}

function seed(team, leader) {
  const people = [
    ['김하늘', ['싱어']], ['이은혜', ['싱어']], ['박찬양', ['건반']], ['최소망', ['드럼']],
    ['정믿음', ['베이스']], ['한빛나', ['싱어', '세컨건반']],
  ];
  const ids = people.map(() => crypto.randomUUID());
  let q = 'begin;\n';
  people.forEach(([name, parts], i) => {
    q += `insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at) values ('${ids[i]}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo${i}${stamp}@praise.local', '{"full_name":"${name}"}', now(), now());\n`;
    q += `insert into public.team_members (team_id, user_id, role, status, approved_at) values (${team}, '${ids[i]}', 'member', 'active', now());\n`;
    for (const p of parts) q += `insert into public.member_parts (team_id, user_id, part_id) select ${team}, '${ids[i]}', id from public.parts where team_id = ${team} and name = '${p}';\n`;
  });
  q += `update public.profiles set display_name = '서지훈' where id = '${leader}';\n`;
  q += `insert into public.member_parts (team_id, user_id, part_id) select ${team}, '${leader}', id from public.parts where team_id = ${team} and name = '인도';\n`;
  for (const [p, n] of [['인도', 1], ['싱어', 2], ['건반', 1], ['베이스', 1], ['드럼', 1]]) {
    q += `insert into public.default_slots (team_id, part_id, count) select ${team}, id, ${n} from public.parts where team_id = ${team} and name = '${p}';\n`;
  }
  const songs = [
    ['주의 집에 거하는 자', '마커스워십', 'G', 72], ['은혜', '손경민', 'D', 68], ['주님 다시 오실 때까지', '어노인팅', 'A', 76],
    ['나 같은 죄인 살리신', '찬송가 305장', 'G', 70], ['오직 예수 뿐이네', '마커스워십', 'E', 128], ['하나님의 부르심', '제이어스', 'C', 82],
  ];
  for (const [t, a, k, b] of songs) q += `select public.add_song(${team}, '${t}', p_version_name => '${a}', p_key => '${k}', p_bpm => ${b});\n`;
  // a second version of the first song, as teams keep for another arrangement
  q += `insert into public.song_versions (team_id, song_id, name, default_key, bpm) select ${team}, id, '어노인팅', 'A', 76 from public.songs where team_id = ${team} and title = '${songs[0][0]}';\n`;
  const sessions = [
    ['지난 주일 2부 예배', "now() - interval '14 days'", 'published', [1, 4, 5]],
    ['금요 기도회', "date_trunc('day', now()) + interval '2 days 20 hours'", 'published', [3, 2, 6]],
    ['주일 1부 예배', "date_trunc('day', now()) + interval '4 days 9 hours'", 'draft', [5, 1]],
    ['주일 2부 예배', "date_trunc('day', now()) + interval '4 days 11 hours'", 'published', [1, 2, 4, 3]],
    ['청년 연합 집회', "date_trunc('day', now()) + interval '11 days 19 hours'", 'draft', []],
  ];
  sessions.forEach(([title, at, status, items]) => {
    q += `with s as (insert into public.sessions (team_id, title, starts_at, location, setlist_status, published_at, created_by) values (${team}, '${title}', ${at}, '본당', '${status}', ${status === 'published' ? 'now()' : 'null'}, '${leader}') returning id)
      insert into public.setlist_items (team_id, session_id, position, song_id, version_id, key, bpm)
      select ${team}, s.id, x.pos, so.id, so.version_id, so.default_key, so.bpm from s, unnest(array[${items.join(',') || 'null'}]::int[]) with ordinality as x(n, pos)
      join (select distinct on (so.id) so.id, v.id as version_id, v.default_key, v.bpm, dense_rank() over (order by so.id) as n
            from public.songs so join public.song_versions v on v.song_id = so.id where so.team_id = ${team} order by so.id, v.id) so on so.n = x.n;\n`;
  });
  q += `insert into public.session_slots (team_id, session_id, part_id, count) select s.team_id, s.id, d.part_id, d.count from public.sessions s join public.default_slots d on d.team_id = s.team_id where s.team_id = ${team} on conflict do nothing;\n`;
  const assign = (session, part, who, status) => `insert into public.assignments (team_id, session_id, part_id, user_id, status, sent_at, responded_at) select ${team}, s.id, p.id, '${who}', '${status}', case when '${status}' = 'draft' then null else now() end, case when '${status}' in ('accepted','declined') then now() end from public.sessions s, public.parts p where s.team_id = ${team} and s.title = '${session}' and p.team_id = ${team} and p.name = '${part}';\n`;
  q += assign('주일 2부 예배', '인도', leader, 'accepted') + assign('주일 2부 예배', '싱어', ids[0], 'accepted') + assign('주일 2부 예배', '싱어', ids[1], 'pending');
  q += assign('주일 2부 예배', '건반', ids[2], 'accepted') + assign('주일 2부 예배', '드럼', ids[3], 'declined') + assign('주일 2부 예배', '베이스', ids[4], 'accepted');
  q += assign('금요 기도회', '인도', leader, 'accepted') + assign('금요 기도회', '싱어', ids[5], 'pending') + assign('금요 기도회', '건반', ids[2], 'accepted');
  q += assign('청년 연합 집회', '싱어', ids[0], 'draft') + assign('청년 연합 집회', '싱어', ids[5], 'draft') + assign('청년 연합 집회', '드럼', ids[3], 'draft');
  q += `insert into public.announcements (team_id, kind, title, body, pinned, created_by) values (${team}, 'general', '11월 수련회 안내', '11월 셋째 주 금토, 가평에서 해요. 참가 신청은 이번 주까지예요.', true, '${leader}');\n`;
  const team_channel = `(select id from public.channels where team_id = ${team} and kind = 'team')`;
  [[ids[0], '이번 주 콘티 확인했어요! 2부 키 G 맞죠?'], [leader, '네 G로 가요. 브릿지 두 번 하고 엔딩은 키 업해요'], [ids[2], '건반 악보 새로 올려 둘게요 🙏']].forEach(([who, body], i) => {
    q += `insert into public.messages (id, team_id, channel_id, sender_id, body, created_at) values ('${crypto.randomUUID()}', ${team}, ${team_channel}, '${who}', '${body}', now() - interval '${30 - i * 10} minutes');\n`;
  });
  q += 'commit;\n';
  sql(q);
}

const screens = (team, sunday) => [
  ['home', `/t/${team}/home`, '할 일'],
  ['sessions', `/t/${team}/sessions`, '다가오는 예배'],
  ['session', `/t/${team}/sessions/${sunday}`, '콘티'],
  ['songs', `/t/${team}/songs`, '곡'],
  ['rotation', `/t/${team}/rotation`, '로테이션'],
  ['chat', `/t/${team}/chat`, '공지'],
  ['team', `/t/${team}/team`, '초대'],
];

(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
  const setup = await (await browser.newContext({ viewport: { width: 390, height: 844 }, locale: 'ko-KR' })).newPage();
  await signIn(setup, { create: true });
  await waitText(setup, '찬양팀에 들어가기');
  await type(setup, '팀 이름', '청년부 찬양팀');
  await setup.getByRole('button', { name: '만들기', exact: true }).click();
  await waitText(setup, '할 일');
  const team = sql(`select id from public.teams order by id desc limit 1`);
  const leader = sql(`select id from auth.users where email = '${email}'`);
  seed(team, leader);
  const sunday = sql(`select id from public.sessions where team_id = ${team} and title = '주일 2부 예배'`);

  for (const scheme of ['light', 'dark']) {
    const page = await (await browser.newContext({ viewport: { width: 390, height: 844 }, locale: 'ko-KR', colorScheme: scheme, deviceScaleFactor: 2 })).newPage();
    await signIn(page, { create: false });
    await waitText(page, '할 일');
    for (const [name, path, ready] of screens(team, sunday)) {
      await page.goto(BASE + path, { waitUntil: 'load' });
      await semantics(page);
      await waitText(page, ready).catch(() => {});
      await page.waitForTimeout(1500);
      await page.screenshot({ path: `${OUT}/design-${LABEL}-${name}-${scheme}.png` });
    }
    console.log('shots', scheme);
  }
  await browser.close();
})().catch((e) => {
  console.error('SHOWCASE FAILED:', e.message);
  process.exit(1);
});
