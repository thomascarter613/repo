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
