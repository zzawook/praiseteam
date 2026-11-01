-- =====================================================================
-- M2: song library, sheets, worship sessions, setlists (콘티), setlist
-- announcements and song statistics.
--
-- Rules
--  * Song library is collaborative: any active member adds and edits
--    songs, links and sheets; deleting songs is for leaders.
--  * Sessions are free-form (any date/time/title), created by leaders.
--  * A draft setlist is visible to leaders only. Publishing makes it
--    visible to the team, records what was announced, and notifies.
--    Re-publishing announces only what changed since the last announcement.
--  * Statistics count published sessions that already happened.
-- =====================================================================

-- Musical key such as C, F#, Bb, Am, C#m
create domain public.musical_key as text
  check (value ~ '^[A-G](#|b)?m?$');

-- ---------------------------------------------------------------------
-- songs and links
-- ---------------------------------------------------------------------
create table public.songs (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  artist text check (char_length(artist) <= 120),
  default_key public.musical_key,
  bpm smallint check (bpm between 20 and 300),
  time_signature text check (time_signature ~ '^[0-9]{1,2}/[0-9]{1,2}$'),
  tags text[] not null default '{}',
  notes text check (char_length(notes) <= 2000),
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (team_id, id)
);

create index songs_team_title_idx on public.songs (team_id, lower(title));
create index songs_created_by_idx on public.songs (created_by);
create trigger songs_set_updated_at before update on public.songs
  for each row execute function private.set_updated_at();

create table public.song_links (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  song_id bigint not null,
  label text check (char_length(label) <= 60),
  url text not null check (url ~* '^https?://' and char_length(url) <= 2000),
  sort_order integer not null default 0,
  foreign key (team_id, song_id) references public.songs (team_id, id) on delete cascade
);

create index song_links_song_idx on public.song_links (team_id, song_id);

-- ---------------------------------------------------------------------
-- sheets: one PDF per sheet in the private `sheets` bucket at
-- {team_id}/{uuid}.pdf (images are converted to PDF in the app).
-- ---------------------------------------------------------------------
create table public.sheets (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  song_id bigint not null,
  key public.musical_key,
  label text check (char_length(label) <= 60),
  storage_path text not null unique,
  page_count integer not null check (page_count between 1 and 200),
  -- [[width, height], ...] in PDF points, for laying out annotations
  page_sizes jsonb not null check (jsonb_typeof(page_sizes) = 'array'),
  size_bytes integer not null check (size_bytes > 0),
  uploaded_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (team_id, id),
  foreign key (team_id, song_id) references public.songs (team_id, id) on delete cascade,
  check (storage_path like team_id::text || '/%')
);

create index sheets_song_idx on public.sheets (team_id, song_id);
create index sheets_uploaded_by_idx on public.sheets (uploaded_by);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('sheets', 'sheets', false, 20971520, array['application/pdf'])
on conflict (id) do nothing;

-- Team id from a storage object name "{team_id}/..."; null if malformed.
create function private.team_of_path(p_name text)
returns bigint
language sql
immutable
set search_path = ''
as $$
  select case
    when split_part(p_name, '/', 1) ~ '^[0-9]{1,18}$' then split_part(p_name, '/', 1)::bigint
  end;
$$;

grant execute on function private.team_of_path(text) to authenticated;

create policy "sheets bucket: members read"
  on storage.objects for select to authenticated
  using (bucket_id = 'sheets' and private.is_member(private.team_of_path(name)));

create policy "sheets bucket: members upload"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'sheets' and private.is_member(private.team_of_path(name)));

create policy "sheets bucket: uploader or leader deletes"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'sheets'
    and (
      owner_id = (select auth.uid())::text
      or private.is_leader(private.team_of_path(name))
    )
  );

-- ---------------------------------------------------------------------
-- sessions (예배 세션) and setlists
-- ---------------------------------------------------------------------
create table public.sessions (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 80),
  starts_at timestamptz not null,
  location text check (char_length(location) <= 80),
  theme text check (char_length(theme) <= 200),
  notes text check (char_length(notes) <= 2000),
  setlist_status text not null default 'draft' check (setlist_status in ('draft', 'published')),
  published_at timestamptz,
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_id, id)
);

create index sessions_team_starts_idx on public.sessions (team_id, starts_at);
create index sessions_created_by_idx on public.sessions (created_by);
create trigger sessions_set_updated_at before update on public.sessions
  for each row execute function private.set_updated_at();

create table public.setlist_items (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  session_id bigint not null,
  position integer not null check (position > 0),
  song_id bigint not null,
  key public.musical_key,
  sheet_id bigint,
  -- 송폼, e.g. "I-V1-C-V2-C-B-C-O"
  song_form text check (char_length(song_form) <= 200),
  notes text check (char_length(notes) <= 500),
  unique (team_id, id),
  foreign key (team_id, session_id) references public.sessions (team_id, id) on delete cascade,
  foreign key (team_id, song_id) references public.songs (team_id, id) on delete restrict,
  foreign key (team_id, sheet_id) references public.sheets (team_id, id) on delete set null (sheet_id),
  constraint setlist_items_position_unique unique (session_id, position) deferrable initially deferred
);

create index setlist_items_song_idx on public.setlist_items (team_id, song_id);
create index setlist_items_sheet_idx on public.setlist_items (team_id, sheet_id);

-- Leaders see draft setlists; everyone sees published ones.
create function private.can_view_setlist(p_session_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sessions s
    where s.id = p_session_id
      and (
        (s.setlist_status = 'published' and private.is_member(s.team_id))
        or private.is_leader(s.team_id)
      )
  );
$$;

grant execute on function private.can_view_setlist(bigint) to authenticated;

-- ---------------------------------------------------------------------
-- announcements (general announcements arrive in M5; setlist
-- announcements are written by publish_setlist only)
-- ---------------------------------------------------------------------
create table public.announcements (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  kind text not null check (kind in ('general', 'setlist')),
  session_id bigint,
  title text not null check (char_length(trim(title)) between 1 and 120),
  body text check (char_length(body) <= 5000),
  pinned boolean not null default false,
  -- setlist kind: what was announced last, and what changed then
  setlist_snapshot jsonb,
  change_summary jsonb,
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (team_id, session_id) references public.sessions (team_id, id) on delete cascade,
  constraint announcements_one_per_session unique (session_id),
  check ((kind = 'setlist') = (session_id is not null))
);

create index announcements_team_idx on public.announcements (team_id, updated_at desc);
create index announcements_created_by_idx on public.announcements (created_by);
create trigger announcements_set_updated_at before update on public.announcements
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- Statistics (security_invoker: each caller's RLS applies)
-- ---------------------------------------------------------------------
create view public.song_history
with (security_invoker = true)
as
select
  si.team_id,
  si.song_id,
  si.session_id,
  se.title as session_title,
  se.starts_at,
  coalesce(si.key, so.default_key)::text as key
from public.setlist_items si
join public.sessions se on se.id = si.session_id
join public.songs so on so.id = si.song_id
where se.setlist_status = 'published';

create view public.song_stats
with (security_invoker = true)
as
select
  so.team_id,
  so.id as song_id,
  count(h.session_id) filter (where h.starts_at <= now())::int as times_played,
  max(h.starts_at) filter (where h.starts_at <= now()) as last_played_at,
  min(h.starts_at) filter (where h.starts_at <= now()) as first_played_at,
  mode() within group (order by h.key) filter (where h.starts_at <= now()) as usual_key,
  min(h.starts_at) filter (where h.starts_at > now()) as next_planned_at
from public.songs so
left join public.song_history h on h.song_id = so.id
group by so.team_id, so.id;

create function public.top_songs(p_team_id bigint, p_from timestamptz, p_to timestamptz)
returns table (song_id bigint, title text, times integer)
language sql
stable
security invoker
set search_path = ''
as $$
  select h.song_id, so.title, count(*)::int
  from public.song_history h
  join public.songs so on so.id = h.song_id
  where h.team_id = p_team_id and h.starts_at >= p_from and h.starts_at < p_to and h.starts_at <= now()
  group by h.song_id, so.title
  order by count(*) desc, so.title
  limit 50;
$$;

-- ---------------------------------------------------------------------
-- Setlist RPCs
-- ---------------------------------------------------------------------
create function public.reorder_setlist(p_session_id bigint, p_item_ids bigint[])
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.sessions s
    where s.id = p_session_id and private.is_leader(s.team_id)
  ) then
    raise exception 'only leaders can reorder setlists' using errcode = '42501';
  end if;

  if (select count(*) from public.setlist_items where session_id = p_session_id)
     <> coalesce(cardinality(p_item_ids), 0) then
    raise exception 'item list does not match the setlist' using errcode = '22023';
  end if;

  -- RLS limits this to leaders; positions are checked at commit.
  update public.setlist_items si
  set position = array_position(p_item_ids, si.id)
  where si.session_id = p_session_id;
end;
$$;

-- What changed between two announced setlists (by song).
create function private.setlist_diff(p_prev jsonb, p_curr jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  with prev as (
    select (e ->> 'song_id')::bigint as song_id, e ->> 'title' as title, e ->> 'key' as key, ord
    from jsonb_array_elements(p_prev) with ordinality as t(e, ord)
  ),
  curr as (
    select (e ->> 'song_id')::bigint as song_id, e ->> 'title' as title, e ->> 'key' as key, ord
    from jsonb_array_elements(p_curr) with ordinality as t(e, ord)
  )
  select jsonb_strip_nulls(jsonb_build_object(
    'added', (select jsonb_agg(c.title order by c.ord) from curr c
              where not exists (select 1 from prev p where p.song_id = c.song_id)),
    'removed', (select jsonb_agg(p.title order by p.ord) from prev p
                where not exists (select 1 from curr c where c.song_id = p.song_id)),
    'key_changed', (select jsonb_agg(jsonb_build_object('title', c.title, 'from', p.key, 'to', c.key) order by c.ord)
                    from curr c join prev p on p.song_id = c.song_id
                    where p.key is distinct from c.key),
    'reordered', case when
      (select array_agg(p.song_id order by p.ord) from prev p where exists (select 1 from curr c where c.song_id = p.song_id))
      is distinct from
      (select array_agg(c.song_id order by c.ord) from curr c where exists (select 1 from prev p where p.song_id = c.song_id))
      then true end
  ));
$$;

-- Who is told about a setlist. Until rotations exist (M4) that is the
-- whole active team; M4 narrows it to the people serving plus leaders.
create function private.setlist_recipients(p_session_id bigint)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(m.user_id), '{}')
  from public.sessions s
  join public.team_members m on m.team_id = s.team_id and m.status = 'active'
  where s.id = p_session_id;
$$;

-- Publish (or re-publish) a session's setlist. Returns the change summary
-- ({} when nothing changed since the last announcement, in which case
-- nobody is notified).
create function public.publish_setlist(p_session_id bigint)
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
             'key', coalesce(si.key, so.default_key)
           ) order by si.position),
           '[]'::jsonb)
  into v_snapshot
  from public.setlist_items si
  join public.songs so on so.id = si.song_id
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

-- ---------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------
alter table public.songs enable row level security;
alter table public.song_links enable row level security;
alter table public.sheets enable row level security;
alter table public.sessions enable row level security;
alter table public.setlist_items enable row level security;
alter table public.announcements enable row level security;

-- songs: collaborative library
create policy "songs: members read" on public.songs for select to authenticated
  using ((select private.is_member(team_id)));
create policy "songs: members add" on public.songs for insert to authenticated
  with check ((select private.is_member(team_id)) and created_by = (select auth.uid()));
create policy "songs: members edit" on public.songs for update to authenticated
  using ((select private.is_member(team_id))) with check ((select private.is_member(team_id)));
create policy "songs: leaders delete" on public.songs for delete to authenticated
  using ((select private.is_leader(team_id)));

create policy "song_links: members read" on public.song_links for select to authenticated
  using ((select private.is_member(team_id)));
create policy "song_links: members add" on public.song_links for insert to authenticated
  with check ((select private.is_member(team_id)));
create policy "song_links: members edit" on public.song_links for update to authenticated
  using ((select private.is_member(team_id))) with check ((select private.is_member(team_id)));
create policy "song_links: members delete" on public.song_links for delete to authenticated
  using ((select private.is_member(team_id)));

create policy "sheets: members read" on public.sheets for select to authenticated
  using ((select private.is_member(team_id)));
create policy "sheets: members add" on public.sheets for insert to authenticated
  with check ((select private.is_member(team_id)) and uploaded_by = (select auth.uid()));
create policy "sheets: members edit" on public.sheets for update to authenticated
  using ((select private.is_member(team_id))) with check ((select private.is_member(team_id)));
create policy "sheets: uploader or leader deletes" on public.sheets for delete to authenticated
  using (uploaded_by = (select auth.uid()) or (select private.is_leader(team_id)));

-- sessions: members read, leaders manage
create policy "sessions: members read" on public.sessions for select to authenticated
  using ((select private.is_member(team_id)));
create policy "sessions: leaders add" on public.sessions for insert to authenticated
  with check ((select private.is_leader(team_id)) and created_by = (select auth.uid()));
create policy "sessions: leaders edit" on public.sessions for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "sessions: leaders delete" on public.sessions for delete to authenticated
  using ((select private.is_leader(team_id)));

-- setlist items: leaders always, members once published
create policy "setlist_items: read when visible" on public.setlist_items for select to authenticated
  using (private.can_view_setlist(session_id));
create policy "setlist_items: leaders add" on public.setlist_items for insert to authenticated
  with check ((select private.is_leader(team_id)));
create policy "setlist_items: leaders edit" on public.setlist_items for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "setlist_items: leaders delete" on public.setlist_items for delete to authenticated
  using ((select private.is_leader(team_id)));

-- announcements: members read; leaders write general ones
create policy "announcements: members read" on public.announcements for select to authenticated
  using ((select private.is_member(team_id)));
create policy "announcements: leaders post" on public.announcements for insert to authenticated
  with check ((select private.is_leader(team_id)) and kind = 'general' and created_by = (select auth.uid()));
create policy "announcements: leaders edit" on public.announcements for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "announcements: leaders delete" on public.announcements for delete to authenticated
  using ((select private.is_leader(team_id)));

-- ---------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------
revoke all on table
  public.songs, public.song_links, public.sheets, public.sessions,
  public.setlist_items, public.announcements, public.song_history, public.song_stats
from anon, authenticated, service_role;

grant select, insert, delete on public.songs to authenticated;
grant update (title, artist, default_key, bpm, time_signature, tags, notes, archived_at) on public.songs to authenticated;

grant select, insert, delete on public.song_links to authenticated;
grant update (label, url, sort_order) on public.song_links to authenticated;

grant select, insert, delete on public.sheets to authenticated;
grant update (key, label) on public.sheets to authenticated;

grant select, insert, delete on public.sessions to authenticated;
grant update (title, starts_at, location, theme, notes) on public.sessions to authenticated;

grant select, insert, delete on public.setlist_items to authenticated;
grant update (key, sheet_id, song_form, notes) on public.setlist_items to authenticated;
-- reorder_setlist runs as the caller and moves positions under RLS
grant update (position) on public.setlist_items to authenticated;

grant select, insert, delete on public.announcements to authenticated;
grant update (title, body, pinned) on public.announcements to authenticated;

grant select on public.song_history, public.song_stats to authenticated;

grant select, insert, update, delete on all tables in schema public to service_role;

revoke execute on function
  public.publish_setlist(bigint),
  public.reorder_setlist(bigint, bigint[]),
  public.top_songs(bigint, timestamptz, timestamptz)
from public, anon;

grant execute on function
  public.publish_setlist(bigint),
  public.reorder_setlist(bigint, bigint[]),
  public.top_songs(bigint, timestamptz, timestamptz)
to authenticated;
