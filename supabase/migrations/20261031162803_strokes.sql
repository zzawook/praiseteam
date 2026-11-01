-- =====================================================================
-- M3: annotations (필기) on sheets, per service.
--
-- A stroke belongs to (setlist item of a session, sheet, page): it shows
-- only for that service, never the next time the song is played.
-- Visibility is `team` (everyone in the team) or `private` (only the
-- person who drew it). Privacy is enforced here, by RLS; Realtime's
-- Postgres Changes applies the same policies, so a private stroke is never
-- sent to anyone else's device.
--
-- Strokes are immutable: drawing inserts (client-generated UUID, so a
-- retried upload is idempotent), erasing sets deleted_at. Undo of an
-- erase clears deleted_at. Offline edits therefore never conflict.
-- =====================================================================

-- strokes reference (session_id, setlist_item_id) so the session can't
-- disagree with the item's session
alter table public.setlist_items
  add constraint setlist_items_session_item_unique unique (session_id, id);

create table public.strokes (
  id uuid primary key,
  team_id bigint not null,
  session_id bigint not null,
  setlist_item_id bigint not null,
  sheet_id bigint not null,
  page_index integer not null check (page_index between 0 and 199),
  owner_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  visibility text not null check (visibility in ('team', 'private')),
  tool text not null check (tool in ('pen', 'highlighter')),
  color integer not null,            -- ARGB
  width real not null check (width > 0 and width <= 0.1),  -- fraction of page width
  -- packed points: per point uint16 x, uint16 y (0..65535 of the page),
  -- uint8 pressure; little endian. See app/lib/features/annotations.
  points bytea not null check (octet_length(points) between 5 and 100000 and octet_length(points) % 5 = 0),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  foreign key (session_id, setlist_item_id) references public.setlist_items (session_id, id) on delete cascade,
  foreign key (team_id, session_id) references public.sessions (team_id, id) on delete cascade,
  foreign key (team_id, sheet_id) references public.sheets (team_id, id) on delete cascade
);

create index strokes_session_idx on public.strokes (session_id);
create index strokes_item_idx on public.strokes (setlist_item_id, page_index);
create index strokes_owner_idx on public.strokes (owner_id);
create index strokes_team_session_idx on public.strokes (team_id, session_id);
create index strokes_team_sheet_idx on public.strokes (team_id, sheet_id);

alter table public.strokes enable row level security;

-- Read: team strokes of setlists you can see; private strokes only your own.
create policy "strokes: read team ones and my own"
  on public.strokes for select to authenticated
  using (
    (visibility = 'team' or owner_id = (select auth.uid()))
    and private.can_view_setlist(session_id)
  );

-- Draw: as yourself, on setlists you can see.
create policy "strokes: draw as myself"
  on public.strokes for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and private.can_view_setlist(session_id)
  );

-- Erase / un-erase: your own strokes; leaders also team strokes.
create policy "strokes: erase mine, leaders erase team ones"
  on public.strokes for update to authenticated
  using (
    owner_id = (select auth.uid())
    or (visibility = 'team' and private.is_leader(team_id))
  )
  with check (
    owner_id = (select auth.uid())
    or (visibility = 'team' and private.is_leader(team_id))
  );

revoke all on table public.strokes from anon, authenticated, service_role;
grant select, insert on public.strokes to authenticated;
grant update (deleted_at) on public.strokes to authenticated;
grant select, insert, update, delete on public.strokes to service_role;

alter publication supabase_realtime add table public.strokes;

-- Copy my strokes (and, for leaders, team strokes) from the most recent
-- earlier service that used the same sheet into this setlist item.
-- Originals stay where they were. Returns the number of strokes copied.
create function public.copy_previous_strokes(p_item_id bigint)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_item public.setlist_items%rowtype;
  v_source bigint;
  v_count integer;
begin
  select * into v_item from public.setlist_items where id = p_item_id;
  if not found or v_item.sheet_id is null then
    return 0;
  end if;

  select si.id into v_source
  from public.setlist_items si
  join public.sessions s on s.id = si.session_id
  where si.sheet_id = v_item.sheet_id
    and si.id <> p_item_id
    and exists (
      select 1 from public.strokes st
      where st.setlist_item_id = si.id
        and st.deleted_at is null
        and (st.owner_id = v_uid or (st.visibility = 'team' and private.is_leader(st.team_id)))
    )
  order by s.starts_at desc
  limit 1;

  if v_source is null then
    return 0;
  end if;

  insert into public.strokes
    (id, team_id, session_id, setlist_item_id, sheet_id, page_index, owner_id, visibility, tool, color, width, points)
  select gen_random_uuid(), v_item.team_id, v_item.session_id, v_item.id, st.sheet_id, st.page_index, v_uid,
         st.visibility, st.tool, st.color, st.width, st.points
  from public.strokes st
  where st.setlist_item_id = v_source
    and st.deleted_at is null
    and (st.owner_id = v_uid or (st.visibility = 'team' and private.is_leader(st.team_id)));

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- copy_previous_strokes runs as the caller and checks identity with this
grant execute on function private.require_uid() to authenticated;

revoke execute on function public.copy_previous_strokes(bigint) from public, anon;
grant execute on function public.copy_previous_strokes(bigint) to authenticated;
