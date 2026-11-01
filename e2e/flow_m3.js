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
    if (body.includes('PGRST303')) {
      const payload = JSON.parse(Buffer.from(auth.split('.')[1], 'base64url').toString());
      const serverDate = Date.parse(r.headers()['date'] || '') / 1000;
      console.log(`[${name}] iat=${payload.iat} server=${serverDate} iat-minus-server=${payload.iat - serverDate}s local=${Math.floor(Date.now() / 1000)}`);
    }
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
// The services tab shows the next service's card ("다음 예배") with its own
// 악보 보기; wait until the session page has replaced it.
async function onSessionPage(page) {
  await page.waitForFunction(() => {
    const texts = [...document.querySelectorAll('flt-semantics')].map((e) => e.getAttribute('aria-label') || e.textContent || '');
    return !texts.some((t) => t.includes('다음 예배')) && texts.some((t) => t.includes('악보 보기'));
  }, null, { timeout: 20000 });
}
async function shot(page, name) { await page.waitForTimeout(600); await page.screenshot({ path: `${SHOTS}/${name}.png` }); console.log('shot', name); }

let pages = [];
(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
  const a = await open(browser, { width: 1280, height: 800 }, 'A');
  const b = await open(browser, { width: 390, height: 844 }, 'B');
  pages = [['A', a], ['B', b]];

  // A: sign up, create team
  await load(a, '/');
  await type(a, '이메일', `a${stamp}@praise.local`);
  await type(a, '비밀번호', 'password123');
  await btn(a, '계정 만들기').click();
  await waitText(a, '찬양팀에 들어가기');
  await shot(a, '02-welcome-desktop');
  await type(a, '팀 이름', '청년부 찬양팀');
  await btn(a, '만들기').click();
  await waitText(a, '할 일');
  const code = require('child_process').execSync(
    `docker exec supabase_db_praiseteam psql -U postgres -d postgres -Atc "select invite_code from public.teams order by id desc limit 1"`,
  ).toString().trim();
  console.log('invite code:', code);
  await shot(a, '03-team-desktop');

  // B: sign up, join with code -> pending
  await load(b, '/');
  await type(b, '이메일', `b${stamp}@praise.local`);
  await type(b, '비밀번호', 'password123');
  await btn(b, '계정 만들기').click();
  await waitText(b, '찬양팀에 들어가기');
  await type(b, '초대 코드', code.toLowerCase());
  await btn(b, '가입하기').click();
  await waitText(b, '승인을 기다리고 있어요');
  await shot(b, '04-pending-mobile');

  // A: sees request (+ live notification badge), approves
  await a.goto(BASE + '/t/1/team', { waitUntil: 'load' });
  await semantics(a);
  await waitText(a, '가입 요청');
  await shot(a, '05-request-desktop');
  await btn(a, '승인').click();
  await waitText(a, '멤버 2명');
  await shot(a, '06-approved-desktop');


  // B: into the team
  await btn(b, '다시 확인').click();
  await waitText(b, '할 일');

  // B serves nowhere yet, so opts in to every setlist in settings
  await load(b, '/t/1/settings');
  await waitText(b, '모든 예배 콘티 받기');
  await b.getByRole('switch', { name: /모든 예배 콘티 받기/ }).or(b.getByRole('checkbox', { name: /모든 예배 콘티 받기/ })).first().click();
  await b.waitForFunction(() => [...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || '').includes('모든 예배 콘티 받기') && ['true', 'mixed'].includes(e.getAttribute('aria-checked') ?? e.querySelector('input')?.checked?.toString())), null, { timeout: 10000 });
  await shot(b, '07-settings-all-setlists-mobile');
  await load(b, '/t/1/sessions');

  // A: add a song with a sheet (photo -> PDF)
  await a.goto(BASE + '/t/1/songs', { waitUntil: 'load' });
  await semantics(a);
  await btn(a, '곡 추가').click();
  await type(a, '곡 이름', '주의 집에 거하는 자');
  await type(a, '가수나 출처', '마커스워십');
  await btn(a, '저장').click();
  await waitText(a, '악보 올리기');
  const [chooser] = await Promise.all([
    a.waitForEvent('filechooser', { timeout: 15000 }),
    btn(a, '악보 올리기').first().click(),
  ]);
  await chooser.setFiles(require('path').join(__dirname, 'sheet.png'));
  await waitText(a, '1쪽');
  await shot(a, '11-upload-dialog-desktop');
  await btn(a, '악보 올리기').last().click();
  await a.waitForFunction(() => [...document.querySelectorAll('flt-semantics')].filter((e) => (e.getAttribute('aria-label') || e.textContent || '').includes('1쪽')).length >= 1, null, { timeout: 30000 });
  await a.waitForTimeout(1500);
  await shot(a, '12-song-detail-desktop');

  // A: create a session, build and announce its setlist
  await a.goto(BASE + '/t/1/sessions', { waitUntil: 'load' });
  await semantics(a);
  await btn(a, '예배 추가').click();
  await type(a, '예배 이름', '주일 2부 예배');
  await btn(a, '저장').click();
  await waitText(a, '곡을 추가해서 콘티를 만들어요.');
  await btn(a, '곡 추가').click();
  await waitText(a, '아직 안 했어요');
  await a.getByText('주의 집에 거하는 자', { exact: true }).or(a.getByRole('button', { name: /주의 집에 거하는 자/ })).first().click();
  await a.waitForTimeout(1500);
  await shot(a, '13-setlist-draft-desktop');
  await btn(a, '콘티 공지하기').first().click();
  await btn(a, '콘티 공지하기').last().click();
  await waitText(a, '공지됨');
  await shot(a, '14-setlist-published-desktop');

  // B: notified, opens the setlist
  await b.reload({ waitUntil: 'load' });
  await semantics(b);
  await b.getByRole('button', { name: /알림/ }).first().click();
  await waitText(b, '주일 2부 예배 콘티');
  await shot(b, '15-notification-mobile');
  await b.getByText('주일 2부 예배 콘티').or(b.getByRole('button', { name: /주일 2부 예배 콘티/ })).first().click();
  await waitText(b, '주의 집에 거하는 자');
  await shot(b, '16-setlist-mobile');


  // ---------------- M3: annotations ----------------
  const sql = (q) => require('child_process').execSync(`docker exec supabase_db_praiseteam psql -U postgres -d postgres -Atc "${q}"`).toString().trim();
  async function drawLine(page, x1, y1, x2, y2) {
    await page.mouse.move(x1, y1);
    await page.mouse.down();
    for (let i = 1; i <= 12; i++) await page.mouse.move(x1 + ((x2 - x1) * i) / 12, y1 + ((y2 - y1) * i) / 12);
    await page.mouse.up();
    await page.waitForTimeout(300);
  }

  // A opens the stand from the session page and draws: one private, one team stroke
  await a.goto(BASE + '/t/1/sessions', { waitUntil: 'load' });
  await semantics(a);
  await a.getByText('주일 2부 예배').or(a.getByRole('button', { name: /주일 2부 예배/ })).first().click();
  await onSessionPage(a);
  await waitText(a, '콘티');
  await a.getByRole('button', { name: '악보 보기' }).click();
  await waitText(a, '필기');
  await a.waitForTimeout(2500); // PDF render
  await btn(a, '필기').click();
  await waitText(a, '나만 보기');
  await drawLine(a, 520, 300, 760, 330);          // private (default target)
  await a.getByRole('button', { name: /팀 공용/ }).first().click();
  await drawLine(a, 520, 420, 760, 450);          // team
  await a.waitForTimeout(1500);
  await shot(a, '17-stand-annotate-desktop');
  console.log('strokes in db:', sql("select visibility || ':' || count(*) from public.strokes group by visibility order by 1"));

  // B opens the same song on the stand: only the team stroke arrives
  let bStrokeRows = null;
  b.on('response', async (r) => {
    if (r.url().includes('/rest/v1/strokes') && r.request().method() === 'GET') {
      try { bStrokeRows = (await r.json()).map((s) => s.visibility); } catch {}
    }
  });
  await b.goto(BASE + '/t/1/stand/1', { waitUntil: 'load' });
  await semantics(b);
  await waitText(b, '필기');
  await b.waitForTimeout(2500);
  console.log('B received strokes:', JSON.stringify(bStrokeRows));
  await shot(b, '18-stand-member-mobile');

  // A draws another team stroke; it shows up on B live
  await drawLine(a, 520, 540, 760, 520);
  await b.waitForTimeout(2500);
  await shot(b, '19-stand-member-live-mobile');
  console.log('strokes in db after live:', sql("select visibility || ':' || count(*) from public.strokes group by visibility order by 1"));

  await browser.close();
  console.log('FLOW M3 OK');
})().catch(async (e) => {
  console.error('FLOW FAILED:', e.message);
  for (const [n, p] of pages) {
    await p.screenshot({ path: `${SHOTS}/fail-${n}.png` }).catch(() => {});
    const labels = await p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => e.getAttribute('aria-label') || '').filter(Boolean).slice(0, 40)).catch(() => []);
    console.error(n, p.url(), JSON.stringify(labels));
  }
  process.exit(1);
});
