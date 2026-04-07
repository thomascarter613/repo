import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { env } from "@repo/config";

export type UserSession = {
  sub: string;
  email?: string;
  name?: string;
  preferredUsername?: string;
  roles: string[];
  expiresAt: number;
};

const SESSION_COOKIE = "web_session";
const STATE_COOKIE = "web_oauth_state";
const SESSION_MAX_AGE_SECONDS = 60 * 60 * 8;

function base64UrlEncode(input: string) {
  return Buffer.from(input, "utf8").toString("base64url");
}

function base64UrlDecode(input: string) {
  return Buffer.from(input, "base64url").toString("utf8");
}

function sign(value: string) {
  return createHmac("sha256", env.WEB_SESSION_SECRET).update(value).digest("base64url");
}

function parseCookieHeader(cookieHeader: string | null) {
  const result: Record<string, string> = {};
  if (!cookieHeader) return result;

  for (const item of cookieHeader.split(";")) {
    const [rawKey, ...rest] = item.trim().split("=");
    result[rawKey] = rest.join("=");
  }

  return result;
}

function isSecure() {
  return process.env.NODE_ENV === "production";
}

function cookieFlags(maxAge: number) {
  const secure = isSecure() ? "; Secure" : "";
  return `Path=/; HttpOnly; SameSite=Lax${secure}; Max-Age=${maxAge}`;
}

export function createStateValue() {
  return randomBytes(32).toString("base64url");
}

export function encodeStateCookie(state: string) {
  return `${STATE_COOKIE}=${state}; ${cookieFlags(600)}`;
}

export function clearStateCookie() {
  return `${STATE_COOKIE}=; ${cookieFlags(0)}`;
}

export function readStateFromCookieHeader(cookieHeader: string | null) {
  const cookies = parseCookieHeader(cookieHeader);
  return cookies[STATE_COOKIE] ?? null;
}

export function buildSession(input: {
  sub: string;
  email?: string;
  name?: string;
  preferredUsername?: string;
  roles: string[];
}): UserSession {
  return {
    ...input,
    expiresAt: Date.now() + SESSION_MAX_AGE_SECONDS * 1000
  };
}

export function encodeSessionCookie(session: UserSession) {
  const payload = base64UrlEncode(JSON.stringify(session));
  const signature = sign(payload);

  return `${SESSION_COOKIE}=${payload}.${signature}; ${cookieFlags(SESSION_MAX_AGE_SECONDS)}`;
}

export function clearSessionCookie() {
  return `${SESSION_COOKIE}=; ${cookieFlags(0)}`;
}

export function readSessionFromCookieHeader(cookieHeader: string | null): UserSession | null {
  const cookies = parseCookieHeader(cookieHeader);
  const raw = cookies[SESSION_COOKIE];
  if (!raw) return null;

  const [payload, signature] = raw.split(".");
  if (!payload || !signature) return null;

  const expected = sign(payload);
  const a = Buffer.from(signature);
  const b = Buffer.from(expected);

  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    return null;
  }

  try {
    const session = JSON.parse(base64UrlDecode(payload)) as UserSession;

    if (!session.expiresAt || Date.now() > session.expiresAt) {
      return null;
    }

    return session;
  } catch {
    return null;
  }
}

export function statesMatch(cookieState: string | null, callbackState: string | null) {
  if (!cookieState || !callbackState) return false;
  const a = Buffer.from(cookieState);
  const b = Buffer.from(callbackState);

  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}
