import { Outlet, createFileRoute, redirect, Link } from "@tanstack/solid-router";
import { fetchCurrentSession } from "../auth/user.functions";
import { ProtectedShell } from "../components/auth/protected-shell";

export const Route = createFileRoute("/app")({
  beforeLoad: async () => {
    const session = await fetchCurrentSession();

    if (!session) {
      throw redirect({
        to: "/login",
      });
    }

    return { session };
  },
  component: AppLayout,
  notFoundComponent: AppNotFound,
});

function AppLayout() {
  return (
    <ProtectedShell>
      <Outlet />
    </ProtectedShell>
  );
}

function AppNotFound() {
  return (
    <ProtectedShell>
      <main class="py-8">
        <div class="rounded-3xl border border-border bg-card p-8 shadow-2xl">
          <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">
            App section
          </p>
          <h1 class="mt-3 text-3xl font-semibold tracking-tight">
            That app page does not exist
          </h1>
          <p class="mt-4 max-w-2xl text-base leading-7 text-muted-foreground">
            The page you tried to open is not part of the protected application area.
          </p>
          <div class="mt-8 flex gap-3">
            <Link
              to="/app"
              class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-card px-4 text-sm font-medium text-card-foreground transition hover:bg-accent hover:text-accent-foreground"
            >
              Go to app home
            </Link>
            <Link
              to="/"
              class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-background px-4 text-sm font-medium text-foreground transition hover:bg-accent hover:text-accent-foreground"
            >
              Go to site home
            </Link>
          </div>
        </div>
      </main>
    </ProtectedShell>
  );
}