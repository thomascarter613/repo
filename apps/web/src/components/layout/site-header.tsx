import { Button } from "../ui/button";

export function SiteHeader() {
  return (
    <header class="border-b border-border">
      <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
        <div class="flex items-center gap-3">
          <div class="h-3 w-3 rounded-full bg-primary" />
          <span class="text-sm font-semibold tracking-wide">Monorepo Web</span>
        </div>
        <nav class="flex items-center gap-3">
          <Button variant="ghost" size="sm" type="button">
            Docs
          </Button>
          <Button variant="secondary" size="sm" type="button">
            Sign in
          </Button>
        </nav>
      </div>
    </header>
  );
}
