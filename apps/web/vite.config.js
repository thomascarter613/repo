import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import { tanstackRouter } from "@tanstack/router-plugin/vite";
import { tanstackStart } from "@tanstack/solid-start/plugin/vite";
import solidPlugin from "vite-plugin-solid";
export default defineConfig({
    plugins: [
        tailwindcss(),
        tanstackRouter({
            target: "solid",
            autoCodeSplitting: true,
            routesDirectory: "./src/routes",
            generatedRouteTree: "./src/routeTree.gen.ts"
        }),
        tanstackStart(),
        solidPlugin({ ssr: true })
    ]
});
//# sourceMappingURL=vite.config.js.map