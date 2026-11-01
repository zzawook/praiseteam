-- =====================================================================
-- M6: live mode. Realtime private channel "live:<session_id>" carries
-- page turns, cues (broadcast) and who is watching (presence). Nothing is
-- stored. Any member of the session's team may join and send; that is the
-- whole rule, so it lives in one function used by both policies.
-- =====================================================================

create function private.can_join_live(p_topic text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_topic ~ '^live:[0-9]{1,18}$' then exists (
      select 1 from public.sessions s
      where s.id = split_part(p_topic, ':', 2)::bigint
        and private.is_member(s.team_id)
    )
    else false
  end;
$$;

grant execute on function private.can_join_live(text) to authenticated;

create policy "live mode: team members receive"
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select private.can_join_live(realtime.topic()))
  );

create policy "live mode: team members send"
  on realtime.messages for insert to authenticated
  with check (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select private.can_join_live(realtime.topic()))
  );
