// Actual PDF + ink stack in the isolated demo. Touch gesture arbitration is
// covered by widget/native tests; this exercises browser drawing and persistence.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {webkit} = require('playwright-core');
const {launch, open, goto, btn, waitText, drawEllipse} = require('../demo/media/browser.cjs');
const base = process.argv[2] || 'http://127.0.0.1:3001';
const engine = process.env.BROWSER || 'chromium';
const out = process.env.ZOOM_SHOTS || '/tmp/praiseteam-zoom';

async function rows(page) {
  return page.evaluate(() => {
    let saved = JSON.parse(localStorage.getItem('flutter.praiseteam_demo_data') || localStorage.getItem('praiseteam_demo_data'));
    if (typeof saved === 'string') saved = JSON.parse(saved);
    return saved.tables.strokes;
  });
}

(async () => {
  fs.mkdirSync(out, {recursive: true});
  const browser = engine === 'webkit' ? await webkit.launch({headless: true}) : await launch();
  let page;
  try {
    page = await open(browser, null);
    const errors = [];
    let loads = 0;
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.text().startsWith('PdfDocument initial load:')) loads++; });
    await goto(page, base, '/t/1/stand/107', '필기');
    const paper = page.getByRole('img', {name: '악보 페이지'}).first();
    await paper.waitFor();
    await page.waitForTimeout(1500);
    assert.ok(loads > 0);
    const initialLoads = loads;
    const original = await paper.boundingBox();
    const aspect = original.width / original.height;
    const existing = await rows(page);
    const oldIds = existing.map(row => row.id);

    await page.getByRole('button', {name: /^확대/}).first().click();
    await waitText(page, '150%');
    await page.getByRole('button', {name: /^확대/}).first().click();
    await waitText(page, '200%');
    await btn(page, '필기').click();
    await waitText(page, '나만 보기');
    await waitText(page, '200%');
    const enlarged = await paper.boundingBox();
    assert.ok(enlarged.width > original.width * 1.8, 'zoom survives opening the ink toolbar');
    const cx = enlarged.x + enlarged.width / 2, cy = enlarged.y + enlarged.height / 2;
    await drawEllipse(page, cx, cy, 30, 18);
    await page.waitForFunction(ids => {
      let saved = JSON.parse(localStorage.getItem('flutter.praiseteam_demo_data') || localStorage.getItem('praiseteam_demo_data'));
      if (typeof saved === 'string') saved = JSON.parse(saved);
      return saved.tables.strokes.some(row => !ids.includes(row.id));
    }, oldIds);
    const saved = (await rows(page)).find(row => !oldIds.includes(row.id));
    const points = Buffer.from(saved.points.slice(2), 'hex');
    assert.ok(Math.abs(points.readUInt16LE(0) / 65535 - (.5 + 30 / enlarged.width)) < .002);
    assert.ok(Math.abs(points.readUInt16LE(2) / 65535 - .5) < .002);
    const ys = [];
    for (let i = 0; i < points.length; i += 5) ys.push(points.readUInt16LE(i + 2) / 65535);
    assert.ok(Math.abs(Math.max(...ys) - Math.min(...ys) - 36 / (enlarged.width / aspect)) < .003);
    assert.equal(saved.width, .004);
    await page.screenshot({path: `${out}/zoomed-ink.png`});
    await page.getByRole('button', {name: /200%/}).click();
    await waitText(page, '100%');
    await page.waitForTimeout(500);
    assert.equal((await rows(page)).find(row => row.id === saved.id).points, saved.points);
    assert.equal(loads, initialLoads, 'zoom and ink do not reopen the PDF');
    await page.screenshot({path: `${out}/ink-after-fit.png`});
    console.log('PASS zoomed handwriting stores page coordinates and fits back proportionally without reloading PDF');

    await btn(page, '완료').click();
    await page.getByRole('button', {name: /^확대/}).first().click();
    await waitText(page, '150%');
    const beforePan = await paper.boundingBox();
    const x = beforePan.x + beforePan.width / 2, y = beforePan.y + beforePan.height / 2;
    await page.mouse.move(x, y);
    await page.mouse.down();
    await page.mouse.move(x, y + 30, {steps: 12});
    await page.mouse.up();
    await page.waitForTimeout(250);
    await waitText(page, '1 / 5');
    assert.equal((await rows(page)).length, oldIds.length + 1, 'view navigation creates no ink');
    // Accessibility bounds are clipped to the viewport. Verify movement using
    // a real stored point at the viewport center, rather than the clipped top.
    const expectedCenterY = .5 - 30 / (beforePan.width / aspect);
    await btn(page, '필기').click();
    await waitText(page, '나만 보기');
    const panned = await paper.boundingBox();
    await page.mouse.click(panned.x + panned.width / 2, panned.y + panned.height / 2);
    await page.waitForFunction(ids => {
      let data = JSON.parse(localStorage.getItem('flutter.praiseteam_demo_data') || localStorage.getItem('praiseteam_demo_data'));
      if (typeof data === 'string') data = JSON.parse(data);
      return data.tables.strokes.filter(row => !ids.includes(row.id)).length === 2;
    }, oldIds);
    const afterPan = (await rows(page)).find(row => !oldIds.includes(row.id) && row.id !== saved.id);
    const panPoint = Buffer.from(afterPan.points.slice(2), 'hex');
    assert.ok(Math.abs(panPoint.readUInt16LE(2) / 65535 - expectedCenterY) < .003,
      'panning then drawing uses the translated paper coordinates');

    await goto(page, base, '/t/1/stand/107', '필기');
    await paper.waitFor();
    await page.waitForTimeout(1000);
    assert.equal((await rows(page)).find(row => row.id === saved.id).points, saved.points);
    await page.screenshot({path: `${out}/ink-after-reload.png`});
    if (engine === 'chromium') {
      await btn(page, '필기').click();
      await waitText(page, '나만 보기');
      const atFit = await paper.boundingBox();
      const centerX = atFit.x + atFit.width / 2, centerY = atFit.y + atFit.height / 2;
      const countBeforePinch = (await rows(page)).length;
      const touch = await page.context().newCDPSession(page);
      await touch.send('Emulation.setTouchEmulationEnabled', {enabled: true, maxTouchPoints: 5});
      const finger = (id, dx) => ({id, x: centerX + dx, y: centerY});
      await touch.send('Input.dispatchTouchEvent', {type: 'touchStart', touchPoints: [finger(11, -35)]});
      await touch.send('Input.dispatchTouchEvent', {type: 'touchStart', touchPoints: [finger(11, -35), finger(12, 35)]});
      await touch.send('Input.dispatchTouchEvent', {type: 'touchMove', touchPoints: [finger(11, -70), finger(12, 70)]});
      await touch.send('Input.dispatchTouchEvent', {type: 'touchEnd', touchPoints: []});
      await waitText(page, '200%');
      await page.waitForTimeout(600);
      assert.equal((await rows(page)).length, countBeforePinch, 'browser pinch in pen mode leaves no marks');
      await page.screenshot({path: `${out}/touch-pinch.png`});
      await touch.detach();
      console.log('PASS real browser touch pinch in pen mode creates no ink');
    }
    assert.deepEqual(errors, []);
    console.log('PASS zoomed panning keeps the page; saved ink survives a fresh viewer');
    console.log(`ZOOM FLOW OK (${engine})`);
  } catch (error) {
    if (page) await page.screenshot({path: `${out}/failure.png`}).catch(() => {});
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => {console.error(error); process.exitCode = 1;});
