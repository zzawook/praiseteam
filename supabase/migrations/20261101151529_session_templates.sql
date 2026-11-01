-- Service templates: the services a team holds week after week (주일 2부
-- 예배, Sundays 11:00 at 본당). Adding a service from one fills its title,
-- day, time and place, so only the date is left to choose.
--
-- weekday is ISO 8601 (1 = Monday ... 7 = Sunday). start_time is the
-- wall-clock time the service starts where the team meets, the same way
-- the app enters a service's time.

create table public.session_templates (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 80),
  weekday smallint not null check (weekday between 1 and 7),
  start_time time not null,
  location text check (char_length(location) <= 80),
  created_at timestamptz not null default now(),
  -- a template is picked by its title, so titles are unique in a team
  unique (team_id, title)
);

alter table public.session_templates enable row level security;

create policy "session_templates: members read" on public.session_templates for select to authenticated
  using ((select private.is_member(team_id)));
create policy "session_templates: leaders add" on public.session_templates for insert to authenticated
  with check ((select private.is_leader(team_id)));
create policy "session_templates: leaders edit" on public.session_templates for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "session_templates: leaders delete" on public.session_templates for delete to authenticated
  using ((select private.is_leader(team_id)));

revoke all on table public.session_templates from anon, authenticated, service_role;
grant select, insert, delete on public.session_templates to authenticated;
grant update (title, weekday, start_time, location) on public.session_templates to authenticated;
