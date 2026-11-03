// Disposable native-test fixtures on the existing local stack. Never resets DB.
const http=require('node:http');
const {execFileSync}=require('node:child_process');
const {prepare}=require('../demo/media/backend.cjs');
const sql=query=>execFileSync('docker',['exec','-i','supabase_db_praiseteam','psql','-U','postgres','-d','postgres','-Atq','-v','ON_ERROR_STOP=1'],{input:query,encoding:'utf8'}).trim();
const literal=value=>"'"+String(value).replaceAll("'","''")+"'";
(async()=>{
 const fixture=await prepare({cleanAnnotations:true,rotationVacancies:true});
 const stamp=Date.now();
 const onboardingEmail=`native-${stamp}@praise.local`;
 const onboardingTeam=`Native QA ${stamp}`;
 const data={team:fixture.team,service:fixture.service,song:fixture.song,channel:fixture.channel,
  actors:fixture.sessions.map(s=>({email:s.user.email,id:s.user.id})),
  password:'local-film-demo-only',onboardingEmail,onboardingPassword:'local-native-test-only',onboardingTeam};
 const server=http.createServer((req,res)=>{
  if(req.method==='GET'&&req.url==='/fixture'){
   res.writeHead(200,{'Content-Type':'application/json','Cache-Control':'no-store'});res.end(JSON.stringify(data));
  }else{res.writeHead(404);res.end()}
 });
 let closing=false;
 async function cleanup(){
  if(closing)return;closing=true;server.close();
  try{
   const teams=sql(`select id from public.teams where name=${literal(onboardingTeam)}`).split('\n').filter(Boolean).map(Number);
   for(const team of teams)sql(`begin; delete from public.sessions where team_id=${team}; delete from public.songs where team_id=${team}; delete from public.teams where id=${team}; commit;`);
   const users=sql(`select id from auth.users where email=${literal(onboardingEmail)}`).split('\n').filter(Boolean);
   for(const id of users){
    sql(`delete from auth.users where id=${literal(id)}`);
   }
   await fixture.cleanup();
   console.log('Native fixtures removed.');
  }catch(e){console.error('Fixture cleanup failed:',e.message);process.exitCode=1}
 }
 process.once('SIGINT',cleanup);process.once('SIGTERM',cleanup);
 server.once('error',async error=>{console.error(error.message);await cleanup();process.exitCode=1});
 server.listen(3939,'127.0.0.1',()=>console.log('Native fixtures ready on localhost:3939 (local stack only).'));
})().catch(e=>{console.error(e.message);process.exitCode=1});
