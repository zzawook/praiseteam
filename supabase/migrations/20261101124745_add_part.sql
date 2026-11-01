-- Adding a part together with the part chats it joins, in one step.
--
-- Part chats (e.g. 싱어팀) list their parts explicitly, so a part added later
-- (splitting 싱어 into 남자 싱어 / 여자 싱어, say) would otherwise be left out
-- of them. Security invoker: the existing row-level rules decide, so only
-- leaders can add parts and link them to chats.

create function public.add_part(
  p_team_id bigint,
  p_name text,
  p_kind text,
  p_channel_ids bigint[] default '{}'
)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_part_id bigint;
begin
  insert into public.parts (team_id, name, kind, sort_order)
  values (
    p_team_id,
    trim(p_name),
    p_kind,
    coalesce((select max(p.sort_order) from public.parts p where p.team_id = p_team_id), 0) + 10
  )
  returning id into v_part_id;

  insert into public.channel_parts (team_id, channel_id, part_id)
  select p_team_id, c.id, v_part_id
  from public.channels c
  where c.id = any (p_channel_ids)
    and c.team_id = p_team_id
    and c.kind = 'parts';

  return v_part_id;
end;
$$;

revoke execute on function public.add_part(bigint, text, text, bigint[]) from public, anon;
grant execute on function public.add_part(bigint, text, text, bigint[]) to authenticated;
