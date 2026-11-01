// Service templates on a phone: save one while adding a service, add the
// next service from it (the following week, same time and place), then
// edit, delete and add templates on their own screen. Screenshots go to
// argv[2].
const { chromium } = require('playwright-core');
const SHOTS = process.argv[2];
const BASE = 'http://127.0.0.1:3000';
const stamp = Date.now();

async function open(browser, viewport, name) {
  // The app enters service times in the device's time zone.
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
async function focus(page, label) {
  // Prefix match: a focused empty field adds its hint to the label.
  const input = page.locator(`input[aria-label^="${label}"], textarea[aria-label^="${label}"]`).last();
  await input.click();
  // Flutter attaches its editing element asynchronously after focus.
  await page.waitForFunction(() => ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName), null, { timeout: 5000 });
  await page.waitForTimeout(250);
}
async function type(page, label, text) {
  await focus(page, label);
  await page.keyboard.type(text, { delay: 15 });
}
async function replace(page, label, text) {
  await focus(page, label);
  await page.keyboard.press('Control+A');
  await page.keyboard.type(text, { delay: 15 });
}
async function waitText(page, text, timeout = 20000) {
  await page.waitForFunction((t) => [...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || e.textContent || '').includes(t)), text, { timeout });
}
async function shot(page, name) { await page.waitForTimeout(600); await page.screenshot({ path: `${SHOTS}/${name}.png` }); console.log('shot', name); }
const sql = (q) => require('child_process').execSync(`docker exec supabase_db_praiseteam psql -U postgres -d postgres -Atc "${q.replace(/"/g, '\\"')}"`).toString().trim();
function expectEq(actual, expected, what) {
  if (actual !== expected) throw new Error(`${what}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  console.log('ok', what);
}

let pages = [];
(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
  const a = await open(browser, { width: 390, height: 844 }, 'A');
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
  const services = () => sql(`select string_agg(to_char(starts_at at time zone 'Asia/Singapore', 'Dy HH24:MI') || ' ' || coalesce(location, '-'), ', ' order by starts_at) from public.sessions where team_id = ${team}`);
  const templates = () => sql(`select coalesce(string_agg(title || ' ' || weekday || ' ' || to_char(start_time, 'HH24:MI') || ' ' || coalesce(location, '-'), ', ' order by title), '') from public.session_templates where team_id = ${team}`);

  // the first service (next Sunday 11:00 by default) is kept as a template
  await load(a, `/t/${team}/sessions`);
  await btn(a, '예배 추가').click();
  await type(a, '예배 이름', '주일 2부 예배');
  await type(a, '장소', '본당');
  await a.getByRole('switch', { name: /템플릿으로 저장/ }).or(a.getByRole('checkbox', { name: /템플릿으로 저장/ })).first().click();
  await shot(a, '59-save-as-template-mobile');
  await btn(a, '저장').last().click();
  await waitText(a, '곡을 추가해서 콘티를 만들어요.');
  expectEq(templates(), '주일 2부 예배 7 11:00 본당', 'template saved with the service');

  // picking it fills everything, on the week after the one already planned
  await load(a, `/t/${team}/sessions`);
  await waitText(a, '주일 2부 예배');
  await btn(a, '예배 추가').click();
  await a.getByRole('checkbox', { name: /주일 2부 예배\s+일 오전 11:00/ }).click();
  await a.getByRole('checkbox', { name: /주일 2부 예배\s+일 오전 11:00/, checked: true }).waitFor({ timeout: 5000 });
  await shot(a, '60-template-picked-mobile');
  await btn(a, '저장').last().click();
  await waitText(a, '곡을 추가해서 콘티를 만들어요.');
  expectEq(services(), 'Sun 11:00 본당, Sun 11:00 본당', 'both services on Sunday 11:00 at 본당');
  expectEq(sql(`select max(starts_at) - min(starts_at) from public.sessions where team_id = ${team}`), '7 days', 'the second one a week later');

  // the templates screen: edit the place, delete, add another
  await load(a, `/t/${team}/sessions`);
  await waitText(a, '주일 2부 예배');
  await btn(a, '예배 추가').click();
  await btn(a, '템플릿 편집').click();
  await waitText(a, '일요일 오전 11:00');
  await shot(a, '61-templates-mobile');
  await a.getByRole('button', { name: /주일 2부 예배/ }).last().click();
  await replace(a, '장소', '소예배실');
  await btn(a, '저장').last().click();
  await waitText(a, '소예배실');
  expectEq(templates(), '주일 2부 예배 7 11:00 소예배실', 'template edited');

  await btn(a, '삭제').first().click();
  await btn(a, '삭제').last().click();
  await waitText(a, '매주 같은 요일');
  expectEq(templates(), '', 'template deleted');

  await btn(a, '템플릿 추가').click();
  await type(a, '예배 이름', '금요 기도회');
  await a.getByRole('checkbox', { name: '금', exact: true }).click();
  await btn(a, '저장').last().click();
  await waitText(a, '금요일 오전 11:00');
  expectEq(templates(), '금요 기도회 5 11:00 -', 'template added on its screen');

  // back in the add dialog, the new template is offered
  await btn(a, '뒤로').click();
  await a.getByRole('checkbox', { name: /금요 기도회\s+금 오전 11:00/ }).waitFor({ timeout: 10000 });
  await btn(a, '취소').click();
  expectEq(services().split(', ').length, 2, 'cancelling added nothing');

  await browser.close();
  console.log('TEMPLATES FLOW PASSED');
})().catch(async (e) => {
  console.error('FLOW FAILED:', e.message);
  for (const [name, page] of pages) await page.screenshot({ path: `${SHOTS}/fail-templates-${name}.png` }).catch(() => {});
  process.exit(1);
});
