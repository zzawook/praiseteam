-- =====================================================================
-- M5: chat channels, announcements and polls.
--
-- Channels
--  * team     everyone in the team
--  * parts    members who play any of the channel's parts (e.g. 싱어팀 =
--             인도 + 싱어). Membership follows member_parts, so changing
--             your parts moves you between channels automatically.
--  * session  people asked to serve in that service; created when the
--             first request for it is sent; read-only a week after.
--  Leaders can open every channel. Who may read a channel is decided in
--  one place: private.can_access_channel().
--
-- Read state (channel_reads, announcement_seen) is readable only by its
-- owner: nobody can see who has read what.
-- Chat notifications are push-only (listed = false) so they never bury the
-- notification list.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Channels
-- ---------------------------------------------------------------------
create table public.channels (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  kind text not null check (kind in ('team', 'parts', 'session')),
  name text not null check (char_length(trim(name)) between 1 and 40),
  session_id bigint,
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (team_id, id),
  constraint channels_one_per_session unique (session_id),
  foreign key (team_id, session_id) references public.sessions (team_id, id) on delete cascade,
  check ((kind = 'session') = (session_id is not null))
);

create index channels_team_idx on public.channels (team_id);
create index channels_created_by_idx on public.channels (created_by);

create table public.channel_parts (
  team_id bigint not null,
  channel_id bigint not null,
  part_id bigint not null,
  primary key (channel_id, part_id),
  foreign key (team_id, channel_id) references public.channels (team_id, id) on delete cascade,
  foreign key (team_id, part_id) references public.parts (team_id, id) on delete cascade
);

create index channel_parts_part_idx on public.channel_parts (team_id, part_id);

create function private.can_access_channel(p_channel_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.channels c
    where c.id = p_channel_id
      and private.is_member(c.team_id)
      and (
        c.kind = 'team'
        or private.is_leader(c.team_id)
        or (c.kind = 'parts' and exists (
              select 1 from public.channel_parts cp
              join public.member_parts mp on mp.team_id = cp.team_id and mp.part_id = cp.part_id
              where cp.channel_id = c.id and mp.user_id = (select auth.uid())))
        or (c.kind = 'session' and exists (
              select 1 from public.assignments a
              where a.session_id = c.session_id and a.user_id = (select auth.uid())
                and a.status in ('pending', 'accepted')))
      )
  );
$$;

grant execute on function private.can_access_channel(bigint) to authenticated;

-- Everyone who receives a channel's messages (for notifications).
create function private.channel_member_ids(p_channel_id bigint)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(distinct m.user_id), '{}')
  from public.channels c
  join public.team_members m on m.team_id = c.team_id and m.status = 'active'
  where c.id = p_channel_id
    and (
      c.kind = 'team'
      or m.role in ('owner', 'leader')
      or (c.kind = 'parts' and exists (
            select 1 from public.channel_parts cp
            join public.member_parts mp on mp.team_id = cp.team_id and mp.part_id = cp.part_id
            where cp.channel_id = c.id and mp.user_id = m.user_id))
      or (c.kind = 'session' and exists (
            select 1 from public.assignments a
            where a.session_id = c.session_id and a.user_id = m.user_id and a.status in ('pending', 'accepted')))
    );
$$;

-- ---------------------------------------------------------------------
-- Messages
-- ---------------------------------------------------------------------
create table public.messages (
  id uuid primary key,                    -- generated on the device
  team_id bigint not null,
  channel_id bigint not null,
  sender_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  body text check (char_length(body) between 1 and 4000),
  reply_to uuid references public.messages (id) on delete set null,
  poll_id bigint,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  foreign key (team_id, channel_id) references public.channels (team_id, id) on delete cascade,
  -- a deleted message keeps no text
  check (deleted_at is not null or body is not null or poll_id is not null)
);

create index messages_channel_created_idx on public.messages (channel_id, created_at desc);
create index messages_sender_idx on public.messages (sender_id);
create index messages_team_idx on public.messages (team_id);
create index messages_reply_idx on public.messages (reply_to);

create table public.channel_reads (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  team_id bigint not null,
  channel_id bigint not null,
  last_read_at timestamptz not null default now(),
  muted boolean not null default false,
  primary key (user_id, channel_id),
  foreign key (team_id, channel_id) references public.channels (team_id, id) on delete cascade
);

create index channel_reads_channel_idx on public.channel_reads (team_id, channel_id);

-- ---------------------------------------------------------------------
-- Announcements: personal "seen" marker (own only), notify on post
-- ---------------------------------------------------------------------
alter table public.announcements add constraint announcements_team_id_id_key unique (team_id, id);

create table public.announcement_seen (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  team_id bigint not null references public.teams (id) on delete cascade,
  seen_at timestamptz not null default now(),
  primary key (user_id, team_id)
);

create index announcement_seen_team_idx on public.announcement_seen (team_id);

-- ---------------------------------------------------------------------
-- Polls
-- ---------------------------------------------------------------------
create table public.polls (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams (id) on delete cascade,
  channel_id bigint,
  announcement_id bigint,
  question text not null check (char_length(trim(question)) between 1 and 200),
  multiple boolean not null default false,
  anonymous boolean not null default false,
  closes_at timestamptz,
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (team_id, id),
  foreign key (team_id, channel_id) references public.channels (team_id, id) on delete cascade,
  foreign key (team_id, announcement_id) references public.announcements (team_id, id) on delete cascade,
  check (num_nonnulls(channel_id, announcement_id) = 1)
);

create index polls_channel_idx on public.polls (team_id, channel_id);
create index polls_announcement_idx on public.polls (team_id, announcement_id);
create index polls_created_by_idx on public.polls (created_by);

alter table public.messages
  add constraint messages_poll_fkey foreign key (team_id, poll_id) references public.polls (team_id, id) on delete cascade;
create index messages_poll_idx on public.messages (team_id, poll_id);

create table public.poll_options (
  id bigint generated always as identity primary key,
  team_id bigint not null,
  poll_id bigint not null,
  label text not null check (char_length(trim(label)) between 1 and 100),
  position integer not null,
  unique (team_id, id),
  unique (poll_id, position),
  foreign key (team_id, poll_id) references public.polls (team_id, id) on delete cascade
);

create table public.poll_votes (
  team_id bigint not null,
  poll_id bigint not null,
  option_id bigint not null,
  user_id uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (poll_id, option_id, user_id),
  foreign key (team_id, poll_id) references public.polls (team_id, id) on delete cascade,
  foreign key (team_id, option_id) references public.poll_options (team_id, id) on delete cascade,
  foreign key (team_id, user_id) references public.team_members (team_id, user_id) on delete cascade
);

create index poll_votes_option_idx on public.poll_votes (team_id, option_id);
create index poll_votes_user_idx on public.poll_votes (team_id, user_id);

create function private.can_see_poll(p_poll_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.polls p
    where p.id = p_poll_id
      and case when p.channel_id is not null
               then private.can_access_channel(p.channel_id)
               else private.is_member(p.team_id) end
  );
$$;

grant execute on function private.can_see_poll(bigint) to authenticated;

-- ---------------------------------------------------------------------
-- Notifications: chat is push-only
-- ---------------------------------------------------------------------
alter table public.notifications add column listed boolean not null default true;

-- One notify(): existing callers pass four arguments and get listed = true.
-- (Replacing in place keeps call sites unambiguous.)
drop function private.notify(bigint, uuid[], text, jsonb);

create function private.notify(
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
    coalesce(p_params, '{}'::jsonb),
    case when coalesce(np.push_enabled, true) then 'pending' else 'skipped' end,
    p_listed
  from (select distinct u as user_id from unnest(p_user_ids) as u where u is not null) r
  left join public.notification_prefs np
    on np.user_id = r.user_id and np.category = p_category;
$$;

create function private.notify_chat_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel public.channels%rowtype;
begin
  select * into v_channel from public.channels where id = new.channel_id;
  perform private.notify(
    new.team_id,
    array(
      select u from unnest(private.channel_member_ids(new.channel_id)) as u
      where u <> new.sender_id
        and not exists (select 1 from public.channel_reads r where r.channel_id = new.channel_id and r.user_id = u and r.muted)
    ),
    'chat_message',
    jsonb_build_object(
      'channel_id', new.channel_id,
      'channel_name', v_channel.name,
      'sender_name', (select display_name from public.profiles where id = new.sender_id),
      'preview', case when new.poll_id is not null
                      then coalesce((select question from public.polls where id = new.poll_id), '')
                      else left(new.body, 120) end,
      'is_poll', new.poll_id is not null,
      'team_name', (select name from public.teams where id = new.team_id)
    ),
    false
  );
  return new;
end;
$$;

create trigger messages_notify
  after insert on public.messages
  for each row execute function private.notify_chat_message();

create function private.notify_announcement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.kind = 'general' then
    perform private.notify(
      new.team_id,
      array(select user_id from public.team_members
            where team_id = new.team_id and status = 'active' and user_id <> coalesce(new.created_by, '00000000-0000-0000-0000-000000000000')),
      'announcement',
      jsonb_build_object(
        'announcement_id', new.id,
        'title', new.title,
        'preview', left(coalesce(new.body, ''), 120),
        'team_name', (select name from public.teams where id = new.team_id)
      )
    );
  end if;
  return new;
end;
$$;

create trigger announcements_notify
  after insert on public.announcements
  for each row execute function private.notify_announcement();

-- ---------------------------------------------------------------------
-- Default channels and session chats
-- ---------------------------------------------------------------------
create or replace function public.create_team(p_name text, p_timezone text default 'Asia/Singapore')
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_team_id bigint;
  v_channel bigint;
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

  insert into public.channels (team_id, kind, name, created_by) values (v_team_id, 'team', '전체', v_uid);

  insert into public.channels (team_id, kind, name, created_by)
  values (v_team_id, 'parts', '싱어팀', v_uid) returning id into v_channel;
  insert into public.channel_parts (team_id, channel_id, part_id)
  select v_team_id, v_channel, id from public.parts where team_id = v_team_id and kind = 'vocal';

  insert into public.channels (team_id, kind, name, created_by)
  values (v_team_id, 'parts', '악기팀', v_uid) returning id into v_channel;
  insert into public.channel_parts (team_id, channel_id, part_id)
  select v_team_id, v_channel, id from public.parts where team_id = v_team_id and kind = 'instrument';

  return v_team_id;
end;
$$;

-- A service gets its chat as soon as someone is asked to serve in it.
create function private.ensure_session_channel()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status in ('pending', 'accepted') then
    insert into public.channels (team_id, kind, name, session_id, created_by)
    select new.team_id, 'session', left(s.title, 40), s.id, s.created_by
    from public.sessions s where s.id = new.session_id
    on conflict (session_id) do nothing;
  end if;
  return new;
end;
$$;

create trigger assignments_session_channel
  after insert or update of status on public.assignments
  for each row execute function private.ensure_session_channel();

-- Session chats close a week after the service.
create function private.archive_session_channels()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.channels c
  set archived_at = now()
  from public.sessions s
  where c.kind = 'session' and c.archived_at is null
    and s.id = c.session_id and s.starts_at < now() - interval '7 days';

  -- push-only chat notifications are not kept long
  delete from public.notifications where listed = false and created_at < now() - interval '14 days';
$$;

revoke execute on function private.archive_session_channels() from public, authenticated, service_role;
select cron.schedule('archive-session-channels', '23 4 * * *', $$select private.archive_session_channels()$$);

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- My channels with unread counts and the latest message (RLS decides which).
create function public.my_channels(p_team_id bigint)
returns table (
  id bigint,
  kind text,
  name text,
  session_id bigint,
  archived boolean,
  muted boolean,
  unread integer,
  last_body text,
  last_is_poll boolean,
  last_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    c.id, c.kind, c.name, c.session_id,
    c.archived_at is not null,
    coalesce(r.muted, false),
    (select count(*)::int from public.messages m
     where m.channel_id = c.id and m.deleted_at is null
       and m.sender_id <> (select auth.uid())
       and m.created_at > coalesce(r.last_read_at, '-infinity'::timestamptz)),
    last.body,
    last.is_poll,
    last.created_at
  from public.channels c
  left join public.channel_reads r on r.channel_id = c.id and r.user_id = (select auth.uid())
  left join lateral (
    -- a poll message has no body: show its question (the app adds "Poll:")
    select coalesce(m.body, (select p.question from public.polls p where p.id = m.poll_id), '') as body,
           m.poll_id is not null as is_poll,
           m.created_at
    from public.messages m
    where m.channel_id = c.id and m.deleted_at is null
    order by m.created_at desc
    limit 1
  ) last on true
  where c.team_id = p_team_id
  order by c.archived_at is not null, last.created_at desc nulls last, c.id;
$$;

create function public.create_poll(
  p_team_id bigint,
  p_question text,
  p_options text[],
  p_channel_id bigint default null,
  p_announcement_id bigint default null,
  p_multiple boolean default false,
  p_anonymous boolean default false,
  p_closes_at timestamptz default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_poll bigint;
begin
  if p_channel_id is not null then
    if not private.can_access_channel(p_channel_id)
       or exists (select 1 from public.channels where id = p_channel_id and archived_at is not null) then
      raise exception 'cannot post in this channel' using errcode = '42501';
    end if;
  elsif p_announcement_id is not null then
    if not private.is_leader(p_team_id) then
      raise exception 'only leaders attach polls to announcements' using errcode = '42501';
    end if;
  end if;
  if coalesce(cardinality(p_options), 0) < 2 or cardinality(p_options) > 10 then
    raise exception 'a poll needs 2 to 10 options' using errcode = '22023';
  end if;

  insert into public.polls (team_id, channel_id, announcement_id, question, multiple, anonymous, closes_at, created_by)
  values (p_team_id, p_channel_id, p_announcement_id, trim(p_question), p_multiple, p_anonymous, p_closes_at, v_uid)
  returning id into v_poll;

  insert into public.poll_options (team_id, poll_id, label, position)
  select p_team_id, v_poll, trim(o), ord
  from unnest(p_options) with ordinality as t(o, ord);

  if p_channel_id is not null then
    insert into public.messages (id, team_id, channel_id, sender_id, poll_id)
    values (gen_random_uuid(), p_team_id, p_channel_id, v_uid, v_poll);
  end if;
  return v_poll;
end;
$$;

-- Replace my votes on a poll.
create function public.poll_vote(p_poll_id bigint, p_option_ids bigint[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_poll public.polls%rowtype;
begin
  select * into v_poll from public.polls where id = p_poll_id;
  if not found or not private.can_see_poll(p_poll_id) then
    raise exception 'poll not found' using errcode = 'P0002';
  end if;
  if v_poll.closes_at is not null and v_poll.closes_at < now() then
    raise exception 'this poll is closed' using errcode = '22023';
  end if;
  if not v_poll.multiple and coalesce(cardinality(p_option_ids), 0) > 1 then
    raise exception 'pick one option' using errcode = '22023';
  end if;
  if exists (
    select 1 from unnest(coalesce(p_option_ids, '{}')) o
    where not exists (select 1 from public.poll_options po where po.id = o and po.poll_id = p_poll_id)
  ) then
    raise exception 'option does not belong to this poll' using errcode = '22023';
  end if;

  delete from public.poll_votes where poll_id = p_poll_id and user_id = v_uid;
  insert into public.poll_votes (team_id, poll_id, option_id, user_id)
  select v_poll.team_id, p_poll_id, o, v_uid from unnest(coalesce(p_option_ids, '{}')) o;
end;
$$;

-- Counts per option, my own choices, and voter names unless anonymous.
create function public.poll_results(p_poll_id bigint)
returns table (option_id bigint, label text, votes integer, mine boolean, voters text[])
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_anonymous boolean;
begin
  if not private.can_see_poll(p_poll_id) then
    raise exception 'poll not found' using errcode = 'P0002';
  end if;
  select anonymous into v_anonymous from public.polls where id = p_poll_id;

  return query
  select
    o.id,
    o.label,
    count(v.user_id)::int,
    coalesce(bool_or(v.user_id = (select auth.uid())), false),
    case when v_anonymous then null
         else array_remove(array_agg(pr.display_name order by v.created_at), null) end
  from public.poll_options o
  left join public.poll_votes v on v.option_id = o.id
  left join public.profiles pr on pr.id = v.user_id
  where o.poll_id = p_poll_id
  group by o.id, o.label, o.position
  order by o.position;
end;
$$;

-- Personal read markers. These run as the caller (RLS applies) and only
-- ever update the marker columns, so the caller needs no update right on
-- the keys.
create function public.mark_channel_read(p_channel_id bigint)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.channel_reads (team_id, channel_id, last_read_at)
  select c.team_id, c.id, now() from public.channels c where c.id = p_channel_id
  on conflict (user_id, channel_id) do update set last_read_at = excluded.last_read_at;
$$;

create function public.set_channel_muted(p_channel_id bigint, p_muted boolean)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.channel_reads (team_id, channel_id, muted)
  select c.team_id, c.id, p_muted from public.channels c where c.id = p_channel_id
  on conflict (user_id, channel_id) do update set muted = excluded.muted;
$$;

create function public.mark_announcements_seen(p_team_id bigint)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.announcement_seen (team_id, seen_at) values (p_team_id, now())
  on conflict (user_id, team_id) do update set seen_at = excluded.seen_at;
$$;

-- ---------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------
alter table public.channels enable row level security;
alter table public.channel_parts enable row level security;
alter table public.messages enable row level security;
alter table public.channel_reads enable row level security;
alter table public.announcement_seen enable row level security;
alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;

create policy "channels: read accessible ones" on public.channels for select to authenticated
  using (private.can_access_channel(id));
create policy "channels: leaders add part channels" on public.channels for insert to authenticated
  with check ((select private.is_leader(team_id)) and kind in ('team', 'parts') and created_by = (select auth.uid()));
create policy "channels: leaders edit" on public.channels for update to authenticated
  using ((select private.is_leader(team_id))) with check ((select private.is_leader(team_id)));
create policy "channels: leaders delete part channels" on public.channels for delete to authenticated
  using ((select private.is_leader(team_id)) and kind = 'parts');

create policy "channel_parts: members read" on public.channel_parts for select to authenticated
  using ((select private.is_member(team_id)));
create policy "channel_parts: leaders add" on public.channel_parts for insert to authenticated
  with check ((select private.is_leader(team_id)));
create policy "channel_parts: leaders delete" on public.channel_parts for delete to authenticated
  using ((select private.is_leader(team_id)));

create policy "messages: read in my channels" on public.messages for select to authenticated
  using (private.can_access_channel(channel_id));
create policy "messages: post in my open channels" on public.messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and private.can_access_channel(channel_id)
    and exists (select 1 from public.channels c where c.id = channel_id and c.archived_at is null)
  );
create policy "messages: edit or delete my own" on public.messages for update to authenticated
  using (sender_id = (select auth.uid())) with check (sender_id = (select auth.uid()));

create policy "channel_reads: own" on public.channel_reads for select to authenticated
  using (user_id = (select auth.uid()));
create policy "channel_reads: own add" on public.channel_reads for insert to authenticated
  with check (user_id = (select auth.uid()) and private.can_access_channel(channel_id));
create policy "channel_reads: own edit" on public.channel_reads for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "announcement_seen: own" on public.announcement_seen for select to authenticated
  using (user_id = (select auth.uid()));
create policy "announcement_seen: own add" on public.announcement_seen for insert to authenticated
  with check (user_id = (select auth.uid()) and (select private.is_member(team_id)));
create policy "announcement_seen: own edit" on public.announcement_seen for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "polls: read visible ones" on public.polls for select to authenticated
  using (private.can_see_poll(id));
create policy "poll_options: read visible ones" on public.poll_options for select to authenticated
  using (private.can_see_poll(poll_id));
-- votes: only your own rows; totals come from poll_results()
create policy "poll_votes: own" on public.poll_votes for select to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------
revoke all on table
  public.channels, public.channel_parts, public.messages, public.channel_reads,
  public.announcement_seen, public.polls, public.poll_options, public.poll_votes
from anon, authenticated, service_role;

grant select, insert, delete on public.channels to authenticated;
grant update (name, archived_at) on public.channels to authenticated;
grant select, insert, delete on public.channel_parts to authenticated;
grant select, insert on public.messages to authenticated;
grant update (body, edited_at, deleted_at) on public.messages to authenticated;
grant select, insert on public.channel_reads to authenticated;
grant update (last_read_at, muted) on public.channel_reads to authenticated;
grant select, insert on public.announcement_seen to authenticated;
grant update (seen_at) on public.announcement_seen to authenticated;
grant select on public.polls, public.poll_options, public.poll_votes to authenticated;

grant select, insert, update, delete on all tables in schema public to service_role;

revoke execute on function
  public.mark_channel_read(bigint),
  public.set_channel_muted(bigint, boolean),
  public.mark_announcements_seen(bigint),
  public.my_channels(bigint),
  public.create_poll(bigint, text, text[], bigint, bigint, boolean, boolean, timestamptz),
  public.poll_vote(bigint, bigint[]),
  public.poll_results(bigint)
from public, anon;

grant execute on function
  public.mark_channel_read(bigint),
  public.set_channel_muted(bigint, boolean),
  public.mark_announcements_seen(bigint),
  public.my_channels(bigint),
  public.create_poll(bigint, text, text[], bigint, bigint, boolean, boolean, timestamptz),
  public.poll_vote(bigint, bigint[]),
  public.poll_results(bigint)
to authenticated;

alter publication supabase_realtime add table public.messages;
