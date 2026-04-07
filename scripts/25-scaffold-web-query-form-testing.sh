#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
WEB_DIR="${ROOT_DIR}/apps/web"

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Error: required file not found: $file"
    exit 1
  fi
}

ensure_dir() {
  mkdir -p "$1"
}

replace_file_if_different() {
  local target="$1"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"

  if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
    rm -f "$tmp"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  mv "$tmp" "$target"
}

patch_web_package_json() {
  node <<'EOF'
const fs = require('fs');
const path = require('path');

const file = path.resolve('apps/web/package.json');
const json = JSON.parse(fs.readFileSync(file, 'utf8'));

json.dependencies ||= {};
json.devDependencies ||= {};
json.scripts ||= {};

const wantedDeps = {
  "@tanstack/solid-form": "^1.28.0"
};

const wantedDevDeps = {
  "@testing-library/dom": "^10.4.0",
  "@vitest/ui": "^3.2.4"
};

for (const [name, version] of Object.entries(wantedDeps)) {
  json.dependencies[name] = json.dependencies[name] || version;
}

for (const [name, version] of Object.entries(wantedDevDeps)) {
  json.devDependencies[name] = json.devDependencies[name] || version;
}

if (!json.scripts["test:watch"]) {
  json.scripts["test:watch"] = "vitest";
}

fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n');
EOF
}

main() {
  require_file "${WEB_DIR}/package.json"
  require_file "${WEB_DIR}/src/routes/__root.tsx"
  require_file "${WEB_DIR}/vitest.config.ts"
  require_file "${WEB_DIR}/src/lib/query/client.ts"

  ensure_dir "${WEB_DIR}/src/lib/forms"
  ensure_dir "${WEB_DIR}/src/store"
  ensure_dir "${WEB_DIR}/src/components/providers"
  ensure_dir "${WEB_DIR}/src/components/forms"
  ensure_dir "${WEB_DIR}/src/routes/demo"
  ensure_dir "${WEB_DIR}/src/tests/components"
  ensure_dir "${WEB_DIR}/src/tests/routes"

  patch_web_package_json

  replace_file_if_different "${WEB_DIR}/src/lib/query/client.ts" <<'EOF'
import { QueryClient } from "@tanstack/solid-query";

export function createAppQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        refetchOnWindowFocus: false,
        retry: 1
      }
    }
  });
}
EOF

  replace_file_if_different "${WEB_DIR}/src/components/providers/app-providers.tsx" <<'EOF'
import { QueryClientProvider } from "@tanstack/solid-query";
import type { JSX } from "solid-js";
import { createMemo } from "solid-js";
import { createAppQueryClient } from "../../lib/query/client";

export function AppProviders(props: { children: JSX.Element }) {
  const queryClient = createMemo(() => createAppQueryClient());

  return (
    <QueryClientProvider client={queryClient()}>
      {props.children}
    </QueryClientProvider>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/store/app-store.ts" <<'EOF'
import { createStore } from "solid-js/store";

type AppStoreState = {
  sidebarOpen: boolean;
  commandPaletteOpen: boolean;
};

const [state, setState] = createStore<AppStoreState>({
  sidebarOpen: false,
  commandPaletteOpen: false
});

export const appStore = {
  state,
  openSidebar() {
    setState("sidebarOpen", true);
  },
  closeSidebar() {
    setState("sidebarOpen", false);
  },
  setCommandPaletteOpen(value: boolean) {
    setState("commandPaletteOpen", value);
  }
};
EOF

  replace_file_if_different "${WEB_DIR}/src/lib/forms/contact-form.ts" <<'EOF'
import { createForm } from "@tanstack/solid-form";

export function createContactForm() {
  return createForm(() => ({
    defaultValues: {
      name: "",
      email: "",
      message: ""
    },
    onSubmit: async ({ value }) => value
  }));
}
EOF

  replace_file_if_different "${WEB_DIR}/src/components/forms/contact-form.tsx" <<'EOF'
import { createSignal } from "solid-js";
import { createContactForm } from "../../lib/forms/contact-form";
import { Button } from "../ui/button";

export function ContactForm() {
  const form = createContactForm();
  const [submitted, setSubmitted] = createSignal<null | {
    name: string;
    email: string;
    message: string;
  }>(null);

  return (
    <div class="rounded-3xl border border-border bg-card p-6 shadow-2xl">
      <div class="mb-5 space-y-2">
        <h2 class="text-xl font-semibold tracking-tight">Demo form</h2>
        <p class="text-sm text-muted-foreground">
          This route exists to prove TanStack Form is wired into the web app layer.
        </p>
      </div>

      <form
        class="space-y-4"
        onSubmit={(event) => {
          event.preventDefault();
          void form.handleSubmit().then((result) => {
            if (result?.value) {
              setSubmitted(result.value);
            }
          });
        }}
      >
        <form.Field
          name="name"
          validators={{
            onChange: ({ value }) =>
              !value || value.trim().length < 2 ? "Name must be at least 2 characters." : undefined
          }}
        >
          {(field) => (
            <div class="space-y-2">
              <label class="text-sm font-medium" for={field().name}>
                Name
              </label>
              <input
                id={field().name}
                name={field().name}
                value={field().state.value}
                onInput={(event) => field().handleChange(event.currentTarget.value)}
                onBlur={field().handleBlur}
                class="h-11 w-full rounded-xl border border-border bg-background px-3 text-foreground outline-none transition focus:border-primary"
                placeholder="Ada Lovelace"
              />
              {field().state.meta.errors[0] ? (
                <p class="text-sm text-red-300">{field().state.meta.errors[0]}</p>
              ) : null}
            </div>
          )}
        </form.Field>

        <form.Field
          name="email"
          validators={{
            onChange: ({ value }) =>
              !value || !value.includes("@") ? "Enter a valid email address." : undefined
          }}
        >
          {(field) => (
            <div class="space-y-2">
              <label class="text-sm font-medium" for={field().name}>
                Email
              </label>
              <input
                id={field().name}
                name={field().name}
                value={field().state.value}
                onInput={(event) => field().handleChange(event.currentTarget.value)}
                onBlur={field().handleBlur}
                class="h-11 w-full rounded-xl border border-border bg-background px-3 text-foreground outline-none transition focus:border-primary"
                placeholder="ada@example.com"
              />
              {field().state.meta.errors[0] ? (
                <p class="text-sm text-red-300">{field().state.meta.errors[0]}</p>
              ) : null}
            </div>
          )}
        </form.Field>

        <form.Field
          name="message"
          validators={{
            onChange: ({ value }) =>
              !value || value.trim().length < 10 ? "Message must be at least 10 characters." : undefined
          }}
        >
          {(field) => (
            <div class="space-y-2">
              <label class="text-sm font-medium" for={field().name}>
                Message
              </label>
              <textarea
                id={field().name}
                name={field().name}
                value={field().state.value}
                onInput={(event) => field().handleChange(event.currentTarget.value)}
                onBlur={field().handleBlur}
                class="min-h-32 w-full rounded-xl border border-border bg-background px-3 py-3 text-foreground outline-none transition focus:border-primary"
                placeholder="Tell us what you want to build."
              />
              {field().state.meta.errors[0] ? (
                <p class="text-sm text-red-300">{field().state.meta.errors[0]}</p>
              ) : null}
            </div>
          )}
        </form.Field>

        <Button type="submit">Submit</Button>
      </form>

      {submitted() ? (
        <div class="mt-6 rounded-2xl border border-border bg-background p-4">
          <p class="text-sm font-medium">Submitted payload</p>
          <pre class="mt-3 overflow-x-auto text-sm text-muted-foreground">
            {JSON.stringify(submitted(), null, 2)}
          </pre>
        </div>
      ) : null}
    </div>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/__root.tsx" <<'EOF'
import {
  HeadContent,
  Outlet,
  Scripts,
  createRootRoute
} from "@tanstack/solid-router";
import { Suspense } from "solid-js";
import { HydrationScript } from "solid-js/web";
import { AppProviders } from "../components/providers/app-providers";
import appCss from "../styles/app.css?url";

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      {
        name: "viewport",
        content: "width=device-width, initial-scale=1"
      },
      {
        title: "Monorepo Web"
      },
      {
        name: "description",
        content: "TanStack Start + Solid web application"
      }
    ],
    links: [{ rel: "stylesheet", href: appCss }]
  }),
  shellComponent: RootDocument
});

function RootDocument(props: { children: unknown }) {
  return (
    <html lang="en">
      <head>
        <HydrationScript />
        <HeadContent />
      </head>
      <body>
        <AppProviders>
          <Suspense>{props.children}</Suspense>
        </AppProviders>
        <Scripts />
      </body>
    </html>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/demo.form.tsx" <<'EOF'
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
EOF

  replace_file_if_different "${WEB_DIR}/src/tests/test-utils.tsx" <<'EOF'
import { QueryClientProvider } from "@tanstack/solid-query";
import { render, type RenderOptions } from "@solidjs/testing-library";
import type { JSX } from "solid-js";
import { createAppQueryClient } from "../lib/query/client";

function Providers(props: { children: JSX.Element }) {
  const client = createAppQueryClient();

  return <QueryClientProvider client={client}>{props.children}</QueryClientProvider>;
}

export function renderWithProviders(ui: () => JSX.Element, options?: RenderOptions) {
  return render(ui, {
    wrapper: Providers,
    ...options
  });
}
EOF

  replace_file_if_different "${WEB_DIR}/src/tests/components/button.test.tsx" <<'EOF'
import { screen } from "@solidjs/testing-library";
import { describe, expect, it } from "vitest";
import { Button } from "../../components/ui/button";
import { renderWithProviders } from "../test-utils";

describe("Button", () => {
  it("renders its label", () => {
    renderWithProviders(() => <Button type="button">Launch</Button>);
    expect(screen.getByRole("button", { name: "Launch" })).toBeInTheDocument();
  });
});
EOF

  replace_file_if_different "${WEB_DIR}/src/tests/routes/demo-form.test.tsx" <<'EOF'
import { screen } from "@solidjs/testing-library";
import { describe, expect, it } from "vitest";
import { ContactForm } from "../../components/forms/contact-form";
import { renderWithProviders } from "../test-utils";

describe("ContactForm", () => {
  it("renders the expected fields and submit control", () => {
    renderWithProviders(() => <ContactForm />);

    expect(screen.getByLabelText("Name")).toBeInTheDocument();
    expect(screen.getByLabelText("Email")).toBeInTheDocument();
    expect(screen.getByLabelText("Message")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Submit" })).toBeInTheDocument();
  });
});
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/index.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";
import { createServerFn } from "@tanstack/solid-start";
import { AppShell } from "../components/layout/app-shell";
import { Button } from "../components/ui/button";
import { AppDialog } from "../components/ui/dialog";

const getGreeting = createServerFn({ method: "GET" }).handler(async () => {
  return "A serious full-stack web foundation, now with data, forms, and testing.";
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
              This layer wires the web app for real application work: provider setup,
              query infrastructure, form primitives, test utilities, and an example
              form route.
            </p>
            <div class="flex flex-wrap items-center gap-3">
              <Button type="button">Primary action</Button>
              <Button variant="secondary" type="button">
                Secondary action
              </Button>
              <a
                class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-card px-4 text-sm font-medium text-card-foreground transition hover:bg-accent hover:text-accent-foreground"
                href="/demo/form"
              >
                Open demo form
              </a>
            </div>
          </div>

          <div class="rounded-3xl border border-border bg-card p-6 shadow-2xl">
            <div class="space-y-3">
              <p class="text-sm font-medium text-card-foreground">Foundation status</p>
              <ul class="space-y-2 text-sm text-muted-foreground">
                <li>• Query provider wired</li>
                <li>• Form baseline route added</li>
                <li>• Test utilities in place</li>
                <li>• Auth still deferred to the next overlay</li>
              </ul>
              <div class="pt-3">
                <AppDialog
                  trigger={
                    <Button variant="ghost" type="button">
                      Open example dialog
                    </Button>
                  }
                  title="Application layer is ready"
                  description="The web app now has data, form, and testing foundations in place."
                >
                  <p class="text-sm text-muted-foreground">
                    The next layer should add server-managed Keycloak authentication and protected routes.
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
EOF

  replace_file_if_different "${WEB_DIR}/vitest.config.ts" <<'EOF'
import { defineConfig } from "vitest/config";
import solidPlugin from "vite-plugin-solid";

export default defineConfig({
  plugins: [solidPlugin()],
  test: {
    environment: "jsdom",
    setupFiles: ["./src/tests/setup.ts"],
    globals: true,
    include: ["src/tests/**/*.test.ts", "src/tests/**/*.test.tsx"]
  }
});
EOF

  replace_file_if_different "${WEB_DIR}/src/tests/setup.ts" <<'EOF'
import "@testing-library/jest-dom";
EOF

  echo "Query + Form + frontend testing layer applied to apps/web."
  echo
  echo "Next steps:"
  echo "  1. bun install"
  echo "  2. bun run --filter @repo/web test"
  echo "  3. bun run --filter @repo/web dev"
  echo "  4. next: corrected scripts/30-scaffold-auth-keycloak-bff.sh"
}

main "$@"