import { assertEquals } from "jsr:@std/assert@1.0.8";
import { assignmentStatus, rehearsalTitle, toLocale } from "./texts.ts";

Deno.test("calendar texts follow the subscriber's language", () => {
  assertEquals(rehearsalTitle("ko", "주일 2부 예배"), "연습: 주일 2부 예배");
  assertEquals(rehearsalTitle("en", "주일 2부 예배"), "Rehearsal: 주일 2부 예배");
  assertEquals(rehearsalTitle("ko", null), "연습");
  assertEquals(assignmentStatus("ko", "pending"), "응답 대기");
  assertEquals(assignmentStatus("en", "accepted"), "Accepted");
});

Deno.test("anything but English means Korean", () => {
  assertEquals(toLocale("en"), "en");
  assertEquals(toLocale("ko"), "ko");
  assertEquals(toLocale(null), "ko");
});
