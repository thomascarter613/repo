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
