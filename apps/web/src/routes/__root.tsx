import type { JSX } from "solid-js";
import {
  HeadContent,
  Outlet,
  Scripts,
  createRootRoute,
  Link,
} from "@tanstack/solid-router";
import { Suspense } from "solid-js";
import { HydrationScript } from "solid-js/web";
import { AppProviders } from "../components/providers/app-providers";
import appCss from "../styles/app.css?url";

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "Monorepo Web" },
      {
        name: "description",
        content: "TanStack Start + Solid web application",
      },
    ],
    links: [{ rel: "stylesheet", href: appCss }],
  }),
  shellComponent: RootDocument,
  notFoundComponent: RootNotFound,
});

function RootDocument(props: { children: JSX.Element }) {
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

function RootNotFound() {
  return (
    <main class="min-h-screen bg-background text-foreground">
      <div class="mx-auto flex min-h-screen max-w-3xl flex-col items-start justify-center gap-4 px-6 py-16">
        <p class="text-sm uppercase tracking-[0.2em] text-muted-foreground">404</p>
        <h1 class="text-4xl font-semibold tracking-tight">Page not found</h1>
        <p class="max-w-xl text-base leading-7 text-muted-foreground">
          The page you tried to open does not exist or has moved.
        </p>
        <Link
          to="/"
          class="inline-flex h-10 items-center justify-center rounded-xl border border-border bg-card px-4 text-sm font-medium text-card-foreground transition hover:bg-accent hover:text-accent-foreground"
        >
          Go home
        </Link>
      </div>
    </main>
  );
}