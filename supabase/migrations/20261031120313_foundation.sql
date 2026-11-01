-- =====================================================================
-- PraiseTeam foundation: profiles, teams, membership, parts, notifications
--
-- Access-control rules used throughout this schema
--  1. Every table in `public` has RLS enabled and explicit GRANTs.
--     Default privileges are normalised below so local dev and the hosted
--     project behave the same (Supabase stopped auto-exposing new tables
--     on 2026-10-30).
--  2. Authorization predicates live in the unexposed `private` schema
--     (is_member / is_leader / is_owner / shares_team_with). They are
--     SECURITY DEFINER so they can read team_members without recursing
--     into its RLS, and they always key off (select auth.uid()).
--  3. State changes that a caller cannot express row-by-row under RLS
--     (bootstrapping a team, joining by code, approvals, role changes)
--     are SECURITY DEFINER RPCs in `public`. Each one re-checks the
--     caller's identity and role explicitly and is executable only by
--     `authenticated`. Everything else is plain RLS.
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------
-- Default privileges: nothing is exposed unless granted explicitly.
-- ---------------------------------------------------------------------
alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke usage, select on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;
alter default privileges for role postgres in schema private
  revoke execute on functions from public;

-- ---------------------------------------------------------------------
-- Generic helpers
-- ---------------------------------------------------------------------
create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- 8-character invite code from an alphabet without look-alikes (0/O, 1/I).
-- 32 symbols, so `byte % 32` is uniform.
create function private.generate_invite_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  bytes bytea := extensions.gen_random_bytes(8);
  code text := '';
begin
  for i in 0..7 loop
    code := code || substr(alphabet, (get_byte(bytes, i) % 32) + 1, 1);
  end loop;
  return code;
end;
$$;

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  avatar_path text,
  locale text not null default 'ko' check (locale in ('ko', 'en')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

-- A profile row is created for every new auth user.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(
      coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
        nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
        nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
        'member'
      ),
      40
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- ---------------------------------------------------------------------
-- teams
-- ---------------------------------------------------------------------
create table public.teams (
  id bigint generated always as identity primary key,
  name text not null check (char_length(trim(name)) between 1 and 60),
  timezone text not null default 'Asia/Singapore',
  invite_code text not null unique default private.generate_invite_code(),
  join_requires_approval boolean not null default true,
  -- informational; the team outlives its creator's account
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index teams_created_by_idx on public.teams (created_by);

create function private.validate_team_timezone()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (select 1 from pg_catalog.pg_timezone_names where name = new.timezone) then
    raise exception 'invalid timezone: %', new.timezone using errcode = '22023';
  end if;
  return new;
end;
$$;

create trigger teams_validate_timezone
  before insert or update of timezone on public.teams
  for each row execute function private.validate_team_timezone();

-- ---------------------------------------------------------------------
-- team_members
-- ---------------------------------------------------------------------
create table public.team_members (
  team_id bigint not null references public.teams (id) on delete cascade,
  -- references profiles (not auth.users) so the API can embed member names;
  -- profiles cascade from auth.users, so account deletion still cascades.
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'leader', 'member')),
  status text not null default 'pending' check (status in ('pending', 'active')),
  joined_at timestamptz not null default now(),
  approved_at timestamptz,
  primary key (team_id, user_id),
  check (status = 'pending' or approved_at is not null)
);

create index team_members_user_id_idx on public.team_members (user_id);

-- ---------------------------------------------------------------------
-- Authorization predicates (used by RLS policies everywhere)
-- ---------------------------------------------------------------------
create function private.is_member(p_team_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.team_members m
    where m.team_id = p_team_id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
  );
$$;

create function private.is_leader(p_team_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.team_members m
    where m.team_id = p_team_id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
      and m.role in ('owner', 'leader')
  );
$$;

create function private.is_owner(p_team_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.team_members m
    where m.team_id = p_team_id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
      and m.role = 'owner'
  );
$$;

-- True when the caller may see `p_user_id`'s profile: they are active
-- together in some team, or the caller leads a team the other user is
-- waiting to join.
create function private.shares_team_with(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.team_members me
    join public.team_members them on them.team_id = me.team_id
    where me.user_id = (select auth.uid())
      and me.status = 'active'
      and them.user_id = p_user_id
      and (them.status = 'active' or me.role in ('owner', 'leader'))
  );
$$;

grant execute on function
  private.is_member(bigint),
  private.is_leader(bigint),
  private.is_owner(bigint),
  private.shares_team_with(uuid)
to authenticated, service_role;

-- ---------------------------------------------------------------------
-- parts (인도, 싱어, 건반, ...) and which members can serve which part
-- ---------------------------------------------------------------------
create table public.parts (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 30),
  kind text not null check (kind in ('vocal', 'instrument', 'tech')),
  sort_order integer not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  unique (team_id, id)
);

create index parts_team_id_idx on public.parts (team_id);

create table public.member_parts (
  team_id bigint not null,
  user_id uuid not null,
  part_id bigint not null,
  primary key (team_id, user_id, part_id),
  foreign key (team_id, user_id) references public.team_members (team_id, user_id) on delete cascade,
  foreign key (team_id, part_id) references public.parts (team_id, id) on delete cascade
);

create index member_parts_part_idx on public.member_parts (team_id, part_id);

-- ---------------------------------------------------------------------
-- notifications: one row per recipient. This table is the single path
-- for every notification (in-app list + push). Producers insert rows via
-- private.notify(); delivery is wired up in the push_delivery migration.
-- ---------------------------------------------------------------------
create table public.notification_prefs (
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null,
  push_enabled boolean not null default true,
  primary key (user_id, category)
);

create table public.notifications (
  id bigint generated always as identity primary key,
  team_id bigint references public.teams (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null,
  params jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  -- pending -> sending (claimed by the push function) -> sent | failed | skipped
  push_status text not null default 'pending'
    check (push_status in ('pending', 'sending', 'sent', 'failed', 'skipped')),
  push_attempts integer not null default 0,
  push_claimed_at timestamptz
);

create index notifications_user_created_idx on public.notifications (user_id, created_at desc);
create index notifications_team_idx on public.notifications (team_id);
create index notifications_pending_idx on public.notifications (created_at)
  where push_status = 'pending';

create table public.device_tokens (
  token text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now()
);

create index device_tokens_user_idx on public.device_tokens (user_id);

-- Insert one notification per distinct recipient. Push is pre-marked
-- 'skipped' for recipients who turned that category off.
create function private.notify(
  p_team_id bigint,
  p_user_ids uuid[],
  p_category text,
  p_params jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notifications (team_id, user_id, category, params, push_status)
  select
    p_team_id,
    r.user_id,
    p_category,
    coalesce(p_params, '{}'::jsonb),
    case when coalesce(np.push_enabled, true) then 'pending' else 'skipped' end
  from (select distinct u as user_id from unnest(p_user_ids) as u where u is not null) r
  left join public.notification_prefs np
    on np.user_id = r.user_id and np.category = p_category;
$$;

create function private.team_leader_ids(p_team_id bigint)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(m.user_id), '{}')
  from public.team_members m
  where m.team_id = p_team_id and m.status = 'active' and m.role in ('owner', 'leader');
$$;

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------
create function private.require_uid()
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  return v_uid;
end;
$$;

create function public.create_team(p_name text, p_timezone text default 'Asia/Singapore')
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_team_id bigint;
begin
  insert into public.teams (name, timezone, created_by)
  values (trim(p_name), p_timezone, v_uid)
  returning id into v_team_id;

  insert into public.team_members (team_id, user_id, role, status, approved_at)
  values (v_team_id, v_uid, 'owner', 'active', now());

  insert into public.parts (team_id, name, kind, sort_order)
  select v_team_id, p.name, p.kind, p.ord
  from (values
    ('인도', 'vocal', 10),
    ('싱어', 'vocal', 20),
    ('건반', 'instrument', 30),
    ('세컨건반', 'instrument', 40),
    ('일렉기타', 'instrument', 50),
    ('어쿠스틱기타', 'instrument', 60),
    ('베이스', 'instrument', 70),
    ('드럼', 'instrument', 80),
    ('음향', 'tech', 90),
    ('영상', 'tech', 100)
  ) as p(name, kind, ord);

  return v_team_id;
end;
$$;

create function public.join_team(p_invite_code text)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_team public.teams%rowtype;
  v_status text;
begin
  select * into v_team
  from public.teams
  where invite_code = upper(trim(p_invite_code));

  if not found then
    raise exception 'invalid invite code' using errcode = 'P0002';
  end if;

  v_status := case when v_team.join_requires_approval then 'pending' else 'active' end;

  insert into public.team_members (team_id, user_id, role, status, approved_at)
  values (v_team.id, v_uid, 'member', v_status, case when v_status = 'active' then now() end)
  on conflict (team_id, user_id) do nothing;

  if found and v_status = 'pending' then
    perform private.notify(
      v_team.id,
      private.team_leader_ids(v_team.id),
      'member_join_request',
      jsonb_build_object(
        'user_id', v_uid,
        'user_name', (select display_name from public.profiles where id = v_uid),
        'team_name', v_team.name
      )
    );
  end if;

  return v_team.id;
end;
$$;

create function public.approve_member(p_team_id bigint, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_uid();
  if not private.is_leader(p_team_id) then
    raise exception 'only leaders can approve members' using errcode = '42501';
  end if;

  update public.team_members
  set status = 'active', approved_at = now()
  where team_id = p_team_id and user_id = p_user_id and status = 'pending';

  if not found then
    raise exception 'no pending request for this user' using errcode = 'P0002';
  end if;

  perform private.notify(
    p_team_id,
    array[p_user_id],
    'member_approved',
    jsonb_build_object('team_name', (select name from public.teams where id = p_team_id))
  );
end;
$$;

create function public.reject_member(p_team_id bigint, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_uid();
  if not private.is_leader(p_team_id) then
    raise exception 'only leaders can reject members' using errcode = '42501';
  end if;

  delete from public.team_members
  where team_id = p_team_id and user_id = p_user_id and status = 'pending';
end;
$$;

-- Owners manage roles. A team always keeps at least one owner.
create function public.set_member_role(p_team_id bigint, p_user_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current text;
begin
  perform private.require_uid();
  if not private.is_owner(p_team_id) then
    raise exception 'only owners can change roles' using errcode = '42501';
  end if;
  if p_role not in ('owner', 'leader', 'member') then
    raise exception 'invalid role: %', p_role using errcode = '22023';
  end if;

  select role into v_current
  from public.team_members
  where team_id = p_team_id and user_id = p_user_id and status = 'active'
  for update;

  if not found then
    raise exception 'not an active member' using errcode = 'P0002';
  end if;

  if v_current = 'owner' and p_role <> 'owner' and (
    select count(*) from public.team_members
    where team_id = p_team_id and status = 'active' and role = 'owner'
  ) = 1 then
    raise exception 'a team needs at least one owner' using errcode = '23514';
  end if;

  update public.team_members
  set role = p_role
  where team_id = p_team_id and user_id = p_user_id;
end;
$$;

-- Leaders remove members; only owners remove owners; never the last owner.
create function public.remove_member(p_team_id bigint, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_target_role text;
begin
  select role into v_target_role
  from public.team_members
  where team_id = p_team_id and user_id = p_user_id
  for update;

  if not found then
    return;
  end if;

  if p_user_id <> v_uid then
    if not private.is_leader(p_team_id) then
      raise exception 'only leaders can remove members' using errcode = '42501';
    end if;
    if v_target_role = 'owner' and not private.is_owner(p_team_id) then
      raise exception 'only owners can remove owners' using errcode = '42501';
    end if;
  end if;

  if v_target_role = 'owner' and (
    select count(*) from public.team_members
    where team_id = p_team_id and status = 'active' and role = 'owner'
  ) = 1 then
    raise exception 'a team needs at least one owner' using errcode = '23514';
  end if;

  delete from public.team_members where team_id = p_team_id and user_id = p_user_id;
end;
$$;

create function public.leave_team(p_team_id bigint)
returns void
language sql
security definer
set search_path = ''
as $$
  select public.remove_member(p_team_id, private.require_uid());
$$;

create function public.rotate_invite_code(p_team_id bigint)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code text;
begin
  perform private.require_uid();
  if not private.is_leader(p_team_id) then
    raise exception 'only leaders can rotate the invite code' using errcode = '42501';
  end if;

  update public.teams
  set invite_code = private.generate_invite_code()
  where id = p_team_id
  returning invite_code into v_code;

  return v_code;
end;
$$;

-- Replace the set of parts a member can serve. Members set their own;
-- leaders can set anyone's.
create function public.set_member_parts(p_team_id bigint, p_user_id uuid, p_part_ids bigint[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
begin
  if not (
    (p_user_id = v_uid and private.is_member(p_team_id))
    or private.is_leader(p_team_id)
  ) then
    raise exception 'not allowed to change these parts' using errcode = '42501';
  end if;

  delete from public.member_parts
  where team_id = p_team_id and user_id = p_user_id
    and part_id <> all (coalesce(p_part_ids, '{}'));

  insert into public.member_parts (team_id, user_id, part_id)
  select p_team_id, p_user_id, pid
  from unnest(coalesce(p_part_ids, '{}')) as pid
  on conflict do nothing;
end;
$$;

-- A device token belongs to whoever registered it last (shared devices).
create function public.register_device_token(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
begin
  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (p_token, v_uid, p_platform, now())
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

-- ---------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.parts enable row level security;
alter table public.member_parts enable row level security;
alter table public.notification_prefs enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;

-- profiles
create policy "profiles: read self and teammates"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select private.shares_team_with(id)));

create policy "profiles: update self"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- teams: members read; pending applicants read the team they applied to
create policy "teams: read own teams"
  on public.teams for select to authenticated
  using (
    (select private.is_member(id))
    or exists (
      select 1 from public.team_members m
      where m.team_id = teams.id and m.user_id = (select auth.uid())
    )
  );

create policy "teams: leaders update settings"
  on public.teams for update to authenticated
  using ((select private.is_leader(id)))
  with check ((select private.is_leader(id)));

-- team_members: own row always; active members see active roster;
-- leaders also see pending requests. Writes go through RPCs only.
create policy "team_members: read roster"
  on public.team_members for select to authenticated
  using (
    user_id = (select auth.uid())
    or (status = 'active' and (select private.is_member(team_id)))
    or (select private.is_leader(team_id))
  );

-- parts
create policy "parts: members read"
  on public.parts for select to authenticated
  using ((select private.is_member(team_id)));

create policy "parts: leaders insert"
  on public.parts for insert to authenticated
  with check ((select private.is_leader(team_id)));

create policy "parts: leaders update"
  on public.parts for update to authenticated
  using ((select private.is_leader(team_id)))
  with check ((select private.is_leader(team_id)));

create policy "parts: leaders delete"
  on public.parts for delete to authenticated
  using ((select private.is_leader(team_id)));

-- member_parts: readable by teammates; writes through set_member_parts()
create policy "member_parts: members read"
  on public.member_parts for select to authenticated
  using ((select private.is_member(team_id)));

-- notification_prefs: own rows only
create policy "notification_prefs: own rows"
  on public.notification_prefs for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- notifications: own rows; the only client write is marking read
create policy "notifications: read own"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy "notifications: mark own read"
  on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- device_tokens: own rows; registration goes through register_device_token()
create policy "device_tokens: read own"
  on public.device_tokens for select to authenticated
  using (user_id = (select auth.uid()));

create policy "device_tokens: delete own"
  on public.device_tokens for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- Grants (least privilege; RLS decides which rows)
-- ---------------------------------------------------------------------
revoke all on table
  public.profiles, public.teams, public.team_members, public.parts,
  public.member_parts, public.notification_prefs, public.notifications,
  public.device_tokens
from anon, authenticated, service_role;

grant select on public.profiles to authenticated;
grant update (display_name, avatar_path, locale) on public.profiles to authenticated;

grant select on public.teams to authenticated;
grant update (name, timezone, join_requires_approval) on public.teams to authenticated;

grant select on public.team_members to authenticated;

grant select, insert, delete on public.parts to authenticated;
grant update (name, kind, sort_order, archived_at) on public.parts to authenticated;

grant select on public.member_parts to authenticated;

grant select, insert, update, delete on public.notification_prefs to authenticated;

grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

grant select, delete on public.device_tokens to authenticated;

-- Edge Functions use the service role.
grant select, insert, update, delete on all tables in schema public to service_role;

-- RPC surface
revoke execute on function
  public.create_team(text, text),
  public.join_team(text),
  public.approve_member(bigint, uuid),
  public.reject_member(bigint, uuid),
  public.set_member_role(bigint, uuid, text),
  public.remove_member(bigint, uuid),
  public.leave_team(bigint),
  public.rotate_invite_code(bigint),
  public.set_member_parts(bigint, uuid, bigint[]),
  public.register_device_token(text, text)
from public, anon;

grant execute on function
  public.create_team(text, text),
  public.join_team(text),
  public.approve_member(bigint, uuid),
  public.reject_member(bigint, uuid),
  public.set_member_role(bigint, uuid, text),
  public.remove_member(bigint, uuid),
  public.leave_team(bigint),
  public.rotate_invite_code(bigint),
  public.set_member_parts(bigint, uuid, bigint[]),
  public.register_device_token(text, text)
to authenticated;

-- private.require_uid is called from within definer RPCs only, but
-- leave_team (SQL function) and RPCs run as the owner, so no grant needed.

-- Realtime: clients get their own new notifications live. Postgres
-- Changes applies the table's RLS, so each user only receives their rows.
alter publication supabase_realtime add table public.notifications;
