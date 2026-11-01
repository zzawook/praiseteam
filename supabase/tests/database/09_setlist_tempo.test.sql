-- A song's tempo for one service: kept with the service, counted as the
-- same song, and reported when it changes after an announcement.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000009a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l9@test.local', '{"full_name":"Lead"}', now(), now()),
  ('00000000-0000-0000-0000-00000000009b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm9@test.local', '{"full_name":"Member"}', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000009a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select set_config('test.song', public.add_song(current_setting('test.team')::bigint, '은혜', p_key => 'D', p_bpm => 68)::text, true);
select set_config('test.version', (select id::text from public.song_versions where song_id = current_setting('test.song')::bigint), true);

-- two past services play the song: one at its usual tempo, one faster
with ins as (insert into public.sessions (team_id, title, starts_at) values (current_setting('test.team')::bigint, '주일 1부', now() - interval '14 days') returning id)
select set_config('test.usual', (select id::text from ins), true);
with ins as (insert into public.sessions (team_id, title, starts_at) values (current_setting('test.team')::bigint, '주일 2부', now() - interval '7 days') returning id)
select set_config('test.faster', (select id::text from ins), true);
insert into public.setlist_items (team_id, session_id, position, song_id, version_id)
values (current_setting('test.team')::bigint, current_setting('test.usual')::bigint, 1, current_setting('test.song')::bigint, current_setting('test.version')::bigint);
insert into public.setlist_items (team_id, session_id, position, song_id, version_id, bpm)
values (current_setting('test.team')::bigint, current_setting('test.faster')::bigint, 1, current_setting('test.song')::bigint, current_setting('test.version')::bigint, 76);
select public.publish_setlist(current_setting('test.usual')::bigint);
select is(public.publish_setlist(current_setting('test.faster')::bigint), '{}'::jsonb, 'first announcement has no change summary');

select is(
  (select setlist_snapshot -> 0 -> 'bpm' from public.announcements where session_id = current_setting('test.faster')::bigint),
  '76'::jsonb, 'the announcement keeps the tempo');
select is(
  (select string_agg(bpm::text, ',' order by starts_at) from public.song_history where song_id = current_setting('test.song')::bigint),
  '68,76', 'history shows each service''s tempo, the version''s own when not set');
select is(
  (select times_played from public.song_stats where song_id = current_setting('test.song')::bigint),
  2, 'both count as the same song');

-- the tempo changes after the announcement
update public.setlist_items set bpm = 72 where session_id = current_setting('test.faster')::bigint;
select set_config('test.summary', public.publish_setlist(current_setting('test.faster')::bigint)::text, true);
select is(
  current_setting('test.summary')::jsonb -> 'tempo_changed',
  '[{"title": "은혜", "from": 76, "to": 72}]'::jsonb, 'a re-announcement reports the tempo change');
select is(current_setting('test.summary')::jsonb - 'tempo_changed', '{}'::jsonb, 'and nothing else');

-- announcements made before tempos were kept report no tempo change
select is(
  private.setlist_diff('[{"song_id": 1, "title": "은혜", "key": "D"}]', '[{"song_id": 1, "title": "은혜", "key": "D", "bpm": 68}]'),
  '{}'::jsonb, 'no tempo change against an announcement without tempos');

-- members cannot change a tempo (RLS filters the update to no rows)
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000009b","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
update public.setlist_items set bpm = 120;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000009a","role":"authenticated"}', true);
select is(
  (select string_agg(coalesce(bpm::text, '-'), ',' order by session_id) from public.setlist_items),
  '-,72', 'member edits changed nothing');
select throws_ok($$
  update public.setlist_items set bpm = 400 where session_id = current_setting('test.faster')::bigint
$$, '23514', null, 'tempo stays within 20 to 300');

select * from finish();
rollback;
