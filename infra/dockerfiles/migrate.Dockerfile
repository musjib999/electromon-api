# syntax=docker/dockerfile:1

# Electromon Migrate — migrations + production APC seed (build context: api project root)
# Layout matches seed imports: /app/db/prisma, /app/db/src, /app/shared/src

FROM node:20-alpine
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@9.15.4 --activate
RUN apk add --no-cache libc6-compat netcat-openbsd openssl python3 make g++ linux-headers

WORKDIR /app

COPY db/package.json db/pnpm-lock.yaml db/prisma.config.ts db/tsconfig.json ./db/
COPY db/prisma ./db/prisma/
COPY db/src ./db/src/
COPY shared/src ./shared/src/
COPY .npmrc ./db/

WORKDIR /app/db
RUN pnpm install --frozen-lockfile

# Prisma 7 loads prisma.config.ts at generate time; a dummy URL is enough (no DB connect).
RUN DATABASE_URL="postgresql://build:build@127.0.0.1:5432/build?schema=public" npx prisma generate

COPY infra/scripts/entrypoint-migrate.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
