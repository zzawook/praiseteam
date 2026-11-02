begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

insert into auth.users (id, email) values
  ('dddd0000-0000-0000-0000-000000000001', 'delete-owner@test.local'),
  ('dddd0000-0000-0000-0000-000000000002', 'delete-member@test.local'),
  ('dddd0000-0000-0000-0000-000000000003', 'delete-coowner@test.local');
insert into auth.sessions (id, user_id) values
  ('dddd1111-0000-0000-0000-000000000001', 'dddd0000-0000-0000-0000-000000000001'),
  ('dddd1111-0000-0000-0000-000000000002', 'dddd0000-0000-0000-0000-000000000002');

select ok(not has_function_privilege('anon', 'public.delete_account()', 'execute'), 'anonymous callers cannot delete accounts');
select ok(not has_function_privilege('authenticated', 'private.request_storage_cleanup()', 'execute'), 'clients cannot dispatch storage deletion');
select ok(not has_table_privilege('authenticated', 'private.storage_cleanup_queue', 'select'), 'cleanup paths are private');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-0000-0000-000000000001","role":"authenticated","session_id":"dddd1111-0000-0000-0000-000000000001"}', true);
select set_config('test.shared', public.create_team('Shared deletion test')::text, true);
reset role;
insert into public.team_members (team_id, user_id, status, approved_at)
values (current_setting('test.shared')::bigint, 'dddd0000-0000-0000-0000-000000000002', 'active', now());

set local role authenticated;
select is((public.account_deletion_info() -> 'blocked_teams')::text, '["Shared deletion test"]', 'last owner is told which team needs another owner');
select throws_ok('select public.delete_account()', 'PT001', 'transfer team ownership before deleting your account', 'last owner cannot abandon teammates');
reset role;
select is((select count(*) from auth.users where id = 'dddd0000-0000-0000-0000-000000000001'), 1::bigint, 'blocked deletion leaves the account intact');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-0000-0000-000000000002","role":"authenticated","session_id":"dddd1111-0000-0000-0000-000000000002"}', true);
select set_config('test.solo', public.create_team('Solo deletion test')::text, true);
select set_config('test.shared_song', public.add_song(current_setting('test.shared')::bigint, 'Keep this song')::text, true);
select set_config('test.solo_song', public.add_song(current_setting('test.solo')::bigint, 'Delete this song')::text, true);
select is((public.account_deletion_info() -> 'deleted_teams')::text, '["Solo deletion test"]', 'sole-member team is listed before confirming');
select is((public.account_deletion_info() -> 'blocked_teams')::text, '[]', 'ordinary membership does not block deletion');
select public.register_device_token('delete-test-device', 'web');
reset role;

insert into storage.objects (bucket_id, name, owner, owner_id) values
  ('sheets', current_setting('test.shared') || '/shared.pdf', 'dddd0000-0000-0000-0000-000000000002', 'dddd0000-0000-0000-0000-000000000002'),
  ('sheets', current_setting('test.solo') || '/solo.pdf', 'dddd0000-0000-0000-0000-000000000002', 'dddd0000-0000-0000-0000-000000000002');
insert into public.sheets (team_id, version_id, storage_path, page_count, page_sizes, size_bytes, uploaded_by)
select v.team_id, v.id, v.team_id || case when v.team_id = current_setting('test.solo')::bigint then '/solo.pdf' else '/shared.pdf' end,
       1, '[[595,842]]', 10, 'dddd0000-0000-0000-0000-000000000002'
from public.song_versions v where v.song_id in (current_setting('test.shared_song')::bigint, current_setting('test.solo_song')::bigint);
insert into public.sessions (team_id, title, starts_at)
values (current_setting('test.solo')::bigint, 'Solo service', now());
insert into public.setlist_items (team_id, session_id, position, song_id, version_id, sheet_id)
select s.team_id, s.id, 1, v.song_id, v.id, sh.id
from public.sessions s join public.song_versions v on v.team_id = s.team_id
join public.sheets sh on sh.version_id = v.id where s.team_id = current_setting('test.solo')::bigint;
insert into private.reminders_sent (kind, target_id, user_id)
values ('nudge', 999999, 'dddd0000-0000-0000-0000-000000000002');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-0000-0000-000000000002","role":"authenticated"}', true);
select throws_ok('select public.delete_account()', '42501', 'sign in again before deleting your account', 'a live session is required');
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-0000-0000-000000000002","role":"authenticated","session_id":"dddd1111-0000-0000-0000-000000000002"}', true);
select lives_ok('select public.delete_account()', 'member can delete own account and sole-member team');
reset role;
select is((select count(*) from auth.users where id = 'dddd0000-0000-0000-0000-000000000002'), 0::bigint, 'auth account is deleted');
select is((select count(*) from auth.sessions where user_id = 'dddd0000-0000-0000-0000-000000000002'), 0::bigint, 'all sessions are revoked');
select is((select count(*) from public.profiles where id = 'dddd0000-0000-0000-0000-000000000002'), 0::bigint, 'profile is deleted');
select is((select count(*) from public.team_members where user_id = 'dddd0000-0000-0000-0000-000000000002'), 0::bigint, 'memberships are removed');
select is((select count(*) from public.device_tokens where token = 'delete-test-device'), 0::bigint, 'push registration is removed');
select is((select count(*) from private.reminders_sent where user_id = 'dddd0000-0000-0000-0000-000000000002'), 0::bigint, 'private reminder records are removed');
select is((select count(*) from public.teams where id = current_setting('test.solo')::bigint), 0::bigint, 'sole-member team is removed despite setlist references');
select is((select count(*) from public.songs where id = current_setting('test.shared_song')::bigint and created_by is null), 1::bigint, 'shared song survives with no author');
select is((select count(*) from public.sheets where storage_path = current_setting('test.shared') || '/shared.pdf' and uploaded_by is null), 1::bigint, 'shared sheet survives with no uploader');
select is((select count(*) from storage.objects where name = current_setting('test.shared') || '/shared.pdf' and owner is null and owner_id is null), 1::bigint, 'shared PDF stays and loses personal ownership');
select is((select count(*) from private.storage_cleanup_queue where storage_path = current_setting('test.solo') || '/solo.pdf'), 1::bigint, 'solo PDF is durably queued for Storage API deletion');

set local role authenticated;
select throws_ok($$select public.create_team('stale token')$$, '42501', 'not authenticated', 'deleted JWT cannot bootstrap a team');
reset role;
insert into public.team_members (team_id, user_id, role, status, approved_at)
values (current_setting('test.shared')::bigint, 'dddd0000-0000-0000-0000-000000000003', 'owner', 'active', now());
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-0000-0000-000000000001","role":"authenticated","session_id":"dddd1111-0000-0000-0000-000000000001"}', true);
select lives_ok('select public.delete_account()', 'owner can delete after another owner is in place');
reset role;
select is((select count(*) from public.team_members where team_id = current_setting('test.shared')::bigint and role = 'owner'), 1::bigint, 'shared team retains its other owner');
select * from finish();
rollback;
