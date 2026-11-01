-- Live mode channels: only members of the session's team may join.
begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000004a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'l4@test.local', '{"full_name":"Lead"}', now(), now()),
  ('00000000-0000-0000-0000-00000000004d', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'o4@test.local', '{"full_name":"Out"}', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000004a","role":"authenticated"}', true);
select set_config('test.team', public.create_team('T')::text, true);
with ins as (insert into public.sessions (team_id, title, starts_at) values (current_setting('test.team')::bigint, '주일', now()) returning id)
select set_config('test.session', (select id::text from ins), true);

select ok(private.can_join_live('live:' || current_setting('test.session')), 'a team member can join the live channel');
select ok(not private.can_join_live('live:999999'), 'unknown session: no');
select ok(not private.can_join_live('live:1;drop'), 'malformed topic: no');
select ok(not private.can_join_live('chat:' || current_setting('test.session')), 'other topics are not live channels');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000004d","role":"authenticated"}', true);
select ok(not private.can_join_live('live:' || current_setting('test.session')), 'outsiders cannot join');

select * from finish();
rollback;
