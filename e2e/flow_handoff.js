// Isolated fixtures: no reset and no queries against another test's teams.
// Checks team time from a browser in Los Angeles, responsive rotation/song
// artwork, and account deletion through the actual settings UI and worker.
const { chromium } = require('playwright-core');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const shots = process.argv[2] || '/tmp/praiseteam-handoff';
fs.mkdirSync(shots, { recursive: true });
const stamp = Date.now();
const emailA = `handoff-a-${stamp}@praise.local`, emailB = `handoff-b-${stamp}@praise.local`;
const sql = (query) => execFileSync('docker', ['exec', 'supabase_db_praiseteam', 'psql', '-U', 'postgres', '-d', 'postgres', '-Atq', '-v', 'ON_ERROR_STOP=1', '-c', query], { encoding: 'utf8' }).trim();
const env = Object.fromEntries(execFileSync('supabase', ['status', '-o', 'env'], { cwd: root, stdio: ['ignore', 'pipe', 'ignore'], encoding: 'utf8' })
  .split('\n').filter((s) => s.includes('=')).map((s) => [s.slice(0, s.indexOf('=')), s.slice(s.indexOf('=') + 1).replace(/^"|"$/g, '')]));
assert.equal(env.API_URL, 'http://127.0.0.1:54321', 'local backend only');
const api = async (route, method, body, token = env.SERVICE_ROLE_KEY) => {
  const response = await fetch(env.API_URL + route, {
    method, headers: { apikey: env.ANON_KEY, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body == null ? undefined : JSON.stringify(body),
  });
  return response;
};
const button = (page, name) => page.getByRole('button', { name, exact: true });
async function load(page, route) {
  await page.goto('http://127.0.0.1:3000' + route, { waitUntil: 'load' });
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached' });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
}
async function text(page, label) {
  await page.waitForFunction((value) => [...document.querySelectorAll('flt-semantics')]
    .some((e) => (e.getAttribute('aria-label') || e.textContent || '').includes(value)), label, { timeout: 25000 });
}
async function type(page, label, value) {
  await page.locator(`input[aria-label^="${label}"], textarea[aria-label^="${label}"]`).last().click();
  await page.waitForFunction(() => ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName));
  await page.waitForTimeout(250);
  await page.keyboard.type(value, { delay: 10 });
}
async function shot(page, name) {
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(shots, name + '.png') });
}
const teams = [], files = [];
let browser, page;

async function sheet(team, version, owner) {
  const filename = `${team}/handoff-${stamp}.pdf`;
  const response = await fetch(`${env.API_URL}/storage/v1/object/sheets/${filename}`, {
    method: 'POST', headers: { Authorization: `Bearer ${env.SERVICE_ROLE_KEY}`, 'Content-Type': 'application/pdf' },
    body: Buffer.from('%PDF-1.4\n% account deletion fixture\n%%EOF\n'),
  });
  assert.equal(response.status, 200, 'fixture uploaded through Storage API');
  files.push(filename);
  sql(`insert into public.sheets (team_id, version_id, storage_path, page_count, page_sizes, size_bytes, uploaded_by) values (${team}, ${version}, '${filename}', 1, '[[595,842]]', 44, '${owner}')`);
  return filename;
}
async function cleanupWorker() {
  const response = await fetch(`${env.API_URL}/functions/v1/storage-cleanup`, {
    method: 'POST', headers: { Authorization: 'Bearer local-dev-push-secret' },
  });
  assert.equal(response.status, 200, 'storage cleanup worker answered');
}

(async () => {
  try {
    browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
    const context = await browser.newContext({ viewport: { width: 1906, height: 900 }, locale: 'ko-KR', timezoneId: 'America/Los_Angeles', colorScheme: 'dark' });
    page = await context.newPage();
    const errors = [];
    page.on('pageerror', (error) => errors.push(error.message));
    await load(page, '/');
    await type(page, '이메일', emailA);
    await type(page, '비밀번호', 'password123');
    await button(page, '계정 만들기').click();
    await text(page, '찬양팀에 들어가기');
    await type(page, '팀 이름', '찬양팀 화면 확인');
    await button(page, '만들기').click();
    await text(page, '할 일');
    const a = sql(`select id from auth.users where email = '${emailA}'`);
    const team = sql(`select id from public.teams where created_by = '${a}'`);
    teams.push(team);
    sql(`insert into public.default_slots(team_id,part_id,count) select ${team},id,case when name='싱어' then 4 else 1 end from public.parts where team_id=${team} and name not in ('어쿠스틱기타','영상')`);

    await load(page, `/t/${team}/sessions`);
    await button(page, '예배 추가').click();
    await type(page, '예배 이름', '팀 시간 확인');
    await text(page, 'Asia/Singapore');
    await button(page, '저장').last().click();
    await text(page, '팀 시간 확인');
    const service = sql(`select id from public.sessions where team_id=${team}`);
    assert.equal(sql(`select to_char(starts_at at time zone 'Asia/Singapore','HH24:MI') from public.sessions where id=${service}`), '11:00', 'Los Angeles browser saves 11:00 in team time');
    sql(`insert into public.sessions(team_id,title,starts_at) select ${team},'주일 예배',starts_at + n * interval '7 days' from public.sessions cross join generate_series(1,3) n where id=${service}`);
    const song = sql(`select public.add_song(${team},'주의 집에 거하는 자',p_version_name=>'마커스워십',p_key=>'G',p_bpm=>72)`);
    const first = sql(`select id from public.song_versions where song_id=${song}`);
    const second = sql(`insert into public.song_versions(team_id,song_id,name,default_key,bpm) values (${team},${song},'어노인팅','A',76) returning id`);
    sql(`insert into public.song_links(team_id,version_id,url) values (${team},${second},'https://youtu.be/aqz-KE-bpKQ')`);
    const sharedFile = await sheet(team, first, a);

    await load(page, `/t/${team}/rotation`);
    await button(page, '표').click();
    await text(page, '세컨건반');
    await shot(page, 'rotation-desktop');
    const header = await page.getByRole('button', { name: /팀 시간 확인/ }).last().boundingBox();
    assert.ok(header && header.x > 450 && header.width >= 180, 'desktop table is centered and has readable columns');
    await page.setViewportSize({ width: 390, height: 844 });
    await shot(page, 'rotation-mobile');

    await load(page, `/t/${team}/songs`);
    await text(page, '주의 집에 거하는 자');
    await page.waitForTimeout(1500);
    await shot(page, 'songs-mobile');
    await page.setViewportSize({ width: 1280, height: 900 });
    await shot(page, 'songs-desktop');
    await page.getByRole('button', { name: /주의 집에 거하는 자/ }).last().click();
    await text(page, '버전 추가');
    await shot(page, 'song-versions');

    const signup = await api('/auth/v1/signup', 'POST', { email: emailB, password: 'password123' });
    assert.equal(signup.status, 200);
    const b = await signup.json();
    sql(`insert into public.team_members(team_id,user_id,status,approved_at) values (${team},'${b.user.id}','active',now())`);
    await load(page, `/t/${team}/settings`);
    await text(page, '팀 가입'); // wait for the async notification settings
    await page.mouse.move(1000, 700);
    await page.mouse.wheel(0, 1600);
    await page.waitForTimeout(500);
    await button(page, '계정 삭제').click();
    await text(page, '유일한 관리자');
    await shot(page, 'account-transfer-required');
    await button(page, '취소').click();
    sql(`update public.team_members set role='owner' where team_id=${team} and user_id='${b.user.id}'`);
    const solo = sql(`select set_config('request.jwt.claims','{"sub":"${a}"}',false); select public.create_team('혼자 남은 팀')`).split('\n').at(-1);
    teams.push(solo);
    const soloSong = sql(`select public.add_song(${solo},'삭제할 곡')`);
    const soloVersion = sql(`select id from public.song_versions where song_id=${soloSong}`);
    const soloFile = await sheet(solo, soloVersion, a);
    await button(page, '계정 삭제').click();
    await text(page, '혼자 남은 팀');
    await page.getByRole('checkbox').click();
    await shot(page, 'account-confirmation');
    await button(page, '계정 삭제').last().click();
    await page.waitForURL((url) => url.pathname === '/login', { timeout: 20000 });
    assert.equal(sql(`select count(*) from auth.users where id='${a}'`), '0');
    assert.equal(sql(`select count(*) from public.teams where id=${solo}`), '0');
    assert.equal(sql(`select count(*) from public.songs where id=${song}`), '1', 'shared song retained');
    const denied = await api('/functions/v1/storage-cleanup', 'POST', {}, b.access_token);
    assert.equal(denied.status, 401, 'a normal user cannot call the cleanup worker');
    await cleanupWorker();
    assert.equal(sql(`select count(*) from storage.objects where bucket_id='sheets' and name='${soloFile}'`), '0', 'solo PDF physically removed through Storage API');
    assert.equal(sql(`select count(*) from storage.objects where bucket_id='sheets' and name='${sharedFile}'`), '1', 'shared PDF retained');
    const deletion = await api('/rest/v1/rpc/delete_account', 'POST', {}, b.access_token);
    assert.equal(deletion.status, 204, 'remaining test owner deletes own account and team');
    await cleanupWorker();
    assert.deepEqual(errors, [], 'no uncaught browser errors');
    console.log('HANDOFF FLOW PASSED: team time, responsive table, artwork, guarded account deletion and file cleanup');
  } catch (error) {
    await page?.screenshot({ path: path.join(shots, 'failure.png') }).catch(() => {});
    console.error('HANDOFF FLOW FAILED:', error.message);
    process.exitCode = 1;
  } finally {
    await browser?.close();
    if (files.length) await api('/storage/v1/object/sheets', 'DELETE', { prefixes: files });
    if (teams.length) {
      const ids = teams.join(',');
      sql(`delete from public.sessions where team_id in (${ids}); delete from public.songs where team_id in (${ids}); delete from public.teams where id in (${ids})`);
    }
    sql(`delete from auth.users where email in ('${emailA}','${emailB}')`);
    if (files.length) sql(`delete from private.storage_cleanup_queue where storage_path in (${files.map((f) => `'${f}'`).join(',')})`);
  }
})();
