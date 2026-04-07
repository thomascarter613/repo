import { Outlet, createFileRoute, Link } from "@tanstack/solid-router";
import { AppShell } from "../components/layout/app-shell";

export const Route = createFileRoute("/auth")({
  component: AuthLayout,
  notFoundComponent: AuthNotFound,
});

function AuthLayout() {
  return (
    <AppShell>
      <Outlet />
    </AppShell>
  );
}

function AuthNotFound() {
  return (
    <AppShell>
      <main class="mx-auto max-w-2xl py-16">
        <div class="rounded-3xl border border-border bg-card p-8 shadow-2xl">
          <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">
            Authentication
          </p>
          <h1 class="mt-3 text-3xl font-semibold tracking-tight">
            That auth page does not exist
          </h1>
          <p class="mt-4 text-base leading-7 text-muted-foreground">
            The authentication route you requested is not available.
          </p>
          <div class="mt-8 flex gap-3">
            <Link
              to="/login"
              class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-card px-4 text-sm font-medium text-card-foreground transition hover:bg-accent hover:text-accent-foreground"
            >
              Go to login
            </Link>
            <Link
              to="/"
              class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-background px-4 text-sm font-medium text-foreground transition hover:bg-accent hover:text-accent-foreground"
            >
              Go home
            </Link>
          </div>
        </div>
      </main>
    </AppShell>
  );
}