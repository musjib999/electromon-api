#!/bin/sh
# When talking to the in-stack postgres service, rebuild DATABASE_URL from
# POSTGRES_PASSWORD so it cannot drift from the role password.

electromon_export_database_url() {
  case "${DATABASE_URL:-}" in
    *'@postgres:'*|*'@postgres/'*|*'@postgres?'*) ;;
    '') ;;
    *) return 0 ;;
  esac

  if [ -z "${POSTGRES_PASSWORD:-}" ]; then
    return 0
  fi

  if ! command -v node >/dev/null 2>&1; then
    echo "WARN: node not found; leaving DATABASE_URL unchanged"
    return 0
  fi

  encoded=$(node -e "process.stdout.write(encodeURIComponent(process.env.POSTGRES_PASSWORD || ''))")
  user="${POSTGRES_USER:-electromon}"
  dbname="${POSTGRES_DB:-electromon}"
  export DATABASE_URL="postgresql://${user}:${encoded}@postgres:5432/${dbname}?schema=public"
  echo "==> DATABASE_URL rebuilt from POSTGRES_PASSWORD (postgres:5432/${dbname})"
}
