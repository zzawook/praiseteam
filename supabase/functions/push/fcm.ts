// Firebase Cloud Messaging HTTP v1 client (service-account auth).
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

export type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

export type FcmMessage = Record<string, unknown>;

/** sent: delivered to FCM. dead_token: token is gone, delete it. error: try again later. */
export type SendOutcome = "sent" | "dead_token" | "error";

export function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (parsed.project_id && parsed.client_email && parsed.private_key) {
      return parsed as ServiceAccount;
    }
  } catch {
    // fall through
  }
  console.error("FCM_SERVICE_ACCOUNT is set but is not a valid service account JSON");
  return null;
}

let cachedToken: { value: string; expiresAt: number } | null = null;

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;

  const key = await importPKCS8(sa.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`FCM token exchange failed: ${res.status}`);
  const json = await res.json();
  cachedToken = { value: json.access_token, expiresAt: now + (json.expires_in ?? 3600) };
  return cachedToken.value;
}

export async function send(sa: ServiceAccount, message: FcmMessage): Promise<SendOutcome> {
  try {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${await accessToken(sa)}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message }),
      },
    );
    if (res.ok) return "sent";

    const body = await res.json().catch(() => ({}));
    const details: Array<Record<string, unknown>> = body?.error?.details ?? [];
    const fcmCode = details.find((d) => String(d["@type"] ?? "").endsWith("FcmError"))
      ?.errorCode;
    if (res.status === 404 || fcmCode === "UNREGISTERED") return "dead_token";

    console.error("FCM send failed", res.status, fcmCode ?? body?.error?.status);
    return "error";
  } catch (e) {
    console.error("FCM send threw", e);
    return "error";
  }
}
