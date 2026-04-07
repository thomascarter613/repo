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

const wantedDeps = {
  "@kobalte/core": "^0.13.11",
  "class-variance-authority": "^0.7.1",
  "clsx": "^2.1.1",
  "tailwind-merge": "^3.3.1"
};

const wantedDevDeps = {
  "@tailwindcss/vite": "^4.1.12",
  "tailwindcss": "^4.1.12"
};

for (const [name, version] of Object.entries(wantedDeps)) {
  json.dependencies[name] = json.dependencies[name] || version;
}

for (const [name, version] of Object.entries(wantedDevDeps)) {
  json.devDependencies[name] = json.devDependencies[name] || version;
}

fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n');
EOF
}

patch_web_vite_config() {
  node <<'EOF'
const fs = require('fs');
const path = require('path');

const file = path.resolve('apps/web/vite.config.ts');
let text = fs.readFileSync(file, 'utf8');

if (!text.includes('import tailwindcss from "@tailwindcss/vite";')) {
  text = `import tailwindcss from "@tailwindcss/vite";\n` + text;
}

if (!text.includes('tailwindcss(),')) {
  text = text.replace(
    /plugins:\s*\[/,
    'plugins: [\n    tailwindcss(),'
  );
}

fs.writeFileSync(file, text);
EOF
}

main() {
  require_file "${WEB_DIR}/package.json"
  require_file "${WEB_DIR}/vite.config.ts"
  require_file "${WEB_DIR}/src/routes/__root.tsx"
  require_file "${WEB_DIR}/src/routes/index.tsx"

  ensure_dir "${WEB_DIR}/src/components/ui"
  ensure_dir "${WEB_DIR}/src/components/layout"
  ensure_dir "${WEB_DIR}/src/lib/utils"
  ensure_dir "${WEB_DIR}/src/styles"

  patch_web_package_json
  patch_web_vite_config

  replace_file_if_different "${WEB_DIR}/src/styles/app.css" <<'EOF'
@import "tailwindcss";

:root {
  color-scheme: dark;

  --background: oklch(0.16 0.01 260);
  --foreground: oklch(0.96 0.01 260);
  --muted: oklch(0.28 0.01 260);
  --muted-foreground: oklch(0.76 0.02 260);
  --card: oklch(0.2 0.01 260);
  --card-foreground: oklch(0.96 0.01 260);
  --border: oklch(0.32 0.01 260);
  --primary: oklch(0.56 0.13 270);
  --primary-foreground: oklch(0.98 0.01 260);
  --accent: oklch(0.28 0.03 270);
  --accent-foreground: oklch(0.96 0.01 260);
  --ring: oklch(0.62 0.11 270);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-border: var(--border);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-ring: var(--ring);
}

html,
body {
  min-height: 100%;
  background: var(--background);
  color: var(--foreground);
}

body {
  font-family:
    Inter,
    ui-sans-serif,
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    sans-serif;
}

* {
  box-sizing: border-box;
}

::selection {
  background: color-mix(in oklab, var(--primary) 35%, transparent);
}
EOF

  replace_file_if_different "${WEB_DIR}/src/lib/utils/cn.ts" <<'EOF'
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: Array<string | false | null | undefined>) {
  return twMerge(clsx(inputs));
}
EOF

  replace_file_if_different "${WEB_DIR}/src/components/ui/button.tsx" <<'EOF'
import { cva, type VariantProps } from "class-variance-authority";
import type { ComponentProps } from "solid-js";
import { cn } from "../../lib/utils/cn";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-xl border text-sm font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        primary:
          "border-transparent bg-primary text-primary-foreground hover:opacity-90",
        secondary:
          "border-border bg-card text-card-foreground hover:bg-accent hover:text-accent-foreground",
        ghost:
          "border-transparent bg-transparent text-foreground hover:bg-accent hover:text-accent-foreground"
      },
      size: {
        sm: "h-9 px-3",
        md: "h-10 px-4",
        lg: "h-11 px-6"
      }
    },
    defaultVariants: {
      variant: "primary",
      size: "md"
    }
  }
);

type ButtonProps = ComponentProps<"button"> &
  VariantProps<typeof buttonVariants>;

export function Button(props: ButtonProps) {
  const { class: className, variant, size, ...rest } = props;

  return (
    <button
      class={cn(buttonVariants({ variant, size }), className)}
      {...rest}
    />
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/components/ui/dialog.tsx" <<'EOF'
import * as Dialog from "@kobalte/core/dialog";
import type { JSX } from "solid-js";
import { cn } from "../../lib/utils/cn";

export function AppDialog(props: {
  trigger: JSX.Element;
  title: string;
  description?: string;
  children: JSX.Element;
}) {
  return (
    <Dialog.Root>
      <Dialog.Trigger>{props.trigger}</Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
        <div class="fixed inset-0 flex items-center justify-center p-4">
          <Dialog.Content
            class={cn(
              "w-full max-w-lg rounded-2xl border border-border bg-card p-6 text-card-foreground shadow-2xl"
            )}
          >
            <Dialog.Title class="text-lg font-semibold">
              {props.title}
            </Dialog.Title>
            {props.description ? (
              <Dialog.Description class="mt-2 text-sm text-muted-foreground">
                {props.description}
              </Dialog.Description>
            ) : null}
            <div class="mt-4">{props.children}</div>
          </Dialog.Content>
        </div>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/components/layout/site-header.tsx" <<'EOF'
import { Button } from "../ui/button";

export function SiteHeader() {
  return (
    <header class="border-b border-border">
      <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
        <div class="flex items-center gap-3">
          <div class="h-3 w-3 rounded-full bg-primary" />
          <span class="text-sm font-semibold tracking-wide">Monorepo Web</span>
        </div>
        <nav class="flex items-center gap-3">
          <Button variant="ghost" size="sm" type="button">
            Docs
          </Button>
          <Button variant="secondary" size="sm" type="button">
            Sign in
          </Button>
        </nav>
      </div>
    </header>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/components/layout/app-shell.tsx" <<'EOF'
import type { JSX } from "solid-js";
import { SiteHeader } from "./site-header";

export function AppShell(props: { children: JSX.Element }) {
  return (
    <div class="min-h-screen bg-background text-foreground">
      <SiteHeader />
      <div class="mx-auto max-w-6xl px-6 py-10">{props.children}</div>
    </div>
  );
}
EOF

  replace_file_if_different "${WEB_DIR}/src/routes/index.tsx" <<'EOF'
import { createFileRoute } from "@tanstack/solid-router";
import { createServerFn } from "@tanstack/solid-start";
import { AppShell } from "../components/layout/app-shell";
import { Button } from "../components/ui/button";
import { AppDialog } from "../components/ui/dialog";

const getGreeting = createServerFn({ method: "GET" }).handler(async () => {
  return "A serious full-stack web foundation, now with Tailwind and Kobalte.";
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
              This layer adds the design foundation for the web app: utility styling,
              accessible primitives, a reusable shell, and the first internal UI wrapper
              pattern.
            </p>
            <div class="flex flex-wrap items-center gap-3">
              <Button type="button">Primary action</Button>
              <Button variant="secondary" type="button">
                Secondary action
              </Button>
            </div>
          </div>

          <div class="rounded-3xl border border-border bg-card p-6 shadow-2xl">
            <div class="space-y-3">
              <p class="text-sm font-medium text-card-foreground">Foundation status</p>
              <ul class="space-y-2 text-sm text-muted-foreground">
                <li>• Tailwind styling ready</li>
                <li>• Kobalte primitive wrapper started</li>
                <li>• App shell in place</li>
                <li>• Auth still deferred to the next overlay</li>
              </ul>
              <div class="pt-3">
                <AppDialog
                  trigger={
                    <Button variant="ghost" type="button">
                      Open example dialog
                    </Button>
                  }
                  title="Kobalte wired successfully"
                  description="This dialog uses a Kobalte primitive wrapped in the app's own component API."
                >
                  <p class="text-sm text-muted-foreground">
                    Keep reusable accessibility logic in wrapped primitives, not scattered
                    through route files.
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

  echo "Tailwind + Kobalte layer applied to apps/web."
  echo
  echo "Next steps:"
  echo "  1. bun install"
  echo "  2. bun run --filter @repo/web dev"
  echo "  3. next: corrected scripts/25-scaffold-web-query-form-testing.sh"
}

main "$@"