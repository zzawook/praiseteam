// Repeated songs must remain distinct occurrences through the real screens,
// publication, ordering, sheet navigation and handwriting. Isolated demo only.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {launch, open, goto, btn, waitText, type, drawEllipse, labels} = require('../demo/media/browser.cjs');
const base = process.argv[2] || 'http://127.0.0.1:3001';
const out = process.env.REPEAT_SHOTS || '/tmp/praiseteam-repeat-songs';
const escape = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

(async () => {
  fs.mkdirSync(out, {recursive: true});
  const browser = await launch();
  let page;
  try {
    page = await open(browser, null, {viewport: {width: 1280, height: 1200}});
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    async function data() {
      return page.evaluate(() => {
        let value = JSON.parse(localStorage.getItem('flutter.praiseteam_demo_data') || localStorage.getItem('praiseteam_demo_data'));
        return typeof value === 'string' ? JSON.parse(value) : value;
      });
    }
    const items = async () => (await data()).tables.setlist_items.filter(r => r.session_id === 107).sort((a,b) => a.position-b.position);
    async function until(check, label) {
      const end = Date.now() + 15000;
      while (Date.now() < end) {
        const value = await items();
        if (check(value)) return value;
        await page.waitForTimeout(100);
      }
      throw new Error(`Timed out: ${label}`);
    }
    await goto(page, base, '/t/1/sessions/107', '라이브하기');
    const initial = await items();
    const original = initial[0];
    const seed = await data();
    const title = seed.tables.songs.find(s => s.id === original.song_id).title;
    const version1 = seed.tables.song_versions.find(v => v.id === original.version_id);
    const version2 = seed.tables.song_versions.find(v => v.song_id === original.song_id && v.id !== original.version_id);
    const row = index => page.getByRole('button', {name: new RegExp(`^${index}\\s+${escape(title)}`)}).first();
    async function add(version, expectedCount) {
      await btn(page, '곡 추가').click();
      const song = page.getByRole('button', {name: new RegExp(`^${escape(title)}(?:\\s|$)`)}).last();
      assert.ok(await song.isEnabled(), 'a song already in the setlist stays selectable');
      await song.click();
      await page.getByRole('button', {name: new RegExp(`^${escape(version.name)}`)}).last().click();
      return (await until(rows => rows.length === expectedCount, 'new occurrence')).at(-1);
    }
    async function edit(index, key, bpm, form, notes) {
      await row(index).click();
      await btn(page, '콘티 수정').click();
      await waitText(page, '콘티에서 빼기');
      await page.getByRole('button', {name: /^키/}).last().click();
      await page.getByRole('menuitem', {name: key, exact: true})
        .or(page.getByRole('option', {name: key, exact: true}))
        .or(page.getByRole('button', {name: key, exact: true})).last().click();
      await type(page, 'BPM', `${bpm}`);
      await type(page, '송폼', form);
      await type(page, '메모', notes);
      await btn(page, '저장').last().click();
      await waitText(page, notes);
      await page.waitForTimeout(400);
    }
    async function publish() {
      await btn(page, '바뀐 내용 공지하기').click();
      await btn(page, '바뀐 내용 공지하기').last().click();
      await page.waitForTimeout(650);
      return (await data()).tables.announcements.find(a => a.session_id === 107);
    }

    const second = await add(version2, initial.length + 1);
    assert.notEqual(second.id, original.id);
    assert.equal(second.song_id, original.song_id);
    assert.equal(second.version_id, version2.id);
    assert.equal(seed.tables.sheets.find(s => s.id === second.sheet_id).version_id, version2.id);
    await edit(5, 'B', 98, '  Chorus x2\nEnding  ', '두 번째 등장만 변경');
    let saved = await items();
    assert.deepEqual(saved.find(r => r.id === original.id), original, 'editing the reprise must not alter the original');
    assert.equal(saved.find(r => r.id === second.id).song_form, '  Chorus x2\nEnding  ');
    let notice = await publish();
    assert.deepEqual(notice.change_summary, {added: [`5. ${title}`]});
    assert.equal(new Set(notice.setlist_snapshot.map(r => r.item_id)).size, 5);
    await edit(5, 'C', 98, '  Chorus x2\nEnding  ', '두 번째 등장만 재수정');
    notice = await publish();
    assert.deepEqual(notice.change_summary, {key_changed: [{title: `5. ${title}`, from: 'B', to: 'C'}]});
    console.log('PASS same song, different version/key/sheet; only the edited occurrence changes');

    const third = await add(version1, 6);
    assert.equal(third.version_id, original.version_id, 'the same version may also repeat');
    assert.equal(third.sheet_id, original.sheet_id);
    await publish();
    // The existing handle is at the top-right of each row. Both rows fit in
    // this desktop viewport; use real pointer dragging, not data mutation.
    const firstBox = await row(1).boundingBox(), lastBox = await row(6).boundingBox();
    assert.ok(firstBox.y > 50 && lastBox.y + lastBox.height < 1100);
    const x = lastBox.x + lastBox.width - 24;
    await page.mouse.move(x, lastBox.y + 24);
    await page.mouse.down();
    await page.mouse.move(x, lastBox.y + 5, {steps: 3});
    await page.mouse.move(x, firstBox.y + 8, {steps: 25});
    await page.waitForTimeout(400);
    await page.mouse.up();
    saved = await until(rows => rows[0].id === third.id, 'reorder identical occurrences');
    notice = await publish();
    assert.deepEqual(notice.change_summary, {reordered: true});
    console.log('PASS identical occurrences reorder by item ID without phantom changes');
    await page.screenshot({path: `${out}/repeated-setlist.png`});

    const sheets = (await data()).tables.sheets;
    const pageCount = item => sheets.find(s => s.id === item.sheet_id)?.page_count || 1;
    const secondIndex = saved.findIndex(r => r.id === second.id);
    const total = saved.reduce((sum,r) => sum+pageCount(r),0);
    const start = saved.slice(0,secondIndex).reduce((sum,r) => sum+pageCount(r),0)+1;
    await row(secondIndex+1).click();
    await btn(page, '악보 보기').last().click();
    await waitText(page, `${start} / ${total}`);
    const beforeInk = (await data()).tables.strokes.map(s => s.id);
    await btn(page, '필기').click();
    await waitText(page, '나만 보기');
    const paper = await page.getByRole('img', {name:'악보 페이지'}).first().boundingBox();
    await drawEllipse(page, paper.x+paper.width*.55, paper.y+paper.height*.4, 24, 15);
    await page.waitForTimeout(700);
    const stroke = (await data()).tables.strokes.find(s => !beforeInk.includes(s.id));
    assert.ok(stroke, 'drawing on the reprise saves a note');
    assert.equal(stroke.setlist_item_id, second.id);
    assert.equal(stroke.sheet_id, second.sheet_id);
    await page.screenshot({path: `${out}/reprise-sheet.png`});
    await btn(page, '닫기').click();
    console.log('PASS selected occurrence opens its own sheet and owns its ink');

    await row(secondIndex+1).click();
    await btn(page, '콘티 수정').click();
    await btn(page, '콘티에서 빼기').click();
    saved = await until(rows => rows.length === 5 && !rows.some(r => r.id === second.id), 'remove only reprise');
    assert.ok(saved.some(r => r.id === original.id) && saved.some(r => r.id === third.id));
    await publish();
    await goto(page, base, '/t/1/sessions/107', '라이브하기');
    assert.equal((await items()).filter(r => r.song_id === original.song_id).length, 2);
    assert.deepEqual(errors, []);
    console.log('PASS removing one occurrence preserves the others after reload');
    console.log('REPEATED SONGS FLOW OK');
  } catch (error) {
    if (page) {
      await page.screenshot({path:`${out}/failure.png`}).catch(()=>{});
      fs.writeFileSync(`${out}/failure-labels.json`, JSON.stringify(await labels(page).catch(()=>[]),null,2));
    }
    throw error;
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
