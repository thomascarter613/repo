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
