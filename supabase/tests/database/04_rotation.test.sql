-- Rotation: drafts, sending, responses, swaps, blockouts, rehearsals, reminders.
begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000002a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l2@test.local', '{"full_name":"Lead"}', now(), now()),
  ('00000000-0000-0000-0000-00000000002b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm2@test.local', '{"full_name":"Min"}', now(), now()),
  ('00000000-0000-0000-0000-00000000002c', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'n2@test.local', '{"full_name":"Nari"}', now(), now()),
  ('00000000-0000-0000-0000-00000000002d', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p2@test.local', '{"full_name":"Paul"}', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select set_config('test.keys', (select id::text from public.parts where team_id = current_setting('test.team')::bigint and name = '건반'), true);
select set_config('test.drums', (select id::text from public.parts where team_id = current_setting('test.team')::bigint and name = '드럼'), true);

-- members with parts: Min & Nari play keys, Paul plays drums
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002b","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000002b', array[current_setting('test.keys')::bigint]);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002c","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000002c', array[current_setting('test.keys')::bigint]);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002d","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000002d', array[current_setting('test.drums')::bigint]);

-- ---- leader: default slots, session, draft
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
insert into public.default_slots (team_id, part_id, count) values (current_setting('test.team')::bigint, current_setting('test.keys')::bigint, 1);
with ins as (insert into public.sessions (team_id, title, starts_at) values (current_setting('test.team')::bigint, '주일', now() + interval '5 days') returning id)
select set_config('test.session', (select id::text from ins), true);
select is((select count::int from public.session_slots where session_id = current_setting('test.session')::bigint), 1, 'new session copies the default slots');

with ins as (
  insert into public.assignments (team_id, session_id, part_id, user_id, source)
  values (current_setting('test.team')::bigint, current_setting('test.session')::bigint, current_setting('test.keys')::bigint, '00000000-0000-0000-0000-00000000002b', 'auto')
  returning id)
select set_config('test.a', (select id::text from ins), true);
select lives_ok($$ update public.assignments set user_id = '00000000-0000-0000-0000-00000000002c' where id = current_setting('test.a')::bigint $$, 'leaders edit drafts freely');
update public.assignments set user_id = '00000000-0000-0000-0000-00000000002b' where id = current_setting('test.a')::bigint;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002b","role":"authenticated"}', true);
select is((select count(*)::int from public.assignments), 0, 'members do not see drafts');
select throws_ok($$
  insert into public.assignments (team_id, session_id, part_id, user_id) values (current_setting('test.team')::bigint, current_setting('test.session')::bigint, current_setting('test.keys')::bigint, '00000000-0000-0000-0000-00000000002b')
$$, '42501', null, 'members cannot assign');
select throws_ok($$ select public.send_assignments(array[current_setting('test.session')::bigint]) $$, '42501', null, 'members cannot send');

-- ---- send
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
select is(public.send_assignments(array[current_setting('test.session')::bigint]), 1, 'leader sends the draft');
update public.assignments set user_id = '00000000-0000-0000-0000-00000000002c' where id = current_setting('test.a')::bigint;
select is((select user_id from public.assignments where id = current_setting('test.a')::bigint), '00000000-0000-0000-0000-00000000002b'::uuid, 'sent assignments change only through the RPCs');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002b","role":"authenticated"}', true);
select is((select status from public.assignments), 'pending', 'member sees the sent request');
select is((select count(*)::int from public.notifications where category = 'assignment_requested'), 1, 'member is notified');
select lives_ok($$ select public.respond_assignment(current_setting('test.a')::bigint, true) $$, 'member accepts');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002c","role":"authenticated"}', true);
select throws_ok($$ select public.respond_assignment(current_setting('test.a')::bigint, false, 'no') $$, '42501', null, 'cannot answer someone else''s request');

-- ---- setlist announcements go to the people serving and leaders
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
select set_config('test.song', public.add_song(current_setting('test.team')::bigint, '곡')::text, true);
insert into public.setlist_items (team_id, session_id, position, song_id, version_id)
select current_setting('test.team')::bigint, current_setting('test.session')::bigint, 1, v.song_id, v.id
from public.song_versions v where v.song_id = current_setting('test.song')::bigint;
select public.publish_setlist(current_setting('test.session')::bigint);
reset role;
select is(
  (select array_agg(user_id order by user_id) from public.notifications
   where category = 'setlist_published' and team_id = current_setting('test.team')::bigint),
  array['00000000-0000-0000-0000-00000000002b']::uuid[],
  'only the person serving is notified (the publishing leader is skipped)');
set local role authenticated;

-- ---- swap: Nari is blocked out that day, so Paul (no keys) and Nari cannot take it yet
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002c","role":"authenticated"}', true);
insert into public.blockouts (team_id, starts_on, ends_on)
select current_setting('test.team')::bigint, (s.starts_at at time zone 'Asia/Singapore')::date, (s.starts_at at time zone 'Asia/Singapore')::date
from public.sessions s where s.id = current_setting('test.session')::bigint;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002b","role":"authenticated"}', true);
select is((select count(*)::int from public.blockouts), 0, 'members do not see others'' blockouts');
select set_config('test.swap', public.request_swap(current_setting('test.a')::bigint, '가족 행사')::text, true);
reset role;
select is((select count(*)::int from public.notifications where category = 'swap_requested' and team_id = current_setting('test.team')::bigint), 0, 'nobody eligible yet: blocked out or wrong part');
set local role authenticated;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
select is((select count(*)::int from public.blockouts), 1, 'leaders see blockouts to plan');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002d","role":"authenticated"}', true);
select throws_ok($$ select public.accept_swap(current_setting('test.swap')::bigint) $$, '42501', null, 'someone without the part cannot take it');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002c","role":"authenticated"}', true);
select throws_ok($$ select public.accept_swap(current_setting('test.swap')::bigint) $$, '42501', null, 'blocked out that day: cannot take it');
delete from public.blockouts;
select lives_ok($$ select public.accept_swap(current_setting('test.swap')::bigint) $$, 'eligible teammate takes it');
select is((select user_id from public.assignments where id = current_setting('test.a')::bigint), '00000000-0000-0000-0000-00000000002c'::uuid, 'assignment moved to Nari');
select is((select status from public.assignments where id = current_setting('test.a')::bigint), 'accepted', 'and is accepted');
select throws_ok($$ select public.accept_swap(current_setting('test.swap')::bigint) $$, 'P0002', null, 'a filled request cannot be taken again');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002b","role":"authenticated"}', true);
select is((select count(*)::int from public.notifications where category = 'swap_filled'), 1, 'requester is told who took it');

-- ---- leader reassigns a sent assignment
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
select public.reassign_assignment(current_setting('test.a')::bigint, '00000000-0000-0000-0000-00000000002b');
reset role;
select is((select count(*)::int from public.notifications where category = 'assignment_removed' and user_id = '00000000-0000-0000-0000-00000000002c'), 1, 'the previous person is told');
select is((select count(*)::int from public.notifications where category = 'assignment_requested' and user_id = '00000000-0000-0000-0000-00000000002b'), 2, 'the new person gets a fresh request');
select is((select status from public.assignments where id = current_setting('test.a')::bigint), 'pending', 'the new person gets a fresh request');
set local role authenticated;

-- ---- rehearsal, RSVP, attendance
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
with ins as (insert into public.rehearsals (team_id, session_id, starts_at, created_by) values (current_setting('test.team')::bigint, current_setting('test.session')::bigint, now() + interval '1 hour', '00000000-0000-0000-0000-00000000002a') returning id)
select set_config('test.rh', (select id::text from ins), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002b","role":"authenticated"}', true);
select lives_ok($$ select public.set_rsvp(current_setting('test.rh')::bigint, 'late', '퇴근이 늦어요') $$, 'member answers the rehearsal');
select throws_ok($$ select public.record_attendance(current_setting('test.rh')::bigint, '00000000-0000-0000-0000-00000000002b', 'present') $$, '42501', null, 'members do not record attendance');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002a","role":"authenticated"}', true);
select public.record_attendance(current_setting('test.rh')::bigint, '00000000-0000-0000-0000-00000000002c', 'absent');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000002b","role":"authenticated"}', true);
select is((select count(*)::int from public.rehearsal_responses), 1, 'members see only their own response');

-- ---- reminders: rehearsal within 2h and an unanswered request, each once
reset role;
update public.assignments set sent_at = now() - interval '3 days' where id = current_setting('test.a')::bigint;
select private.enqueue_due_reminders();
select private.enqueue_due_reminders();
select is((select count(*)::int from public.notifications where category = 'assignment_nudge' and team_id = current_setting('test.team')::bigint), 1, 'unanswered request nudged once');
select is((select count(*)::int from public.notifications where category = 'rehearsal_reminder' and user_id = '00000000-0000-0000-0000-00000000002b'), 1, 'rehearsal reminder sent once');

select * from finish();
rollback;
