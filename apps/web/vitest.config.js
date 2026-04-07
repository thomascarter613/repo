import { defineConfig } from "vitest/config";
import solidPlugin from "vite-plugin-solid";
export default defineConfig({
    plugins: [solidPlugin()],
    test: {
        environment: "jsdom",
        setupFiles: ["./src/tests/setup.ts"],
        globals: true,
        include: ["src/tests/**/*.test.ts", "src/tests/**/*.test.tsx"]
    }
});
//# sourceMappingURL=vitest.config.js.map