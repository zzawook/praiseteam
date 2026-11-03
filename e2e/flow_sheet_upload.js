// Browser picker regression: Safari may focus the page >500 ms before it
// delivers a file. Use the real picker, PDF engine, app upload and preview.
// The isolated demo stores everything on this test browser, never in production.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const playwright = require('playwright-core');
const {semantics, waitText, btn, type, labels} = require('../demo/media/browser.cjs');

const base = process.argv[2] || 'http://127.0.0.1:3001';
const engine = process.env.BROWSER || 'chromium';
const out = process.env.UPLOAD_SHOTS || `/tmp/praiseteam-upload-${engine}`;
const pdf = path.resolve(__dirname, '../app/assets/demo/demo-chart-1.pdf');
const photo = path.resolve(__dirname, 'sheet.png');

(async () => {
  fs.mkdirSync(out, {recursive: true});
  const browser = await playwright[engine].launch({
    headless: true,
    ...(engine === 'chromium' && !process.env.CI ? {executablePath: '/usr/bin/google-chrome'} : {}),
  });
  let page;
  let releasePdf;
  const pdfReady = new Promise(resolve => { releasePdf = resolve; });
  try {
    const context = await browser.newContext({...playwright.devices['iPhone 13'], locale: 'ko-KR'});
    page = await context.newPage();
    const errors = [];
    let loadedPdfs = 0;
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', message => {
      if (message.text().startsWith('PdfDocument initial load:')) loadedPdfs++;
      if (message.type() === 'error' || message.type() === 'warning') console.log(message.type(), message.text());
    });
    // Hold the cold PDF engine download so the progress UI is observable.
    await page.route('**/pdfium.wasm', async route => {
      await pdfReady;
      await route.continue();
    });
    let songUrl;
    async function demoRow(table, field, value) {
      return page.evaluate(({table, field, value}) => {
        let saved = JSON.parse(localStorage.getItem('flutter.praiseteam_demo_data')
          || localStorage.getItem('praiseteam_demo_data'));
        if (typeof saved === 'string') saved = JSON.parse(saved);
        return saved.tables[table].find(row => row[field] === value);
      }, {table, field, value});
    }
    async function song() {
      await page.goto(songUrl, {waitUntil: 'load'});
      await semantics(page);
      await btn(page, '악보 올리기').first().waitFor();
    }
    async function picker() {
      const button = btn(page, '악보 올리기').first();
      // Flutter canvas scrolling is separate from DOM auto-scroll. Keep this
      // focused fixture short enough to tap above the phone's bottom bar.
      const box = await button.boundingBox();
      assert.ok(box && box.y > 100 && box.y + box.height < page.viewportSize().height - 90,
        'the upload button must be visible in the Flutter viewport');
      const [choice] = await Promise.all([
        page.waitForEvent('filechooser'),
        button.tap(),
      ]);
      return choice;
    }
    async function save(name) {
      await waitText(page, '취소');
      await type(page, '악보 이름', name);
      await btn(page, '악보 올리기').last().click();
      await btn(page, '취소').waitFor({state: 'hidden'});
      await waitText(page, name);
      // Demo metadata is persisted with a 250 ms debounce after the mutation.
      await page.waitForTimeout(600);
    }

    // Use a new song with one empty arrangement. The existing demo song has
    // several sheets/links that can push the upload control behind navigation
    // when a mobile browser restores its viewport after closing a dialog.
    await page.goto(`${base}/t/1/songs`, {waitUntil: 'load'});
    await semantics(page);
    await btn(page, '곡 추가').click();
    await type(page, '곡 이름', 'Safari upload regression');
    await btn(page, '저장').last().click();
    await btn(page, '악보 올리기').waitFor();
    await page.waitForTimeout(600);
    // Imperative GoRouter pushes do not necessarily update the browser URL.
    // Read only our newly created demo fixture's ID from its persisted data.
    const songId = (await demoRow('songs', 'title', 'Safari upload regression')).id;
    songUrl = `${base}/t/1/songs/${songId}`;
    await song();
    const delayedChoice = await picker();
    // This exact ordering discarded the input and silently returned [] before
    // the file arrived. A longer provider/iCloud delay must not mean cancel.
    await page.evaluate(() => window.dispatchEvent(new Event('focus')));
    await page.waitForTimeout(1200);
    assert.equal(await page.locator('input[type=file]').count(), 1, 'focus must not cancel a pending selection');
    await delayedChoice.setFiles(pdf);
    await waitText(page, '악보 준비 중');
    await page.screenshot({path: `${out}/preparing.png`});
    releasePdf();
    await waitText(page, '취소');
    await waitText(page, '2쪽');
    await save('Safari PDF check');
    console.log('PASS delayed focus -> PDF preparation -> saved sheet');

    // Reopening the page verifies the bytes and metadata survived a reload.
    await song();
    const sheet = await demoRow('sheets', 'label', 'Safari PDF check');
    assert.equal(sheet.page_count, 2);
    async function downloadOriginal(suffix) {
      const [download] = await Promise.all([
        page.waitForEvent('download'),
        btn(page, '악보 다운로드').first().tap(),
      ]);
      assert.equal(await download.failure(), null);
      assert.equal(download.suggestedFilename(), 'Safari upload regression - 기본 버전 - Safari PDF check.pdf');
      const savedPath = `${out}/download-${suffix}.pdf`;
      await download.saveAs(savedPath);
      assert.deepEqual(fs.readFileSync(savedPath), fs.readFileSync(pdf), 'download preserves original PDF bytes');
      assert.equal(page.url(), songUrl, 'download keeps the song detail screen open');
      await btn(page, '악보 다운로드').first().waitFor();
    }
    await downloadOriginal('owner');
    console.log('PASS owner downloads the original PDF with a readable filename');

    const loadedBefore = loadedPdfs;
    await page.goto(`${base}/t/1/sheets/${sheet.id}`, {waitUntil: 'load'});
    await semantics(page);
    const deadline = Date.now() + 20000;
    while (loadedPdfs === loadedBefore && Date.now() < deadline) await page.waitForTimeout(100);
    assert.ok(loadedPdfs > loadedBefore, 'the uploaded PDF opens after reload');
    await page.waitForTimeout(1000);
    await page.screenshot({path: `${out}/pdf-preview.png`});
    console.log('PASS stored PDF preview after reload');

    await song();
    await picker();
    await page.locator('input[type=file]').dispatchEvent('cancel');
    await btn(page, '악보 올리기').first().waitFor();
    assert.ok(await btn(page, '악보 올리기').first().isEnabled());
    const retry = await picker();
    await retry.setFiles(pdf);
    await waitText(page, '취소');
    await btn(page, '취소').click();
    // Flutter's semantics update before the modal exit animation stops
    // intercepting taps. Let the real route finish closing before another tap.
    await page.waitForTimeout(350);
    await btn(page, '악보 올리기').first().waitFor();
    console.log('PASS picker cancel, same-file retry and confirmation cancel');

    const invalid = await picker();
    await invalid.setFiles({name: 'invalid.pdf', mimeType: 'application/pdf', buffer: Buffer.from('not a PDF')});
    await waitText(page, '요청을 처리하지 못했어요');
    await btn(page, '악보 올리기').first().waitFor();
    const imageChoice = await picker();
    await imageChoice.setFiles(photo);
    await waitText(page, '취소');
    await save('Safari photo check');
    await page.screenshot({path: `${out}/uploaded-sheets.png`});
    console.log('PASS invalid PDF reports error; next photo upload succeeds');
    // All approved team members who can view a sheet can download it, even
    // when they did not upload it and have no delete action.
    await page.evaluate(id => {
      const key = localStorage.getItem('flutter.praiseteam_demo_data') ? 'flutter.praiseteam_demo_data' : 'praiseteam_demo_data';
      const stored = JSON.parse(localStorage.getItem(key));
      const data = typeof stored === 'string' ? JSON.parse(stored) : stored;
      data.tables.team_members.find(row => row.user_id === '00000000-0000-4000-8000-000000000001').role = 'member';
      data.tables.sheets.filter(row => row.id === id).forEach(row => row.uploaded_by = '00000000-0000-4000-8000-000000000002');
      localStorage.setItem(key, JSON.stringify(typeof stored === 'string' ? JSON.stringify(data) : data));
    }, sheet.id);
    await song();
    await downloadOriginal('member');
    await page.screenshot({path: `${out}/member-download.png`});
    console.log("PASS a member can download another member's sheet");
    assert.deepEqual(errors, []);
    console.log(`SHEET UPLOAD FLOW OK (${engine})`);
  } catch (error) {
    if (page) {
      await page.screenshot({path: `${out}/failure.png`}).catch(() => {});
      const failureLabels = await labels(page).catch(() => ['Browser page unavailable']);
      fs.writeFileSync(`${out}/failure-labels.json`, JSON.stringify(failureLabels, null, 2));
    }
    throw error;
  } finally {
    releasePdf();
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
