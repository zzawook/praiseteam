// Real, isolated local-backend fixtures for the video, including two distinct
// authenticated participants. Never runs against a hosted Supabase project.
const { execFileSync } = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const sql = (query) => execFileSync('docker',['exec','-i','supabase_db_praiseteam','psql','-U','postgres','-d','postgres','-Atq','-v','ON_ERROR_STOP=1'],{input:query,encoding:'utf8'}).trim();
const literal = (value) => `'${String(value).replace(/'/g,"''")}'`;

async function prepare() {
  const env=Object.fromEntries(execFileSync('supabase',['status','-o','env'],{cwd:root,encoding:'utf8',stdio:['ignore','pipe','ignore']}).split('\n').filter(s=>s.includes('=')).map(s=>[s.slice(0,s.indexOf('=')),s.slice(s.indexOf('=')+1).replace(/^"|"$/g,'')]));
  assert.equal(env.API_URL,'http://127.0.0.1:54321');
  const tables=JSON.parse(fs.readFileSync(path.join(__dirname,'work/seed.json'),'utf8'));
  const stamp=Date.now();
  const users=[], sessions=[];
  let team;
  const files=[];
  const userMap={}, ids={};
  const request=async (url,opts={})=>{
    const response=await fetch(env.API_URL+url,{...opts,headers:{apikey:env.ANON_KEY,'Content-Type':'application/json',...opts.headers}});
    if(!response.ok)throw new Error(`${url.split('?')[0]}: HTTP ${response.status}`);
    return response;
  };
  async function cleanup() {
    if(files.length)await request('/storage/v1/object/sheets',{method:'DELETE',headers:{Authorization:`Bearer ${env.SERVICE_ROLE_KEY}`},body:JSON.stringify({prefixes:files})});
    const queries=['begin;'];
    if(team)queries.push(`delete from public.sessions where team_id=${team}; delete from public.songs where team_id=${team}; delete from public.teams where id=${team};`);
    if(users.length)queries.push(`delete from auth.users where id in (${users.map(literal).join(',')});`);
    queries.push('commit;');sql(queries.join('\n'));
  }
  try {
  for(let i=0;i<tables.profiles.length;i++) {
    const p=tables.profiles[i];
    if(i<2) {
      const res=await request('/auth/v1/signup',{method:'POST',body:JSON.stringify({email:`film-${stamp}-${i}@praise.local`,password:'local-film-demo-only',data:{full_name:p.display_name}})});
      const session=await res.json();sessions.push(session);userMap[p.id]=session.user.id;
    } else userMap[p.id]=crypto.randomUUID();
    users.push(userMap[p.id]);
  }
  team=Number(sql("select nextval(pg_get_serial_sequence('public.teams','id'))"));
  const columns={};
  for(const [table,rows] of Object.entries(tables)) {
    const info=JSON.parse(sql(`select coalesce(json_agg(column_name),'[]'::json) from information_schema.columns where table_schema='public' and table_name=${literal(table)}`));
    columns[table]=info;
    if(table==='teams') {ids.teams={1:team};continue;}
    if(!rows.length||typeof rows[0].id!=='number')continue;
    const allocated=sql(`select nextval(pg_get_serial_sequence('public.${table}','id')) from generate_series(1,${rows.length})`).split('\n').map(Number);
    ids[table]=Object.fromEntries(rows.map((r,i)=>[r.id,allocated[i]]));
  }
  const uuidMap={...userMap};
  for(const table of ['messages','strokes']) for(const r of tables[table])uuidMap[r.id]=crypto.randomUUID();
  const targets={team_id:'teams',song_id:'songs',version_id:'song_versions',sheet_id:'sheets',session_id:'sessions',part_id:'parts',channel_id:'channels',poll_id:'polls',option_id:'poll_options',assignment_id:'assignments',rehearsal_id:'rehearsals',announcement_id:'announcements',setlist_item_id:'setlist_items'};
  function map(value,table,key) {
    if(value==null)return value;
    if(typeof value==='boolean')return value;
    if(typeof value==='string') {
      if(uuidMap[value])return uuidMap[value];
      if(key==='storage_path')return value.replace(/^1\//,`${team}/`);
      return value;
    }
    if(typeof value==='number')return key==='id'?(ids[table]?.[value]??value):(ids[targets[key]]?.[value]??value);
    if(Array.isArray(value))return value.map(x=>map(x,table,''));
    return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,map(v,table,k)]));
  }
  const mapped=Object.fromEntries(Object.entries(tables).map(([table,rows])=>[table,rows.map(r=>map(r,table,''))]));
  const queries=['begin;','set local session_replication_role = replica;'];
  for(let i=2;i<users.length;i++)queries.push(`insert into auth.users(id,aud,role,email,raw_user_meta_data,created_at,updated_at) values (${literal(users[i])},'authenticated','authenticated',${literal(`film-${stamp}-${i}@praise.local`)},${literal(JSON.stringify({full_name:tables.profiles[i].display_name}))}::jsonb,now(),now());`);
  for(const [table,rows] of Object.entries(mapped)) {
    if(!rows.length)continue;
    const keys=[...new Set(rows.flatMap(r=>Object.keys(r)))].filter(k=>columns[table].includes(k));
    const select=keys.map(k=>`r."${k}"`).join(',');
    const conflict=table==='profiles'?' on conflict(id) do update set display_name=excluded.display_name,locale=excluded.locale':'';
    queries.push(`insert into public.${table} (${keys.map(k=>`"${k}"`).join(',')}) overriding system value select ${select} from jsonb_populate_recordset(null::public.${table},${literal(JSON.stringify(rows))}::jsonb) r${conflict};`);
  }
  queries.push('commit;');sql(queries.join('\n'));
  for(const sheet of mapped.sheets) {
    const bytes=fs.readFileSync(path.join(root,'app/assets/demo',path.basename(sheet.storage_path)));
    const response=await fetch(`${env.API_URL}/storage/v1/object/sheets/${sheet.storage_path}`,{method:'POST',headers:{Authorization:`Bearer ${env.SERVICE_ROLE_KEY}`,'Content-Type':'application/pdf'},body:bytes});
    assert.ok(response.ok,'sample PDF uploaded');files.push(sheet.storage_path);
  }
  async function strokesFor(actor) {
    const response=await request(`/rest/v1/strokes?select=id,owner_id,visibility&session_id=eq.${ids.sessions[107]}`,{
      headers:{Authorization:`Bearer ${sessions[actor].access_token}`},
    });
    return response.json();
  }
  return {team,service:ids.sessions[107],song:ids.songs[1],channel:ids.channels[1],sessions,strokesFor,cleanup};
  } catch(error) {
    await cleanup();
    throw error;
  }
}
module.exports={prepare};
