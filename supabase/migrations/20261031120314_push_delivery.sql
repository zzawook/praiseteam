-- =====================================================================
-- Push delivery for public.notifications
--
-- Flow (at-least-once):
--   1. Producers insert notification rows (push_status = 'pending').
--   2. A statement-level trigger posts the batch of new ids to the `push`
--      Edge Function through pg_net (async, never blocks the producer).
--   3. The function claims rows (pending -> sending), sends them to FCM,
--      then reports results (sent / failed / skipped) and dead tokens.
--   4. A pg_cron job re-dispatches rows still pending after a minute and
--      rows stuck in `sending` (function crashed), up to 5 attempts.
--
-- Per-environment secrets live in Vault, never in migrations:
--   push_function_url    e.g. https://<ref>.supabase.co/functions/v1/push
--   push_webhook_secret  same value as the function's PUSH_WEBHOOK_SECRET
-- =====================================================================

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;

create function private.vault_secret(p_name text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select decrypted_secret from vault.decrypted_secrets where name = p_name limit 1;
$$;

-- Ask the push function to deliver these notifications. No-op until the
-- environment's Vault secrets are configured.
create function private.request_push(p_ids bigint[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text := private.vault_secret('push_function_url');
  v_secret text := private.vault_secret('push_webhook_secret');
begin
  if p_ids is null or cardinality(p_ids) = 0 or v_url is null or v_secret is null then
    return;
  end if;

  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('ids', to_jsonb(p_ids)),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_secret
    ),
    timeout_milliseconds := 10000
  );
end;
$$;

create function private.dispatch_new_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.request_push(
    array(select id from new_rows where push_status = 'pending' order by id)
  );
  return null;
end;
$$;

create trigger notifications_dispatch_push
  after insert on public.notifications
  referencing new table as new_rows
  for each statement execute function private.dispatch_new_notifications();

-- Called by the push function: claims deliverable rows and returns what it
-- needs to send them (recipient locale + device tokens).
create function private.claim_push_batch(p_ids bigint[])
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
    c.params,
    coalesce(p.locale, 'ko'),
    coalesce(
      (select jsonb_agg(jsonb_build_object('token', d.token, 'platform', d.platform))
       from public.device_tokens d
       where d.user_id = c.user_id),
      '[]'::jsonb
    )
  from claimed c
  left join public.profiles p on p.id = c.user_id;
$$;

-- Called by the push function with
--   {"results": [{"id": 1, "status": "sent"}, ...], "dead_tokens": ["..."]}
-- A failed row goes back to pending while it has attempts left.
create function private.complete_push(p_report jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.notifications n
  set push_status = case
        when r.status = 'failed' and n.push_attempts < 5 then 'pending'
        else r.status
      end,
      push_claimed_at = null
  from jsonb_to_recordset(coalesce(p_report -> 'results', '[]'::jsonb)) as r(id bigint, status text)
  where n.id = r.id
    and n.push_status = 'sending'
    and r.status in ('sent', 'failed', 'skipped');

  delete from public.device_tokens
  where token in (
    select jsonb_array_elements_text(coalesce(p_report -> 'dead_tokens', '[]'::jsonb))
  );
end;
$$;

create function private.retry_pushes()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ids bigint[];
begin
  -- The function died after claiming: make those rows deliverable again.
  update public.notifications
  set push_status = 'pending', push_claimed_at = null
  where push_status = 'sending' and push_claimed_at < now() - interval '5 minutes';

  update public.notifications
  set push_status = 'failed'
  where push_status = 'pending' and push_attempts >= 5;

  select array_agg(id order by id) into v_ids
  from (
    select id
    from public.notifications
    where push_status = 'pending'
      and created_at < now() - interval '1 minute'
    order by id
    limit 500
  ) due;

  perform private.request_push(v_ids);
end;
$$;

-- Only the database owner (pg_cron, the push function's direct DB
-- connection) runs these.
revoke execute on function
  private.vault_secret(text),
  private.request_push(bigint[]),
  private.claim_push_batch(bigint[]),
  private.complete_push(jsonb),
  private.retry_pushes()
from public, authenticated, service_role;

select cron.schedule('push-retry', '*/2 * * * *', $$select private.retry_pushes()$$);
select cron.schedule(
  'notifications-retention',
  '17 3 * * *',
  $$delete from public.notifications where created_at < now() - interval '180 days'$$
);
