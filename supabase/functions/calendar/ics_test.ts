import { assert, assertEquals } from "jsr:@std/assert@1.0.8";
import { calendar, escapeText, fold } from "./ics.ts";

Deno.test("escapes text per RFC 5545", () => {
  assertEquals(escapeText("a,b;c\\d\ne"), "a\\,b\\;c\\\\d\\ne");
});

Deno.test("folds long lines at 75 octets without splitting characters", () => {
  const line = "SUMMARY:" + "주일 2부 예배 ".repeat(10);
  const folded = fold(line);
  for (const part of folded.split("\r\n")) {
    assert(new TextEncoder().encode(part).length <= 75, part);
  }
  assertEquals(folded.split("\r\n").map((p, i) => (i === 0 ? p : p.slice(1))).join(""), line);
});

Deno.test("one event per service, times in UTC", () => {
  const ics = calendar("PraiseTeam", [{
    uid: "service-1@praiseteam",
    start: new Date("2026-11-08T03:30:00Z"),
    end: new Date("2026-11-08T05:30:00Z"),
    summary: "[건반] 주일 2부",
    location: "본당",
  }], new Date("2026-11-01T00:00:00Z"));
  assert(ics.startsWith("BEGIN:VCALENDAR\r\n"));
  assert(ics.includes("DTSTART:20261108T033000Z\r\n"));
  assert(ics.includes("SUMMARY:[건반] 주일 2부\r\n"));
  assert(ics.includes("LOCATION:본당\r\n"));
  assertEquals(ics.match(/BEGIN:VEVENT/g)?.length, 1);
  assert(ics.endsWith("END:VCALENDAR\r\n"));
});
