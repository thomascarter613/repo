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
