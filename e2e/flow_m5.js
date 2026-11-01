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
  sql(`insert into public.member_parts (team_id, user_id, part_id) select ${team}, '${bId}', id from public.parts where team_id = ${team} and name = '싱어'`);
  sql(`insert into public.default_slots (team_id, part_id, count) select ${team}, id, 1 from public.parts where team_id = ${team} and name = '건반'`);
  sql(`insert into public.sessions (team_id, title, starts_at) values (${team}, '주일 2부 예배', now() + interval '5 days')`);


  // channels by part
  const labels = async (p) => p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => (e.getAttribute('aria-label') || e.textContent || '').trim()).filter(Boolean));
  await a.goto(BASE + `/t/${team}/chat`, { waitUntil: 'load' });
  await semantics(a);
  await waitText(a, '악기팀');
  await b.goto(BASE + `/t/${team}/chat`, { waitUntil: 'load' });
  await semantics(b);
  await waitText(b, '싱어팀');
  const bSees = (await labels(b)).join(' | ');
  console.log('B sees band channel:', bSees.includes('악기팀'));

  // A opens the singers chat; B posts; A sees it live
  await a.getByText('싱어팀').or(a.getByRole('button', { name: /싱어팀/ })).first().click();
  await waitText(a, '첫 메시지를 남겨보세요.');
  await b.getByText('싱어팀').or(b.getByRole('button', { name: /싱어팀/ })).first().click();
  await waitText(b, '첫 메시지를 남겨보세요.');
  await type(b, '메시지', '화음 연습 7시에 해요');
  await b.keyboard.press('Enter');
  await waitText(b, '화음 연습 7시에 해요');
  await waitText(a, '화음 연습 7시에 해요');
  await shot(a, '29-chat-live-desktop');
  await shot(b, '30-chat-mobile');

  // B makes a poll in the team channel; A votes
  await b.goBack({ waitUntil: 'load' }).catch(() => {});
  await b.goto(BASE + `/t/${team}/chat`, { waitUntil: 'load' });
  await semantics(b);
  await b.getByText('전체').or(b.getByRole('button', { name: /전체/ })).first().click();
  await waitText(b, '첫 메시지를 남겨보세요.');
  await b.getByRole('button', { name: '투표 만들기' }).click();
  await type(b, '질문', '회식 언제 할까요?');
  await type(b, '선택지 1', '금요일');
  await type(b, '선택지 2', '토요일');
  await btn(b, '만들기').click();
  await waitText(b, '회식 언제 할까요?');
  await a.goto(BASE + `/t/${team}/chat`, { waitUntil: 'load' });
  await semantics(a);
  await a.getByText('전체').or(a.getByRole('button', { name: /전체/ })).first().click();
  await waitText(a, '회식 언제 할까요?');
  await a.getByRole('button', { name: /토요일/ }).first().click();
  await a.waitForTimeout(1500);
  await shot(a, '31-poll-voted-desktop');
  console.log('votes:', sql(`select o.label || ':' || count(v.*) from public.poll_options o left join public.poll_votes v on v.option_id = o.id group by o.label order by o.label`).replace(/\n/g, ' '));

  // A posts an announcement; B sees it as new
  await a.goto(BASE + `/t/${team}/announcements`, { waitUntil: 'load' });
  await semantics(a);
  await btn(a, '공지 쓰기').click();
  await type(a, '제목', '수련회 신청 마감');
  await btn(a, '저장').click();
  await waitText(a, '수련회 신청 마감');
  await b.goto(BASE + `/t/${team}/chat`, { waitUntil: 'load' });
  await semantics(b);
  await waitText(b, '새 글');
  await shot(b, '32-chat-tab-new-announcement-mobile');
  console.log('announcement notified B:', sql(`select count(*) from public.notifications where category = 'announcement' and user_id = '${bId}'`));
  console.log('chat notifications listed:', sql(`select bool_or(listed) from public.notifications where category = 'chat_message'`));

  await browser.close();
  console.log('FLOW M5 OK');
})().catch(async (e) => {
  console.error('FLOW FAILED:', e.message);
  for (const [n, p] of pages) {
    await p.screenshot({ path: `${SHOTS}/fail-${n}.png` }).catch(() => {});
    const labels = await p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => e.getAttribute('aria-label') || '').filter(Boolean).slice(0, 40)).catch(() => []);
    console.error(n, p.url(), JSON.stringify(labels));
  }
  process.exit(1);
});
