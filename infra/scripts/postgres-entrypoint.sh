#!/bin/bash
# Wrap the official Postgres entrypoint and sync the role password on every
# start. POSTGRES_PASSWORD is ignored for existing volumes; ALTER USER fixes that.
# Do not use psql :variables — they are sent to the server as literal SQL here.
set -eu

user="${POSTGRES_USER:-electromon}"
db="${POSTGRES_DB:-electromon}"

case "$user" in
  *[!a-zA-Z0-9_]*)
    echo "ERROR: POSTGRES_USER must be alphanumeric/underscore"
    exit 1
    ;;
esac

docker-entrypoint.sh "$@" &
pid=$!

shutdown() {
  kill -TERM "$pid" 2>/dev/null || true
  wait "$pid" || true
}
trap shutdown TERM INT

ready=0
for _ in $(seq 1 60); do
  if pg_isready -U "$user" -d "$db" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [ "$ready" != 1 ]; then
  echo "ERROR: Postgres did not become ready"
  shutdown
  exit 1
fi

if [ -n "${POSTGRES_PASSWORD:-}" ]; then
  escaped=$(printf '%s' "$POSTGRES_PASSWORD" | sed "s/'/''/g")
  printf "ALTER USER %s WITH PASSWORD '%s';\n" "$user" "$escaped" \
    | psql -v ON_ERROR_STOP=1 -U "$user" -d "$db" >/dev/null
  echo "Synced role ${user} password to POSTGRES_PASSWORD"
fi

wait "$pid"
