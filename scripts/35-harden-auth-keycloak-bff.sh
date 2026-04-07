#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
WEB_DIR="${ROOT_DIR}/apps/web"

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Error: required file not found: $file"
    exit 1
  fi
}

ensure_dir() {
  mkdir -p "$1"
}

replace_file_if_different() {
  local target="$1"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"

  if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
    rm -f "$tmp"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  mv "$tmp" "$target"
}

main() {
  require_file "${WEB_DIR}/src/auth/session.server.ts"
  require_file "${WEB_DIR}/src/auth/user.server.ts"
  require_file "${WEB_DIR}/src/routes/index.tsx"

  ensure_dir "${WEB_DIR}/src/auth"
  ensure_dir "${WEB_DIR}/src/routes"
  ensure_dir "${WEB_DIR}/src/routes/app"
  ensure_dir "${WEB_DIR}/src/components/auth"

  replace_file_if_different "${WEB_DIR}/src/auth/session.server.ts" <<'EOF'
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
EOF

  replace_file_if_different "${WEB_DIR}/src/auth/keycloak.server.ts" <<'EOF'
import { env } from "@repo/config";
import { buildSession } from "./session.server";

type TokenResponse = {
  access_token: string;
  id_token?: string;
  refresh_token?: string;
  token_type: string;
  expires_in: number;
};

type ParsedIdToken = {
  sub: string;
  email?: string;
  name?: string;
  preferred_username?: string;
  realm_access?: {
    roles?: string[];
  };
};

function getOidcBase() {
  return `${env.KEYCLOAK_BASE_URL}/realms/${env.KEYCLOAK_REALM}/protocol/openid-connect`;
}

export function getAuthorizationUrl(state: string) {
  const url = new URL(`${getOidcBase()}/auth`);
  url.searchParams.set("client_id", env.KEYCLOAK_CLIENT_ID);
  url.searchParams.set("redirect_uri", env.KEYCLOAK_REDIRECT_URI);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "openid profile email");
  url.searchParams.set("state", state);
  return url.toString();
}

export async function exchangeCodeForTokens(code: string) {
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: env.KEYCLOAK_CLIENT_ID,
    client_secret: env.KEYCLOAK_CLIENT_SECRET,
    code,
    redirect_uri: env.KEYCLOAK_REDIRECT_URI
  });

  const response = await fetch(`${getOidcBase()}/token`, {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded"
    },
    body
  });

  if (!response.ok) {
    throw new Error("Failed to exchange authorization code with Keycloak.");
  }

  return (await response.json()) as TokenResponse;
}

export function decodeJwtPayload<T>(jwt: string): T {
  const [, payload] = jwt.split(".");
  if (!payload) {
    throw new Error("Invalid JWT payload.");
  }

  return JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as T;
}

export function mapIdTokenToSession(idToken: string) {
  const parsed = decodeJwtPayload<ParsedIdToken>(idToken);

  return buildSession({
    sub: parsed.sub,
    email: parsed.email,
    name: parsed.name,
    preferredUsername: parsed.preferred_username,
    roles: parsed.realm_access?.roles ?? []
  });
}
EOF

  replace_file_if_different "${WEB_DIR}/src/auth/user.server.ts" <<'EOF'
import { normalizeRoles } from "./roles";
import { readSessionFromCookieHeader } from "./session.server";

export function getSessionFromRequest(request: Request) {
  const session = readSessionFromCookieHeader(request.headers.get("cookie"));

  if (!session) return null;

  return {
    ...session,
    roles: normalizeRoles(session.roles)
  };
}
EOF

  replace_file_if_different "${WEB_DIR}/src/auth/user.functions.ts" <<'EOF'
import { createServerFn } from "@tanstack/solid-start";
import { getWebRequest } from "@tanstack/solid-start/server";
import { getSessionFromRequest } from "./user.server";

export const fetchCurrentSession = createServerFn({ method: "GET" }).handler(async () => {
  const request = getWebRequest();

  if (!request) return null;

  return getSessionFromRequest(request);
});
EOF

  replace_file_if_different "${WEB_DIR}/src/components/auth/protected-shell.tsx" <<'EOF'
import type { JSX } from "solid-js";
import { AppShell } from "../layout/app-shell";

export function ProtectedShell(props: { children: JSX.Element }) {
  return <AppShell>{props.children}</AppShell>;
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/app.tsx" <<'EOF'
import { Outlet, createFileRoute, redirect } from "@tanstack/solid-router";
import { fetchCurrentSession } from "../auth/user.functions";
import { ProtectedShell } from "../components/auth/protected-shell";

export const Route = createFileRoute("/app")({
  beforeLoad: async () => {
    const session = await fetchCurrentSession();

    if (!session) {
      throw redirect({
        to: "/login"
      });
    }

    return { session };
  },
  component: AppLayout
});

function AppLayout() {
  return (
    <ProtectedShell>
      <Outlet />
    </ProtectedShell>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/app.index.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";

export const Route = createFileRoute("/app/")({
  component: AppHome
});

function AppHome() {
  const context = Route.useRouteContext();

  return (
    <main class="py-8">
      <div class="rounded-3xl border border-border bg-card p-8 shadow-2xl">
        <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">
          Protected Area
        </p>
        <h1 class="mt-3 text-3xl font-semibold tracking-tight">
          Signed-in application area
        </h1>
        <p class="mt-4 text-base leading-7 text-muted-foreground">
          This route is protected by a server-side session lookup before it renders.
        </p>

        <dl class="mt-8 grid gap-4 sm:grid-cols-2">
          <div class="rounded-2xl border border-border bg-background p-4">
            <dt class="text-sm text-muted-foreground">Subject</dt>
            <dd class="mt-2 text-sm font-medium">{context().session.sub}</dd>
          </div>
          <div class="rounded-2xl border border-border bg-background p-4">
            <dt class="text-sm text-muted-foreground">Roles</dt>
            <dd class="mt-2 text-sm font-medium">{context().session.roles.join(", ")}</dd>
          </div>
          <div class="rounded-2xl border border-border bg-background p-4">
            <dt class="text-sm text-muted-foreground">Email</dt>
            <dd class="mt-2 text-sm font-medium">{context().session.email ?? "—"}</dd>
          </div>
          <div class="rounded-2xl border border-border bg-background p-4">
            <dt class="text-sm text-muted-foreground">Expires</dt>
            <dd class="mt-2 text-sm font-medium">
              {new Date(context().session.expiresAt).toLocaleString()}
            </dd>
          </div>
        </dl>

        <div class="mt-8">
          <a
            class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-card px-4 text-sm font-medium text-card-foreground transition hover:bg-accent hover:text-accent-foreground"
            href="/auth/logout"
          >
            Sign out
          </a>
        </div>
      </div>
    </main>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/index.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";
import { createServerFn } from "@tanstack/solid-start";
import { AppShell } from "../components/layout/app-shell";
import { Button } from "../components/ui/button";
import { AppDialog } from "../components/ui/dialog";

const getGreeting = createServerFn({ method: "GET" }).handler(async () => {
  return "Full-stack web foundation with hardened server-managed Keycloak auth.";
});

export const Route = createFileRoute("/")({
  loader: () => getGreeting(),
  component: HomePage
});

function HomePage() {
  const greeting = Route.useLoaderData();

  return (
    <AppShell>
      <main class="flex flex-col gap-10 py-8">
        <section class="grid gap-6 lg:grid-cols-[1.4fr_0.8fr] lg:items-center">
          <div class="space-y-5">
            <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">
              TanStack Start + Solid
            </p>
            <h1 class="max-w-3xl text-4xl font-semibold tracking-tight sm:text-5xl">
              {greeting()}
            </h1>
            <p class="max-w-2xl text-base leading-7 text-muted-foreground">
              The auth layer now reads session state through a server function,
              validates callback state, and enforces session expiry.
            </p>
            <div class="flex flex-wrap items-center gap-3">
              <a href="/login">
                <Button type="button">Sign in</Button>
              </a>
              <a
                class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-card px-4 text-sm font-medium text-card-foreground transition hover:bg-accent hover:text-accent-foreground"
                href="/app"
              >
                Open protected app
              </a>
            </div>
          </div>

          <div class="rounded-3xl border border-border bg-card p-6 shadow-2xl">
            <div class="space-y-3">
              <p class="text-sm font-medium text-card-foreground">Auth hardening status</p>
              <ul class="space-y-2 text-sm text-muted-foreground">
                <li>• auth endpoints remain server routes</li>
                <li>• session lookup moved behind a server function</li>
                <li>• protected subtree uses beforeLoad with server-backed auth state</li>
                <li>• session expiry is enforced</li>
              </ul>
              <div class="pt-3">
                <AppDialog
                  trigger={
                    <Button variant="ghost" type="button">
                      Open hardening note
                    </Button>
                  }
                  title="Auth boundary improved"
                  description="This removes the brittle request-fabrication pattern from the protected route tree."
                >
                  <p class="text-sm text-muted-foreground">
                    The next upgrade is replacing signed cookie payload sessions with opaque
                    server-side sessions backed by a database or store.
                  </p>
                </AppDialog>
              </div>
            </div>
          </div>
        </section>
      </main>
    </AppShell>
  );
}
EOF

  rm -rf "${WEB_DIR}/src/routes/_app.tsx" \
         "${WEB_DIR}/src/routes/_app.index.tsx" \
         "${WEB_DIR}/src/auth/guards.server.ts"

  echo "Auth hardening layer applied to apps/web."
  echo
  echo "Next steps:"
  echo "  1. rm -rf apps/web/.vinxi apps/web/.output apps/web/node_modules/.vite"
  echo "  2. bun run --filter @repo/web dev"
  echo
  echo "Next recommended layer:"
  echo "  - opaque server-side sessions"
  echo "  - refresh / renewal policy"
  echo "  - nonce handling"
  echo "  - deeper role/permission mapping"
}

main "$@"