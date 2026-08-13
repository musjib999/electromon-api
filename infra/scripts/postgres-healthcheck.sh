#!/bin/sh
# Postgres is healthy only after the role password matches POSTGRES_PASSWORD.
# Official image ignores POSTGRES_PASSWORD on an existing volume; this keeps
# the live role in sync so API/migrate DATABASE_URL credentials stay valid.
set -e

user="${POSTGRES_USER:-electromon}"
db="${POSTGRES_DB:-electromon}"

pg_isready -U "$user" -d "$db" >/dev/null 2>&1 || exit 1

if [ -z "${POSTGRES_PASSWORD:-}" ]; then
  exit 0
fi

stamp="${PGDATA:-/var/lib/postgresql/data}/.electromon-pw-hash"
hash=$(printf '%s' "$POSTGRES_PASSWORD" | sha256sum | awk '{print $1}')

if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$hash" ]; then
  exit 0
fi

# -c sends SQL to the server as-is (no psql :variable interpolation).
# Stdin/script mode is required for :'pw'.
psql -v ON_ERROR_STOP=1 -U "$user" -d "$db" --set=pw="$POSTGRES_PASSWORD" >/dev/null <<EOF
ALTER USER ${user} WITH PASSWORD :'pw';
EOF

printf '%s' "$hash" > "$stamp"
echo "Synced role ${user} password to POSTGRES_PASSWORD"
exit 0
