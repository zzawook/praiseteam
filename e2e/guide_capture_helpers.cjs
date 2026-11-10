// Capture real Flutter screens with a separate, removable instruction overlay.
// The underlying app pixels and text are never reconstructed or edited.
const fs = require('node:fs/promises');
const path = require('node:path');
const {btn, labels} = require('../demo/media/browser.cjs');

async function reveal(page, locator) {
  for (let i = 0; i < 12; i++) {
    const box = await locator.boundingBox({timeout:300}).catch(() => null);
    const height = page.viewportSize().height;
    if (box && box.y >= 70 && box.y + box.height <= height - 180) return box;
    await page.mouse.move(210, 500);
    await page.mouse.wheel(0, box && box.y < 70 ? -330 : 330);
    await page.waitForTimeout(220);
  }
  throw new Error('Could not reveal screenshot target');
}

async function capture(page, out, name, marks = []) {
  await fs.mkdir(path.join(out, 'raw'), {recursive:true});
  await page.mouse.move(-20,-20);
  await page.waitForTimeout(500);
  await page.screenshot({path:path.join(out, 'raw', name+'.png')});
  const boxes = [];
  for (const mark of marks) {
    const box = mark.box || await mark.locator.boundingBox({timeout:2000});
    const viewport=page.viewportSize();
    if (!box || box.width <= 0 || box.height <= 0 || box.x < 0 || box.y < 0 || box.x+box.width > viewport.width+1 || box.y+box.height > viewport.height+1) {
      throw new Error(`Screenshot target not visible: ${name} ${mark.number}`);
    }
    boxes.push({number:mark.number, label:mark.label, ...box});
  }
  await page.evaluate(boxes => {
    const layer = document.createElement('div'); layer.id='guide-step-markers';
    layer.style.cssText='position:fixed;inset:0;pointer-events:none;z-index:2147483647';
    for (const box of boxes) {
      const frame=document.createElement('div');
      frame.style.cssText=`position:absolute;box-sizing:border-box;border:2px solid #d95b17;border-radius:8px;left:${box.x}px;top:${box.y}px;width:${box.width}px;height:${box.height}px`;
      const badge=document.createElement('div'); badge.textContent=String(box.number);
      badge.style.cssText=`position:absolute;display:flex;align-items:center;justify-content:center;box-sizing:border-box;width:25px;height:25px;border-radius:50%;border:2px solid white;background:#c6490a;color:white;font:700 16px Arial,sans-serif;left:${Math.max(1,box.x-10)}px;top:${Math.max(2,box.y-14)}px;box-shadow:0 1px 3px #0006`;
      layer.append(frame,badge);
    }
    document.body.append(layer);
  }, boxes);
  try { await page.screenshot({path:path.join(out,name+'.png')}); }
  finally { await page.evaluate(()=>document.getElementById('guide-step-markers')?.remove()); }
  await fs.writeFile(path.join(out,name+'.json'),JSON.stringify({viewport:page.viewportSize(),marks:boxes,labels:await labels(page)},null,2));
  console.log('Captured',name);
}

module.exports={capture,reveal,btn};
