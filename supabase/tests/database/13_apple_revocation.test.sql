begin;
create extension if not exists pgtap with schema extensions;
select no_plan();
insert into auth.users(id,email) values
 ('eeee0000-0000-0000-0000-000000000001','apple-revoke@test.local'),
 ('eeee0000-0000-0000-0000-000000000002','not-apple@test.local');
insert into auth.sessions(id,user_id) values
 ('eeee1111-0000-0000-0000-000000000001','eeee0000-0000-0000-0000-000000000001'),
 ('eeee1111-0000-0000-0000-000000000002','eeee0000-0000-0000-0000-000000000002');
insert into auth.identities(id,provider_id,user_id,provider,identity_data)
values(gen_random_uuid(),'apple-test-subject','eeee0000-0000-0000-0000-000000000001','apple','{"sub":"apple-test-subject"}');
select ok(not has_table_privilege('anon','private.apple_identity_tokens','select'),'anonymous cannot read Apple tokens');
select ok(not has_table_privilege('authenticated','private.apple_identity_tokens','select'),'members cannot read Apple tokens');
select ok(not has_table_privilege('service_role','private.apple_identity_tokens','select'),'service API has no direct token-table access');
select ok(not has_function_privilege('authenticated','public.store_apple_token(uuid,uuid,text,text,text)','execute'),'members cannot store arbitrary provider tokens');
select ok(not has_function_privilege('anon','public.claim_apple_revocations(integer)','execute'),'anonymous cannot claim revocation work');
select ok(not has_function_privilege('authenticated','public.finish_apple_revocation(bigint,boolean,integer)','execute'),'members cannot cancel revocations');
select ok((select relrowsecurity from pg_class where oid='private.apple_identity_tokens'::regclass),'token table also has RLS');

set local role service_role;
select throws_ok($$select public.store_apple_token('eeee0000-0000-0000-0000-000000000002','eeee1111-0000-0000-0000-000000000002','com.test',repeat('a',64),'v1.nonce.cipher')$$,
 '42501','active Apple session required','a non-Apple session cannot attach an Apple grant');
select lives_ok($$select public.store_apple_token('eeee0000-0000-0000-0000-000000000001','eeee1111-0000-0000-0000-000000000001','com.test',repeat('a',64),'v1.nonce.cipher')$$,'verified Apple session can retain an encrypted token');
select public.store_apple_token('eeee0000-0000-0000-0000-000000000001','eeee1111-0000-0000-0000-000000000001','com.test',repeat('a',64),'v1.newnonce.cipher');
select public.store_apple_token('eeee0000-0000-0000-0000-000000000001','eeee1111-0000-0000-0000-000000000001','com.test',repeat('b',64),'v1.nonce.second');
select throws_ok($$select public.store_apple_token('eeee0000-0000-0000-0000-000000000001','eeee1111-0000-0000-0000-000000000099','com.test',repeat('c',64),'v1.nonce.cipher')$$,
 '42501','active Apple session required','revoked sessions cannot store credentials');
reset role;
select is((select count(*) from private.apple_identity_tokens where user_id='eeee0000-0000-0000-0000-000000000001'),2::bigint,'duplicate tokens deduplicate; distinct grants are retained');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"eeee0000-0000-0000-0000-000000000001","role":"authenticated","session_id":"eeee1111-0000-0000-0000-000000000001"}',true);
select lives_ok('select public.delete_account()','Apple account deletion uses the ordinary protected deletion path');
reset role;
select is((select count(*) from private.apple_identity_tokens where user_id='eeee0000-0000-0000-0000-000000000001'),0::bigint,'account token records are removed');
select is((select count(*) from private.apple_revocation_queue where user_id='eeee0000-0000-0000-0000-000000000001'),2::bigint,'all provider grants are queued atomically with deletion');
set local role service_role;
select set_config('test.apple_claim',public.claim_apple_revocations(1)::text,true);
select is(jsonb_array_length(current_setting('test.apple_claim')::jsonb),1,'worker respects its batch size');
select set_config('test.apple_next',public.claim_apple_revocations(1)::text,true);
select isnt((current_setting('test.apple_claim')::jsonb->0->>'id'),(current_setting('test.apple_next')::jsonb->0->>'id'),'leased work cannot be claimed twice');
select public.finish_apple_revocation((current_setting('test.apple_claim')::jsonb->0->>'id')::bigint,false,503);
select public.finish_apple_revocation((current_setting('test.apple_next')::jsonb->0->>'id')::bigint,true,200);
reset role;
select is((select count(*) from private.apple_revocation_queue where user_id='eeee0000-0000-0000-0000-000000000001'),1::bigint,'only successful revocations are removed');
select ok((select next_attempt_at > now() and attempts=1 and last_status=503 from private.apple_revocation_queue where user_id='eeee0000-0000-0000-0000-000000000001'),'failed revocation is retained with retry metadata');
select * from finish();
rollback;
