import { env } from "@repo/config";
import { buildSession } from "./session.server";

type TokenResponse = {
  access_token: string;
  id_token?: string;
  refresh_token?: string;
  token_type: string;
  expires_in: number;
};

type ParsedIdToken = {
  sub: string;
  email?: string;
  name?: string;
  preferred_username?: string;
  realm_access?: {
    roles?: string[];
  };
};

function getOidcBase() {
  return `${env.KEYCLOAK_BASE_URL}/realms/${env.KEYCLOAK_REALM}/protocol/openid-connect`;
}

export function getAuthorizationUrl(state: string) {
  const url = new URL(`${getOidcBase()}/auth`);
  url.searchParams.set("client_id", env.KEYCLOAK_CLIENT_ID);
  url.searchParams.set("redirect_uri", env.KEYCLOAK_REDIRECT_URI);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "openid profile email");
  url.searchParams.set("state", state);
  return url.toString();
}

export async function exchangeCodeForTokens(code: string) {
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: env.KEYCLOAK_CLIENT_ID,
    client_secret: env.KEYCLOAK_CLIENT_SECRET,
    code,
    redirect_uri: env.KEYCLOAK_REDIRECT_URI
  });

  const response = await fetch(`${getOidcBase()}/token`, {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded"
    },
    body
  });

  if (!response.ok) {
    throw new Error("Failed to exchange authorization code with Keycloak.");
  }

  return (await response.json()) as TokenResponse;
}

export function decodeJwtPayload<T>(jwt: string): T {
  const [, payload] = jwt.split(".");
  if (!payload) {
    throw new Error("Invalid JWT payload.");
  }

  return JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as T;
}

export function mapIdTokenToSession(idToken: string) {
  const parsed = decodeJwtPayload<ParsedIdToken>(idToken);

  return buildSession({
    sub: parsed.sub,
    email: parsed.email,
    name: parsed.name,
    preferredUsername: parsed.preferred_username,
    roles: parsed.realm_access?.roles ?? []
  });
}
