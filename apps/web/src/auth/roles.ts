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
