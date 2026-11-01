// Two-user M1 flow against the local stack: create team, join by code,
// approve, pick parts, see notifications. Screenshots go to argv[2].
const { chromium } = require('playwright-core');
const SHOTS = process.argv[2];
const BASE = 'http://127.0.0.1:3000';
const stamp = Date.now();

async function open(browser, viewport, name) {
  const ctx = await browser.newContext({ viewport, locale: 'ko-KR', deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => console.log(`[${name}] pageerror`, String(e)));
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

  // A: rotation -> auto-assign -> send
  await a.goto(BASE + `/t/${team}/rotation`, { waitUntil: 'load' });
  await semantics(a);
  await waitText(a, '주일 2부 예배');
  await a.getByRole('button', { name: /Show menu|메뉴|더보기/ }).last().click().catch(async () => {
    await a.locator('flt-semantics[role=button]').last().click();
  });
  await a.getByRole('menuitem', { name: '자동 배정' }).or(a.getByText('자동 배정')).first().click();
  await waitText(a, '보내기 (1)');
  await shot(a, '20-rotation-draft-desktop');
  await btn(a, '보내기 (1)').first().click();
  await btn(a, '보내기 (1)').last().click();
  await a.waitForTimeout(1500);
  await shot(a, '21-rotation-sent-desktop');
  console.log('after send:', sql(`select status from public.assignments`));

  // B: accepts from "I'm serving"
  await b.goto(BASE + `/t/${team}/sessions`, { waitUntil: 'load' });
  await semantics(b);
  await waitText(b, '내 섬김');
  await shot(b, '22-my-serving-mobile');
  await btn(b, '수락').click();
  await b.waitForTimeout(1500);
  console.log('after accept:', sql(`select status from public.assignments`));
  console.log('B notified:', sql(`select string_agg(category, ',') from public.notifications where user_id = '${bId}'`));
  await shot(b, '23-accepted-mobile');

  // A: the same rotation as a table; a cell opens that part of the service
  const bName = sql(`select display_name from public.profiles where id = '${bId}'`);
  await a.goto(BASE + `/t/${team}/rotation`, { waitUntil: 'load' });
  await semantics(a);
  await waitText(a, '주일 2부 예배');
  await a.getByRole('radio', { name: /^표/ }).or(a.getByRole('button', { name: /^표/ })).or(a.getByRole('checkbox', { name: /^표/ })).first().click();
  await waitText(a, bName);
  await shot(a, '24-rotation-table-desktop');
  await a.locator('flt-semantics').filter({ hasText: bName }).last().click();
  await a.getByRole('button', { name: new RegExp(bName) }).last().waitFor({ timeout: 10000 });
  await shot(a, '25-rotation-cell-desktop');

  await browser.close();
  console.log('FLOW M4 OK');
})().catch(async (e) => {
  console.error('FLOW FAILED:', e.message);
  for (const [n, p] of pages) {
    await p.screenshot({ path: `${SHOTS}/fail-${n}.png` }).catch(() => {});
    const labels = await p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => e.getAttribute('aria-label') || '').filter(Boolean).slice(0, 40)).catch(() => []);
    console.error(n, p.url(), JSON.stringify(labels));
  }
  process.exit(1);
});
