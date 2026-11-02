// Records the real app against an isolated, local Supabase fixture.
// The live chapter asserts two-user page following; notes assert offline replay.
const fs=require('node:fs');const path=require('node:path');const assert=require('node:assert/strict');const {execFileSync}=require('node:child_process');
const {launch,open,goto,btn,waitText,type,draw,labels,work}=require('./browser.cjs');
const base='http://127.0.0.1:3002';const raw=path.join(work,'raw');fs.mkdirSync(raw,{recursive:true});
const metaPath=path.join(work,'clips.json');const clips=fs.existsSync(metaPath)?JSON.parse(fs.readFileSync(metaPath)):{};
const only=process.argv.slice(2);const wanted=n=>!only.length||only.includes(n);
const sleep=(p,s)=>p.waitForTimeout(s*1000);
const sql=q=>execFileSync('docker',['exec','-i','supabase_db_praiseteam','psql','-U','postgres','-d','postgres','-Atq','-v','ON_ERROR_STOP=1'],{input:q,encoding:'utf8'}).trim();
(async()=>{
 const f=await require('./backend.cjs').prepare();const browser=await launch();let current;
 const route=s=>`/t/${f.team}/${s}`;
 async function camera(session=f.sessions[0],width=1280,height=800){const started=Date.now();const p=await open(browser,session,{viewport:{width,height},recordVideo:{dir:raw,size:{width,height}}});return {p,started,width,height};}
 async function finish(name,c,start){await c.p.context().close();const file=await c.p.video().path();clips[name]={file,start:(start-c.started)/1000,width:c.width,height:c.height};fs.writeFileSync(metaPath,JSON.stringify(clips,null,2));console.log('RECORDED',name);}
 async function chapter(name,url,ready,action){if(!wanted(name))return;const c=await camera();current=c.p;await goto(c.p,base,url,ready);await sleep(c.p,1);const start=Date.now();await action(c.p);await sleep(c.p,Math.max(0,(start+23000-Date.now())/1000));await c.p.screenshot({path:path.join(work,`${name}-end.png`)});await finish(name,c,start);}
 try{
  await chapter('home',route('home'),'할 일',async p=>{await sleep(p,3);await btn(p,'수락').click();await sleep(p,2);await btn(p,'참석').first().click();await sleep(p,3);await p.mouse.move(1090,665);await p.mouse.wheel(0,460);await sleep(p,4);await p.mouse.wheel(0,-220);});
  await chapter('songs',route('songs'),'In Jesus Name',async p=>{await sleep(p,4);await p.getByRole('button',{name:/In Jesus Name/}).first().click();await waitText(p,'팀 편곡');await sleep(p,5);await p.mouse.move(1020,630);await p.mouse.wheel(0,310);await sleep(p,4);await p.mouse.wheel(0,-200);});
  await chapter('setlist',route(`sessions/${f.service}`),'라이브하기',async p=>{await sleep(p,3);await p.getByRole('button',{name:/^1\s+In Jesus Name/}).click();await waitText(p,'송폼');await sleep(p,3);await type(p,'BPM','108');await type(p,'메모','마지막 후렴 두 번, 다 함께 마무리');await btn(p,'저장').click();await sleep(p,2);await btn(p,'바뀐 내용 공지하기').click();await sleep(p,1);await btn(p,'바뀐 내용 공지하기').last().click();await sleep(p,2);});
  await chapter('rotation',route('rotation'),'로테이션',async p=>{await sleep(p,2);await btn(p,'표').click();await sleep(p,7);await btn(p,'불가능 날짜').click();await waitText(p,'불가능 날짜');await sleep(p,5);await btn(p,'뒤로').click();});
  await chapter('chat',route(`chat/${f.channel}`),'다음 팀 모임',async p=>{await sleep(p,3);await type(p,'메시지','토요일 합주 때 함께 맞춰봐요!');await btn(p,'보내기').click();await sleep(p,3);await p.getByRole('button',{name:/토요일 점심/}).click();await waitText(p,'3표');await sleep(p,4);});
  if(wanted('live')){
   const a=await camera(f.sessions[0],860,800),b=await camera(f.sessions[1],860,800);current=a.p;
   await Promise.all([goto(a.p,base,route(`sessions/${f.service}`),'라이브하기'),goto(b.p,base,route(`sessions/${f.service}`),'라이브하기')]);
   const start=Date.now();await sleep(a.p,1);
   await Promise.all([btn(a.p,'라이브하기').click(),btn(b.p,'라이브하기').click()]);
   await Promise.all([waitText(a.p,'2명 함께'),waitText(b.p,'2명 함께')]);console.log('VERIFIED two real participants');
   await sleep(a.p,3);await a.p.keyboard.press('ArrowRight');await waitText(b.p,'2 / 5');console.log('VERIFIED remote page follow');
   await sleep(a.p,2);await btn(b.p,'한 번 더').click();await waitText(a.p,'김하늘');console.log('VERIFIED remote cue');
   await sleep(a.p,3);await b.p.getByRole('switch').click();await a.p.keyboard.press('ArrowRight');await waitText(a.p,'3 / 5');await waitText(b.p,'2 / 5');console.log('VERIFIED follow can be disabled');
   await sleep(a.p,Math.max(0,(start+23000-Date.now())/1000));
   await a.p.screenshot({path:path.join(work,'live-a-end.png')});await b.p.screenshot({path:path.join(work,'live-b-end.png')});
   await finish('live-a',a,start);await finish('live-b',b,start);
  }
  await chapter('notes',route(`stand/${f.service}`),'필기',async p=>{
   await btn(p,'필기').click();await waitText(p,'나만 보기');await sleep(p,3);
   await draw(p,520,342,730,355);await sleep(p,2);
   const uid=f.sessions[0].user.id;const count=()=>Number(sql(`select count(*) from public.strokes where owner_id='${uid}' and session_id=${f.service}`));const before=count();
   await p.context().setOffline(true);await draw(p,530,465,760,470);await waitText(p,'필기 1개 대기');assert.equal(count(),before);console.log('VERIFIED offline ink remains local');
   await sleep(p,3);await p.context().setOffline(false);
   await p.waitForFunction(()=>![...document.querySelectorAll('flt-semantics')].some(e=>(e.getAttribute('aria-label')||e.textContent||'').includes('필기 1개 대기')),null,{timeout:40000});
   assert.equal(count(),before+1);console.log('VERIFIED offline ink replayed on reconnect');await sleep(p,3);
  });
 }catch(e){if(current&&!current.isClosed()){await current.screenshot({path:path.join(work,'record-failure.png')});fs.writeFileSync(path.join(work,'record-failure-labels.json'),JSON.stringify(await labels(current),null,2));}throw e;}finally{await browser.close();await f.cleanup();console.log('Local video fixture removed');}
})().catch(e=>{console.error(e);process.exitCode=1});
