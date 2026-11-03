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
    });
    // Hold the cold PDF engine download so the progress UI is observable.
    await page.route('**/pdfium.wasm', async route => {
      await pdfReady;
      await route.continue();
    });
    async function song() {
      await page.goto(`${base}/t/1/songs/1`, {waitUntil: 'load'});
      await semantics(page);
      await btn(page, '악보 올리기').first().waitFor();
    }
    async function picker() {
      const choice = page.waitForEvent('filechooser');
      await btn(page, '악보 올리기').first().click();
      return choice;
    }
    async function save(name) {
      await waitText(page, '취소');
      await type(page, '악보 이름', name);
      await btn(page, '악보 올리기').last().click();
      await btn(page, '취소').waitFor({state: 'hidden'});
      await page.waitForFunction(name => [...document.querySelectorAll('flt-semantics')]
        .some(e => e.getAttribute('aria-label')?.startsWith(`${name}\n`)), name);
      // Demo metadata is persisted with a 250 ms debounce after the mutation.
      await page.waitForTimeout(600);
    }

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
    const loadedBefore = loadedPdfs;
    await page.locator('flt-semantics[aria-label^="Safari PDF check"]').click();
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
