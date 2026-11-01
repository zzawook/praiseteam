-- Annotations: private strokes are visible to their owner only (leaders
-- included), team strokes to the team; strokes belong to one service.
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000001a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l@test.local', '{"full_name":"Leader"}', now(), now()),
  ('00000000-0000-0000-0000-00000000001b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm@test.local', '{"full_name":"Mina"}', now(), now()),
  ('00000000-0000-0000-0000-00000000001c', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'n@test.local', '{"full_name":"Noah"}', now(), now()),
  ('00000000-0000-0000-0000-00000000001d', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'o@test.local', '{"full_name":"Out"}', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.team')::bigint;
select set_config('test.code', (select invite_code from public.teams where id = current_setting('test.team')::bigint), true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001b","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001c","role":"authenticated"}', true);
select public.join_team(current_setting('test.code'));

-- leader: song + sheet + two sessions (earlier published, later published, plus a draft)
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001a","role":"authenticated"}', true);
select set_config('test.song', public.add_song(current_setting('test.team')::bigint, '은혜')::text, true);
select set_config('test.version', (select id::text from public.song_versions where song_id = current_setting('test.song')::bigint), true);
with sh as (
  insert into public.sheets (team_id, version_id, storage_path, page_count, page_sizes, size_bytes, uploaded_by)
  values (current_setting('test.team')::bigint, current_setting('test.version')::bigint, current_setting('test.team') || '/s.pdf', 1, '[[595,842]]', 100, '00000000-0000-0000-0000-00000000001a')
  returning id)
select set_config('test.sheet', (select id::text from sh), true);

with ins as (insert into public.sessions (team_id, title, starts_at) values
  (current_setting('test.team')::bigint, 'early', now() - interval '14 days'),
  (current_setting('test.team')::bigint, 'later', now() + interval '1 day'),
  (current_setting('test.team')::bigint, 'draft', now() + interval '8 days') returning id, title)
select set_config('test.early', (select id::text from ins where title = 'early'), true),
       set_config('test.later', (select id::text from ins where title = 'later'), true),
       set_config('test.draft', (select id::text from ins where title = 'draft'), true);

insert into public.setlist_items (team_id, session_id, position, song_id, version_id, sheet_id)
select current_setting('test.team')::bigint, s, 1, current_setting('test.song')::bigint, current_setting('test.version')::bigint, current_setting('test.sheet')::bigint
from unnest(array[current_setting('test.early')::bigint, current_setting('test.later')::bigint, current_setting('test.draft')::bigint]) as s;
select public.publish_setlist(current_setting('test.early')::bigint);
select public.publish_setlist(current_setting('test.later')::bigint);

select set_config('test.item_early', (select id::text from public.setlist_items where session_id = current_setting('test.early')::bigint), true);
select set_config('test.item_later', (select id::text from public.setlist_items where session_id = current_setting('test.later')::bigint), true);
select set_config('test.item_draft', (select id::text from public.setlist_items where session_id = current_setting('test.draft')::bigint), true);

-- ---- Mina draws one private and one team stroke on the early service
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001b","role":"authenticated"}', true);
select lives_ok($$
  insert into public.strokes (id, team_id, session_id, setlist_item_id, sheet_id, page_index, visibility, tool, color, width, points)
  values
    ('10000000-0000-0000-0000-000000000001', current_setting('test.team')::bigint, current_setting('test.early')::bigint, current_setting('test.item_early')::bigint, current_setting('test.sheet')::bigint, 0, 'private', 'pen', -16777216, 0.004, '\x0000000080ffffffff80'),
    ('10000000-0000-0000-0000-000000000002', current_setting('test.team')::bigint, current_setting('test.early')::bigint, current_setting('test.item_early')::bigint, current_setting('test.sheet')::bigint, 0, 'team', 'pen', -14090062, 0.004, '\x0000000080ffffffff80')
$$, 'member draws private and team strokes');
select lives_ok($$
  insert into public.strokes (id, team_id, session_id, setlist_item_id, sheet_id, page_index, visibility, tool, color, width, points)
  values ('10000000-0000-0000-0000-000000000001', current_setting('test.team')::bigint, current_setting('test.early')::bigint, current_setting('test.item_early')::bigint, current_setting('test.sheet')::bigint, 0, 'private', 'pen', 0, 0.004, '\x0000000080')
  on conflict (id) do nothing
$$, 're-uploading the same stroke is a no-op');
select is((select count(*)::int from public.strokes), 2, 'owner sees both of her strokes');
select throws_ok($$
  insert into public.strokes (id, team_id, session_id, setlist_item_id, sheet_id, page_index, owner_id, visibility, tool, color, width, points)
  values (gen_random_uuid(), current_setting('test.team')::bigint, current_setting('test.early')::bigint, current_setting('test.item_early')::bigint, current_setting('test.sheet')::bigint, 0, '00000000-0000-0000-0000-00000000001c', 'private', 'pen', 0, 0.004, '\x0000000080')
$$, '42501', null, 'cannot draw as someone else');
select throws_ok($$
  insert into public.strokes (id, team_id, session_id, setlist_item_id, sheet_id, page_index, visibility, tool, color, width, points)
  values (gen_random_uuid(), current_setting('test.team')::bigint, current_setting('test.draft')::bigint, current_setting('test.item_draft')::bigint, current_setting('test.sheet')::bigint, 0, 'private', 'pen', 0, 0.004, '\x0000000080')
$$, '42501', null, 'members cannot draw on a draft setlist they cannot see');
select throws_ok($$
  insert into public.strokes (id, team_id, session_id, setlist_item_id, sheet_id, page_index, visibility, tool, color, width, points)
  values (gen_random_uuid(), current_setting('test.team')::bigint, current_setting('test.early')::bigint, current_setting('test.item_early')::bigint, current_setting('test.sheet')::bigint, 0, 'private', 'pen', 0, 0.004, '\x00000000')
$$, '23514', null, 'points must be whole 5-byte points');
select throws_ok($$
  insert into public.strokes (id, team_id, session_id, setlist_item_id, sheet_id, page_index, visibility, tool, color, width, points)
  values (gen_random_uuid(), current_setting('test.team')::bigint, current_setting('test.later')::bigint, current_setting('test.item_early')::bigint, current_setting('test.sheet')::bigint, 0, 'private', 'pen', 0, 0.004, '\x0000000080')
$$, '23503', null, 'a stroke cannot claim another service than its setlist item');

-- ---- Noah (member): team stroke only
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001c","role":"authenticated"}', true);
select is((select count(*)::int from public.strokes), 1, 'teammate sees the team stroke only');
select is((select visibility from public.strokes), 'team', 'and it is the team one');
update public.strokes set deleted_at = now() where id = '10000000-0000-0000-0000-000000000002';

-- ---- Leader: team stroke yes, Mina's private stroke no
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001a","role":"authenticated"}', true);
select is((select deleted_at from public.strokes where id = '10000000-0000-0000-0000-000000000002'), null, 'a member cannot erase someone else''s team stroke');
select is((select count(*)::int from public.strokes), 1, 'even leaders cannot see a member''s private stroke');
update public.strokes set deleted_at = now() where id = '10000000-0000-0000-0000-000000000001';
update public.strokes set deleted_at = now() where id = '10000000-0000-0000-0000-000000000002';
select isnt((select deleted_at from public.strokes where id = '10000000-0000-0000-0000-000000000002'), null, 'leaders can erase team strokes');

-- ---- Mina: private stroke untouched by the leader; she can un-erase the team one
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001b","role":"authenticated"}', true);
select is((select deleted_at from public.strokes where id = '10000000-0000-0000-0000-000000000001'), null, 'leader could not erase the private stroke');
update public.strokes set deleted_at = null where id = '10000000-0000-0000-0000-000000000002';
select is((select deleted_at from public.strokes where id = '10000000-0000-0000-0000-000000000002'), null, 'owner un-erases (undo)');

-- ---- strokes are per service; copying brings them to the later one
select is((select count(*)::int from public.strokes where setlist_item_id = current_setting('test.item_later')::bigint), 0, 'later service starts with a clean sheet');
select is(public.copy_previous_strokes(current_setting('test.item_later')::bigint), 2, 'copy brings both of my strokes');
select is((select count(*)::int from public.strokes where setlist_item_id = current_setting('test.item_early')::bigint), 2, 'originals stay on the earlier service');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001c","role":"authenticated"}', true);
select is((select count(*)::int from public.strokes where setlist_item_id = current_setting('test.item_later')::bigint), 1, 'a copied private stroke stays private');

-- ---- outsider sees nothing
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000001d","role":"authenticated"}', true);
select is((select count(*)::int from public.strokes), 0, 'outsider sees no strokes');

-- ---- privilege surface
reset role;
select ok(not has_column_privilege('authenticated', 'public.strokes', 'points', 'update'), 'strokes cannot be edited, only erased');
select ok(not has_table_privilege('authenticated', 'public.strokes', 'delete'), 'strokes are never hard-deleted by clients');

select * from finish();
rollback;
