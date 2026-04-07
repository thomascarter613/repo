import { screen } from "@solidjs/testing-library";
import { describe, expect, it } from "vitest";
import { Button } from "../../components/ui/button";
import { renderWithProviders } from "../test-utils";

describe("Button", () => {
  it("renders its label", () => {
    renderWithProviders(() => <Button type="button">Launch</Button>);
    expect(screen.getByRole("button", { name: "Launch" })).toBeInTheDocument();
  });
});
