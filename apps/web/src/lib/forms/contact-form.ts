import { createForm } from "@tanstack/solid-form";

export function createContactForm(onSubmitted: (value: {
  name: string;
  email: string;
  message: string;
}) => void) {
  return createForm(() => ({
    defaultValues: {
      name: "",
      email: "",
      message: "",
    },
    onSubmit: async ({ value }) => {
      onSubmitted(value);
    },
  }));
}