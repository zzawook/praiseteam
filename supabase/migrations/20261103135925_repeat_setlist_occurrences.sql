-- A setlist may contain a song more than once. Publish stable occurrence IDs
-- and compare one-to-one, while accepting old snapshots without those IDs.
-- Count service usage once per song and retain every occurrence in history.
-- Existing table constraints, RLS and RPC authorization remain in force.

CREATE OR REPLACE FUNCTION public.publish_setlist(p_session_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
             'item_id', si.id,
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
$function$
;

create or replace view "public"."song_history" with (security_invoker = true) as  SELECT si.team_id,
    si.song_id,
    si.session_id,
    se.title AS session_title,
    se.starts_at,
    (COALESCE(si.key, v.default_key))::text AS key,
    COALESCE(si.bpm, v.bpm) AS bpm,
    si.version_id,
    v.name AS version_name,
    si.id AS item_id,
    si."position"
   FROM ((public.setlist_items si
     JOIN public.sessions se ON ((se.id = si.session_id)))
     JOIN public.song_versions v ON ((v.id = si.version_id)))
  WHERE (se.setlist_status = 'published'::text);


create or replace view "public"."song_stats" with (security_invoker = true) as  SELECT so.team_id,
    so.id AS song_id,
    (count(DISTINCT h.session_id) FILTER (WHERE (h.starts_at <= now())))::integer AS times_played,
    max(h.starts_at) FILTER (WHERE (h.starts_at <= now())) AS last_played_at,
    min(h.starts_at) FILTER (WHERE (h.starts_at <= now())) AS first_played_at,
    mode() WITHIN GROUP (ORDER BY h.key) FILTER (WHERE (h.starts_at <= now())) AS usual_key,
    min(h.starts_at) FILTER (WHERE (h.starts_at > now())) AS next_planned_at,
    (array_agg(h.version_id ORDER BY h.starts_at DESC, h.session_id DESC, h."position" DESC, h.item_id DESC) FILTER (WHERE (h.starts_at <= now())))[1] AS last_version_id
   FROM (public.songs so
     LEFT JOIN public.song_history h ON ((h.song_id = so.id)))
  GROUP BY so.team_id, so.id;


CREATE OR REPLACE FUNCTION public.top_songs(p_team_id bigint, p_from timestamp with time zone, p_to timestamp with time zone)
 RETURNS TABLE(song_id bigint, title text, times integer)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select h.song_id, so.title, count(distinct h.session_id)::int
  from public.song_history h
  join public.songs so on so.id = h.song_id
  where h.team_id = p_team_id and h.starts_at >= p_from and h.starts_at < p_to and h.starts_at <= now()
  group by h.song_id, so.title
  order by count(distinct h.session_id) desc, so.title
  limit 50;
$function$
;

CREATE OR REPLACE FUNCTION private.setlist_diff(p_prev jsonb, p_curr jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare
  v_prev jsonb := coalesce(p_prev, '[]'::jsonb);
  v_curr jsonb := coalesce(p_curr, '[]'::jsonb);
  v_matches integer[] := array_fill(0, array[jsonb_array_length(v_curr)]);
  v_used integer[] := '{}';
  v_added jsonb := '[]';
  v_removed jsonb := '[]';
  v_version jsonb := '[]';
  v_keys jsonb := '[]';
  v_tempos jsonb := '[]';
  v_result jsonb := '{}';
  v_before jsonb;
  v_after jsonb;
  v_title text;
  v_repeated boolean;
  v_match integer;
  v_old_order integer[];
  v_new_order integer[];
  i integer;
  j integer;
  pass integer;
begin
  -- Stable occurrence IDs take precedence, including when a song appears
  -- several times with exactly the same version/key. Never cross-join songs.
  for i in 1..jsonb_array_length(v_curr) loop
    v_after := v_curr -> (i - 1);
    if v_after ->> 'item_id' is not null then
      select ord::integer into v_match
      from jsonb_array_elements(v_prev) with ordinality as t(e, ord)
      where e ->> 'item_id' = v_after ->> 'item_id'
        and e ->> 'song_id' = v_after ->> 'song_id'
        and not (ord::integer = any(v_used))
      order by ord limit 1;
      if v_match is not null then
        v_matches[i] := v_match;
        v_used := array_append(v_used, v_match);
      end if;
    end if;
  end loop;

  -- Older announcements have no item_id. Match unchanged occurrences first,
  -- then remaining occurrences of the song by proximity in the old order.
  -- Each row is used at most once. Once both sides have IDs, different IDs
  -- always mean removal/addition, even for identical versions and keys.
  for pass in 1..2 loop
    for j in 1..jsonb_array_length(v_prev) loop
      if j = any(v_used) then continue; end if;
      v_before := v_prev -> (j - 1);
      select ord::integer into v_match
      from jsonb_array_elements(v_curr) with ordinality as t(e, ord)
      where v_matches[ord::integer] = 0
        and e ->> 'song_id' = v_before ->> 'song_id'
        and (v_before ->> 'item_id' is null or e ->> 'item_id' is null)
        and (pass = 2 or (
          (v_before ->> 'key') is not distinct from (e ->> 'key')
          and (not (v_before ? 'version_id') or (v_before ->> 'version_id') is not distinct from (e ->> 'version_id'))
          and (not (v_before ? 'bpm') or (v_before ->> 'bpm') is not distinct from (e ->> 'bpm'))
        ))
      order by abs(ord - j), ord limit 1;
      if v_match is not null then
        v_matches[v_match] := j;
        v_used := array_append(v_used, j);
      end if;
    end loop;
  end loop;

  for i in 1..jsonb_array_length(v_curr) loop
    v_after := v_curr -> (i - 1);
    v_repeated := (select count(*) from jsonb_array_elements(v_curr) e where e ->> 'song_id' = v_after ->> 'song_id') > 1
      or (select count(*) from jsonb_array_elements(v_prev) e where e ->> 'song_id' = v_after ->> 'song_id') > 1;
    v_title := case when v_repeated then i::text || '. ' else '' end || (v_after ->> 'title');
    if v_matches[i] = 0 then
      v_added := v_added || jsonb_build_array(v_title);
      continue;
    end if;
    v_before := v_prev -> (v_matches[i] - 1);
    if v_before ? 'version_id' and (v_before ->> 'version_id') is distinct from (v_after ->> 'version_id') then
      v_version := v_version || jsonb_build_array(jsonb_build_object('title', v_title, 'from', v_before -> 'version', 'to', v_after -> 'version'));
    end if;
    if (v_before ->> 'key') is distinct from (v_after ->> 'key') then
      v_keys := v_keys || jsonb_build_array(jsonb_build_object('title', v_title, 'from', v_before -> 'key', 'to', v_after -> 'key'));
    end if;
    if v_before ? 'bpm' and (v_before ->> 'bpm') is distinct from (v_after ->> 'bpm') then
      v_tempos := v_tempos || jsonb_build_array(jsonb_build_object('title', v_title, 'from', v_before -> 'bpm', 'to', v_after -> 'bpm'));
    end if;
  end loop;
  for j in 1..jsonb_array_length(v_prev) loop
    if j = any(v_used) then continue; end if;
    v_before := v_prev -> (j - 1);
    v_repeated := (select count(*) from jsonb_array_elements(v_prev) e where e ->> 'song_id' = v_before ->> 'song_id') > 1
      or (select count(*) from jsonb_array_elements(v_curr) e where e ->> 'song_id' = v_before ->> 'song_id') > 1;
    v_title := case when v_repeated then j::text || '. ' else '' end || (v_before ->> 'title');
    v_removed := v_removed || jsonb_build_array(v_title);
  end loop;

  if v_added <> '[]'::jsonb then v_result := v_result || jsonb_build_object('added', v_added); end if;
  if v_removed <> '[]'::jsonb then v_result := v_result || jsonb_build_object('removed', v_removed); end if;
  if v_version <> '[]'::jsonb then v_result := v_result || jsonb_build_object('version_changed', v_version); end if;
  if v_keys <> '[]'::jsonb then v_result := v_result || jsonb_build_object('key_changed', v_keys); end if;
  if v_tempos <> '[]'::jsonb then v_result := v_result || jsonb_build_object('tempo_changed', v_tempos); end if;
  select coalesce(array_agg(x order by x), '{}'::integer[]) into v_old_order from unnest(v_used) x;
  v_new_order := array(select x from unnest(v_matches) x where x <> 0);
  if v_old_order is distinct from v_new_order then v_result := v_result || '{"reordered": true}'::jsonb; end if;
  return jsonb_strip_nulls(v_result);
end;
$function$
;


