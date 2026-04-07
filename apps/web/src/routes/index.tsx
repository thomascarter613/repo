import { createFileRoute } from "@tanstack/solid-router";
import { createServerFn } from "@tanstack/solid-start";
import { AppShell } from "../components/layout/app-shell";
import { Button } from "../components/ui/button";
import { AppDialog } from "../components/ui/dialog";

const getGreeting = createServerFn({ method: "GET" }).handler(async () => {
  return "Full-stack web foundation with hardened server-managed Keycloak auth.";
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
              The auth layer now reads session state through a server function,
              validates callback state, and enforces session expiry.
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
              <p class="text-sm font-medium text-card-foreground">Auth hardening status</p>
              <ul class="space-y-2 text-sm text-muted-foreground">
                <li>• auth endpoints remain server routes</li>
                <li>• session lookup moved behind a server function</li>
                <li>• protected subtree uses beforeLoad with server-backed auth state</li>
                <li>• session expiry is enforced</li>
              </ul>
              <div class="pt-3">
                <AppDialog
                  trigger={
                    <Button variant="ghost" type="button">
                      Open hardening note
                    </Button>
                  }
                  title="Auth boundary improved"
                  description="This removes the brittle request-fabrication pattern from the protected route tree."
                >
                  <p class="text-sm text-muted-foreground">
                    The next upgrade is replacing signed cookie payload sessions with opaque
                    server-side sessions backed by a database or store.
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
