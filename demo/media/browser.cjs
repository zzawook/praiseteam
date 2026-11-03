const {chromium}=require('../../e2e/node_modules/playwright-core');
const fs=require('node:fs');
const path=require('node:path');
const work=path.join(__dirname,'work');
const btn=(p,name)=>p.getByRole('button',{name,exact:true});
const labels=p=>p.evaluate(()=>[...document.querySelectorAll('flt-semantics')].map(e=>e.getAttribute('aria-label')||e.textContent||'').filter(Boolean));
async function waitText(p,text,timeout=25000){await p.waitForFunction(t=>[...document.querySelectorAll('flt-semantics,input,textarea')].some(e=>(e.getAttribute('aria-label')||e.textContent||'').includes(t)),text,{timeout});}
async function semantics(p){await p.waitForSelector('flt-semantics-placeholder',{state:'attached',timeout:45000});await p.evaluate(()=>document.querySelector('flt-semantics-placeholder')?.click());await p.waitForTimeout(600);}
async function goto(p,base,route,ready){await p.goto(base+route,{waitUntil:'load'});await semantics(p);if(ready)await waitText(p,ready);await p.waitForTimeout(800);}
async function type(p,label,value){const field=p.locator(`input[aria-label^="${label}"],textarea[aria-label^="${label}"]`).first();await field.click();await p.waitForTimeout(200);await p.keyboard.press('Control+A');await p.keyboard.type(value,{delay:35});}
async function draw(p,x,y,x2,y2){await p.mouse.move(x,y);await p.mouse.down();for(let i=1;i<=24;i++)await p.mouse.move(x+(x2-x)*i/24,y+(y2-y)*i/24,{steps:2});await p.mouse.up();}
async function drawPath(p,points){await p.mouse.move(...points[0]);await p.mouse.down();for(const point of points.slice(1))await p.mouse.move(...point,{steps:2});await p.mouse.up();}
async function drawEllipse(p,cx,cy,rx,ry){const points=Array.from({length:49},(_,i)=>{const angle=i*Math.PI*2/48;return[cx+Math.cos(angle)*rx,cy+Math.sin(angle)*ry]});await drawPath(p,points);}
async function launch(){return chromium.launch({executablePath:process.env.CI?undefined:'/usr/bin/google-chrome',headless:true,args:['--disable-dev-shm-usage']});}
async function open(browser,session,options={}){
 const context=await browser.newContext({viewport:{width:1280,height:800},locale:'ko-KR',colorScheme:'light',...options});
 if(session)await context.addInitScript(s=>{if(!localStorage.getItem('film-auth-initialized')){localStorage.setItem('sb-127-auth-token',JSON.stringify(s));localStorage.setItem('film-auth-initialized','1');}},session);
 const page=await context.newPage();page.on('pageerror',e=>console.error('UI ERROR:',e.stack||e.message));return page;
}
async function probe(){
 const fixture=await require('./backend.cjs').prepare();const browser=await launch();
 try{const p=await open(browser,fixture.sessions[0]);
 const routes=[['home',`/t/${fixture.team}/home`,'할 일'],['songs',`/t/${fixture.team}/songs`,'In Jesus Name'],['song',`/t/${fixture.team}/songs/${fixture.song}`,'버전'],['setlist',`/t/${fixture.team}/sessions/${fixture.service}`,'라이브하기'],['rotation',`/t/${fixture.team}/rotation`,'로테이션'],['chat',`/t/${fixture.team}/chat/${fixture.channel}`,'투표']];
 for(const [name,route,ready]of routes){await goto(p,'http://127.0.0.1:3002',route,ready);fs.writeFileSync(path.join(work,name+'-labels.json'),JSON.stringify(await labels(p),null,2));await p.screenshot({path:path.join(work,name+'.png')});console.log('Ready:',name);}
 await goto(p,'http://127.0.0.1:3002',`/t/${fixture.team}/sessions/${fixture.service}`,'라이브하기');await btn(p,'라이브하기').click();await waitText(p,'1명 함께');await p.waitForTimeout(2000);fs.writeFileSync(path.join(work,'live-labels.json'),JSON.stringify(await labels(p),null,2));await p.screenshot({path:path.join(work,'live.png')});console.log('Ready: live');
 }finally{await browser.close();await fixture.cleanup();}
}
module.exports={launch,open,goto,semantics,btn,labels,waitText,type,draw,drawPath,drawEllipse,work};
if(require.main===module)probe().catch(e=>{console.error(e);process.exitCode=1});
