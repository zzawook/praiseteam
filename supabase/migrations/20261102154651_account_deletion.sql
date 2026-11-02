-- Account deletion is one database transaction. Shared songs/sheets/services
-- keep their existing ON DELETE SET NULL authorship. Personal rows cascade.
-- Storage files of teams that disappear are queued for the Storage API, so a
-- temporary storage outage cannot strand an account or lose a cleanup request.
create table private.storage_cleanup_queue (
  bucket_id text not null,
  storage_path text not null,
  created_at timestamptz not null default now(),
  primary key (bucket_id, storage_path)
);
alter table private.storage_cleanup_queue enable row level security;
revoke all on private.storage_cleanup_queue from public, anon, authenticated, service_role;

-- Serialize membership changes with deletion's last-owner check. A join or
-- promotion cannot slip between checking a team and deleting it.
create function private.lock_membership_team()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from public.teams
  where id in (old.team_id, new.team_id)
  order by id for update;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
create trigger team_members_lock_team
before insert or update or delete on public.team_members
for each row execute function private.lock_membership_team();

-- A deleted account's still-unexpired JWT must not bootstrap a new team,
-- register a device, or invoke any of the other privileged account RPCs.
create or replace function private.require_uid()
returns uuid language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid := (select auth.uid());
begin
  if v_uid is null or not exists (select 1 from auth.users where id = v_uid) then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  return v_uid;
end;
$$;

create function private.account_deletion_state(p_uid uuid)
returns jsonb language sql stable set search_path = '' as $$
  with owned as (
    select t.id, t.name,
      exists (select 1 from public.team_members other
              where other.team_id = t.id and other.user_id <> p_uid) as has_members,
      exists (select 1 from public.team_members other
              where other.team_id = t.id and other.user_id <> p_uid
                and other.role = 'owner' and other.status = 'active') as has_owner
    from public.teams t join public.team_members me on me.team_id = t.id
    where me.user_id = p_uid and me.role = 'owner' and me.status = 'active'
  )
  select jsonb_build_object(
    'blocked_teams', coalesce((select jsonb_agg(name order by id) from owned where has_members and not has_owner), '[]'::jsonb),
    'deleted_teams', coalesce((select jsonb_agg(name order by id) from owned where not has_members), '[]'::jsonb)
  );
$$;

create function public.account_deletion_info()
returns jsonb language sql stable security definer set search_path = '' as $$
  select private.account_deletion_state(private.require_uid());
$$;

create function private.request_storage_cleanup()
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_url text := private.vault_secret('storage_cleanup_url');
  v_secret text := private.vault_secret('push_webhook_secret');
begin
  if v_url is null or v_secret is null or not exists (select 1 from private.storage_cleanup_queue) then return; end if;
  perform net.http_post(
    url := v_url, body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || v_secret),
    timeout_milliseconds := 10000
  );
end;
$$;

create function public.delete_account()
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_uid();
  v_state jsonb;
  v_teams bigint[];
begin
  -- Identity comes exclusively from the request. Require a live Auth session
  -- for this irreversible operation, including when its JWT has not expired.
  if not exists (
    select 1 from auth.sessions
    where user_id = v_uid and id::text = (select auth.jwt() ->> 'session_id')
      and (not_after is null or not_after > now())
  ) then
    raise exception 'sign in again before deleting your account' using errcode = '42501';
  end if;

  perform 1 from auth.users where id = v_uid for update;
  perform 1 from public.profiles where id = v_uid for update;
  perform 1 from public.teams
  where id in (select team_id from public.team_members where user_id = v_uid)
  order by id for update;

  v_state := private.account_deletion_state(v_uid);
  if jsonb_array_length(v_state -> 'blocked_teams') > 0 then
    raise exception 'transfer team ownership before deleting your account'
      using errcode = 'PT001', detail = (v_state -> 'blocked_teams')::text;
  end if;

  select coalesce(array_agg(me.team_id), '{}') into v_teams
  from public.team_members me
  where me.user_id = v_uid and me.role = 'owner' and me.status = 'active'
    and not exists (select 1 from public.team_members other where other.team_id = me.team_id and other.user_id <> v_uid);

  insert into private.storage_cleanup_queue (bucket_id, storage_path)
  select bucket_id, name from storage.objects
  where bucket_id = 'sheets' and private.team_of_path(name) = any (v_teams)
  on conflict do nothing;

  -- Remove references before deleting the songs/parts they restrict.
  delete from public.sessions where team_id = any (v_teams);
  delete from public.songs where team_id = any (v_teams);
  delete from public.teams where id = any (v_teams);

  -- Shared files belong to the team now; its leaders can still delete them.
  -- Clear both the current owner field and Storage's legacy owner column.
  update storage.objects set owner = null, owner_id = null
  where owner = v_uid or owner_id = v_uid::text;

  delete from private.reminders_sent where user_id = v_uid;
  delete from auth.sessions where user_id = v_uid;
  delete from auth.users where id = v_uid;
  perform private.request_storage_cleanup();
end;
$$;

revoke execute on function private.lock_membership_team(), private.account_deletion_state(uuid),
  private.request_storage_cleanup() from public, anon, authenticated, service_role;
revoke execute on function public.account_deletion_info(), public.delete_account() from public, anon, service_role;
grant execute on function public.account_deletion_info(), public.delete_account() to authenticated;

select cron.schedule('storage-cleanup', '*/5 * * * *', $$select private.request_storage_cleanup()$$);

notify pgrst, 'reload schema';
