// Record real UI actions at the words they explain. Fixtures are local only.
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {launch,open,goto,btn,waitText,type,drawPath,drawEllipse,labels,work}=require('./browser.cjs');
const base='http://127.0.0.1:3002';
const raw=path.join(work,'raw');fs.mkdirSync(raw,{recursive:true});
const metaPath=path.join(work,'clips.json');
const clips=fs.existsSync(metaPath)?JSON.parse(fs.readFileSync(metaPath)):{};
const timing=JSON.parse(fs.readFileSync(path.join(__dirname,'timing.json')));
const only=process.argv.slice(2);
const wanted=name=>!only.length||only.includes(name);
const sleep=(page,seconds)=>page.waitForTimeout(seconds*1000);
for(const [name,value]of Object.entries(timing.scenes)){
 const hash=crypto.createHash('sha256').update(fs.readFileSync(path.join(work,name+'.mp3'))).digest('hex');
 assert.equal(hash,value.audio_sha256,'Narration changed; regenerate its timing cues');
}

(async()=>{
 const f=await require('./backend.cjs').prepare({cleanAnnotations:true,rotationVacancies:true});
 const browser=await launch();let current;
 const route=value=>'/t/'+f.team+'/'+value;
 const cue=(name,anchor)=>timing.scenes[name].cues[anchor];
 async function camera(session=f.sessions[0],width=1280,height=800){
  const started=Date.now();
  const p=await open(browser,session,{viewport:{width,height},recordVideo:{dir:raw,size:{width,height}}});
  return {p,started,width,height};
 }
 function schedule(p,start,events){
  return async(label,target,action)=>{
   await sleep(p,Math.max(0,(start+target*1000-Date.now())/1000));
   const actual=(Date.now()-start)/1000;
   assert.ok(actual-target<.45,label+' missed its narration cue');
   await action();
   events.push({label,target,actual,ready:(Date.now()-start)/1000});
  };
 }
 async function finish(name,c,start,events){
  await c.p.context().close();
  clips[name]={file:await c.p.video().path(),start:(start-c.started)/1000,width:c.width,height:c.height,events,...(name==='notes'?{purpose:'visibility'}:{})};
  fs.writeFileSync(metaPath,JSON.stringify(clips,null,2));console.log('RECORDED',name,JSON.stringify(events));
 }
 async function chapter(name,url,ready,action,setup){
  if(!wanted(name))return;
  const c=await camera();current=c.p;
  await goto(c.p,base,url,ready);if(setup)await setup(c.p);await sleep(c.p,1);
  const start=Date.now(),events=[];
  await action(c.p,schedule(c.p,start,events));
  await sleep(c.p,Math.max(0,(start+23000-Date.now())/1000));
  await c.p.screenshot({path:path.join(work,name+'-end.png')});
  await finish(name,c,start,events);
 }
 try{
  await chapter('setlist',route('sessions/'+f.service),'라이브하기',async(p,at)=>{
   await at('version editor',cue('setlist','version')-.6,async()=>{await p.getByRole('button',{name:/^1\s+In Jesus Name/}).click();await waitText(p,'송폼')});
   await at('tempo',cue('setlist','edit')+1,()=>type(p,'BPM','108'));
   await at('notes',cue('setlist','edit')+2,()=>type(p,'메모','마지막 후렴 두 번, 다 함께 마무리'));
   await at('save',cue('setlist','publish')-.9,()=>btn(p,'저장').click());
   await at('publish dialog',cue('setlist','publish')-.3,()=>btn(p,'바뀐 내용 공지하기').click());
   await at('publish',cue('setlist','publish')+.45,()=>btn(p,'바뀐 내용 공지하기').last().click());
  });
  await chapter('songs',route('songs'),'In Jesus Name',async(p,at)=>{
   await at('versions',cue('songs','versions')-.15,async()=>{await p.getByRole('button',{name:/In Jesus Name/}).first().click();await waitText(p,'팀 편곡')});
   await at('history',cue('songs','history')-.15,async()=>{await p.mouse.move(1020,630);await p.mouse.wheel(0,310)});
  });
  await chapter('rotation',route('rotation'),'로테이션',async(p,at)=>{
   await at('auto menu',cue('rotation','auto')-.5,async()=>{await btn(p,'메뉴 표시').click();await waitText(p,'자동 배정')});
   await at('auto assignment',cue('rotation','auto')-.05,async()=>{await p.getByRole('menuitem',{name:'자동 배정',exact:true}).click();await waitText(p,'3자리를 초안으로')});
   await at('blockouts',cue('rotation','blockouts')-.15,async()=>{await btn(p,'불가능 날짜').click();await waitText(p,'가족 일정')});
   await at('return to rota',cue('rotation','answer')-1,()=>btn(p,'뒤로').click());
   await at('response choices',cue('rotation','answer')-.25,async()=>{
    await btn(p,'서지훈').nth(1).click();await waitText(p,'인도  1명');
    await p.getByLabel(/^응답 대기\s+서지훈$/).click();await waitText(p,'수락');
   });
  },async p=>{await btn(p,'표').click();await sleep(p,.3)});
  if(wanted('live')){
   const a=await camera(f.sessions[0],860,800),b=await camera(f.sessions[1],860,800);current=a.p;
   await Promise.all([goto(a.p,base,route('sessions/'+f.service),'라이브하기'),goto(b.p,base,route('sessions/'+f.service),'라이브하기')]);
   const start=Date.now(),events=[],at=schedule(a.p,start,events);
   await at('join live',cue('live','join')-.1,async()=>{
    await Promise.all([btn(a.p,'라이브하기').click(),btn(b.p,'라이브하기').click()]);
    await Promise.all([waitText(a.p,'2명 함께'),waitText(b.p,'2명 함께')]);
   });
   await at('follow page',cue('live','page')-.1,async()=>{await a.p.keyboard.press('ArrowRight');await waitText(b.p,'2 / 5')});
   await at('send cue',cue('live','cue')-.05,async()=>{await btn(b.p,'한 번 더').click();await waitText(a.p,'김하늘')});
   await at('disable follow',cue('live','unfollow')-.1,()=>b.p.getByRole('switch').click());
   await at('independent page',cue('live','unfollow')+.65,async()=>{await a.p.keyboard.press('ArrowRight');await waitText(a.p,'3 / 5');await waitText(b.p,'2 / 5')});
   console.log('VERIFIED real presence, page following, cue delivery and independent navigation');
   await sleep(a.p,Math.max(0,(start+23000-Date.now())/1000));
   await a.p.screenshot({path:path.join(work,'live-a-end.png')});await b.p.screenshot({path:path.join(work,'live-b-end.png')});
   await finish('live-a',a,start,events);await finish('live-b',b,start,events);
  }
  await chapter('notes',route('stand/'+f.service),'필기',async(p,at)=>{
   async function saved(visibility,count=1){
    for(let i=0;i<30;i++){
     const rows=(await f.strokesFor(0)).filter(r=>r.owner_id===f.sessions[0].user.id&&r.visibility===visibility);
     if(rows.length>=count)return rows;await sleep(p,.15);
    }
    throw new Error(visibility+' stroke did not reach the local backend');
   }
   await at('open pen',.15,async()=>{await btn(p,'필기').click();await waitText(p,'나만 보기')});
   await at('private circle',cue('notes','private')-1.5,async()=>{
    await p.mouse.click(727,770);await drawEllipse(p,594,265,38,19);
    const [stroke]=await saved('private');assert.ok(!(await f.strokesFor(1)).some(r=>r.id===stroke.id));
   });
   await at('shared repeat mark',cue('notes','shared')-.15,async()=>{
    // Let the visibility selection rebuild before changing the ink colour.
    await btn(p,'팀 공용').click();await sleep(p,.3);await p.mouse.click(695,770);
    await drawEllipse(p,459,400,34,13);
    await drawPath(p,[[505,390],[512,400],[519,410]]);await drawPath(p,[[519,390],[512,400],[505,410]]);
    await drawPath(p,[[527,394],[528,391],[531,389],[536,389],[539,391],[540,394],[539,397],[536,400],[533,403],[529,406],[526,410],[541,410]]);
    const strokes=await saved('team',4),visible=await f.strokesFor(1);assert.ok(strokes.every(s=>visible.some(r=>r.id===s.id)));
   });
   console.log('VERIFIED private and shared annotation visibility');await p.mouse.move(80,150);
  });
  await chapter('chat',route('chat'),'전체',async(p,at)=>{
   await at('open team chat',cue('chat','poll')-2,async()=>{await p.getByRole('button',{name:/^전체\s/}).click();await waitText(p,'다음 팀 모임')});
   await at('vote',cue('chat','poll'),async()=>{await p.getByRole('button',{name:/토요일 점심/}).click();await waitText(p,'3표')});
   await at('pinned notice',cue('chat','notice')-.65,async()=>{
    await btn(p,'뒤로').click();await p.getByRole('button',{name:/^공지/}).click();await waitText(p,'이번 주 연습과 주일 준비');
   });
  });
  await chapter('home',route('home'),'할 일',async(p,at)=>{
   await at('accept rota',cue('home','accept'),()=>btn(p,'수락').click());
   await at('rehearsal RSVP',cue('home','rsvp'),()=>btn(p,'참석').first().click());
   await at('readiness and schedule',cue('home','readiness')-.1,async()=>{await p.mouse.move(1090,665);await p.mouse.wheel(0,220)});
  });
 }catch(error){
  if(current&&!current.isClosed()){await current.screenshot({path:path.join(work,'record-failure.png')});fs.writeFileSync(path.join(work,'record-failure-labels.json'),JSON.stringify(await labels(current),null,2))}
  throw error;
 }finally{await browser.close();await f.cleanup();console.log('Local video fixture removed')}
})().catch(error=>{console.error(error);process.exitCode=1});
