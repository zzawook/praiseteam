import { assertEquals } from "jsr:@std/assert@1.0.8";
import { describeChanges, render, when } from "./messages.ts";

Deno.test("times are shown in the team's time zone", () => {
  // 2026-11-08 03:30 UTC = 11:30 in Singapore, 12:30 in Seoul
  assertEquals(when("2026-11-08T03:30:00Z", "Asia/Singapore"), "11/8 11:30");
  assertEquals(when("2026-11-08T03:30:00Z", "Asia/Seoul"), "11/8 12:30");
  assertEquals(when("not a date", "Asia/Seoul"), "");
});

Deno.test("assignment request in Korean and English", () => {
  const params = {
    session_title: "주일 2부",
    part_name: "건반",
    starts_at: "2026-11-08T03:30:00Z",
    team_name: "청년부",
    timezone: "Asia/Singapore",
  };
  assertEquals(render("assignment_requested", "ko", params), { title: "주일 2부 건반 섬김 요청", body: "11/8 11:30 청년부" });
  assertEquals(render("assignment_requested", "en", params).title, "주일 2부: can you serve on 건반?");
});

Deno.test("setlist change summary", () => {
  assertEquals(
    describeChanges({ added: ["은혜"], key_changed: [{ title: "주의 집", from: "G", to: "A" }], reordered: true }, "ko"),
    "추가: 은혜 / 키: 주의 집(G→A) / 순서 변경",
  );
  assertEquals(describeChanges({}, "en"), "");
});

Deno.test("unknown categories fall back instead of failing", () => {
  assertEquals(render("something_new", "en", {}).title, "PraiseTeam");
});
