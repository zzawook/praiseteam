-- A song's tempo for one service, like its key. The same song played
-- faster or slower stays one song, so its history and statistics stay
-- together. Announcements carry the tempo, and a re-announcement reports a
-- changed tempo the way it reports a changed key.

alter table public.setlist_items add column bpm smallint check (bpm between 20 and 300);
grant update (bpm) on public.setlist_items to authenticated;

-- History shows each service's tempo next to its key (columns may only be
-- added at the end of a view).
create or replace view public.song_history
with (security_invoker = true)
as
select
  si.team_id,
  si.song_id,
  si.session_id,
  se.title as session_title,
  se.starts_at,
  coalesce(si.key, so.default_key)::text as key,
  coalesce(si.bpm, so.bpm) as bpm
from public.setlist_items si
join public.sessions se on se.id = si.session_id
join public.songs so on so.id = si.song_id
where se.setlist_status = 'published';

-- What changed between two announced setlists (by song). Announcements
-- made before tempos were kept have none, so they report no tempo change.
create or replace function private.setlist_diff(p_prev jsonb, p_curr jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  with prev as (
    select (e ->> 'song_id')::bigint as song_id, e ->> 'title' as title, e ->> 'key' as key,
           (e ->> 'bpm')::int as bpm, e ? 'bpm' as has_bpm, ord
    from jsonb_array_elements(p_prev) with ordinality as t(e, ord)
  ),
  curr as (
    select (e ->> 'song_id')::bigint as song_id, e ->> 'title' as title, e ->> 'key' as key,
           (e ->> 'bpm')::int as bpm, ord
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

-- Publish (or re-publish) a session's setlist; unchanged but for the
-- tempo in the snapshot. Returns the change summary ({} when nothing
-- changed since the last announcement, in which case nobody is notified).
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
             'key', coalesce(si.key, so.default_key),
             'bpm', coalesce(si.bpm, so.bpm)
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
