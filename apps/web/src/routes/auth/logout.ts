import { createFileRoute } from "@tanstack/solid-router";
import { clearSessionCookie, clearStateCookie } from "../../auth/session.server";

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
              clearStateCookie(),
            ].join(", "),
          },
        });
      },
    },
  },
});