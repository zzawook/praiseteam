// Calendar texts in the subscriber's app language (profiles.locale, kept in
// step with the language the app shows).
export type Locale = "ko" | "en";

export const toLocale = (value: unknown): Locale => (value === "en" ? "en" : "ko");

const texts = {
  ko: { rehearsal: "연습", pending: "응답 대기", accepted: "수락함" },
  en: { rehearsal: "Rehearsal", pending: "Waiting for your answer", accepted: "Accepted" },
} as const;

export function rehearsalTitle(locale: Locale, sessionTitle?: string | null): string {
  const word = texts[locale].rehearsal;
  return sessionTitle ? `${word}: ${sessionTitle}` : word;
}

export function assignmentStatus(locale: Locale, status: string): string {
  return status === "pending" || status === "accepted" ? texts[locale][status] : status;
}
