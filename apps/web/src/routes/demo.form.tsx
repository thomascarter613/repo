import { createFileRoute } from "@tanstack/solid-router";
import { AppShell } from "../components/layout/app-shell";
import { ContactForm } from "../components/forms/contact-form";

export const Route = createFileRoute("/demo/form")({
  component: DemoFormPage
});

function DemoFormPage() {
  return (
    <AppShell>
      <main class="mx-auto max-w-3xl py-8">
        <div class="mb-8 space-y-3">
          <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">
            TanStack Form
          </p>
          <h1 class="text-3xl font-semibold tracking-tight">Form baseline route</h1>
          <p class="max-w-2xl text-base leading-7 text-muted-foreground">
            This route proves the app can host real form logic before the auth layer is added.
          </p>
        </div>

        <ContactForm />
      </main>
    </AppShell>
  );
}
