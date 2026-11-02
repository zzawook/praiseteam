-- Notifications use the team timezone, including rows queued before this change.
create or replace function private.notify(
  p_team_id bigint,
  p_user_ids uuid[],
  p_category text,
  p_params jsonb default '{}'::jsonb,
  p_listed boolean default true
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notifications (team_id, user_id, category, params, push_status, listed)
  select
    p_team_id,
    r.user_id,
    p_category,
    coalesce(p_params, '{}'::jsonb) || jsonb_build_object('timezone', coalesce((select timezone from public.teams where id = p_team_id), 'Asia/Singapore')),
    case when coalesce(np.push_enabled, true) then 'pending' else 'skipped' end,
    p_listed
  from (select distinct u as user_id from unnest(p_user_ids) as u where u is not null) r
  left join public.notification_prefs np
    on np.user_id = r.user_id and np.category = p_category;
$$;

create or replace function private.claim_push_batch(p_ids bigint[])
returns table (
  notification_id bigint,
  team_id bigint,
  category text,
  params jsonb,
  locale text,
  tokens jsonb
)
language sql
security definer
set search_path = ''
as $$
  with claimed as (
    update public.notifications n
    set push_status = 'sending',
        push_attempts = n.push_attempts + 1,
        push_claimed_at = now()
    where n.id = any (p_ids)
      and n.push_status = 'pending'
      and n.push_attempts < 5
    returning n.id, n.team_id, n.user_id, n.category, n.params
  )
  select
    c.id,
    c.team_id,
    c.category,
    c.params || jsonb_build_object('timezone', coalesce(t.timezone, 'Asia/Singapore')),
    coalesce(p.locale, 'ko'),
    coalesce(
      (select jsonb_agg(jsonb_build_object('token', d.token, 'platform', d.platform))
       from public.device_tokens d
       where d.user_id = c.user_id),
      '[]'::jsonb
    )
  from claimed c
  left join public.profiles p on p.id = c.user_id
  left join public.teams t on t.id = c.team_id;
$$;
