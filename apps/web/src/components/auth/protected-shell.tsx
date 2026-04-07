import type { JSX } from "solid-js";
import { AppShell } from "../layout/app-shell";

export function ProtectedShell(props: { children: JSX.Element }) {
  return <AppShell>{props.children}</AppShell>;
}
