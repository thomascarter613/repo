#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
WEB_DIR="${ROOT_DIR}/apps/web"
CONFIG_DIR="${ROOT_DIR}/packages/config"

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

append_if_missing() {
  local file="$1"
  local text="$2"

  touch "$file"
  if ! grep -Fq "$text" "$file"; then
    printf "%s\n" "$text" >> "$file"
  fi
}

patch_web_package_json() {
  node <<'EOF'
const fs = require('fs');
const path = require('path');

const file = path.resolve('apps/web/package.json');
const json = JSON.parse(fs.readFileSync(file, 'utf8'));

json.dependencies ||= {};

const wantedDeps = {
  "@repo/config": "workspace:*"
};

for (const [name, version] of Object.entries(wantedDeps)) {
  json.dependencies[name] = json.dependencies[name] || version;
}

fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n');
EOF
}

patch_root_env_example() {
  if [ ! -f ".env.example" ]; then
    cat > .env.example <<'EOF'
PORT=3001
DATABASE_URL=postgres://app:app@localhost:5432/app

KEYCLOAK_BASE_URL=http://localhost:8080
KEYCLOAK_REALM=myrealm
KEYCLOAK_CLIENT_ID=web
KEYCLOAK_CLIENT_SECRET=replace-me
KEYCLOAK_REDIRECT_URI=http://localhost:3000/auth/callback
WEB_SESSION_SECRET=replace-with-a-long-random-secret-change-me
EOF
    return
  fi

  append_if_missing ".env.example" "KEYCLOAK_BASE_URL=http://localhost:8080"
  append_if_missing ".env.example" "KEYCLOAK_REALM=myrealm"
  append_if_missing ".env.example" "KEYCLOAK_CLIENT_ID=web"
  append_if_missing ".env.example" "KEYCLOAK_CLIENT_SECRET=replace-me"
  append_if_missing ".env.example" "KEYCLOAK_REDIRECT_URI=http://localhost:3000/auth/callback"
  append_if_missing ".env.example" "WEB_SESSION_SECRET=replace-with-a-long-random-secret-change-me"
}

patch_config_env_schema() {
  local file="${CONFIG_DIR}/src/index.ts"
  if [ ! -f "$file" ]; then
    echo "Error: expected config env file at ${file}"
    exit 1
  fi

  cat > "$file" <<'EOF'
import { z } from "zod";

const EnvSchema = z.object({
  PORT: z.coerce.number().default(3001),
  KEYCLOAK_BASE_URL: z.string().url().default("http://localhost:8080"),
  KEYCLOAK_REALM: z.string().min(1).default("myrealm"),
  KEYCLOAK_CLIENT_ID: z.string().min(1).default("web"),
  KEYCLOAK_CLIENT_SECRET: z.string().min(1).default("replace-me"),
  KEYCLOAK_REDIRECT_URI: z.string().url().default("http://localhost:3000/auth/callback"),
  WEB_SESSION_SECRET: z.string().min(32).default("replace-with-a-long-random-secret-change-me")
});

export const env = EnvSchema.parse({
  PORT: process.env.PORT,
  KEYCLOAK_BASE_URL: process.env.KEYCLOAK_BASE_URL,
  KEYCLOAK_REALM: process.env.KEYCLOAK_REALM,
  KEYCLOAK_CLIENT_ID: process.env.KEYCLOAK_CLIENT_ID,
  KEYCLOAK_CLIENT_SECRET: process.env.KEYCLOAK_CLIENT_SECRET,
  KEYCLOAK_REDIRECT_URI: process.env.KEYCLOAK_REDIRECT_URI,
  WEB_SESSION_SECRET: process.env.WEB_SESSION_SECRET
});
EOF
}

main() {
  require_file "${WEB_DIR}/package.json"
  require_file "${WEB_DIR}/src/routes/__root.tsx"
  require_file "${WEB_DIR}/src/routes/index.tsx"
  require_file "${CONFIG_DIR}/src/index.ts"

  ensure_dir "${WEB_DIR}/src/auth"
  ensure_dir "${WEB_DIR}/src/routes/auth"
  ensure_dir "${WEB_DIR}/src/routes/_app"
  ensure_dir "${WEB_DIR}/src/components/auth"

  patch_web_package_json
  patch_root_env_example
  patch_config_env_schema

  replace_file_if_different "${WEB_DIR}/src/auth/roles.ts" <<'EOF'
export type AppRole =
  | "admin"
  | "editor"
  | "member"
  | "associate"
  | "public";

export function normalizeRoles(input: unknown): AppRole[] {
  if (!Array.isArray(input)) return ["public"];

  const allowed = new Set<AppRole>(["admin", "editor", "member", "associate", "public"]);
  const normalized = input.filter((value): value is AppRole => {
    return typeof value === "string" && allowed.has(value as AppRole);
  });

  return normalized.length > 0 ? normalized : ["public"];
}
EOF

  replace_file_if_different "${WEB_DIR}/src/auth/session.server.ts" <<'EOF'
import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { env } from "@repo/config";

export type UserSession = {
  sub: string;
  email?: string;
  name?: string;
  preferredUsername?: string;
  roles: string[];
};

const SESSION_COOKIE = "web_session";
const STATE_COOKIE = "web_oauth_state";

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

export function encodeSessionCookie(session: UserSession) {
  const payload = base64UrlEncode(JSON.stringify(session));
  const signature = sign(payload);

  return `${SESSION_COOKIE}=${payload}.${signature}; ${cookieFlags(28800)}`;
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
    return JSON.parse(base64UrlDecode(payload)) as UserSession;
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

  return {
    sub: parsed.sub,
    email: parsed.email,
    name: parsed.name,
    preferredUsername: parsed.preferred_username,
    roles: parsed.realm_access?.roles ?? []
  };
}

export function getPostLogoutRedirectUrl() {
  return new URL("/", env.KEYCLOAK_REDIRECT_URI).toString();
}

export function getLogoutUrl(idTokenHint?: string) {
  const url = new URL(`${getOidcBase()}/logout`);
  url.searchParams.set("post_logout_redirect_uri", getPostLogoutRedirectUrl());
  if (idTokenHint) {
    url.searchParams.set("id_token_hint", idTokenHint);
  }
  return url.toString();
}
EOF

  replace_file_if_different "${WEB_DIR}/src/auth/user.server.ts" <<'EOF'
import { readSessionFromCookieHeader } from "./session.server";
import { normalizeRoles } from "./roles";

export function getSessionFromRequest(request: Request) {
  const session = readSessionFromCookieHeader(request.headers.get("cookie"));

  if (!session) return null;

  return {
    ...session,
    roles: normalizeRoles(session.roles)
  };
}
EOF

  replace_file_if_different "${WEB_DIR}/src/auth/guards.server.ts" <<'EOF'
import { redirect } from "@tanstack/solid-router";
import { getSessionFromRequest } from "./user.server";

export function requireSession(request: Request) {
  const session = getSessionFromRequest(request);

  if (!session) {
    throw redirect({
      to: "/login"
    });
  }

  return session;
}

export function requireRole(request: Request, role: string) {
  const session = requireSession(request);

  if (!session.roles.includes(role as never)) {
    throw redirect({
      to: "/"
    });
  }

  return session;
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/login.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";
import { AppShell } from "../components/layout/app-shell";
import { Button } from "../components/ui/button";

export const Route = createFileRoute("/login")({
  component: LoginPage
});

function LoginPage() {
  return (
    <AppShell>
      <main class="mx-auto max-w-xl py-16">
        <div class="rounded-3xl border border-border bg-card p-8 shadow-2xl">
          <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">
            Authentication
          </p>
          <h1 class="mt-3 text-3xl font-semibold tracking-tight">
            Sign in
          </h1>
          <p class="mt-4 text-base leading-7 text-muted-foreground">
            Continue with Keycloak using the server-managed authentication flow.
          </p>
          <div class="mt-8">
            <a href="/auth/login">
              <Button type="button">Continue to sign in</Button>
            </a>
          </div>
        </div>
      </main>
    </AppShell>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/auth.login.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";
import { createStateValue, encodeStateCookie } from "../auth/session.server";
import { getAuthorizationUrl } from "../auth/keycloak.server";

export const Route = createFileRoute("/auth/login")({
  server: {
    handlers: {
      GET: async () => {
        const state = createStateValue();

        return new Response(null, {
          status: 302,
          headers: {
            Location: getAuthorizationUrl(state),
            "Set-Cookie": encodeStateCookie(state)
          }
        });
      }
    }
  }
});
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/auth.callback.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";
import { exchangeCodeForTokens, mapIdTokenToSession } from "../auth/keycloak.server";
import {
  clearStateCookie,
  encodeSessionCookie,
  readStateFromCookieHeader,
  statesMatch
} from "../auth/session.server";

export const Route = createFileRoute("/auth/callback")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const url = new URL(request.url);
        const code = url.searchParams.get("code");
        const state = url.searchParams.get("state");
        const cookieState = readStateFromCookieHeader(request.headers.get("cookie"));

        if (!code) {
          return new Response("Missing authorization code.", { status: 400 });
        }

        if (!statesMatch(cookieState, state)) {
          return new Response("Invalid OAuth state.", {
            status: 400,
            headers: {
              "Set-Cookie": clearStateCookie()
            }
          });
        }

        const tokens = await exchangeCodeForTokens(code);

        if (!tokens.id_token) {
          return new Response("Missing id_token from Keycloak token response.", {
            status: 500,
            headers: {
              "Set-Cookie": clearStateCookie()
            }
          });
        }

        const session = mapIdTokenToSession(tokens.id_token);

        return new Response(null, {
          status: 302,
          headers: {
            Location: "/app",
            "Set-Cookie": [
              clearStateCookie(),
              encodeSessionCookie(session)
            ].join(", ")
          }
        });
      }
    }
  }
});
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/auth.logout.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";
import { clearSessionCookie, clearStateCookie } from "../auth/session.server";

export const Route = createFileRoute("/auth/logout")({
  server: {
    handlers: {
      GET: async () => {
        return new Response(null, {
          status: 302,
          headers: {
            Location: "/",
            "Set-Cookie": [
              clearSessionCookie(),
              clearStateCookie()
            ].join(", ")
          }
        });
      }
    }
  }
});
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/_app.tsx" <<'EOF'
import { Outlet, createFileRoute } from "@tanstack/solid-router";
import { requireSession } from "../auth/guards.server";
import { AppShell } from "../components/layout/app-shell";

export const Route = createFileRoute("/_app")({
  beforeLoad: ({ location, cause, context, params, preload, abortController, matches, search, navigate, buildLocation }) => {
    const request = new Request(location.href, {
      headers: typeof document === "undefined" ? undefined : undefined
    });
    const session = requireSession(request);
    return { session };
  },
  component: ProtectedAppLayout
});

function ProtectedAppLayout() {
  return (
    <AppShell>
      <Outlet />
    </AppShell>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/_app.index.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";

export const Route = createFileRoute("/_app/")({
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
          This route is protected by a server-side session check before it renders.
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
  return "Full-stack web foundation with server-managed Keycloak auth.";
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
              The web app now has a protected route subtree, server-side session handling,
              and a Keycloak callback boundary.
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
              <p class="text-sm font-medium text-card-foreground">Auth status</p>
              <ul class="space-y-2 text-sm text-muted-foreground">
                <li>• Keycloak redirect route added</li>
                <li>• callback route exchanges code for tokens</li>
                <li>• OAuth state is validated</li>
                <li>• protected route subtree is in place</li>
              </ul>
              <div class="pt-3">
                <AppDialog
                  trigger={
                    <Button variant="ghost" type="button">
                      Open auth note
                    </Button>
                  }
                  title="Server-managed auth is in place"
                  description="The browser app is no longer the primary token manager."
                >
                  <p class="text-sm text-muted-foreground">
                    Next hardening steps include server-side session storage, nonce handling,
                    refresh policy, and stronger role mapping.
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

  echo "Corrected Keycloak BFF auth layer applied to apps/web."
  echo
  echo "Next steps:"
  echo "  1. bun install"
  echo "  2. set KEYCLOAK_* and WEB_SESSION_SECRET in .env"
  echo "  3. bun run --filter @repo/web dev"
  echo
  echo "Still recommended soon:"
  echo "  - replace signed cookie payload with server-side session storage"
  echo "  - add nonce handling"
  echo "  - add refresh/session expiry strategy"
  echo "  - refine role mapping"
}

main "$@"