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
