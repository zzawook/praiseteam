// Run on the named disposable emulator. Auth/data fixtures stay on localhost.
const {spawn,execFileSync}=require('node:child_process');
const path=require('node:path');
const os=require('node:os');
const fs=require('node:fs');
const root=path.resolve(__dirname,'..');
const args=process.argv.slice(2);
const demo=args.includes('--demo');
const at=args.indexOf('--device');
const device=at<0?'emulator-5554':args[at+1];
const adb=path.join(process.env.ANDROID_SDK_ROOT||path.join(os.homedir(),'Android/Sdk'),'platform-tools/adb');
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
let fixture,run;
const completion=child=>new Promise(resolve=>child.once('exit',resolve));
(async()=>{
 try{
  if(!demo){
   try{await fetch('http://127.0.0.1:3939/fixture');throw new Error('Another native fixture server is already running. Stop it first.')}catch(e){if(e.message.startsWith('Another'))throw e}
   fixture=spawn(process.execPath,[path.join(__dirname,'native_fixture.cjs')],{cwd:root,stdio:['ignore','inherit','inherit']});
   for(let n=0;;n++){
    if(fixture.exitCode!==null)throw new Error('Native fixture setup failed');
    try{const r=await fetch('http://127.0.0.1:3939/fixture');if(r.ok)break}catch{}
    if(n>=90)throw new Error('Native fixture setup timed out');await delay(500);
   }
  }
  const output=path.join(root,'output/native',demo?'android-demo':'android-backend');fs.mkdirSync(output,{recursive:true});
  const target=demo?'mobile_demo_test.dart':'native_backend_test.dart';
  const command=['drive','--no-pub','-d',device,'--driver=test_driver/mobile_driver.dart','--target=integration_test/'+target,
   demo?'--dart-define=DEMO_MODE=true':'--dart-define-from-file=env/local.android.json'];
  run=spawn('flutter',command,{cwd:path.join(root,'app'),stdio:'inherit',env:{...process.env,NATIVE_OUTPUT:output}});
  const finished=completion(run);
  if(!demo){
   for(let n=0;n<180&&run.exitCode===null;n++){
    try{
     const installed=execFileSync(adb,['-s',device,'shell','pm','path','com.kjaehyeok.praiseteam'],{encoding:'utf8',stdio:['ignore','pipe','ignore']});
     if(installed.includes('package:')){
      execFileSync(adb,['-s',device,'shell','pm','grant','com.kjaehyeok.praiseteam','android.permission.POST_NOTIFICATIONS'],{stdio:'ignore'});
      console.log('Notification permission granted on the QA emulator.');break;
     }
    }catch{}
    await delay(500);
   }
  }
  process.exitCode=(await finished)??1;
 }finally{
  if(fixture&&fixture.exitCode===null){const stopped=completion(fixture);fixture.kill('SIGTERM');await stopped}
 }
})().catch(e=>{console.error(e.message);process.exitCode=1});
process.once('SIGINT',()=>run?.kill('SIGINT'));
process.once('SIGTERM',()=>run?.kill('SIGTERM'));
