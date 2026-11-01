// Push texts per notification category and recipient locale.
// Producers put everything a text needs into `params` (see private.notify
// callers), so a notification renders without further lookups.

export type Locale = "ko" | "en";
export type Params = Record<string, unknown>;

type Template = {
  title: (p: Params) => string;
  body: (p: Params) => string;
};

const str = (v: unknown): string =>
  typeof v === "string" ? v : v == null ? "" : String(v);

const list = (v: unknown): string[] => (Array.isArray(v) ? v.map(str) : []);

type Summary = {
  added?: string[];
  removed?: string[];
  version_changed?: Array<{ title: string; from?: string | null; to?: string | null }>;
  key_changed?: Array<{ title: string; from: string | null; to: string | null }>;
  tempo_changed?: Array<{ title: string; from?: number | null; to?: number | null }>;
  reordered?: boolean;
};

/** "추가: A, B / 버전: C(마커스→어노인팅) / 키: C(G→A) / 템포: D(68→72) / 순서 변경" */
export function describeChanges(summary: Summary | undefined, locale: Locale): string {
  if (!summary) return "";
  const ko = locale === "ko";
  const parts: string[] = [];
  if (summary.added?.length) parts.push(`${ko ? "추가" : "Added"}: ${summary.added.join(", ")}`);
  if (summary.removed?.length) parts.push(`${ko ? "빠짐" : "Removed"}: ${summary.removed.join(", ")}`);
  if (summary.version_changed?.length) {
    const versions = summary.version_changed.map((v) => `${v.title}(${v.from ?? "?"}→${v.to ?? "?"})`);
    parts.push(`${ko ? "버전" : "Version"}: ${versions.join(", ")}`);
  }
  if (summary.key_changed?.length) {
    const keys = summary.key_changed.map((k) => `${k.title}(${k.from ?? "?"}→${k.to ?? "?"})`);
    parts.push(`${ko ? "키" : "Key"}: ${keys.join(", ")}`);
  }
  if (summary.tempo_changed?.length) {
    const tempos = summary.tempo_changed.map((t) => `${t.title}(${t.from ?? "?"}→${t.to ?? "?"})`);
    parts.push(`${ko ? "템포" : "Tempo"}: ${tempos.join(", ")}`);
  }
  if (summary.reordered) parts.push(ko ? "순서 변경" : "New order");
  return parts.join(" / ");
}

/** "11/8 19:30" in the team's time zone (params.timezone, IANA name). */
export const when = (iso: unknown, timeZone?: unknown): string => {
  const t = typeof iso === "string" ? new Date(iso) : null;
  if (!t || Number.isNaN(t.getTime())) return "";
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: typeof timeZone === "string" && timeZone ? timeZone : "Asia/Singapore",
    month: "numeric",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(t);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
  return `${Number(get("month"))}/${Number(get("day"))} ${get("hour")}:${get("minute")}`;
};

const serving = (ko: (s: string, part: string, p: Params) => string, en: (s: string, part: string, p: Params) => string): Record<Locale, Template> => ({
  ko: { title: (p) => ko(str(p.session_title), str(p.part_name), p), body: (p) => `${when(p.starts_at, p.timezone)} ${str(p.team_name)}`.trim() },
  en: { title: (p) => en(str(p.session_title), str(p.part_name), p), body: (p) => `${when(p.starts_at, p.timezone)} ${str(p.team_name)}`.trim() },
});

const templates: Record<string, Record<Locale, Template>> = {
  chat_message: {
    ko: {
      title: (p) => str(p.channel_name),
      body: (p) => `${str(p.sender_name)}: ${p.is_poll ? "투표 " : ""}${str(p.preview)}`,
    },
    en: {
      title: (p) => str(p.channel_name),
      body: (p) => `${str(p.sender_name)}: ${p.is_poll ? "Poll " : ""}${str(p.preview)}`,
    },
  },
  announcement: {
    ko: { title: (p) => `공지: ${str(p.title)}`, body: (p) => str(p.preview) },
    en: { title: (p) => `Announcement: ${str(p.title)}`, body: (p) => str(p.preview) },
  },
  assignment_requested: serving((s, part) => `${s} ${part} 섬김 요청`, (s, part) => `${s}: can you serve on ${part}?`),
  assignment_removed: serving((s, part) => `${s} ${part} 섬김에서 빠졌어요`, (s, part) => `You're off ${part} for ${s}`),
  assignment_nudge: serving((s, part) => `${s} ${part} 요청에 아직 답하지 않았어요`, (s, part) => `Still waiting on you: ${part} for ${s}`),
  service_reminder: serving((s, part) => `내일 ${s} ${part} 섬김이 있어요`, (s, part) => `Tomorrow: ${part} for ${s}`),
  assignment_declined: serving(
    (s, part, p) => `${str(p.user_name)}님이 ${s} ${part} 섬김을 거절했어요`,
    (s, part, p) => `${str(p.user_name)} declined ${part} for ${s}`,
  ),
  swap_requested: serving(
    (s, part, p) => `${str(p.user_name)}님이 ${s} ${part} 대타를 구해요`,
    (s, part, p) => `${str(p.user_name)} needs a sub: ${part} for ${s}`,
  ),
  swap_filled: serving(
    (s, part, p) => `${str(p.user_name)}님이 ${s} ${part}을(를) 맡았어요`,
    (s, part, p) => `${str(p.user_name)} took ${part} for ${s}`,
  ),
  rehearsal_scheduled: {
    ko: { title: (p) => `연습 일정: ${when(p.starts_at, p.timezone)}`, body: (p) => [str(p.session_title), str(p.location)].filter(Boolean).join(" ") },
    en: { title: (p) => `Rehearsal: ${when(p.starts_at, p.timezone)}`, body: (p) => [str(p.session_title), str(p.location)].filter(Boolean).join(" ") },
  },
  rehearsal_reminder: {
    ko: { title: (p) => `곧 연습이에요: ${when(p.starts_at, p.timezone)}`, body: (p) => str(p.location) },
    en: { title: (p) => `Rehearsal soon: ${when(p.starts_at, p.timezone)}`, body: (p) => str(p.location) },
  },
  setlist_published: {
    ko: {
      title: (p) => `${str(p.session_title)} 콘티`,
      body: (p) => list(p.songs).join(", "),
    },
    en: {
      title: (p) => `Setlist: ${str(p.session_title)}`,
      body: (p) => list(p.songs).join(", "),
    },
  },
  setlist_updated: {
    ko: {
      title: (p) => `${str(p.session_title)} 콘티가 바뀌었어요`,
      body: (p) => describeChanges(p.summary as Summary, "ko"),
    },
    en: {
      title: (p) => `Setlist changed: ${str(p.session_title)}`,
      body: (p) => describeChanges(p.summary as Summary, "en"),
    },
  },
  member_join_request: {
    ko: {
      title: () => "가입 요청",
      body: (p) => `${str(p.user_name)}님이 ${str(p.team_name)}에 가입을 요청했어요.`,
    },
    en: {
      title: () => "Join request",
      body: (p) => `${str(p.user_name)} asked to join ${str(p.team_name)}.`,
    },
  },
  member_approved: {
    ko: {
      title: () => "가입 승인",
      body: (p) => `${str(p.team_name)}에 가입됐어요.`,
    },
    en: {
      title: () => "You're in",
      body: (p) => `You joined ${str(p.team_name)}.`,
    },
  },
};

const fallback: Record<Locale, Template> = {
  ko: { title: () => "PraiseTeam", body: () => "새 알림이 있어요." },
  en: { title: () => "PraiseTeam", body: () => "You have a new notification." },
};

export function toLocale(value: string | null | undefined): Locale {
  return value === "en" ? "en" : "ko";
}

export function render(category: string, locale: string, params: Params) {
  const loc = toLocale(locale);
  const template = templates[category]?.[loc] ?? fallback[loc];
  return { title: template.title(params), body: template.body(params) };
}
