// Each instruction gets one focused crop of an untouched app screenshot.
// Only the crop and its current step marker are rendered here.
const fs=require('node:fs/promises');
const path=require('node:path');
const crypto=require('node:crypto');
const {chromium}=require('playwright-core');
const root=path.resolve(__dirname,'..');

(async()=>{
 const data=JSON.parse(await fs.readFile(path.join(root,'docs/guide/steps.ko.json'),'utf8'));
 const out=path.join(root,'docs/guide/step-images');await fs.mkdir(out,{recursive:true});
 const jobs=data.topics.flatMap(t=>t.steps.map(step=>({...step.image,topic:t.id})));
 // Serialize software-rendered captures: parallel GPU screenshots can capture
 // stale tiles when the crop viewport changes, despite the image being decoded.
 const browser=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--disable-gpu']});
 const context=await browser.newContext({deviceScaleFactor:2});
 const manifest=[];let next=0;
 try {
   while(next<jobs.length){
    const job=jobs[next++],png=await fs.readFile(path.join(root,'docs/guide/source-captures',job.source+'.png'));
    const page=await context.newPage();
    try {
    if(png.readUInt32BE(16)!==824||png.readUInt32BE(20)!==1640)throw Error('Unexpected source dimensions');
    const [x,y,w,h]=job.crop;
    if(x<0||y<0||x+w>412||y+h>820)throw Error('Crop outside source '+job.file);
    await page.setViewportSize({width:w,height:h});
    await page.setContent(`<html><head><style>html,body{margin:0;padding:0;overflow:hidden;width:${w}px;height:${h}px}img{position:absolute;left:${-x}px;top:${-y}px;width:412px;height:820px}</style></head><body><img src="data:image/png;base64,${png.toString('base64')}"></body></html>`);
    await page.locator('img').evaluate(img=>img.decode());
    if(job.box)await page.evaluate(({b,x,y,n})=>{
     const left=b.x-x,top=b.y-y;
     const frame=document.createElement('div');
     frame.style.cssText=`position:absolute;box-sizing:border-box;border:2px solid #c6490a;border-radius:7px;left:${left}px;top:${top}px;width:${b.width}px;height:${b.height}px`;
     const number=document.createElement('div');number.textContent=n;
     number.style.cssText=`position:absolute;display:flex;align-items:center;justify-content:center;width:23px;height:23px;box-sizing:border-box;border:2px solid white;border-radius:50%;background:#c6490a;color:white;font:700 14px Arial,sans-serif;left:${Math.max(0,left-9)}px;top:${Math.max(0,top-13)}px`;
     document.body.append(frame,number);
    },{b:job.box,x,y,n:job.number});
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
    await page.waitForTimeout(80);
    await page.screenshot({path:path.join(out,job.file)});
    manifest.push({file:job.file,topic:job.topic,step:job.number,source:job.source,source_sha256:crypto.createHash('sha256').update(png).digest('hex'),crop:job.crop});
    } finally { await page.close(); }
   }
 }finally{await browser.close();}
 manifest.sort((a,b)=>a.file.localeCompare(b.file));
 await fs.writeFile(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 console.log('Prepared',manifest.length,'screenshots, one per instruction.');
})().catch(e=>{console.error(e);process.exitCode=1});
