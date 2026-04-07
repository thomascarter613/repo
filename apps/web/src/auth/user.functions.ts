import { createServerFn } from "@tanstack/solid-start";
import { getRequest } from "@tanstack/solid-start/server";
import { getSessionFromRequest } from "./user.server";

export const fetchCurrentSession = createServerFn({ method: "GET" }).handler(async () => {
  const request = getRequest();

  if (!request) return null;

  return getSessionFromRequest(request);
});
