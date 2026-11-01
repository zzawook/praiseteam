-- Song versions. A song is the song itself: its title, time signature,
-- tags and notes. A version is one way the team plays it: whose recording
-- or arrangement it follows, its usual key and tempo, and its sheets and
-- links. A setlist entry picks a version and keeps the key and tempo used
-- that day, so a song's history and statistics stay on the one song
-- whichever version, key or tempo was played.
--
-- Each existing song becomes one version with the song's artist, key and
-- tempo; its sheets, links and setlist entries move to that version.

-- ---------------------------------------------------------------------
-- Versions
-- ---------------------------------------------------------------------
create table public.song_versions (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  song_id bigint not null,
  -- whose version: an artist, a live recording, the team's own arrangement
  name text check (char_length(trim(name)) between 1 and 120),
  default_key public.musical_key,
  bpm smallint check (bpm between 20 and 300),
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_id, id),
  -- lets a setlist entry require a version of its own song
  unique (team_id, song_id, id),
  foreign key (team_id, song_id) references public.songs (team_id, id) on delete cascade
);

create index song_versions_created_by_idx on public.song_versions (created_by);
create trigger song_versions_set_updated_at before update on public.song_versions
  for each row execute function private.set_updated_at();

insert into public.song_versions (team_id, song_id, name, default_key, bpm, created_by, created_at)
select team_id, id, nullif(trim(artist), ''), default_key, bpm, created_by, created_at
from public.songs;

-- ---------------------------------------------------------------------
-- Sheets and links belong to a version
-- ---------------------------------------------------------------------
alter table public.sheets add column version_id bigint;
update public.sheets sh set version_id = v.id from public.song_versions v where v.song_id = sh.song_id;
alter table public.sheets alter column version_id set not null;
alter table public.sheets drop column song_id; -- with its foreign key and index
alter table public.sheets
  add constraint sheets_team_id_version_id_fkey
    foreign key (team_id, version_id) references public.song_versions (team_id, id) on delete cascade,
  -- lets a setlist entry require a sheet of its own version
  add constraint sheets_team_id_version_id_id_key unique (team_id, version_id, id);

alter table public.song_links add column version_id bigint;
update public.song_links l set version_id = v.id from public.song_versions v where v.song_id = l.song_id;
alter table public.song_links alter column version_id set not null;
alter table public.song_links drop column song_id;
alter table public.song_links
  add constraint song_links_team_id_version_id_fkey
    foreign key (team_id, version_id) references public.song_versions (team_id, id) on delete cascade;
create index song_links_version_idx on public.song_links (team_id, version_id);

-- ---------------------------------------------------------------------
-- A setlist entry plays one version of its song, from that version's sheet
-- ---------------------------------------------------------------------
alter table public.setlist_items add column version_id bigint;
update public.setlist_items si set version_id = v.id from public.song_versions v where v.song_id = si.song_id;
alter table public.setlist_items alter column version_id set not null;
-- An entry whose sheet belonged to another song keeps no sheet.
update public.setlist_items si set sheet_id = null
where si.sheet_id is not null
  and not exists (select 1 from public.sheets sh where sh.id = si.sheet_id and sh.version_id = si.version_id);
alter table public.setlist_items
  drop constraint setlist_items_team_id_sheet_id_fkey,
  add constraint setlist_items_version_fkey
    foreign key (team_id, song_id, version_id) references public.song_versions (team_id, song_id, id) on delete restrict,
  add constraint setlist_items_sheet_fkey
    foreign key (team_id, version_id, sheet_id) references public.sheets (team_id, version_id, id)
    on delete set null (sheet_id);
drop index public.setlist_items_song_idx;
create index setlist_items_song_version_idx on public.setlist_items (team_id, song_id, version_id);
create index setlist_items_version_sheet_idx on public.setlist_items (team_id, version_id, sheet_id);

grant update (version_id) on public.setlist_items to authenticated;

-- ---------------------------------------------------------------------
-- History and statistics read key and tempo through the version
-- ---------------------------------------------------------------------
create or replace view public.song_history
with (security_invoker = true)
as
select
  si.team_id,
  si.song_id,
  si.session_id,
  se.title as session_title,
  se.starts_at,
  coalesce(si.key, v.default_key)::text as key,
  coalesce(si.bpm, v.bpm) as bpm,
  si.version_id,
  v.name as version_name
from public.setlist_items si
join public.sessions se on se.id = si.session_id
join public.song_versions v on v.id = si.version_id
where se.setlist_status = 'published';

create or replace view public.song_stats
with (security_invoker = true)
as
select
  so.team_id,
  so.id as song_id,
  count(h.session_id) filter (where h.starts_at <= now())::int as times_played,
  max(h.starts_at) filter (where h.starts_at <= now()) as last_played_at,
  min(h.starts_at) filter (where h.starts_at <= now()) as first_played_at,
  mode() within group (order by h.key) filter (where h.starts_at <= now()) as usual_key,
  min(h.starts_at) filter (where h.starts_at > now()) as next_planned_at,
  -- the version played most recently, offered first when adding the song
  (array_agg(h.version_id order by h.starts_at desc) filter (where h.starts_at <= now()))[1] as last_version_id
from public.songs so
left join public.song_history h on h.song_id = so.id
group by so.team_id, so.id;

-- The song keeps only what every version shares.
alter table public.songs drop column artist, drop column default_key, drop column bpm;

-- ---------------------------------------------------------------------
-- Security
-- ---------------------------------------------------------------------
alter table public.song_versions enable row level security;

-- the song library is shared by the whole team, like songs and sheets
create policy "song_versions: members read" on public.song_versions for select to authenticated
  using ((select private.is_member(team_id)));
create policy "song_versions: members add" on public.song_versions for insert to authenticated
  with check ((select private.is_member(team_id)) and created_by = (select auth.uid()));
create policy "song_versions: members edit" on public.song_versions for update to authenticated
  using ((select private.is_member(team_id))) with check ((select private.is_member(team_id)));
create policy "song_versions: creator or leader deletes" on public.song_versions for delete to authenticated
  using (created_by = (select auth.uid()) or (select private.is_leader(team_id)));

revoke all on table public.song_versions from anon, authenticated, service_role;
grant select, insert, delete on public.song_versions to authenticated;
grant update (name, default_key, bpm) on public.song_versions to authenticated;

-- ---------------------------------------------------------------------
-- Adding a song together with its first version, in one step. Security
-- invoker: the row-level rules decide who may add.
-- ---------------------------------------------------------------------
create function public.add_song(
  p_team_id bigint,
  p_title text,
  p_time_signature text default null,
  p_tags text[] default '{}',
  p_notes text default null,
  p_version_name text default null,
  p_key text default null,
  p_bpm integer default null
)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_song_id bigint;
begin
  insert into public.songs (team_id, title, time_signature, tags, notes)
  values (p_team_id, trim(p_title), p_time_signature, coalesce(p_tags, '{}'), p_notes)
  returning id into v_song_id;

  insert into public.song_versions (team_id, song_id, name, default_key, bpm)
  values (p_team_id, v_song_id, nullif(trim(p_version_name), ''), p_key, p_bpm);

  return v_song_id;
end;
$$;

revoke execute on function public.add_song(bigint, text, text, text[], text, text, text, integer) from public, anon;
grant execute on function public.add_song(bigint, text, text, text[], text, text, text, integer) to authenticated;

-- ---------------------------------------------------------------------
-- Announcements carry the version; a re-announcement reports a changed
-- version as it reports a changed key or tempo. Announcements made before
-- versions or tempos were kept report no such change.
-- ---------------------------------------------------------------------
create or replace function private.setlist_diff(p_prev jsonb, p_curr jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  with prev as (
    select (e ->> 'song_id')::bigint as song_id, e ->> 'title' as title, e ->> 'key' as key,
           (e ->> 'bpm')::int as bpm, e ? 'bpm' as has_bpm,
           (e ->> 'version_id')::bigint as version_id, e ->> 'version' as version, e ? 'version_id' as has_version,
           ord
    from jsonb_array_elements(p_prev) with ordinality as t(e, ord)
  ),
  curr as (
    select (e ->> 'song_id')::bigint as song_id, e ->> 'title' as title, e ->> 'key' as key,
           (e ->> 'bpm')::int as bpm, (e ->> 'version_id')::bigint as version_id, e ->> 'version' as version, ord
    from jsonb_array_elements(p_curr) with ordinality as t(e, ord)
  )
  select jsonb_strip_nulls(jsonb_build_object(
    'added', (select jsonb_agg(c.title order by c.ord) from curr c
              where not exists (select 1 from prev p where p.song_id = c.song_id)),
    'removed', (select jsonb_agg(p.title order by p.ord) from prev p
                where not exists (select 1 from curr c where c.song_id = p.song_id)),
    'version_changed', (select jsonb_agg(jsonb_build_object('title', c.title, 'from', p.version, 'to', c.version) order by c.ord)
                        from curr c join prev p on p.song_id = c.song_id
                        where p.has_version and p.version_id is distinct from c.version_id),
    'key_changed', (select jsonb_agg(jsonb_build_object('title', c.title, 'from', p.key, 'to', c.key) order by c.ord)
                    from curr c join prev p on p.song_id = c.song_id
                    where p.key is distinct from c.key),
    'tempo_changed', (select jsonb_agg(jsonb_build_object('title', c.title, 'from', p.bpm, 'to', c.bpm) order by c.ord)
                      from curr c join prev p on p.song_id = c.song_id
                      where p.has_bpm and p.bpm is distinct from c.bpm),
    'reordered', case when
      (select array_agg(p.song_id order by p.ord) from prev p where exists (select 1 from curr c where c.song_id = p.song_id))
      is distinct from
      (select array_agg(c.song_id order by c.ord) from curr c where exists (select 1 from prev p where p.song_id = c.song_id))
      then true end
  ));
$$;

create or replace function public.publish_setlist(p_session_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_session public.sessions%rowtype;
  v_snapshot jsonb;
  v_previous jsonb;
  v_summary jsonb;
  v_first boolean;
begin
  select * into v_session from public.sessions where id = p_session_id for update;
  if not found then
    raise exception 'session not found' using errcode = 'P0002';
  end if;
  if not private.is_leader(v_session.team_id) then
    raise exception 'only leaders can publish setlists' using errcode = '42501';
  end if;

  select coalesce(
           jsonb_agg(jsonb_build_object(
             'song_id', si.song_id,
             'title', so.title,
             'version_id', si.version_id,
             'version', v.name,
             'key', coalesce(si.key, v.default_key),
             'bpm', coalesce(si.bpm, v.bpm)
           ) order by si.position),
           '[]'::jsonb)
  into v_snapshot
  from public.setlist_items si
  join public.songs so on so.id = si.song_id
  join public.song_versions v on v.id = si.version_id
  where si.session_id = p_session_id;

  if jsonb_array_length(v_snapshot) = 0 then
    raise exception 'the setlist is empty' using errcode = '22023';
  end if;

  select setlist_snapshot into v_previous
  from public.announcements
  where session_id = p_session_id;

  v_first := v_previous is null;
  v_summary := case when v_first then '{}'::jsonb else private.setlist_diff(v_previous, v_snapshot) end;

  if not v_first and v_summary = '{}'::jsonb then
    return v_summary;
  end if;

  insert into public.announcements (team_id, kind, session_id, title, setlist_snapshot, change_summary, created_by)
  values (v_session.team_id, 'setlist', p_session_id, v_session.title, v_snapshot, v_summary, v_uid)
  on conflict (session_id) do update
    set title = excluded.title,
        setlist_snapshot = excluded.setlist_snapshot,
        change_summary = excluded.change_summary,
        updated_at = now();

  update public.sessions
  set setlist_status = 'published', published_at = coalesce(published_at, now())
  where id = p_session_id;

  perform private.notify(
    v_session.team_id,
    array(select r from unnest(private.setlist_recipients(p_session_id)) as r where r <> v_uid),
    case when v_first then 'setlist_published' else 'setlist_updated' end,
    jsonb_build_object(
      'session_id', p_session_id,
      'session_title', v_session.title,
      'starts_at', v_session.starts_at,
      'team_name', (select name from public.teams where id = v_session.team_id),
      'songs', (select jsonb_agg(e -> 'title') from jsonb_array_elements(v_snapshot) as e),
      'summary', v_summary
    )
  );

  return v_summary;
end;
$$;
