import { createFileRoute } from "@tanstack/solid-router";
import { AppShell } from "../components/layout/app-shell";
import { Button } from "../components/ui/button";

export const Route = createFileRoute("/login")({
  component: LoginPage
});

function LoginPage() {
  return (
    <AppShell>
      <main class="mx-auto max-w-xl py-16">
        <div class="rounded-3xl border border-border bg-card p-8 shadow-2xl">
          <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">
            Authentication
          </p>
          <h1 class="mt-3 text-3xl font-semibold tracking-tight">
            Sign in
          </h1>
          <p class="mt-4 text-base leading-7 text-muted-foreground">
            Continue with Keycloak using the server-managed authentication flow.
          </p>
          <div class="mt-8">
            <a href="/auth/login">
              <Button type="button">Continue to sign in</Button>
            </a>
          </div>
        </div>
      </main>
    </AppShell>
  );
}
