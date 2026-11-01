// Song versions: a song added with its first version, a second version
// added on the song's page, the version chosen when the song goes into a
// setlist (bringing its tempo), and switched later in the entry's editor.
// Screenshots go to argv[2].
const { chromium } = require('playwright-core');
const SHOTS = process.argv[2];
const BASE = 'http://127.0.0.1:3000';
const stamp = Date.now();

async function open(browser, viewport, name) {
  const ctx = await browser.newContext({ viewport, locale: 'ko-KR', timezoneId: 'Asia/Singapore', deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => console.log(`[${name}] pageerror`, String(e)));
  page.on('response', async (r) => {
    if (r.status() < 400) return;
    const body = await r.text().catch(() => '');
    console.log(`[${name}] HTTP ${r.status()} ${r.request().method()} ${r.url().split('?')[0]} body=${body.slice(0, 200)}`);
  });
  return page;
}
async function semantics(page) {
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(800);
}
async function load(page, path) {
  await page.goto(BASE + path, { waitUntil: 'load' });
  await semantics(page);
}
const btn = (page, name) => page.getByRole('button', { name, exact: true });
async function type(page, label, text) {
  // Prefix match: a focused empty field adds its hint to the label.
  await page.locator(`input[aria-label^="${label}"], textarea[aria-label^="${label}"]`).last().click();
  // Flutter attaches its editing element asynchronously after focus.
  await page.waitForFunction(() => ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName), null, { timeout: 5000 });
  await page.waitForTimeout(250);
  await page.keyboard.type(text, { delay: 15 });
}
async function waitText(page, text, timeout = 20000) {
  await page.waitForFunction((t) => [...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || e.textContent || '').includes(t)), text, { timeout });
}
async function shot(page, name) { await page.waitForTimeout(600); await page.screenshot({ path: `${SHOTS}/${name}.png` }); console.log('shot', name); }
const sql = (q) => require('child_process').execSync(`docker exec supabase_db_praiseteam psql -U postgres -d postgres -Atqc "${q.replace(/"/g, '\\"')}"`).toString().trim();
function expectEq(actual, expected, what) {
  if (actual !== expected) throw new Error(`${what}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  console.log('ok', what);
}

let pages = [];
(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
  const a = await open(browser, { width: 1280, height: 800 }, 'A');
  pages = [['A', a]];

  await load(a, '/');
  await type(a, '이메일', `a${stamp}@praise.local`);
  await type(a, '비밀번호', 'password123');
  await btn(a, '계정 만들기').click();
  await waitText(a, '찬양팀에 들어가기');
  await type(a, '팀 이름', '청년부 찬양팀');
  await btn(a, '만들기').click();
  await waitText(a, '할 일');
  const team = sql(`select id from public.teams order by id desc limit 1`);
  const entry = () => sql(`select coalesce(v.name, '-') || ' ' || coalesce(si.bpm::text, '-') from public.setlist_items si join public.song_versions v on v.id = si.version_id`);

  // a song with its first version
  await load(a, `/t/${team}/songs`);
  await btn(a, '곡 추가').click();
  await type(a, '곡 이름', '주의 집에 거하는 자');
  await type(a, '가수·버전', '마커스워십');
  await type(a, 'BPM', '72');
  await btn(a, '저장').last().click();
  await waitText(a, '버전 추가');
  expectEq(sql(`select s.title || ' ' || v.name || ' ' || v.bpm from public.songs s join public.song_versions v on v.song_id = s.id`), '주의 집에 거하는 자 마커스워십 72', 'song saved with its first version');

  // a second version on the song's page
  await btn(a, '버전 추가').click();
  await type(a, '가수·버전', '어노인팅');
  await type(a, 'BPM', '76');
  await btn(a, '저장').last().click();
  await waitText(a, '어노인팅');
  await shot(a, '70-song-versions-desktop');
  expectEq(sql(`select string_agg(name || ' ' || bpm, ', ' order by id) from public.song_versions`), '마커스워십 72, 어노인팅 76', 'second version added');

  // into a setlist: choose the version, which brings its tempo
  const session = sql(`insert into public.sessions (team_id, title, starts_at) values (${team}, '주일 2부 예배', now() + interval '3 days') returning id`);
  await load(a, `/t/${team}/sessions/${session}`);
  await btn(a, '곡 추가').click();
  await waitText(a, '아직 안 했어요');
  await a.getByRole('button', { name: /주의 집에 거하는 자/ }).last().click();
  await waitText(a, '어노인팅');
  await shot(a, '71-pick-version-desktop');
  await a.getByRole('button', { name: /어노인팅/ }).last().click();
  await waitText(a, '76 BPM');
  expectEq(entry(), '어노인팅 76', 'the chosen version and its tempo are in the setlist');

  // switch the version for this service in the entry's editor
  await a.getByRole('button', { name: /주의 집에 거하는 자/ }).last().click();
  await waitText(a, '콘티에서 빼기');
  await a.getByRole('button', { name: /^버전/ }).last().click();
  await a.getByRole('menuitem', { name: /마커스워십/ }).or(a.getByRole('option', { name: /마커스워십/ })).or(a.getByRole('button', { name: /^마커스워십/ })).last().click();
  await a.waitForTimeout(500);
  await shot(a, '72-switch-version-desktop');
  await btn(a, '저장').last().click();
  await waitText(a, '72 BPM');
  expectEq(entry(), '마커스워십 72', 'switching brings the other version\'s tempo');

  await browser.close();
  console.log('VERSIONS FLOW PASSED');
})().catch(async (e) => {
  console.error('FLOW FAILED:', e.message);
  for (const [name, page] of pages) {
    await page.screenshot({ path: `${SHOTS}/fail-versions-${name}.png` }).catch(() => {});
    const labels = await page.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((el) => `${el.getAttribute('role') || ''}:${el.getAttribute('aria-label') || el.textContent || ''}`).filter((s) => s.length > 1).slice(0, 60)).catch(() => []);
    console.error(name, page.url(), JSON.stringify(labels));
  }
  process.exit(1);
});
