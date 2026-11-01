-- Service templates: leaders keep them, members can only read them, other
-- teams cannot see them.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000008a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l8@test.local', '{"full_name":"Lead"}', now(), now()),
  ('00000000-0000-0000-0000-00000000008b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm8@test.local', '{"full_name":"Member"}', now(), now()),
  ('00000000-0000-0000-0000-00000000008c', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'o8@test.local', '{"full_name":"Outsider"}', now(), now());

-- the leader's team, which the member joins; the outsider leads another team
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000008a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000008b","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000008c","role":"authenticated"}', true);
select set_config('test.other', public.create_team('Other')::text, true);

-- ---- the leader keeps the team's weekly services
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000008a","role":"authenticated"}', true);
select lives_ok($$
  insert into public.session_templates (team_id, title, weekday, start_time, location)
  values (current_setting('test.team')::bigint, '주일 2부 예배', 7, '11:00', '본당'),
         (current_setting('test.team')::bigint, '금요 기도회', 5, '20:00', null)
$$, 'leaders add templates');
select throws_ok($$
  insert into public.session_templates (team_id, title, weekday, start_time)
  values (current_setting('test.team')::bigint, '주일 2부 예배', 6, '10:00')
$$, '23505', null, 'titles are unique in a team');
select throws_ok($$
  insert into public.session_templates (team_id, title, weekday, start_time)
  values (current_setting('test.team')::bigint, '월요 예배', 0, '10:00')
$$, '23514', null, 'weekday is 1 (Monday) to 7 (Sunday)');
select throws_ok($$
  insert into public.session_templates (team_id, title, weekday, start_time)
  values (current_setting('test.team')::bigint, '   ', 1, '10:00')
$$, '23514', null, 'a title is required');
select lives_ok($$
  update public.session_templates set start_time = '11:30', location = '소예배실' where title = '주일 2부 예배'
$$, 'leaders edit templates');
select is(
  (select start_time::text || ' ' || location from public.session_templates where title = '주일 2부 예배'),
  '11:30:00 소예배실', 'the edit is kept');
select throws_ok($$
  update public.session_templates set team_id = current_setting('test.other')::bigint where title = '주일 2부 예배'
$$, '42501', null, 'a template cannot move to another team');

-- ---- members read them but cannot change them
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000008b","role":"authenticated"}', true);
select is((select count(*)::int from public.session_templates), 2, 'members see the team templates');
select throws_ok($$
  insert into public.session_templates (team_id, title, weekday, start_time)
  values (current_setting('test.team')::bigint, '수요 예배', 3, '19:30')
$$, '42501', null, 'members cannot add templates');
-- RLS filters these to zero rows
update public.session_templates set start_time = '07:00';
delete from public.session_templates;

-- ---- another team's leader sees none of them
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000008c","role":"authenticated"}', true);
select is((select count(*)::int from public.session_templates), 0, 'other teams see no templates');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000008a","role":"authenticated"}', true);
select is(
  (select string_agg(title || ' ' || start_time::text, ', ' order by weekday) from public.session_templates),
  '금요 기도회 20:00:00, 주일 2부 예배 11:30:00', 'member edits and deletes changed nothing');

reset role;
select ok(not has_table_privilege('anon', 'public.session_templates', 'select'), 'signed-out users cannot read templates');

select * from finish();
rollback;
