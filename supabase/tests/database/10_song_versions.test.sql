-- Song versions: a song with its versions, setlist entries that play one
-- version of their own song from that version's sheet, and history and
-- announcements that keep which version was played.
begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l10@test.local', '{"full_name":"Lead"}', now(), now()),
  ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm10@test.local', '{"full_name":"Keys"}', now(), now()),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'o10@test.local', '{"full_name":"Outsider"}', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000100","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000101","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));

-- ---- a member adds a song with its first version, then a second version
select set_config('test.song', public.add_song(
  current_setting('test.team')::bigint, '  주의 집에 거하는 자 ', '4/4', array['빠른'], null, ' 마커스워십 ', 'G', 72)::text, true);
select is(
  (select s.title || '|' || v.name || '|' || v.default_key || '|' || v.bpm
   from public.songs s join public.song_versions v on v.song_id = s.id where s.id = current_setting('test.song')::bigint),
  '주의 집에 거하는 자|마커스워십|G|72', 'add_song stores the song and its first version, trimmed');
select set_config('test.marcus', (select id::text from public.song_versions where song_id = current_setting('test.song')::bigint), true);
with ins as (
  insert into public.song_versions (team_id, song_id, name, default_key, bpm)
  values (current_setting('test.team')::bigint, current_setting('test.song')::bigint, '어노인팅', 'A', 76) returning id)
select set_config('test.anointing', (select id::text from ins), true);
select is((select count(*)::int from public.song_versions where song_id = current_setting('test.song')::bigint), 2, 'members add versions');
select is(public.add_song(current_setting('test.team')::bigint, '빈 버전', p_version_name => '   ') is not null, true, 'a blank version name is allowed');
select is((select name from public.song_versions v join public.songs s on s.id = v.song_id where s.title = '빈 버전'), null, 'and stored as no name');

-- each version keeps its own sheet and link
with sh as (
  insert into public.sheets (team_id, version_id, key, storage_path, page_count, page_sizes, size_bytes)
  values (current_setting('test.team')::bigint, current_setting('test.marcus')::bigint, 'G', current_setting('test.team') || '/g.pdf', 1, '[[595,842]]', 100),
         (current_setting('test.team')::bigint, current_setting('test.anointing')::bigint, 'A', current_setting('test.team') || '/a.pdf', 1, '[[595,842]]', 100)
  returning id, key)
select set_config('test.sheet_g', (select id::text from sh where key = 'G'), true),
       set_config('test.sheet_a', (select id::text from sh where key = 'A'), true);
insert into public.song_links (team_id, version_id, url)
values (current_setting('test.team')::bigint, current_setting('test.anointing')::bigint, 'https://youtu.be/x');

-- ---- the leader plays one version of the song, from that version's sheet
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000100","role":"authenticated"}', true);
with ins as (insert into public.sessions (team_id, title, starts_at) values
  (current_setting('test.team')::bigint, '지난주', now() - interval '7 days'),
  (current_setting('test.team')::bigint, '이번 주', now() + interval '3 days') returning id, title)
select set_config('test.past', (select id::text from ins where title = '지난주'), true),
       set_config('test.next', (select id::text from ins where title = '이번 주'), true);
select set_config('test.other_version', (select v.id::text from public.song_versions v join public.songs s on s.id = v.song_id where s.title = '빈 버전'), true);

select throws_ok($$
  insert into public.setlist_items (team_id, session_id, position, song_id, version_id)
  values (current_setting('test.team')::bigint, current_setting('test.past')::bigint, 1, current_setting('test.song')::bigint, current_setting('test.other_version')::bigint)
$$, '23503', null, 'an entry cannot play a version of another song');
select throws_ok($$
  insert into public.setlist_items (team_id, session_id, position, song_id, version_id, sheet_id)
  values (current_setting('test.team')::bigint, current_setting('test.past')::bigint, 1, current_setting('test.song')::bigint, current_setting('test.marcus')::bigint, current_setting('test.sheet_a')::bigint)
$$, '23503', null, 'an entry cannot show another version''s sheet');

insert into public.setlist_items (team_id, session_id, position, song_id, version_id, key, sheet_id)
values (current_setting('test.team')::bigint, current_setting('test.past')::bigint, 1, current_setting('test.song')::bigint, current_setting('test.marcus')::bigint, 'G', current_setting('test.sheet_g')::bigint),
       (current_setting('test.team')::bigint, current_setting('test.next')::bigint, 1, current_setting('test.song')::bigint, current_setting('test.marcus')::bigint, 'G', current_setting('test.sheet_g')::bigint);
select public.publish_setlist(current_setting('test.past')::bigint);
select public.publish_setlist(current_setting('test.next')::bigint);

select is(
  (select version_name || ' ' || key || ' ' || bpm from public.song_history where session_id = current_setting('test.past')::bigint),
  '마커스워십 G 72', 'history keeps the version, its key and tempo');
select is(
  (select last_version_id::text from public.song_stats where song_id = current_setting('test.song')::bigint),
  current_setting('test.marcus'), 'statistics know the version played last');

-- ---- switching versions, then announcing again
select lives_ok($$
  update public.setlist_items
  set version_id = current_setting('test.anointing')::bigint, sheet_id = current_setting('test.sheet_a')::bigint, key = 'A', bpm = 76
  where session_id = current_setting('test.next')::bigint
$$, 'an entry switches to another version of its song');
select is(
  public.publish_setlist(current_setting('test.next')::bigint),
  '{"version_changed": [{"title": "주의 집에 거하는 자", "from": "마커스워십", "to": "어노인팅"}],
    "key_changed": [{"title": "주의 집에 거하는 자", "from": "G", "to": "A"}],
    "tempo_changed": [{"title": "주의 집에 거하는 자", "from": 72, "to": 76}]}'::jsonb,
  'a re-announcement reports the version, key and tempo change');
select is(
  private.setlist_diff('[{"song_id": 1, "title": "A", "key": "G"}]', '[{"song_id": 1, "title": "A", "key": "G", "version_id": 5, "version": "X"}]'),
  '{}'::jsonb, 'no version change against an announcement without versions');

-- ---- versions in use stay; members delete only their own
select throws_ok($$ delete from public.song_versions where id = current_setting('test.anointing')::bigint $$,
  '23503', null, 'a version a setlist plays cannot be deleted');
with ins as (
  insert into public.song_versions (team_id, song_id, name)
  values (current_setting('test.team')::bigint, current_setting('test.song')::bigint, '리더 편곡') returning id)
select set_config('test.leaders', (select id::text from ins), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000101","role":"authenticated"}', true);
delete from public.song_versions where id = current_setting('test.leaders')::bigint; -- not theirs: filtered
select is((select count(*)::int from public.song_versions where id = current_setting('test.leaders')::bigint), 1, 'members cannot delete others'' versions');
select lives_ok($$ delete from public.song_versions where id = current_setting('test.other_version')::bigint $$, 'members delete their own unused versions');

-- ---- deleting a song takes its versions, sheets and links along
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000100","role":"authenticated"}', true);
delete from public.setlist_items where song_id = current_setting('test.song')::bigint;
delete from public.songs where id = current_setting('test.song')::bigint;
select is(
  (select count(*)::int from public.song_versions where song_id = current_setting('test.song')::bigint)
  + (select count(*)::int from public.sheets where version_id in (current_setting('test.marcus')::bigint, current_setting('test.anointing')::bigint))
  + (select count(*)::int from public.song_links where version_id = current_setting('test.anointing')::bigint),
  0, 'versions, sheets and links go with the song');

-- ---- other teams see none
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000102","role":"authenticated"}', true);
select is((select count(*)::int from public.song_versions), 0, 'other teams see no versions');
select throws_ok($$ select public.add_song(current_setting('test.team')::bigint, 'x') $$, '42501', null, 'outsiders cannot add songs');

reset role;
select ok(
  not has_table_privilege('anon', 'public.song_versions', 'select')
  and not has_function_privilege('anon', 'public.add_song(bigint, text, text, text[], text, text, text, integer)', 'execute'),
  'signed-out users cannot read versions or add songs');

select * from finish();
rollback;
