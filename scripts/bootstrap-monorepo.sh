#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${1:-my-monorepo}"

if ! command -v bun >/dev/null 2>&1; then
  echo "Error: bun is not installed."
  exit 1
fi

mkdir -p "$REPO_NAME"
cd "$REPO_NAME"

mkdir -p \
  apps/api/src \
  apps/web/src \
  packages/shared/src \
  packages/contracts/src \
  packages/config/src \
  packages/database/src \
  packages/observability/src \
  packages/typescript-config \
  tests/e2e \
  docs/adr \
  docs/architecture \
  docs/standards \
  docs/runbooks \
  infra/compose \
  scripts \
  .github/workflows \
  .github/ISSUE_TEMPLATE \
  .devcontainer

cat > .gitignore <<'EOF'
# dependencies
node_modules
.bun
.pnpm-store

# build
dist
build
coverage
.turbo
playwright-report
test-results

# env
.env
.env.*
!.env.example

# editor/system
.DS_Store
.idea
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json

# logs
*.log

# drizzle
drizzle/*.sqlite
drizzle/*.db
EOF

cat > .gitattributes <<'EOF'
* text=auto eol=lf
*.sh text eol=lf
*.ts text eol=lf
*.tsx text eol=lf
*.js text eol=lf
*.json text eol=lf
*.jsonc text eol=lf
*.md text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
EOF

cat > .editorconfig <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false
EOF

cat > package.json <<'EOF'
{
  "name": "my-monorepo",
  "private": true,
  "packageManager": "bun@1.2.13",
  "workspaces": [
    "apps/*",
    "packages/*",
    "tests/*"
  ],
  "scripts": {
    "dev": "turbo run dev --parallel",
    "build": "turbo run build",
    "typecheck": "turbo run typecheck",
    "lint": "turbo run lint",
    "format": "biome check . --write",
    "test": "turbo run test",
    "check": "bun run lint && bun run typecheck && bun run test",
    "db:generate": "turbo run db:generate",
    "db:migrate": "turbo run db:migrate",
    "prepare": "lefthook install"
  },
  "devDependencies": {
    "@biomejs/biome": "2.2.6",
    "@changesets/cli": "2.29.7",
    "@playwright/test": "1.54.2",
    "@types/bun": "1.2.20",
    "lefthook": "1.11.12",
    "turbo": "2.5.6",
    "typescript": "5.9.2"
  }
}
EOF

cat > bunfig.toml <<'EOF'
[install]
saveTextLockfile = true
EOF

cat > turbo.json <<'EOF'
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", "build/**"]
    },
    "typecheck": {
      "dependsOn": ["^typecheck"],
      "outputs": []
    },
    "lint": {
      "outputs": []
    },
    "test": {
      "dependsOn": ["build"],
      "outputs": ["coverage/**"]
    },
    "db:generate": {
      "cache": false
    },
    "db:migrate": {
      "cache": false
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
EOF

cat > tsconfig.json <<'EOF'
{
  "files": [],
  "references": [
    { "path": "./packages/shared" },
    { "path": "./packages/contracts" },
    { "path": "./packages/config" },
    { "path": "./packages/database" },
    { "path": "./packages/observability" },
    { "path": "./apps/api" }
  ]
}
EOF

cat > biome.jsonc <<'EOF'
{
  "$schema": "https://biomejs.dev/schemas/2.0.5/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "includes": ["**", "!dist", "!build", "!.turbo", "!coverage", "!playwright-report", "!test-results"]
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "double",
      "semicolons": "always"
    }
  }
}
EOF

cat > lefthook.yml <<'EOF'
pre-commit:
  parallel: true
  commands:
    lint:
      run: bun run lint
    typecheck:
      run: bun run typecheck

pre-push:
  commands:
    test:
      run: bun run test
EOF

cat > README.md <<'EOF'
# Monorepo

## Purpose

This repository is a greenfield Bun + TypeScript full-stack monorepo baseline.

It establishes:

- Bun workspaces
- Turborepo task orchestration
- TypeScript project references
- Biome linting/formatting
- Hono API on Bun
- Zod contracts
- Drizzle database package
- OpenTelemetry package boundary
- Playwright E2E scaffold
- Lefthook quality gates

## Current State

This repo is intentionally scaffold-first.

What is real already:

- repo operating files
- shared packages
- API health route
- CI scaffold
- local dev environment scaffold

What is intentionally not yet locked:

- frontend framework choice
- production deployment target
- authentication strategy
- database engine selection

## Canonical Rules

- Bun is the only package manager.
- Cross-package imports use package names, not relative upward hacks.
- Apps may depend on packages; packages may not depend on apps.
- Runtime input validation belongs at boundaries.
- Repo-wide tasks run through root scripts.
EOF

cat > CONTRIBUTING.md <<'EOF'
# Contributing

## Working Rules

- Use Bun only.
- Run `bun install` from repo root.
- Before commit, run:
  - `bun run lint`
  - `bun run typecheck`
  - `bun run test`

## Commit Shape

- Prefer atomic commits.
- Keep infra, formatting, and behavior changes separate when practical.
- Document meaningful architectural decisions in `docs/adr/`.

## Branch Naming

Recommended patterns:

- `feat/...`
- `fix/...`
- `chore/...`
- `docs/...`

## Pull Requests

PRs should explain:

- what changed
- why it changed
- any architectural consequence
- how it was verified
EOF

cat > SECURITY.md <<'EOF'
# Security Policy

## Support Posture

This repository is in active early development.

## Reporting

Please do not report security vulnerabilities through public issues.

Instead, report them privately to the maintainers through the agreed private channel for this project.

## Response Model

Reports will be triaged, reproduced, and prioritized based on impact and exploitability.
EOF

cat > .github/CODEOWNERS <<'EOF'
* @your-github-handle
EOF

cat > .github/PULL_REQUEST_TEMPLATE.md <<'EOF'
## Summary

## Why

## Verification

## Risks / Follow-ups
EOF

cat > .github/ISSUE_TEMPLATE/bug_report.md <<'EOF'
---
name: Bug report
about: Report a defect
title: ""
labels: bug
assignees: ""
---

## Description

## Steps to reproduce

## Expected behavior

## Actual behavior
EOF

cat > .github/ISSUE_TEMPLATE/feature_request.md <<'EOF'
---
name: Feature request
about: Propose an enhancement
title: ""
labels: enhancement
assignees: ""
---

## Problem

## Proposed change

## Notes
EOF

cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  push:
  pull_request:

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: 1.2.13

      - name: Install dependencies
        run: bun install --frozen-lockfile

      - name: Lint
        run: bun run lint

      - name: Typecheck
        run: bun run typecheck

      - name: Test
        run: bun run test
EOF

cat > .devcontainer/devcontainer.json <<'EOF'
{
  "name": "bun-monorepo",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/git:1": {}
  },
  "postCreateCommand": "bash -lc 'curl -fsSL https://bun.sh/install | bash && source ~/.bashrc && bun install'",
  "customizations": {
    "vscode": {
      "extensions": [
        "biomejs.biome",
        "ms-playwright.playwright",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
EOF

cat > compose.yaml <<'EOF'
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
EOF

cat > packages/typescript-config/base.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2023",
    "lib": ["ES2023"],
    "module": "Preserve",
    "moduleResolution": "Bundler",
    "strict": true,
    "noEmit": false,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "composite": true,
    "incremental": true,
    "skipLibCheck": true,
    "verbatimModuleSyntax": true
  }
}
EOF

cat > packages/shared/package.json <<'EOF'
{
  "name": "@repo/shared",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc -b --pretty false",
    "lint": "biome check .",
    "test": "bun test"
  }
}
EOF

cat > packages/shared/tsconfig.json <<'EOF'
{
  "extends": "../typescript-config/base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
EOF

cat > packages/shared/src/index.ts <<'EOF'
export const APP_NAME = "my-monorepo";

export function ok(message = "ok") {
  return { status: "ok", message };
}
EOF

cat > packages/contracts/package.json <<'EOF'
{
  "name": "@repo/contracts",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": "./src/index.ts"
  },
  "dependencies": {
    "zod": "4.1.5"
  },
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc -b --pretty false",
    "lint": "biome check .",
    "test": "bun test"
  }
}
EOF

cat > packages/contracts/tsconfig.json <<'EOF'
{
  "extends": "../typescript-config/base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
EOF

cat > packages/contracts/src/index.ts <<'EOF'
import { z } from "zod";

export const HealthResponseSchema = z.object({
  status: z.literal("ok"),
  service: z.string(),
  timestamp: z.string()
});

export type HealthResponse = z.infer<typeof HealthResponseSchema>;
EOF

cat > packages/config/package.json <<'EOF'
{
  "name": "@repo/config",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": "./src/index.ts"
  },
  "dependencies": {
    "zod": "4.1.5"
  },
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc -b --pretty false",
    "lint": "biome check .",
    "test": "bun test"
  }
}
EOF

cat > packages/config/tsconfig.json <<'EOF'
{
  "extends": "../typescript-config/base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
EOF

cat > packages/config/src/index.ts <<'EOF'
import { z } from "zod";

const EnvSchema = z.object({
  PORT: z.coerce.number().default(3001)
});

export const env = EnvSchema.parse({
  PORT: process.env.PORT
});
EOF

cat > packages/database/package.json <<'EOF'
{
  "name": "@repo/database",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": "./src/index.ts"
  },
  "dependencies": {
    "drizzle-orm": "0.44.5",
    "postgres": "3.4.7"
  },
  "devDependencies": {
    "drizzle-kit": "0.31.4"
  },
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc -b --pretty false",
    "lint": "biome check .",
    "test": "bun test",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate"
  }
}
EOF

cat > packages/database/tsconfig.json <<'EOF'
{
  "extends": "../typescript-config/base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src", "drizzle.config.ts"]
}
EOF

cat > packages/database/drizzle.config.ts <<'EOF'
import type { Config } from "drizzle-kit";

export default {
  schema: "./src/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL ?? "postgres://app:app@localhost:5432/app"
  }
} satisfies Config;
EOF

cat > packages/database/src/schema.ts <<'EOF'
import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const healthChecks = pgTable("health_checks", {
  id: uuid("id").defaultRandom().primaryKey(),
  note: text("note").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull()
});
EOF

cat > packages/database/src/index.ts <<'EOF'
export * from "./schema";
EOF

cat > packages/observability/package.json <<'EOF'
{
  "name": "@repo/observability",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": "./src/index.ts"
  },
  "dependencies": {
    "@opentelemetry/api": "1.9.0"
  },
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc -b --pretty false",
    "lint": "biome check .",
    "test": "bun test"
  }
}
EOF

cat > packages/observability/tsconfig.json <<'EOF'
{
  "extends": "../typescript-config/base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
EOF

cat > packages/observability/src/index.ts <<'EOF'
import { trace } from "@opentelemetry/api";

export function getTracer(name = "app") {
  return trace.getTracer(name);
}
EOF

cat > apps/api/package.json <<'EOF'
{
  "name": "@repo/api",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "dependencies": {
    "@repo/config": "workspace:*",
    "@repo/contracts": "workspace:*",
    "@repo/observability": "workspace:*",
    "@repo/shared": "workspace:*",
    "hono": "4.9.5"
  },
  "scripts": {
    "dev": "bun --watch src/index.ts",
    "build": "tsc -b",
    "typecheck": "tsc -b --pretty false",
    "lint": "biome check .",
    "test": "bun test",
    "start": "bun src/index.ts"
  }
}
EOF

cat > apps/api/tsconfig.json <<'EOF'
{
  "extends": "../../packages/typescript-config/base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "references": [
    { "path": "../../packages/shared" },
    { "path": "../../packages/contracts" },
    { "path": "../../packages/config" },
    { "path": "../../packages/observability" }
  ],
  "include": ["src"]
}
EOF

cat > apps/api/src/index.ts <<'EOF'
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
EOF

cat > apps/web/package.json <<'EOF'
{
  "name": "@repo/web",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "echo 'Select and scaffold your web framework next (Next.js, TanStack Start, Vite, etc.)'",
    "build": "echo 'No web framework selected yet'",
    "typecheck": "echo 'No web framework selected yet'",
    "lint": "biome check .",
    "test": "bun test"
  }
}
EOF

cat > apps/web/src/README.md <<'EOF'
# Web App Placeholder

This app is intentionally not framework-locked yet.

Recommended next step:
- choose the web framework
- scaffold it inside `apps/web`
- keep shared contracts and domain logic in `packages/*`
EOF

cat > tests/e2e/package.json <<'EOF'
{
  "name": "@repo/e2e",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "playwright test"
  }
}
EOF

cat > tests/e2e/playwright.config.ts <<'EOF'
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
EOF

cat > tests/e2e/health.spec.ts <<'EOF'
import { expect, test } from "@playwright/test";

test("health endpoint responds ok", async ({ request }) => {
  const response = await request.get("/health");
  expect(response.ok()).toBeTruthy();

  const body = await response.json();
  expect(body.status).toBe("ok");
});
EOF

cat > docs/adr/README.md <<'EOF'
# ADRs

Store architecture decision records here.

Suggested format:
- context
- decision
- consequences
EOF

cat > docs/architecture/README.md <<'EOF'
# Architecture

Store system overviews, boundaries, and diagrams here.
EOF

cat > docs/standards/README.md <<'EOF'
# Standards

Store repository-wide engineering standards here.
EOF

cat > docs/runbooks/README.md <<'EOF'
# Runbooks

Store operational procedures here.
EOF

echo "Installing dependencies..."
bun install

echo
echo "Bootstrap complete."
echo "Next steps:"
echo "  cd $REPO_NAME"
echo "  bun run lint"
echo "  bun run typecheck"
echo "  bun run test"
echo "  bun run --filter @repo/api dev"