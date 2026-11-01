-- Push delivery state machine: pending -> sending -> sent | failed | skipped
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'd1@test.local', '{"full_name":"D1"}', now(), now()),
  ('00000000-0000-0000-0000-0000000000d2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'd2@test.local', '{"full_name":"D2"}', now(), now());

update public.profiles set locale = 'en' where id = '00000000-0000-0000-0000-0000000000d1';
insert into public.device_tokens (token, user_id, platform)
values ('t-live', '00000000-0000-0000-0000-0000000000d1', 'android'),
       ('t-dead', '00000000-0000-0000-0000-0000000000d1', 'web');
insert into public.notification_prefs (user_id, category, push_enabled)
values ('00000000-0000-0000-0000-0000000000d2', 'member_approved', false);

select private.notify(null,
  array['00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000d2', '00000000-0000-0000-0000-0000000000d1']::uuid[],
  'member_approved', '{"team_name":"T"}');

select is((select count(*)::int from public.notifications), 2, 'one row per distinct recipient');
select is(
  (select push_status from public.notifications where user_id = '00000000-0000-0000-0000-0000000000d2'),
  'skipped', 'category turned off -> push skipped, still listed in-app');

select set_config('test.nid', (select id::text from public.notifications where user_id = '00000000-0000-0000-0000-0000000000d1'), true);

-- claim
select is(
  (select jsonb_array_length(tokens) from private.claim_push_batch(array[current_setting('test.nid')::bigint])),
  2, 'claim returns all device tokens');
select is((select push_status from public.notifications where id = current_setting('test.nid')::bigint), 'sending', 'claimed row is sending');
select is((select count(*)::int from private.claim_push_batch(array[current_setting('test.nid')::bigint])), 0, 'a sending row cannot be claimed twice');

-- report a failure + a dead token
select private.complete_push(jsonb_build_object(
  'results', jsonb_build_array(jsonb_build_object('id', current_setting('test.nid')::bigint, 'status', 'failed')),
  'dead_tokens', jsonb_build_array('t-dead')));
select is((select push_status from public.notifications where id = current_setting('test.nid')::bigint), 'pending', 'failed with attempts left goes back to pending');
select is((select count(*)::int from public.device_tokens where token = 't-dead'), 0, 'dead token deleted');
select is((select count(*)::int from public.device_tokens where token = 't-live'), 1, 'live token kept');

-- success
select is((select locale from private.claim_push_batch(array[current_setting('test.nid')::bigint])), 'en', 'claim returns recipient locale');
select private.complete_push(jsonb_build_object(
  'results', jsonb_build_array(jsonb_build_object('id', current_setting('test.nid')::bigint, 'status', 'sent'))));
select is((select push_status from public.notifications where id = current_setting('test.nid')::bigint), 'sent', 'sent recorded');

-- retry sweeper
update public.notifications
set push_status = 'sending', push_claimed_at = now() - interval '10 minutes'
where id = current_setting('test.nid')::bigint;
select private.retry_pushes();
select is((select push_status from public.notifications where id = current_setting('test.nid')::bigint), 'pending', 'stuck claim is released');

update public.notifications set push_attempts = 5 where id = current_setting('test.nid')::bigint;
select private.retry_pushes();
select is((select push_status from public.notifications where id = current_setting('test.nid')::bigint), 'failed', 'gives up after 5 attempts');

select * from finish();
rollback;
