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
