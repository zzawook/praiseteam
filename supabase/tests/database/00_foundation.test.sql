-- Foundation access-control tests: teams, membership, parts, notifications.
begin;
create extension if not exists pgtap with schema extensions;
select plan(32);

-- Users: A (owner), B (joins), C (outsider)
insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.local', '{"full_name":"Alice"}', now(), now()),
  ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.local', '{"name":"Bob"}', now(), now()),
  ('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'carol@test.local', '{}', now(), now());

select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000a'),
  'Alice', 'profile created from full_name');
select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000c'),
  'carol', 'profile falls back to email local part');

-- ---- privilege surface (checked via catalog, not by executing as anon)
select ok(not has_function_privilege('anon', 'public.create_team(text, text)', 'execute'), 'anon cannot execute create_team');
select ok(not has_column_privilege('authenticated', 'public.notifications', 'push_status', 'update'), 'clients cannot update push_status');
select ok(has_column_privilege('authenticated', 'public.notifications', 'read_at', 'update'), 'clients can mark notifications read');

-- ---- A creates a team
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('Praise Team')::text, true);

select is(
  (select role from public.team_members where team_id = current_setting('test.team')::bigint and user_id = '00000000-0000-0000-0000-00000000000a'),
  'owner', 'creator is owner');
select is(
  (select count(*)::int from public.parts where team_id = current_setting('test.team')::bigint),
  10, 'default parts seeded');
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select throws_ok($$ select public.create_team('Bad TZ', 'Mars/Olympus') $$, '22023', null, 'invalid timezone rejected');

-- ---- B joins with the invite code (lowercase, padded)
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
select is(public.join_team('  ' || lower(current_setting('test.code')) || ' '), current_setting('test.team')::bigint, 'join by code returns team id');
select is(
  (select status from public.team_members where team_id = current_setting('test.team')::bigint and user_id = '00000000-0000-0000-0000-00000000000b'),
  'pending', 'joiner is pending');
select is((select count(*)::int from public.teams), 1, 'pending member sees the team they applied to');
select is((select count(*)::int from public.parts), 0, 'pending member cannot read parts');
select is((select count(*)::int from public.team_members), 1, 'pending member sees only own membership');
select throws_ok($$ select public.join_team('NOPE1234') $$, 'P0002', null, 'wrong code rejected');

-- ---- A sees the request and approves
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
select is(
  (select count(*)::int from public.notifications where category = 'member_join_request'),
  1, 'owner notified about join request');
select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000b'),
  'Bob', 'leader can read pending applicant profile');
select lives_ok(
  $$ select public.approve_member(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000000b') $$,
  'owner approves');

-- ---- B is now an active member
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
select is((select count(*)::int from public.notifications where category = 'member_approved'), 1, 'member notified on approval');
select is((select count(*)::int from public.team_members), 2, 'active member sees roster');
select is((select count(*)::int from public.parts), 10, 'active member reads parts');
select is((select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000a'), 'Alice', 'member reads teammate profile');
select is((select count(*)::int from public.notifications), 1, 'member sees only own notifications');

select throws_ok(
  $$ select public.approve_member(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000000c') $$,
  '42501', null, 'member cannot approve');
select throws_ok(
  $$ select public.rotate_invite_code(current_setting('test.team')::bigint) $$,
  '42501', null, 'member cannot rotate invite code');
select throws_ok(
  $$ insert into public.parts (team_id, name, kind) values (current_setting('test.team')::bigint, '하프', 'instrument') $$,
  '42501', null, 'member cannot add parts');
select throws_ok(
  $$ select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000000a', '{}') $$,
  '42501', null, 'member cannot change someone else''s parts');
select lives_ok(
  $$ select public.set_member_parts(
       current_setting('test.team')::bigint,
       '00000000-0000-0000-0000-00000000000b',
       array(select id from public.parts where name in ('건반', '싱어'))) $$,
  'member sets own parts');
select is((select count(*)::int from public.member_parts where user_id = '00000000-0000-0000-0000-00000000000b'), 2, 'own parts saved');

-- ---- owner invariants
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
select throws_ok(
  $$ select public.set_member_role(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000000a', 'member') $$,
  '23514', null, 'last owner cannot step down');

-- ---- device tokens move to the latest registrant
select public.register_device_token('tok-1', 'android');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
select public.register_device_token('tok-1', 'web');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
select is((select count(*)::int from public.device_tokens), 0, 'token no longer listed for previous user');

-- ---- C (outsider) sees nothing
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
select is((select count(*)::int from public.teams), 0, 'outsider sees no teams');
select is((select count(*)::int from public.profiles where id <> '00000000-0000-0000-0000-00000000000c'), 0, 'outsider sees no other profiles');

select * from finish();
rollback;
