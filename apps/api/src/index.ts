import { env } from "@repo/config";
import { HealthResponseSchema } from "@repo/contracts";
import { getTracer } from "@repo/observability";
import { APP_NAME } from "@repo/shared";
import { Hono } from "hono";

const tracer = getTracer("api");
const app = new Hono();

app.get("/health", (c) => {
  return tracer.startActiveSpan("GET /health", (span) => {
    const payload = {
      status: "ok",
      service: APP_NAME,
      timestamp: new Date().toISOString()
    };

    const result = HealthResponseSchema.parse(payload);
    span.end();
    return c.json(result);
  });
});

export default {
  port: env.PORT,
  fetch: app.fetch
};

console.log(`API listening on http://localhost:${env.PORT}`);
