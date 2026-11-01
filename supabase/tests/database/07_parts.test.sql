-- Adding a part with the part chats it joins (add_part).
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000007a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l7@test.local', '{"full_name":"Lead"}', now(), now()),
  ('00000000-0000-0000-0000-00000000007b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7@test.local', '{"full_name":"Tenor"}', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000007a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select set_config('test.singers', (select id::text from public.channels where name = '싱어팀'), true);
select set_config('test.all', (select id::text from public.channels where name = '전체'), true);

-- the leader splits the singers: a new vocal part that joins 싱어팀 (the
-- whole-team chat id is not a part chat and is ignored)
select set_config('test.part', public.add_part(
  current_setting('test.team')::bigint, '  남자 싱어 ', 'vocal',
  array[current_setting('test.singers')::bigint, current_setting('test.all')::bigint])::text, true);
select isnt(current_setting('test.part'), '', 'add_part returns the new part');
select is((select name || '/' || kind from public.parts where id = current_setting('test.part')::bigint), '남자 싱어/vocal', 'stored trimmed, with its kind');
select ok(
  (select sort_order from public.parts where id = current_setting('test.part')::bigint)
    > (select max(sort_order) from public.parts where team_id = current_setting('test.team')::bigint and id <> current_setting('test.part')::bigint),
  'listed after the existing parts');
select is(
  (select array_agg(c.name) from public.channel_parts cp join public.channels c on c.id = cp.channel_id
   where cp.part_id = current_setting('test.part')::bigint),
  array['싱어팀'], 'linked to the part chat only');

-- a tenor who plays only the new part sees 싱어팀
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000007b","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000007b',
  array[current_setting('test.part')::bigint]);
select is((select count(*)::int from public.channels where name = '싱어팀'), 1, 'members of the new part are in its part chat');

select throws_ok(
  $$ select public.add_part(current_setting('test.team')::bigint, '세컨 드럼', 'instrument') $$,
  '42501', null, 'members cannot add parts');

reset role;
select ok(not has_function_privilege('anon', 'public.add_part(bigint, text, text, bigint[])', 'execute'),
  'signed-out users cannot call add_part');

select * from finish();
rollback;
