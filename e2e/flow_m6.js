// Two-user live flow against the local stack, including direct live entry
// from a service and a separate view-only path. Screenshots go to argv[2].
const { chromium } = require('playwright-core');
const SHOTS = process.argv[2];
const BASE = 'http://127.0.0.1:3000';
const stamp = Date.now();
const pageErrors = [];

async function open(browser, viewport, name) {
  const ctx = await browser.newContext({ viewport, locale: 'ko-KR', deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => { pageErrors.push(String(e)); console.log(`[${name}] pageerror`, String(e)); });
  page.on('response', async (r) => {
    if (r.status() < 400) return;
    const auth = (await r.request().allHeaders())['authorization'] || '';
    const body = await r.text().catch(() => '');
    console.log(`[${name}] HTTP ${r.status()} ${r.request().method()} ${r.url().split('?')[0]} auth=${auth.slice(0, 22)} body=${body.slice(0, 200)}`);
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
  // Prefix match: a focused empty field adds its hint to the label
  // ("예배 이름\n예: 주일 2부 예배").
  const input = page.locator(`input[aria-label^="${label}"], textarea[aria-label^="${label}"]`).first();
  await input.click();
  // Flutter attaches its editing element asynchronously after focus.
  await page.waitForFunction(() => ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName), null, { timeout: 5000 });
  await page.waitForTimeout(250);
  await page.keyboard.type(text, { delay: 15 });
}
async function waitText(page, text, timeout = 20000) {
  await page.waitForFunction((t) => [...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || e.textContent || '').includes(t)), text, { timeout });
}
async function shot(page, name) { await page.waitForTimeout(600); await page.screenshot({ path: `${SHOTS}/${name}.png` }); console.log('shot', name); }


let pages = [];
const sql = (q) => require('child_process').execSync(`docker exec supabase_db_praiseteam psql -U postgres -d postgres -Atc "${q.replace(/"/g, '\\"')}"`).toString().trim();
(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
  const a = await open(browser, { width: 1280, height: 800 }, 'A');
  const b = await open(browser, { width: 390, height: 844 }, 'B');
  pages = [['A', a], ['B', b]];

  // sign up both; A creates the team
  await load(a, '/');
  await type(a, '이메일', `a${stamp}@praise.local`);
  await type(a, '비밀번호', 'password123');
  await btn(a, '계정 만들기').click();
  await waitText(a, '찬양팀에 들어가기');
  await type(a, '팀 이름', '청년부 찬양팀');
  await btn(a, '만들기').click();
  await waitText(a, '할 일');

  await load(b, '/');
  await type(b, '이메일', `b${stamp}@praise.local`);
  await type(b, '비밀번호', 'password123');
  await btn(b, '계정 만들기').click();
  await waitText(b, '찬양팀에 들어가기');

  // setup by SQL: B joins as active member playing keys; keys need 1; a service in 5 days
  const team = sql(`select id from public.teams order by id desc limit 1`);
  const bId = sql(`select id from auth.users where email = 'b${stamp}@praise.local'`);
  sql(`insert into public.team_members (team_id, user_id, role, status, approved_at) values (${team}, '${bId}', 'member', 'active', now())`);
  sql(`insert into public.member_parts (team_id, user_id, part_id) select ${team}, '${bId}', id from public.parts where team_id = ${team} and name = '건반'`);
  sql(`insert into public.default_slots (team_id, part_id, count) select ${team}, id, 1 from public.parts where team_id = ${team} and name = '건반'`);
  sql(`insert into public.sessions (team_id, title, starts_at) values (${team}, '주일 2부 예배', now() + interval '5 days')`);


  // a published setlist with two songs (no sheets: one stand page each)
  const session = sql(`select id from public.sessions where team_id = ${team} order by id desc limit 1`);
  sql(`select public.add_song(${team}, '주의 집에 거하는 자'), public.add_song(${team}, '은혜')`);
  sql(`insert into public.setlist_items (team_id, session_id, position, song_id, version_id) select ${team}, ${session}, row_number() over (order by v.song_id), v.song_id, v.id from public.song_versions v where v.team_id = ${team}`);
  sql(`update public.sessions set setlist_status = 'published', published_at = now() where id = ${session}`);

  // the stand header reads "<title>\n<page> / <pages>"
  const headerText = (p) => p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => (e.getAttribute('aria-label') || '').match(/(\d+ \/ \d+)/)).find(Boolean)?.[1] || '');

  // The setlist's view-only action opens the stand without joining live.
  await load(a, `/t/${team}/sessions/${session}`);
  await btn(a, '악보 보기').click();
  await waitText(a, '1 / 2');
  await btn(a, '라이브하기').waitFor();
  if (await btn(a, '라이브 나가기').count()) throw new Error('Viewing sheets joined live mode');
  await btn(a, '닫기').click();

  // The primary action on the service page opens the stand already live.
  for (const p of [a, b]) {
    await load(p, `/t/${team}/sessions/${session}`);
    await btn(p, '라이브하기').click();
    await waitText(p, '1 / 2');
  }
  await waitText(a, '2명 함께');
  await waitText(b, '2명 함께');
  await shot(a, '33-live-joined-desktop');

  // A turns the page with the pedal (right arrow); B follows
  await a.keyboard.press('ArrowRight');
  await waitText(a, '2 / 2');
  await waitText(b, '2 / 2');
  if (await headerText(b) !== '2 / 2') throw new Error('B did not follow A');
  await shot(b, '34-live-followed-mobile');

  // B sends a cue to everyone; A sees the banner
  // one tap on B's cue strip; A sees the banner with B's name (A's own cue
  // rail also reads 한 번 더, so the sender's name is what proves arrival)
  await btn(b, '한 번 더').click();
  await waitText(a, `b${stamp}`);
  await shot(a, '35-live-cue-desktop');

  // B stops following; A turns back; B stays
  await b.getByRole('switch').or(b.getByRole('checkbox')).first().click();
  await b.waitForTimeout(500);
  await a.keyboard.press('ArrowLeft');
  await waitText(a, '1 / 2');
  await b.waitForTimeout(2500);
  const stayed = await headerText(b);
  if (stayed !== '2 / 2') throw new Error(`B moved with follow off: ${stayed}`);
  console.log('B with follow off stays on', stayed);

  // B follows again: back to where the group is
  await b.getByRole('switch').or(b.getByRole('checkbox')).first().click();
  await waitText(b, '1 / 2');

  // late joiner: B leaves, A turns, B comes back and lands on A's page
  await btn(b, '라이브 나가기').click();
  await waitText(a, '1명 함께');
  await a.keyboard.press('ArrowRight');
  await waitText(a, '2 / 2');
  await b.waitForTimeout(1500);
  if (await headerText(b) !== '1 / 2') throw new Error('B moved while out of live mode');
  await btn(b, '라이브하기').click();
  await waitText(b, '2명 함께');
  await waitText(b, '2 / 2');
  console.log('late joiner landed on', await headerText(b));

  // B closes the stand without leaving live mode: B leaves live with it
  await btn(b, '닫기').click();
  await waitText(a, '1명 함께');
  console.log('closing the stand left live mode');

  // Reopening from the service starts a fresh stand and follows the group.
  await btn(b, '라이브하기').click();
  await waitText(b, '2명 함께');
  await waitText(b, '2 / 2');
  console.log('one-click late joiner followed the current page');

  if (pageErrors.length) throw new Error(`Uncaught browser errors: ${pageErrors.join('; ')}`);
  await browser.close();
  console.log('FLOW M6 OK');
})().catch(async (e) => {
  console.error('FLOW FAILED:', e.message);
  for (const [n, p] of pages) {
    await p.screenshot({ path: `${SHOTS}/fail-${n}.png` }).catch(() => {});
    const labels = await p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => e.getAttribute('aria-label') || '').filter(Boolean).slice(0, 40)).catch(() => []);
    console.error(n, p.url(), JSON.stringify(labels));
  }
  process.exit(1);
});
