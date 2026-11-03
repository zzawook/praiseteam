// Read-first service song details for leaders and members. Runs only against
// the isolated demo; YouTube navigation is intercepted, never played remotely.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const playwright = require('playwright-core');
const {open, goto, btn, waitText} = require('../demo/media/browser.cjs');
const base = process.argv[2] || 'http://127.0.0.1:3001';
const engine = process.env.BROWSER || 'chromium';
const out = process.env.DETAILS_SHOTS || `/tmp/praiseteam-setlist-details-${engine}`;

async function details(page) {
  await goto(page, base, '/t/1/sessions/107', '라이브하기');
  await page.getByRole('button', {name: /^1\s+In Jesus Name/}).click();
  await waitText(page, '참고 링크');
  await waitText(page, '선택한 버전: 공유 영상 편곡');
  await page.waitForTimeout(350); // wait for the Flutter sheet entrance animation
  assert.equal(await page.locator('input[aria-label^="BPM"]').count(), 0, 'opening a song must not open editing');
  assert.equal(await btn(page, '저장').count(), 0);
}

(async () => {
  fs.mkdirSync(out, {recursive: true});
  const browser = await playwright[engine].launch({
    headless: true,
    ...(engine === 'chromium' && !process.env.CI ? {executablePath: '/usr/bin/google-chrome'} : {}),
  });
  let page;
  try {
    const errors = [];
    page = await open(browser, null);
    page.on('pageerror', e => errors.push(e.message));
    await details(page);
    await btn(page, '콘티 수정').waitFor();
    await page.screenshot({path: `${out}/leader-details.png`});
    const expectedUrl = await page.evaluate(() => {
      let data = JSON.parse(localStorage.getItem('flutter.praiseteam_demo_data') || localStorage.getItem('praiseteam_demo_data'));
      if (typeof data === 'string') data = JSON.parse(data);
      const item = data.tables.setlist_items.find(row => row.session_id === 107 && row.position === 1);
      return data.tables.song_links.filter(row => row.version_id === item.version_id)
        .sort((a, b) => a.sort_order - b.sort_order)[0].url;
    });
    const context = page.context();
    await context.route(/https:\/\/(?:www\.)?(?:youtube\.com|youtu\.be)\//, route =>
      route.fulfill({contentType: 'text/html', body: '<title>Reference navigation check</title>'}));
    const [reference] = await Promise.all([
      context.waitForEvent('page'),
      page.getByRole('link').first().click(),
    ]);
    await reference.waitForURL(expectedUrl);
    await reference.close();
    await waitText(page, '참고 링크');
    console.log('PASS selected arrangement reference opens in a new tab; service remains open');
    await btn(page, '콘티 수정').click();
    await page.locator('input[aria-label^="BPM"]').waitFor();
    console.log('PASS leaders explicitly choose editing after reading details');

    page = await open(browser, null, {viewport: {width: 390, height: 844}});
    page.on('pageerror', e => errors.push(e.message));
    await goto(page, base, '/t/1/home', '할 일');
    // Change the fictional visitor's role only in this disposable demo context.
    await page.evaluate(() => {
      const key = localStorage.getItem('flutter.praiseteam_demo_data') ? 'flutter.praiseteam_demo_data' : 'praiseteam_demo_data';
      const stored = JSON.parse(localStorage.getItem(key));
      const data = typeof stored === 'string' ? JSON.parse(stored) : stored;
      data.tables.team_members.find(row => row.user_id === '00000000-0000-4000-8000-000000000001').role = 'member';
      localStorage.setItem(key, JSON.stringify(typeof stored === 'string' ? JSON.stringify(data) : data));
    });
    await details(page);
    assert.equal(await btn(page, '콘티 수정').count(), 0, 'members must not get the setlist edit action');
    assert.ok(await page.getByRole('link').count() > 0, 'members get the same references');
    await page.screenshot({path: `${out}/member-phone-details.png`});
    await btn(page, '곡 전체 정보').click();
    await waitText(page, '버전 추가');
    await waitText(page, '공유 영상 편곡');
    console.log('PASS members can read references and navigate to the song library');
    await details(page);
    await btn(page, '악보 보기').last().click();
    await waitText(page, '1 / 5');
    await btn(page, '라이브하기').waitFor();
    assert.equal(await btn(page, '라이브 나가기').count(), 0);
    console.log('PASS sheet action opens the selected song without joining live');
    assert.deepEqual(errors, []);
    console.log(`SETLIST DETAILS FLOW OK (${engine})`);
  } catch (error) {
    if (page) await page.screenshot({path: `${out}/failure.png`}).catch(() => {});
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => {console.error(error); process.exitCode = 1;});
