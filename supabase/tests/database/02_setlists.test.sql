-- Songs, sessions, setlists, publishing and statistics.
begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'leader@test.local', '{"full_name":"Leader"}', now(), now()),
  ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'member@test.local', '{"full_name":"Member"}', now(), now()),
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'out@test.local', '{"full_name":"Outsider"}', now(), now());

-- team: leader owns, member active
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000b1","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));

-- ---- member builds the song library
select lives_ok($$
  select public.add_song(current_setting('test.team')::bigint, '주의 집에 거하는 자', p_version_name => '마커스워십', p_key => 'G', p_bpm => 72),
         public.add_song(current_setting('test.team')::bigint, '은혜', p_key => 'D', p_bpm => 68),
         public.add_song(current_setting('test.team')::bigint, '나는 예배자입니다', p_key => 'A', p_bpm => 120)
$$, 'members add songs');
select throws_ok($$
  select public.add_song(current_setting('test.team')::bigint, 'Bad key', p_key => 'H')
$$, '23514', null, 'invalid musical key rejected');
select throws_ok($$
  insert into public.sessions (team_id, title, starts_at) values (current_setting('test.team')::bigint, 'x', now())
$$, '42501', null, 'members cannot create sessions');
-- RLS filters the delete to zero rows; the song must survive (checked below)
select lives_ok($$ delete from public.songs where title = '은혜' $$, 'member delete is filtered by RLS');

-- ---- storage paths: members of the team only
select lives_ok($$
  insert into storage.objects (bucket_id, name, owner_id) values ('sheets', current_setting('test.team') || '/a.pdf', '00000000-0000-0000-0000-0000000000b1')
$$, 'member uploads into own team folder');

-- ---- leader creates sessions and a draft setlist
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
with ins as (
  insert into public.sessions (team_id, title, starts_at)
  values (current_setting('test.team')::bigint, '주일 2부', now() - interval '7 days') returning id)
select set_config('test.past', (select id::text from ins), true);
with ins as (
  insert into public.sessions (team_id, title, starts_at)
  values (current_setting('test.team')::bigint, '금요 철야', now() + interval '3 days') returning id)
select set_config('test.future', (select id::text from ins), true);

insert into public.setlist_items (team_id, session_id, position, song_id, version_id, key, song_form)
select current_setting('test.team')::bigint, current_setting('test.past')::bigint, row_number() over (order by s.id), s.id, v.id, null, 'I-V1-C-B-C'
from public.songs s join public.song_versions v on v.song_id = s.id where s.title in ('주의 집에 거하는 자', '은혜');

select is((select count(*)::int from public.setlist_items where session_id = current_setting('test.past')::bigint), 2, 'leader sees draft setlist');
select throws_ok($$ select public.publish_setlist(current_setting('test.future')::bigint) $$, '22023', null, 'cannot publish an empty setlist');

-- ---- member cannot see the draft, cannot reorder or publish
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000b1","role":"authenticated"}', true);
select is((select count(*)::int from public.setlist_items), 0, 'member does not see draft setlist');
select throws_ok($$ select public.publish_setlist(current_setting('test.past')::bigint) $$, '42501', null, 'member cannot publish');
select throws_ok($$ select public.reorder_setlist(current_setting('test.past')::bigint, '{}') $$, '42501', null, 'member cannot reorder');
select is((select count(*)::int from public.songs where title = '은혜'), 1, 'member delete left the song in place');

-- the member opts in to every setlist (they are not serving in this one)
insert into public.notification_prefs (user_id, category, push_enabled) values ('00000000-0000-0000-0000-0000000000b1', 'setlist_all', true);

-- ---- leader publishes
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select is(public.publish_setlist(current_setting('test.past')::bigint), '{}'::jsonb, 'first publish has no change summary');
select is(public.publish_setlist(current_setting('test.past')::bigint), '{}'::jsonb, 'republish without changes is a no-op');
select is((select count(*)::int from public.announcements where kind = 'setlist'), 1, 'one setlist announcement per session');

-- ---- member now sees it and was notified once
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000b1","role":"authenticated"}', true);
select is((select count(*)::int from public.setlist_items where session_id = current_setting('test.past')::bigint), 2, 'member sees published setlist');
select is((select count(*)::int from public.notifications where category = 'setlist_published'), 1, 'opted-in member notified once');
select is(
  (select jsonb_array_length(params -> 'songs') from public.notifications where category = 'setlist_published'),
  2, 'notification lists the songs');

-- ---- leader changes key, adds a song, reorders -> change summary
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
update public.setlist_items set key = 'A'
where session_id = current_setting('test.past')::bigint
  and song_id = (select id from public.songs where title = '주의 집에 거하는 자');
insert into public.setlist_items (team_id, session_id, position, song_id, version_id)
select current_setting('test.team')::bigint, current_setting('test.past')::bigint, 3, s.id, v.id
from public.songs s join public.song_versions v on v.song_id = s.id where s.title = '나는 예배자입니다';
select lives_ok($$
  select public.reorder_setlist(
    current_setting('test.past')::bigint,
    array(select id from public.setlist_items where session_id = current_setting('test.past')::bigint order by position desc))
$$, 'leader reorders');
select set_config('test.summary', public.publish_setlist(current_setting('test.past')::bigint)::text, true);
select is(current_setting('test.summary')::jsonb -> 'added', '["나는 예배자입니다"]'::jsonb, 'summary lists the added song');
select is(current_setting('test.summary')::jsonb -> 'key_changed' -> 0 ->> 'to', 'A', 'summary lists the key change');
select is(current_setting('test.summary')::jsonb -> 'reordered', 'true'::jsonb, 'summary notes the new order');
select is(current_setting('test.summary')::jsonb -> 'removed', null, 'nothing removed');

-- ---- statistics
select is(
  (select times_played from public.song_stats where song_id = (select id from public.songs where title = '은혜')),
  1, 'played once (published, in the past)');
select is(
  (select usual_key from public.song_stats where song_id = (select id from public.songs where title = '주의 집에 거하는 자')),
  'A', 'usual key follows the setlist key');

insert into public.setlist_items (team_id, session_id, position, song_id, version_id)
select current_setting('test.team')::bigint, current_setting('test.future')::bigint, 1, s.id, v.id
from public.songs s join public.song_versions v on v.song_id = s.id where s.title = '은혜';
select public.publish_setlist(current_setting('test.future')::bigint);
select is(
  (select times_played from public.song_stats where song_id = (select id from public.songs where title = '은혜')),
  1, 'future sessions do not count as played');
select isnt(
  (select next_planned_at from public.song_stats where song_id = (select id from public.songs where title = '은혜')),
  null, 'future session shows as next planned');

-- ---- outsider sees nothing
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000c1","role":"authenticated"}', true);
select is((select count(*)::int from public.songs) + (select count(*)::int from public.sessions) + (select count(*)::int from public.song_stats), 0, 'outsider sees no songs, sessions or stats');
select throws_ok($$
  insert into storage.objects (bucket_id, name, owner_id) values ('sheets', current_setting('test.team') || '/b.pdf', '00000000-0000-0000-0000-0000000000c1')
$$, '42501', null, 'outsider cannot upload into the team folder');

select * from finish();
rollback;
