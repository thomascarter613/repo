import { createSignal } from "solid-js";
import { createContactForm } from "../../lib/forms/contact-form";
import { Button } from "../ui/button";

export function ContactForm() {
  const [submitted, setSubmitted] = createSignal<null | {
    name: string;
    email: string;
    message: string;
  }>(null);

  const form = createContactForm(setSubmitted);

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
          void form.handleSubmit();
        }}
      >
        <form.Field
          name="name"
          validators={{
            onChange: ({ value }) =>
              !value || value.trim().length < 2 ? "Name must be at least 2 characters." : undefined,
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
              !value || !value.includes("@") ? "Enter a valid email address." : undefined,
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
              !value || value.trim().length < 10 ? "Message must be at least 10 characters." : undefined,
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