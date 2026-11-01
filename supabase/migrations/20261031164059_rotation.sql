-- =====================================================================
-- M4: rotation (로테이션), blockout dates, swap requests, rehearsals with
-- RSVP and attendance, reminders and the calendar feed.
--
-- Assignment lifecycle: draft -> pending (sent) -> accepted | declined.
--  * Drafts are visible to leaders only and have no side effects, so
--    leaders edit them freely with plain inserts/updates/deletes
--    (auto-assign writes drafts too).
--  * Once sent, every change affects a person, so it goes through an RPC
--    that also notifies them: send, respond, reassign, remove, swap.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Slots: how many people per part. New sessions copy the team defaults.
-- ---------------------------------------------------------------------
create table public.default_slots (
  team_id bigint not null,
  part_id bigint not null,
  count smallint not null check (count between 1 and 20),
  primary key (team_id, part_id),
  foreign key (team_id, part_id) references public.parts (team_id, id) on delete cascade
);

create table public.session_slots (
  team_id bigint not null,
  session_id bigint not null,
  part_id bigint not null,
  count smallint not null check (count between 0 and 20),
  primary key (session_id, part_id),
  foreign key (team_id, session_id) references public.sessions (team_id, id) on delete cascade,
  foreign key (team_id, part_id) references public.parts (team_id, id) on delete cascade
);

create index session_slots_team_part_idx on public.session_slots (team_id, part_id);

create function private.copy_default_slots()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.session_slots (team_id, session_id, part_id, count)
  select new.team_id, new.id, d.part_id, d.count
  from public.default_slots d
  where d.team_id = new.team_id;
  return new;
end;
$$;

create trigger sessions_copy_default_slots
  after insert on public.sessions
  for each row execute function private.copy_default_slots();

-- ---------------------------------------------------------------------
-- Assignments
-- ---------------------------------------------------------------------
create table public.assignments (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  session_id bigint not null,
  part_id bigint not null,
  user_id uuid not null,
  status text not null default 'draft' check (status in ('draft', 'pending', 'accepted', 'declined')),
  source text not null default 'manual' check (source in ('manual', 'auto')),
  decline_reason text check (char_length(decline_reason) <= 200),
  sent_at timestamptz,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  unique (team_id, id),
  unique (session_id, part_id, user_id),
  foreign key (team_id, session_id) references public.sessions (team_id, id) on delete cascade,
  foreign key (team_id, part_id) references public.parts (team_id, id) on delete restrict,
  foreign key (team_id, user_id) references public.team_members (team_id, user_id) on delete cascade
);

create index assignments_team_session_idx on public.assignments (team_id, session_id);
create index assignments_team_user_idx on public.assignments (team_id, user_id);
create index assignments_team_part_idx on public.assignments (team_id, part_id);

-- ---------------------------------------------------------------------
-- Blockouts (불가능 날짜), in the team's local dates
-- ---------------------------------------------------------------------
create table public.blockouts (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  user_id uuid not null default auth.uid(),
  starts_on date not null,
  ends_on date not null,
  note text check (char_length(note) <= 200),
  created_at timestamptz not null default now(),
  check (ends_on >= starts_on),
  foreign key (team_id, user_id) references public.team_members (team_id, user_id) on delete cascade
);

create index blockouts_team_user_idx on public.blockouts (team_id, user_id);

-- ---------------------------------------------------------------------
-- Swap requests (대타)
-- ---------------------------------------------------------------------
create table public.swap_requests (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  assignment_id bigint not null,
  requested_by uuid not null references public.profiles (id) on delete cascade,
  message text check (char_length(message) <= 200),
  status text not null default 'open' check (status in ('open', 'filled', 'cancelled')),
  filled_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  foreign key (team_id, assignment_id) references public.assignments (team_id, id) on delete cascade
);

create unique index swap_requests_one_open_idx on public.swap_requests (assignment_id) where status = 'open';
create index swap_requests_team_idx on public.swap_requests (team_id, status);
create index swap_requests_requested_by_idx on public.swap_requests (requested_by);
create index swap_requests_filled_by_idx on public.swap_requests (filled_by);

-- ---------------------------------------------------------------------
-- Rehearsals, RSVP (members) and attendance (leaders)
-- ---------------------------------------------------------------------
create table public.rehearsals (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  session_id bigint,
  starts_at timestamptz not null,
  ends_at timestamptz,
  location text check (char_length(location) <= 80),
  notes text check (char_length(notes) <= 500),
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (team_id, id),
  check (ends_at is null or ends_at > starts_at),
  foreign key (team_id, session_id) references public.sessions (team_id, id) on delete set null (session_id)
);

create index rehearsals_team_starts_idx on public.rehearsals (team_id, starts_at);
create index rehearsals_session_idx on public.rehearsals (team_id, session_id);
create index rehearsals_created_by_idx on public.rehearsals (created_by);

create table public.rehearsal_responses (
  team_id bigint not null,
  rehearsal_id bigint not null,
  user_id uuid not null,
  rsvp text check (rsvp in ('going', 'not_going', 'late')),
  reason text check (char_length(reason) <= 200),
  attendance text check (attendance in ('present', 'absent', 'late')),
  updated_at timestamptz not null default now(),
  primary key (rehearsal_id, user_id),
  foreign key (team_id, rehearsal_id) references public.rehearsals (team_id, id) on delete cascade,
  foreign key (team_id, user_id) references public.team_members (team_id, user_id) on delete cascade
);

create index rehearsal_responses_team_user_idx on public.rehearsal_responses (team_id, user_id);

-- ---------------------------------------------------------------------
-- Calendar feed tokens (secret URL per user)
-- ---------------------------------------------------------------------
create table public.calendar_feeds (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  token uuid not null unique default gen_random_uuid(),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------
create function private.session_label(p_session_id bigint)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'session_id', s.id,
    'session_title', s.title,
    'starts_at', s.starts_at,
    'team_name', t.name,
    'timezone', t.timezone
  )
  from public.sessions s join public.teams t on t.id = s.team_id
  where s.id = p_session_id;
$$;

-- People who may take over an assignment: active members with that part,
-- not already serving in that session, not blocked out that (team-local) day.
create function private.swap_candidates(p_assignment_id bigint)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(m.user_id), '{}')
  from public.assignments a
  join public.sessions s on s.id = a.session_id
  join public.teams t on t.id = a.team_id
  join public.member_parts mp on mp.team_id = a.team_id and mp.part_id = a.part_id
  join public.team_members m on m.team_id = a.team_id and m.user_id = mp.user_id and m.status = 'active'
  where a.id = p_assignment_id
    and m.user_id <> a.user_id
    and not exists (
      select 1 from public.assignments other
      where other.session_id = a.session_id and other.user_id = m.user_id and other.status in ('pending', 'accepted')
    )
    and not exists (
      select 1 from public.blockouts b
      where b.team_id = a.team_id and b.user_id = m.user_id
        and (s.starts_at at time zone t.timezone)::date between b.starts_on and b.ends_on
    );
$$;

-- Setlist announcements now go to the people serving, leaders, and anyone
-- who opted in to every setlist (notification_prefs 'setlist_all').
create or replace function private.setlist_recipients(p_session_id bigint)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(distinct u), '{}')
  from (
    select a.user_id as u from public.assignments a
    where a.session_id = p_session_id and a.status in ('pending', 'accepted')
    union
    select m.user_id from public.sessions s
    join public.team_members m on m.team_id = s.team_id and m.status = 'active' and m.role in ('owner', 'leader')
    where s.id = p_session_id
    union
    select m.user_id from public.sessions s
    join public.team_members m on m.team_id = s.team_id and m.status = 'active'
    join public.notification_prefs np on np.user_id = m.user_id and np.category = 'setlist_all' and np.push_enabled
    where s.id = p_session_id
  ) r;
$$;

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- Send every draft of the given sessions; returns how many were sent.
create function public.send_assignments(p_session_ids bigint[])
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  r record;
  v_count integer := 0;
begin
  if exists (
    select 1 from public.sessions s
    where s.id = any (p_session_ids) and not private.is_leader(s.team_id)
  ) then
    raise exception 'only leaders can send assignments' using errcode = '42501';
  end if;

  for r in
    update public.assignments a
    set status = 'pending', sent_at = now()
    where a.session_id = any (p_session_ids) and a.status = 'draft'
    returning a.team_id, a.session_id, a.user_id, a.part_id
  loop
    v_count := v_count + 1;
    if r.user_id <> v_uid then
      perform private.notify(
        r.team_id, array[r.user_id], 'assignment_requested',
        private.session_label(r.session_id) || jsonb_build_object('part_name', (select name from public.parts where id = r.part_id))
      );
    end if;
  end loop;
  return v_count;
end;
$$;

create function public.respond_assignment(p_assignment_id bigint, p_accept boolean, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_a public.assignments%rowtype;
begin
  select * into v_a from public.assignments where id = p_assignment_id for update;
  if not found or v_a.user_id <> v_uid then
    raise exception 'not your assignment' using errcode = '42501';
  end if;
  if v_a.status = 'draft' then
    raise exception 'assignment was not sent yet' using errcode = '22023';
  end if;

  update public.assignments
  set status = case when p_accept then 'accepted' else 'declined' end,
      decline_reason = case when p_accept then null else left(nullif(trim(p_reason), ''), 200) end,
      responded_at = now()
  where id = p_assignment_id;

  if not p_accept then
    perform private.notify(
      v_a.team_id,
      private.team_leader_ids(v_a.team_id),
      'assignment_declined',
      private.session_label(v_a.session_id) || jsonb_build_object(
        'user_name', (select display_name from public.profiles where id = v_uid),
        'part_name', (select name from public.parts where id = v_a.part_id),
        'reason', nullif(trim(p_reason), '')
      )
    );
  end if;
end;
$$;

-- Leaders change who serves after sending: the new person gets a fresh
-- request, the previous one is told.
create function public.reassign_assignment(p_assignment_id bigint, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_a public.assignments%rowtype;
  v_label jsonb;
begin
  perform private.require_uid();
  select * into v_a from public.assignments where id = p_assignment_id for update;
  if not found or not private.is_leader(v_a.team_id) then
    raise exception 'only leaders can reassign' using errcode = '42501';
  end if;
  if v_a.user_id = p_user_id then
    return;
  end if;

  update public.assignments
  set user_id = p_user_id,
      status = case when v_a.status = 'draft' then 'draft' else 'pending' end,
      sent_at = case when v_a.status = 'draft' then null else now() end,
      responded_at = null,
      decline_reason = null
  where id = p_assignment_id;

  if v_a.status <> 'draft' then
    v_label := private.session_label(v_a.session_id) || jsonb_build_object('part_name', (select name from public.parts where id = v_a.part_id));
    perform private.notify(v_a.team_id, array[p_user_id], 'assignment_requested', v_label);
    perform private.notify(v_a.team_id, array[v_a.user_id], 'assignment_removed', v_label);
  end if;
end;
$$;

create function public.remove_assignment(p_assignment_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_a public.assignments%rowtype;
begin
  perform private.require_uid();
  select * into v_a from public.assignments where id = p_assignment_id for update;
  if not found then
    return;
  end if;
  if not private.is_leader(v_a.team_id) then
    raise exception 'only leaders can remove assignments' using errcode = '42501';
  end if;

  delete from public.assignments where id = p_assignment_id;

  if v_a.status <> 'draft' then
    perform private.notify(
      v_a.team_id, array[v_a.user_id], 'assignment_removed',
      private.session_label(v_a.session_id) || jsonb_build_object('part_name', (select name from public.parts where id = v_a.part_id))
    );
  end if;
end;
$$;

create function public.request_swap(p_assignment_id bigint, p_message text default null)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_a public.assignments%rowtype;
  v_id bigint;
begin
  select * into v_a from public.assignments where id = p_assignment_id;
  if not found or v_a.user_id <> v_uid then
    raise exception 'not your assignment' using errcode = '42501';
  end if;
  if v_a.status not in ('pending', 'accepted') then
    raise exception 'only sent assignments can be swapped' using errcode = '22023';
  end if;

  insert into public.swap_requests (team_id, assignment_id, requested_by, message)
  values (v_a.team_id, p_assignment_id, v_uid, left(nullif(trim(p_message), ''), 200))
  returning id into v_id;

  perform private.notify(
    v_a.team_id,
    private.swap_candidates(p_assignment_id),
    'swap_requested',
    private.session_label(v_a.session_id) || jsonb_build_object(
      'swap_id', v_id,
      'user_name', (select display_name from public.profiles where id = v_uid),
      'part_name', (select name from public.parts where id = v_a.part_id),
      'message', nullif(trim(p_message), '')
    )
  );
  return v_id;
end;
$$;

-- First eligible person to accept takes the assignment. The row lock makes
-- two simultaneous acceptances safe: the second finds the request filled.
create function public.accept_swap(p_swap_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_swap public.swap_requests%rowtype;
  v_a public.assignments%rowtype;
  v_label jsonb;
begin
  select * into v_swap from public.swap_requests where id = p_swap_id for update;
  if not found or v_swap.status <> 'open' then
    raise exception 'this request is no longer open' using errcode = 'P0002';
  end if;
  if not (v_uid = any (private.swap_candidates(v_swap.assignment_id))) then
    raise exception 'you cannot take this assignment' using errcode = '42501';
  end if;

  select * into v_a from public.assignments where id = v_swap.assignment_id for update;
  update public.assignments
  set user_id = v_uid, status = 'accepted', responded_at = now(), decline_reason = null
  where id = v_a.id;

  update public.swap_requests
  set status = 'filled', filled_by = v_uid, closed_at = now()
  where id = p_swap_id;

  v_label := private.session_label(v_a.session_id) || jsonb_build_object(
    'user_name', (select display_name from public.profiles where id = v_uid),
    'part_name', (select name from public.parts where id = v_a.part_id)
  );
  perform private.notify(
    v_a.team_id,
    array(select distinct u from unnest(array[v_swap.requested_by] || private.team_leader_ids(v_a.team_id)) u where u <> v_uid),
    'swap_filled',
    v_label
  );
end;
$$;

create function public.cancel_swap(p_swap_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.swap_requests
  set status = 'cancelled', closed_at = now()
  where id = p_swap_id and status = 'open' and requested_by = private.require_uid();
end;
$$;

create function public.set_rsvp(p_rehearsal_id bigint, p_rsvp text, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_team bigint;
begin
  select team_id into v_team from public.rehearsals where id = p_rehearsal_id;
  if v_team is null or not private.is_member(v_team) then
    raise exception 'not a member' using errcode = '42501';
  end if;
  if p_rsvp not in ('going', 'not_going', 'late') then
    raise exception 'invalid rsvp' using errcode = '22023';
  end if;

  insert into public.rehearsal_responses (team_id, rehearsal_id, user_id, rsvp, reason, updated_at)
  values (v_team, p_rehearsal_id, v_uid, p_rsvp, left(nullif(trim(p_reason), ''), 200), now())
  on conflict (rehearsal_id, user_id) do update
    set rsvp = excluded.rsvp, reason = excluded.reason, updated_at = now();
end;
$$;

create function public.record_attendance(p_rehearsal_id bigint, p_user_id uuid, p_attendance text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_team bigint;
begin
  perform private.require_uid();
  select team_id into v_team from public.rehearsals where id = p_rehearsal_id;
  if v_team is null or not private.is_leader(v_team) then
    raise exception 'only leaders record attendance' using errcode = '42501';
  end if;
  if p_attendance is not null and p_attendance not in ('present', 'absent', 'late') then
    raise exception 'invalid attendance' using errcode = '22023';
  end if;

  insert into public.rehearsal_responses (team_id, rehearsal_id, user_id, attendance, updated_at)
  values (v_team, p_rehearsal_id, p_user_id, p_attendance, now())
  on conflict (rehearsal_id, user_id) do update
    set attendance = excluded.attendance, updated_at = now();
end;
$$;

-- New secret calendar URL (the old one stops working).
create function public.rotate_calendar_token()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_token uuid;
begin
  insert into public.calendar_feeds (user_id) values (v_uid)
  on conflict (user_id) do update set token = gen_random_uuid(), created_at = now()
  returning token into v_token;
  return v_token;
end;
$$;

-- Notify people serving / invited when a rehearsal is scheduled.
create function private.notify_rehearsal()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.notify(
    new.team_id,
    case
      when new.session_id is null then
        array(select user_id from public.team_members where team_id = new.team_id and status = 'active' and user_id <> coalesce(new.created_by, '00000000-0000-0000-0000-000000000000'))
      else
        array(select user_id from public.assignments where session_id = new.session_id and status in ('pending', 'accepted') and user_id <> coalesce(new.created_by, '00000000-0000-0000-0000-000000000000'))
    end,
    'rehearsal_scheduled',
    coalesce(private.session_label(new.session_id), (select jsonb_build_object('team_name', name, 'timezone', timezone) from public.teams where id = new.team_id))
      || jsonb_build_object('rehearsal_id', new.id, 'starts_at', new.starts_at, 'location', new.location)
  );
  return new;
end;
$$;

create trigger rehearsals_notify
  after insert on public.rehearsals
  for each row execute function private.notify_rehearsal();

-- ---------------------------------------------------------------------
-- Reminders (pg_cron, every 5 minutes; each reminder is sent once)
-- ---------------------------------------------------------------------
create table private.reminders_sent (
  kind text not null,
  target_id bigint not null,
  user_id uuid not null,
  sent_at timestamptz not null default now(),
  primary key (kind, target_id, user_id)
);

create function private.enqueue_due_reminders()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
begin
  -- Service tomorrow: from 20:00 the evening before (team time)
  for r in
    select a.team_id, a.session_id, a.user_id, a.part_id
    from public.assignments a
    join public.sessions s on s.id = a.session_id
    join public.teams t on t.id = a.team_id
    where a.status in ('pending', 'accepted')
      and (s.starts_at at time zone t.timezone)::date = (now() at time zone t.timezone)::date + 1
      and (now() at time zone t.timezone)::time >= time '20:00'
      and not exists (select 1 from private.reminders_sent x where x.kind = 'service' and x.target_id = a.session_id and x.user_id = a.user_id)
  loop
    insert into private.reminders_sent (kind, target_id, user_id) values ('service', r.session_id, r.user_id);
    perform private.notify(r.team_id, array[r.user_id], 'service_reminder',
      private.session_label(r.session_id) || jsonb_build_object('part_name', (select name from public.parts where id = r.part_id)));
  end loop;

  -- Rehearsal within two hours: the people invited who did not say no
  for r in
    select rh.id, rh.team_id, rh.starts_at, rh.location, rh.session_id, inv.user_id
    from public.rehearsals rh
    cross join lateral (
      select m.user_id from public.team_members m
      where rh.session_id is null and m.team_id = rh.team_id and m.status = 'active'
      union
      select a.user_id from public.assignments a
      where a.session_id = rh.session_id and a.status in ('pending', 'accepted')
    ) inv
    where rh.starts_at between now() and now() + interval '2 hours'
      and not exists (select 1 from public.rehearsal_responses rr where rr.rehearsal_id = rh.id and rr.user_id = inv.user_id and rr.rsvp = 'not_going')
      and not exists (select 1 from private.reminders_sent x where x.kind = 'rehearsal' and x.target_id = rh.id and x.user_id = inv.user_id)
  loop
    insert into private.reminders_sent (kind, target_id, user_id) values ('rehearsal', r.id, r.user_id);
    perform private.notify(r.team_id, array[r.user_id], 'rehearsal_reminder',
      coalesce(private.session_label(r.session_id), (select jsonb_build_object('team_name', name, 'timezone', timezone) from public.teams where id = r.team_id))
        || jsonb_build_object('rehearsal_id', r.id, 'starts_at', r.starts_at, 'location', r.location));
  end loop;

  -- No answer for 48 hours to a request for an upcoming service
  for r in
    select a.id, a.team_id, a.session_id, a.user_id, a.part_id
    from public.assignments a
    join public.sessions s on s.id = a.session_id
    where a.status = 'pending'
      and a.sent_at < now() - interval '48 hours'
      and s.starts_at > now()
      and not exists (select 1 from private.reminders_sent x where x.kind = 'nudge' and x.target_id = a.id and x.user_id = a.user_id)
  loop
    insert into private.reminders_sent (kind, target_id, user_id) values ('nudge', r.id, r.user_id);
    perform private.notify(r.team_id, array[r.user_id], 'assignment_nudge',
      private.session_label(r.session_id) || jsonb_build_object('part_name', (select name from public.parts where id = r.part_id)));
  end loop;

  delete from private.reminders_sent where sent_at < now() - interval '60 days';
end;
$$;

revoke execute on function private.enqueue_due_reminders() from public, authenticated, service_role;
select cron.schedule('reminders', '*/5 * * * *', $$select private.enqueue_due_reminders()$$);

-- ---------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------
alter table public.default_slots enable row level security;
alter table public.session_slots enable row level security;
alter table public.assignments enable row level security;
alter table public.blockouts enable row level security;
alter table public.swap_requests enable row level security;
alter table public.rehearsals enable row level security;
alter table public.rehearsal_responses enable row level security;
alter table public.calendar_feeds enable row level security;

create policy "default_slots: members read" on public.default_slots for select to authenticated
  using ((select private.is_member(team_id)));
create policy "default_slots: leaders add" on public.default_slots for insert to authenticated
  with check ((select private.is_leader(team_id)));
create policy "default_slots: leaders edit" on public.default_slots for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "default_slots: leaders delete" on public.default_slots for delete to authenticated
  using ((select private.is_leader(team_id)));

create policy "session_slots: members read" on public.session_slots for select to authenticated
  using ((select private.is_member(team_id)));
create policy "session_slots: leaders add" on public.session_slots for insert to authenticated
  with check ((select private.is_leader(team_id)));
create policy "session_slots: leaders edit" on public.session_slots for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "session_slots: leaders delete" on public.session_slots for delete to authenticated
  using ((select private.is_leader(team_id)));

-- Members see sent assignments (the schedule); drafts are leaders' only.
create policy "assignments: read the schedule" on public.assignments for select to authenticated
  using (
    (status <> 'draft' and (select private.is_member(team_id)))
    or (select private.is_leader(team_id))
  );
-- Leaders edit drafts directly; sent ones go through the RPCs above.
create policy "assignments: leaders add drafts" on public.assignments for insert to authenticated
  with check ((select private.is_leader(team_id)) and status = 'draft');
create policy "assignments: leaders edit drafts" on public.assignments for update to authenticated
  using ((select private.is_leader(team_id)) and status = 'draft')
  with check ((select private.is_leader(team_id)) and status = 'draft');
create policy "assignments: leaders delete drafts" on public.assignments for delete to authenticated
  using ((select private.is_leader(team_id)) and status = 'draft');

-- Blockouts: your own; leaders see everyone's to plan.
create policy "blockouts: own or leader reads" on public.blockouts for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_leader(team_id)));
create policy "blockouts: own add" on public.blockouts for insert to authenticated
  with check (user_id = (select auth.uid()) and (select private.is_member(team_id)));
create policy "blockouts: own edit" on public.blockouts for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "blockouts: own delete" on public.blockouts for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "swap_requests: members read" on public.swap_requests for select to authenticated
  using ((select private.is_member(team_id)));

create policy "rehearsals: members read" on public.rehearsals for select to authenticated
  using ((select private.is_member(team_id)));
create policy "rehearsals: leaders add" on public.rehearsals for insert to authenticated
  with check ((select private.is_leader(team_id)) and created_by = (select auth.uid()));
create policy "rehearsals: leaders edit" on public.rehearsals for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "rehearsals: leaders delete" on public.rehearsals for delete to authenticated
  using ((select private.is_leader(team_id)));

-- Responses: your own row; leaders see the team's (attendance is theirs to keep).
create policy "rehearsal_responses: own or leader reads" on public.rehearsal_responses for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_leader(team_id)));

create policy "calendar_feeds: own" on public.calendar_feeds for select to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------
revoke all on table
  public.default_slots, public.session_slots, public.assignments, public.blockouts,
  public.swap_requests, public.rehearsals, public.rehearsal_responses, public.calendar_feeds
from anon, authenticated, service_role;

grant select, insert, update, delete on public.default_slots, public.session_slots to authenticated;
grant select, insert, delete on public.assignments to authenticated;
grant update (part_id, user_id, source) on public.assignments to authenticated;
grant select, insert, delete on public.blockouts to authenticated;
grant update (starts_on, ends_on, note) on public.blockouts to authenticated;
grant select on public.swap_requests to authenticated;
grant select, insert, delete on public.rehearsals to authenticated;
grant update (session_id, starts_at, ends_at, location, notes) on public.rehearsals to authenticated;
grant select on public.rehearsal_responses to authenticated;
grant select on public.calendar_feeds to authenticated;

grant select, insert, update, delete on all tables in schema public to service_role;

revoke execute on function
  public.send_assignments(bigint[]),
  public.respond_assignment(bigint, boolean, text),
  public.reassign_assignment(bigint, uuid),
  public.remove_assignment(bigint),
  public.request_swap(bigint, text),
  public.accept_swap(bigint),
  public.cancel_swap(bigint),
  public.set_rsvp(bigint, text, text),
  public.record_attendance(bigint, uuid, text),
  public.rotate_calendar_token()
from public, anon;

grant execute on function
  public.send_assignments(bigint[]),
  public.respond_assignment(bigint, boolean, text),
  public.reassign_assignment(bigint, uuid),
  public.remove_assignment(bigint),
  public.request_swap(bigint, text),
  public.accept_swap(bigint),
  public.cancel_swap(bigint),
  public.set_rsvp(bigint, text, text),
  public.record_attendance(bigint, uuid, text),
  public.rotate_calendar_token()
to authenticated;
