# Electromon API

NestJS backend with Prisma (PostgreSQL), Redis, RabbitMQ, and MinIO. Includes **`infra/`** for local Docker services and deployment.

**Local URL:** http://localhost:3001  
**Swagger:** http://localhost:3001/api/docs

---

## Prerequisites

- Node.js 20+, pnpm 9+
- Docker Desktop (for `make infra-up` / `make infra-full`)

---

## Run locally without Docker (recommended for development)

Use Docker **only for dependencies** (Postgres, Redis, etc.). Run the NestJS app on your machine with hot reload.

### First time

```bash
make setup
```

Equivalent to:

```bash
make install
make env                 # cp infra/env/local.env.example → .env (+ db/.env)
make infra-up            # Docker: postgres, redis, rabbitmq, minio
pnpm db:generate
pnpm db:migrate:deploy
pnpm db:seed
```

### Every day

```bash
make infra-up    # start deps if Docker was stopped
make dev         # build db/shared packages + nest start --watch
```

### Without any Docker

Install PostgreSQL locally, then:

```bash
cp infra/env/local.env.example .env
# Edit DATABASE_URL in .env

make install
pnpm db:generate && pnpm db:migrate:deploy && pnpm db:seed
make dev
```

---

## Run with Docker

### Dependencies only (app on host)

```bash
cp infra/env/local.env.example .env
make infra-up
make dev
```

| Service | Port |
|---------|------|
| PostgreSQL | 5432 |
| Redis | 6379 |
| RabbitMQ | 5672 (mgmt 15672) |
| MinIO | 9000 (console 9001) |

### Full stack (API + deps in containers)

```bash
cp infra/env/local.env.example .env
make infra-full
```

Runs migrate job, then API container on **:3001**.

### Observability (optional)

```bash
make infra-up
make dev              # API on host so Prometheus can scrape :3001
make infra-obs-up
```

Grafana: http://localhost:3030 (`admin` / `electromon`)

### Stop / reset

```bash
make infra-down       # stop deps
make infra-full-down  # stop full stack
make infra-reset      # remove volumes + orphaned containers (if name conflicts)
```

---

## Environment

```bash
make env    # copies infra/env/local.env.example → .env
```

Key variables:

| Variable | Example |
|----------|---------|
| `DATABASE_URL` | `postgresql://electromon:electromon@localhost:5432/electromon` |
| `API_PORT` | `3001` |
| `CORS_ORIGIN` | `http://localhost:3000` |
| `JWT_ACCESS_SECRET` | min 32 chars (change in production) |

Template: [infra/env/local.env.example](./infra/env/local.env.example)

---

## Database

```bash
make db-studio           # Prisma Studio UI
pnpm db:migrate          # create migration (dev)
pnpm db:migrate:deploy   # apply migrations
pnpm db:seed             # Dev/demo: Jigawa INEC + fake results + demo users
pnpm db:seed:production:apc  # Production APC: geography + campaign + director only
pnpm db:generate         # regenerate Prisma client
```

Production APC seed requires `SEED_ADMIN_PASSWORD` (min 12 chars). On Dokploy / Docker deploy, the migrate container runs it after `prisma migrate deploy` when that variable is set. See `infra/env/dokploy.env.example`.

Deploy (local / staging / production): see [infra/DEPLOY.md](./infra/DEPLOY.md).

After schema changes:

```bash
pnpm db:generate && pnpm db:build && pnpm shared:build
```

---

## Demo accounts (after seed)

Password for all: **`ChangeMe123!`**

| Email | Role |
|-------|------|
| `director@electromon.ng` | Campaign director |
| `pu.officer@electromon.ng` | PU officer (17-13-01-001) |
| `ward.officer@electromon.ng` | Ward RA officer (ATAFI) |
| `lga.officer@electromon.ng` | LGA collation (Hadejia) |
| `state.officer@electromon.ng` | State collation |
| `national.officer@electromon.ng` | National collation |

---

## Project structure

```
├── src/              NestJS modules (collation, auth, field-reports, …)
├── db/               Prisma schema, migrations, seed
├── shared/           Enums and types (@electromon/shared)
├── docs/             Architecture, API reference, testing
├── infra/            Docker Compose, Dockerfiles, observability
└── test/             Jest unit + e2e
```

---

## Scripts

| Command | Description |
|---------|-------------|
| `make dev` | Dev server with watch |
| `make build` | Production build |
| `make test` | Unit tests |
| `make test-e2e` | E2E tests |
| `pnpm lint` | ESLint |

---

## Related

- **Web dashboard:** [github.com/ibrex29/electromon-web](https://github.com/ibrex29/electromon-web) — separate repo
- [infra/README.md](./infra/README.md) — Compose files, staging/production
- [docs/README.md](./docs/README.md) — Documentation index
- [docs/API.md](./docs/API.md) — REST API reference
