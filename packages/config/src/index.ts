import { z } from "zod";

const EnvSchema = z.object({
  PORT: z.coerce.number().default(3001),
  KEYCLOAK_BASE_URL: z.string().url().default("http://localhost:8080"),
  KEYCLOAK_REALM: z.string().min(1).default("myrealm"),
  KEYCLOAK_CLIENT_ID: z.string().min(1).default("web"),
  KEYCLOAK_CLIENT_SECRET: z.string().min(1).default("replace-me"),
  KEYCLOAK_REDIRECT_URI: z.string().url().default("http://localhost:3000/auth/callback"),
  WEB_SESSION_SECRET: z.string().min(32).default("replace-with-a-long-random-secret-change-me")
});

export const env = EnvSchema.parse({
  PORT: process.env.PORT,
  KEYCLOAK_BASE_URL: process.env.KEYCLOAK_BASE_URL,
  KEYCLOAK_REALM: process.env.KEYCLOAK_REALM,
  KEYCLOAK_CLIENT_ID: process.env.KEYCLOAK_CLIENT_ID,
  KEYCLOAK_CLIENT_SECRET: process.env.KEYCLOAK_CLIENT_SECRET,
  KEYCLOAK_REDIRECT_URI: process.env.KEYCLOAK_REDIRECT_URI,
  WEB_SESSION_SECRET: process.env.WEB_SESSION_SECRET
});
