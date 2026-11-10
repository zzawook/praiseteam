// Add document step numbers to untouched app captures. The browser renders
// the original PNG at its original pixel size, then a separate marker layer.
const fs=require('node:fs/promises');
const path=require('node:path');
const crypto=require('node:crypto');
const {chromium}=require('playwright-core');
const {capture}=require('./guide_capture_helpers.cjs');
const root=path.resolve(__dirname,'..');
const source=path.join(root,'output/guide/screenshots');
const out=path.join(root,'docs/guide/screenshots');

(async()=>{
 const guide=JSON.parse(await fs.readFile(path.join(root,'docs/guide/walkthrough.ko.json'),'utf8'));
 await fs.mkdir(out,{recursive:true});
 const browser=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true});
 const context=await browser.newContext({viewport:{width:412,height:820},deviceScaleFactor:2});
 const page=await context.newPage(),manifest=[];
 try {
  for(const [i,chapter] of guide.pages.entries())for(const [j,figure] of (chapter.visuals||[]).entries()){
   const png=await fs.readFile(path.join(source,'raw',figure.source+'.png'));
   if(png.readUInt32BE(16)!==824||png.readUInt32BE(20)!==1640)throw Error('Unexpected capture dimensions: '+figure.source);
   const meta=JSON.parse(await fs.readFile(path.join(source,figure.source+'.json'),'utf8'));
   const name=`page-${String(i+1).padStart(2,'0')}-${j+1}`;
   const markers=figure.marks.map(([old,number])=>{
    const marker=meta.marks.find(m=>m.number===old);if(!marker)throw Error('Missing marker '+figure.source+' '+old);
    const box=figure.boxes?.[old]||{x:marker.x,y:marker.y,width:marker.width,height:marker.height};
    return{number,label:marker.label,box};
   });
   await page.setContent(`<html><head><style>html,body{margin:0;padding:0;width:412px;height:820px;overflow:hidden}img{display:block;width:412px;height:820px}</style></head><body><img src="data:image/png;base64,${png.toString('base64')}"></body></html>`);
   await page.locator('img').evaluate(img=>img.decode());
   await capture(page,out,name,markers);
   // Only final, numbered screenshots belong to the maintained guide.
   await fs.unlink(path.join(out,name+'.json'));
   await fs.unlink(path.join(out,'raw',name+'.png'));
   manifest.push({file:name+'.png',source:figure.source,source_sha256:crypto.createHash('sha256').update(png).digest('hex'),marks:markers});
  }
  await fs.rmdir(path.join(out,'raw'));
  await fs.writeFile(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 }finally{await browser.close();}
 console.log('Prepared',manifest.length,'numbered screenshots');
})().catch(e=>{console.error(e);process.exitCode=1});
