import { createFileRoute } from "@tanstack/solid-router";
import { exchangeCodeForTokens, mapIdTokenToSession } from "../../auth/keycloak.server";
import {
  clearStateCookie,
  encodeSessionCookie,
  readStateFromCookieHeader,
  statesMatch,
} from "../../auth/session.server";

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
              "Set-Cookie": clearStateCookie(),
            },
          });
        }

        const tokens = await exchangeCodeForTokens(code);

        if (!tokens.id_token) {
          return new Response("Missing id_token from Keycloak token response.", {
            status: 500,
            headers: {
              "Set-Cookie": clearStateCookie(),
            },
          });
        }

        const session = mapIdTokenToSession(tokens.id_token);

        return new Response(null, {
          status: 302,
          headers: {
            Location: "/app",
            "Set-Cookie": [
              clearStateCookie(),
              encodeSessionCookie(session),
            ].join(", "),
          },
        });
      },
    },
  },
});