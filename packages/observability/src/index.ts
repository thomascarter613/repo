import { trace } from "@opentelemetry/api";

export function getTracer(name = "app") {
  return trace.getTracer(name);
}
