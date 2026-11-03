// Browser-only demo: no local or hosted backend is needed.
// Serve app/build/demo on port 3001, then: node e2e/flow_demo.js [base URL]
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {launch,open,goto,semantics,btn,waitText,type,draw,labels}=require('../demo/media/browser.cjs');
const base=process.argv[2]||'http://127.0.0.1:3001';
const out=process.env.DEMO_SHOTS||'/tmp/praiseteam-demo-qa';fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await launch();const errors=[],forbidden=[];let page;let pdfLoads=0;
 try{
  page=await open(browser,null);page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(/supabase\.(co|in)|firebaseinstallations|fcmregistrations|demo\.praiseteam\.invalid/.test(r.url()))forbidden.push(r.url().split('?')[0]);});
  page.on('console',message=>{if(message.text().startsWith('PdfDocument initial load:'))pdfLoads++;});
  await goto(page,base,'/','할 일');await waitText(page,'초기화');await page.screenshot({path:out+'/desktop-home.png'});
  await goto(page,base,'/t/1/songs','In Jesus Name');
  await btn(page,'곡 추가').click();await type(page,'곡 이름','데모에서 만든 곡');await btn(page,'저장').click();await waitText(page,'데모에서 만든 곡');
  await page.waitForTimeout(600);await page.reload();await semantics(page);await waitText(page,'데모에서 만든 곡');console.log('PASS local mutation and reload');
  const other=await open(browser,null,{viewport:{width:390,height:844}});await goto(other,base,'/t/1/songs','In Jesus Name');assert.ok(!(await labels(other)).some(x=>x.includes('데모에서 만든 곡')));await other.screenshot({path:out+'/mobile-songs.png'});await other.context().close();console.log('PASS visitor isolation');
  await goto(page,base,'/t/1/sessions/107','라이브하기');await page.getByRole('button',{name:/^1\s+In Jesus Name/}).click();await waitText(page,'송폼');await type(page,'BPM','108');await type(page,'메모','데모에서 바꾼 메모');await btn(page,'저장').click();await waitText(page,'데모에서 바꾼 메모');
  await btn(page,'바뀐 내용 공지하기').click();await btn(page,'바뀐 내용 공지하기').last().click();await page.waitForTimeout(600);console.log('PASS setlist edit and publish');
  await btn(page,'라이브하기').click();await waitText(page,'1명 함께');await waitText(page,'필기');await page.waitForTimeout(2000);await page.screenshot({path:out+'/stand.png'});console.log('PASS sample PDF and local live preview');
  // Drawing, save acknowledgements and toolbar changes must retain the
  // loaded PDF. Reopening it cleared the page image and flashed white.
  const loadedBeforeInk=pdfLoads;assert.ok(loadedBeforeInk>0,'the sample PDF loaded');
  await btn(page,'필기').click();await waitText(page,'나만 보기');
  await draw(page,570,420,650,435);await btn(page,'팀 공용').click();
  await btn(page,'형광펜').click();await draw(page,570,450,650,450);
  await btn(page,'펜').click();await btn(page,'완료').click();
  await btn(page,'필기').click();await btn(page,'완료').click();
  await page.waitForTimeout(1500);
  assert.equal(pdfLoads,loadedBeforeInk,'annotation actions must not reload the PDF');
  console.log('PASS PDF stays loaded across drawing, tool changes and toolbar toggles');
  await goto(page,base,'/t/1/rotation','로테이션');await btn(page,'표').click();await page.waitForTimeout(500);await page.screenshot({path:out+'/desktop-table.png'});
  await goto(page,base,'/t/1/chat/1','다음 팀 모임');await type(page,'메시지','샘플 콘티 확인했어요!');await btn(page,'보내기').click();await waitText(page,'샘플 콘티 확인했어요!');await page.getByRole('button',{name:/토요일 점심/}).click();await waitText(page,'3표');console.log('PASS chat and poll');
  await btn(page,'초기화').click();await waitText(page,'할 일');await goto(page,base,'/t/1/songs','In Jesus Name');assert.ok(!(await labels(page)).some(x=>x.includes('데모에서 만든 곡')));console.log('PASS reset returns to original samples');
  const mobile=await open(browser,null,{viewport:{width:390,height:844},colorScheme:'dark'});await goto(mobile,base,'/t/1/home','할 일');await mobile.screenshot({path:out+'/mobile-dark-home.png'});await btn(mobile,'초기화').click();await waitText(mobile,'할 일');await mobile.context().close();
  assert.deepEqual(errors,[]);assert.deepEqual(forbidden,[]);console.log('PASS no cloud backend / push requests and no page errors');console.log('DEMO FLOW OK');
 }catch(e){if(page){await page.screenshot({path:out+'/failure.png'});fs.writeFileSync(out+'/failure-labels.json',JSON.stringify(await labels(page),null,2));}throw e;}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
