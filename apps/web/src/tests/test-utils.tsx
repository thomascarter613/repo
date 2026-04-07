import { QueryClientProvider } from "@tanstack/solid-query";
import { render } from "@solidjs/testing-library";
import type { JSX } from "solid-js";
import { createAppQueryClient } from "../lib/query/client";

function Providers(props: { children: JSX.Element }) {
  const client = createAppQueryClient();

  return <QueryClientProvider client={client}>{props.children}</QueryClientProvider>;
}

export function renderWithProviders(ui: () => JSX.Element): ReturnType<typeof render>  {
  return render(ui, {
    wrapper: Providers,
  });
}