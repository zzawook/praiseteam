// Reconnect the document capture browser to an explicitly recorded local
// fixture. capture-state.json contains IDs only, never passwords or tokens.
const fs=require('node:fs/promises');
const path=require('node:path');
const {execFileSync}=require('node:child_process');
const assert=require('node:assert/strict');
const browserTools=require('../demo/media/browser.cjs');
const captureTools=require('./guide_capture_helpers.cjs');
const root=path.resolve(__dirname,'..');
const sql=q=>execFileSync('docker',['exec','-i','supabase_db_praiseteam','psql','-U','postgres','-d','postgres','-Atq','-v','ON_ERROR_STOP=1'],{input:q,encoding:'utf8'}).trim();

async function recover() {
 const state=JSON.parse(await fs.readFile(path.join(root,'output/guide/capture-state.json'),'utf8'));
 assert.notEqual(state.cleaned_up,true,'The recorded capture fixture has already been removed.');
 assert.ok(Array.isArray(state.users)&&state.users.every(id=>/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)));
 const env=Object.fromEntries(execFileSync('supabase',['status','-o','env'],{cwd:root,encoding:'utf8',stdio:['ignore','pipe','ignore']}).split('\n').filter(s=>s.includes('=')).map(s=>[s.slice(0,s.indexOf('=')),s.slice(s.indexOf('=')+1).replace(/^"|"$/g,'')]));
 assert.equal(env.API_URL,'http://127.0.0.1:54321');
 assert.ok(Number.isSafeInteger(state.team));
 const users=JSON.parse(sql(`select json_agg(json_build_object('id',u.id,'email',u.email,'name',p.display_name)) from auth.users u join public.profiles p on p.id=u.id join public.team_members m on m.user_id=u.id where m.team_id=${state.team}`));
 assert.equal(users.length,state.users.length,'Capture state must contain only this fixture team.');
 assert.equal(new Set(state.users).size,state.users.length);
 assert.ok(users.every(u=>state.users.includes(u.id)&&/^(film|guide)-.*@praise\.local$/.test(u.email)));
 assert.equal(sql(`select count(*) from public.team_members where team_id<>${state.team} and user_id in (${state.users.map(id=>`'${id}'`).join(',')})`),'0','Fixture users must not belong to another team.');
 async function signIn(name) {
  const user=users.find(u=>u.name===name);
  const r=await fetch(env.API_URL+'/auth/v1/token?grant_type=password',{method:'POST',headers:{apikey:env.ANON_KEY,'Content-Type':'application/json'},body:JSON.stringify({email:user.email,password:'local-film-demo-only'})});
  assert.ok(r.ok,'local fixture sign-in');return r.json();
 }
 const sessions=[await signIn('서지훈'),await signIn('김하늘')];
 const browser=await browserTools.launch();
 const mobile={viewport:{width:412,height:820},deviceScaleFactor:2,isMobile:true,hasTouch:true,locale:'ko-KR',timezoneId:'Asia/Singapore'};
 const owner=await browserTools.open(browser,sessions[0],mobile),member=await browserTools.open(browser,sessions[1],mobile);
 owner.setDefaultTimeout(2000);member.setDefaultTimeout(2000);
 const out=path.join(root,'output/guide/screenshots');
 async function cleanup() {
  await browser.close();
  const files=JSON.parse(sql(`select coalesce(json_agg(name),'[]'::json) from storage.objects where bucket_id='sheets' and split_part(name,'/',1)='${state.team}'`));
  if(files.length){const r=await fetch(env.API_URL+'/storage/v1/object/sheets',{method:'DELETE',headers:{apikey:env.ANON_KEY,Authorization:`Bearer ${env.SERVICE_ROLE_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({prefixes:files})});assert.ok(r.ok,'fixture storage cleanup');}
  sql(`begin; delete from public.sessions where team_id=${state.team};delete from public.songs where team_id=${state.team};delete from public.teams where id=${state.team};delete from auth.users where id in (${state.users.map(id=>`'${id}'`).join(',')});commit;`);
 }
 return {root,state,env,sql,users,sessions,browser,owner,member,out,base:'http://127.0.0.1:3020',tools:browserTools,capture:captureTools,route:s=>'/t/'+state.team+'/'+s,cleanup};
}
module.exports={recover};
