import { createFileRoute } from "@tanstack/solid-router";
import { createStateValue, encodeStateCookie } from "../../auth/session.server";
import { getAuthorizationUrl } from "../../auth/keycloak.server";

export const Route = createFileRoute("/auth/login")({
  server: {
    handlers: {
      GET: async () => {
        const state = createStateValue();

        return new Response(null, {
          status: 302,
          headers: {
            Location: getAuthorizationUrl(state),
            "Set-Cookie": encodeStateCookie(state),
          },
        });
      },
    },
  },
});