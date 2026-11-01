// Calendar subscription feed: GET /functions/v1/calendar/<token>.ics
//
// The token is the secret in the URL (public.calendar_feeds); rotating it in
// the app revokes old URLs. Calendar apps can't send auth headers, so this
// function does not verify JWTs (see config.toml) and authorizes by token.
import postgres from "npm:postgres@3.4.4";
import { calendar, type CalendarEvent } from "./ics.ts";

const sql = postgres(Deno.env.get("SUPABASE_DB_URL")!, { prepare: false, max: 2, idle_timeout: 20 });

const SERVICE_HOURS = 2; // sessions have no end time; show two hours
const tokenPattern = /^[0-9a-f-]{36}$/i;

const statusText: Record<string, string> = { pending: "응답 대기 / Waiting for your answer", accepted: "수락 / Accepted" };

Deno.serve(async (req) => {
  if (req.method !== "GET") return new Response("Method Not Allowed", { status: 405 });
  const last = new URL(req.url).pathname.split("/").pop() ?? "";
  const token = last.replace(/\.ics$/, "");
  if (!tokenPattern.test(token)) return new Response("Not Found", { status: 404 });

  const [feed] = await sql`select user_id from public.calendar_feeds where token = ${token}::uuid`;
  if (!feed) return new Response("Not Found", { status: 404 });

  const services = await sql`
    select a.id, a.status, s.title, s.starts_at, s.location, p.name as part, t.name as team
    from public.assignments a
    join public.sessions s on s.id = a.session_id
    join public.parts p on p.id = a.part_id
    join public.teams t on t.id = a.team_id
    join public.team_members m on m.team_id = a.team_id and m.user_id = a.user_id and m.status = 'active'
    where a.user_id = ${feed.user_id} and a.status in ('pending', 'accepted')
      and s.starts_at > now() - interval '30 days'`;

  const rehearsals = await sql`
    select r.id, r.starts_at, r.ends_at, r.location, s.title as session_title, t.name as team
    from public.rehearsals r
    join public.team_members m on m.team_id = r.team_id and m.user_id = ${feed.user_id} and m.status = 'active'
    join public.teams t on t.id = r.team_id
    left join public.sessions s on s.id = r.session_id
    where r.starts_at > now() - interval '30 days'
      and (r.session_id is null or exists (
        select 1 from public.assignments a
        where a.session_id = r.session_id and a.user_id = ${feed.user_id} and a.status in ('pending', 'accepted')))
      and not exists (
        select 1 from public.rehearsal_responses rr
        where rr.rehearsal_id = r.id and rr.user_id = ${feed.user_id} and rr.rsvp = 'not_going')`;

  const events: CalendarEvent[] = [
    ...services.map((r) => {
      const start = new Date(r.starts_at);
      return {
        uid: `service-${r.id}@praiseteam`,
        start,
        end: new Date(start.getTime() + SERVICE_HOURS * 3600_000),
        summary: `[${r.part}] ${r.title}`,
        location: r.location,
        description: `${r.team}\n${statusText[r.status] ?? r.status}`,
      };
    }),
    ...rehearsals.map((r) => {
      const start = new Date(r.starts_at);
      return {
        uid: `rehearsal-${r.id}@praiseteam`,
        start,
        end: r.ends_at ? new Date(r.ends_at) : new Date(start.getTime() + 3600_000),
        summary: r.session_title ? `연습 / Rehearsal: ${r.session_title}` : "연습 / Rehearsal",
        location: r.location,
        description: r.team,
      };
    }),
  ];

  return new Response(calendar("PraiseTeam", events), {
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Cache-Control": "private, max-age=900",
    },
  });
});
