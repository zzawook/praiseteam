-- Channels, chat, read state privacy, announcements and polls.
begin;
create extension if not exists pgtap with schema extensions;
select plan(33);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000003a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l3@test.local', '{"full_name":"Lead"}', now(), now()),
  ('00000000-0000-0000-0000-00000000003b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 's3@test.local', '{"full_name":"Singer"}', now(), now()),
  ('00000000-0000-0000-0000-00000000003c', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'k3@test.local', '{"full_name":"Keys"}', now(), now()),
  ('00000000-0000-0000-0000-00000000003d', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'o3@test.local', '{"full_name":"Out"}', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select is((select array_agg(name order by id) from public.channels), array['전체', '싱어팀', '악기팀'], 'a new team gets the default channels');
select set_config('test.all', (select id::text from public.channels where name = '전체'), true);
select set_config('test.singers', (select id::text from public.channels where name = '싱어팀'), true);
select set_config('test.band', (select id::text from public.channels where name = '악기팀'), true);

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000003b',
  array(select id from public.parts where team_id = current_setting('test.team')::bigint and name = '싱어'));
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000003c',
  array(select id from public.parts where team_id = current_setting('test.team')::bigint and name = '건반'));

-- ---- channel visibility follows parts
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
select is((select array_agg(name order by id) from public.channels), array['전체', '싱어팀'], 'singer sees the team and singers channels');
select lives_ok($$
  insert into public.messages (id, team_id, channel_id, body) values
    ('20000000-0000-0000-0000-000000000001', current_setting('test.team')::bigint, current_setting('test.singers')::bigint, '화음 연습 7시')
$$, 'singer posts in the singers channel');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
select is((select array_agg(name order by id) from public.channels), array['전체', '악기팀'], 'keys player sees the team and band channels');
select is((select count(*)::int from public.messages), 0, 'keys player cannot read the singers channel');
select throws_ok($$
  insert into public.messages (id, team_id, channel_id, body) values (gen_random_uuid(), current_setting('test.team')::bigint, current_setting('test.singers')::bigint, 'hi')
$$, '42501', null, 'cannot post in a channel you are not in');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003a","role":"authenticated"}', true);
select is((select count(*)::int from public.channels), 3, 'leaders see every channel');
select is((select count(*)::int from public.messages), 1, 'and read every channel');

-- ---- chat notifications: channel members except the sender, push only
reset role;
select is(
  (select array_agg(user_id order by user_id) from public.notifications where category = 'chat_message' and team_id = current_setting('test.team')::bigint),
  array['00000000-0000-0000-0000-00000000003a']::uuid[],
  'only the leader is notified (the keys player is not in that channel, the sender is skipped)');
select is((select bool_and(not listed) from public.notifications where category = 'chat_message' and team_id = current_setting('test.team')::bigint), true, 'chat notifications stay out of the notification list');
set local role authenticated;

-- leader mutes the singers channel
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003a","role":"authenticated"}', true);
insert into public.channel_reads (team_id, channel_id, muted) values (current_setting('test.team')::bigint, current_setting('test.singers')::bigint, true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
insert into public.messages (id, team_id, channel_id, body) values ('20000000-0000-0000-0000-000000000002', current_setting('test.team')::bigint, current_setting('test.singers')::bigint, '둘째');
reset role;
select is((select count(*)::int from public.notifications where category = 'chat_message' and team_id = current_setting('test.team')::bigint), 1, 'a muted channel sends no push');
set local role authenticated;

-- ---- changing parts moves you into channels
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
select public.set_member_parts(current_setting('test.team')::bigint, '00000000-0000-0000-0000-00000000003c',
  array(select id from public.parts where team_id = current_setting('test.team')::bigint and name in ('건반', '싱어')));
select is((select count(*)::int from public.messages where channel_id = current_setting('test.singers')::bigint), 2, 'adding a part opens that channel, history included');

-- ---- unread counts and read-state privacy
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
insert into public.messages (id, team_id, channel_id, body) values ('20000000-0000-0000-0000-000000000003', current_setting('test.team')::bigint, current_setting('test.all')::bigint, '전체 공지');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
select is((select unread from public.my_channels(current_setting('test.team')::bigint) where name = '전체'), 1, 'one unread in the team channel');
insert into public.channel_reads (team_id, channel_id, last_read_at) values (current_setting('test.team')::bigint, current_setting('test.all')::bigint, now() + interval '1 second');
select is((select unread from public.my_channels(current_setting('test.team')::bigint) where name = '전체'), 0, 'reading clears it');
select lives_ok($$ select public.mark_channel_read(current_setting('test.all')::bigint); select public.mark_channel_read(current_setting('test.all')::bigint) $$, 'marking read works first time and again');
select lives_ok($$ select public.mark_announcements_seen(current_setting('test.team')::bigint); select public.mark_announcements_seen(current_setting('test.team')::bigint) $$, 'marking announcements seen is repeatable');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003a","role":"authenticated"}', true);
select is((select count(*)::int from public.channel_reads where user_id <> '00000000-0000-0000-0000-00000000003a'), 0, 'nobody, not even a leader, can see who read what');
reset role;
select ok(not has_column_privilege('authenticated', 'public.messages', 'channel_id', 'update'), 'messages cannot be moved to another channel');
set local role authenticated;

-- ---- deleting: own messages only, and the text is gone
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
update public.messages set deleted_at = now(), body = null where id = '20000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
select is((select body from public.messages where id = '20000000-0000-0000-0000-000000000001'), '화음 연습 7시', 'cannot delete someone else''s message');
update public.messages set deleted_at = now(), body = null where id = '20000000-0000-0000-0000-000000000001';
select is((select body from public.messages where id = '20000000-0000-0000-0000-000000000001'), null, 'deleting my message removes its text');

-- ---- session chat: the people serving
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003a","role":"authenticated"}', true);
with ins as (insert into public.sessions (team_id, title, starts_at) values (current_setting('test.team')::bigint, '주일', now() + interval '3 days') returning id)
select set_config('test.session', (select id::text from ins), true);
insert into public.assignments (team_id, session_id, part_id, user_id)
select current_setting('test.team')::bigint, current_setting('test.session')::bigint, id, '00000000-0000-0000-0000-00000000003b'
from public.parts where team_id = current_setting('test.team')::bigint and name = '싱어';
select is((select count(*)::int from public.channels where kind = 'session'), 0, 'drafts do not open a session chat');
select public.send_assignments(array[current_setting('test.session')::bigint]);
select is((select count(*)::int from public.channels where kind = 'session'), 1, 'sending opens the session chat');
select set_config('test.session_chat', (select id::text from public.channels where kind = 'session'), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
select is((select count(*)::int from public.channels where kind = 'session'), 1, 'the person serving is in it');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
select is((select count(*)::int from public.channels where kind = 'session'), 0, 'others are not');

-- archived channels are read-only
reset role;
update public.channels set archived_at = now() where id = current_setting('test.session_chat')::bigint;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
select throws_ok($$
  insert into public.messages (id, team_id, channel_id, body) values (gen_random_uuid(), current_setting('test.team')::bigint, current_setting('test.session_chat')::bigint, 'late')
$$, '42501', null, 'archived chats are read-only');

-- ---- polls
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
select set_config('test.poll', public.create_poll(current_setting('test.team')::bigint, '회식 언제?', array['금', '토'], current_setting('test.all')::bigint)::text, true);
select is((select count(*)::int from public.messages where poll_id = current_setting('test.poll')::bigint), 1, 'a chat poll is posted as a message');
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003b","role":"authenticated"}', true);
select throws_ok($$
  select public.poll_vote(current_setting('test.poll')::bigint, array(select id from public.poll_options where poll_id = current_setting('test.poll')::bigint))
$$, '22023', null, 'single-choice poll takes one option');
select public.poll_vote(current_setting('test.poll')::bigint, array(select id from public.poll_options where poll_id = current_setting('test.poll')::bigint and label = '토'));
select is((select votes from public.poll_results(current_setting('test.poll')::bigint) where label = '토'), 1, 'vote counted');
select is((select voters from public.poll_results(current_setting('test.poll')::bigint) where label = '토'), array['Singer'], 'named poll shows voters');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003c","role":"authenticated"}', true);
select is((select count(*)::int from public.poll_votes), 0, 'other people''s vote rows are not readable');
select set_config('test.anon', public.create_poll(current_setting('test.team')::bigint, '익명', array['A', 'B'], current_setting('test.all')::bigint, null, false, true)::text, true);
select public.poll_vote(current_setting('test.anon')::bigint, array(select id from public.poll_options where poll_id = current_setting('test.anon')::bigint and label = 'A'));
select is((select voters from public.poll_results(current_setting('test.anon')::bigint) where label = 'A'), null, 'anonymous poll hides voters');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003d","role":"authenticated"}', true);
select throws_ok($$ select * from public.poll_results(current_setting('test.poll')::bigint) $$, 'P0002', null, 'outsiders cannot see polls');

-- ---- announcements notify the team and are listed
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000003a","role":"authenticated"}', true);
insert into public.announcements (team_id, kind, title, body, created_by) values (current_setting('test.team')::bigint, 'general', '수련회 안내', '11월 셋째 주', '00000000-0000-0000-0000-00000000003a');
reset role;
select is((select count(*)::int from public.notifications where category = 'announcement' and listed and team_id = current_setting('test.team')::bigint), 2, 'both members get a listed announcement notification');

select * from finish();
rollback;
