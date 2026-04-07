import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: ".",
  use: {
    baseURL: "http://127.0.0.1:3001"
  },
  webServer: {
    command: "bun run --filter @repo/api dev",
    url: "http://127.0.0.1:3001/health",
    reuseExistingServer: true,
    timeout: 120000
  }
});
