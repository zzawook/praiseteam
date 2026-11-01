// Offline: services in the next 7 days are kept on the device (setlist,
// sheets with their PDFs, notes). With the connection gone, the stand still
// opens a service this page never loaded, and notes drawn meanwhile go up
// once the connection is back. Screenshots go to argv[2].
const { chromium } = require('playwright-core');
const { execSync } = require('child_process');
const crypto = require('crypto');
const path = require('path');
const SHOTS = process.argv[2];
const BASE = 'http://127.0.0.1:3000';
const stamp = Date.now();

async function open(browser, viewport, name) {
  const context = await browser.newContext({ viewport, locale: 'ko-KR', deviceScaleFactor: 1 });
  const page = await context.newPage();
  page.on('pageerror', (e) => console.log(`[${name}] pageerror`, String(e)));
  page.on('requestfailed', (r) => console.log(`[${name}] failed ${r.method()} ${r.url().split('?')[0]} ${r.failure()?.errorText}`));
  page.on('response', (r) => { if (r.status() >= 400) console.log(`[${name}] HTTP ${r.status()} ${r.request().method()} ${r.url().split('?')[0]}`); });
  page.on('console', (m) => { if (m.type() === 'error' || /offline|outbox/i.test(m.text())) console.log(`[${name}] console ${m.text().slice(0, 300)}`); });
  if (process.env.TRACE) page.on('request', (r) => console.log(`[${name}] > ${r.method()} ${r.url().split('?')[0]}`));
  return page;
}
async function semantics(page) {
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(800);
}
async function load(page, p) {
  await page.goto(BASE + p, { waitUntil: 'load' });
  await semantics(page);
}
const btn = (page, name) => page.getByRole('button', { name, exact: true });
async function type(page, label, text) {
  // Prefix match: a focused empty field adds its hint to the label
  // ("예배 이름\n예: 주일 2부 예배").
  const input = page.locator(`input[aria-label^="${label}"], textarea[aria-label^="${label}"]`).first();
  await input.click();
  await page.waitForFunction(() => ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName), null, { timeout: 5000 });
  await page.waitForTimeout(250);
  await page.keyboard.type(text, { delay: 15 });
}
const labels = (page) => page.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => e.getAttribute('aria-label') || e.textContent || ''));
async function waitText(page, text, timeout = 20000) {
  await page.waitForFunction((t) => [...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || e.textContent || '').includes(t)), text, { timeout });
}
async function waitGone(page, text, timeout = 30000) {
  await page.waitForFunction((t) => ![...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || e.textContent || '').includes(t)), text, { timeout });
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
async function drawLine(page, x1, y1, x2, y2) {
  await page.mouse.move(x1, y1);
  await page.mouse.down();
  for (let i = 1; i <= 12; i++) await page.mouse.move(x1 + ((x2 - x1) * i) / 12, y1 + ((y2 - y1) * i) / 12);
  await page.mouse.up();
  await page.waitForTimeout(300);
}

const repo = path.join(__dirname, '..');
const sql = (q) => execSync(`docker exec supabase_db_praiseteam psql -U postgres -d postgres -Atqc "${q.replace(/"/g, '\\"')}"`).toString().trim();
const env = Object.fromEntries(
  execSync('supabase status -o env', { cwd: repo, stdio: ['ignore', 'pipe', 'ignore'] })
    .toString().split('\n').filter((l) => l.includes('='))
    .map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1).replace(/^"|"$/g, '')]),
);

/** A one-page A4 PDF with a line of text. */
function pdf(text) {
  const content = `BT /F1 40 Tf 72 740 Td (${text}) Tj ET`;
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
    `<< /Length ${content.length} >>\nstream\n${content}\nendstream`,
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  let out = '%PDF-1.4\n';
  const offsets = objects.map((o, i) => { const at = out.length; out += `${i + 1} 0 obj\n${o}\nendobj\n`; return at; });
  const xref = out.length;
  out += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n${offsets.map((o) => `${String(o).padStart(10, '0')} 00000 n \n`).join('')}`;
  out += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(out, 'latin1');
}
async function uploadSheet(team, song, text) {
  const file = pdf(text);
  const storagePath = `${team}/${crypto.randomUUID()}.pdf`;
  const res = await fetch(`${env.API_URL}/storage/v1/object/sheets/${storagePath}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${env.SERVICE_ROLE_KEY}`, 'Content-Type': 'application/pdf' },
    body: file,
  });
  if (!res.ok) throw new Error(`upload failed: ${res.status} ${await res.text()}`);
  return sql(`insert into public.sheets (team_id, song_id, storage_path, page_count, page_sizes, size_bytes) values (${team}, ${song}, '${storagePath}', 1, '[[595, 842]]', ${file.length}) returning id`);
}

let pages = [];
(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
  const a = await open(browser, { width: 390, height: 844 }, 'A');
  const b = await open(browser, { width: 1280, height: 800 }, 'B');
  pages = [['A', a], ['B', b]];

  // A creates the team; B signs up
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

  // Setup by SQL and storage: B is a member; two services this week, each
  // with its own song and PDF; A left a team note on the second one.
  const team = sql(`select id from public.teams order by id desc limit 1`);
  const aId = sql(`select id from auth.users where email = 'a${stamp}@praise.local'`);
  const bId = sql(`select id from auth.users where email = 'b${stamp}@praise.local'`);
  sql(`insert into public.team_members (team_id, user_id, role, status, approved_at) values (${team}, '${bId}', 'member', 'active', now())`);
  const song1 = sql(`insert into public.songs (team_id, title) values (${team}, '주의 집에 거하는 자') returning id`);
  const song2 = sql(`insert into public.songs (team_id, title) values (${team}, '은혜') returning id`);
  const sheet1 = await uploadSheet(team, song1, 'Sheet one');
  const sheet2 = await uploadSheet(team, song2, 'Sheet two');
  const friday = sql(`insert into public.sessions (team_id, title, starts_at) values (${team}, '금요 기도회', now() + interval '2 days') returning id`);
  const sunday = sql(`insert into public.sessions (team_id, title, starts_at) values (${team}, '주일 2부 예배', now() + interval '3 days') returning id`);
  sql(`insert into public.setlist_items (team_id, session_id, position, song_id, sheet_id) values (${team}, ${friday}, 1, ${song1}, ${sheet1})`);
  const item2 = sql(`insert into public.setlist_items (team_id, session_id, position, song_id, sheet_id) values (${team}, ${sunday}, 1, ${song2}, ${sheet2}) returning id`);
  sql(`update public.sessions set setlist_status = 'published', published_at = now() where id in (${friday}, ${sunday})`);
  sql(`insert into public.rehearsals (team_id, session_id, starts_at, location) values (${team}, ${sunday}, now() + interval '2 days 20 hours', '본당 2층')`);
  sql(`insert into public.strokes (id, team_id, session_id, setlist_item_id, sheet_id, page_index, owner_id, visibility, tool, color, width, points) values ('${crypto.randomUUID()}', ${team}, ${sunday}, ${item2}, ${sheet2}, 0, '${aId}', 'team', 'pen', ${0xff2541b2 | 0}, 0.006, '\\x33330040ffcccccd4cff')`);

  // B opens the app: this week's services are kept on the device
  await load(b, `/t/${team}/sessions`);
  await waitText(b, '주일 2부 예배');
  await b.waitForTimeout(4000);

  // A fresh page (nothing in memory); the stand of Friday loads the PDF engine
  await load(b, `/t/${team}/sessions`);
  await waitText(b, '금요 기도회');
  await b.getByText('금요 기도회').or(b.getByRole('button', { name: /금요 기도회/ })).first().click();
  await onSessionPage(b);
  await btn(b, '악보 보기').click();
  await waitText(b, '필기');
  await b.waitForTimeout(2500);
  await btn(b, '닫기').click();
  await waitText(b, '악보 보기');

  // Connection gone. Sunday was never opened on this page.
  await b.context().setOffline(true);
  await btn(b, '뒤로').click();
  await waitText(b, '주일 2부 예배');
  await b.getByText('주일 2부 예배').or(b.getByRole('button', { name: /주일 2부 예배/ })).first().click();
  await onSessionPage(b);
  await waitText(b, '은혜');
  await waitText(b, '오프라인이에요');
  await waitText(b, '본당 2층'); // the rehearsal, kept with the session
  await shot(b, '40-offline-session-desktop');
  await btn(b, '악보 보기').click();
  await waitText(b, '오프라인');
  await waitText(b, '필기');
  await b.waitForTimeout(2500); // PDF render, from the device
  await shot(b, '41-offline-stand-desktop');

  // B draws while offline: kept, waiting
  await btn(b, '필기').click();
  await waitText(b, '나만 보기');
  await drawLine(b, 520, 360, 760, 390);
  await waitText(b, '필기 1개 대기');
  const before = sql(`select count(*) from public.strokes where owner_id = '${bId}'`);
  if (before !== '0') throw new Error(`stroke reached the server while offline? ${before}`);
  await shot(b, '42-offline-note-waiting-desktop');

  // Connection back: the note goes up on its own
  await b.context().setOffline(false);
  await waitGone(b, '필기 1개 대기', 40000);
  const after = sql(`select visibility || ':' || count(*) from public.strokes where owner_id = '${bId}' group by visibility`);
  if (after !== 'private:1') throw new Error(`expected B's private stroke on the server, got ${after}`);
  console.log('after reconnect, B strokes on server:', after);
  await shot(b, '43-back-online-desktop');

  await browser.close();
  console.log('FLOW OFFLINE OK');
})().catch(async (e) => {
  console.error('FLOW FAILED:', e.message);
  for (const [n, p] of pages) {
    await p.screenshot({ path: `${SHOTS}/fail-${n}.png` }).catch(() => {});
    const l = await labels(p).then((x) => x.filter(Boolean).slice(0, 40)).catch(() => []);
    console.error(n, p.url(), JSON.stringify(l));
  }
  process.exit(1);
});
